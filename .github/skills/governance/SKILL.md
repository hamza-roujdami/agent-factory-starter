---
name: governance
description: "Responsible-AI guardrails, security, and governance for the agent. USE FOR: 'is it safe', 'content safety', 'guardrails', 'responsible AI', 'security review', 'governance', 'compliance', 'FIDES', 'agent governance', 'data boundaries', 'red team', 'who can use it', sign-off before go-live. DO NOT USE FOR: identity/RBAC wiring (use azure-integration / infra-landing-zone), evaluation quality scores (use evaluation-observability)."
---

# Governance — safe, compliant, accountable

Guardrails so the agent can ship responsibly. Much of this is **platform-team / responsible-AI territory**;
the builder's job is to apply a short checklist and know who owns the rest. Keep it proportionate to the
use case — a low-risk internal helper needs less than a customer-facing or regulated one.

## What the platform team owns (confirm, don't build)

- **Content safety / filters** on the Foundry models (jailbreak, harmful content).
- **Identity & least privilege** — the agent's Entra identity + RBAC (see `azure-integration` / `infra-landing-zone`).
- **Network & data boundaries** — VNet/private endpoints, region/data residency, Azure Policy guardrails.
- **Org governance tooling** — Microsoft Foundry's governance surface (e.g. **Agent Governance Toolkit**)
  and **FIDES** security for agents are evolving; confirm what your platform team has enabled and what it
  requires of you. Don't assume specifics — check the current Foundry governance/responsible-AI docs.

## What the builder does (short checklist)

- **Secrets**: never in the image or env literals — use Foundry **connections** / Key Vault (see `foundry-deploy`).
- **Grounding & honesty**: ground answers on approved KB (see `azure-integration`); design a clear
  "I don't know / escalate" fallback (capture it in `references/context.md` §9, §14).
- **Human-in-the-loop**: for consequential actions, require confirmation/approval (§14).
- **Data handling**: only send the model what's needed; record PII/retention/residency (§17). Review what
  flows to any non-Microsoft tool the agent calls.
- **Evaluation as a safety gate**: add safety/quality checks to the eval set and run them in CI
  (see `evaluation-observability`) — block deploy on regressions.
- **Auditability**: rely on the per-agent identity + tracing for who-did-what (see `evaluation-observability`).
- **Access**: confirm who may use the agent and through which channels (§6, §7).

## Go-live sign-off

Before shipping, confirm with the platform/responsible-AI owner:
- [ ] Content safety enabled on the model
- [ ] Identity + least-privilege RBAC in place; no secrets in code
- [ ] Data boundaries (region/residency, PII handling) reviewed
- [ ] Safety + quality evals pass in CI
- [ ] Human-in-the-loop on consequential actions
- [ ] Required org governance (Agent Governance Toolkit / FIDES, if mandated) satisfied

> Record outcomes + any open risks in `references/context.md` (§25 Security & Compliance, §28 Risks).
> When unsure about a specific control, ask the platform team — don't guess.
