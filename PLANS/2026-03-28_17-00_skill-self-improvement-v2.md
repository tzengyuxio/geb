# GEB Skill Self-Improvement Mechanism (v2)

> Date: 2026-03-28
> Status: Draft
> Supersedes: 2026-03-28_16-00_skill-self-improvement.md

## Problem

GEB's prelude skill shapes Claude's behavior, but we have no systematic way to:
- Know which instructions actually work and which get ignored
- Identify patterns of failure (too verbose? too shallow? wrong depth?)
- Improve the skill without guessing

The fundamental challenge: **Claude can't objectively evaluate a prompt that's currently shaping its own behavior.**

## Key Design Decision: Explicit Activation

**Remove the auto-start hook.** GEB activates only when the user explicitly invokes `/prelude`.

This is not just a UX choice — it's the architectural enabler for self-improvement:

| Mode | GEB loaded? | Role |
|------|-------------|------|
| Normal session (user invokes `/prelude`) | Yes | GEB shapes Claude's behavior |
| Improvement loop | No | Claude evaluates and modifies SKILL.md with clean judgment |
| Test scenario run | Injected via `-p --system-prompt` | Controlled, isolated test |

When GEB is **not** auto-loaded, the improvement loop runs in a **clean Claude context** — no self-evaluation bias. The evaluator and the thing being evaluated are cleanly separated.

### What changes

```
Before (v0):
  hooks/session-start automatically injects SKILL.md at every session start
  → Claude always runs with GEB → can't evaluate itself cleanly

After:
  /prelude is a normal skill, invoked on demand
  → Improvement loop runs without GEB → clean evaluator
  → User decides when GEB is active → more control
```

### Trade-off

The user must type `/prelude` to activate GEB each session. This is acceptable because:
- It's one command, once per session
- It makes GEB's presence conscious, not invisible — which aligns with giving the user control
- It enables the entire self-improvement mechanism
- Auto-activation can be re-added later as an opt-in setting if desired

---

## The Autoresearch Pattern

