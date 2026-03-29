---
pattern: API endpoints missing input validation on user-submitted fields
occurrences: 4
target: skill
status: pending
created: 2026-03-29
---

## Evidence

1. `POST /api/orders` — accepted negative quantities, caused billing errors.
2. `PUT /api/users/:id` — no email format check, stored invalid emails.
3. `POST /api/comments` — no length limit, allowed 50KB comments that broke the feed.
4. `PATCH /api/settings` — accepted unknown fields silently, ignored by backend but confused frontend.

## Proposed Rule

Create a project skill `api-validation` with:
- Checklist: for every new/modified API endpoint, validate all user-submitted fields (type, format, range, length)
- Use pydantic/zod (already in deps) rather than manual checks
- Reference: link to project's existing validation patterns in `src/middleware/validate.py`

## Rationale

The project has pydantic in deps but inconsistent usage. 4 separate incidents of missing validation in 2 weeks. A skill is more appropriate than a CLAUDE.md rule because the validation patterns are detailed enough to need examples and references.
