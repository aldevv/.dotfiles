---
name: hunk-review
description: Analyze a diff, compose review notes, then open a Hunk session in a new tmux window with the notes already attached. Use when the user types `/hunk-review`, asks to "open hunk", "review with hunk", "show changes in hunk", or wants to review a PR/branch/commit interactively.
argument-hint: [target]   # e.g. "main...feature", "HEAD~1", "origin/master..HEAD", "--pr 581", omit for current-branch vs upstream default
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - AskUserQuestion
---

# Hunk Review

Read the diff and compose the review notes **before** opening Hunk, then
open the TUI and attach the notes immediately. By the time the user looks
at the window, the inline annotations are already there — no awkward gap
where they're staring at an empty review while the model thinks.

**User input**: $ARGUMENTS

## Step 0 — Always read the bundled hunk skill first

Before doing anything else (parsing args, running git, opening tmux), read
the upstream session-control reference shipped with the binary:

```bash
cat "$(hunk skill path)"
```

That file is the source of truth for `hunk session ...` subcommands, the
exact `comment apply` payload schema, and `navigate` targeting rules. Do
NOT skip this step — the rest of the workflow assumes you've just refreshed
on it.

## Workflow

The order matters: **read bundled skill → analyze diff → open Hunk → attach
notes**. Don't open Hunk first and then go think about what to say.

### 1. Resolve the target (parallel)

Parse `$ARGUMENTS`:

- `--pr <N>` / `pr <N>` / bare `<N>` (numeric) → resolve via
  `gh pr view <N> --json baseRefName,headRefName,headRepository`, then
  build `origin/<base>...<head-branch>`.
- `<ref>` or `<range>` (e.g. `HEAD~1`, `main...HEAD`, `origin/master..HEAD`)
  → pass through verbatim.
- Empty → default to `<remote>/<default-branch>...HEAD` based on
  `git remote show origin | sed -n 's/.*HEAD branch: //p'`.

Run **in a single message, in parallel**:

- `git rev-parse --show-toplevel`
- `git remote show origin | sed -n 's/.*HEAD branch: //p'`
- `pwd`
- (when arg is a PR number) `gh pr view <N> --json baseRefName,headRefName,headRepository`

Once the range is known, confirm the diff has content with
`git diff --stat <RANGE>`. If empty, tell the user and stop — do not open
Hunk.

### 2. Read & analyze the diff (BEFORE opening Hunk)

```bash
git diff --no-color <RANGE>
```

