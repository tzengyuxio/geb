#!/usr/bin/env python3
"""
GEB Telemetry Analyzer

Reads session logs from ~/.geb/sessions/*.jsonl and produces insights.

Usage:
  python3 scripts/analyze.py                     # analyze all logs
  python3 scripts/analyze.py --days 7            # last 7 days
  python3 scripts/analyze.py --json              # machine-readable output
  python3 scripts/analyze.py --feed-improve      # output feedback for improve loop
"""

import sys
import json
import os
from pathlib import Path
from datetime import datetime, timedelta
from collections import Counter, defaultdict

SESSIONS_DIR = Path.home() / ".geb" / "sessions"


def load_events(days: int | None = None) -> list[dict]:
    """Load all events, optionally filtered by recency."""
    if not SESSIONS_DIR.exists():
        return []

    cutoff = None
    if days:
        cutoff = (datetime.now() - timedelta(days=days)).strftime("%Y-%m-%d")

    events = []
    for log_file in sorted(SESSIONS_DIR.glob("*.jsonl")):
        date_str = log_file.stem  # YYYY-MM-DD
        if cutoff and date_str < cutoff:
            continue
        with open(log_file) as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    events.append(json.loads(line))
                except json.JSONDecodeError:
                    continue

    return events


def analyze(events: list[dict]) -> dict:
    """Analyze events and produce insights."""
    if not events:
        return {"total_events": 0, "message": "No telemetry data found."}

    # Basic counts
    event_types = Counter(e.get("event") for e in events)

    # Depth routing analysis
    depth_events = [e for e in events if e.get("event") == "depth_routing"]
    depth_counts = Counter(e.get("depth") for e in depth_events)

    # Override analysis
    overrides = [e for e in events if e.get("event") == "override"]
    override_patterns = Counter(
        f"{e.get('from', '?')} → {e.get('to', '?')}" for e in overrides
    )

    # Skill usage
    skill_events = [e for e in events if e.get("event") == "skill"]
    skill_counts = Counter(e.get("name") for e in skill_events)
    skill_triggers = Counter(e.get("trigger") for e in skill_events)

    # Dynamic routing
    upgrades = [e for e in events if e.get("event") == "upgrade"]
    downgrades = [e for e in events if e.get("event") == "downgrade"]

    # Task completion
    completions = [e for e in events if e.get("event") == "complete"]
    accepted = sum(1 for e in completions if e.get("accepted"))
    corrected = [e for e in completions if e.get("correction")]

    # Override rate (how often does the user disagree with depth routing)
    override_rate = (
        len(overrides) / len(depth_events) if depth_events else 0
    )

    # Per-day activity
    daily = defaultdict(int)
    for e in events:
        ts = e.get("ts", "")[:10]  # YYYY-MM-DD
        if ts:
            daily[ts] += 1

    return {
        "total_events": len(events),
        "date_range": {
            "first": min(daily.keys()) if daily else None,
            "last": max(daily.keys()) if daily else None,
            "active_days": len(daily),
        },
        "event_types": dict(event_types),
        "depth_routing": {
            "total": len(depth_events),
            "distribution": dict(depth_counts),
        },
        "overrides": {
            "total": len(overrides),
            "rate": round(override_rate, 3),
            "patterns": dict(override_patterns),
        },
        "skills": {
            "invocations": dict(skill_counts),
            "trigger_types": dict(skill_triggers),
        },
        "dynamic_routing": {
            "upgrades": len(upgrades),
            "downgrades": len(downgrades),
        },
        "completions": {
            "total": len(completions),
            "accepted": accepted,
            "corrected": len(corrected),
            "corrections": [e.get("correction") for e in corrected],
        },
    }


