---
name: tmux
description: Spawn a tmux pane, window, or session running claude (or any other command) without leaving the current session. Triggers on "open a new pane", "split with claude", "open another claude beside this one", "new tmux pane/panel", "new tmux window", "new tmux tab", "side-by-side claude", "create a new session to do X", "spawn a new session for X", "open a session for <task>", "run X in a new pane/window/session", "do X in a new pane/window/session", "start X in a new pane/window/session", "kick off X in a new pane/window/session", or any request to launch a sibling shell/claude instance from inside tmux, including any request phrased as "run/do/start <task> in a new <pane|window|session|tab|panel|split>". Also fires when the user asks for two or more clearly unrelated tasks in one request (different repos, different long-running concerns, different features or PRs in the same project, "fix issue #N AND resolve conflicts in PR #M") so the skill can spawn the extras into their own windows/sessions instead of running them serially in the current pane. When the parallel tasks live in the same repo but need different branches checked out (a feature branch and a PR branch, two different issues), spawn a git worktree per extra task and open the new window in that worktree so the branches don't collide. Defaults to a new pane (split). Opens a new window when the user says "window" or "tab". Opens a new tmux session when the user says "session to do X" / "session for X" AND the task lives outside the current repo/working directory tree; otherwise a "session" request becomes a new window. For multi-task splits: same-repo tasks get a new window (in a worktree if branch-isolating); off-tree tasks get a new session. Pick decisively, do not ask the user.
---

# tmux pane/window helper

Use this skill whenever the user asks to spawn a sibling shell or claude instance from inside their current tmux session. The harness's first instinct (`tmux new-window`) is wrong by default — most users mean a **pane** (split), not a window (tab).

## CRITICAL: Never spawn-to-relocate the current task

Do not ask the user mid-task whether to "spawn a fresh claude session", "hand this off to a dedicated session", or any variant framed as managing conversation length, context budget, or feature size. It disrupts work and wastes their time. Keep working in the current pane and ship the next bounded action. Spawn primitives are for parallel work the user asked for, not for relocating the current task.

## CRITICAL: Anchor spawns on `$TMUX_PANE`, not the user's current view

Without `-t`, `tmux split-window` / `new-window` / `display-message` operate on the **active client's current window** — wherever the user happens to be looking. If the user moved focus while Claude was working (a different window in the same session, or a different session), the spawn lands in the wrong place: a split next to unrelated work, a new window in the wrong session, a pane-count check that returns numbers from the user's view instead of Claude's.

`$TMUX_PANE` is set in Claude's bash environment to the pane id (`%NN`) of the pane Claude is running in. Use it as the anchor on every tmux invocation that spawns or inspects:

```bash
# Inspect Claude's window, not the user's current view.
tmux display-message -t "$TMUX_PANE" -p '#{window_panes}'
tmux display-message -t "$TMUX_PANE" -p '#{session_name}'

# Split Claude's pane.
tmux split-window -h -t "$TMUX_PANE" -c <dir> "<command>"

# New window in Claude's session (note the trailing `:` to mean "this session, next index").
claude_session=$(tmux display-message -t "$TMUX_PANE" -p '#{session_name}')
tmux new-window -t "$claude_session:" -c <dir> "<command>"
```

Apply this to the examples below: every `split-window`, `new-window`, and inspecting `display-message` in the rest of this skill should carry `-t "$TMUX_PANE"` (or `-t "$claude_session:"` for cross-window spawns) unless the spawn is explicitly into a different named session (the `tmux new-session -d -s <name>` flow). The skill examples below omit `-t` for readability; add it in real invocations.

## Spawning claude: standard invocation

Spawned claude sessions are autonomous side jobs — the user is not sitting in the new pane approving each tool call. The default invocation is:

```bash
claude --dangerously-skip-permissions "<prompt>"
```

That single line is the whole pattern. It works the same for `split-window`, `new-window`, `new-session`, and worktree windows: the trailing command on any of those spawns is just that. Skip the flag only when the user explicitly says the new session should be interactive.

For prompts longer than a sentence or that contain awkward quoting, pre-write the prompt to a file and pipe it:

