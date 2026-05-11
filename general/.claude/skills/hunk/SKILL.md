---
name: hunk
description: Analyze a diff, compose review notes that explain complex flows or difficult paths, then open a Hunk session in a new tmux window with the notes already attached. Requires tmux + `hunk` CLI. Use when the user types `/hunk`, `/hunk-review`, asks to "open hunk", "review with hunk", "show changes in hunk", or wants to review a PR/branch/commit interactively in the Hunk TUI. Do NOT trigger for plain PR review prose with no Hunk/TUI mention (use `code-review:code-review`), for posting a comment on an existing PR/MR thread (use `add-comment`), for whole-plugin audits (use `neovim-plugin-review`), or when not inside tmux.
argument-hint: [target]   # e.g. "main...feature", "HEAD~1", "--pr 581", "pr 30", or a bare PR number. Omit for current-branch vs upstream default.
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - AskUserQuestion
---

# Hunk

Open the Hunk TUI and attach review notes for any complex flows or difficult paths in the diff. Default to applying nothing: comments are reserved for things a careful reader would still find non-obvious.

**User input**: $ARGUMENTS

## Files

- `scripts/hunk-pre-pr.sh` — the PreToolUse hook this skill optionally installs. Read it directly when you need to know what runs: `cat "$HOME/.claude/skills/hunk/scripts/hunk-pre-pr.sh"`.
- `references/review-guidance.md` — comment scope (what to flag, what to skip) plus tone rules and a worked example. Read at Round 3 before deciding what to apply.
- `references/hook-install.md` — the prompt + commands + settings.json target shape for Round 4. Read at Round 4 only when the state file is missing.

## When NOT to use

- Not inside tmux (`$TMUX` unset). The skill has nowhere to open the Hunk window.
- `hunk` CLI not installed. Tell the user to install it first.
- The user wants PR-review prose, not an interactive TUI session — defer to `code-review:code-review`.
- The user wants to post a comment to an existing PR/MR thread — defer to `add-comment`.
- The user wants a multi-angle audit of a Neovim plugin — defer to `neovim-plugin-review`.

## Preconditions (check before Round 1)

If any of these fail, tell the user what failed and stop. Don't proceed to Round 1.

- `[[ -n "$TMUX" ]]` — must be inside a tmux session.
- `command -v hunk >/dev/null` — the `hunk` CLI must be on `$PATH`.
- `git rev-parse --show-toplevel` — must be inside a git repo (Round 1 needs this anyway).

## Parallelism rules

Fire as much as possible in parallel. The workflow is three rounds; everything within a round goes in a single message with parallel tool calls. Inter-round work is serial only because later rounds need earlier rounds' outputs (range, pane count, diff text).

- **Round 1 — Discovery** (parallel): bundled skill, repo root, default branch, pane count, hook-prompt state, (if PR arg) `gh pr view`.
- **Round 2 — Open + read** (the `git diff` and `tmux split/new-window` are parallel; `sleep 2 && hunk session list` is a sequenced probe to verify the session is up before Round 3).
- **Round 3 — Apply** (sequential within the round): `comment apply` then `navigate`. These race if parallel.

## Round 1 — Discovery (everything parallel)

Fire ALL of these in a single message:

- `cat "$(hunk skill path)"` (bundled session-control reference, the source of truth for `hunk session ...` semantics)
- `git rev-parse --show-toplevel`
- `git symbolic-ref --short refs/remotes/origin/HEAD` (faster than `git remote show origin`; the default branch is `${out#origin/}`)
- `tmux display-message -p '#{window_panes}'` (drives split-vs-new-window in Round 2)
- `test -f "$HOME/.cache/hunk/state.json" && cat "$HOME/.cache/hunk/state.json" || echo MISSING` (Round 4 prompt state)
- If `$ARGUMENTS` matches `^(--pr +)?[0-9]+$` or `^pr +[0-9]+$` (a numeric PR identifier, with optional `pr` / `--pr` prefix): also fire `gh pr view <N> --json baseRefName,headRefName,headRepository`. `HEAD~N` does NOT match because it starts with `HEAD`.

Resolve `<RANGE>` from `$ARGUMENTS`:

| `$ARGUMENTS` | `<RANGE>` |
|---|---|
| empty | `origin/<default>...HEAD` |
| `HEAD~1`, `main..feature`, `origin/master..HEAD`, etc. | pass through verbatim |
| `--pr N` / `pr N` / bare numeric `N` | `origin/<base>...<head>` from `gh pr view` |
| (working-tree review, no commits) | no range; use `hunk diff` / `git diff` with no args |
| (staged review) | `hunk diff --staged` / `git diff --staged` |

## Round 2 — Open Hunk + read diff (parallel)

Once `<RANGE>` is known, single message with these in parallel:

