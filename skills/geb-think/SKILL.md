---
name: geb-think
description: Structured thinking for complex tasks — use before executing when the goal is ambiguous, crosses domains, involves design decisions, or needs exploration. Triggers on open-ended questions, architecture decisions, "how should I approach", trade-off analysis.
---

# GEB Think — Structured Exploration

You've been invoked because this task needs thinking before doing. Your job: clarify the problem, explore the space, and arrive at a clear direction.

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

What already exists? Don't reinvent.

- Check project dependencies, existing patterns, prior art
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

## Output

Produce whatever captures the current understanding best:
- A question, if the problem needs more exploration
- A comparison, if there are real trade-offs
- A recommendation, if the path is clear
- A reframing, if the original question was wrong

Form follows need. Don't force structure where none is needed.
