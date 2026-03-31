You are evaluating whether a Claude Code skill ("GEB") improves Claude's behavior on a specific scenario.

## Skill Behavior Reference

| Skill | Behavior |
|-------|----------|
| prelude | Depth guard — intervenes when structured thinking is needed (depth signals, ripple impact, disciplines), stays silent on simple tasks. Also handles discipline evolution: detects recurring patterns and creates proposals. |
| geb:think | Structured exploration — problem definition, research, approach comparison, clear direction. Key principle: investigate while asking (show findings alongside questions, never ask-and-stop). |
| geb:debug | Systematic diagnosis — symptoms → reproduce → isolate → root cause → fix. Iron rule: no fix without stated root cause. |
| geb:review | Multi-dimensional quality audit — correctness, consistency, ripple impact, security, completeness. Leads with problems, ends with verdict (ready/needs fixes/needs rethinking). |

## Scenario

- **Name**: {{name}}
- **Skill**: {{skill}}
- **Skill behavior**: (see reference table above)
- **Category**: {{category}}
- **Expected behavior**: depth-signal = detect complexity and engage thinking; upgrade = discover hidden complexity mid-task; discipline = apply universal guardrails; conflict = balance competing signals; diagnosis = systematic root-cause identification before fixing; quality = multi-dimensional review across correctness, security, completeness; evolution = pattern detection and discipline proposal creation
- **Prompt**: "{{prompt}}"

## Pass Criteria

{{pass_criteria}}

## Fail Patterns (response should NOT contain these)

{{fail_patterns}}

## Response A — With GEB Skill

```
{{with_geb}}
```

## Response B — Without GEB Skill (Control)

```
{{control}}
```

## Instructions

Evaluate Response A (with skill) against the criteria. Be strict and objective.

### Step 1: Score each pass criterion

For each criterion, output exactly:

```
- criterion: "<criterion text>"
  result: PASS | FAIL
  note: "<one sentence explanation>"
```

### Step 2: Check fail patterns

For each fail pattern found in Response A, output:

```
- pattern: "<pattern>"
  found: true | false
  context: "<where it appeared, if found>"
```

### Step 3: Compare A vs B

```
comparison: BETTER | SAME | WORSE
explanation: "<one sentence: how does the skill change behavior?>"
```

Definitions:
- **BETTER**: Response A demonstrates clearly improved behavior that aligns with the expected depth
- **SAME**: No meaningful behavioral difference between A and B
- **WORSE**: Response A behaves less appropriately than B for this scenario

### Step 4: Overall

```
overall:
  criteria_passed: <N>
  criteria_total: <N>
  fail_patterns_triggered: <N>
  comparison: <BETTER|SAME|WORSE>
  pass_rate: <0.0 to 1.0>
```

Output ONLY the YAML evaluation. No preamble, no explanation outside the YAML structure.
