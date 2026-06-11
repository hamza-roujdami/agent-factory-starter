---
name: evaluation-observability
description: "Measure and watch the agent: evaluate quality and set up tracing/monitoring. USE FOR: 'evaluate the agent', 'eval', 'is it any good', 'test quality', 'add tracing', 'observability', 'monitor the agent', 'App Insights', 'OpenTelemetry', 'eval dashboard', 'optimize the prompt/instructions', 'agent optimizer'. DO NOT USE FOR: deploying (use foundry-deploy), wiring KB/state (use azure-integration), governance/security policy (use governance)."
---

# Evaluation & Observability — prove it works, then watch it

The back half of "test your agent": **evaluate** answer quality and **observe** what it does in production.
Verified against the Microsoft Agent Framework source + Foundry docs.

## Evaluate (MAF built-in)

MAF ships an evaluation framework — start local (fast, no API), graduate to Foundry evaluators.

```python
# Local — fast inner-loop / CI smoke tests
from agent_framework import evaluate_agent, LocalEvaluator, keyword_check, tool_called_check

local = LocalEvaluator(keyword_check("refund", "policy"), tool_called_check("lookup_order"))
results = await evaluate_agent(agent=agent, queries=["How do I get a refund?"], evaluators=local)
results.raise_for_status()   # fail CI if below threshold
```

```python
# Cloud — Foundry evaluators (quality/safety scorers, dashboards in the portal)
from agent_framework.foundry import FoundryEvals

evals = FoundryEvals(project_client=client, model="gpt-4o")
results = await evaluate_agent(agent=agent, queries=[...], evaluators=evals)
```

- Keep a small **eval dataset** of representative queries (+ expected behavior) under the project; grow it
  from real traces over time.
- Run evals before each deploy as a quality gate (locally, or wherever you run checks).
- Foundry surfaces eval runs as **dashboards**; see the official "Agent evaluators" guidance.

## Observe (OpenTelemetry → App Insights)

MAF emits OpenTelemetry traces/logs/metrics using the GenAI semantic conventions.

```python
from agent_framework.observability import configure_otel_providers

configure_otel_providers()  # reads OTEL_* env vars; or enable_console_exporters=True for local
```

- **Local dev**: DevUI with `--instrumentation`, the Aspire Dashboard (Docker), or the AI Toolkit for VS
  Code tracing view — all show traces without Azure.
- **Hosted**: Foundry **auto-injects** `APPLICATIONINSIGHTS_CONNECTION_STRING` and the protocol libraries
  emit OTel **by default** — traces appear in the linked Application Insights (Transaction search /
  Performance). No wiring needed.
- Use the same App Insights data to **right-size** the hosted sandbox (CPU/memory vs. observed peaks).

## Optimize (Agent Optimizer)

Foundry's **Agent Optimizer** can auto-improve the agent's instructions from eval results/traces. Treat it
as a loop: evaluate → optimize instructions → re-evaluate. See the official "Agent optimizer" guidance.

## The loop

```
build → evaluate (local → Foundry) → deploy → observe (App Insights) → optimize → re-evaluate
```

> Docs: Foundry "Agent evaluators", "Agent optimizer overview", and
> learn.microsoft.com/azure/foundry/observability/concepts/trace-agent-concept.
