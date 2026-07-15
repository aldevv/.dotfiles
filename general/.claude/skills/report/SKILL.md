---
name: report
description: Analyze a diff, compose review notes that explain complex flows or difficult paths, then open a Hunk session as a pane inside the caller claude session's current tmux window with the notes already attached. Also the home of the shared review/report output-format references (`references/diff-note-format.md`, `references/format.md`) that every review and own-work skill follows. Requires tmux + `hunk` CLI. Use when the user types `/report`, `/report-review`, asks to "open hunk", "review with hunk", "show changes in hunk", or wants to review a PR/branch/commit interactively in the Hunk TUI. Do NOT trigger for plain PR review prose with no Hunk/TUI mention (use `code-review:code-review`), for posting a comment on an existing PR/MR thread (use `add-comment`), for whole-plugin audits (use `neovim-plugin-review`), or when not inside tmux.
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

- `scripts/hunk-pre-pr.sh` — the PreToolUse hook this skill optionally installs. Read it directly when you need to know what runs: `cat "$HOME/.claude/skills/report/scripts/hunk-pre-pr.sh"`.
- `references/review-guidance.md` — comment scope (what to flag, what to skip) plus tone rules and a worked example. Read at Round 3 before deciding what to apply.
- `references/examples.md` — curated good / bad concrete Hunk notes the operator has explicitly labeled in prior sessions. Read at Round 3 alongside `review-guidance.md` so you can pattern-match on shape before applying. Also the file to update when the operator labels a note good or bad in the current session — see "Operator feedback → examples.md" below.
- `references/hook-install.md` — the prompt + commands + settings.json target shape for Round 4. Read at Round 4 only when the state file is missing.

## When NOT to use

- Not inside tmux (`$TMUX` unset). The skill has nowhere to split off the Hunk pane.
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

