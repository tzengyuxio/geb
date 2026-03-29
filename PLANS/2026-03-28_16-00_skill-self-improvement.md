# GEB Skill Self-Improvement Mechanism

> Date: 2026-03-28
> Status: Draft

## Problem

GEB's prelude skill shapes Claude's behavior, but we have no way to know:
- Is it actually working? Which instructions does Claude follow, which does it ignore?
- When it fails, what pattern of failure is it? (too verbose on simple tasks? too shallow on complex ones?)
- How do we improve it without guessing?

The fundamental challenge: **Claude can't objectively evaluate a prompt that's currently shaping its own behavior.** We need an external feedback loop.

## Design: The Improvement Loop

```
Collect signals → Evaluate with tests → Analyze patterns → Propose changes → Validate → Apply
   (continuous)      (on-demand)          (automated)        (automated)     (automated)  (human)
```

### Key Constraint

**Human-in-the-loop for application.** The loop automates everything except the final decision. SKILL.md changes always require user approval.

---

## 1. Signal Collection (continuous, passive)

During normal GEB-powered sessions, certain user behaviors are implicit feedback about the skill's effectiveness:

### Signal Types

| Signal | Example | What it means |
|--------|---------|---------------|
| **Depth override (down)** | User says "just do it" after Claude starts analyzing | Depth was too high — skill over-triggered Slow mode |
| **Depth override (up)** | User says "think more" after Claude rushed to code | Depth was too low — skill missed complexity signals |
| **Behavioral correction** | "don't explain, just do" or "you should have asked first" | Specific instruction in SKILL.md isn't calibrated right |
| **Explicit feedback** | "the skill is too verbose" / "I like how you handled that" | Direct user input about effectiveness |
| **Silent acceptance** | User proceeds without correction after a Medium/Slow response | Positive signal — depth was appropriate |

### Collection Mechanism

Add to SKILL.md a lightweight logging instruction:

```
When the user corrects your depth assessment or behavioral approach,
append a one-line entry to ~/.geb/feedback.log:

  YYYY-MM-DD | <signal_type> | <user_message_summary> | <your_depth_was> | <depth_should_have_been>
```

`~/.geb/` (in user home, not project) serves as a cross-project feedback store. This is separate from the per-project `.geb/` state directory.

### Why not the memory system?

The memory system (`~/.claude/projects/.../memory/`) is designed for curated, high-value memories. Skill feedback is high-volume, low-signal-per-entry data — better suited to a log file that gets batch-analyzed, not individual memory entries.

---

## 2. Test Scenarios (evaluation)

A defined set of test cases that represent the skill's expected behavior across the depth spectrum.

### Format

```yaml
# tests/scenarios.yml

- name: simple-rename
  prompt: "Rename the variable `userName` to `user_name` in auth.py"
  context:
    files:
      auth.py: |
        def get_user(userName: str):
            return db.find(userName)
  expected_depth: fast
  pass_criteria:
    - Executes directly without planning preamble
    - No mention of depth assessment or framework
    - Response text before code is under 2 sentences
  fail_patterns:
    - "let me think"
    - "let me analyze"
    - "before I start"
    - "I'll plan"

- name: ambiguous-refactor
  prompt: "This auth module is getting messy, can you clean it up?"
  context:
    files:
      auth.py: "(200-line file with mixed concerns)"
  expected_depth: medium
  pass_criteria:
    - One-sentence confirmation of approach before proceeding
    - Does not launch into multi-paragraph analysis
    - Does not silently start rewriting without confirmation
  fail_patterns:
    - Starts immediately rewriting code (too fast)
    - Writes 3+ paragraphs of analysis (too slow)

- name: system-design
  prompt: "I want to redesign our API error handling across all services"
  context:
    files: "(multiple service files)"
  expected_depth: slow
  pass_criteria:
    - Asks at least one clarifying question before starting
    - Identifies the scope/complexity of the task
    - Does NOT immediately start writing code
  fail_patterns:
    - Starts with a code block
    - "here's the implementation"
    - Makes assumptions about scope without checking

- name: silent-rule-check
  prompt: "add .env to .gitignore"
  context:
    files:
      .gitignore: "node_modules/\n"
  expected_depth: fast
  pass_criteria:
    - Just does it
    - No mention of GEB, depth, framework, or thinking mode
    - Total response under 50 words
  fail_patterns:
    - "I've assessed this as"
    - "this is a fast task"
    - mentions the framework by name

- name: dynamic-upgrade
  prompt: "change the button color to blue"
  context:
    files:
      # Button is used in 15 places with theme system
      Button.tsx: "(component with theme tokens)"
      theme.ts: "(design token system)"
      # ...14 more files importing Button
  expected_depth: starts-fast-upgrades-to-medium
  pass_criteria:
    - Starts to execute, then discovers scope is larger than expected
    - Suggests or mentions the broader impact
  fail_patterns:
    - Silently changes only one file ignoring theme system
    - Launches into full architecture analysis from the start
```

