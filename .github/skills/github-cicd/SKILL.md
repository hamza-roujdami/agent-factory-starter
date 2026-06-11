---
name: github-cicd
description: "Set up GitHub + GitHub Actions CI/CD so a git push deploys the agent to Foundry and returns a testable URL. USE FOR: 'set up CI/CD', 'GitHub Actions', 'deploy on push', 'create the pipeline', 'connect to GitHub', 'automate deployment', git init + create repo + workflow + OIDC auth to Azure. DO NOT USE FOR: local/manual deploy (use foundry-deploy), verifying the landing zone (use infra-landing-zone)."
---

# GitHub CI/CD — push to deploy, get a URL to test

Complete the journey's back half: **git push → GitHub Actions → deploy to Foundry → a live URL to test.**
This is the automated path; `foundry-deploy` is the local/manual one.

Be hand-holding: the builder may be non-technical. Explain each step in plain language, run the commands
for them, and end by giving them the URL where they can try their agent.

**Model: the environment is already provisioned** by the platform team (confirmed via
`environment-readiness`). So the pipeline **deploys only** — it does not provision Azure resources.

## Prerequisites

- `environment-readiness` passed: Foundry project + model + Azure landing zone are ready.
- The project deploys locally already (via `foundry-deploy`): `azd ai agent init` produced an
  `azure.yaml` + `agent.yaml`, and `azd deploy` works against the ready environment.
- Tools: `git`, GitHub CLI (`gh`) authenticated (`gh auth login`), `azd` authenticated (`azd auth login`).
- An **OIDC deploy identity** to Azure (federated credential) — usually set up by the **platform team**.
  Ask them for `AZURE_CLIENT_ID` / `AZURE_TENANT_ID` / `AZURE_SUBSCRIPTION_ID` if you don't have it.

## Recommended path — `azd pipeline config` (OIDC, no secrets)

azd generates the workflow **and** wires passwordless auth in one step:

```bash
git init && git add -A && git commit -m "initial commit"   # if not already a repo
azd pipeline config --provider github
```

This will:
- Create (or connect) a **GitHub repository** and push to it.
- Wire **OIDC** federated auth so GitHub Actions authenticates to Azure with **no secrets** stored in the
  repo (best practice). If the platform team already created the deploy identity, supply its values
  instead of creating a new one.
- Set pipeline variables (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_ENV_NAME`,
  `AZURE_LOCATION`).
- Commit a workflow at `.github/workflows/azure-dev.yml`.

The workflow should run **`azd deploy` only** (the environment is already provisioned). After it finishes,
**every push to the default branch redeploys the agent**. The run logs (and the Foundry project) expose
the agent's endpoint — share that URL so the builder can test it.

## What the workflow does (shape)

The `azure-dev.yml` authenticates with OIDC, installs azd, then **deploys** (no provision):

```yaml
permissions:
  id-token: write      # required for OIDC federated login
  contents: read
# ... on: push to main, workflow_dispatch ...
# steps: checkout → azure/login@v2 (client-id/tenant-id/subscription-id, no secret)
#        → setup azd → azd deploy --no-prompt
```

The hosted runtime auto-injects `FOUNDRY_PROJECT_ENDPOINT` and `APPLICATIONINSIGHTS_CONNECTION_STRING`
(plus other `FOUNDRY_*` vars) into the agent container — don't hardcode or redeclare them. Your own
settings (e.g. the model deployment name) are declared in `agent.yaml`'s `environment_variables`.

## Build for the right architecture

The hosted platform requires **x86_64 (linux/amd64)** images. If the CI runner (or a local build) is
ARM, build with `docker build --platform linux/amd64 .` or the image will fail to start.

## Test the deployed agent

Once the workflow succeeds:

```bash
azd ai agent invoke "Hello!"        # invoke the deployed agent
# or curl the Responses API at the Foundry project endpoint (see foundry-deploy)
```

## Notes

- Prefer OIDC/federated identity over stored secrets. If the org requires a client secret instead, use
  `azd pipeline config --auth-type client-credentials` (less preferred).
- The exact hosted-agent CI steps build on standard azd deploy — verify against the official guide:
  https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/deploy-hosted-agent
- Keep the pipeline idempotent; protect the default branch; require the workflow to pass before merge.
