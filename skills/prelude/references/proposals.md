# Discipline Proposals

## Directory

Proposals live in `.geb/proposals/`. Each proposal is a Markdown file with YAML frontmatter.

```
.geb/
  proposals/
    check-theme-consumers.md      ← pending
    validate-api-inputs.md        ← pending
    .approved/                    ← applied proposals (archive)
    .rejected/                    ← rejected proposals (archive)
```

## Proposal Format

```markdown
---
pattern: <one-line description of the recurring pattern>
occurrences: <number of times observed, or "multiple" if no telemetry>
target: CLAUDE.md | skill
status: pending
created: YYYY-MM-DD
---

## Evidence

<What was observed — concrete examples from the project.>

## Proposed Rule

<The exact text to add to CLAUDE.md, or the skill behavior to create.>

## Rationale

<Why this pattern is worth codifying — what goes wrong without it.>
```

## Lifecycle

1. **Created** — GEB detects a pattern and writes to `.geb/proposals/`
2. **Pending** — User reviews via `/geb:groove`
3. **Approved** — Rule written to CLAUDE.md (or skill created), proposal moved to `.geb/proposals/.approved/`
4. **Rejected** — Proposal moved to `.geb/proposals/.rejected/`, GEB won't re-propose the same pattern

## Trigger Conditions

Create a proposal only when:
- The same pattern has been observed **3+ times** (with telemetry) or **2+ times in the current session** (without telemetry)
- The pattern caused an actual issue (bug, rework, user correction) — not just a stylistic preference
- No existing CLAUDE.md rule or project skill already covers it
- The pattern is **project-specific**, not something Claude already handles well by default

Do NOT create proposals for:
- General best practices Claude already knows
- One-off issues unlikely to recur
- Patterns already covered by GEB's built-in disciplines

## Target Selection

When creating a proposal, set `target` based on complexity:

**target: CLAUDE.md** when:
- The rule fits in 1-3 lines
- No examples or checklists needed
- Simple "always do X before Y" pattern

**target: skill** when:
- The rule needs examples, checklists, or step-by-step procedures
- Multiple trigger contexts exist (not just one situation)
- References to project files or patterns would be helpful
- The rule is complex enough that a one-liner would be too vague to follow
