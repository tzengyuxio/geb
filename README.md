# GEB

**Adaptive thinking for Claude Code.**

> Get Every Breakthrough.

---

## The Problem

An LLM has one autoregressive process reading one set of instructions. It doesn't have two cognitive systems. Trying to make it behave as both "fast and intuitive" and "slow and deliberate" through a single prompt creates an irresolvable contradiction — strengthening one mode degrades the other.

Most AI coding frameworks try to control *all* of Claude's behavior. GEB takes a different approach: **Claude's defaults are already good. GEB only adds what's missing.**

## What GEB Does

Claude already handles simple tasks well — renaming a variable, fixing a typo, running tests. It doesn't need a framework to tell it how to do these things.

What Claude lacks is **System 2** — the deliberate, structured thinking that kicks in for complex problems: exploring trade-offs, decomposing multi-step plans, verifying goals, and learning from patterns.

**GEB provides this second circuit.** It stays silent on simple tasks and intervenes only when depth is needed.

## What Makes GEB Different

| Approach | What it optimizes for |
|----------|----------------------|
| Prompt rules in CLAUDE.md | Static behavior — same rules, every time |
| Code-focused frameworks | Code quality — discipline, testing, review |
| Project management frameworks | Reliability — context persistence, task tracking |
| **GEB** | **Thinking quality — the right cognitive tools at the right time** |

A task using GEB might produce code, a decision record, a research note, a workflow design, or a reframed problem statement. The framework treats all of these as equally valid outcomes.

## Philosophy

> Claude's default behavior is System 1 — intuitive, automatic, general-purpose.
> GEB is System 2 — deliberate, effortful, activated on demand.

GEB is a **depth guard**: it watches for signals that a task needs more thinking than surface-level execution, and intervenes when it detects them. For everything else, it stays out of the way.

You don't notice GEB on simple tasks. That's by design — not because of a "silent rule" that suppresses the framework, but because **the framework genuinely has nothing to add**. The absence of intervention is not a mode; it's the natural state.

GEB speaks up when it matters:
- "This crosses three services with inconsistent patterns. Want me to explore approaches?"
- "Done. Note: this also affects 8 components that share the same theme token."
- "I've noticed this validation issue three times now. Created a discipline proposal."

## How It Works

### Depth Guard

Prelude — the always-on core — watches for signals during every task:

- **Open-ended goals** — "redesign", "how should I", "what's the best way"
- **Cross-domain scope** — touches multiple systems, modules, or layers
- **Design decisions** — meaningful alternatives exist with different trade-offs
- **Hidden complexity** — what started simple reveals deeper issues

When signals are detected, GEB engages the appropriate cognitive tool. When signals are absent, Claude's defaults handle the task with zero overhead.

### Cognitive Tools

| Skill | When it activates | What it does |
|-------|------------------|--------------|
| `/geb:think` | Ambiguous goals, trade-off analysis | Structured exploration: problem definition → approach comparison → clear direction |
| `/geb:plan` | Multi-step implementation | Decompose into atomic steps with verify conditions, dependency graphs, execution strategy |
| `/geb:debug` | Something broken, unexpected behavior | Systematic diagnosis: symptoms → reproduce → isolate → root cause → fix → verify |
| `/geb:review` | Work completed, before shipping | Multi-dimensional quality audit: correctness, consistency, ripple, security, completeness |
| `/geb:align` | Task completion, drift suspected | Goal verification: completeness, accuracy, drift, ripple impact |
| `/geb:groove` | Recurring patterns noticed | Discipline pipeline: create proposals → user reviews → graduate to automated habits |

These chain naturally for deep tasks: think → plan → (execute) → review → align. Debug when something breaks. Groove when patterns emerge.

### Disciplines

Always-on guardrails that don't require conscious engagement:

- **Evidence before claims** — verify before saying "done"; "should work" is not evidence
- **Search before building** — check existing deps and project utilities before writing custom code
- **Anti-rationalization** — "this is too simple to check" means it's important enough to check
- **Goal awareness** — suggest alignment checks when multi-step work wraps up

### Discipline Evolution (Groove)

Disciplines are not fixed. GEB watches for recurring patterns — the same mistake happening repeatedly, the same type of issue surfacing across tasks. When it detects one, it creates a **proposal** in `.geb/proposals/`.

You review proposals via `/geb:groove`. Approved proposals become CLAUDE.md rules or project-specific skills — graduating from active System 2 attention into automatic System 1 reflexes. Like water carving a groove in stone: repeated flow creates a permanent channel.

