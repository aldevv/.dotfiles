#!/usr/bin/env bash
# PreToolUse hook for Write / Edit / NotebookEdit.
#
# Replaces the "Pre-edit re-scan (mandatory)" text rule in CLAUDE.md.
# That rule depended on model self-policing at exactly the right tool-call
# boundary, which was unreliable under context pressure and especially
# after a compaction summary. This hook fires externally on every
# Write/Edit, injecting a short additionalContext reminder.
#
# Stays cheap: no jq filtering on tool_input.command, no file reads.
# Always emits the same compact reminder.
set -euo pipefail

# Drain stdin so the parent doesn't get a SIGPIPE on EPIPE.
cat >/dev/null

read -r -d '' MSG <<'EOF' || true
PRE-EDIT REMINDER: re-scan the Lazy load table in ~/CLAUDE.md and load any lazy file whose trigger fires on the current work. After a compaction summary, assume every lazy file's contents have been evicted from context and re-read every triggered file — the summary preserves the fact of reading, not the content.
EOF

jq -c -n --arg msg "$MSG" \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $msg}}'
