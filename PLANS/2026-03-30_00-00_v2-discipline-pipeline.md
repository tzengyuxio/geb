# v2: Discipline Pipeline + Skill Generator

> Date: 2026-03-30
> Status: Approved

## Goal

Implement the discipline evolution pipeline: GEB detects recurring patterns during use, generates discipline proposals, and graduates them into System 1 reflexes (CLAUDE.md rules or user skills) upon user approval.

## Phase B: Discipline Pipeline

1. Design proposal format + `.geb/proposals/` structure
2. Implement pattern detection in prelude
3. Build `geb:evolve` skill (list/approve/reject proposals)
4. Add test scenarios for pipeline
5. Update project state docs

## Phase C: Skill Generator (after B is validated)

Extend geb:evolve: when a proposal exceeds single-rule complexity, generate a full skill instead.

## Key Design Decisions

- Proposals are Markdown files in `.geb/proposals/`, human-readable and git-friendly
- Two detection modes: telemetry-based (cross-session) and observation-based (within-session)
- Conservative trigger threshold to avoid proposal spam
- Target output: CLAUDE.md rule (simple) or user skill (complex)
