# Example: Depth Guard — When GEB Stays Silent vs Intervenes

> Demonstrates the core depth guard behavior: GEB does nothing on simple tasks (System 1 handles them), and only intervenes when it detects signals that deeper thinking is needed.

## Scenario

A developer is working on a Python Flask API. They alternate between simple edits and complex design questions — showing how GEB adapts without any explicit mode switching.

---

## Conversation

### Turn 1 — Simple rename (GEB stays silent)

**User:**
```
Rename `get_user_info` to `get_user_profile` in src/api/users.py
```

**Claude:**

Done. Renamed `get_user_info` → `get_user_profile` in `src/api/users.py` and updated the 3 call sites:
- `src/api/routes.py:42`
- `src/api/routes.py:87`
- `tests/test_users.py:15`

All tests pass.

> **What happened:** No depth signals detected — explicit request, clear scope, imperative tone. Claude's default behavior (System 1) handles this perfectly. GEB adds nothing, and that's correct. No framework meta-commentary, no "I've assessed this as a simple task."

---

### Turn 2 — Typo fix (GEB stays silent)

**User:**
```
There's a typo on line 23 — "recieve" should be "receive"
```

**Claude:**

Fixed.

> **What happened:** One word. The task was trivial, the outcome obvious. System 1 at its best.

---

### Turn 3 — Ripple impact detected (Dynamic Awareness)

**User:**
```
Change the return type of `get_user_profile` from dict to UserProfile dataclass
```

**Claude:**

Done. Changed return type to `UserProfile` and updated the function body.

Note: this also affects `src/api/serializers.py` — the `serialize_user` function expects a dict. I've updated it to accept `UserProfile`. Tests pass.

> **What happened:** Still no depth signals for the task itself — it's a clear, specific request. But GEB's Dynamic Awareness detected ripple impact: a change to shared code (return type contract) that affects another module. It surfaced this in one sentence without interrupting the flow.

---

### Turn 4 — Depth signals detected (GEB intervenes)

**User:**
```
I want to redesign our API error handling across all services
```

**Claude:**

This crosses multiple services with inconsistent patterns — I can see auth returns tuples, orders raises exceptions, and inventory uses boolean flags. Before proposing a unified approach:

- What's the target consumer? (Frontend SPA, mobile app, third-party integrations?)
- Is there a preferred HTTP status code strategy? (e.g., always 200 with error body vs semantic status codes)

Meanwhile, here's what I've found so far...

*(Engages structured exploration via geb:think)*

> **What happened:** Strong depth signals detected — "redesign" (open-ended goal), "across all services" (cross-domain scope), inconsistent patterns (design decisions needed). GEB shifted from silent to active, engaging structured thinking. Note the "investigate while asking" pattern: Claude shares findings alongside questions, not just ask-and-stop.

---

### Turn 5 — User explicitly reports recurring pattern (Discipline evolution)

**User:**
```
This is the third time this week I've had to fix missing input validation on an API endpoint. It keeps happening.
```

**Claude:**

I've noticed this pattern too. Created a discipline proposal in `.geb/proposals/validate-api-inputs.md` — it suggests adding a project rule to always validate user-submitted fields using pydantic (already in your deps).

Run `/geb:groove` to review and apply it.

For now, want me to fix the current endpoint?

> **What happened:** The user explicitly reported a recurring pattern. GEB's discipline evolution triggered: it created a formal proposal that can be reviewed and, if approved, graduated into a CLAUDE.md rule — becoming an automatic reflex (System 1) for future sessions.

---

## Key Takeaways

| Principle | How it appeared |
|-----------|----------------|
| **System 1 is default** | Simple tasks get zero framework overhead |
| **GEB is a depth guard** | Only intervenes when depth signals are present |
| **Dynamic Awareness** | Ripple impact surfaced mid-task without disrupting flow |
| **Structured thinking on demand** | Complex task → geb:think engages automatically |
| **Discipline evolution** | Recurring pattern → proposal → potential System 1 graduation |
| **No mode switching** | No Fast/Medium/Slow labels — just natural escalation |
