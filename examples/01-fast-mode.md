# Example: Fast Mode — Zero Friction Execution

> Demonstrates how GEB handles simple, clear-scope tasks with no overhead.

## Scenario

A developer is working on a Python Flask API. They need to rename a function and fix a typo in a docstring. These are small, unambiguous tasks — GEB should execute silently with no framework overhead.

---

## Conversation

### Turn 1 — Direct rename request

**User:**
```
Rename `get_user_info` to `get_user_profile` in src/api/users.py
```

**Claude:**

*(GEB silently assesses: explicit request, imperative tone, predictable scope → Fast)*

Done. Renamed `get_user_info` → `get_user_profile` in `src/api/users.py` and updated the 3 call sites:
- `src/api/routes.py:42`
- `src/api/routes.py:87`
- `tests/test_users.py:15`

All tests pass.

> **What happened behind the scenes:**
> GEB detected Fast signals (imperative tone, clear scope, single file target) and executed immediately. No "I'll rename the function for you" preamble, no "Would you like me to also update the call sites?" — just did the obvious right thing.
>
> Note the ripple impact surfacing: Claude found and updated call sites without being asked, and confirmed tests still pass. This is the "surface ripple impact, even in Fast mode" principle.

---

### Turn 2 — Typo fix

**User:**
```
There's a typo in line 23 of the same file — "recieve" should be "receive"
```

**Claude:**

Fixed.

> **What happened:** The simplest possible response. One word. The task was trivial, the outcome obvious, and the user can verify with a glance at the diff. GEB's silent rule in action — the user doesn't feel the framework's existence.

---

### Turn 3 — Fast with ripple detection

**User:**
```
Change the return type of `get_user_profile` from dict to UserProfile dataclass
```

**Claude:**

Done. Changed return type to `UserProfile` and updated the function body to construct the dataclass.

Note: this also affects `src/api/serializers.py` — the `serialize_user` function expects a dict. I've updated it to accept `UserProfile`. Tests pass.

> **What happened:** Still Fast mode — the task is clear. But the change had a ripple effect into another module. GEB surfaces this in one sentence rather than silently fixing or silently ignoring. The user knows what changed and why.

---

### Turn 4 — Fast with dynamic upgrade suggestion

**User:**
```
Add caching to `get_user_profile`
```

**Claude:**

This is more involved than a simple edit — there are decisions around cache backend (Redis vs in-memory), TTL policy, and invalidation strategy. Want me to step back and think through the approach?

Or if you just want a simple `functools.lru_cache`, I can add that now.

> **What happened:** GEB started in Fast but detected ambiguity during assessment. "Add caching" could mean an in-memory decorator or a full Redis caching layer. Instead of guessing, it offered a **dynamic upgrade** — suggesting structured thinking while also offering the simple path if that's all the user wants.
>
> This is the "Upgrade" principle: if unexpected complexity appears mid-task, suggest stepping back rather than charging ahead with assumptions.

---

### Turn 5 — User overrides to stay fast

**User:**
```
Just lru_cache is fine
```

**Claude:**

Done. Added `@lru_cache(maxsize=128)` to `get_user_profile`. Added `cache_clear()` call in `update_user_profile` to invalidate on writes.

> **What happened:** The user said "just ... is fine" — a clear Fast override. GEB immediately executes the simple version. No further questions.

---

## Key Takeaways

| Principle | How it appeared |
|-----------|----------------|
| **Silent rule** | User never sees "GEB" or "depth assessment" mentioned |
| **Zero friction** | Simple tasks get immediate execution |
| **Ripple surfacing** | Changes to shared code are noted in one sentence |
| **Dynamic upgrade** | Ambiguity triggers a suggestion, not a wall of questions |
| **User override** | "Just X is fine" immediately returns to Fast |
| **Downgrade known patterns** | `lru_cache` is a solved problem — no analysis needed |
