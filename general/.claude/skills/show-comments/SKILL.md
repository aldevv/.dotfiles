---
name: show-comments
description: >
  Show every comment on a GitHub PR (or GitLab MR) as compact tables: one table of
  inline review threads (file:line, severity, resolved vs OPEN) and one of reviews +
  conversation comments, flagging bot vs human authors and highlighting unresolved
  threads. Read-only: it never posts, resolves, or dismisses. Triggers on
  "/show-comments", "show comments", "show me all the comments on this PR/MR",
  "list the PR comments", "what comments are on this PR", "any unresolved threads",
  "who commented on my PR", "did a human comment". Takes an optional PR/MR number or
  URL; with none, uses the PR for the current branch. Preconditions: `gh` + `jq`
  (GitHub) or `glab` (GitLab). To REPLY to a comment use `add-comment`; to run a
  multi-angle review use `pr-code-review`; this skill only displays.
argument-hint: "[pr-number | pr-url | mr-url]  (optional; defaults to the current branch's PR)"
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

Derive `OWNER/REPO` from `gh repo view --json nameWithOwner -q .nameWithOwner` (or the URL).

## Step 2a — Fetch (GitHub)
Run these three (read-only). Under an `auto-new-day` `AUTO-*` session a write-shim blocks even read `gh api graphql`; prefix those with `AUTO_NEW_DAY_APPROVED=1` and `tail -n +2` to drop the override banner before `jq`. In a normal session no prefix is needed.

Inline review threads (resolved state lives only in GraphQL):
```bash
gh api graphql -f query='
{ repository(owner:"OWNER",name:"REPO"){ pullRequest(number:N){
  reviewThreads(first:100){ nodes{
    isResolved isOutdated path line
    comments(first:1){ nodes{ author{login} body } }
  } } } } }' \
| jq -r '.data.repository.pullRequest.reviewThreads.nodes[]
  | [ .comments.nodes[0].author.login,
      (.path // "-"), (.line // "-"|tostring),
      (if .isResolved then "resolved" else "OPEN" end),
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

`# | Author | File:Line | Sev | Status | Gist`

- `Status` is `✅ resolved` or `⚠️ OPEN`. Mark threads whose newest comment post-dates the last push as `OPEN (new)` when that's knowable.
- `Gist` is a one-line paraphrase, not the raw dump; keep it short.
- `Author` is the thread's original commenter (`.comments.nodes[0].author.login`, already fetched in Step 2a). Tag bots per Step 3, e.g. `github-actions [bot]`, so the human/bot split is visible per-row.

Table B (reviews + conversation):

`Author | Type | Sev | Status | Note`

- `Type` ∈ `review (APPROVED|CHANGES_REQUESTED|COMMENTED|DISMISSED)` or `comment`.
- `Sev` per Step 4 (review state → severity; comment → leading glyph else `-`).
- `Status` says **done vs not done** — whether the row still needs action — NOT which commit it sits on. For a **review**, first find each reviewer's LATEST review by `submitted_at`; only that one is operative, every earlier review from the same reviewer is superseded. Then:
  - `⚠️ not done` — the reviewer's latest review is `CHANGES_REQUESTED` (a live block; this is what still drives `reviewDecision`).
  - `✅ done` — the reviewer's latest is `APPROVED`, OR this review was superseded by a newer one from the same reviewer (its findings no longer gate), OR `DISMISSED`.
  - `-` — a `COMMENTED` review that is the latest (informational, nothing to resolve).
  Put the short commit sha (`head`/`old`) in the Note as a parenthetical if useful, e.g. `(on old head 1d18d04)`; keep it out of the Status cell so a superseded block never reads as live. A **conversation comment** has no resolution state, so its `Status` is `-`.
- Tag bots per Step 3 in the `Author` cell.

## Step 6 — Summary line
One line after the tables: total threads, `N open` (of which how many human), review decision if any (`gh pr view --json reviewDecision,mergeable`), and whether any human has commented at all. If everything is bot and resolved, say so plainly.

## Guardrails
- **Read-only. Never** `gh pr comment` / `gh pr review` / `gh api ... -X POST|PUT` / `glab mr note` / resolve / dismiss. If the operator wants to act, hand off: `add-comment` (reply), or the manual resolve/dismiss recipes in `~/work/.claude/lazy/gh.md`.
- Truncate bodies; never paste a multi-paragraph bot review verbatim into the table.
