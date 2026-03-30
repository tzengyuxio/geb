#!/usr/bin/env bash
#
# GEB Telemetry Hook — logs tool usage for pattern analysis
#
# Triggered on PostToolUse. Records tool name, file paths, and skill
# invocations to ~/.geb/sessions/YYYY-MM-DD.jsonl.
#
# Toggle: touch ~/.geb/collect (enable) / rm ~/.geb/collect (disable)
#

[ ! -f "$HOME/.geb/collect" ] && exit 0

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')
TS=$(date -Iseconds)
LOG_DIR="$HOME/.geb/sessions"
LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d).jsonl"

mkdir -p "$LOG_DIR"

# Skill invocations — high-value signal
if [ "$TOOL_NAME" = "Skill" ]; then
  SKILL=$(echo "$INPUT" | jq -r '.tool_input.skill // "unknown"')
  ARGS=$(echo "$INPUT" | jq -r '.tool_input.args // ""')
  echo "{\"ts\":\"$TS\",\"event\":\"skill\",\"skill\":\"$SKILL\",\"args\":\"$ARGS\"}" >> "$LOG_FILE"
  exit 0
fi

# File modifications — for ripple impact analysis
if [ "$TOOL_NAME" = "Edit" ] || [ "$TOOL_NAME" = "Write" ]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // "unknown"')
  echo "{\"ts\":\"$TS\",\"event\":\"file_mod\",\"tool\":\"$TOOL_NAME\",\"file\":\"$FILE_PATH\"}" >> "$LOG_FILE"
  exit 0
fi

# Agent spawns — track subagent usage
if [ "$TOOL_NAME" = "Agent" ]; then
  DESC=$(echo "$INPUT" | jq -r '.tool_input.description // ""')
  echo "{\"ts\":\"$TS\",\"event\":\"agent\",\"description\":\"$DESC\"}" >> "$LOG_FILE"
  exit 0
fi

exit 0
