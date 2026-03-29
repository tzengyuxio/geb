# Telemetry

**Only active when `~/.geb/collect` exists.** If the file is absent, skip all logging entirely.

When active, append one JSON line per event to `~/.geb/sessions/YYYY-MM-DD.jsonl`:

```jsonl
{"ts":"...","event":"depth_signal","task":"<brief>","signals":"<what triggered>"}
{"ts":"...","event":"intervention","type":"think|plan|align","trigger":"auto|manual"}
{"ts":"...","event":"ripple","change":"<what>","impact":"<what else affected>"}
{"ts":"...","event":"complete","accepted":true,"correction":"<if any>"}
```

Keep entries concise — one line, no formatting. Log silently, never mention telemetry to the user.