Hunk always opens as a `split-window` off Claude's pane in the caller's current tmux window. The `-t "$TMUX_PANE"` target MUST be set on every tmux invocation; without it, tmux uses whatever the user is currently looking at (often a different window in the same session, because Claude's task ran for a while and the user moved focus), and the split lands in the wrong window.

`$TMUX_PANE` is set in Claude's bash environment to the pane id (`%NN`) of the pane Claude is running in. Use it as the target on every tmux invocation:

- `tmux split-window -t "$TMUX_PANE" ...` — split Claude's pane (this is the ONLY tmux open call in the flow).
- `tmux display-message -t "$TMUX_PANE" -p '#{...}'` — any pane-metadata read for diagnostics.

`new-window` is NOT part of this skill anymore. If the user asks for a separate window, tell them the skill only splits the current one and let them promote the pane themselves with `<prefix> !` (break pane out to its own window) after the fact.

`split-window` auto-switches focus for clients viewing Claude's session; clients viewing other windows or sessions are not yanked.

## Parallelism rules

Fire as much as possible in parallel. The workflow is three rounds; everything within a round goes in a single message with parallel tool calls. Inter-round work is serial only because later rounds need earlier rounds' outputs (range, diff text).

- **Round 1 — Discovery** (parallel): bundled skill, repo root, default branch, hook-prompt state, (if PR arg) `gh pr view`.
- **Round 2 — Open + read** (the `git diff` and `tmux split-window` are parallel; an active poll on `hunk session list` confirms the session is live before Round 3; do NOT use a fixed `sleep` — poll instead).
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

If the caller hands you a ready-to-apply comment batch (e.g. `pr-code-review` invokes `Skill(report)` with the JSON inline, or you're handed `comments_json=<path>` in `$ARGUMENTS`), the workflow collapses to TWO rounds:

- **Round 1 — Discovery** unchanged. Skip the `gh pr view` parallel call only if the caller also provided `<RANGE>` verbatim.
- **Round 2 — Open + apply** (single message, all parallel except the apply, which is gated on session-up):
  - `tmux split-window -h -l 70% -t "$TMUX_PANE"` to open the Hunk TUI as a pane in Claude's window (only mode; no new-window branch)
  - poll-then-apply one-liner (below), which blocks on `hunk session list` finding the repo, then pipes the supplied JSON to `hunk session comment apply --stdin`
  - `hunk session navigate --next-comment` runs AFTER the poll-then-apply in the SAME bash subshell so it's strictly sequenced without an extra round trip

In this mode you do NOT read `review-guidance.md`, do NOT read the diff to decide whether to comment, and do NOT re-derive hunk numbers if the caller supplied `newLine` (preferred; see "Targeting" in Round 3). Total elapsed time is dominated by Hunk's cold-start (typically ~500ms-1s), not by Claude latency.

**CRITICAL: apply every comment the caller supplied.** Fast-path is a load-all path: if the caller wrote N comments into the JSON, all N land in Hunk. Never drop a comment because you judge it low-severity, duplicative of an existing thread, redundant, or "the operator won't want that one" — the caller (typically `pr-code-review`) already made the include/exclude decision when it built the batch. Filtering on the hunk side hides notes from the operator's read-out and breaks the "Hunk = full picture" invariant. The ONLY reason to reject a comment mid-apply is a hard anchor error (the pre-apply diff-line validator flags `MISSING ADD <file>:<line>`); in that case, surface the error and let the caller fix the anchor, don't silently drop.

Recognize "pre-supplied" by any of:
- The skill prompt body contains a JSON object with a top-level `comments:` array.
- `$ARGUMENTS` includes `comments_json=<path>` or `comments=<path>`.
- The user pastes a numbered findings list with `file:line` anchors and explicitly says "open in hunk with these notes".

## Round 1 — Discovery (everything parallel)

Fire ALL of these in a single message:

- `cat "$(hunk skill path)"` (bundled session-control reference, the source of truth for `hunk session ...` semantics)
- `git rev-parse --show-toplevel`
- `git symbolic-ref --short refs/remotes/origin/HEAD` (faster than `git remote show origin`; the default branch is `${out#origin/}`)
- **Refresh the base ref — the local one may be stale.** Fetch the base/default branch (and, for a PR arg, its base) before resolving `<RANGE>`: `git fetch origin <default-or-base> --quiet` (fall back to a bare `git fetch origin --quiet` if you don't yet know the base). A stale local `main` is the #1 cause of a wrong diff — it makes `main...HEAD` report `no merge base` or dump the whole tree, and makes local `main..HEAD` diff against an old base. After fetching, ALWAYS compute ranges against the remote-tracking ref (`origin/<base>`), never the local branch name. Sanity-check with `git merge-base origin/<base> HEAD`; a returned sha means `origin/<base>...HEAD` is the correct, GitHub-matching range.
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
| `HEAD~1`, `origin/master..HEAD`, etc. | pass through verbatim |
| a range naming a LOCAL base branch (`main..feature`, `main...HEAD`) | rewrite the local base to its remote-tracking ref (`origin/main...HEAD`) after fetching — never diff against a local base that may be stale |
| `--pr N` / `pr N` / bare numeric `N` | `origin/<base>...<head>` from `gh pr view` |
| (working-tree review, no commits) | no range; use `hunk diff` / `git diff` with no args |
| (staged review) | `hunk diff --staged` / `git diff --staged` |

Two-dot (`origin/<branch>..HEAD`) vs three-dot (`origin/<base>...HEAD`) is the caller's choice, not something to override: two-dot shows only the commits on HEAD past the pushed branch head (a minimal delta of new work); three-dot shows the whole PR the way GitHub/GitLab render it. When a caller passes an explicit range, honor it verbatim after the local→remote rewrite above. Note the tradeoff only if asked: in a two-dot delta, a line a new commit replaced shows as `-` even where the web PR shows it as `+`.

## Round 2 — Open Hunk + read diff (parallel)

Once `<RANGE>` is known, single message with these in parallel:

- `git diff --no-color <RANGE>` (full diff for you to read; serves double duty as the emptiness check, no separate `--stat` call needed). **Skip in the fast path** — pre-supplied callers already analyzed the diff.
- Open Hunk in tmux as a pane split off Claude's pane, ALWAYS:
  ```bash
  tmux split-window -h -l 70% -t "$TMUX_PANE" "cd <REPO_ROOT> && hunk diff --watch <RANGE>"
  ```
  `-l 70%` sizes the new pane (hunk) to 70% of the original pane's width; the diff viewer is the focal task and benefits from horizontal real estate (split-view diff columns), so Claude shrinks to ~30% on the left rather than splitting 50/50. There is NO conditional on pane count, NO alternative `new-window` branch, and NO `target_session` / `force_new_window` opt-out. If the user asks for a "new window" or a "separate session," tell them the skill only splits — they can break the pane out afterwards with `<prefix> !` or move it to another window with `<prefix> .` if they want it standalone.
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

`split-window` auto-switches focus for clients viewing Claude's session. A client attached to a different session, or viewing a different window in Claude's session, is not yanked — they'll see the new pane next time they navigate to Claude's window.

If the diff returns empty, tell the user and stop. The Hunk pane will be empty too; either close it (`tmux kill-pane -t <pane>`) or leave it for the user.

If the poll loop exits without finding the session, tell the user "hunk failed to start" and stop. Do NOT proceed to apply on the assumption "it'll be up by the next tool call" — that's the regression that drops 12 comments silently.

## Round 3 — Apply (or skip)

**Skip this round entirely in the fast path** — the apply + navigate already happened in Round 2 inside the same bash subshell as the poll loop.

In the analysis path (no pre-supplied comments), read `references/review-guidance.md` AND `references/examples.md`. The guidance file has the rules; the examples file has concrete good / bad Hunk notes the operator has labeled in prior sessions. Pattern-match your draft against the good examples' shapes and against the bad examples' anti-patterns before applying.

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
# /tmp/report-validate.sh
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
' > /tmp/report-lines.tsv

jq -r '.comments[] | [.filePath, (.newLine // ""), (.oldLine // "")] | @tsv' /tmp/pr-N-comments.json |
while IFS=$'\t' read -r file nl ol; do
  if [ -n "$nl" ]; then
    grep -qP "^ADD\t${file}\t${nl}$" /tmp/report-lines.tsv || echo "MISSING ADD ${file}:${nl}"
  elif [ -n "$ol" ]; then
    grep -qP "^DEL\t${file}\t${ol}$" /tmp/report-lines.tsv || echo "MISSING DEL ${file}:${ol}"
  fi
done
```

If the validator prints any `MISSING` lines, stop and surface them to the caller. Do NOT silently fall back to `hunkNumber` — that's exactly the foot-gun this validation prevents.

If `comment apply` errors for any reason, fall back to `hunk session review --json` (per the bundled skill) to confirm the file/report structure. If the session is gone, stop and tell the user; don't try to reopen Hunk on its own.

**If nothing worth commenting on** — still leave one `Feature Explanation:` orientation note at the top of the diff. This is the minimum bar so the reader doesn't have to derive the feature from the code.

First, clear any `[pending]` placeholder (the pre-PR/MR hook drops one; `/report` usually doesn't):

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
cat "$HOME/.claude/skills/report/scripts/hunk-pre-pr.sh"
```

To make the hook **block** PR/MR creation until the user closes Hunk (instead of the default deny-then-retry-then-Allow), change the final `exit 0` to `exit 2`.

The hook exits early (no Hunk, no deny) when the current tmux session name matches `AUTO-inreview`, `AUTO-inprogress`, or `AUTO-inreview-others` — the three sessions `auto-new-day` dispatches. Those sessions' dispatch skills (`fix-bug-work`, `impl-connector`, `newconnector`, `pr-code-review-work`) already run `/report` themselves before returning control, so re-opening Hunk on `gh pr create` is redundant. To disable the bailout, drop the `case` block at the top of the script.

## Agent notes visibility

If the user reports "I don't see the comments", they likely have `agent_notes = false` in their `~/.config/hunk/config.toml`. Reload with the flag so existing comments show up:

```bash
hunk session reload --repo <REPO_ROOT> -- diff --agent-notes <RANGE>
```

**WARNING**: `reload` clears live comments but does NOT clear persisted agent notes — they survive the reload. If you re-apply your batch after a reload without clearing first, every note DUPLICATES (the operator sees each note twice). So before ANY re-apply that follows a reload (e.g. you changed the range, or fixed a note's wording), clear ALL notes first, not just the live ones:

```bash
hunk session comment clear --repo <REPO_ROOT> --yes
```

A `comment list --json | rm` loop is NOT enough — the default `comment list` returns only live comments and misses the persisted agent notes (visible via `comment list --type all --json`, keyed by `noteId`), which is exactly what leaves a stale duplicate behind. Use `comment clear --yes` (clears everything), then re-apply the batch.

## Operator feedback → examples.md

When the operator explicitly labels a Hunk note **good** or **bad** in the current session ("that's a good note", "this one is bad", "the summary is confusing", "keep this as an example"), record it in `references/examples.md` before continuing.

Trigger phrases (any of these fires the update):
- "this is a good note" / "that's a good note" / "keep this one as an example" / "this note is useful"
- "this is a bad note" / "that's a bad note" / "this doesn't help" / "the summary is confusing" / "rewrite this"
- "keep track of good notes" / "save this as a good example" / "save this as bad"

Update procedure:
1. Identify the specific note being labeled (its `filePath`, `newLine`, `summary`, `rationale`). If the operator's message references only the summary text, grep the current Hunk session's `comment list --json` to find the full note.
2. Genericize: replace project-specific tokens with generic placeholders. Ticket IDs → `<TICKET>`, vendor names → `<VENDOR>`, error codes → `<VENDOR_ERR_A>` / `<VENDOR_ERR_B>`, operation names → `<op>`, field names → `<field>`, method names → `<method>`. Keep the sentence shape intact; strip only the identifying data.
3. Append the genericized note under `## Good examples` or `## Bad examples` in `references/examples.md`. Number sequentially (`G3`, `G4`, `B3`, `B4`, ...). Include the summary line, the rationale, and a one-sentence paraphrase of the operator's reason.
4. If the operator gave a corrected version in the same turn (e.g. "the bad shape was X, do it like Y instead"), save both — the bad one under `## Bad examples` with a cross-reference to the good.

Never move an entry between Good and Bad without an explicit operator statement — the file is stable evidence, not editable opinions.

The examples file is a first-class part of the Round 3 review process. Load it alongside `review-guidance.md` before every note-application decision. Skipping it means re-committing anti-patterns the operator has already flagged.

## Common arguments → command mapping

| User says | Command to run |
|---|---|
| `/report` (no arg) | `hunk diff --watch <remote-default>...HEAD` |
| `/report HEAD~1` | `hunk diff --watch HEAD~1` |
| `/report --pr 30` | resolve via `gh pr view`, `hunk diff --watch <base>...<head>` |
| `/report main..feature` | `hunk diff --watch main..feature` |
| (working tree changes) | `hunk diff --watch` (no args) |
| (staged changes) | `hunk diff --watch --staged` |

`--watch` is the default so Hunk auto-reloads whenever the diff input changes (e.g. new commits, edited files, cursor movement across the branch). Drop `--watch` only if the caller explicitly asks for a static snapshot.