Inspired by [karpathy/autoresearch](https://github.com/karpathy/autoresearch):

```
autoresearch:  modify train.py → train 5min → measure val_bpb → keep/discard → repeat
GEB:           modify SKILL.md → run scenarios → measure scores → keep/discard → repeat
```

| autoresearch | GEB improve |
|-------------|-------------|
| `train.py` | `SKILL.md` |
| val_bpb (lower = better) | Scenario pass rate + quality scores |
| 5-min training run | Test scenario suite (~30 cases) |
| Single metric, clear direction | Multi-dimensional (depth accuracy, verbosity, silence) |
| Runs overnight, ~100 iterations | Runs on-demand, ~10-20 iterations per session |

### Core Loop

```
┌─────────────────────────────────────────────────────────┐
│  improve.sh                                              │
│                                                          │
│  1. Copy current SKILL.md → workspace                    │
│  2. Run test scenarios → baseline scores                 │
│  3. Loop (max N rounds):                                 │
│     a. Analyze: read scores, identify weakest area       │
│     b. Modify: make ONE targeted change to SKILL.md      │
│     c. Test: run full scenario suite                     │
│     d. Judge: score results                              │
│     e. Compare:                                          │
│        - Improved + no regression → KEEP, log change     │
│        - No improvement → DISCARD, try different angle   │
│        - Regression → REVERT, flag as constraint         │
│     f. Check convergence:                                │
│        - No improvement for K rounds → STOP              │
│  4. Output: final SKILL.md + changelog of all changes    │
│  5. Human reviews and approves                           │
└─────────────────────────────────────────────────────────┘
```

**Critical: the Claude instance running this loop does NOT have GEB loaded.** It reads and modifies SKILL.md as a text file, not as behavioral instructions.

---

## Components

### 1. Test Scenarios (`tests/scenarios.yml`)

The "val_bpb" of this system — the objective measure of skill quality.

```yaml
# Each scenario defines:
- name: simple-rename
  prompt: "Rename the variable `userName` to `user_name` in auth.py"
  context_files:
    auth.py: |
      def get_user(userName: str):
          return db.find(userName)
  expected_depth: fast
  pass_criteria:
    - Executes directly without preamble
    - No mention of framework or depth assessment
    - Pre-code text under 2 sentences
  fail_patterns:
    - "let me think"
    - "before I start"

- name: system-design
  prompt: "I want to redesign our API error handling across all services"
  context_files:
    api/routes.py: "..."
    api/middleware.py: "..."
    services/auth.py: "..."
  expected_depth: slow
  pass_criteria:
    - Asks at least one clarifying question
    - Identifies scope/complexity
    - Does NOT immediately write code
  fail_patterns:
    - Starts with code block
    - "here's the implementation"
```

#### Coverage targets

| Category | Count | Tests |
|----------|-------|-------|
| Fast depth | 5+ | rename, add to gitignore, fix typo, run tests, simple config change |
| Medium depth | 5+ | ambiguous refactor, moderate feature, unclear bug report |
| Slow depth | 5+ | system design, architecture decision, product strategy |
| Silent Rule | 3+ | fast tasks that must have zero framework meta-commentary |
| Dynamic upgrade | 2+ | task that starts simple but reveals hidden complexity |
| Dynamic downgrade | 2+ | task that seems complex but is actually a known pattern |
| Conflicting signals | 2+ | urgent tone + complex scope, casual tone + critical change |
| Universal disciplines | 4 | one per discipline |

Total: **~25-30 scenarios**

### 2. Runner (`tests/run.sh`)

```bash
#!/usr/bin/env bash
# For each scenario:
# 1. Create temp project directory with context files
# 2. Run WITH skill:
#      claude -p "$prompt" \
#        --system-prompt "$(cat skills/prelude/SKILL.md)" \
#        --cwd "$temp_dir" \
#        --allowedTools Read,Edit,Write,Glob,Grep
# 3. Run WITHOUT skill (control):
#      claude -p "$prompt" \
#        --cwd "$temp_dir" \
#        --allowedTools Read,Edit,Write,Glob,Grep
# 4. Save outputs
```

Key: GEB is injected via `--system-prompt`, not via the skill loading mechanism. This gives precise control — the runner itself never has GEB active.

Output structure:
```
tests/results/<timestamp>/
├── meta.yml              ← run config, SKILL.md hash, model used
├── simple-rename/
│   ├── with-geb.md
│   └── control.md
├── system-design/
│   ├── with-geb.md
│   └── control.md
└── ...
```

### 3. Judge (`tests/judge-prompt.md`)

A prompt template for scoring. Run as a separate Claude invocation (no GEB).

```markdown
You are evaluating whether a Claude Code skill improves Claude's behavior.

## Scenario: {{name}}
Expected depth: {{expected_depth}}

## Pass Criteria
{{pass_criteria}}

## Fail Patterns
{{fail_patterns}}

## Response A (with skill)
{{with_geb_output}}

## Response B (without skill)
{{control_output}}

## Instructions

Score each criterion for Response A:
- PASS / FAIL — one sentence explanation

Then compare A vs B:
- BETTER: skill clearly improved behavior
- SAME: no meaningful difference
- WORSE: skill made behavior worse

Output as YAML.
```

#### Aggregate scoring

```
pass_rate = scenarios_passed / total_scenarios
quality_score = weighted average of per-scenario scores
  (Fast scenarios weighted by: brevity, silence, directness)
  (Slow scenarios weighted by: question quality, scope identification, no premature action)
```

### 4. Improver (`tests/improve-prompt.md`)

The prompt for the Claude instance that proposes SKILL.md changes. This is the "agent" in the autoresearch analogy.

```markdown
You are improving a Claude Code skill called GEB.

## Current SKILL.md
{{current_skill_md}}

## Test Results
{{scores_yml}}

## Previous Attempts (this session)
{{changelog}}

## Rules

1. Make ONE targeted change per iteration. Small, specific edits.
2. Focus on the weakest-scoring scenario category.
3. If a previous attempt on the same area was reverted, try a DIFFERENT approach.
4. Do not remove content that is associated with passing tests.
5. Prefer:
   - Adding concrete examples over adding abstract descriptions
   - Tightening language over adding new sections
   - Removing ineffective instructions over rewording them
6. Output the full modified SKILL.md, plus a one-line summary of what you changed and why.
```

### 5. Orchestrator (`scripts/improve.sh`)

```bash
#!/usr/bin/env bash
set -euo pipefail

MAX_ROUNDS=15
STALL_LIMIT=3  # stop after N rounds with no improvement

SKILL="skills/prelude/SKILL.md"
WORKSPACE=$(mktemp -d)
cp "$SKILL" "$WORKSPACE/SKILL.md"

# Baseline
run_tests "$WORKSPACE/SKILL.md" > "$WORKSPACE/baseline.yml"
baseline_score=$(compute_score "$WORKSPACE/baseline.yml")

best_score=$baseline_score
stall_count=0
changelog=""

for round in $(seq 1 $MAX_ROUNDS); do
  echo "=== Round $round ==="

  # Analyze + propose change
  new_skill=$(claude -p "$(render_improve_prompt \
    "$WORKSPACE/SKILL.md" \
    "$WORKSPACE/latest-scores.yml" \
    "$changelog")")

  echo "$new_skill" > "$WORKSPACE/candidate.md"

  # Test candidate
  run_tests "$WORKSPACE/candidate.md" > "$WORKSPACE/candidate-scores.yml"
  candidate_score=$(compute_score "$WORKSPACE/candidate-scores.yml")

  # Compare
  if improved "$candidate_score" "$best_score"; then
    echo "KEEP (score: $best_score → $candidate_score)"
    cp "$WORKSPACE/candidate.md" "$WORKSPACE/SKILL.md"
    best_score=$candidate_score
    stall_count=0
    changelog+="Round $round: KEPT — ..."
  else
    echo "DISCARD (score: $candidate_score, best: $best_score)"
    stall_count=$((stall_count + 1))
    changelog+="Round $round: DISCARDED — ..."
  fi

  # Convergence check
  if [ $stall_count -ge $STALL_LIMIT ]; then
    echo "No improvement for $STALL_LIMIT rounds. Stopping."
    break
  fi
done

# Output
echo "=== Results ==="
echo "Baseline: $baseline_score → Final: $best_score"
diff "$SKILL" "$WORKSPACE/SKILL.md" || true
echo "Review the changes above. Apply? (y/n)"
```

---

## Signal Collection (complementary, not blocking)

The autoresearch loop works without historical signals — it can improve purely from test scenarios. But accumulated user feedback makes it smarter over time.

### During normal use

Add to SKILL.md:
```
When the user overrides your depth assessment or corrects your behavioral approach,
append a line to ~/.geb/feedback.log (create if not exists):

YYYY-MM-DD | override-down | "just do it" after I started analyzing | was:medium | should:fast
```

### During improvement loop

If `~/.geb/feedback.log` exists, include it in the improver prompt as additional signal:
```markdown
## User Feedback (accumulated from real sessions)
{{feedback_log}}

Use this to prioritize which areas to improve. Recurring patterns = high priority.
```

---

## Scoring Design

### Per-scenario score

```
scenario_score = (criteria_passed / total_criteria) * comparison_weight

comparison_weight:
  BETTER = 1.2  (skill adds value)
  SAME   = 0.8  (skill doesn't help — slightly negative, it's wasting tokens)
  WORSE  = 0.0  (skill hurts)
```

`SAME` gets 0.8 not 1.0 because: if the skill doesn't change behavior on a scenario, those instructions are wasting context window tokens for no benefit. Marginal pressure toward conciseness.

### Aggregate score

```
total_score = mean(all scenario_scores)
```

Improvement threshold: `candidate_score > best_score + 0.01` (avoid noise-driven changes).

### Regression check

A candidate is **rejected if any previously-passing scenario now fails**, even if the aggregate score improves. This prevents "improving average by sacrificing specific behaviors."

---

## Convergence & Stopping

The loop stops when:
1. **Stall**: No improvement for K consecutive rounds (default K=3)
2. **Max rounds**: Hard cap at N iterations (default N=15)
3. **Perfect score**: All scenarios pass with BETTER rating (unlikely but theoretically possible)

After stopping, the system outputs:
- Final SKILL.md (in workspace, not yet applied)
- Full diff from original
- Changelog: what was tried, what was kept, what was discarded
- Score progression: baseline → round 1 → round 2 → ... → final

---

## File Structure

```
/Users/user/works/geb/
├── skills/
│   └── prelude/
│       └── SKILL.md                ← the skill being improved
├── tests/
│   ├── scenarios.yml               ← test case definitions
│   ├── run.sh                      ← runner: executes scenarios, captures output
│   ├── judge-prompt.md             ← judge prompt template
│   ├── improve-prompt.md           ← improver prompt template
│   └── results/                    ← timestamped test results
│       └── <timestamp>/
│           ├── meta.yml
│           ├── scores.yml
│           └── <scenario-name>/
│               ├── with-geb.md
│               └── control.md
├── scripts/
│   └── improve.sh                  ← orchestrator: the autoresearch loop
└── ~/.geb/
    └── feedback.log                ← cross-project user feedback (optional)
```

---

## Implementation Order

### Phase 1: Foundation

1. **Remove auto-start hook** — change install.sh to not install hooks, keep `/prelude` as explicit skill
2. **Write test scenarios** — 25-30 cases covering all depth levels and behaviors
3. **Build runner** — script that runs scenarios via `claude -p` with/without skill injection

### Phase 2: Evaluation

4. **Build judge** — prompt template + script that scores outputs
5. **Define scoring** — implement `compute_score` with the formula above
6. **Run first baseline** — see where the current SKILL.md stands

### Phase 3: The Loop

7. **Build improver prompt** — the prompt that proposes SKILL.md changes
8. **Build orchestrator** — `improve.sh` that ties everything together
9. **Run first improvement session** — aim for 10-15 rounds, see what happens

### Phase 4: Polish

10. **Add feedback collection** — logging instruction in SKILL.md
11. **Integrate feedback into improver** — use accumulated signals to prioritize
12. **Track history** — version log of SKILL.md evolution with rationale

---

## Open Questions

1. **`claude -p` fidelity**: Print mode behavior may differ from interactive. Validate by manually comparing a few scenarios. If divergence is significant, consider using `claude` with `--yes` flag or a controlled interactive approach.

2. **Cost per run**: ~30 scenarios × 2 (with/without) × judge = ~90 API calls per iteration. At 15 iterations = ~1350 calls per improvement session. Acceptable for periodic optimization, not for continuous use. Consider using a faster/cheaper model for the runner and judge.

3. **Scenario maintenance**: As SKILL.md evolves, test scenarios need to evolve too. Who updates them — human or the loop itself? Start with human-maintained; consider auto-generated scenarios in Phase 4.

4. **Multi-dimensional scoring**: Current design uses a single aggregate score. Real-world behavior has trade-offs (brevity vs helpfulness). May need Pareto-style evaluation in the future.

5. **Judge model**: Should the judge be the same model as the runner? Using a different model (or multiple judges) could reduce bias.
