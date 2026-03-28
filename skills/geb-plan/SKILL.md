---
name: geb-plan
description: Decompose a decided approach into executable steps — use after thinking through an approach, when ready to implement a multi-step task. Triggers on "plan this", "break this down", "what are the steps", or when a task clearly needs sequenced execution.
---

# GEB Plan — Decomposition & Execution Design

You've been invoked because the direction is clear and now needs to be broken into executable steps.

## Input

By now you should have (from `/geb-think` or the user directly):
- A clear goal
- A chosen approach
- Known constraints

If any of these are missing, state what's missing and either fill it in yourself or ask.

## Decomposition Rules

### Keep steps atomic and verifiable

Each step should:
- Do one thing
- Have a clear "done" condition
- Be independently testable where possible

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
- If you need more than 10 steps, the task should probably be split into phases
- Each step should take roughly similar effort — if one is 10x larger, break it down further

## Output Format

```
## Goal
[One sentence]

## Steps
1. [Step] — verify: [how to confirm it worked]
2. [Step] — verify: [...]
   ↳ depends on: 1
3. [Step] — verify: [...]

## Parallel opportunities
[Which steps can run concurrently]

## Risks
[Anything that might derail the plan — optional, only if non-obvious]
```

After presenting the plan, ask: "Ready to start, or adjust anything?"
