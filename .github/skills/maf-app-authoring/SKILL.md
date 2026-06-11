---
name: maf-app-authoring
description: "Author the agent app (src/app.py) with Microsoft Agent Framework + Foundry. USE FOR: 'build the agent', 'create app.py', 'scaffold the agent app', 'wire up the agent', 'MAF agent', adding context providers, running the agent locally with DevUI, the Agent + SkillsProvider + FoundryChatClient shape. DO NOT USE FOR: authoring individual src/skills (use skill-authoring), wiring Cosmos/AI Search (use azure-integration), verifying the Azure landing zone (use infra-landing-zone), hosted deploy (use foundry-deploy)."
---

# MAF App Authoring — the agent app in `src/`

How to build the shipped agent (Agent B) with **Microsoft Agent Framework** (core v1.3.0+) on
**Azure AI Foundry**. Verified against the `agent-framework` samples.

## Packages

```toml
# pyproject.toml (Python 3.13)
dependencies = [
  "agent-framework-core",
  "agent-framework-foundry",
  "agent-framework-ag-ui",   # default UI: AG-UI web protocol (FastAPI)
  "fastapi",
  "uvicorn",
  "agent-framework-devui",   # quick local debug harness only — NOT production
  "azure-identity",
  "python-dotenv",
]
```

## `src/app.py` shape

`Agent` + `FoundryChatClient` + `context_providers` (skills auto-discovered from `src/skills/`,
plus any custom providers). Auth via `DefaultAzureCredential`.

```python
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from agent_framework import Agent, ContextProvider, SkillsProvider
from agent_framework.foundry import FoundryChatClient
from azure.identity import DefaultAzureCredential
from dotenv import load_dotenv

load_dotenv()


class DateTimeContextProvider(ContextProvider):
    """EXAMPLE custom context provider (not a built-in). Injects the current UTC time each turn.

    Minimal illustration of the ContextProvider pattern — override before_run / after_run.
    """

    def __init__(self) -> None:
        super().__init__(source_id="datetime")

    async def before_run(self, *, agent: Any, session: Any, context: Any, state: dict[str, Any]) -> None:
        now = datetime.now(timezone.utc).isoformat()
        context.extend_instructions(self.source_id, f"Current UTC time: {now}")


def build_agent() -> Agent:
    client = FoundryChatClient(
        project_endpoint=os.environ["FOUNDRY_PROJECT_ENDPOINT"],
        model=os.environ["AZURE_AI_MODEL_DEPLOYMENT_NAME"],
        credential=DefaultAzureCredential(),  # az login locally; managed identity in Azure
    )
    skills = SkillsProvider.from_paths(skill_paths=str(Path(__file__).parent / "skills"))
    return Agent(
        client=client,
        name="{{AGENT_NAME}}",
        instructions="{{SYSTEM_PROMPT}}",
        context_providers=[skills, DateTimeContextProvider()],
    )


if __name__ == "__main__":
    # Default UI: AG-UI web protocol served over FastAPI.
    from fastapi import FastAPI
    from agent_framework.ag_ui import add_agent_framework_fastapi_endpoint

    app = FastAPI()
    add_agent_framework_fastapi_endpoint(app, build_agent(), "/")
    # Run with: uvicorn app:app --reload   (AG-UI frontend talks to this endpoint)

    # Quick-debug alternative (no frontend needed):
    #   from agent_framework.devui import serve; serve(entities=[build_agent()], auto_open=True)
```

## Key facts (verified)

- **Auth**: `DefaultAzureCredential` everywhere. Samples use `AzureCliCredential` for pure-local; prefer
  `DefaultAzureCredential` so the same code works with managed identity in Azure. Never hardcode keys.
- **Env (local vs hosted — important)**: the two settings are `FOUNDRY_PROJECT_ENDPOINT`
  (`https://<account>.services.ai.azure.com/api/projects/<project>`) and `AZURE_AI_MODEL_DEPLOYMENT_NAME`.
  - **Local**: keep them in `src/.env` (gitignored, `load_dotenv()`); document every var in `.env.example`.
  - **Hosted**: `.env` **never ships in the image**. Foundry **auto-injects** `FOUNDRY_PROJECT_ENDPOINT` +
    `APPLICATIONINSIGHTS_CONNECTION_STRING` (don't declare them); your own vars (e.g.
    `AZURE_AI_MODEL_DEPLOYMENT_NAME`) go in `agent.yaml` `environment_variables`; secrets come from a
    Foundry **connection** (`${{connections...}}`, Key Vault) — see `foundry-deploy`. So a var is mirrored:
    `.env` for local ↔ `agent.yaml` for hosted.
- **Skills auto-discovery**: `SkillsProvider.from_paths(skill_paths="src/skills")` scans for `SKILL.md`
  files. If skills ship runnable scripts, pass a `script_runner` (see `skill-authoring`). Skills are
  **experimental** — MAF emits a `[SKILLS]` `FutureWarning`; filter it if noisy.
- **Context providers** compose in a list and run in order. `before_run` adds instructions/messages/tools;
  `after_run` processes the response. History providers (file/Cosmos) are context providers too.
- **Running**: the **default UI is AG-UI** — a FastAPI app exposing
  `add_agent_framework_fastapi_endpoint(app, agent, "/")` (run `uvicorn app:app --reload`), which the AG-UI
  web frontend connects to. AG-UI can host an agent **or** a workflow. For a quick poke without a frontend,
  `serve()` from `agent_framework.devui` is a debug harness (`http://localhost:8080`, `--instrumentation`
  for traces) — **dev only**. Neither is the production surface; deploy as a hosted agent (see `foundry-deploy`).
  On a hosted agent, AG-UI maps to the **Invocations** protocol (see `channels`).
- **Hosted env**: in Azure, `FOUNDRY_PROJECT_ENDPOINT` + `APPLICATIONINSIGHTS_CONNECTION_STRING` are
  injected automatically; locally you set them in `src/.env`.
- **Streaming**: `async for chunk in agent.run(prompt, stream=True): chunk.text`.

## Hand off

- Add capabilities → `skill-authoring`. Wire Cosmos/AI Search → `azure-integration`.
- Provision Azure → `infra-landing-zone`. Ship it → `foundry-deploy`.
