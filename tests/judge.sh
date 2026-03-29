#!/usr/bin/env bash
#
# GEB Judge
#
# Scores test results by sending each scenario to a judge Claude instance.
# Reads results from a run directory, outputs scores.yml.
#
# Usage:
#   bash tests/judge.sh tests/results/<timestamp>
#   bash tests/judge.sh tests/results/<timestamp> --scenario rename-variable
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
JUDGE_TEMPLATE="$SCRIPT_DIR/judge-prompt.md"
MODEL="${JUDGE_MODEL:-sonnet}"

if [ $# -lt 1 ]; then
  echo "Usage: bash tests/judge.sh <results-dir> [--scenario <name>]"
  exit 1
fi

RESULTS_DIR="$1"
shift

FILTER_SCENARIO=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --scenario) FILTER_SCENARIO="$2"; shift 2 ;;
    --model) MODEL="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [ ! -d "$RESULTS_DIR" ]; then
  echo "Error: results directory not found: $RESULTS_DIR"
  exit 1
fi

SCORES_FILE="$RESULTS_DIR/scores.yml"
echo "# GEB Judge Scores — $(date -Iseconds)" > "$SCORES_FILE"
echo "# Model: $MODEL" >> "$SCORES_FILE"
echo "scenarios:" >> "$SCORES_FILE"

SCENARIO_DIRS=$(find "$RESULTS_DIR" -mindepth 1 -maxdepth 1 -type d | sort)
TOTAL=$(echo "$SCENARIO_DIRS" | wc -l | tr -d ' ')
CURRENT=0

for SCENARIO_DIR in $SCENARIO_DIRS; do
  SCENARIO_NAME=$(basename "$SCENARIO_DIR")

  if [ -n "$FILTER_SCENARIO" ] && [ "$SCENARIO_NAME" != "$FILTER_SCENARIO" ]; then
    continue
  fi

  # Skip if missing required files
  if [ ! -f "$SCENARIO_DIR/with-geb.md" ] || [ ! -f "$SCENARIO_DIR/control.md" ]; then
    echo "  Skipping $SCENARIO_NAME (missing output files)"
    continue
  fi

  CURRENT=$((CURRENT + 1))
  echo "[$CURRENT/$TOTAL] Judging: $SCENARIO_NAME"

  # Extract skill/category for scores.yml (simple grep, no python needed)
  SKILL=$(grep '^skill:' "$SCENARIO_DIR/scenario.yml" | head -1 | cut -d' ' -f2-)
  SKILL="${SKILL:-prelude}"
  CATEGORY=$(grep '^category:' "$SCENARIO_DIR/scenario.yml" | head -1 | cut -d' ' -f2-)

  # Build judge prompt — single Python call handles all template substitution
  FULL_PROMPT=$(python3 -c "
import sys
template = open('$JUDGE_TEMPLATE').read()
with_geb = open('$SCENARIO_DIR/with-geb.md').read()
control = open('$SCENARIO_DIR/control.md').read()
scenario = open('$SCENARIO_DIR/scenario.yml').read()

# Extract fields
import re
category = ''
prompt_text = ''
skill = 'prelude'
pass_criteria = ''
fail_patterns = ''

for line in scenario.split('\n'):
    if line.startswith('category:'):
        category = line.split(': ', 1)[1].strip()
    elif line.startswith('prompt:'):
        prompt_text = line.split(': ', 1)[1].strip()
    elif line.startswith('skill:'):
        skill = line.split(': ', 1)[1].strip()

in_pass = False
in_fail = False
for line in scenario.split('\n'):
    if line.startswith('pass_criteria:'):
        in_pass = True; in_fail = False; continue
    elif line.startswith('fail_patterns:'):
        in_fail = True; in_pass = False; continue
    elif not line.startswith('  '):
        in_pass = False; in_fail = False
    if in_pass:
        pass_criteria += line + '\n'
    if in_fail:
        fail_patterns += line + '\n'

result = template
result = result.replace('{{name}}', '$SCENARIO_NAME')
result = result.replace('{{skill}}', skill)
result = result.replace('{{category}}', category)
result = result.replace('{{prompt}}', prompt_text)
result = result.replace('{{pass_criteria}}', pass_criteria.strip())
result = result.replace('{{fail_patterns}}', fail_patterns.strip())
result = result.replace('{{with_geb}}', with_geb)
result = result.replace('{{control}}', control)
print(result)
")

  # Run judge
  JUDGE_OUTPUT=$(claude -p "$FULL_PROMPT" \
    --disable-slash-commands \
    --no-session-persistence \
    --tools "" \
    --model "$MODEL" \
    --max-budget-usd 0.25 \
    2>&1 < /dev/null || echo "judge_error: true")

  # Save individual judge output
  echo "$JUDGE_OUTPUT" > "$SCENARIO_DIR/judge.yml"

  # Append to aggregate scores
  echo "" >> "$SCORES_FILE"
  echo "  - name: $SCENARIO_NAME" >> "$SCORES_FILE"
  echo "    skill: $SKILL" >> "$SCORES_FILE"
  echo "    category: $CATEGORY" >> "$SCORES_FILE"
  echo "    judge_output: |" >> "$SCORES_FILE"
  echo "$JUDGE_OUTPUT" | sed 's/^/      /' >> "$SCORES_FILE"

done

echo ""
echo "Scores saved to: $SCORES_FILE"
echo ""
echo "Compute aggregate score:"
echo "  python3 tests/score.py $SCORES_FILE"
