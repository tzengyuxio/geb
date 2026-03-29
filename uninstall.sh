#!/usr/bin/env bash
set -euo pipefail

SKILLS_DIR="$HOME/.claude/skills"
SKILLS=(prelude geb:think geb:plan geb:align)

echo "Uninstalling GEB..."

for skill in "${SKILLS[@]}"; do
  target="$SKILLS_DIR/$skill"
  if [ -L "$target" ]; then
    rm "$target"
    echo "  Removed: $skill"
  elif [ -d "$target" ]; then
    rm -rf "$target"
    echo "  Removed: $skill"
  fi
done

echo "Done."
