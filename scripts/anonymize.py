#!/usr/bin/env python3
"""
GEB Telemetry Anonymizer

Strips personal and project-specific information from session logs,
preserving only the structural signals needed for skill improvement.

Usage:
  python3 scripts/anonymize.py ~/.geb/sessions/
  python3 scripts/anonymize.py ~/.geb/sessions/ --output /tmp/anon/
"""

import sys
import json
import re
import hashlib
from pathlib import Path
from datetime import datetime

# Fields to preserve as-is (structural signals)
PRESERVE_FIELDS = {"event", "depth", "from", "to", "name", "trigger", "accepted"}

# Fields to anonymize (may contain personal/project info)
ANONYMIZE_FIELDS = {"task", "signals", "reason", "correction"}

# Fields to remove entirely
REMOVE_FIELDS = {"ts"}

# Known safe values that don't need anonymization
SAFE_VALUES = {
    "fast", "medium", "slow",
    "auto", "manual",
    "geb:think", "geb:plan", "geb:align", "prelude",
    "depth_routing", "override", "skill", "upgrade", "downgrade", "complete",
}


def categorize_task(task: str) -> str:
    """Replace task description with a category label."""
    task_lower = task.lower()

    patterns = [
        (r"renam|variable|function name", "rename"),
        (r"fix|bug|error|broken", "bugfix"),
        (r"refactor|clean|messy", "refactor"),
        (r"add|implement|create|build|new", "feature"),
        (r"test|spec|coverage", "testing"),
        (r"design|architect|approach", "design"),
        (r"review|check|verify", "review"),
        (r"document|readme|docs", "documentation"),
        (r"deploy|ship|release", "deployment"),
        (r"config|setup|install", "configuration"),
        (r"search|find|query", "search"),
        (r"migrat|convert|upgrad", "migration"),
        (r"style|css|layout|ui", "styling"),
        (r"auth|login|permission", "auth"),
        (r"api|endpoint|route", "api"),
        (r"database|schema|model", "database"),
    ]

    for pattern, category in patterns:
        if re.search(pattern, task_lower):
            return f"[{category}]"

    return "[other]"


def anonymize_text(text: str) -> str:
    """Replace specific details with generic tokens."""
    if not text:
        return ""

    # Replace file paths
    text = re.sub(r"[/\\][\w./\\-]+\.\w+", "[path]", text)

    # Replace identifiers that look project-specific
    text = re.sub(r"`[^`]+`", "[identifier]", text)

    # Replace quoted strings
    text = re.sub(r'"[^"]*"', "[string]", text)
    text = re.sub(r"'[^']*'", "[string]", text)

    # Replace URLs
    text = re.sub(r"https?://\S+", "[url]", text)

    # Collapse multiple spaces
    text = re.sub(r"\s+", " ", text).strip()

    # If still long, truncate
    if len(text) > 80:
        text = text[:77] + "..."

    return text


def anonymize_event(event: dict) -> dict:
    """Anonymize a single event."""
    result = {}

    for key, value in event.items():
        if key in REMOVE_FIELDS:
            continue

        if key in PRESERVE_FIELDS:
            if isinstance(value, str) and value in SAFE_VALUES:
                result[key] = value
            elif isinstance(value, (bool, int, float)):
                result[key] = value
            elif key in ("depth", "from", "to", "name", "trigger", "event"):
                result[key] = value  # always safe for these fields
            elif key == "accepted":
                result[key] = value
            else:
                result[key] = anonymize_text(str(value))
            continue

        if key in ANONYMIZE_FIELDS:
            if key == "task":
                result[key] = categorize_task(str(value))
            elif key == "correction":
                result[key] = anonymize_text(str(value)) if value else None
            else:
                result[key] = anonymize_text(str(value))
            continue

        # Unknown fields: anonymize by default
        result[key] = anonymize_text(str(value)) if isinstance(value, str) else value

    return result


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 scripts/anonymize.py <sessions-dir> [--output <dir>]")
        sys.exit(1)

    sessions_dir = Path(sys.argv[1])
    if not sessions_dir.exists():
        print(f"Error: {sessions_dir} not found")
        sys.exit(1)

    # Output directory
    output_dir = sessions_dir.parent / "sessions-anon"
    if "--output" in sys.argv:
        idx = sys.argv.index("--output")
        output_dir = Path(sys.argv[idx + 1])

    output_dir.mkdir(parents=True, exist_ok=True)

    total_events = 0
    total_files = 0

    for log_file in sorted(sessions_dir.glob("*.jsonl")):
        anon_events = []

        with open(log_file) as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    event = json.loads(line)
                    anon_events.append(anonymize_event(event))
                    total_events += 1
                except json.JSONDecodeError:
                    continue

        if anon_events:
            output_file = output_dir / log_file.name
            with open(output_file, "w") as f:
                for event in anon_events:
                    f.write(json.dumps(event) + "\n")
            total_files += 1

    print(f"Anonymized {total_events} events from {total_files} files")
    print(f"Output: {output_dir}/")
    print()
    print("Stripped: file paths, task descriptions, timestamps, project-specific terms")
    print("Preserved: event types, depth values, skill names, override patterns")


if __name__ == "__main__":
    main()