def generate_feedback(analysis: dict) -> str:
    """Generate feedback text suitable for the improve loop."""
    lines = ["# GEB Telemetry Feedback (auto-generated)", ""]

    overrides = analysis.get("overrides", {})
    if overrides.get("total", 0) > 0:
        rate = overrides["rate"]
        lines.append(f"## Override Rate: {rate:.0%}")
        lines.append(f"Users overrode depth routing {overrides['total']} times.")
        lines.append("Patterns:")
        for pattern, count in overrides.get("patterns", {}).items():
            lines.append(f"  - {pattern}: {count} times")
        lines.append("")

        if rate > 0.3:
            lines.append(
                "HIGH OVERRIDE RATE — depth routing is frequently wrong. "
                "Focus improvements on depth signal accuracy."
            )
        lines.append("")

    depth = analysis.get("depth_routing", {})
    dist = depth.get("distribution", {})
    if dist:
        total = sum(dist.values())
        lines.append("## Depth Distribution")
        for d, count in sorted(dist.items()):
            pct = count / total * 100
            lines.append(f"  - {d}: {count} ({pct:.0f}%)")
        lines.append("")

    skills = analysis.get("skills", {})
    triggers = skills.get("trigger_types", {})
    if triggers:
        auto = triggers.get("auto", 0)
        manual = triggers.get("manual", 0)
        total = auto + manual
        if total > 0:
            lines.append(
                f"## Skill Triggers: {auto} auto, {manual} manual "
                f"({auto/total:.0%} auto-trigger rate)"
            )
            if auto / total < 0.5:
                lines.append(
                    "LOW AUTO-TRIGGER RATE — skill descriptions may need "
                    "stronger trigger conditions."
                )
            lines.append("")

    corrections = analysis.get("completions", {}).get("corrections", [])
    if corrections:
        lines.append("## User Corrections at Completion")
        for c in corrections:
            lines.append(f"  - {c}")
        lines.append("")

    return "\n".join(lines)


def print_report(analysis: dict):
    """Print human-readable report."""
    a = analysis
    print(f"\n{'='*60}")
    print(f"  GEB Telemetry Report")
    print(f"{'='*60}")
    print(f"  Events:       {a['total_events']}")

    dr = a.get("date_range", {})
    if dr.get("first"):
        print(f"  Period:       {dr['first']} to {dr['last']} ({dr['active_days']} active days)")

    print()

    # Depth routing
    depth = a.get("depth_routing", {})
    if depth.get("total"):
        print(f"  Depth Routing ({depth['total']} decisions):")
        dist = depth.get("distribution", {})
        total = sum(dist.values())
        for d in ["fast", "medium", "slow"]:
            count = dist.get(d, 0)
            pct = count / total * 100 if total else 0
            bar = "█" * int(pct / 5) + "░" * (20 - int(pct / 5))
            print(f"    {d:8s}  {bar}  {count} ({pct:.0f}%)")
        print()

    # Overrides
    overrides = a.get("overrides", {})
    if overrides.get("total"):
        print(f"  Overrides: {overrides['total']} ({overrides['rate']:.0%} of routing decisions)")
        for pattern, count in overrides.get("patterns", {}).items():
            print(f"    {pattern}: {count}")
        print()

    # Skills
    skills = a.get("skills", {})
    invocations = skills.get("invocations", {})
    if invocations:
        print(f"  Skill Usage:")
        for sk, count in sorted(invocations.items(), key=lambda x: -x[1]):
            trigger = skills.get("trigger_types", {})
            print(f"    {sk:14s}  {count} invocations")
        triggers = skills.get("trigger_types", {})
        if triggers:
            print(f"    Triggers: {triggers.get('auto', 0)} auto, {triggers.get('manual', 0)} manual")
        print()

    # Dynamic routing
    dyn = a.get("dynamic_routing", {})
    if dyn.get("upgrades") or dyn.get("downgrades"):
        print(f"  Dynamic Routing: {dyn['upgrades']} upgrades, {dyn['downgrades']} downgrades")
        print()

    # Completions
    comp = a.get("completions", {})
    if comp.get("total"):
        print(f"  Completions: {comp['total']} total, {comp['accepted']} accepted, {comp['corrected']} corrected")
        if comp.get("corrections"):
            print(f"  Corrections:")
            for c in comp["corrections"]:
                print(f"    - {c}")
        print()


def main():
    days = None
    output_json = "--json" in sys.argv
    feed_improve = "--feed-improve" in sys.argv

    if "--days" in sys.argv:
        idx = sys.argv.index("--days")
        days = int(sys.argv[idx + 1])

    events = load_events(days)
    analysis = analyze(events)

    if output_json:
        print(json.dumps(analysis, indent=2))
    elif feed_improve:
        print(generate_feedback(analysis))
    else:
        if analysis.get("total_events", 0) == 0:
            print("\nNo telemetry data found.")
            print(f"Enable collection: touch ~/.geb/collect")
            print(f"Logs will appear in: {SESSIONS_DIR}/")
        else:
            print_report(analysis)


if __name__ == "__main__":
    main()