```bash
claude --dangerously-skip-permissions < /tmp/prompt.txt
```

## Default: new pane (`split-window`)

```bash
tmux split-window -h -c <dir> "<command>"
```

- `-h` = horizontal split (panes side-by-side, left/right). Best for wide terminals.
- `-v` = vertical split (panes stacked, top/bottom). Use when the current window is already wide-split or the user asks for "below".
- `-c <dir>` = starting working directory for the new pane.
- The trailing string is the shell command to run; omit for a plain shell.

Examples:

```bash
# claude with a prompt, side-by-side, in a specific repo
tmux split-window -h -c /home/kanon/work/c1 "claude --dangerously-skip-permissions 'explain the current branch and quote the key code'"

# plain shell stacked below
tmux split-window -v -c /home/kanon/work/baton-sdk

# inherit current pane's cwd (omit -c)
tmux split-window -h "claude --dangerously-skip-permissions"
```

## When the user says "session to do X" / "session for X" / "new session for ..."

The user often says "session" colloquially to mean "a fresh context for this new task," not literally `tmux new-session`. Pick based on **scope**:

- **Different repo, project, or working directory tree from the current session** → real new tmux **session**. Use this when the task lives somewhere unrelated to what's open now (e.g. current session is in `~/repos/hunk`, the new task is in `~/work/baton-sdk`), or when the user is starting work on a different long-running concern they'll want to detach and come back to.
- **Same project/repo, but a separate task** → new **window** inside the current session. The user's mental model of "session" here is just "a separate tab to work in"; a window does that without losing the cwd context or breaking sibling tooling that targets the current session.

Real tmux session (different scope):

```bash
# Detached so we don't leave the current session blind; switch-client moves us in.
tmux new-session -d -s <name> -c <dir>
tmux send-keys -t <name> "<command>" Enter   # optional: run something on launch
tmux switch-client -t <name>                 # attach the current client to the new session
```

- Pick `<name>` from the task: `hunk-review`, `baton-fix-foo`, `notes`. Keep it short, no spaces, lowercase. If a session by that name already exists, reuse it (`tmux has-session -t <name>` returns 0) instead of creating a duplicate.
- `-c <dir>` sets the working directory for the first window. Pass the repo root, not `$PWD`, unless the user pointed at a specific subdir.
- Use `send-keys ... Enter` rather than the trailing `"<command>"` arg to `new-session`; the trailing-arg form ties the session's lifetime to that command, so it dies when the command exits.

Same-project task ("session" colloquially) → fall through to the `new-window` flow below.

Examples:

```bash
# User: "create a new session to review the baton-sdk PR" while current session is hunk.
tmux new-session -d -s baton-pr -c /home/kanon/work/baton-sdk
tmux send-keys -t baton-pr "gh pr checkout 1234 && claude 'review this branch'" Enter
tmux switch-client -t baton-pr

# User: "create a new session to do the test cleanup" while inside the hunk repo.
# Same repo → window, not session.
tmux new-window -c /home/kanon/repos/github.com/modem-dev/hunk "claude 'clean up the flaky pty tests'"
```

Pick decisively; do not ask the user to confirm window vs session. If the cwd is something generic like `$HOME` and the task name doesn't tell you which repo, default to a new **window** (cheaper to throw away than a session).

## Proactive splitting: multiple unrelated tasks in one request

When the user asks you to do **two or more tasks that don't share the current task's context**, split them into separate windows or sessions yourself, don't run them serially in this pane. Decide without asking:

- Tasks in **different repos / working directory trees** → spawn a new tmux **session** per off-tree task and run each one there.
- Tasks in the **same project** that need different branches checked out (fix issue #N **and** resolve conflicts in PR #M, two different feature branches, a hotfix while a long-running branch is open) → spawn a **git worktree** per extra task and open a new tmux **window** in that worktree. Without a worktree the second task would either have to wait for the first to free the working tree or stomp on its branch checkout, which defeats the point of running them in parallel. See "Parallel work in the same repo" below.
- Tasks in the **same project** that don't need branch isolation (lint pass, doc edit, running a long-running command alongside the current work) → spawn a new tmux **window** per task in the current working tree.
- Tasks that are **steps of one thing** in the current context → do them here, no split.

Spawn the extra window/session before starting the unrelated work, name it after the task, and tell the user one line per spawn so they can switch to it. Example:

```text
Started two side jobs:
  - window `fix-conflicts-pr-270` in worktree /home/kanon/worktrees/hunk/pr-270-conflict-fix: claude resolving conflicts on PR 270
  - session `baton-pr` in /home/kanon/work/baton-sdk: reviewing PR 1234
Continuing the original ask (issue #463 fix) here.
```

Do not split for trivial sub-steps (a follow-up grep, a one-shot script) that are clearly part of the current task.

## Parallel work in the same repo (worktrees + new windows)

When two same-repo tasks each need their own branch checked out, the second task gets a **git worktree** so it can have its own working tree and branch independent of the current pane. Use the `worktree` helper documented in the `worktrees` skill; it sets up the standard path layout and symlinks `.envrc` / `CLAUDE.md` / `.claude/` into the new worktree.

Concrete pattern for "fix issue #463 AND resolve conflicts in PR #270" (both in the same hunk repo, current pane already on a working branch):

```bash
# 1. From the current main checkout, create a worktree for the side task.
#    `worktree new` cuts a new branch off HEAD; for an existing remote PR branch,
#    create the worktree then fetch+checkout the PR branch inside it.
worktree new pr-270-conflict-fix
WORKTREE=$(worktree root)/pr-270-conflict-fix

# 2. Inside the new worktree, check out the PR branch so we can solve its conflicts.
#    `gh pr checkout` is the simplest way; it resolves the branch name automatically.
(cd "$WORKTREE" && gh pr checkout 270)

# 3. Open a new tmux window IN the worktree directory, with claude scoped to that task.
#    Use `-d` (detached) so the user stays focused on this conversation; without it,
#    tmux steals focus to the new window and the user loses their place mid-task.
tmux new-window -d -c "$WORKTREE" \
  "claude 'resolve the merge conflicts on PR 270 against main, then run typecheck and tests'"

# 4. Continue the original task (issue #463) in the current pane.
```

**Always pass `-d` when the spawn is a side job during a multi-task split.** The user is mid-conversation in the original pane and wants to stay there; the side window should exist and be reachable via `Ctrl-b <n>` without grabbing focus. Only omit `-d` when the user explicitly asked to *move* into the new window (e.g. "open a window for me to do X").

Rules of thumb for the worktree path:

- **Worktree per side task, not per main task.** The current pane keeps using the main checkout; only the *new* parallel tasks need worktrees. Spinning up a worktree for the current pane is busywork.
- **Branch name = worktree name.** Pick a short slug from the task: `pr-270-conflict-fix`, `fix-463`, `lint-cleanup`. The `worktree new` command derives the worktree path from the branch name.
- **`worktree -a <branch>`** (create-or-attach) is right when the branch already exists locally; `worktree new <branch>` creates a fresh branch off HEAD. Pick based on whether the side task is starting a new branch or continuing one.
- **Don't open the worktree in a separate session** unless the task is also off-tree. Same-repo work belongs in the same tmux session so the windows are grouped together and `tmux list-windows` shows them side by side.
- **Off-tree (different repo) parallel work still uses a tmux session**, not a worktree window. Worktrees are a same-repo, different-branch isolation tool; they don't replace sessions for cross-repo work.

## When the user explicitly says "window" or "tab"

```bash
tmux new-window -c <dir> "<command>"
```

- **Don't pass `-n` by default.** This user's tmux config sets `automatic-rename-format` to `#{b:pane_current_path}:#{pane_current_command}`, so new windows automatically get a `<folder>:<program>` name (e.g. `md-preview.nvim:nvim`). The status bar splits the name on the first `:` and colorizes the halves (folder `#d5c4a1` warm-light, program `#83a598` muted blue-green). Active vs inactive is distinguished by the `#F` flag (`*` marker), not a color change. Passing `-n` *turns auto-rename off* for that window, freezing the name forever, which is usually wrong.
- **Pass `-n` only when you need a stable name for dedupe / matching.** Example: a skill that checks `tmux list-windows | grep -F "$expected_name"` before opening, so a second invocation reuses the existing window. Two rules:
  - The shape is `<left-half>:<right-half>` with exactly one `:` (the first one) acting as the split point.
  - Pick the halves by what you want visually prominent. The status bar splits on the first `:` and renders left side in `#d5c4a1` (warm light tan — "the project / category") and right side in `#83a598` (muted blue-green — "the distinguishing detail"). Put the *grouping* on the left, the *most distinguishing signal* on the right. Examples: `md-preview.nvim:nvim` (auto-rename shape; project on left, running program on right), `hunk-c1:feature/foo` (the hunk skill's shape; "this is a hunk window for c1" on the left, branch as the standout on the right).
- A new window hides the current pane; a split keeps both visible. Use only when the user explicitly says "window" or "tab".

## Vocabulary map

| User says | Use |
| -- | -- |
| "pane", "panel", "split", "side-by-side", "next to this", "below this" | `tmux split-window` |
| "window", "tab", "another window" | `tmux new-window` |
| "session to do X" / "session for X" / "new session" in the **same** repo/tree | `tmux new-window` (colloquial "session" = a fresh tab) |
| "session to do X" / "session for X" where X is in a **different** repo/tree | `tmux new-session -d -s <name>` + `switch-client` |
| Multiple unrelated tasks in one request | Spawn extras proactively (window for same-tree, session for off-tree); do not ask |
| Parallel same-repo tasks that each need their own branch (issue #N + PR #M, two branches) | `worktree new <branch>` + `tmux new-window -c <worktree-path>` per side task |

When the user says "panel" they mean **pane** — that's a common slip.

## Passing prompts to claude safely

The trailing arg to `tmux split-window` / `new-window` is a single shell command string. Quoting matters:

- Wrap the whole command in double quotes; put the claude prompt in single quotes inside.
- If the prompt itself contains single quotes, escape them or use `$'...'` ANSI-C quoting.
- Avoid newlines in the prompt — they break the tmux arg parsing. Use a single long line, or pre-write the prompt to a file and `claude < /tmp/prompt.txt`.

```bash
tmux split-window -h -c /tmp "claude 'a prompt without single quotes'"
tmux split-window -h -c /tmp "claude \"prompt with 'inner quotes' is fine\""
```

## Safety check before splitting

If `$TMUX` is empty, the user isn't inside tmux and `split-window` will fail with "no current client". Check first:

```bash
if [ -z "$TMUX" ]; then
  echo "not inside tmux"
else
  tmux split-window -h -c "$PWD"
fi
```

In Claude Code's `Bash` tool, just inspect `echo $TMUX` first if uncertain.

## Verify after spawning

```bash
tmux list-panes -F '#{pane_index}: #{pane_current_command} #{pane_current_path}'
```

For a new window, use `tmux list-windows` and report the window index so the user can switch (`Ctrl-b <n>` by default).

## Layout helpers (optional polish)

After splitting, balance the panes evenly:

```bash
tmux select-layout even-horizontal   # equal-width left/right panes
tmux select-layout even-vertical     # equal-height stacked panes
tmux select-layout main-vertical     # big left pane, small right column
tmux select-layout tiled             # auto-grid for many panes
```

Resize a specific pane:

```bash
tmux resize-pane -t <index> -x 80   # set width to 80 cols
tmux resize-pane -t <index> -y 20   # set height to 20 rows
```

## Common mistakes to avoid

- Defaulting to `new-window` when the user said "pane" or "panel". **Always default to `split-window`.**
- Forgetting `-c <dir>` — the new pane inherits the tmux session's cwd, not the current pane's, which is often wrong.
- Quoting the entire `claude '<prompt>'` invocation with single quotes on the outside, then embedding single quotes — shell breaks. Keep outer quotes double, inner single.
- Running `tmux split-window` from a non-tmux shell. Always check `$TMUX` if unsure.
