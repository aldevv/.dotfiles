---
name: hunk-review
description: Open a Hunk diff review in a new tmux window and walk the user through the changes. Use when the user types `/hunk-review`, asks to "open hunk", "review with hunk", "show changes in hunk", or wants to review a PR/branch/commit interactively.
argument-hint: [target]   # e.g. "main...feature", "HEAD~1", "origin/master..HEAD", "--pr 581", omit for current-branch vs upstream default
allowed-tools:
  - Bash
  - Read
---

# Hunk Review

Spin up a Hunk diff review in a new tmux window so the user can see the
changeset in a proper TUI, then leave inline review notes pointing at the
parts worth scrutinizing.

**User input**: $ARGUMENTS

This skill orchestrates Hunk; the actual session control reference is the
SKILL.md bundled with the binary. Locate it with `hunk skill path` and read
it first if you need to recall any `hunk session ...` subcommand.

## Workflow

### 1. Resolve the target

Parse `$ARGUMENTS`:

- `--pr <N>` or `pr <N>` or just `<N>` (numeric) → resolve to a branch
  comparison via `gh pr view <N> --json baseRefName,headRefName,headRepository`,
  then build the range `origin/<base>...<head-branch>`.
  - Cleanup-service uses `main` as default; `system-mega` uses `master`.
    Trust whatever `gh pr view` returns — don't hard-code.
- `<ref>` or `<range>` (e.g. `HEAD~1`, `main...HEAD`, `origin/master..HEAD`)
  → pass through verbatim.
- Empty → default to `<remote>/<default-branch>...HEAD` based on
  `git remote show origin | sed -n 's/.*HEAD branch: //p'`.

Always operate from the repo root the user is in (`pwd` of the agent).
Confirm the diff has content with `git diff --stat <range>` before opening
Hunk; if empty, tell the user and stop.

### 2. Open in a new tmux window

```bash
tmux new-window -t "$(tmux display-message -p '#{session_name}')" \
  -n hunk-review \
  "cd <REPO_ROOT> && hunk diff <RANGE>"
```

The `tmux new-window` (without `-d`) auto-switches the user to the new
window, which is what they want. Don't use `-d`.

If the user says "open in a pane" instead, use `tmux split-window -h` with
the same `cd && hunk diff …` command.

### 3. Locate the live session and apply review notes

After 2–3 seconds (so the daemon registers the new session):

```bash
hunk session list
hunk session review --repo <REPO_ROOT> --json
```

The review JSON contains a `review.files[*].hunks[*]` shape. For each
non-trivial change pick a target — preferring `hunkNumber` over `newLine`
because newLine targeting only works on lines literally added/changed (not
context lines), and Hunk's `newRange` field shows ONLY the contiguous
changed slice, not the full hunk window.

Apply review notes in **one batch** via `comment apply` rather than many
single calls:

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

Then jump to the first comment so the user lands there:

```bash
hunk session navigate --repo <REPO_ROOT> --next-comment
```

### 4. Comment style — what's worth highlighting

Don't comment on every hunk. Highlight:

- **Behavioral changes** — return-shape changes, new branches in control
  flow, anything a casual reader might miss.
- **Cross-file invariants** — when one change relies on a behavior in
  another file/repo (e.g. "this depends on legalhold-tool's SQS dispatch").
- **Rollout footguns** — new Slack volume, new env vars, deploy ordering.
- **Test gaps** — areas not covered by the new tests, especially in repos
  that ban mocks.
- **Skip the mechanical** — pure renames, signature widening, comment-only
  changes.

Each comment: a short `summary` (one-line headline) plus a `rationale`
(why-it-matters). Both will render in the Hunk TUI.

## Agent notes visibility

If the user reports "I don't see the comments", they likely have
`agent_notes = false` in their `~/.config/hunk/config.toml`. Reload with the
flag set so the existing comments show up:

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

## Pre-PR-create hook

There's a companion hook at `~/.claude/hooks/hunk-review-prepush.sh`
that auto-runs this flow when a `gh pr create` is about to fire. It is
**not enabled by default**. To enable, add to `~/.claude/settings.json`
under `PreToolUse`:

```json
{
  "matcher": "Bash",
  "hooks": [
    {
      "type": "command",
      "command": "/home/kanon/.claude/hooks/hunk-review-prepush.sh",
      "timeout": 10
    }
  ]
}
```

The hook is informational (exit 0) — it opens Hunk in a new window so the
user can scan the diff in parallel with the PR being created. To make it
strict (block until reviewed) edit the script and change the final `exit 0`
to `exit 2`; the user will then need to re-run the `gh pr create` command
after reviewing.

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
