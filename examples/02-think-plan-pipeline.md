# Example: Think → Plan Pipeline — Structured Exploration to Execution

> Demonstrates the full pipeline from ambiguous goal through structured thinking to actionable plan.

## Scenario

A team is building a CLI tool in Rust for managing personal notes. The user wants to add a search feature but hasn't decided on the approach. This is a Slow task — vague goal, design decisions required, multiple valid approaches.

---

## Conversation

### Turn 1 — Open-ended request

**User:**
```
I want to add search to our notes CLI. Right now it just lists and opens notes by filename.
```

**Claude:**

*(GEB silently assesses: open-ended goal, design decisions needed, multiple approaches → Slow. Engages `/geb:think`.)*

### Problem Definition

You want to find notes by **content**, not just filename — moving from a file browser to a knowledge retrieval tool.

Looking at the codebase, I see:
- Notes are Markdown files in `~/.notes/`, averaging 200-500 lines
- Current `list` command already reads filenames and frontmatter titles
- No existing indexing or search infrastructure
- Dependencies: `clap` for CLI, `walkdir` for file traversal — nothing search-related yet

### Approaches

| | **Approach A: Regex grep** | **Approach B: Fuzzy matching** | **Approach C: Full-text index** |
|---|---|---|---|
| **How** | Walk files, regex match per line | Nucleo/skim for fuzzy scoring | Build a tantivy index, query it |
| **Speed (1k notes)** | ~200ms | ~150ms | <10ms after indexing |
| **Speed (10k notes)** | ~2s | ~1.5s | <10ms |
| **Complexity** | Low — 50 lines | Medium — 150 lines | High — 400+ lines, index management |
| **UX** | Exact matches only | Tolerates typos, ranked results | Ranked, supports phrases and boolean ops |
| **Maintenance** | None | None | Index rebuild on note changes |

### Recommendation

**Start with Approach B (fuzzy matching).** Here's why:

1. For a personal notes tool, 1k-5k notes is the realistic range — fuzzy matching handles this without indexing overhead
2. Nucleo is the same engine powering Helix editor's picker — battle-tested, fast, and already in the Rust ecosystem
3. It gives you ranked results and typo tolerance, which matter more for notes than exact grep matches
4. If you later outgrow it, migrating to tantivy is additive — you'd add an index layer, not rewrite the search

Want me to plan the implementation, or do you want to adjust the direction?

> **What happened:**
> GEB engaged `/geb:think` structured exploration:
> 1. **Problem definition** — reframed "add search" as "move from file browsing to knowledge retrieval"
> 2. **Research** — examined the codebase to understand current state and constraints
> 3. **Approach design** — 3 concrete options with a comparison table
> 4. **Direction** — clear recommendation with reasoning, ending with a handoff question

---

### Turn 2 — User confirms, requests plan

**User:**
```
Fuzzy sounds right. Plan it out.
```

**Claude:**

*(Direction confirmed. Engages `/geb:plan` for decomposition.)*

## Goal

Add fuzzy content search to the notes CLI using nucleo, with ranked results and interactive selection.

## Steps

1. **Add nucleo dependency and create search module skeleton**
   Create `src/search.rs` with the `SearchEngine` struct and public `search(query) -> Vec<Match>` interface.
   Verify: `cargo check` passes.

2. **Implement file content loading**
   `SearchEngine::load()` walks `~/.notes/`, reads each file, builds a list of `(path, title, content)` entries.
   Verify: unit test `search::tests::test_load_notes` passes with fixture files.

3. **Implement fuzzy matching and ranking**
   Wire nucleo's `Matcher` to score each entry against the query. Return top-N results sorted by score.
   Verify: unit test `search::tests::test_fuzzy_ranking` — "rust borrw" matches a note titled "Rust Borrow Checker".

4. **Add `search` CLI subcommand**
   Register `notes search <query>` in clap. Print results as a numbered list: `[score] title — path`.
   Verify: `cargo run -- search "test query"` returns formatted output.
   ↳ depends on: 1, 2, 3

5. **Add interactive selection (optional, stretch)**
   After displaying results, let user pick one to open in `$EDITOR`.
   Verify: manual test — selecting a result opens the file.
   ↳ depends on: 4

## Execution

Inline — 5 steps, mostly sequential with clear dependencies. Steps 2 and 3 could be parallelized (both work on `search.rs` internals), but the module is small enough that inline execution is simpler.

## Dependency graph

```
1 ──→ 2 ──→ 4 ──→ 5
  ╲        ╱
   → 3 ──→
```

Steps 2 and 3 are independent of each other but both depend on 1. Step 4 needs both done.

Ready to start, or adjust anything?

> **What happened:**
> `/geb:plan` decomposed the decided approach into atomic, verifiable steps:
> - Each step has a concrete "verify" condition
> - Dependencies are explicit
> - Execution strategy is justified (inline over agents — small module)
> - A dependency graph makes the structure visual
> - Step 5 is marked as stretch — honest about scope boundaries

---

### Turn 3 — Execution begins

**User:**
```
Go ahead
```

**Claude:**

*(Executes step 1...)*

Step 1 done — added `nucleo` to Cargo.toml and created `src/search.rs` with the `SearchEngine` struct. `cargo check` passes.

Moving to steps 2 and 3...

*(Executes steps 2 and 3, then step 4...)*

Steps 1-4 complete. The `search` subcommand works:

```
$ notes search "borrow check"
[0.82] Rust Borrow Checker — ~/.notes/rust-borrowing.md
[0.65] Ownership Deep Dive — ~/.notes/ownership.md
[0.41] Memory Safety Notes — ~/.notes/memory-safety.md
```

All 4 tests pass. Step 5 (interactive selection) is the stretch goal — want me to continue?

> **What happened:**
> Claude executed the plan step by step, reporting at natural milestones rather than after every micro-action. It paused at the boundary between "core" (steps 1-4) and "stretch" (step 5), letting the user decide.

---

### Turn 4 — Proactive alignment

**User:**
```
Yeah, do step 5 too.
```

**Claude:**

Done. Pressing a number after search results opens that note in `$EDITOR`.

We've covered the full plan — want me to check this against the original goal?

> **What happened:**
> After completing all steps, GEB proactively suggests alignment. This is the "Proactive Alignment" principle — when a multi-step task wraps up, suggest a goal check without waiting for the user to ask.

---

## Key Takeaways

| Principle | How it appeared |
|-----------|----------------|
| **Depth assessment** | Open-ended "add search" → Slow → structured thinking |
| **Investigate while asking** | Shared codebase findings alongside the approach question |
| **think → plan handoff** | Direction decided in think, decomposed in plan |
| **Atomic verifiable steps** | Each step has a concrete "verify" condition |
| **Dependency surfacing** | Visual graph shows what can be parallelized |
| **Natural milestone reporting** | Status updates at meaningful boundaries, not every line |
| **Proactive alignment** | Suggested goal check at task completion |
