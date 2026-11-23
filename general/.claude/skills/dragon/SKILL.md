---
name: dragon
description: Open files in `dragon` (drag-and-drop helper) so the user can drag them into a chat app, browser upload or email. Always drags every file together as one drop, never one at a time. Triggers on "/dragon", "dragon", "open it in dragon", "open the logs in dragon", "give me the files to drag", "I want to drag and drop these", "dragon again". Requires `dragon` on `$PATH`. Not for showing file contents (just print or read them) or for uploading files yourself.
argument-hint: <file>...   # one or more paths; globs are fine
allowed-tools:
  - Bash
---

# dragon

Hand files to the user as one drag-and-drop window.

## Steps

1. Resolve the files the user means (the paths just discussed, or the ones they name). If any of them can carry secrets (logs with tokens, configs), redact a copy first and pass the copies.
2. Run the helper, passing every file in one call:

   ```bash
   ~/.claude/skills/dragon/scripts/drag.sh <file>...
   ```

   It closes dragon windows left from earlier calls, then opens one window with `--all` (one drag carries every file), `--on-top`, and `--and-exit` (closes after the drop). It returns right away.
3. Tell the user how many files are in the window, in one line. If they ask for "dragon again", rerun step 2 with the same files.

## Notes

- Never open one dragon window per file, and never call `dragon` without `--all`: plain `dragon a b c` makes the user drag each file separately.
- Don't `pkill -f dragon` from a command line that itself contains "dragon": it matches its own shell. The helper kills by process name instead.
