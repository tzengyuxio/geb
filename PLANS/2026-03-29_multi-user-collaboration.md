# Multi-User Collaboration for .geb/ State

## Goal

Support multiple team members using GEB on the same repo without state conflicts.

## Decision

**Approach A: Dual-layer state** — shared project knowledge (committed) + personal session state (gitignored).

- Shared: `.geb/index.md` (Goal, Progress, Notes), budded files, archive
- Personal: `.geb/.local/status.md` (session continuity, current work)
- Merge strategy for shared files: last-write-wins (standard git merge)

## Changes Made

1. `skills/prelude/SKILL.md` — rewrote Organic State section with two-layer design, renamed Status→Progress, added session continuity read order, added multi-user note
2. `skills/geb-think/SKILL.md` — clarified decisions go to shared Notes, not .local/
3. `skills/geb-plan/SKILL.md` — plans to shared state, session position to .local/status.md
4. `skills/geb-align/SKILL.md` — milestones to shared Progress, session state to .local/
5. `.gitignore` — added `.geb/.local/`

## Key Design Choices

- **Progress vs Status**: "Auth shipped" (Progress, shared fact) vs "I'm on step 3" (Status, personal)
- **No tooling needed**: Markdown merge conflicts are straightforward
- **Backward compatible**: Single-user experience unchanged; .local/ is just an extra layer
