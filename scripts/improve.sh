#!/usr/bin/env bash
#
# GEB Self-Improvement Loop (autoresearch pattern)
#
# Iteratively improves SKILL.md by:
#   1. Running test scenarios → baseline scores
#   2. Proposing one targeted change
#   3. Testing the change
#   4. Keeping or discarding based on score comparison
#   5. Repeating until convergence
#
# Usage:
#   bash scripts/improve.sh                        # improve prelude (default)
#   bash scripts/improve.sh --target geb:think     # improve a specific skill
#   bash scripts/improve.sh --max-rounds 10
#   bash scripts/improve.sh --stall-limit 5
#   bash scripts/improve.sh --baseline tests/results/20260328-180332
#   bash scripts/improve.sh --dry-run
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TESTS_DIR="$PROJECT_DIR/tests"
TARGET_SKILL="${TARGET_SKILL:-prelude}"
IMPROVE_TEMPLATE="$TESTS_DIR/improve-prompt.md"

# Defaults
MAX_ROUNDS=${MAX_ROUNDS:-15}
STALL_LIMIT=${STALL_LIMIT:-3}
RUNNER_MODEL=${RUNNER_MODEL:-sonnet}
JUDGE_MODEL=${JUDGE_MODEL:-sonnet}
IMPROVE_MODEL=${IMPROVE_MODEL:-opus}
IMPROVEMENT_THRESHOLD=0.01
MAX_REGRESSION_RATIO=${MAX_REGRESSION_RATIO:-0.10}  # allow up to 10% of scenarios to regress
MIN_IMPROVEMENT_FOR_REGRESSION=0.05                  # only if overall improvement > 5%
DRY_RUN=false
EXISTING_BASELINE=""

# Feedback file (optional, from real usage)
FEEDBACK_FILE="$HOME/.geb/feedback.log"

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --max-rounds) MAX_ROUNDS="$2"; shift 2 ;;
    --stall-limit) STALL_LIMIT="$2"; shift 2 ;;
    --runner-model) RUNNER_MODEL="$2"; shift 2 ;;
    --judge-model) JUDGE_MODEL="$2"; shift 2 ;;
    --improve-model) IMPROVE_MODEL="$2"; shift 2 ;;
    --baseline) EXISTING_BASELINE="$2"; shift 2 ;;
    --target) TARGET_SKILL="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Resolve skill file path from target name
SKILL_FILE="$PROJECT_DIR/skills/$TARGET_SKILL/SKILL.md"
if [ ! -f "$SKILL_FILE" ]; then
  echo "Error: SKILL.md not found for target '$TARGET_SKILL': $SKILL_FILE"
  exit 1
fi

# Session workspace
SESSION_ID=$(date +%Y%m%d-%H%M%S)
WORKSPACE="$TESTS_DIR/results/improve-$SESSION_ID"
mkdir -p "$WORKSPACE"

echo "╔════════════════════════════════════════════════════╗"
echo "║  GEB Self-Improvement Loop                        ║"
echo "╠════════════════════════════════════════════════════╣"
echo "║  Max rounds:     $MAX_ROUNDS"
echo "║  Stall limit:    $STALL_LIMIT"
echo "║  Runner model:   $RUNNER_MODEL"
echo "║  Judge model:    $JUDGE_MODEL"
echo "║  Improver model: $IMPROVE_MODEL"
echo "║  Target skill:   $TARGET_SKILL"
echo "║  Skill file:     $SKILL_FILE"
echo "║  Workspace:      $WORKSPACE"
echo "╚════════════════════════════════════════════════════╝"
echo ""

# Copy original SKILL.md
cp "$SKILL_FILE" "$WORKSPACE/original-SKILL.md"
cp "$SKILL_FILE" "$WORKSPACE/current-SKILL.md"

# Load feedback if available
FEEDBACK_CONTENT=""
if [ -f "$FEEDBACK_FILE" ]; then
  FEEDBACK_CONTENT=$(cat "$FEEDBACK_FILE")
  echo "Loaded user feedback from $FEEDBACK_FILE"
fi

