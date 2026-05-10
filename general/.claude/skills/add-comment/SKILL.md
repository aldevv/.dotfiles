---
name: add-comment
description: Draft a short, casual review comment on a GitHub PR or GitLab MR — a reply or a new line comment — confirm with the user, optionally fact-check with subagents, then post it via gh or glab. Triggers on "/add-comment", "/pr-comment", "/pr-comment-answer", "/mr-comment", "answer this PR/MR comment", "reply to this review comment", "draft a reply to <reviewer>", "post a comment on PR #N", "post a comment on MR !N", "leave a comment on this line", or when the user wants to draft a review comment on a PR or MR.
---

# add-comment

Draft a short, human review comment on a GitHub PR or GitLab MR, confirm with `AskUserQuestion`, optionally fact-check with subagents, then post. Two flavors:

- **Reply** to an existing comment.
- **New line comment** on a file/line.

Top-level conversation comments are also supported but rare.

Pick the tool from the URL: `github.com` → `gh`, `gitlab.*` → `glab`. If the user gives a PR number with `#N`, use gh. If they give an MR with `!N` or mention GitLab, use glab. Ask if unclear.

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

Match this voice.

Reply (pushback):

> i'd keep this one. nil just means the role doesn't exist (snowflake returns 200 empty), and the same missing role often shows up across lots of grant rows, so caching it saves a bunch of calls. callers already skip on nil anyway.

Reply (agreeing, brief):

> good catch, will fix.

Reply (already done):

> done.

New line comment (feedback as reviewer):

> could batch this with a GetManyJSON over the distinct ids before the loop. the old code was already doing that.

> same on the writes. one SetManyJSON after the loop, like workersToStore.

Notice: lowercase, no greeting, no em dash, position first, then the reason, then maybe one clarification. Stops.

### Bad vs good

Robot:

> first hit per location goes one-by-one to GetJSON. that's 30 sequential roundtrips on a 30-location page. could batch it with GetManyJSON before the loop, the old 3-phase code already did.

Better, but still bot-flavoured. Human:

> could batch this with a GetManyJSON over the distinct ids before the loop. the old code was already doing that.

What changed: dropped the magnitude detail, dropped the long subordinate clause, dropped the colon-and-list rhythm. Same point, half the words.

## Workflow

1. **Identify.** Reply or new line comment? Which platform? For a reply: a comment URL (GitHub: `.../pull/N#discussion_rXXXXX`, GitLab: `.../merge_requests/N#note_XXXXX`), a reviewer name, or "the comment we just looked at". For a new line comment: PR/MR + file + line. Ask if unclear.

2. **Read the code.** For a reply, fetch the original with `gh api repos/OWNER/REPO/pulls/comments/COMMENT_ID` (GitHub) or `glab api projects/PROJECT_ID/merge_requests/MR_IID/notes/NOTE_ID` (GitLab) and read the file. For a new line comment, just read the file at the target line. Don't draft blind.

3. **Draft** in the voice above. If a sentence sounds like a memo, rewrite it.

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

7. **Report the URL** so the user can verify.

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

## When NOT to use this skill

- The user wants a long, formal response. Use plain composition.
- The user is accepting the suggestion. Skip the comment, do the code change.
- The user wants a regular code comment in a file. This skill is for PR/MR review comments only.