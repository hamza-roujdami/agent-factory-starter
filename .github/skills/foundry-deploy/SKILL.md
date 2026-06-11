---
name: foundry-deploy
description: "Package and deploy the agent as a Foundry hosted agent against an already-provisioned environment. USE FOR: 'deploy the agent', 'deploy to Foundry', 'hosted agent', 'ship the agent', 'go live', building the Dockerfile + agent.yaml, running azd ai agent init/deploy, the Responses vs Invocations API. DO NOT USE FOR: verifying the landing zone (use infra-landing-zone), automated CI/CD (use github-cicd), local dev with DevUI (use maf-app-authoring)."
---

# Foundry Deploy — ship the hosted agent

Deploy the agent to **Microsoft Foundry** as a hosted agent. A hosted agent is **your container image**:
Agent Service pulls it from ACR, provisions a per-session sandbox, and gives it a **dedicated Entra agent
identity + endpoint** automatically. Verified against the official deploy guide.

> Status: Hosted agents are in **preview** (GA targeted June 2026) — confirm current status/regions in the
> Foundry docs before a production commitment.

## Deployment lifecycle

1. **Build & push** the container image to Azure Container Registry (ACR).
2. **Create an agent version** — registers the image; the platform provisions infra + creates the agent identity.
3. **Poll** until version status is `active`.
4. **Invoke** the agent's dedicated endpoint.

`azd` (and the VS Code extension) automate all four — prefer it.

## Artifacts

- **`Dockerfile`** — builds the agent image (Python 3.13). **Must be `linux/amd64`** — on Apple Silicon
  build with `docker build --platform linux/amd64 .` or the platform can't run it.
- **`agent.yaml`** — the hosted-agent definition: declares the protocols the container exposes and its
  `environment_variables`. (`azd ai agent init` also generates `azure.yaml`, the azd project config.)

## Container requirements

- Serve on **port 8088** locally. Use a Foundry **protocol library** to handle the HTTP/streaming server,
  health checks, and OpenTelemetry: `azure-ai-agentserver-responses` (or `…-invocations`). It auto-exposes
  a `/readiness` endpoint.
- **Protocols** (declare in `agent.yaml`): **Responses** (default — platform manages conversation history +
  streaming, OpenAI-compatible) · **Invocations** (arbitrary JSON, you manage state) · **Invocations-WS**
  (voice, preview). One container can expose several. *Not sure? Start with Responses.*

## Prerequisites

```bash
az login
azd auth login
azd ext install azure.ai.agents      # the AI agent extension for azd
```

A **ready** Foundry project + deployed model (platform team — confirm via `environment-readiness` /
`infra-landing-zone`). Deploying needs **Foundry Project Manager** at project scope; the runtime
**Foundry User** role is auto-assigned to the agent identity by azd. The ACR must stay **public-reachable**
(private-endpoint-only ACR isn't supported).

## Flow (azd — recommended)

```bash
azd ai agent init -m ./agent.yaml    # wire the project to your ready Foundry project + model
azd ai agent run                     # run the agent host locally (http://localhost:8088)
azd ai agent invoke --local "Hello!" # smoke-test locally
azd deploy                           # build → push to ACR → create version → deploy
azd down                             # tear down when finished
```

The environment is already provisioned (platform team) — there is **no `azd provision`** step.

> Docker-less option: a **source-code `.zip` deploy** (preview) lets the platform build the image for you —
> handy for non-technical builders. SDK (`azure-ai-projects>=2.1.0`, `create_version`) and REST are also available.

## Invoke the deployed agent

The endpoint is created automatically (no publishing needed):

```
Responses:    {project_endpoint}/agents/{name}/endpoint/protocols/openai/responses
Invocations:  {project_endpoint}/agents/{name}/endpoint/protocols/invocations
```

```bash
azd ai agent invoke "Hello!"   # against the deployed agent — share this with the builder to test
```

## Configuration & secrets

- **Platform-injected** (don't redeclare): `FOUNDRY_PROJECT_ENDPOINT`, `APPLICATIONINSIGHTS_CONNECTION_STRING`,
  and other `FOUNDRY_*` vars. Declare your own (e.g. the model deployment name) in `agent.yaml`.
- **Secrets**: never bake into the image or env literals. Reference a Foundry **project connection**:
  `${{connections.<name>.credentials.<field>}}` in `agent.yaml` — resolved (Key Vault-backed) at sandbox start.

## Observability

Built-in: the platform injects `APPLICATIONINSIGHTS_CONNECTION_STRING` and the protocol libraries emit
OpenTelemetry traces by default — view them in the linked Application Insights resource.

## Notes

- DevUI is for local dev only; the hosted agent is the production surface.
- Reference sample (MAF + Dockerfile): `github.com/microsoft-foundry/foundry-samples` → `samples/python/hosted-agents/agent-framework`.
- Full guide: https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/deploy-hosted-agent
