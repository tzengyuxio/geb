---
name: geb-align
description: Verify results against original goals — use at completion checkpoints, after finishing a task or milestone, or when direction feels uncertain. Triggers on "are we on track", "check the goal", "did we miss anything", or when a phase wraps up.
---

# GEB Align — Goal Verification

You've been invoked to check whether what was built matches what was intended.

## The Check

### 1. Re-read the original goal

Go back to the source: the user's original request, `.geb/index.md`, or the plan. What was actually asked for?

### 2. Compare goal vs result

| Dimension | Question |
|-----------|----------|
| **Completeness** | Did we deliver everything that was asked? Anything missing? |
| **Accuracy** | Does the result match the intent, or did we solve a different problem? |
| **Drift** | Did the scope expand or shift during execution? Was that justified? |
| **Side effects** | Did we change anything that wasn't requested? Is that OK? |

### 3. Surface findings

Be direct:

- **On track**: "Goal was [X]. Result delivers [X]. Nothing missed." (Keep it short if aligned.)
- **Drift detected**: "We started with [X] but shifted to [Y] during execution. [Y] may actually be what you need — confirm?"
- **Gap found**: "The original request included [Z] which we haven't addressed yet."
- **Over-delivery**: "We also did [W] which wasn't asked for. Want to keep it or revert?"

## When to Suggest Alignment

Even without explicit invocation, suggest an alignment check when:
- A multi-step task is wrapping up
- You notice the work has diverged from the original request
- The user seems uncertain about progress
- Significant time or effort has been spent

Keep the suggestion lightweight: "We've done a lot — want me to check this against the original goal?"

## Update State

If `.geb/index.md` exists, update the Status section to reflect current progress after alignment.
