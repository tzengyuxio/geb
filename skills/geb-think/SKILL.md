---
name: geb-think
description: Structured thinking for complex tasks — use before executing when the goal is ambiguous, crosses domains, involves design decisions, or needs exploration. Triggers on open-ended questions, architecture decisions, "how should I approach", trade-off analysis.
---

# GEB Think — Structured Exploration

This task needs thinking before doing. Clarify the problem, explore the space, and arrive at a clear direction.

## Core Principle: Investigate While Asking

**Never ask-and-stop.** When you need clarification, simultaneously share what you've already found:

Bad: "What framework are you using?"
Good: "I see three services with inconsistent error handling — auth returns tuples, orders raises exceptions, inventory returns booleans. Before I propose a unified pattern: are these all Flask, or mixed frameworks?"

Always provide value alongside questions.

## Thinking Flow

Engage steps as needed — not every step every time:

### 1. Problem Definition

What is the user *really* trying to solve? This often differs from what they asked.

- State your understanding of the goal in one sentence
- Identify what's unclear — mark as tentative, don't block on it
- Name what's explicitly out of scope

Problem definition is continuous. Revisit as understanding grows.

### 2. Research & Exploration

Don't reinvent. Check if the problem is already solved by project dependencies or standard libraries before designing a custom solution.

- If the research topic is too large, produce a **research method** rather than trying to cover everything
- For well-known patterns, skip research and go straight to approach design

### 3. Approach Design

When there are meaningful alternatives:

- Propose 2-3 paths with concrete trade-offs
- Lead with your recommendation and why
- Keep it concise — a comparison table is better than paragraphs

### 4. Direction

End with one of:
- A clear recommendation: "I recommend [X] because [Y]. Proceed?"
- A key question that unblocks: "The main decision is [X]. Which way do you lean?"
- A reframed problem: "After looking at this, the real issue is [Y], not [original X]."

## What's Next

- If the direction leads to a multi-step implementation, suggest `/geb-plan` to decompose into steps.
- If the task is small enough to execute directly from here, just do it.
- If `.geb/index.md` exists, update it with the decision or direction reached.