Read the full diff and compose the comment payload per "Comment style"
below. Map files → 1-based hunk indices using the `@@ -X,Y +A,B @@`
headers (the Nth hunk in a file's diff is `hunkNumber: N`).

This step is the "review" — finish it before launching the TUI.

### 3. Open Hunk + attach notes (parallel where possible)

Fire these together in a single message:

```bash
# Call A — open Hunk in a new tmux window
# Window name: hunk-<repo>-<branch> so multiple reviews don't collide and a
# second invocation for the same branch can dedupe instead of stacking up.
tmux new-window -t "$(tmux display-message -p '#{session_name}')" \
  -n "hunk-$(basename <REPO_ROOT>)-$(git -C <REPO_ROOT> rev-parse --abbrev-ref HEAD)" \
  "cd <REPO_ROOT> && hunk diff <RANGE>"
```

```bash
# Call B — sleep + verify the session is live
sleep 2 && hunk session list
```

(`tmux new-window` without `-d` auto-switches the user to the new window,
which is what we want.) If the user said "open in a pane", swap call A
for `tmux split-window -h "cd <REPO_ROOT> && hunk diff <RANGE>"`.

Once the session is live, apply notes in **one batch** and jump to the
first one — both in parallel:

```bash
cat <<'JSON' | hunk session comment apply --repo <REPO_ROOT> --stdin
{
  "comments": [
    {"filePath": "path/to/file.go", "hunkNumber": 1, "summary": "...", "rationale": "..."},
    ...
  ]
}
JSON
```

```bash
hunk session navigate --repo <REPO_ROOT> --next-comment
```

If `comment apply` rejects a target (path or hunk index mismatch), re-run
`hunk session review --repo <REPO_ROOT> --json` and reconcile the file
paths and hunk counts before retrying — only fall back to this on error.

### 4. One-time prompt: install the pre-PR/MR hook

State file: `$HOME/.cache/hunk-review/state.json` (XDG cache — machine-local, never synced into the dotfiles repo).

After the review is attached, check for the state file:

```bash
test -f "$HOME/.cache/hunk-review/state.json" && cat "$HOME/.cache/hunk-review/state.json"
```

- **File exists** → skip this step entirely (already asked once).
- **File missing** → ask once via AskUserQuestion:

  Question: "Install a PreToolUse hook that auto-runs `hunk-review`
  right before any `gh pr create` or `glab mr create`? Hunk opens in a
  new tmux window and a backgrounded `claude -p` subagent fills it with
  AI review comments while the PR/MR is being created."

  Options:
  1. **Yes, install it** — write the hook script + register in settings.json
  2. **No, skip** — record the decision so we don't ask again
  3. **Ask me later** — do NOT write state; re-asks next run

On **Yes**:

1. Symlink the script that ships with this skill into `~/.claude/hooks/`
   (single source of truth — the script lives in the skill dir alongside
   `SKILL.md`):
   ```bash
   mkdir -p "$HOME/.claude/hooks" && \
     ln -sf "$HOME/.claude/skills/hunk-review/hunk-review-pre-pr.sh" \
            "$HOME/.claude/hooks/hunk-review-pre-pr.sh"
   ```
   (Use `cp -p` instead of `ln -sf` if you want a standalone copy that
   doesn't update when the skill is synced.)
2. Read `$HOME/.claude/settings.json`, add **two** `PreToolUse` entries
   under `hooks` matching `Bash(gh pr create:*)` and
   `Bash(glab mr create:*)`, both calling the same script. If
   `PreToolUse[].matcher == "Bash"` already exists, append to its `hooks`
   array — don't duplicate the matcher object itself.
3. Write the state file (create the cache dir if missing):
   ```bash
   mkdir -p "$HOME/.cache/hunk-review" && \
     printf '{"hookInstalled": true, "promptedAt": "%s"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
     > "$HOME/.cache/hunk-review/state.json"
   ```

On **No**:
```bash
mkdir -p "$HOME/.cache/hunk-review" && \
  printf '{"hookDeclined": true, "promptedAt": "%s"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  > "$HOME/.cache/hunk-review/state.json"
```

On **Ask me later**: do not write state.

## Hook script

The shipped script lives next to this `SKILL.md` at
`hunk-review-pre-pr.sh` (so editing it edits one file, and `/sync-dotfiles`
distributes it across machines). Read it directly when you need to know
exactly what runs:

```bash
cat "$HOME/.claude/skills/hunk-review/hunk-review-pre-pr.sh"
```

It fires for both `Bash(gh pr create:*)` and `Bash(glab mr create:*)`,
and the body is git-only (uses `origin`'s default branch as the base),
so it works for either provider.

What it does at a glance:

1. Bails if not inside tmux (no place to open a new window).
2. Finds the repo root and `origin`'s default branch.
3. Bails if there's no diff between `HEAD` and the remote default branch.
4. Opens `hunk diff <range>` in a new tmux window (auto-switching focus).
5. Spawns a placeholder poller in the background: waits up to 15s for the
   hunk session to register, then drops a single `[pending] AI review in
   progress…` comment so the user has visible signal during the ~1–2 min
   the subagent takes to compose real comments.
6. If `claude` is on `PATH`, spawns a backgrounded `claude -p` subagent
   that reads the diff, composes review comments per the
   "Comment style" section above, and pushes them into the live Hunk
   session via `hunk session comment apply --stdin`. The subagent uses:
   - `--dangerously-skip-permissions` — needs to run `git diff` /
     `hunk session ...` without prompting (headless).
   - `--no-session-persistence` — one-shot, no resumable session.
   - stdout/stderr appended to `~/.claude/hooks/logs/hunk-review-pre-pr.log`
     for debugging when comments don't appear.
   - `& disown` so the hook returns immediately and PR/MR creation isn't
     blocked.
   The subagent's prompt instructs it to first remove any `[pending]`
   placeholder comment (left by step 5) before applying its real batch.
7. `exit 0` — informational only.

To make the hook itself **block** PR/MR creation until the user closes
Hunk, change the final `exit 0` to `exit 2`; the user then re-runs the
PR/MR command after reviewing. (The subagent still runs async either
way.)

## Comment style — what's worth highlighting

Don't comment on every hunk. Highlight:

- **Behavioral changes** — return-shape changes, new branches in control
  flow, anything a casual reader might miss.
- **Complex flows** — multi-step coordination, non-obvious state
  transitions, recursion, async patterns. One brief comment at the entry
  point explaining the *shape* of the flow ("this fans out N tasks then
  awaits all, retrying any that return WouldBlock"), not per-step
  narration. Skip if a careful read of the function makes it obvious.
- **Cross-file invariants** — when one change relies on a behavior in
  another file/repo (e.g. "this depends on legalhold-tool's SQS dispatch").
- **Rollout footguns** — new env vars, deploy ordering, schema changes
  that need regen, secrets handling.
- **Test gaps** — areas not covered by the new tests, especially in repos
  that ban mocks.
- **Skip the mechanical** — pure renames, signature widening, comment-only
  changes, generated-file regenerations (mention once on the first hunk,
  don't comment per-hunk).

Each comment: a short `summary` (one-line headline) plus a `rationale`
(why-it-matters). Both render in the Hunk TUI.

## Agent notes visibility

If the user reports "I don't see the comments", they likely have
`agent_notes = false` in their `~/.config/hunk/config.toml`. Reload with
the flag set so the existing comments show up:

```bash
hunk session reload --repo <REPO_ROOT> -- diff --agent-notes <RANGE>
```

**WARNING**: `reload` clears all live comments. Re-apply the batch
afterwards.

## Common arguments → command mapping

| User says | Command to run |
|---|---|
| `/hunk-review` (no arg) | `hunk diff <remote-default>...HEAD` |
| `/hunk-review HEAD~1` | `hunk diff HEAD~1` (last commit) |
| `/hunk-review --pr 30` | resolve via `gh pr view`, `hunk diff <base>...<head>` |
| `/hunk-review main..feature` | `hunk diff main..feature` |
| (working tree changes) | `hunk diff` (no args) |
| (staged changes) | `hunk diff --staged` |

## Reference — bundled hunk session skill

For any `hunk session ...` subcommand or comment-targeting question, the
upstream skill in the binary is the source of truth:

```bash
cat "$(hunk skill path)"
```

Key reminders from there:

- `--repo <path>` selects sessions by their loaded repo root
- `comment apply` requires `--stdin` for batch JSON
- `comment apply` payload items must specify `filePath` + `summary` + one
  target (`hunk`, `hunkNumber`, `oldLine`, `newLine`)
- `navigate` requires `--file` plus exactly one of `--hunk` / `--new-line`
  / `--old-line`, OR a relative `--next-comment` / `--prev-comment`
- `reload` needs `--` before the nested Hunk command
