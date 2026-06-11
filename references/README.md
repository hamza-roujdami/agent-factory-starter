# references/ — context store (gitignored)

Everything the coding agent reads as **context** but that does **not** ship in the app.
This whole folder is gitignored.

## Where things go

| Path | What | Who creates it |
|------|------|----------------|
| `docs/` | **Drop your documents here** — meeting notes, PDFs, specs, transcripts, screenshots | **You** |
| `context.md` | The structured project spec (28-section) | `/intake` (generated from `docs/`) |
| `examples/` | Reference repos/code to mirror (optional) | You |
| *(symlinks)* | Shared refs (e.g. `agent-framework`, landing zone) — symlinked from `~/references/`, never copied | You |

## Workflow

1. Drop raw documents into **`references/docs/`**.
2. Run **`/intake`** → the agent reads `docs/` and produces `references/context.md` + fills `AGENTS.md` placeholders.
3. Build the app in `src/` using that context.

## Conventions

- Project-specific material (customer docs, context) lives here as real files.
- Shared, reusable material (framework, landing zone) is **symlinked** from `~/references/` — never copied per-project.
- Nothing here is committed.
