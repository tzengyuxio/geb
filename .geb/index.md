# GEB Project State

## Goal

Build an adaptive thinking framework for Claude Code that intervenes when depth is needed and stays silent otherwise.

## Progress

- v0 core skills shipped: prelude, geb:think, geb:plan, geb:align
- Test infrastructure: multi-skill runner, judge, scorer with per-skill reporting
- Self-improvement loop operational (scripts/improve.sh)
- **2026-03-29: Core philosophy rewrite** — dropped "fast and slow" dual-mode model, adopted "depth guard" architecture. See [philosophy.md](philosophy.md) for full rationale.

## Notes

- Prelude's improvement loop hits Pareto frontier quickly — structural changes needed more than parameter tuning
- geb:plan scores lowest (0.3) in current test suite, room for improvement
- See [philosophy.md](philosophy.md) for the System 1/2 cognitive architecture decisions
