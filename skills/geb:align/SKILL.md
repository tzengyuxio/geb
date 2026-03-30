---
name: geb:align
description: Verify results against original goals — use at completion checkpoints, after finishing a task or milestone, or when direction feels uncertain. Triggers on "are we on track", "check the goal", "did we miss anything", or when a phase wraps up.
---

# GEB Align — Goal Verification

Check whether what was done matches what was intended.

## The Check

### 1. Re-read the original goal

Go back to the source: the user's original request, `.geb/index.md`, or the plan. What was actually asked for?

### 2. Compare goal vs result

| Dimension | Question |
|-----------|----------|
| **Completeness** | Did we deliver everything asked? Anything missing? |
| **Accuracy** | Does the result match the intent, or did we solve a different problem? |
| **Drift** | Did scope expand or shift during execution? Was that justified? |
| **Side effects** | Did we change anything unrequested? Is that OK? |

### 3. Check ripple impact

For each modified file, ask: **does anything else depend on what I changed?**

- If you modified an interface, type, or return contract → grep for all consumers and verify they still work.
- If you modified shared config (theme tokens, env vars, feature flags) → list all files that reference them.
- If you changed function signatures → check all call sites.

Surface anything unreviewd: "Changed `theme.colors.primary` — also used by Card, Header, Sidebar, Badge, Alert, Modal, Nav. Verified they all still render correctly." Or: "Changed `login()` return type — 3 call sites updated, but `middleware.py` also calls it and may need attention."

### 4. Verify quality

Run automated checks — don't just verify alignment on paper:
- Run tests, linters, or type checkers
- Check for build errors
- Spot-check the output manually if automated checks aren't available

### 5. Surface findings

Be direct:

- **On track**: "Goal was [X]. Result delivers [X]. Nothing missed." (Short if aligned.)
- **Drift detected**: "We started with [X] but shifted to [Y]. [Y] may be what you need — confirm?"
- **Gap found**: "The original request included [Z] which we haven't addressed yet."
- **Over-delivery**: "We also did [W] which wasn't asked for. Keep or revert?"

## What's Next

Based on findings:
- **Aligned** → done, or proceed to next phase
- **Gap found** → suggest addressing it, or re-enter `/geb:plan` for remaining work
- **Drift detected** → confirm new direction with user before continuing
- **Needs rethinking** → suggest `/geb:think` to reassess approach

## When to use align vs review

- **"Are we building the right thing?"** → `/geb:align` (this skill)
- **"Is what we built good enough?"** → `/geb:review` (includes a lightweight goal check)
- **Both at once** → just run `/geb:review` — it starts with a goal check before auditing quality

Use align on its own for **milestone checkpoints** where direction matters more than code quality — e.g., after phase 1 of a multi-phase project, before committing to the next phase.

## Update State

If `.geb/index.md` exists:
- Update the **Progress** section in `index.md` with milestone facts (shared — e.g., "Auth module complete, API tests passing").
- Update `.geb/.local/status.md` with your session state (personal — e.g., "Finished alignment check, next: deploy").
