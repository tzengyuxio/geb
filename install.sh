#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_TARGET="$HOME/.claude/skills/prelude"

echo "Installing GEB framework v0..."

# Symlink skill directory
if [ -L "$SKILL_TARGET" ] || [ -d "$SKILL_TARGET" ]; then
  echo "Skill directory already exists at $SKILL_TARGET — removing old link."
  rm -rf "$SKILL_TARGET"
fi
ln -s "$SCRIPT_DIR/skills/prelude" "$SKILL_TARGET"
echo "  Linked skill: $SKILL_TARGET → $SCRIPT_DIR/skills/prelude"

echo "Done. Start a new Claude Code session to activate."
