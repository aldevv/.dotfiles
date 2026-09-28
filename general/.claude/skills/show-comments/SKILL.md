---
name: show-comments
description: >
  Show every comment on a GitHub PR (or GitLab MR) as compact tables: one table of
  inline review threads (file:line, severity, resolved vs OPEN, outdated) and one of reviews +
  conversation comments, flagging bot vs human authors and highlighting unresolved
  threads, then closes with a minimal "Recommended actions" table listing only what
  actually gates the merge. Read-only: it never posts, resolves, or dismisses. Triggers on
  "/show-comments", "show comments", "show me all the comments on this PR/MR",
  "list the PR comments", "what comments are on this PR", "any unresolved threads",
  "who commented on my PR", "did a human comment". Takes an optional PR/MR number or
  URL; with none, uses the PR for the current branch. Preconditions: `gh` + `jq`
  (GitHub) or `glab` (GitLab). To REPLY to a comment use `add-comment`; to run a
  multi-angle review use `pr-code-review`; this skill only displays.
argument-hint: "[pr-number | pr-url | mr-url] [--no-cache]  (optional; defaults to the current branch's PR)"
---

# show-comments

Display all comments on a pull/merge request as two tables. Read-only.

## When to use vs siblings
- **This skill**: just SHOW what's there (threads, reviews, conversation), with resolved/OPEN status and bot/human split.
- `add-comment`: draft + post a reply to a thread. `pr-code-review`: produce a new multi-angle review. `report`: open the diff in Hunk. None of those is a substitute for a plain read-out, and this skill never posts.

