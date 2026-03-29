#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"
SETTINGS_FILE="$HOME/.claude/settings.json"

SKILLS=(prelude geb:think geb:plan geb:align geb:groove)
HOOK_COMMAND="bash ~/.claude/skills/prelude/session-start"

echo "Installing GEB..."

# ── Symlink skills ──

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

# ── Install session-start hook ──

if [ -f "$SETTINGS_FILE" ]; then
  # Check if GEB hook already exists
  if python3 -c "
import json
with open('$SETTINGS_FILE') as f:
    s = json.load(f)
hooks = s.get('hooks', {}).get('SessionStart', [])
for h in hooks:
    for hk in h.get('hooks', []):
        if 'geb' in hk.get('command', '').lower() or 'prelude/session-start' in hk.get('command', ''):
            exit(0)
exit(1)
" 2>/dev/null; then
    echo "  Hook: already configured"
  else
    # Add GEB hook to existing settings
    python3 -c "
import json
with open('$SETTINGS_FILE') as f:
    s = json.load(f)
if 'hooks' not in s:
    s['hooks'] = {}
if 'SessionStart' not in s['hooks']:
    s['hooks']['SessionStart'] = []
s['hooks']['SessionStart'].append({
    'matcher': '',
    'hooks': [{
        'type': 'command',
        'command': '$HOOK_COMMAND',
        'async': False
    }]
})
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(s, f, indent=4)
"
    echo "  Hook: added to $SETTINGS_FILE"
  fi
else
  # Create settings with just the hook
  python3 -c "
import json
s = {
    'hooks': {
        'SessionStart': [{
            'matcher': '',
            'hooks': [{
                'type': 'command',
                'command': '$HOOK_COMMAND',
                'async': False
            }]
        }]
    }
}
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(s, f, indent=4)
"
  echo "  Hook: created $SETTINGS_FILE"
fi

echo ""
echo "Done. GEB will activate automatically on every new session."
echo ""
echo "Skills available:"
echo "  /prelude     — depth guard, disciplines, organic state (auto-loaded)"
echo "  /geb:think   — structured thinking for complex tasks"
echo "  /geb:plan    — decompose approach into executable steps"
echo "  /geb:align   — verify results against original goals"
echo "  /geb:groove  — review and apply discipline proposals"
