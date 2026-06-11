---
name: skill-authoring
description: "Scaffold and author an app skill under src/skills/<name>/ for the shipped agent. USE FOR: 'new skill', 'add a capability', 'create a skill', 'scaffold a skill', 'add a tool to the agent', authoring SKILL.md + references/ + scripts/, the MAF SkillsProvider / agentskills.io progressive-disclosure pattern. DO NOT USE FOR: cockpit skills in .github/skills/ (those configure the coding agent), the main app.py (use maf-app-authoring)."
---

# Skill Authoring — capabilities in `src/skills/`

App skills are **modular capabilities of the shipped agent** (Agent B). MAF's `SkillsProvider`
discovers them and exposes them to the model via the **agentskills.io progressive-disclosure** pattern:

1. **Advertise** — each skill's `name` + `description` is injected into the system prompt.
2. **Load** — full `SKILL.md` body returned on demand via the `load_skill` tool.
3. **Read resources** — files under `references/` returned via `read_skill_resource`.
4. **Run scripts** — files under `scripts/` executed via `run_skill_script`.

> These are **app skills** (`src/skills/`), distinct from **cockpit skills** (`.github/skills/`) that
> configure the coding agent. Same file name (`SKILL.md`), different audience and runtime.

## Canonical layout (what to scaffold)

```
src/skills/<name>/          # <name> = kebab-case, matches SKILL.md `name`
  SKILL.md                  # frontmatter (name + description) + ## Usage steps
  references/               # markdown/data the agent reads on demand (resources)
  scripts/                  # executable python the agent runs (CLI-style)
```

There is **no `data/` folder** — structured data lives under `references/` as a resource.

## `SKILL.md` template

```markdown
---
name: <skill-name>
description: <one line of what it does + "Use when ...">. This is the discovery surface — put trigger words here.
---

## Usage

When <trigger condition>:
1. Review `references/<DOC>.md` to find <the relevant data>.
2. Run `scripts/<script>.py --arg <value>` to <do the action>.
3. Present the result clearly to the user.
```

Keep the frontmatter `description` specific — it's all the model sees until it decides to load the skill.

## Scripts

Scripts are CLI-style Python the agent invokes via `run_skill_script`. Accept arguments (e.g. argparse),
print a clear result to stdout, exit non-zero on failure.

```python
# scripts/example.py
import argparse

def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--value", required=True)
    args = p.parse_args()
    print(f"result: {args.value}")

if __name__ == "__main__":
    main()
```

To let the agent run file-based scripts, the app must pass a `script_runner` to the provider:
`SkillsProvider.from_paths(skill_paths="src/skills", script_runner=subprocess_script_runner)`.
(`subprocess_script_runner` runs each script in a subprocess; ship a copy or import the MAF sample helper.)

## Security

MAF XML-escapes skill metadata before prompt injection and guards resource reads against path traversal
and symlink escape — but **only load skills from trusted sources**. Treat scripts as code you own: no
secrets in `references/`, validate script inputs, keep side effects idempotent where possible.

## Steps to add a skill

1. Create `src/skills/<name>/` with `SKILL.md`, `references/`, `scripts/`.
2. Fill `SKILL.md` frontmatter + `## Usage`; add resource docs under `references/`; add script(s) under `scripts/`.
3. No registration needed — `SkillsProvider.from_paths("src/skills")` auto-discovers it on next run.
4. Test by asking the agent something that should trigger the skill; confirm it loads + runs.
