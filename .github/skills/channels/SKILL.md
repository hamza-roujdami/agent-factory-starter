---
name: channels
description: "Publish the agent to where users are: Teams + Microsoft 365 Copilot, custom web/API, or voice. USE FOR: 'publish to Teams', 'Microsoft 365', 'M365 Copilot', 'add a channel', 'voice agent', 'talk to it', 'phone/voice', 'where can users reach the agent', 'surface the agent'. DO NOT USE FOR: building the agent (use maf-app-authoring), deploying the hosted agent (use foundry-deploy), CI/CD (use github-cicd)."
---

# Channels — surface the agent where users are

A deployed hosted agent has a dedicated endpoint, but most users reach it through a **channel**. Pick the
surfaces from the project's `references/context.md` (§7). Verified against Foundry hosted-agents docs.

## Teams + Microsoft 365 Copilot (the common case)

If the agent uses the **Responses** protocol (the default), the platform **auto-bridges** it to the
**Activity** protocol for Microsoft 365 channels — **no separate wiring**. Publish the hosted agent and
connect it to Teams / M365 Copilot.

- Identity: M365-invoked agents support **OAuth 2.0 On-Behalf-Of (OBO)** — the agent can act with the
  signed-in user's delegated permissions; otherwise it uses its own agent identity (see `azure-integration`).
- Cross-channel: a conversation is reachable from the playground, API, and Teams via its conversation ID.
- Alternative (more control): build on the **Microsoft 365 Agents SDK** directly — MAF has a sample agent
  exposing M365-compatible endpoints (local test with `devtunnel` + Agents Playground).
- Docs: Foundry "Agent applications" (publish to Teams, Microsoft 365, or custom apps).

## Custom web / API

The hosted agent's **Responses** endpoint is OpenAI-compatible — any OpenAI SDK can call it from your own
web app or backend:
```
{project_endpoint}/agents/{name}/endpoint/protocols/openai/responses
```
For non-OpenAI UIs (e.g. **AG-UI**), use the **Invocations** protocol (raw SSE, you define the contract).

## Voice

Real-time voice (mic in, speech out) uses the **Invocations (WebSocket)** protocol (`invocations_ws`),
pairing **Azure Voice Live** (or Pipecat / LiveKit) inside the container.

> ⚠️ `invocations_ws` is in **preview** and currently **North Central US only** — confirm region before
> promising voice. See the Foundry "Build a voice agent" guide.

## Choosing

| Want | Use |
|------|-----|
| Chat in Teams / M365 Copilot | Responses + Activity (auto-bridged) — publish via Agent applications |
| Your own web/app UI | Responses endpoint (OpenAI-compatible) |
| Custom streaming UI (AG-UI) | Invocations |
| Real-time voice | Invocations (WebSocket) + Voice Live *(preview, NCUS)* |

Start with the channel in the spec; a hosted agent can expose several protocols at once. Confirm the agent
is built on Responses first (see `maf-app-authoring`), then publish via `foundry-deploy` / `github-cicd`.