### Organic State

Project memory that grows like a living tree:

```
Stage 0: .geb/index.md                    ← everything in one file
Stage 1: .geb/index.md + research.md      ← a section budded out
Stage 2: .geb/index.md + research/ + ...  ← continued growth
```

- No preset structure — form follows content
- `index.md` is always the entry point for any new session
- All Markdown — human-readable, git-friendly

**Multi-user friendly.** State is split into shared (`.geb/`, committed) and personal (`.geb/.local/`, gitignored). Multiple team members can each use GEB on the same repo without conflicts.

## Install

```bash
git clone https://github.com/tzengyuxio/geb.git
cd geb
bash install.sh
```

This installs 7 skills and a session-start hook:

| Skill | What it does |
|-------|-------------|
| `prelude` | Auto-loaded every session. Depth guard, disciplines, organic state. |
| `/geb:think` | Structured exploration for complex tasks. |
| `/geb:plan` | Decompose approach into executable steps with orchestration. |
| `/geb:debug` | Systematic diagnosis for anything broken or unexpected. |
| `/geb:review` | Multi-dimensional quality audit before shipping. |
| `/geb:align` | Verify results against original goals, check ripple impact. |
| `/geb:groove` | Review and apply discipline proposals generated from usage patterns. |

Prelude loads automatically via a SessionStart hook. The other skills are invoked on demand — either manually or auto-triggered by Claude when your task matches their description.

### Optional: enable usage collection

```bash
touch ~/.geb/collect
```

This enables local-only telemetry — GEB will silently log depth routing decisions, skill invocations, and user overrides to `~/.geb/sessions/`. **Nothing is uploaded or sent anywhere.** The data stays on your machine and can be used to improve your local GEB skills over time. See [Telemetry & Self-Improvement](#telemetry--self-improvement) for details.

## Uninstall

```bash
bash uninstall.sh
```

## Telemetry & Self-Improvement

GEB includes a built-in feedback loop: collect real usage data, analyze patterns, and iteratively improve the skills.

### Enable telemetry

```bash
touch ~/.geb/collect    # enable
rm ~/.geb/collect       # disable
```

When enabled, GEB silently logs events to `~/.geb/sessions/YYYY-MM-DD.jsonl` — depth routing decisions, user overrides, skill invocations, dynamic routing events, and task outcomes. No data is sent anywhere; everything stays on your machine.

### Analyze your data

```bash
python3 scripts/analyze.py              # full report
python3 scripts/analyze.py --days 7     # last 7 days
python3 scripts/analyze.py --json       # machine-readable
```

The report shows: depth distribution, override rate (how often you disagree with routing), skill auto-trigger rate, and user corrections — all signals that point to where the skills need tuning.

### Improve the skills

Feed your telemetry into the autoresearch-style improvement loop:

```bash
# Generate feedback from your usage data
python3 scripts/analyze.py --feed-improve > ~/.geb/feedback.log

# Run the improvement loop (modifies SKILL.md, tests, keeps or discards)
bash scripts/improve.sh --target prelude
bash scripts/improve.sh --target geb:think
```

Each round: propose one change → test against scenarios → score → keep if improved, discard if not.

### Contributing telemetry to the project

If you'd like to submit a PR with improvement proposals informed by your telemetry data, please anonymize your logs first:

```bash
python3 scripts/anonymize.py ~/.geb/sessions/   # outputs to ~/.geb/sessions-anon/
```

This strips:
- File paths and directory names (replaced with generic tokens)
- Task descriptions and user messages (replaced with category labels)
- Timestamps (shifted to relative offsets)
- Project-specific terms (names, URLs, identifiers)

What's preserved: event types, depth values, skill names, override patterns, and correction categories — the structural signals needed for improvement without any personal or project context.

**Never commit raw `~/.geb/sessions/` files** — they contain task descriptions that may reference proprietary code or private information.

## Roadmap

GEB follows a self-bootstrapping strategy — each version is built using the previous one. If the framework isn't good enough to improve itself, it's not ready.

- **v0** — Minimal core: adaptive depth routing, thinking flow, organic state, universal disciplines
- **v1** — Depth guard architecture, multi-skill test infrastructure, self-improvement loop
- **v2** (current) — Discipline pipeline (`geb:groove`): pattern detection → proposals → graduation to automated habits. Next: skill generator for complex patterns.

## License

MIT
