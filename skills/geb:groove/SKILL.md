---
name: geb:groove
description: Review and apply discipline proposals — use when GEB has detected recurring patterns and created proposals in .geb/proposals/. Triggers on "review proposals", "groove", "check discipline proposals", or when prelude suggests running this skill.
---

# GEB Groove — Discipline Pipeline

Review, approve, or reject discipline proposals that GEB generated from observed usage patterns. Proposals are Markdown files in `.geb/proposals/` — see prelude's [references/proposals.md](../prelude/references/proposals.md) for format details.

## Workflow

### 1. List pending proposals

Read all `.md` files in `.geb/proposals/` (excluding `.approved/` and `.rejected/` subdirs). For each, show:

```
Pending proposals:
  1. check-theme-consumers — "Modifying theme tokens without checking downstream consumers" (3 occurrences, target: CLAUDE.md)
  2. validate-api-inputs — "API endpoints missing input validation" (4 occurrences, target: skill)
```

If no proposals exist, say so and exit.

### 2. Review a proposal

When the user selects one (by number or name), read the full file and present:
- **Pattern**: what was observed
- **Evidence**: concrete examples
- **Proposed rule**: the exact change
- **Target**: CLAUDE.md or new skill

Then ask: "Approve, reject, or edit?"

### 3. Apply decision

**Approve** (target: CLAUDE.md):
1. Read the project's CLAUDE.md (create if absent)
2. Append the proposed rule under a `## Project Disciplines` section
3. Move the proposal to `.geb/proposals/.approved/`
4. Confirm: "Added to CLAUDE.md. This will take effect next session."

**Approve** (target: skill):

Check if `skill-creator` is available in the current skill list.

**With skill-creator** (preferred):
1. Invoke skill-creator in Create mode, passing: skill name (from filename), description (from `pattern` field), behavior (from `Proposed Rule`), examples (from `Evidence`)
2. Move the proposal to `.geb/proposals/.approved/`

**Without skill-creator** (fallback):
1. Create the skill directory in the project (ask for location if unclear)
2. Write SKILL.md:
   - `name`: from proposal filename
   - `description`: the `pattern` field + trigger contexts (when should this skill activate?)
   - Body: convert `Proposed Rule` into imperative instructions; use `Evidence` as concrete examples. Write in imperative form ("Validate all fields" not "You should validate").
3. Move the proposal to `.geb/proposals/.approved/`
4. Confirm: "Created skill at [path]. Install with `ln -s` or add to install.sh."

**Reject**:
1. Move to `.geb/proposals/.rejected/`
2. Confirm: "Rejected. GEB won't re-propose this pattern."

**Edit**:
1. Let the user modify the proposed rule
2. Save the edited version, then re-ask approve/reject

### 4. Batch mode

If the user says "approve all" or "review all", iterate through each proposal sequentially.

## Guard Rails

- Never auto-approve. Every proposal needs explicit user consent.
- Never modify existing CLAUDE.md rules — only append new ones under `## Project Disciplines`.
- If `.geb/proposals/` doesn't exist or is empty, say "No pending proposals" and suggest the user keeps working — patterns emerge from use.
