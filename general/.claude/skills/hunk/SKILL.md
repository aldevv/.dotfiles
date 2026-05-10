---
name: hunk
description: Analyze a diff, compose review notes that explain complex flows or difficult paths, then open a Hunk session in a new tmux window with the notes already attached. Use when the user types `/hunk`, `/hunk-review`, asks to "open hunk", "review with hunk", "show changes in hunk", or wants to review a PR/branch/commit interactively.
argument-hint: [target]   # e.g. "main...feature", "HEAD~1", "origin/master..HEAD", "--pr 581", omit for current-branch vs upstream default
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - AskUserQuestion
---

# Hunk

Read the diff and compose the review notes **before** opening Hunk, then
open the TUI and attach the notes immediately. By the time the user looks
at the window, the inline annotations are already there — no awkward gap
where they're staring at an empty review while the model thinks.

**Comments are reserved for complex flows and difficult paths.** If the
diff doesn't have any, do not apply any comments — clear the `[pending]`
placeholder (see "Skip-when-trivial" below) and stop. Mechanical changes,
renames, signature widening, simple bug fixes, and clearly-readable
refactors don't get comments.

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
notes (or clear placeholder)**. Don't open Hunk first and then go think
about what to say.

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

Read the full diff and decide whether it contains any **complex flows or
difficult paths** (see "Comment scope" below). If yes, compose the comment
payload and map files → 1-based hunk indices using the `@@ -X,Y +A,B @@`
headers (the Nth hunk in a file's diff is `hunkNumber: N`). If no, prepare
to skip.

This step is the "review" — finish it before launching the TUI.

### 3. Open Hunk + attach notes (or clear placeholder)

Fire these together in a single message:

```bash
# Call A — open Hunk. If the current tmux window only has one pane, split
# right (less window churn for casual use); otherwise open a new window.
# Window name (multi-pane case): hunk-<repo>-<branch> so multiple reviews
# don't collide and a second invocation for the same branch can dedupe
# instead of stacking up.
if [[ "$(tmux display-message -p '#{window_panes}')" == "1" ]]; then
  tmux split-window -h "cd <REPO_ROOT> && hunk diff <RANGE>"
else
  tmux new-window -t "$(tmux display-message -p '#{session_name}')" \
    -n "hunk-$(basename <REPO_ROOT>)-$(git -C <REPO_ROOT> rev-parse --abbrev-ref HEAD)" \
    "cd <REPO_ROOT> && hunk diff <RANGE>"
fi
```

```bash
# Call B — sleep + verify the session is live
sleep 2 && hunk session list
```

(`tmux new-window` and `tmux split-window` without `-d` auto-switch focus
to the new pane/window, which is what we want.) If the user explicitly
asks to "open in a new window" even when only one pane is present, skip
the conditional and go straight to `tmux new-window`.

Once the session is live:

- **If complex flows or difficult paths exist** — apply notes in **one
  batch** and jump to the first one:
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

- **If nothing complex** — go straight to "Skip-when-trivial" below.

If `comment apply` rejects a target (path or hunk index mismatch), re-run
`hunk session review --repo <REPO_ROOT> --json` and reconcile the file
paths and hunk counts before retrying — only fall back to this on error.

### 3b. Skip-when-trivial — clear the placeholder

The hook drops a single `[pending] AI review in progress…` comment as soon
as the Hunk session registers (so the user sees the window isn't empty
while the parent session thinks). When the diff has nothing complex worth
explaining, you must remove that placeholder so the user isn't left
staring at "AI review in progress" forever:

```bash
hunk session comment list --repo <REPO_ROOT> --json \
  | jq -r '.comments[] | select(.summary | startswith("[pending]")) | .id' \
  | while read -r cid; do
      hunk session comment rm "" "$cid" --repo <REPO_ROOT>
    done
```

(The empty positional is required: `hunk session comment rm` takes
`[sessionId]` then `<commentId>` as positionals; `--repo` replaces session
lookup but leaves the first slot needing an empty string.)

After clearing, briefly tell the user the diff was straightforward and no
review comments were warranted — don't apply an empty placeholder of your
own, just leave the session uncommented.

### 4. One-time prompt: install the pre-PR/MR hook

State file: `$HOME/.cache/hunk/state.json` (XDG cache — machine-local, never synced into the dotfiles repo).

After the review is attached (or the placeholder cleared), check for the
state file:

```bash
test -f "$HOME/.cache/hunk/state.json" && cat "$HOME/.cache/hunk/state.json"
```

- **File exists** → skip this step entirely (already asked once).
- **File missing** → ask once via AskUserQuestion:

  Question: "Install a PreToolUse hook that auto-runs `hunk`
  right before any `gh pr create` or `glab mr create`? Hunk opens in a
  new tmux window and the parent Claude session fills it with review
  comments for any complex flows in the diff (or clears the placeholder
  if there's nothing complex)."

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
     ln -sf "$HOME/.claude/skills/hunk/hunk-pre-pr.sh" \
            "$HOME/.claude/hooks/hunk-pre-pr.sh"
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
   mkdir -p "$HOME/.cache/hunk" && \
     printf '{"hookInstalled": true, "promptedAt": "%s"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
     > "$HOME/.cache/hunk/state.json"
   ```

On **No**:
```bash
mkdir -p "$HOME/.cache/hunk" && \
  printf '{"hookDeclined": true, "promptedAt": "%s"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  > "$HOME/.cache/hunk/state.json"
```

On **Ask me later**: do not write state.

## Hook script

The shipped script lives next to this `SKILL.md` at
`hunk-pre-pr.sh` (so editing it edits one file, and `/sync-dotfiles`
distributes it across machines). Read it directly when you need to know
exactly what runs:

```bash
cat "$HOME/.claude/skills/hunk/hunk-pre-pr.sh"
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
   progress…` comment so the user has visible signal during the ~20–60s
   the parent session takes to read the diff.
6. Returns `permissionDecision: "deny"` with a brief instructing the
   parent session to:
   - Read the pre-computed diff.
   - Decide whether the diff has complex flows or difficult paths.
   - If yes: remove the `[pending]` placeholder and apply real comments.
   - If no: remove the `[pending]` placeholder and apply nothing.
   - Re-run the original `gh pr create` / `glab mr create` command.
7. On retry the hook surfaces an Allow/Deny prompt (default mode) or
   asks the user to confirm in conversation (bypassPermissions mode).

To make the hook itself **block** PR/MR creation until the user closes
Hunk, change the final `exit 0` to `exit 2`; the user then re-runs the
PR/MR command after reviewing.

## Comment scope — only complex flows and difficult paths

**The bar is high.** A comment must explain something a careful reader
would still find non-obvious after reading the function. Default to
applying nothing.

Apply a comment when:

- **Complex flows** — multi-step coordination, non-obvious state
  transitions, recursion, async patterns, fan-out/await, retry loops with
  subtle conditions. One brief comment at the entry point explaining the
  *shape* of the flow ("this fans out N tasks then awaits all, retrying
  any that return WouldBlock") — never per-step narration.
- **Difficult paths** — code with a non-obvious invariant the reader has
  to hold in their head, a subtle ordering requirement, a workaround for
  a specific bug or platform quirk, or a control-flow edge that's easy to
  misread.

**Do NOT comment on:**

- Behavioral changes that are clear from the diff itself (return-shape
  changes, new branches that any careful reader will catch).
- Cross-file invariants, rollout footguns, test gaps, env-var changes —
  those belong in the PR description, not in the hunk session.
- Pure renames, signature widening, comment-only changes, generated-file
  regenerations.
- Anything a careful read of the function makes obvious.

If the diff is entirely mechanical or the new code is straightforward,
**apply nothing** and clear the placeholder per "Skip-when-trivial".

Each comment that does get applied: a short `summary` (one-line headline)
plus a `rationale` (why-it-matters / what-shape-the-flow-has). Both render
in the Hunk TUI.

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
| `/hunk` (no arg) | `hunk diff <remote-default>...HEAD` |
| `/hunk HEAD~1` | `hunk diff HEAD~1` (last commit) |
| `/hunk --pr 30` | resolve via `gh pr view`, `hunk diff <base>...<head>` |
| `/hunk main..feature` | `hunk diff main..feature` |
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
