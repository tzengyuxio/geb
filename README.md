# GEB

**A thinking-centric adaptive framework for Claude Code.**

> Get Every Breakthrough.

---

## What is GEB?

GEB is not a coding framework. It is a system for **thinking and problem-solving**, where coding is one of many execution capabilities.

Most AI coding frameworks focus on writing better code. GEB focuses on **thinking more clearly** — whether that leads to code, a decision, a research note, or a workflow design.

Core philosophy: **潤物細無聲** — invisible in daily use, surfacing at the right moments with the right insight.

## How it works

GEB injects a single skill (`prelude`) at session start that shapes how Claude approaches every interaction:

**Adaptive Depth** — inspired by Kahneman's *Thinking, Fast and Slow*:

| Depth | When | Claude does |
|-------|------|-------------|
| **Fast** | Clear path, small scope, direct tone | Execute silently. Zero friction. |
| **Medium** | Some ambiguity, moderate scope | One-sentence confirmation before proceeding |
| **Slow** | Vague goal, cross-domain, design decisions | Structured thinking: define → research → design → decide → act |

You control depth with natural language — "直接做", "想一下", "慢想" — no special syntax needed.

**Organic State** — project memory that grows like a tree:

- Starts as a single `.geb/index.md` file
- Sections bud into their own files as they grow
- No preset structure — form follows content
- Survives across sessions

**Universal Disciplines** — brief checkpoints, not lengthy processes:

1. Evidence before claims
2. Anti-rationalization
3. Goal-reverse verification
4. Search before building

## Install

```bash
git clone https://github.com/tzengyuxio/geb.git
cd geb
bash install.sh
```

This symlinks the `prelude` skill to `~/.claude/skills/prelude/`. Start a new Claude Code session to activate.

## Uninstall

```bash
bash uninstall.sh
```

## Version

v0 — Minimal viable core. Meta-Cognition routing + Layer 0 thinking + organic state + universal disciplines.

## License

MIT
