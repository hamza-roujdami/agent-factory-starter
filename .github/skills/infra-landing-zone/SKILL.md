---
name: infra-landing-zone
description: "Verify and consume the Azure AI Landing Zone the platform team provisioned, and pull the connection details the app needs. USE FOR: 'is the landing zone ready', 'verify Azure resources', 'what did the platform team set up', 'get my endpoints', 'check RBAC', confirming Foundry project + Cosmos + AI Search + App Insights + managed identity exist. DO NOT USE FOR: writing Bicep or running azd provision (the platform team owns provisioning), deploying the agent (use foundry-deploy), wiring services in code (use azure-integration)."
---

# Azure AI Landing Zone — verify & consume (don't provision)

**The builder does not provision Azure.** A **platform team** stands up the **Azure AI Landing Zone** and
the app's resources. This skill helps the builder **confirm those exist and are ready**, and **extract the
connection details** the app needs. It is read-only verification, not provisioning.

> If you're looking for the quick GO/NO-GO gate across GitHub + Foundry + Azure, use
> `environment-readiness` first. This skill is the deeper Azure-specific verification.

## What the platform team should have provisioned

Within the **`bicep-ptn-aiml-landing-zone`** pattern, expect:

- **Foundry account + project** + a **model deployment**
- **Application Insights** + Log Analytics (observability)
- **Container Registry (ACR)** (for the hosted-agent image)
- **Cosmos DB** (conversation history) — if §23 needs persistence
- **Azure AI Search** (KB/RAG) — if §12 has knowledge sources
- **Managed identity** + **RBAC** for the app (least privilege), typically:
  Foundry User (runtime model/tool access — azd auto-assigns this to the agent's identity at deploy),
  Cosmos DB Built-in Data Contributor, Search Index Data Reader, AcrPull. The Foundry **project managed
  identity** also needs Container Registry Repository Reader to pull the image.
  (Foundry User was formerly named Azure AI User.)
- Networking (VNet, private endpoints, DNS), Azure Policy guardrails

## Verify it's ready

```bash
az login
az account show                                          # right subscription?
az resource list -g <rg> -o table                        # what exists in the app's resource group
az cognitiveservices account show -n <foundry> -g <rg>   # Foundry account
```

Confirm the app identity has its role assignments (`az role assignment list --assignee <id> -o table`).

## Pull the connection details into config

Capture these into `references/context.md` (§22) and the app's `.env.example` — the app reads them via
`DefaultAzureCredential`, never with keys:

```
FOUNDRY_PROJECT_ENDPOINT=https://<account>.services.ai.azure.com/api/projects/<project>
AZURE_AI_MODEL_DEPLOYMENT_NAME=<deployment>
COSMOS_ENDPOINT=https://<account>.documents.azure.com:443/
AZURE_AI_SEARCH_ENDPOINT=https://<service>.search.windows.net
AZURE_AI_SEARCH_INDEX=<index-name>
APPLICATIONINSIGHTS_CONNECTION_STRING=<from the project>
```

## If something is missing

Stop and **ask the platform team** — don't try to create it. Record the gap as a `❓ OPEN`/risk in
`references/context.md` (§18, §22). Then hand off to `azure-integration` (wire the code) and
`foundry-deploy` (deploy against the ready environment).
