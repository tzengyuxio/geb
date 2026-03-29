# Orchestration Details

## Orchestrator thin, Worker well-fed

When delegating to subagents, the main session becomes an orchestrator:

**Orchestrator responsibilities:**
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

## Model selection

Choose the model based on the nature of each step:

- **Judgment work** (design decisions, architecture review, ambiguous requirements) → strongest available model
- **Mechanical work** (implement a well-specified function, write tests, format conversion) → fast model
- **Default** → follow current session model

## Wave execution

For plans with mixed dependencies, execute in waves:

```
Wave 1: steps 1, 5       (independent — run in parallel)
Wave 2: steps 2, 3       (depend on wave 1 — run in parallel)
Wave 3: step 4           (depends on wave 2)
```

Between waves: verify all completed steps, update state, then dispatch next wave.

## When agents fail

If a subagent reports a problem:
- **Completed with concerns** → review the concerns, decide if they're acceptable or need a follow-up step
- **Needs more context** → provide the missing context and re-dispatch
- **Blocked** → assess if the blocker affects the whole plan or just this step. If isolated, continue other steps and address the blocker separately
