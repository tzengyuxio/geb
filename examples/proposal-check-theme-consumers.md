---
pattern: Modifying theme tokens without checking downstream consumers
occurrences: 3
target: CLAUDE.md
status: pending
created: 2026-03-28
---

## Evidence

1. Changed `theme.colors.primary` from red to blue — broke Card, Header, and Sidebar border colors without noticing.
2. Updated `theme.spacing.lg` — Modal and Drawer padding shifted, caught in PR review.
3. Renamed `theme.fonts.heading` — 4 components still referencing old token, build failed.

## Proposed Rule

Add to CLAUDE.md under project-specific disciplines:

```
## Theme Token Discipline
Before modifying any value in src/theme.ts:
1. grep -r for the token name across src/components/
2. List all consumers in the commit message
3. Verify each consumer still renders correctly after the change
```

## Rationale

Theme tokens are shared state used by 8+ components. Changes propagate silently. Without a grep-first discipline, breakage is only caught downstream (PR review or production).
