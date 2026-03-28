#!/usr/bin/env bash
set -euo pipefail

SKILL_TARGET="$HOME/.claude/skills/prelude"

echo "Uninstalling GEB framework..."

if [ -L "$SKILL_TARGET" ]; then
  rm "$SKILL_TARGET"
  echo "  Removed skill symlink: $SKILL_TARGET"
elif [ -d "$SKILL_TARGET" ]; then
  rm -rf "$SKILL_TARGET"
  echo "  Removed skill directory: $SKILL_TARGET"
else
  echo "  Skill not found at $SKILL_TARGET — nothing to remove."
fi

echo "Done. Restart Claude Code to deactivate."