## Step 1 — Resolve the target
From `$ARGUMENTS`:
- A number (`149`) or GitHub URL → that PR in the current repo (or the URL's repo).
- A GitLab URL, or repo remote is GitLab → treat as an MR, use `glab` (Step 2b).
- Empty → the PR for the current branch: `gh pr view --json number,url` (errors if the branch has no PR — say so and stop).
- `--no-cache` anywhere in `$ARGUMENTS` forces a full re-validation: ignore the Step 5.6 done-cache on read and rewrite it from scratch. Strip it before parsing the PR target.

Derive `OWNER/REPO` from `gh repo view --json nameWithOwner -q .nameWithOwner` (or the URL).

## Step 2a — Fetch (GitHub)
Run these three (read-only). Under an `auto-new-day` `AUTO-*` session a write-shim blocks even read `gh api graphql`; prefix those with `AUTO_NEW_DAY_APPROVED=1` and `tail -n +2` to drop the override banner before `jq`. In a normal session no prefix is needed.

Inline review threads (resolved state lives only in GraphQL):
```bash
gh api graphql -f query='
{ repository(owner:"OWNER",name:"REPO"){ pullRequest(number:N){
  reviewThreads(first:100){ nodes{
    id isResolved isOutdated path line
    comments(first:1){ nodes{ author{login} body } }
  } } } } }' \
| jq -r '.data.repository.pullRequest.reviewThreads.nodes[]
  | [ .comments.nodes[0].author.login,
      (.path // "-"), (.line // "-"|tostring),
      (if .isResolved then "resolved" else "OPEN" end),
      (if .isOutdated then "outdated" else "current" end),
      (.comments.nodes[0].body | gsub("[\n\r]+";" ") | .[0:100]) ] | @tsv'
```

Reviews (state + timestamp + head-anchor + body) and conversation comments. `submitted_at` lets Step 5 find each reviewer's LATEST verdict (earlier ones are superseded); `commit_id` is kept only as a parenthetical in the Note, not the status:
```bash
HEAD=$(gh pr view N --json headRefOid -q .headRefOid)
gh api repos/OWNER/REPO/pulls/N/reviews \
  | jq -r --arg head "$HEAD" '.[] | [.user.login, .state, .submitted_at,
      ((.commit_id // "-")[0:8]),
      (if (.commit_id // "") == $head then "head" else "old" end),
      (.body|gsub("[\n\r]+";" ")|.[0:80])] | @tsv'
gh api repos/OWNER/REPO/issues/N/comments \
  | jq -r '.[] | [.user.login, (.body|gsub("[\n\r]+";" ")|.[0:100])] | @tsv'
```

## Step 2b — Fetch (GitLab)
```bash
glab api "projects/:id/merge_requests/N/discussions?per_page=100" \
  | jq -r '.[] | .notes[] | select(.system==false)
      | [.author.username, (.resolved|tostring),
         (.position.new_path // "-"), (.position.new_line // "-"|tostring),
         (.body|gsub("[\n\r]+";" ")|.[0:100])] | @tsv'
```
GitLab folds inline + conversation into "discussions"; a note with a `.position` is inline, without is conversation.

## Step 3 — Classify author
Bot if the login ends with `[bot]` or matches a known bot (`github-actions`, `linear-code`, `coderabbitai`, `codecov`, `sonarcloud`, `dependabot`, `renovate`). Everyone else is human. **Call out the human/bot split explicitly** — "who actually reviewed" is usually the first thing the operator wants.

## Step 4 — Severity (best-effort)
Bot inline comments often lead with a glyph/word: 🔴/`Blocking`/`Bug` → high, 🟠 → med-high, 🟡/`Suggestion`/`Nit` → low. Map the leading token to a `Sev` cell; use `-` when none. Never invent a severity a human didn't state.

For Table B rows, derive `Sev` from the row kind: a **review** maps from its state — `CHANGES_REQUESTED` → high, `COMMENTED`/`DISMISSED` → `-` (informational), `APPROVED` → ✅; a **conversation comment** uses the same leading-glyph rule as inline threads, else `-`.

## Step 5 — Render two tables
Table A (inline threads), one row per thread. **Order resolved threads first, then open**; within each group keep the order returned.

`# | Author | File:Line | Sev | Status | Outdated | Gist`

- `Status` is `✅ resolved` or `⚠️ OPEN`. Mark threads whose newest comment post-dates the last push as `OPEN (new)` when that's knowable.
- `Outdated` is `🕓 outdated` when GitHub flagged the thread outdated (`isOutdated` true — the code it anchored to changed under it, and GitHub then returns a null `line`, so `File:Line` shows `-`), else `current`. It is the closest per-thread signal that a LATER commit already touched that code, so an `⚠️ OPEN` + `🕓 outdated` thread is very likely already addressed and just never clicked "Resolve" — distinct from `⚠️ OPEN` + `current`, which the latest code still matches and is the set that actually needs a look. **"Outdated" only means the code MOVED, not that the concern was fixed** — Step 5.5 validates that. When Step 5.5 ran, this cell shows the validated verdict (`🕓 → ✅ done` / `🕓 → ⚠️ still` / `🕓 → ? unsure`) instead of a bare `🕓 outdated`. Call the outdated count (and the done/still split when validated) out in the Step 6 summary. GitHub only; GitLab has no direct equivalent, use `-`.
- `Gist` is a one-line paraphrase, not the raw dump; keep it short.
- `Author` is the thread's original commenter (`.comments.nodes[0].author.login`, already fetched in Step 2a). Tag bots per Step 3, e.g. `github-actions [bot]`, so the human/bot split is visible per-row.

Table B (reviews + conversation):

`Author | Type | Sev | Status | Note`

- `Type` ∈ `review (APPROVED|CHANGES_REQUESTED|COMMENTED|DISMISSED)` or `comment`.
- `Sev` per Step 4 (review state → severity; comment → leading glyph else `-`).
- `Status` says **done vs not done** — whether the row still needs YOUR action. For a **review**, first find each reviewer's LATEST review by `submitted_at`; earlier reviews from the same reviewer are superseded. Classify the latest using BOTH its state and whether commits were pushed after it (the `head`/`old` anchor from Step 2a):
  - `⚠️ not done` — latest is `CHANGES_REQUESTED` AND it sits on the CURRENT head. The bot reviewed the current code and still blocks: this genuinely needs work.
  - `🔄 pending re-review` — latest is `CHANGES_REQUESTED` but on an OLD head (commits were pushed after it). It still drives `reviewDecision`, but it does NOT reflect the current code, so it is NOT "not done" — the findings may already be fixed and the bot just hasn't re-scored. Don't report it as a live block; say the block is stale and, if a re-review check is running, note that.
  - `✅ done` — latest is `APPROVED`, OR superseded by a newer review from the same reviewer, OR `DISMISSED`.
  - `-` — latest is `COMMENTED` (informational, nothing to resolve).
  Keep the sha out of the Status cell — put `(on old head 1d18d04)` in the Note. A **conversation comment** has no resolution state, so its `Status` is `-`.

  **The `head` vs `old` anchor is decisive here:** a `CHANGES_REQUESTED` you have already pushed fixes past is `🔄 pending re-review`, never `⚠️ not done`. Only a changes-request on the CURRENT head is a real "not done".
- Tag bots per Step 3 in the `Author` cell.

## Step 5.5 — Validate the outdated threads (GitHub, best-effort, read-only)

`🕓 outdated` only means the anchored code MOVED, not that the concern was fixed. When there are `⚠️ OPEN` + `🕓 outdated` threads, upgrade the label to a verdict by checking each against the CURRENT head. This stays read-only: it reads code, never posts or resolves. Skip when there are zero outdated threads.

1. **Get the current code.** If the target PR is the current branch and `git rev-parse HEAD` equals the PR `headRefOid`, read files straight from the working tree. Otherwise fetch each thread's file at head: `gh api repos/OWNER/REPO/contents/<path>?ref=<headRefOid> -q .content | base64 -d`. (The thread's own `line` is null — it's outdated — so you work from the file's current state, not the old line number.)
2. **Judge each outdated thread.** Locate the concern in the current file by the symbol/pattern the comment names (function, field, the bad line it quoted), then classify:
   - `✅ done` — the flagged problem is gone, or the suggested change is present, in current HEAD.
   - `⚠️ still` — the concern still applies even though the line moved (a real surviving issue — treat like a live `current` finding, not a safe outdated one).
   - `? unsure` — a static read can't tell (needs runtime, or the comment is ambiguous).
   For more than ~2 outdated threads, run these as **parallel subagents** (one per thread, or batched one per file), each handed the thread body + the current file, so the main context stays lean and the checks mirror the review-verification pattern. Every verdict carries a one-line why and a confidence `%`; tag `✓N` (N = independent subagents that agreed) per the review-findings convention, and never assume `✅ done` from the outdated flag alone — the flag is the reason to check, not the answer.
