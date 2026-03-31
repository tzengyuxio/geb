# GEB Design Philosophy

## The Fundamental Insight

An LLM has one autoregressive process reading one set of instructions. It does not have two cognitive systems. Trying to make it behave as both System 1 (fast, intuitive) and System 2 (slow, deliberate) through a single set of instructions creates an irresolvable contradiction:

> You cannot instruct an LLM to "act as if it has no instructions." Every rule about "be fast, don't over-think" reminds the model it is operating within a framework, producing the opposite of the intended effect.

This was validated empirically: the self-improvement loop consistently showed that strengthening Fast-mode instructions degraded Slow-mode scenarios and vice versa. This is not a tuning problem — it is a structural conflict inherent in the dual-mode design.

## The Reframing

Claude's default behavior IS System 1 — intuitive, automatic, general-purpose. It already handles simple tasks well without framework intervention.

GEB's role is to be the **second circuit** — System 2. It provides the deliberate, effortful cognitive tools that Claude's defaults don't have: structured exploration, strategic planning, goal alignment, focus, and memory.

```
Claude default  = System 1 (intuitive, automatic)
GEB             = System 2 (deliberate, effortful)

GEB does not control System 1.
GEB is a separate circuit that activates when System 1 is insufficient.
```

## Architecture Mapping

### Prelude = Salience Network (not System 2)

Prelude is injected into the system prompt, so it technically operates within System 1's context. It is NOT System 2 itself — it is a **sentinel within System 1** that watches for signals requiring System 2 engagement.

This is analogous to the brain's salience network: an automatic mechanism whose sole job is to detect "this situation needs deliberate attention" and activate the appropriate cognitive resources.

Design implication: **the sentinel must be extremely lightweight.** The heavier it is, the more it disrupts System 1's natural operation. Signal detection + minimal guardrails, nothing more.

### geb:think / geb:debug / geb:review / geb:align = System 2 Tools

These are the actual System 2 cognitive tools:
- **geb:think** — structured exploration, problem reframing, approach comparison
- **geb:debug** — systematic diagnosis, root cause analysis
- **geb:review** — multi-dimensional quality audit
- **geb:align** — goal verification, drift detection

They are activated on demand (by prelude's signal detection or by explicit user invocation), not always-on.

### .geb/ State = Working Memory & Long-term Memory

Project state that persists across sessions — the equivalent of writing things down to extend cognitive capacity beyond a single "thought."

## Disciplines: Trained Reflexes

Disciplines (evidence-before-claims, search-before-building, anti-rationalization) occupy a unique position in this model. They are not System 2 deliberation, nor pure System 1 automaticity. They are **trained reflexes** — habits that System 2 establishes, which System 1 then executes automatically.

A doctor washing hands before surgery doesn't engage deliberate cognition each time — but the habit was deliberately trained. Similarly, GEB's disciplines are lightweight instructions that become automatic guardrails.

### Discipline Evolution: From System 2 to System 1

This maps to GEB's organic/self-bootstrapping philosophy:

1. **Discovery** (System 2): Through repeated use, GEB notices a pattern — e.g., "this user's codebase has a recurring issue with unvalidated API inputs"
2. **Codification** (System 2 → bridge): GEB proposes a new discipline, skill, or CLAUDE.md rule
3. **Automation** (System 1): Once written into CLAUDE.md or a user-space skill, the pattern becomes part of the default context — triggered automatically without deliberate intervention

```
Observation (System 2)
    → Proposed habit (.geb/proposals/)
        → User approval (geb:groove)
            → CLAUDE.md / user skill (System 1 reflex)
```

This is the cognitive equivalent of GEB's "organic growth" and "self-bootstrapping" principles: the framework learns from its own operation, converting expensive System 2 insights into cheap System 1 reflexes. Over time, the user's environment becomes increasingly tuned — not because GEB controls more behavior, but because discovered patterns graduate into automated defaults.

### v2 Implementation: The Discipline Pipeline

The evolution mechanism is now concrete infrastructure, not just a concept:

- **Detection**: Prelude watches for recurring patterns (3+ occurrences with telemetry, 2+ within a session)
- **Proposal**: Writes structured proposals to `.geb/proposals/` with evidence, proposed rule, and target
- **Review**: `/geb:groove` lets the user list, preview, approve, or reject proposals
- **Graduation**: Approved proposals become CLAUDE.md rules (simple patterns) or user skills (complex patterns)
- **Guard rails**: Never auto-apply; conservative trigger thresholds to avoid proposal spam

## What GEB Does NOT Do

- **Does not manage simple task behavior.** Claude handles these by default.
- **Does not suppress Claude's natural tendencies.** No "silent rule," no "don't be verbose" instructions.
- **Does not classify tasks into depth categories.** It only detects signals that depth is needed.
- **Does not try to make the LLM behave as if the framework doesn't exist.** That is a paradox.

## Historical Context

GEB v0 was inspired by Kahneman's "Thinking, Fast and Slow" and attempted to implement both systems within a single skill (prelude). The dual-mode approach:
- Used Fast/Medium/Slow classification
- Included a "Silent Rule" (in Fast mode, user must not feel the framework)
- Required Dynamic Routing to shift between modes

This was abandoned on 2026-03-29 after empirical evidence showed:
1. Fast-mode scenarios scored SAME as control (no GEB value added)
2. Improvement attempts consistently caused cross-mode regressions
3. The Silent Rule was a self-referential paradox

The current "depth guard" architecture resolves these issues by accepting that System 1 doesn't need management — only System 2 needs to be provided.
