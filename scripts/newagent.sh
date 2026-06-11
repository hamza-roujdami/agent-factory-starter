#!/usr/bin/env bash
#
# newagent — create a new agent project from the agent-factory-starter template.
#
# Usage:
#   newagent <name> [parent-directory]
#
# Creates <parent-directory>/<name> (default: alongside the template), copies the
# cockpit (AGENTS.md, .github/ skills + instructions, references/ scaffolding),
# starts a fresh git repo, and opens it in VS Code. Then you just talk to Copilot.

set -euo pipefail

# --- resolve the template (this script lives in <template>/scripts/) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- read arguments ---
NAME="${1:-}"
if [[ -z "$NAME" ]]; then
  echo "Usage: newagent <name> [parent-directory]"
  echo "Example: newagent support-bot"
  exit 1
fi

# name must be a simple, lowercase, repo-friendly slug
if ! [[ "$NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
  echo "✗ '$NAME' isn't a valid name. Use lowercase letters, numbers, and hyphens (e.g. support-bot)."
  exit 1
fi

PARENT_DIR="${2:-$(dirname "$TEMPLATE_DIR")}"
DEST="$PARENT_DIR/$NAME"

if [[ -e "$DEST" ]]; then
  echo "✗ $DEST already exists. Pick another name or remove it first."
  exit 1
fi

echo "→ Creating '$NAME' from the agent-factory-starter template…"

# --- copy the cockpit (not .git, scripts/, the factory README, or any dropped docs) ---
mkdir -p "$DEST/references/docs" "$DEST/src/skills"
cp    "$TEMPLATE_DIR/AGENTS.md"                  "$DEST/"
cp    "$TEMPLATE_DIR/.gitignore"                 "$DEST/"
cp -R "$TEMPLATE_DIR/.github"                    "$DEST/"
cp    "$TEMPLATE_DIR/references/README.md"       "$DEST/references/"
cp    "$TEMPLATE_DIR/references/docs/README.md"  "$DEST/references/docs/"
touch "$DEST/src/skills/.gitkeep"

# --- a short, friendly README for the new project ---
cat > "$DEST/README.md" <<EOF
# $NAME

An AI agent built with **Microsoft Agent Framework** + **Microsoft Foundry**, scaffolded from
\`agent-factory-starter\`.

## Getting started — just talk to Copilot

1. Open this folder in **VS Code**.
2. Open the **Copilot chat** (the chat icon in the sidebar).
3. Say what you want to build — for example: *"Help me build an agent that …"*

Copilot guides you the rest of the way: understanding your idea, checking your environment is ready,
designing it, building it, and shipping it to a live URL you can test. No prior Azure or coding
experience needed.

> Tip: drop any notes, documents, or examples about your use case into \`references/docs/\` first —
> Copilot will read them.
EOF

# --- fresh git repo + first commit ---
cd "$DEST"
git init -q
git add -A
if ! git commit -qm "Initial commit from agent-factory-starter" 2>/dev/null; then
  echo "ℹ Skipped the first commit — set your git name/email, then run:  git commit -m \"Initial commit\""
fi

echo "✓ Created $DEST"

# --- open in VS Code if available ---
if command -v code >/dev/null 2>&1; then
  code "$DEST"
  echo "✓ Opening in VS Code…"
else
  echo "ℹ Open it in VS Code with:  code \"$DEST\""
fi

cat <<'EOF'

Next:
  1. In VS Code, open the Copilot chat.
  2. Tell it what you want to build — it takes it from there.
EOF
