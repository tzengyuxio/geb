# GEB

**Adaptive thinking for Claude Code.**

> Get Every Breakthrough.

---

## The Problem

Claude Code treats every task the same way. Ask it to rename a variable, and it writes three paragraphs of analysis first. Ask it to design a system architecture, and it jumps straight to code without thinking through the trade-offs.

Most AI coding tools optimize for **code output** — more code, faster code, better code. But the real bottleneck in AI-assisted work isn't code generation. It's **knowing when to think and when to act**.

## What GEB Does

GEB reshapes how Claude Code thinks. Instead of treating every task with the same approach, it teaches Claude to **match its thinking depth to your task's complexity** — automatically.

- **Simple request?** Execute immediately. No preamble, no confirmation, no friction.
- **Moderate ambiguity?** One-sentence check-in, then proceed.
- **Complex problem?** Structured thinking: define the problem, research, design approaches, decide, then act.

The depth isn't a binary switch — it's a **continuous dial**. Claude suggests; you override with natural language anytime. And it dynamically adjusts mid-task as complexity reveals itself.

## What Makes GEB Different

GEB is not just a coding tool. It's a system for **thinking and problem-solving**, where code is one of many possible outputs.

| Approach | What it optimizes for |
|----------|----------------------|
| Prompt rules in CLAUDE.md | Static behavior — same rules, every time |
| Code-focused frameworks | Code quality — discipline, testing, review |
| Project management frameworks | Reliability — context persistence, task tracking |
| **GEB** | **Thinking quality — right depth, right time** |

A task using GEB might produce code, a decision record, a research note, a workflow design, or a reframed problem statement. The framework treats all of these as equally valid outcomes.

## Philosophy

> *Like rain that nourishes silently* — invisible in daily use, surfacing at the right moments with the right depth.

GEB is designed like a good co-pilot: you don't notice it most of the time, but it speaks up when it matters.

**Silent by default.** It only surfaces for:
- Depth adjustment — "This is more involved than expected. Want me to step back and think through the approach?"
- Goal awareness — "We started with X, but this is heading toward Y. Still right?"
- Session continuity — "Last time we were working on X. Continue from there?"
- State management — "This section has grown. Split into its own file?"

No commands to learn. No special syntax. "Just do it", "think about this", "analyze carefully" — everyday language is the control mechanism.

## How It Works

### Adaptive Depth

Inspired by Kahneman's *Thinking, Fast and Slow*:

| Depth | Signals | Claude does |
|-------|---------|-------------|
| **Fast** | Clear, small, imperative tone | Execute silently. Zero friction. |
| **Medium** | Some ambiguity, moderate scope | One-sentence confirmation, then proceed |
| **Slow** | Vague goal, cross-domain, design decisions | Structured thinking pipeline |

Depth isn't locked at the start. If a "fast" task reveals unexpected complexity, Claude suggests upgrading. If a "slow" assessment turns out to be a known pattern, it simplifies. You can override at any point.

### Thinking Core

When depth calls for it, GEB engages structured thinking — not every step every time, but as needed:

1. **Problem definition** — continuous, not one-time. What are you *really* trying to solve? Refines as understanding grows.
2. **Research & exploration** — what already exists? What can we learn from prior art?
3. **Approach design** — 2-3 paths with trade-offs and a recommendation.
4. **Decision & planning** — lock direction, decompose into steps.
5. **Action** — execute directly, or alternate between thinking and doing.

The output is whatever best captures the current understanding — a question, a plan, a decision record, or nothing at all. Form follows need.

### Organic State

Project memory that grows like a living tree — not "build an empty house and move in", but "settle on land and grow the space you need":

```
Stage 0: .geb/index.md                    ← everything in one file
Stage 1: .geb/index.md + research.md      ← a section budded out
Stage 2: .geb/index.md + research/ + ...  ← continued growth
```

- No preset structure — form follows content
- `index.md` is always the entry point for any new session
- Content ages gracefully: old items fold into archives, never deleted
- All Markdown — human-readable, git-friendly

**Multi-user friendly.** State is split into two layers:

- **Shared** (`.geb/`, committed) — project goals, milestone progress, design decisions, research. Team knowledge that benefits everyone.
- **Personal** (`.geb/.local/`, gitignored) — session continuity, current work status. Only you need this.

Multiple team members can each use GEB on the same repo. Shared files merge like any Markdown; personal state never conflicts.

### Universal Disciplines

Brief checkpoints applied at all depths — not lengthy processes, but silent guardrails:

1. **Evidence before claims** — verify before saying "done"
2. **Anti-rationalization** — catch "this is too simple to need checking" thoughts
3. **Goal-reverse verification** — did we achieve the *goal*, or just complete the *task list*?
4. **Search before building** — check if it exists before creating from scratch

## Install

```bash
git clone https://github.com/tzengyuxio/geb.git
cd geb
bash install.sh
```

This installs 4 skills and a session-start hook:

| Skill | What it does |
|-------|-------------|
| `prelude` | Auto-loaded every session. Depth routing, organic state, silent rule. |
| `/geb:think` | Structured exploration for complex tasks. |
| `/geb:plan` | Decompose approach into executable steps with orchestration. |
| `/geb:align` | Verify results against original goals. |

Prelude loads automatically via a SessionStart hook. The other three skills are invoked on demand — either manually or auto-triggered by Claude when your task matches their description.

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
- **v1** (current) — Engineering infrastructure: context management, subagent orchestration, multi-skill architecture
- **v2** — Context modules: pluggable execution roles, ad-hoc role creation, self-learning system

## License

MIT
