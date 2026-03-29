You are evaluating whether a Claude Code skill ("GEB") improves Claude's behavior on a specific scenario.

## Skill Behavior Reference

| Skill | Behavior |
|-------|----------|
| prelude | Adaptive depth routing — matches thinking depth to task complexity (fast/medium/slow) |
| geb:think | Structured exploration — problem definition, research, approach comparison, clear direction |
| geb:plan | Decomposition & execution design — atomic steps, dependency surfacing, execution strategy |

## Scenario

- **Name**: {{name}}
- **Skill**: {{skill}}
- **Skill behavior**: (see reference table above)
- **Category**: {{category}}
- **Expected depth**: {{category}} (fast = execute silently, medium = brief confirmation then proceed, slow = structured thinking with clarifying questions)
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
