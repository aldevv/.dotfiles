---
name: pr-code-review
description: Multi-angle review of one OR more GitHub PRs. The coordinator adaptively picks an agent count between 1 and 12 plus an effort tier (low / medium / high) per PR based on the PR's scope, importance, and complexity — a one-file typo gets 1 agent at low effort; a security-sensitive multi-file refactor gets 10-12 at high effort. The user can still override with `count=<N>` or a leading integer. Loads applicable CLAUDE.md / CLAUDE.local.md / lazy rules from cwd, walking up to home, before fanning out, and passes the loaded rules to every subagent. After the review agents return, spawns a second parallel verification pass that has DIFFERENT subagents fact-check every factual claim. BLOCKER and MAJOR findings MUST be verified by public-doc fetch, local reproduction on the checked-out PR branch, or runtime-path trace through code; the "very obvious from the diff" escape hatch requires the verifier to state explicitly that no extra verification was needed. Each consolidated finding ships with a confidence percentage (0-100%), a ✓ marker, and the verification mode used. Opens Hunk with ALL findings attached first, then asks the operator a yes/no whether to reduce to the most important + highest-confidence findings (the skill picks an integer between 1 and 5 based on confidence and importance), then walks each surviving finding with the user for Yes-post / Edit / Skip. Trigger on "/auto-new-day:pr-code-review <pr-or-list>", "code review this PR with N subagents", "review these PRs with subagents", "do a multi-angle review of PR #N", or any explicit request to deeply review one or more PRs. Use `pr-code-review` for explicit PRs with operator-in-the-loop comment posting. Sibling skills (project-scoped batch drivers like `pr-code-review-all`) call this skill under the hood.
argument-hint: <pr-or-list> [count=<N>] [--no-subagents] (e.g. https://github.com/owner/repo/pull/80, "owner/repo#80 owner/other-repo#42 count=9", or "9 <url1> <url2>"). `--no-subagents` (or `NO_SUBAGENTS=1` in env) collapses every parallel review / verification `Agent(...)` spawn into a sequential `TaskCreate` list in the main session — slower wall-time, much cheaper token cost.
---

# pr-code-review

Multi-PR multi-angle review with verified findings, confidence scoring, and operator-in-the-loop comment posting. One or more PRs per invocation. Each subagent flags only issues anchored to `+` lines in the diff. Each factual claim is independently fact-checked by a different subagent before the operator sees the table. The operator approves each finding before it lands on the PR.

Re-review awareness: each review appends a short entry to a per-PR log. When a PR is reviewed again, the skill reads that file first, so the next pass knows which lines were already commented on, which findings were filtered as FALSE, and what HEAD SHA the last review saw. That lets the new run focus on what changed since then rather than re-litigating settled ground.

The log's location depends on where the operator invoked the skill (`INVOKED_FROM`, captured at Step 0a):
- **Invoked inside a git repo** (`INVOKED_FROM` resolves under any `.git` directory) → log lives at `$REPO_DIR/.pr/$PR_NUM.md`. One folder per repo; one file per PR.
- **Invoked outside any git repo** (typical: `~/work`, `~/repos`, a multi-repo coordinator dir) → log lives at `$INVOKED_FROM/.pr/$REPO/$PR_NUM.md`. One `.pr/` folder collecting every reviewed repo as a subdirectory; one file per PR.

The repo-local layout keeps the log next to its repo. The parent-folder layout keeps cross-repo reviews grouped together, which is the common case when batch-reviewing PRs from a multi-repo home like `~/work`.

See `references/examples.md` for sample findings, comment phrasing, and ask/post loop output.

## Subagent execution mode (`--no-subagents` / `NO_SUBAGENTS=1`)

Default: the parallel review / verification / hunk-prep fan-outs described below fire as designed (fastest wall time, highest token cost). Passing `--no-subagents` in `$ARGUMENTS`, OR setting `NO_SUBAGENTS=1` in the environment, replaces EVERY `Agent(...)` parallel-spawn step in this skill with a `TaskCreate` list executed sequentially by the main session — one task per would-be subagent role (each review lens, each verification pass), same brief, same synthesis at the end. Trades wall time for token cost (no context duplication across N subagents). `auto-new-day` sets this by default; its `--fast` flag suppresses it.

## CRITICAL: Validation loop in `--no-subagents` mode

When `--no-subagents` is active, the Step 4 verification round MUST run as a **repeated checklist**, not a single sequential pass. A single pass in the same session shares context with the review, so it counts as `✓1` at best — the operator ends up with reviewed-but-not-independently-verified findings. That defeats the review.

Policy (applies whenever `--no-subagents` / `NO_SUBAGENTS=1` is set):

- Build a **VALIDATION_CHECKLIST** at Step 4 with one row per surviving finding from Step 3. Each row lists: the claim, the anchor `file:line`, the specific check to run (doc fetch, code path trace, spec quote, local reproduction), and the pass counter.
- Run the checklist end-to-end **at least three times** (default `VALIDATION_PASSES=3`; the operator may override with `passes=<N>` in `$ARGUMENTS`, clamped to `2..5`). Each pass is a fresh sweep over the whole checklist — do NOT stop early on the first "looks fine" pass, and do NOT skip rows on later passes because an earlier pass passed them.
- Each independent pass counts as `+1` toward the finding's `✓N` marker. `✓3` in sequential mode means three independent re-checks in the SAME session, each performed after clearing local scratch state (drop the prior verifier's notes, re-read the code / doc from scratch, form the verdict without looking at earlier passes' answers).
- If any pass FLIPS a verdict (e.g. `TRUE` → `FALSE` or vice versa), surface the disagreement in Step 5 and lower the confidence — do NOT quietly average. Two out of three still leaves the finding uncertain; say so.
- BLOCKER and MAJOR findings ALWAYS get the full pass count. MINOR findings may cap at `VALIDATION_PASSES=2` when the operator opts in via `--fast-minor`, otherwise they run the full count too.
- The rule also applies to Step 5a's "approve PR" confidence: the final go/no-go is computed only after all validation passes complete, and the confidence percentage is scaled down when passes disagreed.

Why: `--no-subagents` exists to save tokens on runs no human is watching in real time (typically `auto-new-day`). Cheap wall time is fine to spend on multiple sequential re-checks; the alternative is shipping `✓1` findings that were never actually verified.

## CRITICAL: Approving a PR — no body unless explicitly asked

When the operator says "approve the PR" / "approve it" / "lgtm it" / any equivalent during or after a review, submit the approval WITHOUT a `--body`. No `lgtm`, no `looks good`, no summary, no nothing:

```bash
gh pr review <N> --repo <owner>/<repo> --approve
```

The operator approves PRs all day and adds words to the approval only when they specifically want to. Auto-attaching a body (even something as short as `lgtm`) creates noise on every PR thread and clutters the reviewer's history. Only add `--body "<text>"` when the operator explicitly says "approve with body X" / "approve and say Y" / "leave a comment on the approval saying Z". Same rule applies to `--request-changes` and `--comment` reviews: no body unless explicitly asked.

## When to run

- User types `/auto-new-day:pr-code-review <pr>` or `/auto-new-day:pr-code-review N <pr1> <pr2> ...` and asks to "review this PR with subagents" / "review these PRs with N subagents".
- User pastes one or more PR URLs and asks for a deep review with posted comments.

Do NOT trigger for:
- A drive-by skim where the user only wants prose feedback (just review inline).
- Reviewing the user's own PR before opening it (use project-specific pre-PR validators when available).

## Inputs

One or more PR references, in any of these shapes per PR:
- `https://github.com/<org>/<repo>/pull/<N>`
- `<org>/<repo>#<N>`
- `#<N>` (only if cwd is inside the repo clone)

Multiple PRs are space-separated in the arg string. Order does not matter; agents fan out across all PRs in parallel.

Optional flags inside the arg string:
- A bare leading integer (`9 <urls...>`) OR `count=<N>` → number of subagents per PR. When set, this OVERRIDES the adaptive sizing in Step 2 (clamped to `1..12`). When unset, Step 2 picks a count adaptively in `1..12` based on the PR's scope, importance, and complexity.

(Legacy note: `target_session=` and `force_new_window=` were forwarded to the inner `hunk` call in earlier versions. Hunk now always splits off the calling pane, so those flags are dead. If a sibling batch driver still passes them, ignore silently.)

Parse each PR reference to `OWNER`, `REPO`, `PR_NUM`. If any reference is malformed, ask the user.

## Step 0. Multi-PR dispatcher (skipped for single PR)

If MORE than one PR was passed, the current session acts as a dispatcher: it does no review work itself. Instead it opens a tmux session called `<folder>-code-review` (where `<folder>` is `basename "$(pwd)"` slugified) and spawns one window per PR with a fresh `claude --dangerously-skip-permissions` instance reviewing that single PR. Each spawned per-PR claude runs the single-PR flow end-to-end; its own hunk pane splits off inside that per-PR window when the review reaches the open-Hunk step.

Why: each PR's review is independent, can take minutes, and benefits from running in its own claude context. The operator attaches to the session and watches each PR in its own window without cross-contamination.

Implementation:

**Prefer the shipping `review` util** at `$SCRIPTS/shared/utilities/review` (or wherever the operator keeps it on `$PATH`). It handles slugifying the folder name, dispatching each URL into its own window, switching the operator to the session if already in tmux (or printing `tmux attach` if not), and works under any `tmux base-index`. Just call:

```bash
review "<space-separated PR/MR URLs>"
```

If `review` is not on PATH, fall back to the inline equivalent below. The fallback must:
- capture the placeholder window's actual index (`tmux list-windows -F '#{window_index}' | head -n1`) instead of hardcoding `:0`, since `base-index` can be `0` or `1`
- end with `tmux switch-client -t "$session"` when `$TMUX` is set, or `echo "attach with: tmux attach -t $session"` otherwise

```bash
folder=$(basename "$PWD" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')
[ -z "$folder" ] && folder="review"
session="${folder}-code-review"

placeholder_idx=
if ! tmux has-session -t "$session" 2>/dev/null; then
  tmux new-session -d -s "$session" -n placeholder
  placeholder_idx=$(tmux list-windows -t "$session" -F '#{window_index}' | head -n1)
fi

posted=0
for url in "${pr_urls[@]}"; do
  win_name=$(name_for "$url")  # e.g. <repo>-<N>
  cmd="claude --dangerously-skip-permissions '/auto-new-day:pr-code-review ${url}'"
  if [ -n "$placeholder_idx" ] && [ $posted -eq 0 ]; then
    tmux rename-window -t "${session}:${placeholder_idx}" "$win_name"
    tmux send-keys     -t "${session}:${placeholder_idx}" "$cmd" C-m
  else
    tmux new-window -t "${session}:" -n "$win_name" "$cmd"
  fi
  posted=$((posted + 1))
done

echo "dispatched $posted PRs to tmux session '${session}'"
if [ -n "${TMUX:-}" ]; then
  tmux switch-client -t "$session"
else
  echo "attach with: tmux attach -t ${session}"
fi
```

After dispatching, exit the skill. Do not proceed to Step 0a / Step 1 / etc. on the original claude. Those steps belong to the per-PR claude instances in the spawned windows, each of which sees ONE PR url via `/auto-new-day:pr-code-review <url>` and runs the single-PR flow end-to-end.

If only ONE PR was passed, proceed to Step 0a directly. The dispatcher mode is multi-PR-only.

## Step 0a. Load applicable CLAUDE.md rules BEFORE fanning out

Before anything else, snapshot the invocation directory. The skill `cd`s into each PR's checkout during Step 0b, so the original location has to be captured up front. This value drives where the per-PR log lives (Step 1b and Step 5c).

```bash
INVOKED_FROM=$(pwd -P)
```

Then resolve the canonical log root once and remember it for every PR in the batch:

```bash
# Resolve the target date once (--date arg or today).
SCRIPTS="$HOME/work/.claude/skills/auto-new-day/scripts"
DATE=$("$SCRIPTS/resolve-date.sh" ${DATE_ARG:-today})

# If INVOKED_FROM is inside any git repo, per-repo layout wins (one
# .inreview/<DATE>/auto-new-day:pr-code-review/ folder next to each repo's code).
# Otherwise, treat INVOKED_FROM as a multi-repo parent (e.g. ~/work) and
# group all PR logs under <INVOKED_FROM>/.inreview/<DATE>/auto-new-day:pr-code-review/<repo>/.
if git -C "$INVOKED_FROM" rev-parse --show-toplevel >/dev/null 2>&1; then
  PR_LOG_LAYOUT="per-repo"
else
  PR_LOG_LAYOUT="parent"
  PR_LOG_ROOT="$INVOKED_FROM/.inreview/$DATE/auto-new-day:pr-code-review"
fi
```

State the chosen layout in chat ("PR review logs will land under `~/work/.inreview/<DATE>/auto-new-day:pr-code-review/<repo>/<N>.md` because cwd is not in a git repo.") so the operator can interrupt and override if the auto-detection picked wrong. (Note: this used to be a separate `.pr/` folder; it now lives under `.inreview/<DATE>/auto-new-day:pr-code-review/` so auto-new-day's per-date archive picks it up automatically — `/auto-new-day --date X` replays this report with zero copy-around.)

Also resolve the operator's own GitHub login once. Step 5's author-aware overlap tagging uses it to tell apart comments the operator wrote (tag `overlap=self-silent` for insist, `overlap=self-engaged` for lower-default) from comments other humans wrote (tag `overlap=external-human`) and from bot comments (tag `overlap=external-bot`). No overlap ever silently drops a finding; every consolidated finding still ships to Hunk in Step 6b with its tag in the summary prefix. The operator makes the drop decision in Step 8.

```bash
OPERATOR_LOGIN=$(gh api user --jq .login)
```

If the call fails (no auth, network) set `OPERATOR_LOGIN=""` and fall back to treating every overlap as "different user" (drop). Don't block the whole skill on this lookup.

The review agents need the same project rules the main session uses. This skill ALWAYS loads:

1. **Home CLAUDE.md** — `~/CLAUDE.md` (global rules) and `~/CLAUDE.local.md` if it exists.
2. **Ancestor CLAUDE.md walk** — from `cwd` up to `$HOME`, include every `CLAUDE.md` / `CLAUDE.local.md` found along the way. This picks up project-root and intermediate-scope rules without enumerating them by hand.
3. **Repo-local CLAUDE.md** — once `REPO_DIR` is resolved (Step 0b below), also load `$REPO_DIR/CLAUDE.md` and `$REPO_DIR/CLAUDE.local.md` if they exist.
4. **Lazy files whose triggers fire for the review work itself.** Many CLAUDE.md files in the ancestor walk point at `.claude/lazy/*.md` rule files with `**Read when**` clauses. Walk each loaded CLAUDE.md, collect any `.claude/lazy/*.md` references, and load each one whose trigger fires on the current work. Triggers commonly relevant to this skill:
   - "running `gh` subcommands" (the skill runs many)
   - file-pattern triggers that match files touched in any PR's diff (test files, CI workflows, package directories, action handlers, etc.)
   - any explicit "PR review" / "code review" trigger
   Err broader on a match: a wasted load is fine, a silently-missed load is not.

Build one **CONTEXT_PACK** containing the full text of every loaded file, with a header per file showing the source path. Write it to `/tmp/pr-review-context-pack.md` and also keep the in-memory string. The pack feeds into each subagent prompt at Step 3.

**The coordinator (this skill) decides per agent how to pass rules to subagents.** Pick from:

1. **Inline full text.** Embed the relevant CLAUDE.md section(s) directly in the agent's prompt body. Best for short, must-read rules every agent needs (e.g. project-wide style or correctness rules that apply across angles). All standing agents should get these inline.
2. **Path-index only.** List the loaded files by path and tell the agent to `Read` whichever match its lens. Best for thick reference docs the agent may or may not need. The agent loads on demand from `/tmp/pr-review-context-pack.md` or the original path.
3. **Both.** Inline the must-read block + an index of additional files. Default for the standing six angles.

Subagents MAY walk the CLAUDE.md tree themselves if their prompt instructs them to, but the coordinator should bias toward pre-loading. The reason: every subagent walking the tree means N × ancestor-walk cost. The coordinator already did it once; reuse that work.

For each angle, decide which loaded files matter. Examples:
- **error-handling** agent: inline any project-wide error-propagation rules; path-index deeper language/framework references that may or may not apply.
- **pagination** agent: inline any project-wide pagination/list-iteration rules; path-index framework specifics.
- **tests** agent: path-index any test/CI rule files; nothing inlined unless the project has hard rules every test must follow.
- **API surface** agent: don't pass CLAUDE.md rules (they don't help with vendor docs); pass vendor doc URLs from the PR description instead.

If `cwd` is outside any project checkout (e.g. running this skill from `~`), still load home + any ancestor-walk rules; the per-repo CLAUDE.md is filled in once `REPO_DIR` resolves per PR.

## Step 0b. Resolve the local checkout (per PR)

For each PR, the diff and the inline-comment workflow both need a local clone. The skill first looks for an existing checkout in the common locations, and only clones if none is found.

When a clone IS needed, the destination depends on whether the operator is currently working in a "work" context. Detection is based on `pwd`: if the current directory is inside `${WORK:-$HOME/work}` or `$HOME/worktrees/work`, the operator is working on work repos, so the clone lands under `${WORK:-$HOME/work}/$REPO`. Otherwise it lands under `${PROJECTS:-$HOME/repos}/$REPO`. This avoids dropping a work repo into the personal tree (or vice versa) just because the operator happens to be elsewhere when they kick off a review.

```bash
# Existing-checkout search: any of these wins.
candidates=(
  "${WORK:-$HOME/work}/$REPO"
  "$HOME/repos/$REPO"
  "${PROJECTS:-$HOME/projects}/$REPO"
  "${CODE:-$HOME/code}/$REPO"
)
REPO_DIR=""
for c in "${candidates[@]}"; do
  [ -d "$c/.git" ] && { REPO_DIR="$c"; break; }
done

# Not found locally. Pick the clone target based on pwd.
if [ -z "$REPO_DIR" ]; then
  cwd=$(pwd -P)
  work_root="${WORK:-$HOME/work}"
  case "$cwd" in
    "$work_root"|"$work_root"/*|"$HOME/worktrees/work"|"$HOME/worktrees/work"/*)
      REPO_DIR="$work_root/$REPO"
      ;;
    *)
      REPO_DIR="${PROJECTS:-$HOME/repos}/$REPO"
      ;;
  esac
  mkdir -p "$(dirname "$REPO_DIR")"
  gh repo clone "$OWNER/$REPO" "$REPO_DIR"
fi

cd "$REPO_DIR"
git fetch origin "pull/$PR_NUM/head:pr-$PR_NUM" -f
git checkout "pr-$PR_NUM"
```

State which destination you picked and the reason in chat before the clone runs ("cloning $OWNER/$REPO under $REPO_DIR (pwd is inside $WORK, so this is a work-context clone)") so the operator can interrupt if the auto-detection is wrong. If the operator overrides ("no, put it in repos") just clone to `${PROJECTS:-$HOME/repos}/$REPO` instead; do not re-derive the path.

The `-f` on the fetch covers the case where the local clone already has a `pr-<N>` branch from a prior run.

When multiple PRs are passed, run the per-PR checkout sequentially (different repos can't safely `cd` in parallel inside the same shell). Each PR's diff lands in `/tmp/pr-<N>.diff` so the agents stay isolated.

Also reload the CONTEXT_PACK from Step 0a now that `$REPO_DIR/CLAUDE.md` is reachable. Append the repo-local file if present.

## Step 1. Fetch PR metadata and diff (per PR, in parallel across PRs)

For each PR, in a single message run these in parallel:

```bash
gh api "repos/$OWNER/$REPO/pulls/$PR_NUM" \
  --jq '{title, body, head: .head.sha, base: .base.ref, additions, deletions, changed_files, author: .user.login, created_at, updated_at, state, draft, html_url}' \
  > "/tmp/pr-$PR_NUM.meta.json"

git diff "origin/$(jq -r .base /tmp/pr-$PR_NUM.meta.json)...pr-$PR_NUM" > "/tmp/pr-$PR_NUM.diff"

gh api "repos/$OWNER/$REPO/pulls/$PR_NUM/comments" \
  --jq '[.[] | {id, in_reply_to_id, user: .user.login, path, line, commit_id, body: (.body[0:400])}]' \
  > "/tmp/pr-$PR_NUM.existing-comments.json"

gh api "repos/$OWNER/$REPO/issues/$PR_NUM/comments" \
  --jq '[.[] | {id, user: .user.login, body: (.body[0:500])}]' \
  > "/tmp/pr-$PR_NUM.existing-issue-comments.json"

gh api "repos/$OWNER/$REPO/pulls/$PR_NUM/reviews" \
  --jq '[.[] | select(.body != "" and .body != null) | {id, user: .user.login, state, submitted_at, commit_id, body: (.body[0:800])}]' \
  > "/tmp/pr-$PR_NUM.existing-reviews.json"
```

Three sources, all author-tagged so Step 5 can apply the author-aware policy:
- `existing-comments.json` — inline review comments on lines (parents + replies; `in_reply_to_id` tells you which are replies). Bodies trimmed to 400 chars.
- `existing-issue-comments.json` — top-level / issue-style comments on the PR. Bodies trimmed to 500 chars.
- `existing-reviews.json` — paragraph-length review-summary bodies attached to a review submission (the "Request changes" / "Comment" / "Approve" body, when non-empty). Bodies trimmed to 800 chars since these are usually the longest.

If the project has well-known noise paths the diff should exclude (generated files, vendored code, lockfiles), pass a path filter to `git diff` here. Detect them from `.gitattributes`, `.gitignore`, or the project's CLAUDE.md rather than hardcoding any path list.

Note the `head` SHA. Every inline comment must be posted with `commit_id` equal to the PR head (FULL SHA, not abbreviated; `gh` rejects abbreviated commit IDs with `commit_id is not part of the pull request`).

## Step 1b. Load prior-review log (per PR)

After Step 1 fetches the diff and existing comments, also check for a prior-review log. The skill writes this file at Step 5c whenever it finishes a review; it's a short, append-only log per PR so the next pass can pick up where the last one left off.

Resolve the log path using `PR_LOG_LAYOUT` from Step 0a:

```bash
if [ "$PR_LOG_LAYOUT" = "per-repo" ]; then
  PR_LOG="$REPO_DIR/.inreview/$DATE/auto-new-day:pr-code-review/$PR_NUM.md"
else
  PR_LOG="$PR_LOG_ROOT/$REPO/$PR_NUM.md"
fi

PRIOR_REVIEW_SUMMARY=""
LAST_REVIEWED_SHA=""
if [ -f "$PR_LOG" ]; then
  PRIOR_REVIEW_SUMMARY=$(cat "$PR_LOG")
  # Entries are appended chronologically; the last `head: <sha>` line is the
  # most recent review. `grep -m1` would pick the OLDEST, so use tail to flip.
  LAST_REVIEWED_SHA=$(grep -oE 'head: [0-9a-f]{7,40}' "$PR_LOG" | tail -n1 | awk '{print $2}')
  if [ -n "$LAST_REVIEWED_SHA" ] && git cat-file -e "$LAST_REVIEWED_SHA" 2>/dev/null; then
    git diff "$LAST_REVIEWED_SHA...pr-$PR_NUM" > "/tmp/pr-$PR_NUM.new-since-last.diff"
  else
    : > "/tmp/pr-$PR_NUM.new-since-last.diff"
  fi
else
  : > "/tmp/pr-$PR_NUM.new-since-last.diff"
fi
```

If the log is absent (first review on this PR), `PRIOR_REVIEW_SUMMARY` stays empty and `new-since-last.diff` is empty too. The agents fall back to the full diff in that case (Step 3 handles this branch).

If `LAST_REVIEWED_SHA` is unreachable (PR was force-pushed and the old SHA was garbage-collected from the local clone), treat it as a first review for diff-incremental purposes but still pass `PRIOR_REVIEW_SUMMARY` to agents so they know which findings were already posted or filtered. The full diff is the fallback.

## Step 1c. Classify PR shape (REFACTOR vs MIXED vs FEATURE)

Before sizing or fanning out, classify the PR as one of three shapes. The classification controls how strict the moves-and-refactors hard constraint binds for every agent in Step 3. Get this wrong and the agents will burn effort flagging implementation details of moved code that the reviewer has no intent to revisit. State the classification and the one-sentence rationale in chat before Step 2.

**Read these signals from `/tmp/pr-<N>.meta.json` (PR description) and `/tmp/pr-<N>.diff`:**

- **Description language.** Verbs like "migrate", "move", "extract", "rename", "replace X with Y", "convert", "switch to", "port to", "lift out", "consolidate", "containerize" all point at REFACTOR. Verbs like "add", "implement", "support", "introduce", "enable", "new" point at FEATURE.
- **Diff shape.** A diff that's mostly `-` followed by `+` of the same logic with adjusted signatures, package paths, or call sites is REFACTOR. A diff that adds net-new top-level functions / resource types / endpoints / fields with no `-` counterpart is FEATURE.
- **File creation pattern.** New file that's a relocation of logic from a deleted/shrunk file is REFACTOR (e.g. `pkg/x/cache.go` deleted, `pkg/x/session_cache.go` added, same operations). New file that introduces a new abstraction or resource is FEATURE.
- **The base-branch comparison.** For every chunk of suspicious "new" code in the diff, run `git -C $REPO_DIR show origin/<base>:<old-path>` (when the path was renamed/relocated) or grep the base branch for the deleted symbols. If the pattern (drain loop, mutex, bare-error return, in-memory cache) existed pre-PR in any form, the PR's version is a RELOCATION, not new logic.

Classification rules:

| Shape | When | Behavior |
| --- | --- | --- |
| **REFACTOR** | The PR description explicitly says it's a migration/move/refactor/replace AND the diff is dominated by signature-style changes / file relocations / API-version migrations. Examples: "migrate to V2", "replace sync.Map with session store", "containerize the connector", "extract X into pkg/Y", "rename Foo to Bar". | Agents review the MOVE only: was the right thing moved, are all callers redirected, is anything dropped, is the new package/abstraction correct, did anything end up orphaned. Agents do NOT review the LOGIC of the moved code (concurrency model, error-wrapping style, granularity of cache writes, retry semantics) because that logic was forced into its current shape BY the move and is not the reviewer's choice to redesign on this PR. |
| **MIXED** | The PR description names a refactor AND new behavior in the same change (e.g. "containerize + add new resource type", "migrate to V2 AND add Workspaces sync"). | Agents review the MOVE per REFACTOR rules, AND review the NEW behavior per FEATURE rules. Annotate each finding with which mode it falls under; FEATURE-mode findings are eligible to post, REFACTOR-mode findings stay out unless they break correctness. |
| **FEATURE** | The PR adds net-new top-level functionality with little or no relocation of existing code. | Standard review: all six angles apply. |

If unsure, lean toward REFACTOR. The cost of missing a logic bug in a refactor is small (the bug existed pre-PR or was forced by the move); the cost of dumping six logic findings on a refactor PR is real damage to the reviewer's relationship with the author.

**Worked example (the one this skill is calibrated against).** PR description: "Containerizes the baton-panda-doc connector ... Migrated to ConnectorBuilderV2 / ResourceSyncerV2 ... Replaced in-memory user cache with session store ... Added workspace session cache: workspaces are written to the session store page-by-page during the List phase." Diff: 11 files, ~573 lines, all SDK signature migrations + relocation of `cacheUsers` (deleted) into `getUsersFromSession`/`fetchAllUsers` (added) + relocation of `roleBuilder.GetWorkspaces` (deleted) into `getWorkspacesFromSession`/`fetchAllWorkspaces` (added) + new metadata config options. **Classification: REFACTOR.** Wrong-classification findings that should NOT have been raised: "session-store errors lack connector prefix" (the pre-PR `cacheUsers` had the same bareness), "removing usersMtx introduces a double-drain race" (the mutex was removed BECAUSE of the lambda compatibility requirement that drives the entire refactor; the race is a consequence of the forced move, not a logic bug to fix on this PR), "per-page cache writes + non-empty short-circuit could expose partial cache" (this is the implementation of the move itself). Correct findings: orphan `ValidateConfig` left behind after its only caller was deleted (move debris).

In REFACTOR mode, the finding bar is: "would this break, or has this already broken, something that worked pre-PR?" If the answer is no, drop it.

## Step 2. Decide the agent count and effort per agent

**The coordinator (you) picks both COUNT (1-12) and EFFORT (low/medium/high) per PR based on actual scope, importance, and complexity.** PRs in the same batch CAN get different counts and effort tiers — size each one independently. State the chosen count, the chosen effort, and a one-sentence rationale in chat before fanning out ("PR #123: 4 agents, medium effort — touches user provisioning across 3 files, no new external API.").

**User override wins unconditionally.** If `count=<N>` or a leading integer was in the args, use that count (clamped to `1..12`) for every PR in the batch; you still pick the effort tier per PR.

### Sizing matrix

| Indicators                                                                                                              | Count | Effort  |
| ---                                                                                                                     | ----- | ------- |
| Doc-only / typo / single-literal change; no behavior change; <20 LOC; one file                                          | 1     | low     |
| Single bug fix, one concern, ≤50 LOC, ≤2 files                                                                          | 2     | low     |
| Small feature or refactor, ≤200 LOC, ≤4 files, no new external API                                                      | 3-4   | medium  |
| Medium feature, multiple files, one new resource / endpoint, or non-trivial control flow                                | 5-6   | medium  |
| Large feature, new external API surface, new auth/scope/permission, schema change, public-ID stability impact           | 7-9   | high    |
| Security-sensitive (auth, secrets, multi-tenant data path), data-loss risky, breaking change, large refactor (>500 LOC) | 10-12 | high    |

Tie-breakers — bump count UP one tier when any of:
- The PR touches the auth or session-establishment path.
- The PR changes a public ID format, schema field, or capability flag.
- The PR adds a new external API call (the API-surface verifier alone isn't enough; widen the lens).
- The PR description references a customer incident or production regression.

Bump DOWN one tier when:
- The PR is generated by a known auto-bot (dependabot, an auto-bump workflow) AND only touches lockfiles / versions / vendor.
- The PR is an explicit revert of a recent merge (you only need to confirm the revert is clean).

### What "effort" controls

The effort tier modifies each subagent's prompt and tool budget. Pass `effort: <low|medium|high>` into every subagent prompt so the agent knows the budget.

- **low** — anchor-and-skim. Read the diff. Read the function the `+` lines live in. No external doc fetches. No vendored-code trace. Word cap 250. Aim for under 60 seconds wall-clock.
- **medium** — anchor + trace. Read the diff. Read every caller and callee of changed functions one level out. Fetch one or two external docs ONLY when the agent's lens requires it (e.g. API surface). Word cap 500. Aim for 1-3 minutes wall-clock.
- **high** — anchor + trace + verify. Read the diff. Trace the runtime path through changed code into vendored / SDK code. Fetch all relevant vendor doc pages for every new endpoint. Read related test files to understand the spec the PR claims to meet. Word cap 700. Aim for 3-6 minutes wall-clock.

### Angle selection at low counts

When count drops below the standing six, keep this irreducible floor (in order of importance, drop from the bottom):

1. **Code correctness** (always)
2. **API surface** (when external API is touched, otherwise drop)
3. **Error handling**
4. **Pagination & control flow**
5. **Data model & contracts**
6. **Tests & regression risk**

Concrete picks:
- count=1 → angle 1 only
- count=2 → angle 1 + angle 2 if API surface touched, else angle 1 + 3
- count=3 → 1, then 2 if API surface else 3, plus 4 if list/iterator code touched else 5
- count=4-6 → fill from the list top-down, skipping irrelevant lenses (e.g. skip pagination on a PR that touches no list code)

### Extended angles at high counts

When count is 7-12, keep all six standing angles, add the API verifier (Agent 7) if external API is touched, then extend with these in the order documented (skip the next once N is reached):

8. **Memory & performance under load** — page-size caps, per-resource sort cost, peak heap on large datasets.
9. **Concurrency & thread-safety** — concurrent calls, mutable cache state, goroutine/thread spawn paths.
10. **Backwards compatibility & migration risk** — public-ID / schema / capability stability, behavior change for existing callers or customers.
11. **Security & CI** — secret exposure, CI gate regressions, workflow secret references, dependency injection of trust.
12. **Data integrity & index/key correctness** — map-key collision risk, cross-type ID conflation, validation-invariant dependence.

(These five are NOT mutually exclusive with the standing six; pick the next-most-relevant one if the PR touches the area.)

## Step 3. Spawn N parallel review agents (per PR, all PRs in one message)

Launch every agent for every PR in a SINGLE message (parallel Agent tool calls), `run_in_background: true`. For two PRs at count=9, that's 18 agents in one batch. The runtime handles them concurrently.

Each prompt MUST include this hard constraint verbatim:

> **HARD CONSTRAINT:** only flag issues anchored to a `+` line in `/tmp/pr-<N>.diff`. Every finding MUST cite a `+` line. Skip concerns about unchanged code, even if PR behavior depends on it. Report `file:post-image-line` and the one-line excerpt of the `+` line so the user can verify it lives in the diff.

Each prompt MUST include this hard constraint verbatim:

> **HARD CONSTRAINT — moves and refactors:** if a `+` line is part of code that was relocated, extracted, renamed, or migrated (file move, function extraction, helper lift, V1→V2 signature migration, package rename, type rename) and the behavior on that line is unchanged versus the pre-PR code, do NOT flag the underlying behavior as a finding. The PR's contribution is the move itself; the pre-existing code's properties are out of scope for THIS review. To determine "pre-existing behavior," cross-reference the `-` lines in the same diff hunk OR read the file's previous version on the base branch (e.g. `git show origin/<base>:<path>`). Flag ONLY: (a) bugs introduced BY the move (wrong target, missing case, signature drift, lost annotation, broken control flow), (b) genuinely new logic added during the move (not just rephrased), (c) the move itself being wrong (e.g. wrong package, wrong abstraction). Pre-existing patterns the move preserves — client-side pagination drains that already existed, bare-error returns that already existed, missing tests that already existed, comments / naming / style that already existed — are cleanup follow-ups, NOT review findings for this PR. If the pre-existing pattern is severe enough to mention, frame it as a separate follow-up suggestion outside the per-finding loop, not as a comment to post on this PR.

Each prompt MUST include this verification preamble verbatim:

> **VERIFICATION RULE:** every claim you make about runtime behavior, framework / SDK behavior, vendor API, or rule violation will be re-checked by a different subagent. Do NOT assert behavior you have not directly traced in the code or read in the spec. If you are uncertain, say so explicitly with a confidence percentage (0-100%) on the finding. Confidence below 60% should not be a finding. It's a question; reword as "verify this against X" rather than asserting the bug.
>
> **In-code comments claiming a runtime lacks a capability** ("this runtime has no X", "X isn't available", "the interpreter doesn't expose Y") are snapshots, not facts. When such a comment justifies a design choice on the PR (e.g. "we use Math.random because goja has no Web Crypto"), feature-detect (`typeof X === "function"` probe or upstream API grep) before treating the comment as evidence. If the capability is actually present, that's a MAJOR finding — the design choice is defending against a constraint that no longer exists.

Each prompt MUST include the CONTEXT_PACK from Step 0a, either inline at the top (preferred for short packs) or as a path to `/tmp/pr-review-context-pack.md` with the instruction "read this file first." Subagents are NOT expected to walk the CLAUDE.md tree themselves; the main skill already did that.

Each prompt MUST include the three existing-comments JSON paths (`/tmp/pr-<N>.existing-comments.json`, `/tmp/pr-<N>.existing-issue-comments.json`, and `/tmp/pr-<N>.existing-reviews.json`) plus the operator's GitHub login (`OPERATOR_LOGIN=<login>` from Step 0a). Include this instruction verbatim:

> **EXISTING DISCUSSION ON THIS PR.** Three sources to scan before reporting a finding:
> 1. Inline review comments at `/tmp/pr-<N>.existing-comments.json` (parents + replies).
> 2. Issue-style comments at `/tmp/pr-<N>.existing-issue-comments.json`.
> 3. Review-summary bodies at `/tmp/pr-<N>.existing-reviews.json` (the "Request changes" / "Comment" paragraph).
>
> Each entry has `user` (GitHub login) and `body`. If your finding overlaps with an existing entry where `user != "<OPERATOR_LOGIN>"`, that's a different-user overlap and the coordinator will drop it at Step 5; you can skip the finding to save effort. If your finding overlaps with an entry where `user == "<OPERATOR_LOGIN>"`, still surface the finding (the coordinator decides at Step 5 whether to DROP it or upgrade it to INSIST). When unsure whether two phrasings describe the same issue, surface yours and let the coordinator dedup.

If `PRIOR_REVIEW_SUMMARY` from Step 1b is non-empty, each prompt MUST also include the following block verbatim:

> **PRIOR REVIEWS:** this PR has been reviewed before. The summary of every prior pass is below (each entry has a date, the HEAD SHA at the time, posted findings, and findings filtered as FALSE). Use it to:
> 1. **Skip lines already posted** as comments in a previous round. Don't re-flag the same `file:line` unless the code at that line has actually changed since `LAST_REVIEWED_SHA`.
> 2. **Do not re-litigate FALSE findings.** If a claim was filtered as FALSE in a prior round and the underlying code is unchanged, do not surface it again.
> 3. **Check whether previously-flagged issues are addressed.** If a prior BLOCKER or MAJOR has been fixed, ignore it. If it has NOT been fixed and the line still appears in `/tmp/pr-<N>.diff`, flag it again with a note that it was previously flagged.
> 4. **Prioritize new ground.** `/tmp/pr-<N>.new-since-last.diff` contains only the lines that changed since `LAST_REVIEWED_SHA`. Spend most of your effort there. The full diff at `/tmp/pr-<N>.diff` is still authoritative for the anchor-rule (every finding must cite a `+` line in the full diff), but the new-since-last diff is where you should look first.
>
> Prior review summary:
>
> ```
> <PRIOR_REVIEW_SUMMARY contents>
> ```

If `PRIOR_REVIEW_SUMMARY` is empty (first review on this PR), omit the block entirely.

**The PR_SHAPE classification from Step 1c MUST be included verbatim in every agent prompt.** Use this block:

> **PR_SHAPE:** `<REFACTOR | MIXED | FEATURE>` — `<one-sentence rationale from Step 1c>`.
>
> If `REFACTOR`: your job is to review the MOVE, not the moved code. Acceptable findings: dropped behavior, missed call-site, wrong target package/abstraction, orphaned code/dead helpers/imports left behind, signature drift that breaks a downstream caller, lost annotation / pagination token / error path during the migration. UNACCEPTABLE findings (drop without surfacing, do NOT spend effort on these): error-wrapping style of the moved code, concurrency model of the moved code, cache write granularity, retry semantics, log-level choice, comment style. Those are properties of the move's design that the author committed to when picking the target shape; this PR is not the place to renegotiate them. The bar for a REFACTOR-mode finding is "does this break, or has this already broken, something that worked pre-PR?" If no, drop it.
>
> If `MIXED`: treat each `+` line as either MOVE or NEW. For MOVE lines (anything whose pre-PR equivalent existed in a deleted file / function / V1 signature), apply REFACTOR rules. For NEW lines (net-new functions, resource types, endpoints, fields that have no pre-PR equivalent), apply FEATURE rules. When in doubt for a given line, prefer REFACTOR.
>
> If `FEATURE`: all six angles apply normally.

The six standing angles (specialize each prompt around the PR's actual content, but the lens stays constant):

1. **Code correctness** — bug-fix logic, off-by-one, nil/None deref, type-mismatch in added lines. Does each claimed fix actually do what the description says?
2. **API surface** — verify new endpoints, JSON / response fields, and protocol-level shapes against the vendor's OpenAPI / Postman / official docs. Flag UNBACKED claims. Use WebFetch / WebSearch.
3. **Error handling** — swallowed errors, lost root causes, wrong error types or codes for the path, ambiguous return shapes. Whether the project requires specific wrapping / error codes / connector-prefix conventions comes from the loaded CLAUDE.md / lazy-rule context, not from this skill.
4. **Pagination & control flow** — does new list / iterator / streaming code page correctly? Off-by-one. Duplicate emission across pages. Infinite-loop or unbounded-buffer risk. Cursor / token / offset shape matches the upstream contract.
5. **Data model & contracts** — does the new code's data shape match its downstream consumers? ID stability, parent/child invariants, expandable/foreign-key targets that actually exist, type/trait correctness, schema or annotation drift between producer and consumer.
6. **Tests & regression risk** — does the PR add coverage for the changed behavior? Run the project's standard `build` and `lint` commands and report failures. Backwards-compat of any public identifier or schema field that downstream callers might depend on.

Severity tiers across all six: **BLOCKER / MAJOR / MINOR**.

Each finding now also carries an **agent-side confidence percentage (0-100%)**. The agent reports its own initial estimate; the verification step in Step 4 either confirms (✓) or revises it. The output shape per finding is:

```
{
  "agent": "<angle name>",
  "severity": "BLOCKER|MAJOR|MINOR",
  "confidence_pct": 0-100,
  "file": "path/to/file.go",
  "line": 67,
  "excerpt": "<the + line>",
  "claim": "<one-sentence assertion about behavior or rule>",
  "consequence": "<user-visible effect if claim is true>",
  "fix": "<concrete change>",
  "verifiable_by": "<file or doc URL or function the verifier should consult>"
}
```

**Do NOT flag the operator's personal style preferences.** The CONTEXT_PACK may include the operator's writing style rules (em-dash bans, comment policy, log-level preferences, naming conventions, vocabulary lists). Those are personal-config preferences, not PR-review concerns for someone else's PR. Drop entirely:
- Punctuation preferences (em-dashes, double-hyphens, semicolons in prose).
- Log-level preferences (e.g. Warn vs Debug).
- Comment style preferences: presence of any comment, comment placement, multi-line docstrings, narrative comments.
- String-literal style preferences (lowercase, no trailing periods, etc.).
- Variable casing / abbreviation preferences inherited from the operator's CLAUDE.md.

**Do NOT flag the operator's personal git / PR / commit conventions.** These are operator-local guidelines about the operator's OWN work, not team rules every author has signed up for. Even when they appear in the loaded CLAUDE.md / lazy-rule files (because those configure the operator's behavior), do NOT enforce them on someone else's PR. Drop entirely:
- Claude / AI / automation attribution in PR descriptions, commit messages, or branch names (`🤖 Generated with Claude Code`, `Co-Authored-By: Claude`, etc.). Operator-local rule about what THEY emit, not a team rule binding the PR author.
- PR description format conventions: length caps, no `## Summary` / `## Test plan` section headers, no function names in bullets, "audience is upper management" framing. Operator-local PR-writing guidance, not the PR author's standard.
- Branch naming conventions (`ticket-id + slug`, no `<username>/` prefix). Operator-local; other authors use their own conventions.
- Commit-message format conventions (lowercase imperative, one line, no body).
- PR title prefix conventions when the author isn't bound by the same ticket system (`CXH-XXX:` for the operator's tickets does NOT apply to a different team's PR).

Rule of thumb: if the only reason something is "wrong" is because a CLAUDE.md / lazy-rule file telling the operator how to write THEIR commits and PRs says so, it's NOT a finding on someone else's PR. The PR author writes by THEIR conventions, not the operator's. **Past mistake:** flagged a Claude-attribution line in another author's PR body, a `Co-Authored-By: Claude` trailer in another author's commit, and an unusual branch name as MAJOR/MINOR findings. All three were operator-local rules; the operator rejected every comment and told the skill to stop catching these.

If the PR author also happens to follow these rules, that's fine; they'll see them in CI or their own review. The agent's job is to catch correctness, API, data-model, control-flow, and test issues. NOT to enforce the operator's writing or git-hygiene rules on someone else.

What you DO flag stays the same: correctness bugs, missing/wrong error types where the PROJECT (not the operator's personal config) requires them, wrong endpoints, JSON-tag mismatches, pagination shape mismatches, actually-swallowed errors, data-model issues, missing tests on changed behavior.

**Severity calibration — these are NOT blockers:**
- A naming-only nit (variable name, constant-vs-literal). MINOR.
- A doc-link URL pointing at a stale family when the spec still resolves. MINOR.
- A non-stylistic readability concern (e.g. an extracted helper would make a 50-line function clearer). MINOR.

**Severity calibration — these are NOT findings (DROP entirely):**
- Pre-existing patterns the PR's move/refactor preserves (drains that already drained, bare-error returns that already lacked codes, missing tests that were already missing, comments / naming / style that already existed in the previous shape). The PR moved them; it didn't introduce them. If you find yourself writing "this preserves a pre-existing pattern, but..." — stop, don't surface it. Cleanup belongs to a follow-up PR scoped to the cleanup.
- Findings whose only consequence is "this could have been fixed during the move." The PR's contract is the move, not a cleanup. The maintainer didn't sign up for an audit of every line the diff touches incidentally.

BLOCKER is reserved for: panics, data loss, wrong authentication, broken core semantics, a wrong vendor URL / method that produces 404 at runtime, a serialization mismatch that silently drops data. If you cannot describe the user-visible failure in one sentence, it is not a BLOCKER.

Word caps: 500-700 each. Output shape per finding as above.

### Agent 7 (conditional): External-API doc verifier

**Spawn this agent when the diff introduces a new external API call.** Detection signals (any one is enough):

- A new endpoint constant or path literal in client/transport code (e.g. `"/v1/users/%s/roles"`).
- A new method that calls the HTTP client, constructs an outbound URL, or wraps a vendor SDK call.
- A new HTTP method constant (`POST` / `PUT` / `DELETE` / `PATCH`) on a `+` line in a client file.
- A new request-payload or response struct (with JSON / serialization tags) tied to a new endpoint.
- A new query parameter or required header on a `+` line in client code.

If NONE of those signals appear, do NOT spawn this agent. Agent 2 (API surface) already covers field-level checks on existing endpoints.

When spawned, the agent's prompt is:

> Review PR #<N> in <org>/<repo> for **external API call correctness**. The PR is checked out at <REPO_DIR> on branch pr-<N>. The diff is at /tmp/pr-<N>.diff. Read the CONTEXT_PACK before forming claims.
>
> The PR introduces one or more NEW external API calls. Your job: verify each new call against the vendor's official documentation. For every new call (`+` line in client code), confirm ALL of:
>
> 1. **URL exists** — the exact path is documented (cite the doc URL).
> 2. **HTTP method matches** — POST / GET / PUT / DELETE / PATCH per the spec.
> 3. **Path params** — name, position, type match the spec.
> 4. **Query params** — every query key is documented; required ones are present.
> 5. **Request payload** — serialization tags on the request struct match the spec (field names, types, required vs optional).
> 6. **Response shape** — serialization tags on the response struct match the spec.
> 7. **Auth / headers** — required auth scheme and any vendor-specific headers (e.g. `Idempotency-Key`, `X-Tenant-Id`) are present.
> 8. **Pagination contract** — if the endpoint paginates, the cursor / `has_more` / `after` / offset shape matches what the new code reads.
>
> Use WebFetch / WebSearch against the official vendor docs and OpenAPI / Postman spec. Do NOT pattern-match from REST conventions or sibling projects; cite the actual spec for every claim.
>
> **HARD CONSTRAINT + VERIFICATION RULE** (same as the other agents): every finding must anchor to a `+` line in `/tmp/pr-<N>.diff`, must include a confidence percentage, and will be re-checked by a separate verifier subagent. Report `file:line` + `+` excerpt + 1-3 sentence issue + concrete fix + the doc URL that proves your claim. Severity: BLOCKER (URL / method / required-field wrong, doesn't exist) / MAJOR (optional-field mismatch, header missing, payload shape drift) / MINOR (naming nit, missing-but-unused field). Under 600 words.

This agent's output merges into the consolidated punch-list at Step 5 just like the others.

## Step 4. Verification round (parallel, ≥1 different subagent per finding)

Once all review agents return, **spawn at least one verification agent per finding** in a single message, parallel, `run_in_background: true`. Every verifier MUST be a DIFFERENT `Agent` invocation than the reviewer that produced the finding (don't reuse the same agentId; the system already routes new Agent calls to fresh contexts).

### Verifier count scales with importance

Don't use a single verifier for every finding. The coordinator picks the count per finding based on severity and the agent's reported confidence:

| Original finding                                  | Verifiers to spawn |
| ------------------------------------------------- | ------------------ |
| BLOCKER, any confidence                           | **3 verifiers** (consensus check)   |
| MAJOR with agent confidence ≥ 80%                 | **2 verifiers**                     |
| MAJOR with agent confidence 60-79%                | **1 verifier**                      |
| MINOR, any confidence                             | **1 verifier**                      |
| Any finding that makes a CLAUDE.md-rule claim     | **+1 extra** (one verifier reads the rule file independently) |
| Any finding citing vendor API behavior            | **+1 extra** (one verifier fetches the doc independently)     |

The "+1 extra" stacks on top of the base count, so a BLOCKER that asserts framework retry behavior gets 3 base + 1 source-reader = 4 verifiers; a MAJOR that asserts an OpenAPI shape gets 2 base + 1 doc-fetcher = 3.

Fire all verifiers across all findings in ONE message. A PR with 5 findings (1 BLOCKER, 2 MAJOR-high, 2 MINOR) plus one CLAUDE-rule claim and one vendor-API claim → 3 + 2+2 + 1+1 + 1 + 1 = 11 verifiers in parallel.

### Aggregating multi-verifier results

When multiple verifiers cover one finding, aggregate by majority + confidence:

- **All verifiers VERIFIED** → final confidence = mean of verifier confidences, marker = `✓<N>` (N = total verifiers, ALL agreeing).
- **Majority VERIFIED, minority NUANCED** → final confidence = mean of VERIFIED verifiers, marker = `✓<K>/<N>` (K = VERIFIED count, N = total verifiers); body must mention the nuance from the dissenting verifier.
- **Split (50/50 VERIFIED vs FALSE/NUANCED<60%)** → DROP the finding; log the disagreement in `/tmp/pr-<N>-verification.md` so the operator can review.
- **Majority FALSE** → DROP the finding.
- **All FALSE** → DROP the finding without ambiguity.

For a single-verifier finding (MINOR or MAJOR<80%), the rules from the previous spec apply unchanged: VERIFIED keeps it (marker = `✓1`), FALSE drops it, NUANCED ≥60% keeps it (marker = `✓1` with nuance in body), NUANCED <60% drops.

**Marker shape recap:** the operator should be able to glance at the marker and know how many independent subagents looked at the claim and how many agreed.
- `✓1` — one verifier, agreed.
- `✓3` — three verifiers, all three agreed.
- `✓2/3` — three verifiers, two agreed (one NUANCED dissent retained in body).

### Verification mode requirements (BLOCKER / MAJOR)

Every BLOCKER and every MAJOR verifier MUST report which **mode** it used to verify. The mode is part of the verifier's response and feeds into the final finding marker.

The four modes:

- **docs** — fetched the relevant vendor / framework / spec doc URL via WebFetch (or `mcp__context7__query-docs` for library docs) and cited the section that proves or refutes the claim. Required for any claim about vendor API behavior, OpenAPI / Postman shapes, scopes, or third-party library semantics.
- **repro** — reproduced the issue locally on the checked-out PR branch at `$REPO_DIR` (already on `pr-<N>` from Step 0b). The verifier runs the relevant build/test/command and reports the actual outcome. For Go: `go build ./...`, `go vet ./...`, targeted `go test ./pkg/...`, or running the connector against a mock. For JS/TS: `npm test`, `tsc --noEmit`, or running the script. For shell: actually invoking it. Required for any behavioral claim that is testable in <2 minutes on the operator's machine; optional for slower paths.
- **trace** — traced the actual runtime path through source code. Cite the file:line chain (e.g. `pkg/foo/bar.go:42 → vendor/x/y.go:117 → vendor/x/z.go:80`). Required for any claim about framework / SDK / vendored-dependency behavior.
- **obvious** — the finding is self-evident from the diff alone: type mismatch you can see in the `+` line, missing nil check on a return value the very next line dereferences, off-by-one in a literal range, etc. Using `obvious` is allowed but the verifier MUST include a one-sentence justification ("obvious: `+ if user.Name {` dereferences a nil-able pointer field with no guard on the line above"). Without that justification the finding is downgraded to MINOR. Vague justifications ("it's clear from context") do NOT qualify; the sentence must point at the specific construct that makes verification unnecessary.

Per-severity mode requirements:

| Severity                                                            | Allowed modes                       | Notes                                                                                                  |
| ------------------------------------------------------------------- | ----------------------------------- | ------------------------------------------------------------------------------------------------------ |
| BLOCKER, claim about vendor API behavior                            | docs (REQUIRED) + one of trace/repro for additional confirmation | Two distinct verifiers, each using its own mode.                                                       |
| BLOCKER, claim about framework / SDK / vendored-dep behavior        | trace (REQUIRED) + optionally repro | Reading the actual vendored source is non-negotiable.                                                  |
| BLOCKER, behavioral claim runnable in <2 min                        | repro (REQUIRED) + optionally trace | If the claim is "this build fails" or "this panics", actually run it.                                  |
| BLOCKER, claim self-evident from diff                               | obvious (with justification)        | Verifier must say WHY no extra verification was needed. Skipping the justification downgrades the row. |
| MAJOR                                                               | any one of docs / repro / trace / obvious | Pick the cheapest mode that proves the claim. `obvious` still requires the one-sentence justification. |
| MINOR                                                               | any mode, or no verification beyond reading the diff (existing rules) | No mode-justification requirement for MINORs.                                                          |

The verifier prompt now ends with a structured-output requirement (see below). The mode is part of every BLOCKER/MAJOR verifier response so the operator can see — per finding — what kind of evidence was gathered.

Each verifier prompt:

> You are independently fact-checking ONE claim from a multi-angle PR review. You did not produce this claim. Your only job is to confirm or refute it.
>
> **Claim:** <agent's claim verbatim>
> **Anchored at:** <file>:<line> in PR #<N> at <REPO_DIR>, diff /tmp/pr-<N>.diff
> **Excerpt:** <the + line the original agent cited>
> **Claimed consequence:** <agent's stated consequence>
> **Verifiable by:** <agent's `verifiable_by` field>
> **Initial agent confidence:** <agent_confidence_pct>%
> **Severity:** <BLOCKER|MAJOR|MINOR>
>
> Verify by reading source code, vendored / dependency code, fetching external docs (WebFetch / context7), or reproducing locally on the checked-out PR branch at `$REPO_DIR`. Trace the actual runtime path or read the actual spec. Do NOT take the claim at face value.
>
> **For BLOCKER and MAJOR claims, pick a verification MODE from {docs, repro, trace, obvious} and report it explicitly in your response.** Constraints:
> - vendor API behavior claim → `docs` is REQUIRED.
> - framework / SDK / vendored-dep behavior claim → `trace` is REQUIRED.
> - behavioral claim runnable in <2 min on the checked-out branch → `repro` is REQUIRED (run it; don't speculate).
> - any other claim → pick the cheapest mode that actually proves the point.
> - `obvious` is allowed when the claim is self-evident from the `+` line itself; you MUST include a one-sentence justification naming the specific construct that makes verification unnecessary. Without that sentence the verdict is downgraded.
>
> For MINOR, you may skip the mode and just verify by reading.
>
> If the claim references a CLAUDE.md / project-rule, check the loaded CONTEXT_PACK; do not invent the rule.
>
> Return one of:
> - **VERIFIED** + revised confidence (0-100%) + 1-2 sentences citing the evidence + `mode: <docs|repro|trace|obvious>` + `evidence: <doc URL | file:line chain | command + outcome | one-sentence justification>`
> - **FALSE** + 1-2 sentences explaining why the claim does not hold (with citation) + `mode: <…>` + `evidence: <…>`
> - **NUANCED** + revised confidence + 1-2 sentences explaining the gap (e.g. "claim is true only when X; PR is in the X=false case") + `mode: <…>` + `evidence: <…>`
>
> Word cap: 250 words.

The verifier output sets the FINAL confidence percentage and the ✓ marker:
- **VERIFIED** → final confidence = verifier's revised confidence, ✓ marker present.
- **NUANCED** with confidence ≥ 60% → keep as a finding with verifier's confidence, ✓ marker present but the body must include the nuance.
- **NUANCED** with confidence < 60% → drop the finding entirely. It's a question, not a bug.
- **FALSE** → drop the finding entirely. Do NOT surface it to the operator. Add a one-liner to the verification log so the operator can see what was filtered.

The verification log lives at `/tmp/pr-<N>-verification.md` and is preserved for audit:

```
## Verification log for PR #<N>

| Original Agent | Claim (short) | Verdict | Final Conf | Reason |
| -------------- | ------------- | ------- | ---------- | ------ |
| correctness    | un-coded error skips framework retry | FALSE | n/a | framework retry.go:60 only retries codes A+B |
| api-surface    | endpoint X is v2-only                | VERIFIED | 88% | vendor docs confirm; PR docs.mdx also states |
```

This log is NOT shown to the operator inline (it'd be noise); only summarized in the final wrap.

## Step 5. Consolidate

Now build the punch-list from surviving (VERIFIED + qualifying NUANCED) findings. For each:

- `severity` (BLOCKER / MAJOR / MINOR)
- `confidence_pct` (final, from verifier)
- `verified` (always `true` here, since FALSE / <60% NUANCED were dropped. The ✓ goes on every surfaced finding by construction.)
- `file`
- `line` (post-image, must correspond to a `+` line in the diff)
- `body` (the comment as it will be posted. See "Comment phrasing" below.)

Dedupe overlapping findings across review agents on the same PR: two agents flagging the same line collapse to one row. Keep the higher severity and the higher final confidence. Use `references/examples.md` for examples of merged vs split findings.

**Author-aware overlap tagging** against `/tmp/pr-<N>.existing-comments.json`, `/tmp/pr-<N>.existing-issue-comments.json`, and `/tmp/pr-<N>.existing-reviews.json` from Step 1. For EVERY consolidated finding, scan all three sources — **including bot comments (Copilot, coderabbit, sourcery, greptile, DeepSource, sonarcloud, and any `*[bot]` login)** — for an entry that already raises the same concern. This is a HARD requirement: never surface a finding without running this check first, and never re-raise an issue a human developer or bot already flagged on this PR.

Matching rules (a finding overlaps if ANY of these are true against an existing entry):
- **Same `file:line`** where the existing entry is an inline comment on the exact anchor line the finding targets.
- **Same hunk** where the existing entry is an inline comment on a nearby line within the same continuous diff hunk (±5 lines from the finding's anchor).
- **Same conceptual issue** where the existing entry (inline OR issue-comment OR review body) describes the same problem in different words on the same file. Match on: normalized keywords from the finding headline vs. the existing body, symbol / identifier / API name overlap (e.g. both mention `ListUsers` on `pkg/client/users.go`), or the same vendor-doc URL cited by both. When in doubt, treat it as a match — a false-dup tag is cheap; a re-raised comment is not.

Bots emit canonical wording; make the semantic match generous for them. Coderabbit's "Add error handling for the ignored return value" and a review-agent's "This return err is dropped" are the same finding.

**CRITICAL: never silently drop a finding at consolidation.** Every consolidated finding surfaces into the Step 6b Hunk batch and the Step 6a table. Overlap information is a TAG on the finding (surfacing to the operator so they can decide), NOT a pre-filter that hides the finding from Hunk. The operator makes the drop decision at Step 8, not the skill.

Tag each finding as follows:

1. **Overlap with a bot** (`entry.user` matches `*[bot]` OR is one of the known bot logins listed above): tag `overlap=external-bot`, add a one-line note to the finding body ("already flagged by <bot-login> at <permalink>"), and set the default action in Step 8 to **skip**. Bot findings are almost always already visible to the PR author; re-posting them just adds noise. The operator can override per-finding in Step 8 if the bot's phrasing was weak.
2. **Overlap with a different HUMAN user's entry** (`entry.user != OPERATOR_LOGIN` AND not a bot): tag `overlap=external-human`, add a one-line note to the finding body ("also noted by <user> at <permalink>"), and lower the default action from post to skip in Step 8. Do NOT drop — the operator sees it in Hunk with the DUP-EXTERNAL-HUMAN summary prefix and picks per-finding whether to +1 the existing thread or skip.
3. **Overlap with the operator's own entry** (`entry.user == OPERATOR_LOGIN`):
   - Inspect the thread. For inline comments, "thread has replies" = `any other entry in existing-comments.json has in_reply_to_id == entry.id`. For issue-comments and review summaries, "thread has engagement" = there's a later issue-comment from any user other than the operator OR a later review submission.
   - **Thread has replies / engagement** → tag `overlap=self-engaged`. Lower default action to skip. Body note: "you already said this on <permalink>; thread moved on."
   - **Thread is silent** (no replies, no engagement) → tag `overlap=self-silent`, mark `insist=true`. Body leads with `(reiterating my earlier note since the line hasn't changed)`.
4. **No overlap** → tag `overlap=none` (implicit), fresh finding.

Every tagged finding still lands in Hunk via Step 6b so the operator sees the full picture and decides in Step 8. Two phrasings that might describe the same issue: keep both, tag the newer one `overlap=maybe-dup` with a body note pointing at the possible dup. False drops are worse than minor duplication; the operator will skip the redundant ones during the ask loop.

**Report the check ran.** The Step 6a table's header line MUST include a "dedup checked against N existing entries (H human, B bot)" note so the operator can see the check happened. If any of the three JSON files was empty (Step 1 returned no comments/reviews), print "no existing comments to dedup against" instead so it's obvious no coverage was possible.

### Comment phrasing

Comments are inline review notes, not essays. Match the operator's existing style on the repo (informal, lowercase, no em-dashes, no emojis).

- **1-3 sentences max.** State the issue, then the fix.
- **No re-quoting the code.** GitHub already shows the line.
- **Reference other files by `file:line`** when the issue spans more than the anchor line.
- **Forbidden punctuation:** em-dash `—` and double-hyphen `--`.
- **NEVER reference the operator's personal config or rules.** No "CLAUDE.md says", no "project rule says", no "the rules in ~/CLAUDE.md", no quoting of personal style configs. The PR author does not know the operator's CLAUDE.md; they should not need to. State the bug directly: what's wrong + the fix. If the only reason something is wrong is that the operator's config disallows it, the finding probably shouldn't be a comment at all, or post it as a low-severity nit phrased as a preference, not a rule citation.
- **NEVER reference internal docs paths** like `~/CLAUDE.md` or `.claude/lazy/*.md` inside a comment body. The PR author can't read those files.
- **Don't appeal to authority.** "this violates X" is weaker than "this drops the email key on unmarshal, so Message() loses the most useful field". Show the consequence; let the consequence carry the argument.
- **DO cite official vendor docs when the finding was verified against them.** Format: bare URL at the end of the comment, no `[label](url)` markdown. Single link: `(spec: https://docs.vendor.com/reference/foo)`. Multiple: `(spec: https://docs.vendor.com/reference/foo, https://docs.vendor.com/reference/bar)`. The PR author should be able to confirm the claim by clicking the link. Applies ONLY to claims actually verified, never invent a URL to make the comment look authoritative.

Examples in `references/examples.md`.

## Step 5a. Compute "approve PR" confidence

After the punch-list is final (deduped per Step 5), compute a single 0-100% number per PR so the operator can tell at a glance whether it's safe to approve. The number IS opinionated: it weighs both severity and how much scrutiny each finding got.

Formula. Start at 100 and deduct per surviving finding:

```
approve_pct = 100

for each finding in surviving_punch_list:
  if finding.severity == "BLOCKER":
    approve_pct -= 50              # one BLOCKER drops you under the "approve" line
  elif finding.severity == "MAJOR":
    if finding.final_confidence >= 80: approve_pct -= 15
    else:                              approve_pct -= 7
  elif finding.severity == "MINOR":
    if finding.final_confidence >= 85 and finding.has_concrete_fix:
      approve_pct -= 2
    # else MINOR doesn't move the needle
  if finding.insist:
    approve_pct -= 5               # re-flagged unaddressed comment, extra weight

approve_pct = max(0, approve_pct)
```

Bucket the number into a recommendation tier and include both the number and the tier in the report and the wrap:

| approve_pct | Tier                         | What it means                                                                                  |
| ----------- | ---------------------------- | ---------------------------------------------------------------------------------------------- |
| 81-100      | **SAFE TO APPROVE**          | Zero BLOCKERs, at most a couple of low-conf MAJORs / MINORs. The PR can land.                  |
| 61-80       | **APPROVE WITH NOTES**       | MAJORs present but advisory. Author should glance at the comments; nothing blocks merge.       |
| 31-60       | **APPROVE WITH CAUTION**     | Multiple MAJORs or one high-conf BLOCKER bordering. Address the listed items before merge.     |
| 0-30        | **DO NOT APPROVE YET**       | BLOCKER(s) outstanding. Material issues to resolve first.                                      |

Floor and ceiling rules:
- ANY BLOCKER caps the tier at "APPROVE WITH CAUTION" or lower (a single 50%-confidence BLOCKER is still a BLOCKER; never silently downgrade because the math floats).
- An empty punch-list (zero surviving findings) is always `approve_pct = 100`, tier "SAFE TO APPROVE".
- If `OPERATOR_LOGIN == pr.author.login` (the operator is reviewing their own PR), drop the tier one level (you're biased; the math should reflect that).

State the number and tier in chat once it's computed so the operator sees it before Hunk opens:

```
PR #<N> — approve_pct=<P>%  →  <TIER>
  reasons: <X> BLOCKER(s), <Y> MAJOR(s), <Z> INSIST'd, <W> MINOR(s) over the bar
```

## Step 5b. Persist the consolidated report

Before opening Hunk or asking the operator anything, write the full consolidated report (all surviving findings) to a stable on-disk path so the operator can revisit it later. This ALWAYS happens, even if the operator later picks to reduce or skip all findings.

**Path:**

```
<REPO_DIR>/.inreview/<DATE>/auto-new-day:pr-code-review/pr-<N>-<slug>-full.md
```

- `<DATE>` = the resolved date (`--date` arg or today), same value used at Step 1b for `$PR_LOG`.
- `<pr-title-slug>` = sanitized PR title: lowercase, replace any non-alnum run with `-`, trim leading/trailing `-`, cap at 120 chars. Prefix with the PR number for uniqueness, suffix with `-full` to distinguish from the short per-PR log at `pr-<N>.md` (Step 5c).
- The full report lives next to the per-PR log in the same per-date archive so auto-new-day's snapshot picks BOTH up — `/auto-new-day --date X` can replay the full review verbatim.

Retired: the previous `${REVIEWS_DIR:-$HOME/.reviews}/<repo>/<DATE>/<author>/pr-<N>-<slug>.md` archive. It's been folded into the per-date in-repo archive so there's one source of truth. The `reviews` fzf util now points at `~/work/baton-*/.inreview/*/auto-new-day:pr-code-review/*.md` instead of `~/.reviews/`.

```bash
SLUG=$(jq -r '.title' "/tmp/pr-$PR_NUM.meta.json" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' \
  | cut -c1-120)
REPORT_DIR="$REPO_DIR/.inreview/$DATE/auto-new-day:pr-code-review"
mkdir -p "$REPORT_DIR"
REPORT_PATH="$REPORT_DIR/pr-$PR_NUM-$SLUG-full.md"
```

**Contents (Markdown):** the report MUST include, in order:

1. Header line: `# PR #<N>: <title>` (title verbatim from `.title` in the meta.json).
2. Metadata block listing, in this order:
   - **Approve verdict** first: `Approve: <P>% — <TIER>` (e.g. `Approve: 72% — APPROVE WITH NOTES`). The verdict is the first line so a reader scanning the archive sees it before the finding details.
   - **PR URL** (from `.html_url`).
   - **Author** (from `.author`).
   - **Created** (from `.created_at`, formatted as `YYYY-MM-DD HH:MM UTC` — trim the `T`/`Z` for readability).
   - **State** (from `.state`) + `(draft)` suffix if `.draft` is true.
   - **Base / Head SHA** (base ref + full 40-char head SHA).
   - **Agent count** + **verifier counts** (per severity tier).
   - **Run timestamp** (this review's local ISO-8601).
3. **PR description** section: a `## Description` heading followed by the PR body verbatim from `.body`. If `.body` is empty or null, write `_(no description provided)_`. Fence with `> ` block-quote prefix on every line so the description is visually distinct from this skill's own prose. This gives the reader the PR author's intent right next to the findings, so they don't have to switch to GitHub to read what the PR was for.
4. The findings table from Step 6a (verbatim, same Sev / Conf / ✓ / File:Line / Headline columns).
5. One subsection per finding with the FULL comment body, the diff excerpt, the verifier verdict(s), and the resolved confidence. BLOCKERs first, MAJORs next, MINORs last.
6. Link to the verification audit log at `/tmp/pr-<N>-verification.md` and instruction to copy it into the same persisted dir if the operator wants the FALSE-drop history retained.
7. List of agents that ran (angles) and their individual report paths (`/tmp/pr-<N>.agent<K>.md`) so the operator can dig deeper.

Write the report BEFORE opening Hunk or asking the reduce question. The operator may interrupt at any point and the on-disk artifact survives.

The `reviews` CLI util (commonly at `$SCRIPTS/shared/utilities/reviews`) fzf-picks any report under `~/work/baton-*/.inreview/*/auto-new-day:pr-code-review/*.md` (the per-date in-repo archive) by date or across all dates.

## Step 5c. Append entry to the per-PR log

Alongside the full archive at Step 5b, append a short summary to the per-PR log. The path was already resolved into `$PR_LOG` at Step 1b (using `$PR_LOG_LAYOUT` from Step 0a):
- per-repo layout: `$REPO_DIR/.inreview/$DATE/auto-new-day:pr-code-review/$PR_NUM.md`
- parent layout: `$PR_LOG_ROOT/$REPO/$PR_NUM.md`  (where `$PR_LOG_ROOT` = `<INVOKED_FROM>/.inreview/$DATE/auto-new-day:pr-code-review`)

This is the lightweight pointer that future re-reviews read at Step 1b. One entry per review run, one line per finding; full bodies live in the archive.

Call the helper script `scripts/pr-log-append.sh` (shipped with this skill) rather than inlining the markdown template here. The script handles header initialization on first call, severity counts, and append-only ordering so Step 1b's SHA grep keeps working.

First build two TSV files from the consolidated punch-list and the verification audit log:

```bash
# Findings TSV: one row per surviving finding (Step 5 punch-list, BLOCKER->MAJOR->MINOR).
# Columns: sev<TAB>conf<TAB>verified-marker<TAB>file:line<TAB>headline
findings_tsv=$(mktemp)
# ... populate from the consolidated punch-list ...

# Filtered TSV: one row per claim dropped at Step 4 (verifier FALSE / low-conf NUANCED).
# Columns: angle<TAB>claim<TAB>reason
filtered_tsv=$(mktemp)
# ... populate from /tmp/pr-$PR_NUM-verification.md ...
```

Then call the script:

```bash
SKILL_DIR="${PR_REVIEW_SKILL_DIR:-$HOME/.claude/skills/auto-new-day:pr-code-review}"
"$SKILL_DIR/scripts/pr-log-append.sh" \
  --pr-log    "$PR_LOG" \
  --pr-num    "$PR_NUM" \
  --title     "$(jq -r .title /tmp/pr-$PR_NUM.meta.json)" \
  --url       "https://github.com/$OWNER/$REPO/pull/$PR_NUM" \
  --author    "$AUTHOR" \
  --head      "$HEAD_SHA" \
  --agents    "$AGENT_COUNT" \
  --verifiers "$VERIFIER_COUNT" \
  --count     "$COUNT" \
  --effort    "$EFFORT" \
  --findings  "$findings_tsv" \
  --filtered  "$filtered_tsv" \
  --archive   "$REPORT_PATH"
```

Resulting file shape (the script writes this; here for reference so future readers know what to expect when reading the log at Step 1b):

```markdown
# PR #<N>: <title>

URL: https://github.com/<owner>/<repo>/pull/<N>
Author: <login>


## <YYYY-MM-DD> (head: <full-40-char-SHA>)
Agents: <N> review + <V> verifiers (count=<C>, effort=<E>)
Surfaced: <total> findings (<B> BLOCKER, <Mj> MAJOR, <Mn> MINOR)
Archive: <path to Step 5b report>

### Surfaced (do not re-flag the same line unless code changed)
- BLOCKER 92% ✓3 src/foo.go:42 wrong type breaks downstream consumer
- MAJOR 78% ✓2 src/bar.go:18 items emitted twice across pages
- MINOR 65% ✓1 src/baz.go:91 repeated literal could be a const

### Filtered FALSE / low-confidence (do not re-litigate)
- correctness: un-coded error skips framework retry (framework retry.go:60 only retries codes A+B)
```

Rules baked into the script:
- Header is written only on first call (the `# PR #<N>: <title>` block). Subsequent calls append a new `## <date> (head: <sha>)` section.
- The header sentinel `head: <40-char-SHA>` is the contract Step 1b reads. Do not edit it by hand.
- Multiple sections in chronological order: each re-review on the same PR adds the most recent at the bottom. Step 1b's `tail -n1` grep picks the most recent SHA from there.

Suggest the operator add `.pr/` to the repo's `.gitignore` or `.git/info/exclude`. The log is per-operator review state, not part of the project. The skill itself never commits `.pr/` and never blocks on its presence in `git status`.

## Step 6. Print findings table + open Hunk with EVERY finding attached

The operator decides what to post by scanning the full picture once: a table of every surviving finding plus an open Hunk TUI showing every comment on its diff anchor. Do NOT filter or ask anything yet — open ALL findings first, then ask in Step 7.

**Hunk opens by DEFAULT for every PR.** The only reasons to skip Hunk are the two cases enumerated in Step 6c. "Recommendation is SAFE TO APPROVE" is NOT one of them — an approve verdict still gets a Hunk pane (with existing reviewer threads attached, if any) so the operator can eyeball the diff before hitting approve. Do not silently skip Hunk because the punch-list is short; if you are skipping it, Step 6c REQUIRES you to print the one-line reason in chat.

### Step 6a. Print the findings table

Print one Markdown table per PR to the user before opening Hunk. Columns:

| # | Sev | Conf | Verified | Mode(s) | File:Line | Headline |
| - | --- | ---- | -------- | ------- | --------- | -------- |
| 1 | BLOCKER | 92% | ✓3      | docs + trace + repro | src/foo.go:42 | wrong type breaks downstream consumer |
| 2 | MAJOR   | 78% | ✓2      | docs + trace         | src/bar.go:18 | items emitted twice across pages |
| 3 | MAJOR   | 73% | ✓2/3    | trace                | src/qux.go:55 | role mapping mismatch (1 nuance) |
| 4 | BLOCKER | 95% | ✓3      | obvious              | src/baz.go:18 | nil deref on next line (no guard) |
| 5 | MINOR   | 65% | ✓1      | —                    | src/baz.go:91 | repeated literal could be a const |

Rules (canonical format spec lives in the shared hunk references — [`~/.claude/skills/report/references/format.md`](~/.claude/skills/report/references/format.md) for the finding marker + verdict/report block, and [`diff-note-format.md`](~/.claude/skills/report/references/diff-note-format.md) for the Hunk note shape; keep every surface consistent with them):
- BLOCKERs first, MAJORs next, MINORs last. Within tier, sort by confidence desc.
- The Verified column shows `✓<N>` when all N verifiers agreed, or `✓<K>/<N>` when K of N agreed (one or more NUANCED). Every surfaced row carries a marker by construction (FALSE / low-confidence-NUANCED rows were dropped at Step 4). The number tells the operator how much scrutiny the finding got.
- **Sub-80% + multi-validated → justify the ceiling.** Any finding with final confidence < 80% AND `✓2`+ (or `✓K/N`) MUST include a one-line "why not higher" in its comment body, naming the residual uncertainty the verifiers could not close. A `✓1` sub-80% finding is self-explanatory.
- Headline is the one-line lede of the comment body (under ~70 chars). Not the full body.
- `#` matches the order the ask loop will walk in Step 8.
- If a PR has zero surviving findings, print one line per PR saying so and STILL proceed to Step 6b — existing reviewer threads (`[THREAD]` entries) may still need a Hunk pane. Only after Step 6b's filter shows zero `[NEW]` AND zero eligible `[THREAD]` entries does Step 6c's "nothing to attach" clause fire.

### Step 6b. Open Hunk with EVERY finding + every existing reviewer thread

After all tables print, invoke the `report` skill in its **fast path** with EVERY consolidated finding attached AND every eligible existing reviewer thread from Step 1. **"Every consolidated finding"** = every row that survived Step 4 verification (VERIFIED or NUANCED≥60%), regardless of Step 5's overlap tags, regardless of severity, regardless of the operator's likely eventual disposition. The Hunk pane is the operator's read-out; the skill does not pre-filter it.

The mandate is explicit:

- Findings tagged `overlap=external-bot`, `overlap=external-human`, `overlap=self-engaged`, `overlap=self-silent`, `overlap=maybe-dup` — all land in the batch. The summary prefix carries the tag so the operator sees it in the TUI list.
- `[THREAD]` entries for existing reviewer threads that don't overlap a `[NEW]` finding — all land in the batch (up to the 30-thread cap below).
- Severity-downgraded rows (BLOCKER → MAJOR, MAJOR → MINOR after verifier NUANCE) — land in the batch at their final severity, not their initial one.
- MINORs — land regardless of confidence, as long as they passed Step 4.

The Step 6a table shows the SAME set of rows as the Hunk batch, in the same order. If a row is in the table but not in Hunk (or vice versa), that's a skill bug — the two views MUST be consistent. Step 7's "reduce to 1-5" is the ONLY place a survivor gets hidden, and it's operator-gated.

**Before calling Skill(report), write the full comment batch to `/tmp/pr-<N>-comments.json`** using `newLine` anchors so each comment lands on the exact `+` line it references (never on a hunk position that resolves to an unchanged context line). The batch combines two categories:

```bash
cat > /tmp/pr-<N>-comments.json <<'JSON'
{
  "comments": [
    {"filePath": "src/foo.go", "newLine": 67,
     "summary": "[NEW] BLOCKER (92% ✓3): <one-line headline>",
     "rationale": "<the full comment body from Step 5>"},
    {"filePath": "src/foo.go", "newLine": 142,
     "summary": "[THREAD] <author-login>: <one-line excerpt of their comment>",
     "rationale": "they said: \"<comment body trimmed to ~280 chars with …>\"\n\n<permalink>\n\nthread state: <unanswered-by-you | you-replied | resolved>"},
    ...
  ]
}
JSON
```

Two categories, distinguished by the `summary` prefix:

- **`[NEW] ...`** — one entry per consolidated finding (Step 5 output), in the same order as the table (BLOCKERs first, MAJORs next, MINORs last). NO filtering. Overlap-tagged findings still ship; their summary prefix carries the tag (e.g. `[NEW][DUP-EXTERNAL-HUMAN] MAJOR (78% ✓2): ...` or `[NEW][DUP-EXTERNAL-BOT] MINOR (72% ✓2): ...`).
- **`[THREAD] ...`** — one entry per existing reviewer thread from `/tmp/pr-<N>.existing-comments.json` (inline review-thread comments) + `/tmp/pr-<N>.existing-issue-comments.json` (top-level / issue-style comments) + `/tmp/pr-<N>.existing-reviews.json` (review-summary bodies with non-empty body text). Skip:
  - Threads where the LATEST message is from the operator (`author.login == OPERATOR_LOGIN`) — they already engaged.
  - Bot-authored entries (`author.type == "Bot"`, `*[bot]` login suffix, `github-actions`, `dependabot`, `renovate`, `coderabbitai`, `sonarcloud`, `codecov`).
  - Empty review summaries (the bare APPROVED/REQUEST_CHANGES with no body — there's nothing to reply to).
  - Do NOT skip on "already deduplicated against a `[NEW]` finding" — attach the thread anyway. Step 5 no longer drops overlaps; it tags them. When a thread and a `[NEW]` finding anchor to the same line, the operator sees both entries in Hunk (the finding shows the agent's take, the thread shows the reviewer's) and picks per-comment in Step 8.

  Per-thread anchor: inline comments → `filePath` + `newLine` from the comment's `line` / `original_line` (use `newLine` when the comment anchors a `+` line in the current diff; use `oldLine` for `-` lines). Issue-style comments and review summaries don't have a file anchor — represent them with `hunkNumber: 0` so they land at the top of the diff as PR-wide threads, with the summary prefix making the kind clear.

Rules for the JSON:
- `newLine` MUST match the exact `file:line` from the consolidated finding or existing thread, and that line MUST be a `+` line in `/tmp/pr-<N>.diff`. If the finding describes a range, pick the most specific anchor inside the range.
- Use `oldLine` instead only for findings about a deleted line.
- NEVER use `hunkNumber` for diff-anchored findings; only use `hunkNumber: 0` for PR-wide threads (issue-style + review summaries that have no file anchor).
- The `summary` field includes the `[NEW]` or `[THREAD]` prefix + confidence + ✓ marker (NEW only) so the operator sees status in the Hunk TUI title.
- Cap threads at 30 per PR. If more exist, attach the 30 most recent (by `created_at` desc) and surface the count in the post-table summary ("attached 30 of 47 existing threads — older ones available in the existing-*.json files").

Hunk's fast path validates every anchor before applying. If you fed it a misaligned line, the apply aborts with a `MISSING ADD <file>:<line>` message; rebuild the JSON with the correct anchor and retry.

Then invoke the report skill once per PR:

```
Skill(report, args: "comments_json=/tmp/pr-<N>-comments.json range=origin/<base>...pr-<N>")
```

Capture the apply output — it lists one `commentId` per attached comment in the form `mcp:<session>:<index>`. Save the mapping `finding_# → commentId` to `/tmp/pr-<N>-commentids.tsv` (one row per finding, columns: `<#>\t<commentId>`). Step 7 needs it to prune dropped findings out of the Hunk session.

Hunk always splits its TUI off the calling Claude's pane. For single-PR runs the operator sees Claude on the left and Hunk on the right in the same window. For multi-PR runs, the Step 0 dispatcher spawned each PR into its own per-PR tmux window, so each PR's Hunk pane splits inside that PR's window — the operator switches PRs with the standard tmux window-switch keys.

### Step 6c. Skipping Hunk

Skip Step 6b ONLY in these two enumerated cases. Every other run opens Hunk, including runs where the approve_pct verdict from Step 5a is SAFE TO APPROVE.

1. **Missing tools.** `tmux` is not running, OR the `hunk` CLI is not on `$PATH`. Print one line saying which is missing (`hunk skipped: tmux not running` or `hunk skipped: hunk CLI not found on $PATH`) and continue to Step 7.
2. **Nothing to attach.** After building the Step 6b JSON, BOTH counters are zero: zero `[NEW]` findings survived Step 5 AND zero `[THREAD]` entries survived the Step 6b filters (all threads were already-engaged, bot-authored, empty, or deduped). Print `hunk skipped: no new findings and no eligible existing threads to attach` and continue to Step 7.

If EITHER (a) the tools are available AND (b) at least one `[NEW]` or `[THREAD]` entry exists, Hunk opens. Do not gate Hunk on approve_pct, on the tier, on operator preference guessed from context, or on "this looks like an approve" — none of those are in this list.

The findings table from Step 6a still prints regardless of which branch fires.

## Step 7. Ask the operator whether to reduce findings (yes/no)

Hunk is now open with every finding attached. The operator can scan them in the TUI. Before walking the ask-then-post loop, ALWAYS ask via `AskUserQuestion`:

```
question: "<N> findings open in Hunk. Reduce to the most important + highest-confidence ones, or walk all of them?"
header:   "Reduce"
options:
  - "No, walk all <N>" (recommended when total ≤ 5)
  - "Yes, reduce" (recommended when total > 5)
```

The recommended option flips on volume: ≤5 → walk all (no reduction needed); >5 → reduce (avoids drowning the operator in low-impact MINORs).

### Step 7a. If the operator picks "Yes, reduce"

YOU (the coordinator) decide the survivor count. Pick an integer in `[1, 5]` based on the actual finding mix:

- **All BLOCKERs always survive**, up to the cap of 5.
- Fill remaining slots with MAJORs in descending confidence order.
- Fill the final slot(s) with MINORs ONLY when they have ≥ 85% confidence AND describe a concrete fix the author can apply in under 10 lines.
- If only 1 finding clears these bars, keep 1. If 5 BLOCKERs exist, keep 5.

Worked sizing:
- 1 BLOCKER + 4 MAJORs + 6 MINORs → keep 5 (BLOCKER + top 4 MAJORs by confidence).
- 0 BLOCKERs + 2 MAJORs + 8 MINORs → keep 2-3 (both MAJORs, plus 1 MINOR if it meets the high-confidence concrete-fix bar).
- 3 BLOCKERs + 0 others → keep 3 (all BLOCKERs, no padding).
- 0 BLOCKERs + 0 MAJORs + 4 MINORs all ≥ 85% → keep 1-2 (no need to surface every MINOR even if they qualify; pick the most impactful).

State the count you picked and one-sentence rationale in chat ("Reducing to 3: 1 BLOCKER + 2 MAJORs by confidence."). Do NOT ask the operator to confirm the count — you decide.

Prune the dropped findings from the Hunk session via `/tmp/pr-<N>-commentids.tsv`:

```bash
for cid in $(awk -v keep="<keep-csv>" 'BEGIN{split(keep, K, ","); for(k in K) S[K[k]]=1} !($1 in S) {print $2}' /tmp/pr-<N>-commentids.tsv); do
  hunk session comment rm "$cid" --repo "<REPO_ROOT>"
done
```

With `--repo`, `hunk session comment rm` takes exactly one positional: the `<commentId>`. The two-form signature is `<session-id> <commentId>` OR `<commentId> --repo <path>` — passing both an empty session-id and `--repo` errors with "Specify exactly one comment id with --repo".

After pruning, also drop the dropped rows from the in-memory punch-list so Step 8 only walks survivors. The dropped findings stay in the persisted report at `<REPO_DIR>/.inreview/<DATE>/auto-new-day:pr-code-review/pr-<N>-<slug>-full.md` and in the verification log at `/tmp/pr-<N>-verification.md` so the operator can recover them later.

### Step 7b. If the operator picks "No, walk all"

No pruning. Hunk stays as-is. Proceed straight to Step 8 with every finding.

## Step 8. Ask-then-post loop

**MANDATORY: delegate to the `add-comment` skill for drafting AND posting every comment in this step.** Run `Skill(add-comment)` at the top of Step 8 with all surviving findings batched as one call. Do NOT inline the ask-then-post loop with per-finding `AskUserQuestion` calls — that's the regression that produced modal-picker churn in past sessions and bypassed the tmux-pane draft file that `add-comment` opens by default.

The `add-comment` skill is the source of truth for:
- Voice (1-3 sentences, lowercase, no em-dash, no greetings, plain words)
- The `references/examples.md` corpus of approved phrasings
- When to spawn fact-check verifier subagents for a draft
- The exact `gh api ...` shape for line comments, replies, and top-level PR comments
- The tmux-pane editable-draft-file confirmation flow (the DEFAULT when `$TMUX` is set — see add-comment "Tmux-pane draft mode (default)"). Every surviving finding becomes one block in ONE draft file the operator can scan, edit, or SKIP in a normal editor.

When invoking `add-comment`, hand it EVERY surviving finding at once so it batches them into a single draft file (one block per finding). The operator ends up looking at one screen with all N drafts, not N modal pickers in a row. Skipping this delegation and inlining per-finding `AskUserQuestion` calls is a REGRESSION — it violates add-comment's default and forces the operator into a slower, less-editable flow.

**Fallback ONLY when `$TMUX` is unset AND `add-comment` cannot open the draft-file pane:** inline the `AskUserQuestion` loop below, but even then follow add-comment's voice and per-comment confirmation rules exactly.

### Step 8a. Read operator's Hunk notes as feedback for the agent

Between Step 7 and now the operator may have opened Hunk and written their own notes on the diff. **These are NOT PR comments to post.** They are feedback / instructions / questions directed at the agent (you) about the agent's drafts. Read them, act on them, then adjust the agent drafts before walking the per-finding ask loop.

```bash
hunk session comment list --repo "$REPO_DIR" --type user --json
```

Returns `{"comments":[{noteId, filePath, newRange:[start,end], body, ...}, ...]}`. For each user note, locate the agent draft anchored at the same `file:line` (or nearest) and interpret the note as a directive on that draft:

- **Question** ("can we verify X?", "did you check Y?") → go verify X / Y; do the research; report back what you found; then update or drop the agent draft based on the answer.
- **Correction** ("this is wrong because Z", "actually Z") → drop or rewrite the draft; do not argue.
- **Tone / phrasing direction** ("shorter", "less hedgy", "frame as a question") → rewrite the draft accordingly.
- **Drop signal** ("not worth flagging", "skip this one") → drop the draft from the punch-list before the ask loop.
- **New direction** ("look at <other thing> instead") → investigate the new direction, possibly add a finding, drop the original.

After acting on every note, surface a short recap to the operator: which drafts changed, which were dropped, what you verified. THEN proceed to Step 8b with the updated punch-list.

When the user-notes list is empty, skip this sub-step entirely and proceed straight to Step 8b.

Never post a user-authored Hunk note as a PR comment. The operator's voice in Hunk is for steering the agent, not for the PR author.

### Step 8b. Agent-drafts ask loop

For each finding (BLOCKERs first, then MAJORs, then MINORs), use **AskUserQuestion** with three options:

- `Yes, post it` (the recommended option, listed first)
- `Edit first` (user dictates the rewrite, then re-ask)
- `Skip` (don't post; move on)

**Show the full comment body inline in the question text**, fenced with `---` lines, in addition to the `preview` field. The preview box can be missed; the question text is the primary surface the user reads. Include the confidence + ✓ marker in the header so the operator can use it as a sanity check on whether to trust the finding:

```
question: "Post this on <file>:<line>?\n\n---\n<comment body>\n---"
header:   "BLOCKER 1, 92% ✓3"  /  "MAJOR 2, 78% ✓2"  /  "MAJOR 3, 73% ✓2/3"  /  "MINOR 4, 65% ✓1"
preview:  <same comment body, wrapped at ~60 cols>
```

### Length budget — short by default

Aim for **one to two sentences, ~30 words**. Lead with the bug, end with the fix. Cut anything else.

- Drop "verify in dev"-style suggestions.
- Drop "either X or Y" alternatives unless both are non-obvious; pick the better one and recommend it.
- Drop background sentences that re-state what the code says.
- A reader who's already in the diff doesn't need recap, they need the punch.

If the user replies "much shorter", "trim", "too long", or similar on any draft, cut by ~50% and re-ask. Two iterations is the budget; if you can't get it short enough the finding is probably stapled together from two issues, split it.

On "Yes, post it":

```bash
gh api "repos/$OWNER/$REPO/pulls/$PR_NUM/comments" \
  -X POST \
  -F commit_id="$HEAD_SHA" \
  -F path="$FILE" \
  -F line="$LINE" \
  -F side=RIGHT \
  -F body="$BODY" \
  --jq '.html_url'
```

Print the returned `html_url` so the user can verify. If `gh` returns `commit_id is not part of the pull request`, you used an abbreviated SHA; refetch the full SHA via `gh api repos/$OWNER/$REPO/pulls/$PR_NUM/commits --jq '.[-1].sha'`.

**Append every approved comment to `references/examples.md`** so the corpus grows with the operator's actual voice. After a successful post, edit `~/.claude/skills/auto-new-day:pr-code-review/references/examples.md` to add the new entry under the matching category section (Correctness / Data model / Error handling / API surface / Pagination / Tests / Style nits). Format:

```
**<short label>** (`<file>:<line>`)
> <comment body, verbatim>
```

If no category section matches, create one. Keep entries ordered by recency (newest at the top of its section). This is the only way the examples corpus stays a true reference of what the operator actually ships, not what an LLM thought was a good idea.

Edits to `Skip` and `Edit first` outcomes are NOT appended (only posted comments). If the user edits a draft and then approves the edited version, append the FINAL approved body, not the original draft.

On "Edit first": ask the user what to change, rewrite the body, re-run the same AskUserQuestion with the updated preview. Do not auto-post after an edit.

On "Skip": move on, no API call.

### Multi-line anchors

If the finding spans a range, post with `start_line` + `line` + `start_side` + `side`:

```bash
gh api "repos/$OWNER/$REPO/pulls/$PR_NUM/comments" \
  -X POST \
  -F commit_id="$HEAD_SHA" \
  -F path="$FILE" \
  -F start_line="$START" -F start_side=RIGHT \
  -F line="$END"          -F side=RIGHT \
  -F body="$BODY" \
  --jq '.html_url'
```

### PR-level findings (no anchor)

For findings that genuinely have no `+` line anchor (e.g. "no tests added"), post a regular issue comment instead of a review comment:

```bash
gh pr comment "$PR_NUM" --repo "$OWNER/$REPO" --body "$BODY"
```

The ask still happens, just the API endpoint differs.

### Step 8c. Existing-threads reply loop

After Step 8b's per-new-finding ask-then-post loop finishes (and the operator has had time to scroll Hunk, where `[THREAD] ...` notes from Step 6b are visible alongside the new findings), iterate the same set of existing reviewer threads that were attached to Hunk in Step 6b — for each, ask the operator whether to draft a reply.

Build the thread list from the same JSON sources fetched in Step 1, applying the same filters as Step 6b (skip threads where the latest message is the operator's, skip bot authors, skip empty review summaries). Then walk them ONE AT A TIME via `AskUserQuestion`:

```
You have <N> unanswered reviewer threads on this PR. Walk them now?
  - "Walk all <N>"  → step through each, draft-and-confirm via add-comment
  - "Pick which"    → show the list with anchors and excerpts; operator picks indices to walk
  - "Skip threads"  → finish without replies; remaining threads stay unanswered until next sweep
```

For each thread the operator chooses to walk:

1. **Show the thread context** in chat (file:line anchor, author, last 2 messages trimmed to ~200 chars each, the permalink).
2. **Invoke `/add-comment`** with the thread's permalink as the argument. `add-comment` owns the draft+fact-check+confirm+post flow — voice rules, per-comment yes/no gate, all of it. Do NOT inline-write the reply here; the `add-comment` skill is the source of truth for reply voice.
3. **Wait for `add-comment` to return** (it returns either "posted" with a comment URL, "skipped" if the operator said no, or "blocked" with a reason). Record the outcome in `/tmp/pr-<N>-replies.tsv` (columns: `thread_id\toutcome\turl_or_reason`).

After all threads are walked, print a one-line summary:

```
threads: <R> replied, <S> skipped, <F> filtered (already-engaged / bot / empty)
```

**Hard rule: `add-comment` owns posting.** Don't draft and post inline — always go through the skill. If `add-comment` isn't available in the current session, surface that as a one-line warning and skip the reply loop (don't try to ad-hoc the voice yourself; the result is what the user called out as a regression in past sessions).

**Skip the reply loop entirely when:**
- The operator picked "Skip threads" in the umbrella question.
- Zero threads survived the Step 6b filter (no unanswered, non-bot, non-empty threads on this PR).

## Step 9. Wrap

After every PR's ask loop finishes, print ONE summary block:

```
posted <K> comments across <M> PR(s):
  PR #<N1>: <K1> posted, <S1> skipped, <F1> filtered  →  approve <P1>% <TIER1>
  PR #<N2>: <K2> posted, <S2> skipped, <F2> filtered  →  approve <P2>% <TIER2>
full reports:
  <REPO1>/.inreview/<DATE>/auto-new-day:pr-code-review/pr-<N1>-<slug1>-full.md
  <REPO2>/.inreview/<DATE>/auto-new-day:pr-code-review/pr-<N2>-<slug2>-full.md
per-PR logs appended this run (layout: per-repo or parent, picked at Step 0a):
  <PR_LOG_1>
  <PR_LOG_2>
audit logs: /tmp/pr-<N1>-verification.md, /tmp/pr-<N2>-verification.md, ...
(browse with `reviews`, fzf picks any report from today; `reviews --all` for any date)
```

Nothing else. No recap of skipped findings, no encouragement.

### Step 9a. Dispatched-session snapshot hook (conditional)

A dispatching system (one that fans this skill out to async sessions and wants a per-run archive of artifacts) can opt in via two env vars set in the session bootstrap:

- `$AUTO_NEW_DAY_DATE_DIR` — the per-run archive directory (existence of this var is the gate).
- `$AUTO_NEW_DAY_SNAPSHOT_CMD` — a shell-evaluable command string that performs the snapshot. The dispatching system owns the command's content; this skill just runs it.

If both are set, eval the command after the wrap summary. Otherwise skip the step entirely (operator invoked the skill directly outside any dispatch flow).

```bash
if [ -n "${AUTO_NEW_DAY_DATE_DIR:-}" ] && [ -n "${AUTO_NEW_DAY_SNAPSHOT_CMD:-}" ]; then
  eval "$AUTO_NEW_DAY_SNAPSHOT_CMD" || true
fi
```

Best-effort; never block on this. The dispatching system is responsible for making its command idempotent and silent-on-failure. This skill has no opinion about what the command does — that's a concern of whatever system spawned this session.

## Step 9b. Approving the PR (only on explicit operator request)

The skill does NOT auto-approve based on Step 5a's confidence. The approve verdict is INFORMATION for the operator; the operator decides whether to approve.

When the operator says "approve" (or "approve PR #N", "go ahead and approve") after the wrap, the default action is `gh pr review --approve` with NO body. No "LGTM", no "looks good", no summary of the review.

```bash
gh pr review "$PR_NUM" --repo "$OWNER/$REPO" --approve
```

Do NOT add `--body "<anything>"` unless the operator explicitly tells you to ("approve with a comment", "approve and say <text>", "approve with body: <text>"). A bodiless approve is the default; an approve-with-body requires an explicit operator instruction in the same message.

When the operator says "approve" but the Step 5a tier is "APPROVE WITH CAUTION" or "DO NOT APPROVE YET", surface the mismatch once before running the command: "approve_pct was <P>% (<TIER>); still want to approve?" then act on the operator's confirmation. The mismatch check happens only once per `approve` request; if the operator confirms, do it and don't re-litigate.

If the operator says "approve all" after a multi-PR run, do the bodiless approve in sequence for every PR whose punch-list was walked. Still apply the mismatch check per PR; one "yes, approve all even the cautious ones" covers the whole batch.

## Failure modes

- **`gh` refuses `commit_id`**: you abbreviated the SHA. Use the full 40-char SHA from `gh api .../pulls/<N>/commits | jq '.[-1].sha'`.
- **`line` out of diff range**: GitHub rejects inline comments on lines GitHub doesn't show as changed. Either move the anchor to an actual `+` line, or fall back to a PR-level issue comment.
- **Local clone missing**: clone into a checkout root the operator already uses (see Step 0b). Don't review from a worktree if the dev-env files may not be mirrored.
- **PR force-pushed mid-review**: refetch `pr-<N>` (`git fetch origin pull/<N>/head:pr-<N> -f`), re-run Step 1 to get the new HEAD SHA, and warn the user that prior posted comments may now be on stale lines.
- **Verification round drops every finding**: not a failure; print "no surviving findings on PR #<N> after independent verification. Full audit at /tmp/pr-<N>-verification.md" and skip to the next PR. The verification log shows which claims were filtered and why.
- **Subagent over-claims**: if an agent reports confidence ≥ 90% on a behavior claim that the verifier marks FALSE, log it in the verification audit. Repeated over-claims from the same angle indicate the prompt needs tightening, open the SKILL.md to update.

## Composition

- **Pre-flight:** CLAUDE.md / lazy-rule loading at Step 0a. This is mandatory; subagents do not walk the CLAUDE.md tree themselves.
- **Verification:** Step 4 fans out one verifier per finding in parallel. This is mandatory before the operator sees any finding.
- **Downstream:** `hunk` (Step 6b) opens the diff with consolidated review notes attached in a new tmux window per PR, before the reduce ask in Step 7.
- **Sibling skills:**
  - Project-scoped batch drivers (e.g. `pr-code-review-all` under work) discover a set of PRs and call this skill with their URLs. They are the breadth pass; this skill is the depth-on-one-or-a-few pass.
  - `add-comment` (post one specific reply) composes inside this skill's ask-then-post step; you can call out to it for tricky multi-thread replies.
