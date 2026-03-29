# Example: Align — Goal Verification and Drift Detection

> Demonstrates how `/geb:align` catches scope drift, missing requirements, and over-delivery during a real task.

## Scenario

A user asked Claude to "add user authentication to our Express API." Over the course of implementation, several things happened: OAuth was added alongside password auth, rate limiting was included, and the original requirement for email verification was forgotten. `/geb:align` catches all of this.

---

## Conversation (abbreviated — showing the alignment phase)

### Earlier in the session

**User (original request):**
```
Add user authentication to our Express API. We need:
- Email/password signup and login
- Email verification before account activation
- JWT tokens for session management
- Password reset flow
```

**Claude:** *(Went through think → plan, then executed 7 implementation steps over several turns.)*

---

### The alignment check

**User:**
```
/geb:align
```

**Claude:**

### Goal vs Result

**Original goal:** Email/password auth with email verification, JWT sessions, and password reset.

| Dimension | Finding |
|-----------|---------|
| **Completeness** | ⚠️ **Gap found.** Email verification is not implemented. `POST /auth/signup` creates an active account immediately — there's no verification token, no confirmation email, no "pending" account state. |
| **Accuracy** | ✅ JWT session management works correctly. Password reset flow is complete with token expiry. |
| **Drift** | ⚠️ **Scope expanded.** I added Google OAuth (`GET /auth/google`) and rate limiting on `/auth/login` (5 attempts/min). Neither was requested. |
| **Side effects** | ✅ No unintended changes to existing routes or middleware. |

### Automated verification

```
✅  npm test — 23/23 passing
✅  eslint — no errors
⚠️  No tests for email verification (because it wasn't implemented)
```

### Summary

- **Missing:** Email verification — the second item in your original requirements
- **Over-delivered:** OAuth and rate limiting — useful but not requested
- **Core auth:** Working correctly

### Recommended next steps

1. **Implement email verification** — this was an explicit requirement. I can plan this as a follow-up.
2. **Decide on OAuth and rate limiting** — keep, revert, or defer to a separate PR?

> **What happened:**
> `/geb:align` went back to the user's original request and systematically compared it against what was actually built:
>
> 1. **Re-read the original goal** — the user's 4-bullet list
> 2. **Compared on 4 dimensions** — found a gap (email verification), drift (OAuth + rate limiting), and confirmed accuracy
> 3. **Ran automated checks** — tests pass, but the absence of verification tests is itself a signal
> 4. **Surfaced findings directly** — no sugar-coating, clear categorization
> 5. **Proposed next steps** — actionable, not just diagnostic

---

### User responds to alignment findings

**User:**
```
Oh wow, I totally forgot about email verification too. Keep the OAuth, revert the rate limiting (we handle that at the load balancer), and plan the email verification.
```

**Claude:**

Reverted rate limiting middleware — removed `src/middleware/rate-limit.js` and its references in `src/routes/auth.js`.

For email verification, I'll plan the implementation:

## Goal

Add email verification: new accounts start inactive, receive a verification email, and activate via a confirmation link.

## Steps

1. **Add `verified` field to User model** — default `false`, block login when unverified.
   Verify: existing signup test fails (account is now inactive by default).

2. **Create verification token system** — generate a signed token on signup, store expiry.
   Verify: unit test for token generation and validation.

3. **Add email sending** — `POST /auth/signup` triggers a verification email with the token link.
   Verify: test with mocked email transport confirms email is queued.

4. **Add verification endpoint** — `GET /auth/verify/:token` activates the account.
   Verify: integration test — signup → verify → login succeeds.

Ready to start?

> **What happened:**
> Claude acted on all three decisions immediately:
> - Kept OAuth (no action needed)
> - Reverted rate limiting (clean removal)
> - Planned email verification (re-entered `/geb:plan`)
>
> The alignment check caught a real oversight that both the user and Claude had missed during implementation. This is the core value of `/geb:align` — systematic comparison against the *original intent*, not just "does the code work?"

---

## When align catches different issues

### Drift that's actually good

Sometimes scope drift is the right call. Align surfaces it; the user decides:

```
Drift: Added input sanitization on all auth endpoints.
This wasn't requested, but prevents XSS in user-submitted fields.
→ Recommend keeping.
```

### Subtle accuracy issues

The code works, but solves a slightly different problem:

```
Accuracy: Password reset sends a new random password instead of a reset link.
The original request said "password reset flow" — typically this means a
link to choose a new password, not a system-generated one.
→ Confirm: did you want emailed passwords or a reset-link flow?
```

### Everything aligned

When there's nothing to flag, keep it short:

```
Goal was email/password auth with JWT and password reset.
Result delivers all four requirements. No drift, no gaps.
Tests passing, no side effects. ✅
```

---

## Key Takeaways

| Principle | How it appeared |
|-----------|----------------|
| **Re-read the original** | Went back to the user's exact 4-bullet request |
| **4-dimension check** | Completeness, accuracy, drift, side effects — systematic |
| **Automated verification** | Ran tests, noted the *absence* of expected tests |
| **Direct findings** | No "great job overall!" — just the facts |
| **Actionable next steps** | Gap → plan, over-delivery → user decides |
| **Catches human blind spots** | Both user and Claude forgot email verification |
