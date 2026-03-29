# GEB Skill Self-Improvement Mechanism (v3)

> Date: 2026-03-28
> Status: Active
> Supersedes: v1 (16:00), v2 (17:00)

## Problem

GEB's prelude skill shapes Claude's behavior, but we can't measure whether it works, what fails, or how to improve it. Claude can't objectively evaluate a prompt that's shaping its own behavior.

## Key Decisions (from conversation)

### 1. Explicit Activation

Remove auto-start hook. GEB activates only via `/prelude`.

This enables self-improvement: the improvement loop runs in a clean Claude context (no GEB loaded), cleanly separating evaluator from evaluated.

### 2. Autoresearch Pattern

```
modify SKILL.md → run test scenarios → score → keep/discard → repeat
```

One targeted change per iteration. Stop after 3 stalled rounds or 15 max rounds.

### 3. Skill Ecosystem (roadmap, not blocking)

GEB will grow from one skill to three workflow-phase skills:

```
geb:think  → before doing (clarify problem, explore direction)
geb:plan   → after thinking (decompose steps, organize execution)
geb:align  → after doing (check results against original goal)
```

These are orthogonal to the Layer 2 domain modules (research/decision/design/market/review/implement/debug). The skills are workflow phases; the modules are perspectives that skills invoke internally.

```
              research  decision  design  market  implement  debug  review
geb:think       ✓         ✓        ✓       ✓
geb:plan                  ✓                         ✓
geb:align                 ✓        ✓       ✓        ✓         ✓       ✓
```

### 4. User Feedback to Address

- Activation message too sparse ("GEB 已啟動" says nothing)
- GEB too invisible in normal use — can't tell if it's doing anything
- Other installed skills (e.g., superpowers:brainstorming) take over complex tasks instead of GEB

Items 1-2 are SKILL.md quality issues that the improvement loop should fix. Item 3 is architectural (needs skill ecosystem, v0.5+).

## CLI Flags for Test Runner

```bash
# WITH GEB:
claude -p "$prompt" \
  --bare \
  --append-system-prompt "$(cat SKILL.md)" \
  --no-session-persistence \
  --allowed-tools "Read,Edit,Write,Glob,Grep" \
  --model sonnet

# WITHOUT GEB (control):
claude -p "$prompt" \
  --bare \
  --no-session-persistence \
  --allowed-tools "Read,Edit,Write,Glob,Grep" \
  --model sonnet

# JUDGE (no tools needed):
claude -p "$judge_prompt" \
  --bare \
  --no-session-persistence \
  --tools "" \
  --model sonnet

# IMPROVER (strongest model, no tools):
claude -p "$improver_prompt" \
  --bare \
  --no-session-persistence \
  --tools "" \
  --model opus
```

`--bare` ensures clean environment: no hooks, no CLAUDE.md, no other skills.

## Scoring

```
per_scenario = (criteria_passed / total_criteria) * comparison_weight
  BETTER = 1.2 | SAME = 0.8 | WORSE = 0.0

aggregate = mean(all per_scenario scores)
improvement_threshold = candidate > best + 0.01
regression_rule = reject if ANY previously-passing scenario now fails
```

## File Structure

```
tests/
├── scenarios.yml          ← test case definitions
├── run.sh                 ← executes scenarios via claude -p
├── judge-prompt.md        ← scoring template
├── improve-prompt.md      ← improvement proposal template
├── score.py               ← compute aggregate scores from judge output
└── results/               ← timestamped outputs
scripts/
└── improve.sh             ← orchestrator (the autoresearch loop)
```

## Implementation Order

1. Remove auto-hook, update install/uninstall
2. Write 25-30 test scenarios
3. Build runner (run.sh)
4. Build judge (prompt + score.py)
5. Build improver prompt
6. Build orchestrator (improve.sh)
7. Run first baseline + improvement session
