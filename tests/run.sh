#!/usr/bin/env bash
#
# GEB Test Runner
#
# Runs test scenarios against SKILL.md and a control (no skill).
# Outputs results to tests/results/<timestamp>/
#
# Usage:
#   bash tests/run.sh                          # run all scenarios
#   bash tests/run.sh --skill path/to/SKILL.md # test a specific SKILL.md
#   bash tests/run.sh --scenario rename-variable # run one scenario
#   bash tests/run.sh --control-only           # skip GEB runs, only control
#   bash tests/run.sh --geb-only               # skip control runs
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SCENARIOS_FILE="$SCRIPT_DIR/scenarios.yml"
SKILL_FILE="${SKILL_FILE:-$PROJECT_DIR/skills/prelude/SKILL.md}"
MODEL="${MODEL:-sonnet}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULTS_DIR="$SCRIPT_DIR/results/$TIMESTAMP"
ORIGINAL_DIR="$(pwd)"

# Parse args
FILTER_SCENARIO=""
RUN_GEB=true
RUN_CONTROL=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skill) SKILL_FILE="$2"; shift 2 ;;
    --scenario) FILTER_SCENARIO="$2"; shift 2 ;;
    --control-only) RUN_GEB=false; shift ;;
    --geb-only) RUN_CONTROL=false; shift ;;
    --model) MODEL="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [ ! -f "$SCENARIOS_FILE" ]; then
  echo "Error: scenarios file not found: $SCENARIOS_FILE"
  exit 1
fi

if [ "$RUN_GEB" = true ] && [ ! -f "$SKILL_FILE" ]; then
  echo "Error: SKILL.md not found: $SKILL_FILE"
  exit 1
fi

mkdir -p "$RESULTS_DIR"

# Save run metadata
cat > "$RESULTS_DIR/meta.yml" <<EOF
timestamp: $TIMESTAMP
model: $MODEL
skill_file: $SKILL_FILE
skill_hash: $(md5 -q "$SKILL_FILE" 2>/dev/null || md5sum "$SKILL_FILE" | cut -d' ' -f1)
scenarios_file: $SCENARIOS_FILE
filter: ${FILTER_SCENARIO:-all}
EOF

echo "GEB Test Runner"
echo "  Model:     $MODEL"
echo "  Skill:     $SKILL_FILE"
echo "  Results:   $RESULTS_DIR"
echo ""

# Parse scenarios from YAML using Python (avoid yq dependency)
SCENARIO_NAMES=$(python3 -c "
import yaml, sys
with open('$SCENARIOS_FILE') as f:
    scenarios = yaml.safe_load(f)
for s in scenarios:
    print(s['name'])
")

TOTAL=$(echo "$SCENARIO_NAMES" | wc -l | tr -d ' ')
CURRENT=0

SKILL_CONTENT=""
if [ "$RUN_GEB" = true ]; then
  SKILL_CONTENT=$(cat "$SKILL_FILE")
fi

for SCENARIO_NAME in $SCENARIO_NAMES; do
  # Apply filter
  if [ -n "$FILTER_SCENARIO" ] && [ "$SCENARIO_NAME" != "$FILTER_SCENARIO" ]; then
    continue
  fi

  CURRENT=$((CURRENT + 1))
  echo "[$CURRENT/$TOTAL] $SCENARIO_NAME"

  # Extract scenario data with Python
  SCENARIO_DATA=$(python3 -c "
import yaml, json, sys
with open('$SCENARIOS_FILE') as f:
    scenarios = yaml.safe_load(f)
for s in scenarios:
    if s['name'] == '$SCENARIO_NAME':
        print(json.dumps(s))
        break
")

  PROMPT=$(echo "$SCENARIO_DATA" | python3 -c "import json,sys; print(json.load(sys.stdin)['prompt'])")
  SCENARIO_DIR="$RESULTS_DIR/$SCENARIO_NAME"
  mkdir -p "$SCENARIO_DIR"

  # Save scenario metadata
  echo "$SCENARIO_DATA" | python3 -c "
import json, sys
s = json.load(sys.stdin)
print(f\"category: {s['category']}\")
print(f\"prompt: {s['prompt']}\")
print('pass_criteria:')
for c in s.get('pass_criteria', []):
    print(f'  - {c}')
print('fail_patterns:')
for p in s.get('fail_patterns', []):
    print(f'  - {p}')
" > "$SCENARIO_DIR/scenario.yml"

  # Create temp project directory with context files
  TEMP_DIR=$(mktemp -d)
  echo "$SCENARIO_DATA" | python3 -c "
import json, sys, os
s = json.load(sys.stdin)
for path, content in s.get('context_files', {}).items():
    full = os.path.join('$TEMP_DIR', path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, 'w') as f:
        f.write(content)
"

  # Run WITH GEB (cd to temp dir so Claude sees the files)
  if [ "$RUN_GEB" = true ]; then
    echo "  → with GEB..."
    (cd "$TEMP_DIR" && claude -p "$PROMPT" \
      --disable-slash-commands \
      --append-system-prompt "$SKILL_CONTENT" \
      --no-session-persistence \
      --allowed-tools "Read,Edit,Write,Glob,Grep" \
      --model "$MODEL" \
      --max-budget-usd 0.50 \
      2>&1 < /dev/null) > "$SCENARIO_DIR/with-geb.md" || echo "(claude error)" > "$SCENARIO_DIR/with-geb.md"
  fi

  # Run WITHOUT GEB (control)
  if [ "$RUN_CONTROL" = true ]; then
    # Recreate temp dir for clean state
    rm -rf "$TEMP_DIR"
    TEMP_DIR=$(mktemp -d)
    echo "$SCENARIO_DATA" | python3 -c "
import json, sys, os
s = json.load(sys.stdin)
for path, content in s.get('context_files', {}).items():
    full = os.path.join('$TEMP_DIR', path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, 'w') as f:
        f.write(content)
"
    echo "  → control..."
    (cd "$TEMP_DIR" && claude -p "$PROMPT" \
      --disable-slash-commands \
      --no-session-persistence \
      --allowed-tools "Read,Edit,Write,Glob,Grep" \
      --model "$MODEL" \
      --max-budget-usd 0.50 \
      2>&1 < /dev/null) > "$SCENARIO_DIR/control.md" || echo "(claude error)" > "$SCENARIO_DIR/control.md"
  fi

  # Cleanup
  rm -rf "$TEMP_DIR"
done

echo ""
echo "Done. Results in: $RESULTS_DIR"
echo ""
echo "Next step: run the judge"
echo "  bash tests/judge.sh $RESULTS_DIR"
