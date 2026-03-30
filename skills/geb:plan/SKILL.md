---
name: geb:plan
description: Decompose a decided approach into executable steps — use after thinking through an approach, when ready to implement a multi-step task. Triggers on "plan this", "break this down", "what are the steps", or when a task clearly needs sequenced execution.
---

# GEB Plan — Decomposition & Execution Design

The direction is clear. Break it into executable steps and decide how to execute them.

## Pre-check

Before planning, assess: **is the goal specific enough to decompose?**

- "Implement auth with signup, login, and password reset" → **goal is clear** — plan it.
- "Refactor this, whatever approach makes sense" → **approach is undefined** — suggest `/geb:think` first.
- "Make this better" → **goal is vague** — ask what "better" means, or suggest `/geb:think`.

The test: can you write a one-sentence Goal for the plan? If not, the direction isn't decided yet.

## Decomposition Rules

### Keep steps atomic and verifiable

Each step must have a **verify** condition — a concrete way to confirm it's done.

Bad: "Set up the backend"
Good: "Create the Express app with health check endpoint. Verify: `curl localhost:3000/health` returns 200."

Every step in the output MUST include `— verify: [...]`. No exceptions.

### Surface dependencies

Mark which steps depend on others. Independent steps can be parallelized.

```
1. Create database schema          ← independent
2. Create API route handlers       ← depends on 1
3. Add input validation            ← depends on 2
4. Write integration tests         ← depends on 2
   (3 and 4 can run in parallel)
```

### Right-size the plan

- 3-7 steps for most tasks
- More than 10 steps → split into phases
- Steps should be roughly similar effort — if one is 10x larger, break it down

## Execution Strategy

| Situation | Strategy |
|-----------|----------|
| 3 or fewer steps, all sequential | Execute inline — no subagents needed |
| Independent steps that don't share state | Parallel agents — each gets curated context |
| Large plan with mixed dependencies | Wave execution — batch independent steps per wave |

Key principle: **orchestrator thin, worker well-fed** — curate context per agent, don't say "go figure it out." See [references/orchestration.md](references/orchestration.md) for dispatch patterns, model selection, wave execution, and failure handling.

## Output Format

```
## Goal
[One sentence]

## Steps
1. [Step] — verify: [...] — model: [if using agents]
2. [Step] — verify: [...]
   ↳ depends on: 1
3. [Step] — verify: [...]

## Execution
[inline | parallel agents | wave execution]
[If agents: brief summary of context curation approach]

## Risks  (optional — only if non-obvious)
[Anything that might derail the plan]
```

After presenting the plan, ask: "Ready to start, or adjust anything?"

## Persistence

If this is a multi-session project with `.geb/index.md`:
- Save the plan to shared state: in `index.md` Notes, or as `.geb/plan.md` if substantial.
- Save your current position to `.geb/.local/status.md` (e.g., "Executing step 3 of 5, steps 1-2 done").

Plans that only live in the conversation are lost on context reset.
