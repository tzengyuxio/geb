---
name: geb:plan
description: Decompose a decided approach into executable steps — use after thinking through an approach, when ready to implement a multi-step task. Triggers on "plan this", "break this down", "what are the steps", or when a task clearly needs sequenced execution.
---

# GEB Plan — Decomposition & Execution Design

The direction is clear. Break it into executable steps and decide how to execute them.

## Pre-check

This skill works best when the goal and approach are already decided. If either is unclear, suggest `/geb:think` first rather than planning around ambiguity.

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

## Execution Strategy

After decomposing steps, decide how to execute them:

### When to use subagents

| Situation | Strategy |
|-----------|----------|
| 3 or fewer steps, all sequential | Execute inline — no subagents needed |
| Independent steps that don't share state | Spawn parallel agents — each gets curated context |
| Large plan with mixed dependencies | Wave execution — batch independent steps per wave |

### Orchestrator thin, Worker well-fed

When delegating to subagents, the main session becomes an orchestrator:

**Orchestrator (you) responsibilities:**
- Hold the plan and global context
- Dispatch each task with curated context (don't say "go figure it out" — give the agent everything it needs)
- Collect results and verify against the step's "done" condition
- Update progress state after each step
- Quality gate: review agent output before proceeding

**What to give each agent:**
- The specific step description and verification criteria
- Relevant source files or context (pre-extracted, not "go read the whole repo")
- Constraints: what NOT to touch, scope boundaries
- Expected output format

**Example agent dispatch:**
```
Agent: "Implement the search module"
Context:
  - Step: "Create search.rs with fuzzy matching using nucleo crate"
  - Verify: "cargo test search:: passes"
  - Relevant files: src/notes.rs (Note struct definition), Cargo.toml
  - Constraint: only create/modify src/search.rs
  - Model: sonnet (well-specified implementation task)
```

### Model selection

Choose the model based on the nature of each step:

- **Judgment work** (design decisions, architecture review, ambiguous requirements) → strongest model (opus)
- **Mechanical work** (implement a well-specified function, write tests for existing code, format conversion) → fast model (sonnet or haiku)
- **Default** → follow current session model

### Wave execution

For plans with mixed dependencies, execute in waves:

```
Wave 1: steps 1, 5       (independent — run in parallel)
Wave 2: steps 2, 3       (depend on wave 1 — run in parallel)
Wave 3: step 4           (depends on wave 2)
```

Between waves: verify all completed steps, update state, then dispatch next wave.

## Output Format

```
## Goal
[One sentence]

## Steps
1. [Step] — verify: [how to confirm it worked]
2. [Step] — verify: [...]
   ↳ depends on: 1
3. [Step] — verify: [...]

## Execution
[inline | parallel agents | wave execution]
[If agents: which steps get which model, what context each needs]

## Risks  (optional — only if non-obvious)
[Anything that might derail the plan]
```

After presenting the plan, ask: "Ready to start, or adjust anything?"

## Persistence

If this is a multi-session project with `.geb/index.md`:
- Save the plan to shared state: in `index.md` Notes, or as `.geb/plan.md` if substantial.
- Save your current position to `.geb/.local/status.md` (e.g., "Executing step 3 of 5, steps 1-2 done").

Plans that only live in the conversation are lost on context reset.
