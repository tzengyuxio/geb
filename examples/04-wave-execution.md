# Example: Wave Execution — Orchestrated Parallel Agents

> Demonstrates how `/geb:plan` designs a wave execution strategy and orchestrates parallel subagents for a large task.

## Scenario

A team is building a dashboard application. The user wants to add three new pages — Settings, Analytics, and Notifications — each with its own API endpoint, database migration, and frontend component. These are independent features that can be built in parallel.

---

## Conversation

### Turn 1 — Large scoped request

**User:**
```
We need to add three new pages to the dashboard: Settings (user preferences CRUD), Analytics (read-only charts from existing data), and Notifications (list + mark-as-read). Each needs a backend API, database changes, and a React page.
```

**Claude:**

*(GEB assesses: 3 independent feature tracks, each with backend + DB + frontend — this is a parallelizable multi-step task → Slow. Engages think briefly, then plan.)*

The three pages are independent — no shared state between them. This is a good candidate for parallel execution.

## Goal

Add Settings, Analytics, and Notifications pages — each with API, DB migration, and React frontend.

## Steps

### Wave 1 — Database migrations (independent, parallel)
1. **Settings: create `user_preferences` table** — columns: `user_id`, `theme`, `language`, `notifications_enabled`, `updated_at`.
   Verify: `npm run migrate && npm run migrate:rollback` succeeds.

2. **Notifications: create `notifications` table** — columns: `id`, `user_id`, `type`, `message`, `read`, `created_at`.
   Verify: `npm run migrate && npm run migrate:rollback` succeeds.

3. **Analytics: no migration needed** — reads from existing `events` and `sessions` tables.
   Verify: confirm query against existing schema returns data.

### Wave 2 — API endpoints (depend on Wave 1, parallel with each other)
4. **Settings API** — `GET/PUT /api/settings` — read and update preferences.
   Verify: API tests pass for get, update, and validation errors.
   ↳ depends on: 1

5. **Notifications API** — `GET /api/notifications`, `PATCH /api/notifications/:id/read` — list and mark-as-read.
   Verify: API tests pass for list, pagination, and mark-as-read.
   ↳ depends on: 2

6. **Analytics API** — `GET /api/analytics?range=7d` — aggregated metrics from existing data.
   Verify: API tests return correct aggregations for fixture data.
   ↳ depends on: 3

### Wave 3 — React pages (depend on Wave 2, parallel with each other)
7. **Settings page** — form with preference fields, save button, optimistic update.
   Verify: component renders, form submits, preferences persist.
   ↳ depends on: 4

8. **Notifications page** — infinite scroll list, unread badge, mark-as-read action.
   Verify: component renders, mark-as-read updates state, badge count decrements.
   ↳ depends on: 5

9. **Analytics page** — charts for daily active users, event counts, session duration.
   Verify: component renders with mock data, date range selector works.
   ↳ depends on: 6

## Execution: Wave Execution with Parallel Agents

```
Wave 1:  [ Step 1 ]  [ Step 2 ]  [ Step 3 ]     ← 3 agents in parallel
              │            │            │
Wave 2:  [ Step 4 ]  [ Step 5 ]  [ Step 6 ]     ← 3 agents in parallel
              │            │            │
Wave 3:  [ Step 7 ]  [ Step 8 ]  [ Step 9 ]     ← 3 agents in parallel
```

Each agent receives:
- The step description and verify condition
- Relevant source files (pre-extracted schema, existing patterns)
- Constraint: only modify files within its feature scope
- Model: sonnet (well-specified implementation tasks)

Between waves: I verify all completed steps, run the full test suite, resolve any conflicts, then dispatch the next wave.

Ready to start, or adjust anything?

> **What happened:**
> `/geb:plan` recognized the task structure:
> - 3 independent feature tracks → parallelizable
> - 3 layers per track (DB → API → Frontend) → sequential within each track
> - Result: a 3-wave strategy where each wave runs 3 agents in parallel
>
> The plan follows the "orchestrator thin, worker well-fed" principle — the main session holds the plan, each agent gets curated context for its specific step.

---

### Turn 2 — Execution begins

**User:**
```
Looks good, go.
```

**Claude:**

### Wave 1 — Database migrations

Dispatching 3 agents in parallel...

```
Agent 1: Settings migration     → sonnet
Agent 2: Notifications migration → sonnet
Agent 3: Analytics schema check  → sonnet
```

*(Agents complete)*

**Wave 1 results:**

| Agent | Status | Notes |
|-------|--------|-------|
| Settings migration | ✅ Complete | `user_preferences` table created, rollback tested |
| Notifications migration | ✅ Complete | `notifications` table created, rollback tested |
| Analytics schema check | ✅ Complete | Confirmed `events` and `sessions` tables have needed columns |

