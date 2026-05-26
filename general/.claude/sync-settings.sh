#!/usr/bin/env bash
set -euo pipefail

src="$HOME/.claude/my-settings.json"
dst="$HOME/.claude/settings.json"

if [ ! -f "$src" ]; then
  echo "sync-settings: source missing at $src" >&2
  exit 1
fi
if [ ! -f "$dst" ]; then
  echo "sync-settings: target missing at $dst (creating empty)"
  echo '{}' > "$dst"
fi

read -r -d '' prompt <<EOF || true
You are running as a one-shot updater. Your job is to merge any new or
changed values from MY_SETTINGS into TARGET_SETTINGS, then write the
result back to TARGET_SETTINGS. Do not remove anything TARGET_SETTINGS
already has that MY_SETTINGS does not mention.

MY_SETTINGS = $src
TARGET_SETTINGS = $dst

Merge rules:
- Keys present only in TARGET_SETTINGS: keep as-is.
- Keys present only in MY_SETTINGS: add them to TARGET_SETTINGS.
- Both sides have an object: recurse with the same rules.
- Both sides have an array: concatenate (TARGET_SETTINGS entries first,
  then MY_SETTINGS entries), then drop entries whose JSON is identical
  to one already present.
- Both sides have a scalar (string / number / bool): take the
  MY_SETTINGS value, because MY_SETTINGS is the authoritative source.

After writing, validate the result is parseable JSON. Reply with one
short sentence: either "synced" plus a brief count of keys added or
overridden, or a clear error message if the merge failed.

Use 2-space indent in the output.
EOF

exec claude -p "$prompt" --permission-mode acceptEdits
