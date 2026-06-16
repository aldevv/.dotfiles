---
name: add-comment
description: Draft a short, casual review comment on a GitHub PR or GitLab MR — a reply or a new line comment — confirm with the user, optionally fact-check with subagents, then post it via gh or glab. Triggers on "/add-comment", "/pr-comment", "/pr-comment-answer", "/mr-comment", "answer this PR/MR comment", "reply to this review comment", "draft a reply to <reviewer>", "post a comment on PR #N", "post a comment on MR !N", "leave a comment on this line", or when the user wants to draft a review comment on a PR or MR.
---

# add-comment

Draft a short, human review comment on a GitHub PR or GitLab MR, confirm with `AskUserQuestion`, optionally fact-check with subagents, then post.

## Routing (decide before drafting)

Three flavors. Pick exactly one:

1. **Reply to an existing comment** — the user is answering a thread (gave a comment URL, said "reply to <reviewer>", "answer this comment"). Post as a note under the existing discussion. Don't relocate the reply to a different line, even if a different line would anchor better.
2. **New line comment** — a NEW comment AND the feedback is about a specific file/line of code. This is the default for any new comment that critiques, questions, or suggests a change to code. Anchor it on the exact line the comment is about. If you don't know the line yet, find it before posting (read the diff or the file).
3. **Top-level MR/PR comment** — a NEW comment AND there is no specific line of code to anchor on (general questions about the MR, scope/approach feedback that spans the whole change, status updates, "ready for review" pings). Only use this when no line could carry the same comment.

Hard rule: if the draft references a file, function, variable, or specific code behaviour, it MUST be a line comment, not a top-level comment. Top-level is the fallback only when the comment is genuinely MR-wide.

## Tool

Pick from the URL: `github.com` → `gh`, `gitlab.*` → `glab`. PR `#N` is gh; MR `!N` or any gitlab.* URL is glab. Ask if unclear.

## Voice (non-negotiable)

Read like a tired engineer on Slack, not a memo:

- **Short.** 1–3 sentences. Cut anything that doesn't carry weight.
- **Plain words.** No fancy vocab. Say "matters", not "is load-bearing". Say "before the loop", not "prior to iteration".
- **Simple grammar.** Short sentences. No semicolons. No nested "which" clauses. One idea per sentence.
- **Lowercase.** Even product names (snowflake, not Snowflake).
- **No greetings.** No "hey", "hi", "thanks", "thanks for the look".
- **No em dashes** or double-hyphens (`--`). Use a period or comma.
- **No formal hedges.** Skip "happy to revisit", "let me know if", "open to other approaches", "appreciate the feedback".
- **No bullets, no headings, no code blocks** unless you really need to quote a snippet.
- **Position first.** Then the reason. Then maybe one clarification. Stop.
- **Contractions.** i'd, doesn't, isn't.

### Reference examples

Real comments posted via this skill (deduped, with use counts) live at
[`references/examples.md`](references/examples.md). Read that file before
drafting — it's the canonical voice training set, and the `(×N)` counts make
overused phrasings visible so you avoid parroting them.

The list grows automatically: every successful post is recorded by step 7
below. Same text in the same category bumps `(×N)`; new text appends a new
bullet.

### Bad vs good

Robot:

> first hit per location goes one-by-one to GetJSON. that's 30 sequential roundtrips on a 30-location page. could batch it with GetManyJSON before the loop, the old 3-phase code already did.

Better, but still bot-flavoured. Human:

> could batch this with a GetManyJSON over the distinct ids before the loop. the old code was already doing that.

What changed: dropped the magnitude detail, dropped the long subordinate clause, dropped the colon-and-list rhythm. Same point, half the words.

## Workflow

1. **Identify and route.** Walk the routing tree above:
   - If the user is replying to an existing thread (gave a comment URL, said "reply to <reviewer>", "answer this comment") → **reply**. Need: comment URL or note id.
   - Otherwise it's a NEW comment. Does the feedback target a specific file/line of code?
     - Yes → **line comment**. If the user didn't give a line, ask. If they gave a file but not a line, read the file and pick the right line. Don't fall back to top-level just because the line is unknown.
     - No (genuinely MR-wide) → **top-level MR/PR comment**.

   Pick the platform from the URL: github.com → gh, gitlab.* → glab. Ask if unclear.

2. **Read the code.** For a reply, fetch the original with `gh api repos/OWNER/REPO/pulls/comments/COMMENT_ID` (GitHub) or `glab api projects/PROJECT_ID/merge_requests/MR_IID/notes/NOTE_ID` (GitLab) and read the file. For a new line comment, just read the file at the target line. Don't draft blind.

3. **Draft** in the voice above. Skim [`references/examples.md`](references/examples.md) for prior posts — reuse phrasings that fit, and pick a different shape if a candidate line already has a high `(×N)` count. If a sentence sounds like a memo, rewrite it.

4. **(Optional) Fact-check with subagents.** Run this only when the draft makes specific claims — names a function, cites a line, asserts behaviour, says "the old code did X", quotes a number. Skip for opinion replies ("i'd keep this", "agree, that's cleaner").

   Spawn one agent per fact. Each gets:
   - The full draft.
   - One claim to check.
   - The files to read.
   - Output: `VERIFIED` / `FALSE` / `NUANCED` plus 1–3 sentences with line numbers, ≤120 words.

   How to split claims: every verb you can grep or read code to check is its own claim. "X goes one-by-one to GetJSON" is one claim. "GetManyJSON exists and works as a drop-in" is another. "the old code was doing this" is a third (check git for pre-PR state).

   If any claim comes back `FALSE`, rewrite to drop or fix it before confirming. If `NUANCED`, decide: does the nuance change meaning (rewrite) or is it pedantic (leave it, mention to the user when confirming).

