# Organic State: .geb/ Directory

For projects spanning multiple sessions, use `.geb/` for organic project memory. **Do NOT create preemptively** — only when knowledge worth preserving accumulates.

## Session start behavior

If the current directory contains `.geb/`, actively read these files at the start of the conversation:
1. `.geb/.local/status.md` (personal — where I left off)
2. `.geb/index.md` (shared — project context)

Connect naturally if relevant; don't bring up old projects unprompted.

## Two layers: shared + personal

**Shared** (committed to git) — team knowledge:
- `.geb/index.md` — Goal (one sentence), Progress (milestone facts), Notes (decisions, open questions)
- Budded files: `research.md`, `decisions.md`, `plan.md`, etc.
- `archive/` for stale items

**Personal** (gitignored via `.geb/.local/`) — individual session state:
- `.geb/.local/status.md` — what *I* am currently working on, where *I* left off

## Growth

Sections bud into own files at ~50 lines. `index.md` stays the concise entry point.

## Aging

Suggest archiving stale items to `.geb/archive/`. Never delete.
