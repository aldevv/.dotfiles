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

Open the Hunk TUI and attach review notes for any complex flows or difficult paths in the diff. Targeted notes are reserved for things a careful reader would still find non-obvious. When none are warranted, always leave a single `Feature Explanation:` orientation comment at the top of the diff so the reader has a starting point without having to derive the feature from the code.

**User input**: $ARGUMENTS

## Canonical CLI reference (read first)

The bundled `hunk-review` SKILL at `$(hunk skill path)` is the source of truth for every `hunk session ...` invocation, payload shape, flag, and error message. This skill layers a workflow on top: tmux orchestration, parallelism, pre-supplied comments, a diff-line validator, and a hook-install prompt. Do NOT restate CLI semantics here — when something is unclear about a `hunk session ...` command, go read the bundled skill.

Round 1 already loads it (`cat "$(hunk skill path)"`). Treat that read as mandatory.

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

## CRITICAL: Anchor every tmux call on `$TMUX_PANE`

The pane-count check and the eventual `split-window` / `new-window` MUST target Claude's pane, NOT the active client's current window. Without `-t`, tmux uses whatever the user is currently looking at, which is often a different window in the same session (Claude's task ran for a while; the user moved focus). The pane then lands in the wrong window: a split next to some unrelated work, or a new window in the wrong session if the user switched sessions.

`$TMUX_PANE` is set in Claude's bash environment to the pane id (`%NN`) of the pane Claude is running in. Use it as the target on every tmux invocation:

- `tmux display-message -t "$TMUX_PANE" -p '#{window_panes}'` — pane count of Claude's window
- `tmux display-message -t "$TMUX_PANE" -p '#{session_name}'` — Claude's session name
- `tmux split-window -t "$TMUX_PANE" ...` — split Claude's pane
- `tmux new-window -t "<claude-session>:" ...` — new window in Claude's session (derive `<claude-session>` from `$TMUX_PANE`, never from `tmux display-message` without `-t`)

This does not change focus behavior. `split-window` and `new-window` still auto-switch the focused client viewing Claude's session; clients viewing other windows or sessions are not yanked.

## Parallelism rules

Fire as much as possible in parallel. The workflow is three rounds; everything within a round goes in a single message with parallel tool calls. Inter-round work is serial only because later rounds need earlier rounds' outputs (range, pane count, diff text).

- **Round 1 — Discovery** (parallel): bundled skill, repo root, default branch, pane count, hook-prompt state, (if PR arg) `gh pr view`.
- **Round 2 — Open + read** (the `git diff` and `tmux split/new-window` are parallel; an active poll on `hunk session list` confirms the session is live before Round 3; do NOT use a fixed `sleep` — poll instead).
- **Round 3 — Apply** (sequential within the round): `comment apply` then `navigate`. These race if parallel.

### PR-feedback path: addressed-reviewer summary

If the work being reviewed in Hunk addressed reviewer feedback on an existing PR/MR (the common shape: someone left comments, this branch fixes each of them), attach one short note per addressed reviewer thread in addition to whatever feature-explanation / complex-flow notes you'd normally leave. The reader scrolls Hunk, lands on a `+` line, and sees "bjorn: did X. they said: '...'. <link>" right there.

**Detection — fire any of these:**
- The caller passes `pr_feedback=<path>` in `$ARGUMENTS`, where `<path>` is a JSON file with a top-level `pr_feedback: [...]` array (schema below).
- `fix-bug` Phase 7b, `impl-connector` Step 6 post-implementation, or any orchestrator skill that just walked an End-of-phase recap hands you the same JSON.
- Auto-detect from environment: if `$HOME/work/.auto-new-day/dispatch/<TICKET>.json` exists where `<TICKET>` is the lowercased ticket id from the current branch (`cxh-NNNN-...` style), AND the file has a `feedback` array, AND the latest commit (HEAD) was authored in the current session (heuristic: `git log -1 --format=%ar HEAD` is "X seconds/minutes ago" rather than hours/days), parse the dispatch and treat it as the payload. The dispatch's `feedback[]` entries carry `author`, `path`, `line`, `body`, and `source` — map these to the schema below.
- Auto-detect from the latest commit message: `git log -1 --format=%B HEAD` contains a PR-fix marker (`fix: address PR feedback`, `Fixes PR #NN comments`, `Addresses <author>'s review`, or a recent commit that named the PR review explicitly). When this fires WITHOUT a structured payload, you don't have the verbatim quotes — fall back to the analysis path and skip per-thread notes.

**Payload schema** (`pr_feedback[]` entries):

```json
{
  "author": "Bjorn Tipling",
  "author_handle": "bjorn-c1",
  "thread_link": "https://github.com/conductorone/baton-foo/pull/9#discussion_r1234567890",
  "comment": "Grant uses the bulk semantic-patch endpoint which returns 200 even on partial failure. Add a success_condition guard checking errors == [].",
  "fix_file": "pkg/config/config.yaml",
  "fix_line": 418,
  "fix_summary": "added the CEL guard for 200+errors partial-fail"
}
```

Field rules:
- `author` is the display name; `author_handle` is the gh/glab login. Use the FIRST NAME (or handle if no first name) in the hunk summary.
- `comment` is verbatim text from the comment. The skill truncates with `…` if it's over ~120 chars when building the rationale.
- `fix_file` + `fix_line` anchor the note. They MUST be a real `+` line in the diff — the diff-line validator (Round 3) catches mistakes.
- `fix_summary` is the one-line "how we fixed it" (the same content the operator wrote in the End-of-phase recap's `fix:` field, minus the file:line prefix).
- `thread_link` is the permalink to the comment / review / ticket entry.

**Workflow** when this fires:

- **Round 1 — Discovery** unchanged.
- **Round 2 — Open + read** unchanged.
- **Round 3 — Apply** — generate one hunk note per `pr_feedback[]` entry per `references/review-guidance.md` → "PR-feedback mode" (format spec lives there). Plus, ALWAYS include the Feature Explanation orientation note at the top of the diff. Plus, if the diff contains a complex flow that would benefit from a code-explanation note (existing behavior), include that too.

The three note categories are additive: orientation + per-reviewer + complex-flow can all coexist. They anchor on different lines, so the reader sees each one in context as they scroll.

If detection picks up a context (e.g. dispatch JSON exists) but the payload turns out to be empty (`feedback: []`) or missing required fields, fall back to the analysis path and surface to the user that the payload was malformed.

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
- `tmux display-message -t "$TMUX_PANE" -p '#{window_panes} #{session_name}'` (drives split-vs-new-window in Round 2; `-t "$TMUX_PANE"` anchors on Claude's pane so the user's current view never affects the decision — see "Anchor every tmux call on `$TMUX_PANE`" above. The two fields come back space-separated; capture both since Round 2 also needs `session_name`)
- `test -f "$HOME/.cache/hunk/state.json" && cat "$HOME/.cache/hunk/state.json" || echo MISSING` (Round 4 prompt state)
- If `$ARGUMENTS` matches `^(--pr +)?[0-9]+$` or `^pr +[0-9]+$` (a numeric PR identifier, with optional `pr` / `--pr` prefix): also fire `gh pr view <N> --json baseRefName,headRefName,headRepository`. `HEAD~N` does NOT match because it starts with `HEAD`.
- **PR-feedback detection** (fires the PR-feedback path described below): in parallel, run
  ```bash
  BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  TICKET=$(echo "$BRANCH" | grep -oE '^(cxh|CXH)-[0-9]+' | tr '[:lower:]' '[:upper:]')
  DISPATCH="$HOME/work/.auto-new-day/dispatch/${TICKET}.json"
  test -f "$DISPATCH" && echo "DISPATCH=$DISPATCH" || echo "DISPATCH=NONE"
  git log -1 --format='%ar | %s' HEAD 2>/dev/null
  ```
  Combine with `$ARGUMENTS` parsing: if `$ARGUMENTS` matches `pr_feedback=([^ ]+)` capture the path as `<PR_FEEDBACK_PATH>`. Decision rule:
  - `pr_feedback=<path>` in args → PR-feedback path, payload at `<path>`.
  - `DISPATCH != NONE` AND `git log -1 --format=%ar HEAD` shows minutes-or-seconds ago AND the dispatch file has a non-empty `feedback[]` array → PR-feedback path, payload constructed from the dispatch (see PR-feedback section above for the schema map).
  - Otherwise → analysis path (no per-reviewer notes; just orientation + any complex-flow notes).

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
  - **`force_new_window=true` is set (without `target_session`)** → `tmux new-window -t "$(tmux display-message -t "$TMUX_PANE" -p '#{session_name}'):" ...` in Claude's session regardless of pane count.
  - **1 pane and no directives** → `tmux split-window -h -l 70% -t "$TMUX_PANE" "cd <REPO_ROOT> && hunk diff <RANGE>"`. `-l 70%` sizes the new pane (hunk) to 70% of the original pane's width; the diff viewer is the focal task and benefits from horizontal real estate (split-view diff columns), so Claude shrinks to ~30% on the left rather than splitting 50/50.
  - **>1 panes and no directives** → `tmux new-window -t "$(tmux display-message -t "$TMUX_PANE" -p '#{session_name}'):" -n "hunk-$(basename <REPO_ROOT>):$(git -C <REPO_ROOT> rev-parse --abbrev-ref HEAD)" "cd <REPO_ROOT> && hunk diff <RANGE>"`
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

`split-window` and `new-window` auto-switch focus for clients viewing Claude's session. A client attached to a different session, or viewing a different window in Claude's session, is not yanked — they'll see the new pane next time they navigate to Claude's window.

If the diff returns empty, tell the user and stop. The Hunk window will be empty too; either close it (`tmux kill-pane -t <pane>`) or leave it for the user.

If the poll loop exits without finding the session, tell the user "hunk failed to start" and stop. Do NOT proceed to apply on the assumption "it'll be up by the next tool call" — that's the regression that drops 12 comments silently.

## Round 3 — Apply (or skip)

**Skip this round entirely in the fast path** — the apply + navigate already happened in Round 2 inside the same bash subshell as the poll loop.

In the analysis path (no pre-supplied comments), read `references/review-guidance.md`. Read the diff. Decide whether it contains complex flows or difficult paths.

In the PR-feedback path (Round 1 detection fired), read `references/review-guidance.md` → "PR-feedback mode" for the per-thread note format. Build the batch JSON by walking the payload (each entry → one comment with `filePath` = `fix_file`, `newLine` = `fix_line`, `summary` = `<first-name>: <fix_summary>`, `rationale` = `they said: "<comment, ≤120 chars with …>"\n\n<thread_link>`). Plus build the Feature Explanation orientation note at the top of the diff. Plus, if the diff also has a complex flow worth a code-explanation note, append that — all three categories ship in the same `comment apply --stdin` batch (the validator and the apply both accept multi-entry batches).

When auto-detecting from the auto-new-day dispatch JSON, map fields:
- dispatch `feedback[i].author` → payload `author_handle` (gh login). The display name isn't in the dispatch; fall back to the handle in the hunk summary unless the operator has handed you a separate `author_displayName` map.
- dispatch `feedback[i].body` → payload `comment` (truncate to ≤120 chars; if the body is multiline, take the first sentence only).
- dispatch `feedback[i].path` + `line` → original comment location, NOT the fix location. To find the fix anchor, grep the diff for the same `path` and pick the nearest `+` line (most-recent commit). If no `+` line in that file landed in this session's commits, skip that thread — the fix happened in an earlier session and isn't yours to attribute.
- dispatch `feedback[i].source` (e.g. `pr-review`, `pr-comment`) plus the PR URL from the dispatch JSON's top-level `prUrl` → construct `thread_link`. For PR review inline comments specifically, the dispatch may not carry the discussion id; in that case use the PR URL itself plus the file:line as the link (the operator can scroll to it).

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

If `comment apply` errors for any reason, fall back to `hunk session review --json` (per the bundled skill) to confirm the file/hunk structure. If the session is gone, stop and tell the user; don't try to reopen Hunk on its own.

**If nothing worth commenting on** — still leave one `Feature Explanation:` orientation note at the top of the diff. This is the minimum bar so the reader doesn't have to derive the feature from the code.

First, clear any `[pending]` placeholder (the pre-PR/MR hook drops one; `/hunk` usually doesn't):

```bash
hunk session comment list --repo <REPO_ROOT> --json | \
  jq -r '.comments[] | select(.summary | startswith("[pending]")) | .commentId' | \
  while read -r cid; do hunk session comment rm "$cid" --repo <REPO_ROOT>; done
```

With `--repo`, `hunk session comment rm` takes exactly one positional: the `<commentId>`. The two-form signature is `<session-id> <commentId>` OR `<commentId> --repo <path>` — passing both an empty session-id and `--repo` errors with "Specify exactly one comment id with --repo".

Then apply the orientation note using the same `comment apply --stdin && navigate --next-comment` pattern from above, with a single-entry payload:

- **Anchor**: pick the file that best represents the feature surface (proto/schema, public API, primary handler). Skip generated files (`*.pb.go`, `*.pb.validate.go`, `*_protoopaque.pb.go`, `*.gen.go`), vendored code (`vendor/`), test files, and trivial one-liners (e.g. version bumps). If everything in the diff is generated/vendored/trivial, fall back to the first added line in the first file. Use the first `+` line in the chosen file as `newLine`.
- **Summary**: `"Feature Explanation: <one-line headline>"` (chat-line, no period).
- **Rationale**: 2-3 sentences in plain words. What the feature does, what the change adds, and (if relevant) the design tradeoff. This is the only note the reader gets, so make it count. The tone rules and meta-narration bans in `references/review-guidance.md` still apply.

Tell the user that no targeted notes were warranted and a top-of-diff `Feature Explanation:` note was left as the orientation.

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