5. **Confirm via `AskUserQuestion`.** Show the draft verbatim. Two options:
   - "Post it" — go to step 6.
   - "Revise" — iterate. Common asks: "shorter", "less robot", "drop the magnitude estimate", "simpler words".

   The question must show the exact text that will be posted.

6. **Post.** Pick the right endpoint for the platform.

   ### GitHub (`gh`)

   **Reply to an existing review comment:**
   ```bash
   gh api repos/OWNER/REPO/pulls/PULL_NUMBER/comments \
     -X POST \
     -f body="<the approved draft>" \
     -F in_reply_to=COMMENT_ID
   ```

   **New line comment on a file:**
   ```bash
   gh api repos/OWNER/REPO/pulls/PULL_NUMBER/comments \
     -X POST \
     -f body="<the approved draft>" \
     -f commit_id=$(gh api repos/OWNER/REPO/pulls/PULL_NUMBER --jq '.head.sha') \
     -f path=PATH_RELATIVE_TO_REPO_ROOT \
     -F line=LINE_NUMBER \
     -f side=RIGHT
   ```
   `side=RIGHT` anchors on the post-change file. Use `LEFT` for the pre-change side (rare).

   **Top-level PR conversation comment:**
   ```bash
   gh api repos/OWNER/REPO/issues/PULL_NUMBER/comments \
     -X POST \
     -f body="<the approved draft>"
   ```

   ### GitLab (`glab`)

   GitLab needs the project ID (numeric or `group%2Fproject` URL-encoded) and the MR IID. Get them from the URL or with `glab mr view --output json`.

   **Reply to an existing discussion (thread a note under it):**
   ```bash
   glab api projects/PROJECT_ID/merge_requests/MR_IID/discussions/DISCUSSION_ID/notes \
     -X POST \
     -F body="<the approved draft>"
   ```
   The `DISCUSSION_ID` is the thread id, not the note id. Find it with `glab api projects/PROJECT_ID/merge_requests/MR_IID/discussions --jq '.[] | {id, notes: [.notes[] | {id, body}]}'`.

   **New line comment on a file:**
   ```bash
   # Grab the diff refs for position
   refs=$(glab api projects/PROJECT_ID/merge_requests/MR_IID --jq '.diff_refs')
   base=$(jq -r '.base_sha'  <<<"$refs")
   head=$(jq -r '.head_sha'  <<<"$refs")
   start=$(jq -r '.start_sha' <<<"$refs")

   glab api projects/PROJECT_ID/merge_requests/MR_IID/discussions \
     -X POST \
     -F body="<the approved draft>" \
     -F position[position_type]=text \
     -F position[base_sha]=$base \
     -F position[head_sha]=$head \
     -F position[start_sha]=$start \
     -F position[new_path]=PATH_RELATIVE_TO_REPO_ROOT \
     -F position[new_line]=LINE_NUMBER
   ```
   For a comment on a removed line, set `position[old_path]` and `position[old_line]` instead.

   **Top-level MR conversation note:**
   ```bash
   glab api projects/PROJECT_ID/merge_requests/MR_IID/notes \
     -X POST \
     -F body="<the approved draft>"
   ```

7. **Record the example.** After every successful post, append the chosen text to [`references/examples.md`](references/examples.md) so future runs can see it:

   ```bash
   python3 ~/.claude/skills/add-comment/scripts/record_example.py \
     --category "<heading>" \
     --body "<exact posted text>"
   ```

   Pick the category that fits — common ones already present:

   - `Replies — agreeing or already done`
   - `Replies — pushback`
   - `Replies — clarifying / asking back`
   - `New line comments — feedback`
   - `New line comments — nit`
   - `Top-level PR/MR comments`

   The script dedups on body text within a category, so re-posting the same line just bumps its `(×N)`. Unknown categories are created at the end of `## Answers`.

   Run this once per posted comment, even if a single skill invocation posted several (e.g. three replies in a loop).

8. **Report the URL(s)** so the user can verify.

## Common failure modes

- **Sounding like an LLM.** Em dashes, "I'd be happy to", "Let me know if", any greeting → rewrite.
- **Big words.** "load-bearing", "non-trivial", "in steady state", "geographically" — replace with plain ones.
- **Long sentences.** If you used a semicolon, split it.
- **Over-explaining.** One sentence of "why" is enough.
- **Too agreeable on replies.** This skill is for pushback or clarification. If you're accepting the suggestion, just make the code change.
- **Posting before confirmation.** Always run `AskUserQuestion` first.
- **Skipping the file read.** A draft that doesn't engage with the actual code looks generic.
- **Skipping fact-check on factual drafts.** A subtly-wrong claim is worse than a longer comment.
- **Wrong endpoint.** GitHub replies need `in_reply_to`. GitHub new line comments need `commit_id`+`path`+`line`. GitLab new line comments need the full `position` object (base_sha+head_sha+start_sha+path+line). Mixing them returns 422.
- **Wrong tool.** `gh` doesn't talk to GitLab and `glab` doesn't talk to GitHub. Pick from the URL.
- **Posting code feedback as a top-level MR/PR comment.** If the comment is about a specific file, function, line, or diff hunk, it MUST be a line comment. Top-level is for MR-wide feedback only. Concrete check: if the draft says "this", "here", "line N", or names a symbol from the diff, find the line and post there.
- **Zsh globbing the `position[...]` brackets in glab.** Quote the whole `-F "position[key]=value"` argument. Unquoted, zsh hits "no matches found" and the curl never runs.

## When NOT to use this skill

- The user wants a long, formal response. Use plain composition.
- The user is accepting the suggestion. Skip the comment, do the code change.
- The user wants a regular code comment in a file. This skill is for PR/MR review comments only.