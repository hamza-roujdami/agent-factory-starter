---
name: environment-readiness
description: "Checkpoint AFTER design, the LAST gate before coding: turn the architecture's service list into a platform request and confirm the agentic-AI platform is ready. USE FOR: 'is my environment ready', 'what services do I need', 'request the platform', 'prerequisites', 'before I build', 'confirm my setup', Foundry + identity + App Insights + (Cosmos/AI Search if needed) readiness. DO NOT USE FOR: discovering requirements (use discovery), designing the architecture (use solution-architecture), wiring services in code (use azure-integration), deploying (use foundry-deploy)."
---

# Environment Readiness — the last gate before coding

A checkpoint the agent runs **right after `solution-architecture`**, once the design exists — and
**before** any code is written. The design names the services the agent needs; this step turns that into a
**platform request** and confirms the platform is ready.

**Key principle: the builder does NOT build the platform.** A separate **platform team** runs one standard
**agentic-AI platform**. The builder doesn't audit infra health — they **request** the services their
design needs, and the platform team switches them on. If something isn't ready, the answer is *"ask the
platform team"* — never *"let's provision it ourselves."*

Be plain-spoken; the builder may be non-technical. Walk it one item at a time, run the verify commands for
them, and translate results into a simple "ready ✅ / not yet ❌, here's who to ask."

## What services does this agent need?

The set depends on the design. Some services are needed by **every** MAF + Foundry agent; the rest are
**design-driven** — only request them if the architecture calls for them.

| Always needed (any agent) | Why |
|---|---|
| **Foundry project + 1 chat model** | the agent's brain |
| **Entra identity + RBAC** (Foundry User to run; Foundry Project Manager to deploy) | auth via `DefaultAzureCredential` |
| **Application Insights** | tracing/observability (auto-injected when hosted) |
| **Container registry (ACR)** | stores the hosted agent image |

| Design-driven (only if the design needs it) | Triggered when the agent… |
|---|---|
| **Cosmos DB** | needs durable conversation history / app state |
| **Azure AI Search** | does RAG / grounds on a knowledge base |
| **Key Vault connection** | calls an external API that needs a secret |
| **MCP / data-source tools** | integrates with a specific backend system |

> Pull the exact list from the architecture (`src/docs/`). Foundry + identity + App Insights + ACR are the
> baseline; add Cosmos / AI Search / Key Vault / tools per the design — nothing more.

## Confirm the platform is ready

For each needed service, confirm access and capture the concrete values the app will use.

### GitHub (source control)
- [ ] A GitHub repository exists (or they can create one) and the builder has push access.
- Verify: `gh auth status` · `gh repo view` (if a repo exists).
- Note: deployment is **manual** (`azd deploy` from the command line) — no GitHub Actions / CI/CD needed.

### Foundry (always)
- [ ] A **Foundry project** exists and the builder has at least **Foundry User** access. Deploying a hosted
      agent additionally needs **Foundry Project Manager** at project scope. (Formerly Azure AI User /
      Azure AI Project Manager.)
- [ ] A **chat model is deployed** in that project.
- [ ] The target **region supports hosted agents** (preview — ~20 regions, e.g. East US 2, Sweden Central,
      North Central US; confirm against the current Foundry region list).
- Capture: `FOUNDRY_PROJECT_ENDPOINT` (`https://<account>.services.ai.azure.com/api/projects/<project>`)
  and `AZURE_AI_MODEL_DEPLOYMENT_NAME`.

### Identity, observability, registry (always)
- [ ] App **identity + RBAC** in place (managed identity with the roles the app needs).
- [ ] **Application Insights** available (auto-injected for hosted agents).
- [ ] **Container registry** reachable for the hosted image.
- Verify: `az account show` (logged in + right subscription). `az login` if not.

### Design-driven services (only if the design needs them)
- [ ] **Cosmos DB** connection — if the design persists history/state.
- [ ] **Azure AI Search** index + connection — if the design does RAG/KB grounding.
- [ ] **Key Vault** connection(s) — if the design calls external APIs needing secrets.
- Deeper Azure verification + pulling connection details → use the `infra-landing-zone` skill.

## Outcome

- **All ready ✅** → record the captured endpoints/names in `references/context.md` (§18 dependencies,
  §22 Azure footprint) and proceed to **build** (`maf-app-authoring`).
- **Something missing ❌** → **stop and give the builder a crisp request for the platform team**, listing
  exactly the services the design needs:
  - GitHub repo (source control) + push access
  - Foundry project endpoint + deployed chat model + my access role
  - App identity & RBAC + App Insights + container registry + region
  - *(only if the design needs them)* Cosmos · AI Search · Key Vault connections
- Mark unresolved items as `❓ OPEN` in the spec so they stay visible.

> Don't let the build proceed on an unconfirmed platform — a missing endpoint or role surfaces as a
> confusing failure much later. Confirm here, then code.
