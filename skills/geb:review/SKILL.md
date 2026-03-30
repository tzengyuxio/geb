---
name: geb:review
description: Multi-dimensional quality review of completed work — use after finishing a feature, milestone, or deliverable to check quality before shipping. Triggers on "review this", "is this ready?", "check the quality", "before we ship", or at completion of significant work.
---

# GEB Review — Quality Audit

Work is done. Check if it's good enough to ship.

## Quick Goal Check

Before diving into quality, glance at the original goal: **are we still on track?** If the work has drifted from the original request, flag it now — no point auditing quality on something that solves the wrong problem.

- If aligned → proceed to quality dimensions below
- If drifted → surface the drift first, then ask whether to continue the review or re-align via `/geb:align`

This is a lightweight check, not a full alignment audit. For deep goal verification on milestones, use `/geb:align` directly.

## Quality Dimensions

Check each dimension. Skip any that clearly don't apply.

### Correctness

Does it work as intended?

- Test the happy path and key edge cases
- Run existing tests — do they still pass?
- Manually verify the core behavior, don't just trust "it compiled"

### Consistency

Does it fit with what's already there?

- Naming conventions, code style, patterns — does this match the project?
- Error handling — same approach as the rest of the codebase?
- For non-code: does the tone, format, structure match existing deliverables?

### Ripple Impact

What else does this touch?

- Grep for consumers of any modified interfaces, types, or shared config
- List affected downstream components
- If nothing was checked: "Ripple impact not verified — these files may be affected: [list]"

### Security & Safety

Any obvious risks?

- User input validation (SQL injection, XSS, command injection)
- Auth/authz — does this bypass any access controls?
- Secrets in code — hardcoded keys, tokens, passwords?
- For non-code: data privacy, legal compliance, brand risk

### Completeness

Anything missing?

- Error handling for failure cases
- Tests for new functionality
- Documentation for public APIs or user-facing changes
- Migration steps if needed

## Output

Be direct. Lead with problems, not praise:

```
## Review: [what was reviewed]

### Issues
- [Critical] Missing input validation on POST /api/orders — accepts negative quantities
- [Important] No test for the password reset flow
- [Minor] Inconsistent error format (returns string, rest of API returns {error: ...})

### Ripple Impact
Changed UserProfile type — also used by: settings page, admin panel, export API. All verified.

### Verdict
[Ready / Needs fixes / Needs rethinking]
```

If everything is clean: "Reviewed [X]. No issues found. Ready to ship."

## When NOT to use this skill

- You only need a direction/goal checkpoint, not quality audit → use `/geb:align`
- Something is broken and you need to find the cause → use `/geb:debug`
- You're exploring approaches before implementation → use `/geb:think`
