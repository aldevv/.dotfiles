---
name: add-comment
description: Draft a short, casual review comment on a GitHub PR or GitLab MR, a reply or a new line comment, confirm with the user, optionally fact-check with subagents, then post via gh or glab. Triggers on "/add-comment", "/pr-comment", "/pr-comment-answer", "/mr-comment", "answer this PR/MR comment", "answer the comment", "respond to this comment", "reply to this review comment", "draft a reply", "draft the reply", "draft a response", "draft the response", "draft a reply to <reviewer>", "draft a response to <reviewer>", "answer all of <reviewer>'s comments", "respond to all open threads", "mark all as done/fixed", "post a comment on PR #N", "post a comment on MR !N", "leave a comment on this line", or when the user wants to draft, answer, or batch-acknowledge review comments on a PR or MR. Fires even when the trigger phrase is bundled with other actions (e.g. "draft the reply to X and post it").
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

   **MANDATORY per-batch confirmation.** Earlier confirmations in the same session do NOT carry over to a new batch. A high-level instruction like "go ahead with the replies" or "post them" without the user seeing the verbatim draft text is NOT confirmation — show the drafts and ask again. Even when a plan was approved earlier with summary descriptions (e.g. "reply with `done`"), confirm the actual text once more before posting.

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

8. **Open in browser (first post of the session only).** If `$BROWSER` is set AND no comment has been opened this session yet, fire-and-forget the posted URL through `$BROWSER` so the user can eyeball formatting. Skip silently when `$BROWSER` is unset.

   Session is tracked with a marker file. Use `$CLAUDE_SESSION_ID` if exposed, fall back to `$TMUX_PANE`, then `$PPID`. Once the marker exists for the session, later posts in the same session do NOT auto-open — they stay quiet so the loop doesn't spam tabs.

   ```bash
   sid="${CLAUDE_SESSION_ID:-${TMUX_PANE:-$PPID}}"
   marker="$HOME/.cache/add-comment/sessions/${sid//[^A-Za-z0-9._-]/_}.opened"
   if [ -n "$BROWSER" ] && [ ! -f "$marker" ]; then
     mkdir -p "$(dirname "$marker")"
     touch "$marker"
     "$BROWSER" "$POSTED_URL" >/dev/null 2>&1 &
   fi
   ```

   `$POSTED_URL` is the `html_url` printed by the `gh`/`glab` post in step 6. Don't block on browser launch — the `&` keeps it async so the skill can finish.

9. **Report the URL(s)** so the user can verify.

## Batch mode

When the user asks to mark a set of comments at once (e.g. "answer all of <reviewer>'s comments", "mark all as done/fixed"), confirm the full mapping ONCE via a single `AskUserQuestion` showing a comment-id → reply table with the **verbatim** body for each, then post each in a loop. Skip per-reply confirmation and fact-checking. Each successful post still records to `references/examples.md`.

The batch-mode confirmation is REQUIRED, not optional. A prior plan listing reply intent in summary form (e.g. "reply 'done' to threads X/Y/Z") is not a substitute — the table must show the literal bodies that will be posted. If the user said "go ahead" or "do it" without seeing the bodies, surface the verbatim table and ask again.

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