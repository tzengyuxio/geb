# Telemetry

**Only active when `~/.geb/collect` exists.** If the file is absent, skip all logging entirely.

Events are logged to `~/.geb/sessions/YYYY-MM-DD.jsonl`, one JSON line per event.

## Automatic events (via PostToolUse hook)

These are captured by `hooks/telemetry.sh` — no action needed from the skill:

```jsonl
{"ts":"...","event":"skill","skill":"geb:think","args":""}
{"ts":"...","event":"file_mod","tool":"Edit","file":"src/theme.ts"}
{"ts":"...","event":"agent","description":"Research codebase"}
```

## Manual events (logged by prelude in-context)

These require prelude to actively write to the log when the situation arises:

```jsonl
{"ts":"...","event":"miss","context":"<what the user said GEB should have caught>"}
```

## Analysis

The combination of automatic + manual events enables gap analysis:
- **Skill events** show what GEB did
- **File mod events** show the scope of changes (ripple impact candidates)
- **Miss events** show where GEB should have intervened but didn't

`scripts/analyze.py` can cross-reference these to identify improvement opportunities.

Keep entries concise — one line, no formatting. Log silently, never mention telemetry to the user.
