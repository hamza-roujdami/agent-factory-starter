---
name: azure-integration
description: "Wire Azure services into the MAF agent: Foundry model, Cosmos conversation history, AI Search RAG/KB grounding. USE FOR: 'add conversation history', 'persist chat', 'add Cosmos', 'add AI Search', 'RAG', 'knowledge base', 'ground the agent on docs', 'configure the Foundry model', managed-identity auth + RBAC for these services. DO NOT USE FOR: verifying the resources exist (use infra-landing-zone), the base app shape (use maf-app-authoring)."
---

# Azure Integration — Foundry · Cosmos · AI Search

Wire the three core Azure services into the agent as MAF clients/context providers. All use
`DefaultAzureCredential` (managed identity in Azure, `az login` locally) — never keys.

## Foundry (model)

```python
from agent_framework.foundry import FoundryChatClient
from azure.identity import DefaultAzureCredential

client = FoundryChatClient(
    project_endpoint=os.environ["FOUNDRY_PROJECT_ENDPOINT"],
    model=os.environ["AZURE_AI_MODEL_DEPLOYMENT_NAME"],
    credential=DefaultAzureCredential(),
)
```

RBAC: the agent's identity needs **Foundry User** (runtime model/tool access) on the Foundry project —
azd auto-assigns this at deploy. (Foundry User was formerly named Azure AI User.)

## Cosmos (conversation history / state)

> **First check the protocol.** With the **Responses** protocol (the default for hosted agents), Foundry
> **already persists conversation history** by conversation ID — you don't need Cosmos just for chat
> history. Reach for `CosmosHistoryProvider` when you use the **Invocations** protocol (you own state) or
> need app-specific state/audit beyond what the platform stores.

`agent-framework-azure-cosmos` provides `CosmosHistoryProvider` (a `HistoryProvider`, itself a context
provider). Use file-based history for local dev, swap to Cosmos for production persistence.

```python
from agent_framework_azure_cosmos import CosmosHistoryProvider

history = CosmosHistoryProvider(
    source_id="history",
    # cosmos endpoint + database/container config per package docs
    credential=DefaultAzureCredential(),
)
agent = Agent(client=client, context_providers=[skills, history])
```

RBAC: **Cosmos DB Built-in Data Contributor** (data-plane) on the account. (`CosmosCheckpointStorage`
exists for workflow checkpointing if you use workflows.)

## AI Search (KB / RAG grounding)

`agent-framework-azure-ai-search` provides `AzureAISearchContextProvider` (+ `AzureAISearchSettings`).
Add it as a context provider so the agent grounds answers on indexed knowledge.

```python
from agent_framework_azure_ai_search import AzureAISearchContextProvider

kb = AzureAISearchContextProvider(
    source_id="kb",
    # search endpoint + index name per package docs
    credential=DefaultAzureCredential(),
)
agent = Agent(client=client, context_providers=[skills, kb, history])
```

RBAC: **Search Index Data Reader** (query) and **Search Service Contributor** (manage index) as needed.
Assign these to the **agent's identity** (created at deploy). Alternatively, reach AI Search (and other
Foundry tools) through the project's **Toolbox MCP endpoint** via an MCP client instead of wiring the SDK
directly — see the Foundry Toolbox docs.

## Env vars to document in `.env.example`

```
FOUNDRY_PROJECT_ENDPOINT=https://<account>.services.ai.azure.com/api/projects/<project>
AZURE_AI_MODEL_DEPLOYMENT_NAME=<deployment>
COSMOS_ENDPOINT=https://<account>.documents.azure.com:443/
AZURE_AI_SEARCH_ENDPOINT=https://<service>.search.windows.net
AZURE_AI_SEARCH_INDEX=<index-name>
```

## Notes

- Context providers run in list order; put `skills` first, then KB grounding, then history.
- Confirm these resources are ready in the Azure AI Landing Zone (verify with `infra-landing-zone`) before wiring.
- Check the package README for the exact constructor kwargs — they evolve; treat the snippets as shape.
