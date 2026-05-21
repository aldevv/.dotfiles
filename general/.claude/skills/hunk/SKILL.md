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
- **Round 2 — Open + read** (the `git diff` and `tmux split/new-window` are parallel; an active poll on `hunk session list` confirms the session is live before Round 3; do NOT use a fixed `sleep` — poll instead).
- **Round 3 — Apply** (sequential within the round): `comment apply` then `navigate`. These race if parallel.

### Fast path: pre-supplied comments

If the caller hands you a ready-to-apply comment batch (e.g. `pr-code-review` invokes `Skill(hunk)` with the JSON inline, or you're handed `comments_json=<path>` in `$ARGUMENTS`), the workflow collapses to TWO rounds:

- **Round 1 — Discovery** unchanged. Skip the `gh pr view` parallel call only if the caller also provided `<RANGE>` verbatim.
- **Round 2 — Open + apply** (single message, all parallel except the apply, which is gated on session-up):
  - `tmux split-window` / `new-window` to open the Hunk TUI
  - poll-then-apply one-liner (below), which blocks on `hunk session list` finding the repo, then pipes the supplied JSON to `hunk session comment apply --stdin`
  - `hunk session navigate --next-comment` runs AFTER the poll-then-apply in the SAME bash subshell so it's strictly sequenced without an extra round trip

In this mode you do NOT read `review-guidance.md`, do NOT read the diff to decide whether to comment, and do NOT re-derive hunk numbers if the caller supplied `newLine` (preferred; see "Targeting" in Round 3). Total elapsed time is dominated by Hunk's cold-start (typically ~500ms-1s), not by Claude latency.

Recognize "pre-supplied" by any of:
- The skill prompt body contains a JSON object with a top-level `comments:` array.
- `$ARGUMENTS` includes `comments_json=<path>` or `comments=<path>`.
- The user pastes a numbered findings list with `file:line` anchors and explicitly says "open in hunk with these notes".

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

- `git diff --no-color <RANGE>` (full diff for you to read; serves double duty as the emptiness check, no separate `--stat` call needed). **Skip in the fast path** — pre-supplied callers already analyzed the diff.
- Open Hunk in tmux. Pick from `$ARGUMENTS` and Round 1's pane count, in priority order:
  - **`target_session=<name>` is set** → open in that session, always as a new window. Create the session detached first if it doesn't exist:
    ```bash
    tmux has-session -t "<name>" 2>/dev/null || tmux new-session -d -s "<name>" -n placeholder
    tmux new-window -t "<name>:" -n "hunk-$(basename <REPO_ROOT>):$(git -C <REPO_ROOT> rev-parse --abbrev-ref HEAD)" "cd <REPO_ROOT> && hunk diff <RANGE>"
    ```
    Window does NOT auto-focus because the target session is different from the current session. That's intentional for batch use; the operator will `tmux attach -t <name>` after the run.
  - **`force_new_window=true` is set (without `target_session`)** → `tmux new-window` in the current session regardless of pane count.
  - **1 pane and no directives** → `tmux split-window -h "cd <REPO_ROOT> && hunk diff <RANGE>"`
  - **>1 panes and no directives** → `tmux new-window -t "$(tmux display-message -p '#{session_name}')" -n "hunk-$(basename <REPO_ROOT>):$(git -C <REPO_ROOT> rev-parse --abbrev-ref HEAD)" "cd <REPO_ROOT> && hunk diff <RANGE>"`
  - The window-name shape is `hunk-<repo>:<branch>`. The status-bar regex splits on the first non-path char, so the left ("folder" color, slightly whiter) reads `hunk-<repo>` and the right ("program" color, soft blue) reads the branch — branch becomes the most visible signal at a glance. The repo-included prefix keeps dedupe per-branch across multiple repos in the same tmux session.
  - If the user said "open in a new window" even with one pane, skip the conditional and go straight to `new-window`.
- Active poll for session-up (replaces the old `sleep 2 && hunk session list`). MUST match on the absolute `repo:` path, not the basename, otherwise two repos with the same basename collide. MUST run inside the SAME bash command as any follow-up so the apply only fires after the session resolves:
  ```bash
  for i in $(seq 1 30); do
    hunk session list 2>/dev/null | grep -qF "repo: <REPO_ROOT>" && break
    sleep 0.2
  done
  hunk session list 2>/dev/null | grep -qF "repo: <REPO_ROOT>" || { echo "hunk session never came up for <REPO_ROOT>"; exit 1; }
  ```
  Worst case 6s, typical case 200-400ms on a warm hunk. `grep -F` (literal) avoids the `:` in `repo:` being interpreted by `grep -P`. Replace the legacy `sleep` form everywhere.
- **Fast-path bonus parallel call**: if pre-supplied comments are present, chain everything in ONE bash command so a tool-batch round-trip can't interleave between poll-success and apply:
  ```bash
  for i in $(seq 1 30); do
    hunk session list 2>/dev/null | grep -qF "repo: <REPO_ROOT>" && break
    sleep 0.2
  done && \
  hunk session list 2>/dev/null | grep -qF "repo: <REPO_ROOT>" && \
  cat <comments_json> | hunk session comment apply --repo <REPO_ROOT> --stdin && \
  hunk session navigate --repo <REPO_ROOT> --next-comment
  ```
  The diff-line validator (see Round 3) runs BEFORE this chain on its own line; misaligned comments abort the batch instead of half-attaching. If you split poll and apply across two separate tool calls, you'll regress to the bug where the apply landed zero comments because the session wasn't visible yet in the second subshell.

Both `split-window` and `new-window` auto-switch focus to the new pane/window.

If the diff returns empty, tell the user and stop. The Hunk window will be empty too; either close it (`tmux kill-pane -t <pane>`) or leave it for the user.

If the poll loop exits without finding the session, tell the user "hunk failed to start" and stop. Do NOT proceed to apply on the assumption "it'll be up by the next tool call" — that's the regression that drops 12 comments silently.

## Round 3 — Apply (or skip)

**Skip this round entirely in the fast path** — the apply + navigate already happened in Round 2 inside the same bash subshell as the poll loop.

In the analysis path (no pre-supplied comments), read `references/review-guidance.md`. Read the diff. Decide whether it contains complex flows or difficult paths.

**If real comments to apply** — fire these two SEQUENTIALLY in the SAME bash command (joined with `&&`) so navigate never races apply:

```bash
cat <<'JSON' | hunk session comment apply --repo <REPO_ROOT> --stdin && \
hunk session navigate --repo <REPO_ROOT> --next-comment
{
  "comments": [
    {"filePath": "path/to/file.go", "newLine": 67, "summary": "...", "rationale": "..."}
  ]
}
JSON
```

**Targeting — STRICT rule:** every comment MUST anchor to a real changed line in the diff, not a hunk position. Comments attached only by `hunkNumber` land at the start of the hunk, which is often an unchanged context line; that surfaces the comment on the wrong line in the TUI and confuses the reader.

Use this priority order:
1. **`newLine: <N>`** when the finding describes an added line (`+` in the diff). This is the default; pre-supplied callers should always use it.
2. **`oldLine: <N>`** when the finding describes a deleted line (`-` in the diff).
3. **`hunkNumber: <K>`** only when the finding genuinely belongs to the hunk as a whole and no single line is the right anchor (e.g. "this entire function should be deleted"). Rare.

Never mix: pick exactly one of `newLine` / `oldLine` / `hunkNumber` per comment.

### Validate every comment lands on a real diff line

Before piping the JSON to `hunk session comment apply`, run a one-shot validator that pulls the diff once and confirms each `(filePath, newLine|oldLine)` pair is actually a `+` or `-` line. Reject the apply if any comment is misaligned — emit a fix-up message naming the offenders so the caller can correct or drop them.

```bash
# /tmp/hunk-validate.sh
git diff --no-color <RANGE> | awk '
  /^diff --git / { sub("^.*b/", ""); file=$0; next }
  /^@@ / {
    match($0, /\+[0-9]+/); newStart = substr($0, RSTART+1, RLENGTH-1) + 0;
    match($0, /-[0-9]+/); oldStart = substr($0, RSTART+1, RLENGTH-1) + 0;
    nl = newStart - 1; ol = oldStart - 1; next
  }
  /^\+/  { nl++; print "ADD\t" file "\t" nl; next }
  /^-/   { ol++; print "DEL\t" file "\t" ol; next }
  /^ /   { nl++; ol++; next }
' > /tmp/hunk-lines.tsv

jq -r '.comments[] | [.filePath, (.newLine // ""), (.oldLine // "")] | @tsv' /tmp/pr-N-comments.json |
while IFS=$'\t' read -r file nl ol; do
  if [ -n "$nl" ]; then
    grep -qP "^ADD\t${file}\t${nl}$" /tmp/hunk-lines.tsv || echo "MISSING ADD ${file}:${nl}"
  elif [ -n "$ol" ]; then
    grep -qP "^DEL\t${file}\t${ol}$" /tmp/hunk-lines.tsv || echo "MISSING DEL ${file}:${ol}"
  fi
done
```

If the validator prints any `MISSING` lines, stop and surface them to the caller. Do NOT silently fall back to `hunkNumber` — that's exactly the foot-gun this validation prevents.

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