3. **Never auto-resolve.** The verdict feeds the `Outdated` cell only. Resolving/dismissing a thread is a write and is out of scope here; if the operator wants it, hand off (the resolve recipe in `~/work/.claude/lazy/gh.md`).

Scope: validate `🕓 outdated` threads by default (the usual ask is "are these done?"). `current` threads still anchor to live code and are the set that most needs review; validate them too only if the operator asks.

**Before validating, consult the done-cache (Step 5.6): any thread already cached `done` is rendered `✅ done (cached)` and is NOT re-validated here.** After validating, write the new `done` verdicts back to the cache. That is what stops every run from re-checking the same fixed threads.

## Step 5.6 — Done-thread cache (skip re-checking what's already fixed)

Validating a thread (Step 5.5) or fixing the code behind it is expensive — spawning subagents, reading files. Once a thread is confirmed done, remember it so later runs (and later sessions) don't redo the work. The cache is a throwaway temp file keyed to the PR, not the conversation.

- **Cache file:** `/tmp/show-comments-done-<owner>-<repo>-<pr>.json`, `owner/repo` sanitized by replacing `/` and `#` with `-` (e.g. `/tmp/show-comments-done-ConductorOne-baton-axiomatic-243.json`). For a GitLab MR use `-mr-<iid>`.
- **Key:** the thread's GraphQL node `id` (fetched in Step 2a — stable across pushes; GitLab: the discussion `id`). **Value:** `{"status":"done","headSha":"<short sha marked at>","reason":"<one line: what fixed it / why done>","by":"validate|fix"}`.
- **Read (start of Step 5):** load the file if it exists (`[]`/absent → empty). A thread whose `id` is cached `done` renders `Outdated` = `✅ done (cached)` and is skipped by Step 5.5. A cached-done id no longer present in the live threads is dropped (thread resolved/gone) — prune it on write.
- **Write (end of Step 5.5, and whenever a fix lands):** merge in every thread newly confirmed done — the Step 5.5 `✅ done` verdicts (`by:"validate"`), plus any thread whose underlying issue was fixed in code this session (`by:"fix"`, reason = the fix's `file:line`). This is the hook the operator meant by "when we fix issues, cache them": a fixing flow appends the fixed threads' ids here so the next `show-comments` shows them `✅ done (cached)` without re-checking. Write with `jq` (read-merge-write); never hand-edit.
- **Trust model:** once cached `done`, stay done — a later commit only adds code, and a genuinely re-introduced regression arrives as a NEW thread id (bots re-post), so a still-present cached id is still fixed. `--no-cache` (Step 1 arg) forces a full re-validation and rewrites the cache from scratch; use it if you suspect a stale entry.

## Step 6 — Summary line
One line after the tables: total threads, `N open` (of which how many human, and how many of the open ones are `🕓 outdated` vs `current`). When Step 5.5 ran, add the validated split — e.g. `12 outdated → 10 ✅ done, 1 ⚠️ still, 1 ? unsure`, and call out any `⚠️ still` explicitly since those are live despite being outdated. Then the review decision if any (`gh pr view --json reviewDecision,mergeable`), and whether any human has commented at all. If everything is bot and resolved, say so plainly.

## Step 7 — Recommended actions table (minimal path to merge)
Last thing printed. This is NOT a redo of the comment tables: it is the SMALLEST set of actions that flips the PR to mergeable, derived from the merge gate, not from the full finding list. Fewer rows is better; one row is the goal.

First read the actual gate (don't infer it from the tables):
```bash
gh pr view N --json reviewDecision,mergeable,mergeStateStatus,isDraft
gh pr checks N 2>/dev/null   # required + failing checks; ignore non-required green ones
```
Then list ONLY things that block merge, ranked by how cheaply they unblock. A finding belongs in this table only if removing it changes whether the PR can merge:

- **Live blocking review** (`⚠️ not done` in Table B: `CHANGES_REQUESTED` on the CURRENT head, or a human whose latest review requests changes on head): a row to address it. This is the one class that always gates.
- **Stale bot block** (`🔄 pending re-review`: `CHANGES_REQUESTED` on an OLD head): usually the WHOLE gate on connector PRs. The action is **dismiss it** (`gh api -X PUT repos/OWNER/REPO/pulls/N/reviews/<id>/dismissals -f message="..." -f event=DISMISS`), NOT "fix its old findings" (already fixed, that's why it's stale) and NOT "wait for a re-review" (a bot that only ever posts `COMMENTED` on clean runs never clears its own prior `CHANGES_REQUESTED`). Check `.state=="APPROVED"` count for that bot: if it's zero, dismissal is the only path.
- **Failing required check**: a row to fix it (name the check).
- **Open thread that actually gates**: only when the repo enforces thread resolution to merge, OR a required/human reviewer is blocking on it, OR Step 5.5 marked it `⚠️ still`. A plain open bot `🟡`/`Suggestion`/`Nit` on current head does NOT gate merge — EXCLUDE it (mention in the summary, not here).
- **Draft / not-mergeable-for-other-reasons** (`isDraft`, conflicts): a row for that.

Exclude by construction: anything `✅ resolved` / `✅ done` / `✅ done (cached)`, validated-`done` outdated threads, and non-blocking nits. If two rows would unblock the same gate, keep the cheaper one only.

Table (Action, then How, then Why, then Author — the operator reads left-to-right and stops once they know what to run):

`# | Action | How | Why | Author`

- `Action` is imperative and specific ("dismiss the stale bot review", "fix the failing `go test` check").
- `How` is the exact command or sibling skill to run: a `gh`/`git` one-liner, `add-comment`, etc. This skill stays read-only; it recommends, never executes.
- `Why` is the gate token ONLY, no prose: `reviewDecision=CHANGES_REQUESTED (stale)`, `check "go test" red`, `unresolved required thread`. A few words, never a sentence. The operator hates reading; the token is enough.
- `Author` is who raised the finding/thread/review that drives this action (the original commenter from Table A/B, bot-tagged per Step 3), so each action traces to its source. Use `-` when the action is derived from the merge gate rather than a specific comment (e.g. a draft or failing-check row with no attributable author).

If the gate is already clear (`reviewDecision` `APPROVED` or empty, mergeable true, checks green, no gating thread), emit a single row: `Nothing blocking — ready to merge.` Never pad the table to look busy; an empty gate is the best outcome and should read as one line.

## Guardrails
- **Read-only. Never** `gh pr comment` / `gh pr review` / `gh api ... -X POST|PUT` / `glab mr note` / resolve / dismiss. If the operator wants to act, hand off: `add-comment` (reply), or the manual resolve/dismiss recipes in `~/work/.claude/lazy/gh.md`.
- Truncate bodies; never paste a multi-paragraph bot review verbatim into the table.