### Coverage

Test scenarios should cover:
- Each depth level (Fast / Medium / Slow) — at least 3 cases each
- Dynamic upgrade and downgrade — at least 2 cases each
- The Silent Rule — at least 2 cases
- Universal disciplines — at least 1 case each
- Edge cases: conflicting signals (urgent tone + complex scope)

Target: **20-30 scenarios** for meaningful coverage.

---

## 3. Runner

A script that executes test scenarios and captures outputs.

```bash
# tests/run.sh

# For each scenario:
# 1. Create a temp directory with the scenario's context files
# 2. Run with GEB active:
#      claude -p "prompt" --allowedTools Edit,Read,Write
# 3. Run without GEB (control):
#      claude -p "prompt" --allowedTools Edit,Read,Write --skill-disable prelude
# 4. Save both outputs to tests/results/<timestamp>/<scenario-name>/
```

Each run produces:
```
tests/results/2026-03-28/
├── simple-rename/
│   ├── with-geb.md       ← Claude's response with skill active
│   └── without-geb.md    ← Claude's response without skill (control)
├── system-design/
│   ├── with-geb.md
│   └── without-geb.md
└── ...
```

### Limitations

- `claude -p` (print mode) may behave differently from interactive sessions
- Tool use simulation is limited
- Some scenarios (dynamic upgrade) are hard to trigger in non-interactive mode

Mitigation: Focus test scenarios on initial response behavior (first message), which is more predictable in print mode.

---

## 4. Judge

A separate Claude invocation that scores outputs against criteria. This is the "LLM-as-judge" pattern.

```bash
# tests/judge.sh

# For each scenario result:
claude -p "$(cat <<EOF
You are evaluating a Claude Code skill's effectiveness.

## Scenario
Name: ${scenario_name}
Expected depth: ${expected_depth}

## Criteria
${pass_criteria}

## Anti-patterns
${fail_patterns}

## Claude's Response (with skill)
${with_geb_output}

## Claude's Response (without skill, control)
${without_geb_output}

## Score

For each criterion, output:
- PASS / FAIL
- Brief explanation (1 sentence)

Then output an overall assessment:
- EFFECTIVE: skill clearly improved behavior vs control
- NEUTRAL: no meaningful difference
- HARMFUL: skill made behavior worse
- UNCLEAR: can't determine from this scenario
EOF
)"
```

### Output Format

```yaml
# tests/results/2026-03-28/scores.yml

- scenario: simple-rename
  criteria:
    - name: "Executes directly"
      result: PASS
      note: "Response was 1 sentence + code edit"
    - name: "No framework mention"
      result: PASS
      note: "No meta-commentary"
  overall: EFFECTIVE
  comparison: "Without skill, Claude added 2 paragraphs of explanation before editing"

- scenario: system-design
  criteria:
    - name: "Asks clarifying question"
      result: FAIL
      note: "Jumped straight to proposing 3 approaches without understanding scope"
  overall: NEUTRAL
  comparison: "Both with and without skill produced similar behavior"
```

---

## 5. Analysis

Reads all available signals and produces improvement proposals.

