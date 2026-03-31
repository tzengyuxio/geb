---
name: geb:debug
description: Systematic diagnosis when something isn't working as expected — use for bugs, failures, unexpected behavior, or any "why isn't this working?" situation. Triggers on "debug this", "why is this broken", "this isn't working", "help me figure out what's wrong", or when a fix attempt has already failed.
---

# GEB Debug — Systematic Diagnosis

Something isn't working. Find out why before trying to fix it.

## The Iron Rule

**No fix without root cause.** If you don't know why it's broken, your fix is a guess. Guesses create new problems.

## Workflow

### 1. Symptoms

**Read the code first.** Before asking the user anything, read the relevant files to understand the current state. The answer is often in the code.

State what's actually happening vs what's expected. Be specific:

- Bad: "it's broken"
- Good: "POST /api/orders returns 500, expected 201. Started after yesterday's deploy."

Only ask the user for more information if you've read the available code and still can't determine the issue. Never ask for information you can find yourself.

### 2. Reproduce

Can you make it happen reliably?

- **Read the test file and the code under test** — trace the execution path mentally or by reading
- Run the failing test, hit the endpoint, execute the command
- If not reproducible → gather more data (logs, env differences, timing), don't guess
- Note: for non-code issues ("why did this campaign underperform?"), reproduction means gathering the data that shows the gap between expected and actual

### 3. Isolate

Narrow down where the problem lives:

- **Binary search**: which layer/component/step is the first one that goes wrong?
- **Check recent changes**: `git diff`, recent commits, new deps, config changes
- **Check boundaries**: what goes in vs what comes out at each component boundary

Don't jump to the deepest layer first. Start broad, narrow systematically.

### 4. Root Cause

State the root cause in one sentence before proposing any fix:

- "The login endpoint hashes with md5 but create_user hashes with sha256 — they never match."
- "The campaign targeted 18-24 but the content assumed 30+ decision-makers."

If you can't state the root cause clearly, you're not done isolating.

### 5. Fix and Verify

Now fix it. Then verify:

- Run the originally failing test/command — does it pass?
- Run adjacent tests — did the fix break anything else?
- For non-code: does the data confirm the fix addresses the root cause?

"Should work now" is not verification. Evidence or it didn't happen.

## When NOT to use this skill

- The problem is obvious and the fix is trivial (typo, missing import) → just fix it
- You're exploring options, not diagnosing a failure → use `/geb:think`
- You're checking quality of completed work → use `/geb:review`
