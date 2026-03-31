#!/usr/bin/env bash
set -euo pipefail

SKILLS_DIR="$HOME/.claude/skills"
SETTINGS_FILE="$HOME/.claude/settings.json"
SKILLS=(prelude geb:think geb:align geb:debug geb:review geb:groove)

echo "Uninstalling GEB..."

# ── Remove skill symlinks ──

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

# ── Remove session-start hook ──

if [ -f "$SETTINGS_FILE" ]; then
  python3 -c "
import json
with open('$SETTINGS_FILE') as f:
    s = json.load(f)
if 'hooks' in s and 'SessionStart' in s['hooks']:
    s['hooks']['SessionStart'] = [
        h for h in s['hooks']['SessionStart']
        if not any('prelude/session-start' in hk.get('command', '') for hk in h.get('hooks', []))
    ]
    # Clean up empty structures
    if not s['hooks']['SessionStart']:
        del s['hooks']['SessionStart']
    if not s['hooks']:
        del s['hooks']
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(s, f, indent=4)
" 2>/dev/null && echo "  Hook: removed from $SETTINGS_FILE"
fi

echo "Done."