### Inputs
- `~/.geb/feedback.log` (accumulated user corrections)
- `tests/results/latest/scores.yml` (latest test results)
- `skills/prelude/SKILL.md` (current skill)

### Process

```
1. Group feedback signals by category:
   - Over-triggered Slow (depth too high)
   - Under-triggered Slow (depth too low)
   - Too verbose
   - Too terse
   - Specific behavioral issues

2. Cross-reference with test results:
   - Which SKILL.md sections are test scenarios failing on?
   - Which sections have no test coverage?

3. For each identified issue, propose a specific SKILL.md edit:
   - Quote the current text
   - Propose replacement
   - Cite the signals/test-results that justify the change
   - Rate confidence: HIGH (clear pattern) / MEDIUM (some signal) / LOW (hypothesis)
```

### Output

```markdown
# Improvement Proposal — 2026-03-28

## Issue 1: Slow mode triggers too easily on imperative requests with moderate scope
- **Evidence**: 5 feedback signals of depth-override-down; test "ambiguous-refactor" scored HARMFUL
- **Current SKILL.md** (line 41): "Most tasks fall in between — use judgment"
- **Proposed change**: Add explicit rule: "When user tone is imperative, bias toward Fast even if scope is moderate. Imperative tone is a stronger signal than scope ambiguity."
- **Confidence**: HIGH

## Issue 2: ...
```

---

## 6. Validation

Before presenting proposals to the user, verify they don't break things.

1. Apply proposed changes to a copy of SKILL.md
2. Re-run the full test suite against the modified version
3. Compare scores:
   - **Improved**: the targeted test cases now pass
   - **No regression**: previously-passing tests still pass
   - **Regressed**: some previously-passing tests now fail → flag for review

Only surface proposals where: targeted improvement AND no regression.

---

## 7. Application (human-in-the-loop)

Present to user:
- Diff of proposed SKILL.md changes
- Evidence that drove each change (feedback signals + test results)
- Validation results (before/after scores)

User can:
- **Approve** → apply changes, commit as new version
- **Modify** → adjust the proposed change, re-validate
- **Reject** → discard, optionally note why (becomes a feedback signal itself)

---

## Implementation Phases

### Phase 1: Test Scenarios (build now)

The most immediately valuable piece. Even without the full loop, having defined test scenarios lets us:
- Evaluate the current SKILL.md objectively
- Compare before/after when we make manual changes
- Build a regression suite

Deliverables:
- `tests/scenarios.yml` — 20-30 test cases
- `tests/run.sh` — runner script
- `tests/judge.sh` — judge prompt + scoring

### Phase 2: Signal Collection (add to SKILL.md)

Low-effort addition. Add feedback logging instruction to SKILL.md + create `~/.geb/` directory convention.

Deliverables:
- Updated SKILL.md with logging instruction
- `~/.geb/feedback.log` format definition

### Phase 3: Analysis + Validation (automation)

The full loop. Reads signals + test results, proposes changes, validates them.

Deliverables:
- `scripts/analyze.sh` — reads signals and test results, produces proposals
- `scripts/validate.sh` — applies proposals to copy, re-runs tests
- `scripts/improve.sh` — orchestrates the full loop

### Phase 4: Refinement

- Track improvement history (version log of SKILL.md changes + what drove them)
- Tune the judge prompt based on experience
- Add scenario generators for edge cases
- Consider: can the analysis step itself be improved by the loop?

---

## Open Questions

1. **`claude -p` fidelity**: How closely does print mode match interactive behavior? We may need to validate test scenarios against real interactive sessions periodically.

2. **Judge reliability**: LLM-as-judge has known biases (positivity bias, sensitivity to prompt ordering). Should we run the judge multiple times and take consensus?

3. **Feedback signal noise**: Users correct Claude for many reasons, not all related to GEB. How do we distinguish "GEB-caused" corrections from general corrections?

4. **Skill-off baseline**: Does `claude -p` support disabling specific skills for control runs? If not, we need another way to get a baseline.

5. **Cost**: Running 30 scenarios × 2 (with/without skill) × judge evaluation = ~90 Claude invocations per test run. Acceptable for periodic evaluation, too expensive for continuous.
