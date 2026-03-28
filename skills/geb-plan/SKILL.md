---
name: geb-plan
description: Decompose a decided approach into executable steps — use after thinking through an approach, when ready to implement a multi-step task. Triggers on "plan this", "break this down", "what are the steps", or when a task clearly needs sequenced execution.
---

# GEB Plan — Decomposition & Execution Design

The direction is clear. Break it into executable steps.

## Pre-check

This skill works best when the goal and approach are already decided. If either is unclear, suggest `/geb-think` first rather than planning around ambiguity.

## Decomposition Rules

### Keep steps atomic and verifiable

Each step should do one thing with a clear "done" condition.

Bad: "Set up the backend"
Good: "Create the Express app with health check endpoint. Verify: `curl localhost:3000/health` returns 200."

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

## Output Format

```
## Goal
[One sentence]

## Steps
1. [Step] — verify: [how to confirm it worked]
2. [Step] — verify: [...]
   ↳ depends on: 1
3. [Step] — verify: [...]

## Parallel opportunities  (optional — only if parallelizable steps exist)
[Which steps can run concurrently]

## Risks  (optional — only if non-obvious risks exist)
[Anything that might derail the plan]
```

After presenting the plan, ask: "Ready to start, or adjust anything?"

## Persistence

If this is a multi-session project with `.geb/index.md`, save the plan there (or as `.geb/plan.md` if it's substantial). Plans that only live in the conversation are lost on context reset.
