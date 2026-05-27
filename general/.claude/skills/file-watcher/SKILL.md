---
name: file-watcher
description: "Start OR stop a recurring file-watcher for a file (default: ./HANDOFF.md or ./handoff.md in the current project). When starting, every ~20 minutes the watcher compares the file's mtime to a cached baseline; if it advanced, the watcher reads the file, executes the `Next bounded action` it specifies end-to-end (write code, run the project's tests, commit using the prefix from recent commits, no Claude attribution), and refreshes the baseline. Autonomous-drive rules from ~/CLAUDE.md apply: no natural-breakpoint summaries, no remote push, no work-tagged files. START triggers: `/file-watcher`, `watch this file`, `watch HANDOFF.md`, `set up a HANDOFF monitor`, `monitor handoff`, `poll <file> for changes`, `start the baton watcher`. STOP triggers: `stop watching the file`, `stop watching HANDOFF`, `stop the file-watcher`, `stop the handoff monitor`, `unwatch <file>`, `cancel the watcher`, or any equivalent phrasing about ending the poll for a specific file. Do NOT trigger on read-only `tail -f` style requests, or on one-shot reminders (use CronCreate with recurring:false). The `remove all loops` phrasing kills every cron job, not just this watcher; for a targeted stop on this watcher specifically, this skill is the right call."
argument-hint: "[file-path] (optional, absolute or relative; defaults to ./HANDOFF.md or ./handoff.md)"
---

# file-watcher

Set up (or tear down) a recurring cron job that watches a file. On each fire it compares the file's mtime to a cached baseline; if the file advanced, it reads the file, runs the `Next bounded action` the file specifies, commits, and updates the baseline.

## Mode select

First, decide between **start** and **stop** based on the user's phrasing:

- **Stop** if the user said anything like `stop watching`, `stop the watcher`, `unwatch`, `cancel the watcher`, `stop monitoring`. Skip to the **Stop mode** section below.
- Otherwise treat it as **start** and run steps 1, 4 in order.

## Stop mode

1. Resolve the target file the same way as start-mode Step 1 (argument first, else `./HANDOFF.md` or `./handoff.md`). If the user named a different file in the stop phrasing, use that.
2. Call `CronList` to list active jobs.
3. Find the job whose `prompt` starts with `FILE-WATCHER for <target absolute path>`. If multiple jobs match (unlikely), delete all of them.
4. Call `CronDelete` for each matching job id.
5. Optionally remove the cached baseline: `rm -f "$HOME/.cache/file-watcher/$slug/last-mtime"`. Leave the cache dir in place; it's cheap.
6. Print one line: `Stopped watching <target>. Cancelled job(s): <id>[, <id>...].` If no job matched, say `No active watcher for <target>.` and stop.

## Step 1, resolve the target file

If the user passed a path as the argument, resolve it to an absolute path. Otherwise look in the current working directory for `HANDOFF.md` first, then `handoff.md`. If neither exists, stop and ask the user which file to watch.

Refuse paths under `$WORK` or any work-tagged directory.

## Step 2, prime the cache

```bash
target=<absolute path resolved in step 1>
slug=$(printf '%s' "$target" | sed 's|^/||; s|/|_|g; s|\.md$||')
cache_dir="$HOME/.cache/file-watcher/$slug"
mkdir -p "$cache_dir"
stat -c %Y "$target" > "$cache_dir/last-mtime"
```

The baseline is set to "now," so the first cron fire is a silent no-op unless the file is touched between now and then.

## Step 3, register the recurring job

Call `CronCreate` with:

- `cron`: `13,33,53 * * * *` (three fires per hour, off the :00/:30 marks).
- `recurring`: `true`.
- `prompt`: a self-contained instruction string built from the template below, with `$target` and `$cache_dir/last-mtime` substituted for the absolute paths resolved in step 1 and step 2.

Prompt template (substitute the two paths before passing to CronCreate):

```
FILE-WATCHER for <TARGET>.

1. Run: stat -c %Y <TARGET>  (current mtime).
2. Run: cat <CACHE_FILE>  (baseline).
3. If current == baseline: stop. Emit no narration to the user, no tool calls beyond the two reads.
4. If current > baseline:
   a. Read <TARGET>.
   b. Execute the "Next bounded action" it specifies end-to-end. Write code, run the project's test command (infer from recent commits or repo layout), commit with the same subject prefix as the last few commits on this branch. Author is `git config user.name`; never mention Claude, never add Co-Authored-By: Claude.
   c. Refresh baseline: stat -c %Y <TARGET> > <CACHE_FILE>
   d. Autonomous-drive rules from ~/CLAUDE.md apply: keep iterating without natural-breakpoint summaries. Do not push to remote. Do not touch work-tagged files.
```

## Step 4, report back

Print one line to the user:

```
Watching <target> every ~20 minutes. Job id: <id>. Stop with `remove all loops` or CronDelete.
```

Recurring cron jobs auto-expire after 7 days per the scheduler; rerun the skill to refresh.