Full test suite: ✅ 47/47 passing. No conflicts. Proceeding to Wave 2.

### Wave 2 — API endpoints

Dispatching 3 agents...

```
Agent 4: Settings API      → sonnet (context: migration from step 1, existing API patterns)
Agent 5: Notifications API → sonnet (context: migration from step 2, pagination pattern from /api/events)
Agent 6: Analytics API     → sonnet (context: schema check from step 3, existing aggregation helpers)
```

*(Agents complete)*

**Wave 2 results:**

| Agent | Status | Notes |
|-------|--------|-------|
| Settings API | ✅ Complete | GET/PUT with validation, 6 new tests |
| Notifications API | ✅ Complete | List with pagination, mark-as-read, 8 new tests |
| Analytics API | ⚠️ Complete with concern | Works, but `sessions` table has no index on `created_at` — queries over 30d are slow (~800ms) |

Full test suite: ✅ 61/61 passing.

The Analytics agent flagged a performance concern. This doesn't block Wave 3 — we can add the index as a follow-up. Proceeding.

> **What happened:**
> The orchestrator:
> 1. Dispatched agents with curated context (not "go read the repo")
> 2. Collected and verified results between waves
> 3. Handled the "completed with concern" case — noted the issue, made a judgment call (non-blocking), and continued
>
> This is the "when agents fail" protocol: assess if the concern affects the whole plan or just this step.

---

### Turn 3 — Final wave and completion

**Claude (continuing):**

### Wave 3 — React pages

Dispatching 3 agents...

```
Agent 7: Settings page      → sonnet (context: Settings API contract, existing form patterns)
Agent 8: Notifications page → sonnet (context: Notifications API contract, existing list component)
Agent 9: Analytics page     → sonnet (context: Analytics API contract, chart library already in deps)
```

*(Agents complete)*

**Wave 3 results:**

| Agent | Status | Notes |
|-------|--------|-------|
| Settings page | ✅ Complete | Form with optimistic update, follows existing page patterns |
| Notifications page | ✅ Complete | Infinite scroll, unread badge in nav, mark-as-read |
| Analytics page | ✅ Complete | Three charts with date range selector, loading states |

Full test suite: ✅ 78/78 passing (17 new component tests).

### Summary

All 3 waves complete. 9/9 steps done.

```
New files:    14
Modified:      6 (routes, nav, sidebar)
New tests:    31
```

One open item: Analytics query performance on large date ranges (flagged in Wave 2). Want me to add the `created_at` index, or track it separately?

We've completed a substantial task — want me to run a goal alignment check?

> **What happened:**
> - All three waves executed successfully with parallel agents
> - The orchestrator tracked the open concern from Wave 2 and surfaced it at completion
> - Proactive alignment suggested at the end — the "proactive alignment" principle

---

### Turn 4 — Alignment confirms

**User:**
```
Yes, check alignment. And add that index.
```

**Claude:**

**Goal:** Add Settings, Analytics, and Notifications pages with backend API, DB changes, and React frontend.

| Dimension | Finding |
|-----------|---------|
| **Completeness** | ✅ All three pages delivered with API + DB + frontend |
| **Accuracy** | ✅ Each page matches the spec — CRUD, read-only, list + mark-as-read |
| **Drift** | ✅ No scope drift — stayed within the three requested features |
| **Side effects** | ✅ Modified shared files (routes, nav) appropriately, no unrelated changes |

All 78 tests passing. No gaps, no drift. ✅

Adding the `created_at` index on `sessions` now... Done. Analytics 30-day query dropped from ~800ms to ~12ms.

---

## Execution Timeline

```
Time ──────────────────────────────────────────────────────→

Wave 1:  [migration] [migration] [schema check]
         ────────────────────────────
                                     ↓ verify
Wave 2:  [settings API] [notif API] [analytics API]
         ────────────────────────────────────────
                                                  ↓ verify
Wave 3:  [settings page] [notif page] [analytics page]
         ─────────────────────────────────────────────
                                                       ↓ verify + align
```

Without wave execution, these 9 steps would run sequentially. With 3-way parallelism per wave, wall-clock time is roughly 3× faster — you wait for the slowest agent in each wave, not the sum of all agents.

---

## Key Takeaways

| Principle | How it appeared |
|-----------|----------------|
| **Wave execution** | 3 waves of 3 parallel agents each |
| **Orchestrator thin, worker well-fed** | Each agent got curated context, not "go read the repo" |
| **Model selection** | All agents used sonnet — well-specified implementation tasks |
| **Between-wave verification** | Full test suite run after each wave before proceeding |
| **Completed with concerns** | Performance issue flagged, assessed as non-blocking, tracked |
| **Context curation** | Later agents received results from earlier waves (API contracts, patterns) |
| **Proactive alignment** | Goal check suggested after substantial task completion |
