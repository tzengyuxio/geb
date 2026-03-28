#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"

SKILLS=(prelude geb-think geb-plan geb-align)

echo "Installing GEB..."

# Remove legacy hooks if present
HOOKS_SETTINGS="$HOME/.claude/settings.json"
if [ -f "$HOOKS_SETTINGS" ]; then
  if grep -q "session-start" "$HOOKS_SETTINGS" 2>/dev/null; then
    echo "  Note: GEB no longer uses auto-start hooks. Remove old hook entries from $HOOKS_SETTINGS if present."
  fi
fi

# Symlink each skill
for skill in "${SKILLS[@]}"; do
  target="$SKILLS_DIR/$skill"
  source="$SCRIPT_DIR/skills/$skill"

  if [ ! -d "$source" ]; then
    echo "  Warning: skill source not found: $source"
    continue
  fi

  if [ -L "$target" ] || [ -d "$target" ]; then
    rm -rf "$target"
  fi

  ln -s "$source" "$target"
  echo "  Linked: $skill"
done

echo ""
echo "Done. Skills installed:"
echo "  /prelude    — activate GEB (depth routing, organic state)"
echo "  /geb-think  — structured thinking for complex tasks"
echo "  /geb-plan   — decompose approach into executable steps"
echo "  /geb-align  — verify results against original goals"
