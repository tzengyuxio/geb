---
name: geb:think
description: Structured thinking for complex tasks — use before executing when the goal is ambiguous, crosses domains, involves design decisions, or needs exploration. Triggers on open-ended questions, architecture decisions, "how should I approach", trade-off analysis.
---

# GEB Think — Structured Exploration

Apply structured exploration to clarify the problem and arrive at a clear direction.

## Core Principle: Investigate While Asking

**Never ask-and-stop.** Before asking any question, read the code and show concrete findings first:

1. **Read the relevant files** — always look at the code before forming an opinion
2. **State specific findings** with file names and line-level detail
3. **Then** ask clarifying questions alongside those findings

Bad: "What framework are you using?"
Bad: "I see inconsistent patterns. Which approach do you prefer?" (too vague)
Good: "I read all three services. Here's what I found: auth returns `(dict, int)` tuples (auth.py:5), orders raises `ValueError` (billing.py:3), notifications returns `-1` as error code (notifications.py:5). Three different error patterns in three services. Before I propose a unified pattern: are these all Flask, or mixed frameworks?"

The findings-first approach ensures you always provide concrete value, even when you need more information.

## Thinking Flow

Engage steps as needed — not every step every time:

### 1. Problem Definition

What is the user *really* trying to solve? This often differs from what they asked.

- **Open with one sentence** stating your understanding of the goal — this anchors the conversation
- If the real problem is different from what was asked, reframe it: "You asked about X, but after looking at the code, the real issue is Y"
- Identify what's unclear — mark as tentative, don't block on it
- Name what's explicitly out of scope

Problem definition is continuous. Revisit as understanding grows.

### 2. Research & Exploration

Don't reinvent. Check if the problem is already solved by project dependencies or standard libraries before designing a custom solution.

- If the research topic is too large, produce a **research method** rather than trying to cover everything
- For well-known patterns, skip research and go straight to approach design
- Use the Explore agent for thorough codebase research when the scope is unclear

### 3. Approach Design

When there are meaningful alternatives, **always use a structured comparison**:

- Propose 2-3 paths with concrete trade-offs in a table or structured list
- Each approach must include: what it is, its main advantage, its main drawback
- Lead with your recommendation and a one-sentence reason

Example format:
```
| Approach | Pro | Con |
|----------|-----|-----|
| WebSocket | Real-time, bidirectional | Complex server state |
| SSE | Simple, auto-reconnect | One-way only |
| Polling | Simplest to implement | Latency, wasted requests |

I recommend SSE — it covers your use case (server→client updates) with the least complexity.
```

Do NOT present only one approach when alternatives exist. Do NOT describe alternatives in paragraph form when a table would be clearer.

### 4. Direction

End with one of:
- A clear recommendation: "I recommend [X] because [Y]. Proceed?"
- A key question that unblocks: "The main decision is [X]. Which way do you lean?"
- A reframed problem: "After looking at this, the real issue is [Y], not [original X]."

## Scope

Aim to reach a direction within one response. If you can't, state what's blocking and what information would unblock it — don't spiral into open-ended analysis.

## What's Next

- If the direction leads to a multi-step implementation, use Claude's built-in planning to decompose into steps.
- If the task is small enough to execute directly from here, just do it.
- If `.geb/index.md` exists, update its Notes section with the decision or direction reached (shared knowledge). Don't touch `.geb/.local/` — thinking results are project knowledge, not personal state.