- `git diff --no-color <RANGE>` (full diff for you to read; serves double duty as the emptiness check, no separate `--stat` call needed)
- Open Hunk in tmux. Pick from Round 1's pane count:
  - 1 pane → `tmux split-window -h "cd <REPO_ROOT> && hunk diff <RANGE>"`
  - >1 panes → `tmux new-window -t "$(tmux display-message -p '#{session_name}')" -n "hunk-$(basename <REPO_ROOT>):$(git -C <REPO_ROOT> rev-parse --abbrev-ref HEAD)" "cd <REPO_ROOT> && hunk diff <RANGE>"`
  - The window-name shape is `hunk-<repo>:<branch>`. The status-bar regex splits on the first non-path char, so the left ("folder" color, slightly whiter) reads `hunk-<repo>` and the right ("program" color, soft blue) reads the branch — branch becomes the most visible signal at a glance. The repo-included prefix keeps dedupe per-branch across multiple repos in the same tmux session.
  - If the user said "open in a new window" even with one pane, skip the conditional and go straight to `new-window`.
- `sleep 2 && hunk session list` (delayed probe: gives Hunk ~2s to register, then confirms the session is live)

Both `split-window` and `new-window` auto-switch focus to the new pane/window.

If the diff returns empty, tell the user and stop. The Hunk window will be empty too; either close it (`tmux kill-pane -t <pane>`) or leave it for the user.

If `hunk session list` shows no session for the repo, retry after another `sleep 2` (cold tmux + cold hunk can take longer). If still missing, tell the user "hunk failed to start" and stop.

## Round 3 — Apply (or skip)

Read `references/review-guidance.md`. Read the diff. Decide whether it contains complex flows or difficult paths.

**If real comments to apply** — fire these two SEQUENTIALLY (do not parallelize: navigate races apply and may find nothing):

```bash
cat <<'JSON' | hunk session comment apply --repo <REPO_ROOT> --stdin
{
  "comments": [
    {"filePath": "path/to/file.go", "hunkNumber": 1, "summary": "...", "rationale": "..."}
  ]
}
JSON
```

```bash
hunk session navigate --repo <REPO_ROOT> --next-comment
```

**Targeting**: prefer `hunkNumber` (1-based index of the `@@ @@` header in the file's diff output) — it's the most stable across reformats. Fall back to `newLine` / `oldLine` only when the hunk index is ambiguous (e.g. multiple notes targeting different lines inside the same large hunk). `hunk` is accepted too but `hunkNumber` is the preferred name.

If `comment apply` errors for any reason (path mismatch, hunk mismatch, session vanished), run `hunk session review --repo <REPO_ROOT> --json` to confirm the file/hunk structure (iterate `.review.files[].path` and `.review.files[].hunks[]`). If the session is gone, stop and tell the user; don't try to reopen Hunk on its own.

**If nothing worth commenting on** — clear any `[pending]` placeholder (the pre-PR/MR hook drops one; `/hunk` usually doesn't) and stop:

```bash
hunk session comment list --repo <REPO_ROOT> --json | \
  jq -r '.comments[] | select(.summary | startswith("[pending]")) | .commentId' | \
  while read -r cid; do hunk session comment rm "" "$cid" --repo <REPO_ROOT>; done
```

The empty first positional is required: `hunk session comment rm` takes `[sessionId]` then `<commentId>`; `--repo` replaces session lookup but the first arg slot still needs `""`.

Tell the user the diff was straightforward and no review comments were warranted.

## Round 4 — One-time hook-install prompt

You already loaded `$HOME/.cache/hunk/state.json` in Round 1.

- File exists → skip this step entirely (already asked once).
- File missing → read `references/hook-install.md` and follow the prompt + commands there. Delegates the `settings.json` JSON edit to the `update-config` skill.

## Hook script

`scripts/hunk-pre-pr.sh` is the source of truth — its header comment block lists what fires, when, and the two-phase deny-then-retry flow. Read it for detail:

```bash
cat "$HOME/.claude/skills/hunk/scripts/hunk-pre-pr.sh"
```

To make the hook **block** PR/MR creation until the user closes Hunk (instead of the default deny-then-retry-then-Allow), change the final `exit 0` to `exit 2`.

## Agent notes visibility

If the user reports "I don't see the comments", they likely have `agent_notes = false` in their `~/.config/hunk/config.toml`. Reload with the flag so existing comments show up:

```bash
hunk session reload --repo <REPO_ROOT> -- diff --agent-notes <RANGE>
```

**WARNING**: `reload` clears all live comments. Re-apply the batch afterwards.

## Common arguments → command mapping

| User says | Command to run |
|---|---|
| `/hunk` (no arg) | `hunk diff <remote-default>...HEAD` |
| `/hunk HEAD~1` | `hunk diff HEAD~1` |
| `/hunk --pr 30` | resolve via `gh pr view`, `hunk diff <base>...<head>` |
| `/hunk main..feature` | `hunk diff main..feature` |
| (working tree changes) | `hunk diff` (no args) |
| (staged changes) | `hunk diff --staged` |
