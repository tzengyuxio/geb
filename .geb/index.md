# GEB Project State

## Goal

Build an adaptive thinking framework for Claude Code that intervenes when depth is needed and stays silent otherwise.

## Progress

- v0 core skills shipped: prelude, geb:think, geb:plan, geb:align
- v1.0 tagged (2026-03-29): depth guard architecture, multi-skill test infrastructure, self-improvement loop
- v2.0 tagged (2026-03-30): discipline pipeline (geb:groove), skill generator, hook-based telemetry
- v2.1 tagged (2026-03-30): hook-based telemetry + miss reporting
- **Post v2.1**: added geb:debug (systematic diagnosis) and geb:review (quality audit) — 7 skills total

### Current Skill Set
| Layer | Skill | Role |
|-------|-------|------|
| Sentinel | prelude | Depth guard, disciplines, organic state, orchestration reference |
| Thinking | geb:think | Structured exploration |
| Diagnosis | geb:debug | Symptoms → root cause → fix → verify |
| Quality | geb:review | Multi-dimensional audit |
| Alignment | geb:align | Goal verification + ripple impact |
| Growth | geb:groove | Discipline evolution pipeline |

## Notes

- geb:plan removed — planning uses Claude's built-in capabilities; orchestration moved to prelude references
- See [philosophy.md](philosophy.md) for System 1/2 cognitive architecture and discipline evolution theory
- 24 test scenarios across 6 skills
- Prelude SKILL.md slimmed via progressive disclosure (organic-state, telemetry, orchestration in references/)