# Helper: find latest timestamped results dir (exclude improve-* dirs)
find_latest_run() {
  ls -td "$TESTS_DIR/results"/[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-* 2>/dev/null | grep -v 'improve-' | head -1
}

# Helper: copy control results from source to target run directory
merge_control_results() {
  local source_dir="$1"
  local target_dir="$2"
  for scenario_dir in "$source_dir"/*/; do
    local scenario_name
    scenario_name=$(basename "$scenario_dir")
    if [ -f "$scenario_dir/control.md" ]; then
      cp "$scenario_dir/control.md" "$target_dir/$scenario_name/control.md" 2>/dev/null || true
    fi
  done
}

# Helper: build improver prompt using temp files (avoids shell escaping issues)
build_improve_prompt() {
  local skill_file="$1"
  local scores_file="$2"
  local changelog_file="$3"
  local feedback_file="$4"

  python3 - "$IMPROVE_TEMPLATE" "$skill_file" "$scores_file" "$changelog_file" "$feedback_file" <<'PYEOF'
import sys

template_path, skill_path, scores_path, changelog_path, feedback_path = sys.argv[1:6]

template = open(template_path).read()
skill_md = open(skill_path).read()
scores = open(scores_path).read()

try:
    changelog = open(changelog_path).read().strip() or "No previous attempts yet."
except FileNotFoundError:
    changelog = "No previous attempts yet."

try:
    feedback = open(feedback_path).read().strip() or "No user feedback available."
except FileNotFoundError:
    feedback = "No user feedback available."

result = template
result = result.replace("{{skill_md}}", skill_md)
result = result.replace("{{scores}}", scores)
result = result.replace("{{changelog}}", changelog)
result = result.replace("{{feedback}}", feedback)
print(result)
PYEOF
}

# ── Baseline ──────────────────────────────────────────────

CONTROL_RUN=""

if [ -n "$EXISTING_BASELINE" ]; then
  echo "Using existing baseline: $EXISTING_BASELINE"
  LATEST_RUN="$EXISTING_BASELINE"

  if [ ! -f "$LATEST_RUN/scores.yml" ]; then
    echo "Error: no scores.yml in baseline dir. Run judge first."
    exit 1
  fi
else
  echo "═══ Baseline Run ═══"

  echo "Running GEB scenarios for $TARGET_SKILL..."
  env MODEL="$RUNNER_MODEL" \
    bash "$TESTS_DIR/run.sh" --skill "$WORKSPACE/current-SKILL.md" --filter-skill "$TARGET_SKILL" --geb-only 2>&1 | tail -5

  LATEST_RUN=$(find_latest_run)
  if [ -z "$LATEST_RUN" ]; then
    echo "Error: no results found after baseline run"
    exit 1
  fi

  echo "Running control scenarios for $TARGET_SKILL..."
  env MODEL="$RUNNER_MODEL" \
    bash "$TESTS_DIR/run.sh" --filter-skill "$TARGET_SKILL" --control-only 2>&1 | tail -5
  CONTROL_RUN=$(find_latest_run)

  merge_control_results "$CONTROL_RUN" "$LATEST_RUN"

  echo "Judging baseline..."
  env JUDGE_MODEL="$JUDGE_MODEL" \
    bash "$TESTS_DIR/judge.sh" "$LATEST_RUN" 2>&1 | tail -3
fi

# Score baseline
BASELINE_SCORE=$(python3 "$TESTS_DIR/score.py" "$LATEST_RUN/scores.yml" --json \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['aggregate_score'])")

cp "$LATEST_RUN/scores.yml" "$WORKSPACE/baseline-scores.yml"

# Find or set control run for later reuse
if [ -z "$CONTROL_RUN" ]; then
  # When using existing baseline, control results are already merged in
  CONTROL_RUN="$LATEST_RUN"
fi

echo ""
echo "Baseline score: $BASELINE_SCORE"
echo ""

# ── Improvement Loop ─────────────────────────────────────

BEST_SCORE=$BASELINE_SCORE
STALL_COUNT=0
CHANGELOG_FILE="$WORKSPACE/changelog.txt"
touch "$CHANGELOG_FILE"

# Save feedback to a file for the prompt builder
FEEDBACK_TMP="$WORKSPACE/feedback.txt"
echo "$FEEDBACK_CONTENT" > "$FEEDBACK_TMP"

LAST_ROUND=0

for ROUND in $(seq 1 "$MAX_ROUNDS"); do
  LAST_ROUND=$ROUND
  echo "═══ Round $ROUND / $MAX_ROUNDS (best: $BEST_SCORE, stall: $STALL_COUNT/$STALL_LIMIT) ═══"

  # Pick scores file: latest if available, otherwise baseline
  SCORES_FILE="$WORKSPACE/latest-scores.yml"
  if [ ! -f "$SCORES_FILE" ]; then
    SCORES_FILE="$WORKSPACE/baseline-scores.yml"
  fi

  # Build improver prompt via temp files
  IMPROVE_PROMPT=$(build_improve_prompt \
    "$WORKSPACE/current-SKILL.md" \
    "$SCORES_FILE" \
    "$CHANGELOG_FILE" \
    "$FEEDBACK_TMP")

  if [ "$DRY_RUN" = true ]; then
    echo "  [DRY RUN] Would call improver with ${#IMPROVE_PROMPT} chars"
    break
  fi

  # Write prompt to temp file and pipe to claude (avoids argument length issues)
  PROMPT_TMP=$(mktemp)
  echo "$IMPROVE_PROMPT" > "$PROMPT_TMP"

  # Call improver
  echo "  → Proposing change..."
  IMPROVER_OUTPUT=$(claude -p "$(cat "$PROMPT_TMP")" \
    --disable-slash-commands \
    --no-session-persistence \
    --tools "" \
    --model "$IMPROVE_MODEL" \
    --max-budget-usd 1.00 \
    2>&1 < /dev/null)
  rm -f "$PROMPT_TMP"

  # Save raw improver output
  echo "$IMPROVER_OUTPUT" > "$WORKSPACE/round-${ROUND}-proposal.md"

  # Extract change summary
  CHANGE_SUMMARY=$(echo "$IMPROVER_OUTPUT" | grep "^CHANGE_SUMMARY:" | head -1 | sed 's/^CHANGE_SUMMARY:[[:space:]]*//')
  TARGET_CATEGORY=$(echo "$IMPROVER_OUTPUT" | grep "^TARGET_CATEGORY:" | head -1 | sed 's/^TARGET_CATEGORY:[[:space:]]*//')

  if [ -z "$CHANGE_SUMMARY" ]; then
    CHANGE_SUMMARY="(could not parse summary)"
  fi

  echo "  Change: $CHANGE_SUMMARY"
  echo "  Target: $TARGET_CATEGORY"

  # Extract new SKILL.md
  NEW_SKILL=$(echo "$IMPROVER_OUTPUT" | sed -n '/---SKILL_MD_START---/,/---SKILL_MD_END---/p' | sed '1d;$d')

  if [ -z "$NEW_SKILL" ]; then
    echo "  ✗ Failed to extract SKILL.md from improver output. Skipping round."
    STALL_COUNT=$((STALL_COUNT + 1))
    echo "Round $ROUND: SKIPPED — improver output malformed" >> "$CHANGELOG_FILE"
    continue
  fi

  # Save candidate
  echo "$NEW_SKILL" > "$WORKSPACE/candidate-SKILL.md"

  # Test candidate
  echo "  → Testing candidate..."
  env MODEL="$RUNNER_MODEL" \
    bash "$TESTS_DIR/run.sh" --skill "$WORKSPACE/candidate-SKILL.md" --filter-skill "$TARGET_SKILL" --geb-only 2>&1 | tail -3

  CANDIDATE_RUN=$(find_latest_run)

  merge_control_results "$CONTROL_RUN" "$CANDIDATE_RUN"

  # Judge candidate
  echo "  → Judging candidate..."
  env JUDGE_MODEL="$JUDGE_MODEL" \
    bash "$TESTS_DIR/judge.sh" "$CANDIDATE_RUN" 2>&1 | tail -3

  # Score candidate
  CANDIDATE_SUMMARY=$(python3 "$TESTS_DIR/score.py" "$CANDIDATE_RUN/scores.yml" --baseline "$WORKSPACE/baseline-scores.yml" --json)
  CANDIDATE_SCORE=$(echo "$CANDIDATE_SUMMARY" | python3 -c "import json,sys; print(json.load(sys.stdin)['aggregate_score'])")
  REGRESSIONS=$(echo "$CANDIDATE_SUMMARY" | python3 -c "import json,sys; r=json.load(sys.stdin)['regressions']; print(','.join(r) if r else '')")

  cp "$CANDIDATE_RUN/scores.yml" "$WORKSPACE/latest-scores.yml"

  # Compare
  IMPROVED=$(python3 -c "print('true' if $CANDIDATE_SCORE > $BEST_SCORE + $IMPROVEMENT_THRESHOLD else 'false')")

  # Count regressions
  REGRESSION_COUNT=0
  if [ -n "$REGRESSIONS" ]; then
    REGRESSION_COUNT=$(echo "$REGRESSIONS" | tr ',' '\n' | wc -l | tr -d ' ')
  fi

  # Relaxed regression rule: allow up to MAX_REGRESSION_RATIO of total scenarios if improvement is significant
  TOTAL_SCENARIOS=$(echo "$CANDIDATE_SUMMARY" | python3 -c "import json,sys; print(json.load(sys.stdin)['total_scenarios'])")
  MAX_REGRESSIONS=$(python3 -c "import math; print(math.floor($TOTAL_SCENARIOS * $MAX_REGRESSION_RATIO))")
  SCORE_DELTA=$(python3 -c "print(round($CANDIDATE_SCORE - $BEST_SCORE, 4))")
  ACCEPTABLE_REGRESSION=$(python3 -c "print('true' if $REGRESSION_COUNT <= $MAX_REGRESSIONS and $CANDIDATE_SCORE > $BEST_SCORE + $MIN_IMPROVEMENT_FOR_REGRESSION else 'false')")

  if [ "$REGRESSION_COUNT" -gt 0 ] && [ "$ACCEPTABLE_REGRESSION" = "false" ]; then
    echo "  ✗ REVERT — $REGRESSION_COUNT regressions, improvement insufficient (score: $CANDIDATE_SCORE, delta: $SCORE_DELTA)"
    echo "    Regressions: $REGRESSIONS"
    STALL_COUNT=$((STALL_COUNT + 1))
    echo "Round $ROUND: REVERTED — $CHANGE_SUMMARY [regressions($REGRESSION_COUNT): $REGRESSIONS, score: $CANDIDATE_SCORE]" >> "$CHANGELOG_FILE"
  elif [ "$REGRESSION_COUNT" -gt 0 ] && [ "$ACCEPTABLE_REGRESSION" = "true" ]; then
    echo "  ✓ KEEP (with $REGRESSION_COUNT regressions) — improved: $BEST_SCORE → $CANDIDATE_SCORE (delta: $SCORE_DELTA)"
    echo "    Accepted regressions: $REGRESSIONS"
    cp "$WORKSPACE/candidate-SKILL.md" "$WORKSPACE/current-SKILL.md"
    cp "$WORKSPACE/candidate-SKILL.md" "$WORKSPACE/round-${ROUND}-kept.md"
    BEST_SCORE=$CANDIDATE_SCORE
    STALL_COUNT=0
    echo "Round $ROUND: KEPT (${REGRESSION_COUNT} regressions accepted) — $CHANGE_SUMMARY [score: $BEST_SCORE]" >> "$CHANGELOG_FILE"
  elif [ "$IMPROVED" = "true" ]; then
    echo "  ✓ KEEP — improved: $BEST_SCORE → $CANDIDATE_SCORE"
    cp "$WORKSPACE/candidate-SKILL.md" "$WORKSPACE/current-SKILL.md"
    cp "$WORKSPACE/candidate-SKILL.md" "$WORKSPACE/round-${ROUND}-kept.md"
    BEST_SCORE=$CANDIDATE_SCORE
    STALL_COUNT=0
    echo "Round $ROUND: KEPT — $CHANGE_SUMMARY [score: $BEST_SCORE]" >> "$CHANGELOG_FILE"
  else
    echo "  ~ DISCARD — no significant improvement (score: $CANDIDATE_SCORE, best: $BEST_SCORE)"
    STALL_COUNT=$((STALL_COUNT + 1))
    echo "Round $ROUND: DISCARDED — $CHANGE_SUMMARY [score: $CANDIDATE_SCORE]" >> "$CHANGELOG_FILE"
  fi

  # Convergence check
  if [ "$STALL_COUNT" -ge "$STALL_LIMIT" ]; then
    echo ""
    echo "No improvement for $STALL_LIMIT consecutive rounds. Stopping."
    break
  fi

  echo ""
done

# ── Report ────────────────────────────────────────────────

echo ""
echo "╔════════════════════════════════════════════════════╗"
echo "║  Improvement Session Complete                     ║"
echo "╠════════════════════════════════════════════════════╣"
echo "║  Baseline:  $BASELINE_SCORE"
echo "║  Final:     $BEST_SCORE"
echo "║  Rounds:    $LAST_ROUND"
echo "╚════════════════════════════════════════════════════╝"
echo ""

# Show changelog
echo "── Changelog ──"
cat "$CHANGELOG_FILE"
echo ""

# Show diff
if ! diff -q "$WORKSPACE/original-SKILL.md" "$WORKSPACE/current-SKILL.md" > /dev/null 2>&1; then
  echo "── Changes ──"
  diff -u "$WORKSPACE/original-SKILL.md" "$WORKSPACE/current-SKILL.md" || true
  echo ""
  echo "Improved SKILL.md saved to: $WORKSPACE/current-SKILL.md"
  echo ""
  echo "To apply:"
  echo "  cp $WORKSPACE/current-SKILL.md $SKILL_FILE"
else
  echo "No improvements found. SKILL.md unchanged."
fi
