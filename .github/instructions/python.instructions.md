---
description: "Python conventions for the MAF agent app in src/ (adds to global defaults; overrides where the structure differs)"
applyTo: "**/*.py"
---

# Python rules — the MAF agent app

This project builds a **Microsoft Agent Framework** app for **Foundry hosted agents**. These rules add to
the global AI-agent defaults and **override** them where this template differs.

## Structure (overrides the default `agent.py` / `server.py` layout)

- Entry point is **`src/app.py`** — not `agent.py` + `server.py`.
- App capabilities are **skills** under `src/skills/<name>/` = `SKILL.md` + `references/` + `scripts/` (no `data/`).
- No hand-written `infra/` — the **platform team** provisions Azure (see `AGENTS.md`); the app deploys with `azd deploy`.

## The agent

- Build with `FoundryChatClient` + `Agent(context_providers=[...])`.
- Auto-discover skills: `SkillsProvider.from_paths(skill_paths="src/skills")`. Skills are **experimental** —
  MAF emits a `[SKILLS]` `FutureWarning`; filter it if noisy.
- Auth with `DefaultAzureCredential` everywhere. Never hardcode secrets or keys.
- Read platform-injected env (`FOUNDRY_PROJECT_ENDPOINT`, `APPLICATIONINSIGHTS_CONNECTION_STRING`); declare
  your own settings (e.g. the model deployment name) — don't redeclare `FOUNDRY_*`.

## Running

- **Default UI = AG-UI**: a FastAPI app with `add_agent_framework_fastapi_endpoint(app, agent, "/")`, run via
  `uvicorn app:app --reload`. DevUI (`serve()` from `agent_framework.devui`) is a quick **debug** harness only.
- Hosted = a Foundry **protocol library** (`azure-ai-agentserver-responses`, port 8088). Don't hand-roll a bespoke server.
- If you containerize on Apple Silicon, build `linux/amd64` (`docker build --platform linux/amd64 .`).

## Style (same as defaults — don't re-litigate)

- Python 3.13, Ruff, async for I/O, type hints on signatures. Prefer simple functions over class hierarchies.
