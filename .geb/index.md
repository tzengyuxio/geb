# GEB Project State

## Goal

Build an adaptive thinking framework for Claude Code that intervenes when depth is needed and stays silent otherwise.

## Progress

- v0 core skills shipped: prelude, geb:think, geb:plan, geb:align
- v1.0 tagged (2026-03-29): depth guard architecture, multi-skill test infrastructure, self-improvement loop
- **v2 in progress**: discipline pipeline (geb:groove) — pattern detection → proposal → graduation to System 1

### v2 Milestones
- [x] Proposal format and `.geb/proposals/` structure designed
- [x] Pattern detection workflow in prelude SKILL.md
- [x] `geb:groove` skill built (list/approve/reject proposals)
- [x] 3 evolution test scenarios added (detect, no-false-positive, propose-with-evidence)
- [x] Baseline test run (20260330-032327): prelude 0.7067, evolution 2/3 pass
- [x] Phase C: skill generator — groove detects skill-creator and delegates, or generates directly as fallback

## Notes

- See [philosophy.md](philosophy.md) for System 1/2 cognitive architecture and discipline evolution theory
- Prelude SKILL.md slimmed via progressive disclosure (organic-state + telemetry in references/)
- geb:plan orchestration details also moved to references/
