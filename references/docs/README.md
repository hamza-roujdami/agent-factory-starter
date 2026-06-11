# docs/ — drop your documents here

Put any source material the agent should use as context:

- Meeting notes (`.md`, `.txt`)
- Use-case specs / PRDs (`.pdf`, `.docx`)
- Transcripts
- Screenshots / diagrams
- Anything the customer or team shares

Then run **`/intake`** — the agent reads everything in this folder and produces
`references/context.md` (the structured project spec).

> This folder is gitignored. Nothing here is committed.
