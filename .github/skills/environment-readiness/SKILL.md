---
name: environment-readiness
description: "Checkpoint AFTER discovery: confirm the builder's environment is provisioned and ready before building. USE FOR: 'is my environment ready', 'prerequisites', 'do I have what I need', 'before I build', 'check my setup', GitHub + Foundry + Azure readiness, confirming the platform team has things ready. DO NOT USE FOR: discovering requirements (use discovery), wiring services in code (use azure-integration), deploying (use foundry-deploy)."
---

# Environment Readiness — the gate between discovery and build

A **GO / NO-GO checkpoint** the agent runs **right after `discovery`**, before design and build.

**Key principle: the builder does NOT build the platform.** A separate **platform team** provisions the
environment — GitHub, Microsoft Foundry, and the Azure AI Landing Zone. The builder's job here is simply
to **confirm those are ready to use**. If anything is missing, the answer is *"sync with your platform
team"* — never *"let's provision it ourselves."*

Be plain-spoken; the builder may be non-technical. Walk the checklist one item at a time, run the verify
commands for them, and translate the results into a simple "ready ✅ / not yet ❌, here's who to ask."

## Ask the builder: is your environment ready?

Three areas. For each, confirm access and capture the concrete values the app will need.

### 1. GitHub (source control)
- [ ] A GitHub repository exists (or they can create one) and the builder has push access.
- Verify: `gh auth status` · `gh repo view` (if a repo exists).
- Note: deployment is **manual** (`azd deploy` from the command line) — no GitHub Actions / CI/CD needed.

### 2. Microsoft Foundry
- [ ] A **Foundry project** exists and the builder has at least **Foundry User** access (runtime model/tool
      access). Deploying a hosted agent additionally needs **Foundry Project Manager** at project scope.
      (These roles were recently renamed — formerly Azure AI User / Azure AI Project Manager.)
- [ ] A **model is deployed** in that project.
- [ ] The target **region supports hosted agents** (preview — ~20 regions, e.g. East US 2, Sweden Central,
      North Central US; confirm against the current Foundry region list).
- Capture: `FOUNDRY_PROJECT_ENDPOINT` (`https://<account>.services.ai.azure.com/api/projects/<project>`)
  and `AZURE_AI_MODEL_DEPLOYMENT_NAME`.

### 3. Azure + AI Landing Zone
- [ ] An **Azure subscription** and the **Azure AI Landing Zone** are provisioned (networking, private
      endpoints, policies) — owned by the platform team.
- [ ] The app's **identity + RBAC** are in place (managed identity with the roles the app needs).
- [ ] Region confirmed.
- Verify: `az account show` (logged in + right subscription). `az login` if not.
- Deeper Azure verification + pulling connection details → use the `infra-landing-zone` skill.

## Outcome

- **All ready ✅** → record the captured endpoints/names in `references/context.md` (§18 dependencies,
  §22 Azure footprint) and proceed to `solution-architecture` → build.
- **Something missing ❌** → **stop and tell the builder to sync with the platform team.** Give them a
  crisp "please provision / share these" list:
  - GitHub repo (source control) + push access
  - Foundry project endpoint + deployed model name + my access role
  - Azure subscription + AI Landing Zone ready + app identity & RBAC + region
- Mark unresolved items as `❓ OPEN` in the spec so they stay visible.

> Don't let the build proceed on an unconfirmed environment — a missing endpoint or role surfaces as a
> confusing failure much later. Gate early.
