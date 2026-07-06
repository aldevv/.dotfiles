---
name: add-comment
description: Draft a short, casual review comment on a GitHub PR or GitLab MR, a reply or a new line comment, confirm with the user, optionally fact-check with subagents, then post via gh or glab. Triggers on "/add-comment", "/pr-comment", "/pr-comment-answer", "/mr-comment", "answer this PR/MR comment", "answer the comment", "respond to this comment", "reply to this review comment", "draft a reply", "draft the reply", "draft a response", "draft the response", "draft a reply to <reviewer>", "draft a response to <reviewer>", "answer all of <reviewer>'s comments", "respond to all open threads", "mark all as done/fixed", "post a comment on PR #N", "post a comment on MR !N", "leave a comment on this line", "open the comment pane", "open the comment window", "open the draft pane", "open the draft window", "open the draft file", "open the answer draft pane", "open the answer draft window", "open the drafts", "open the drafts pane", "open the drafts window", "open the answer pane", "open the answer window", "show me the draft comments", "show the draft comments", "show me the draft pane", "show the draft file", "surface the drafts", "put the drafts in a pane", "put the drafts in a window", or when the user wants to draft, answer, or batch-acknowledge review comments on a PR or MR. Fires even when the trigger phrase is bundled with other actions (e.g. "draft the reply to X and post it"). Any phrasing that asks for a drafts pane / drafts window / drafts file for PR or MR review comments loads this skill.
---

# add-comment

Draft a short, human review comment on a GitHub PR or GitLab MR, confirm with `AskUserQuestion`, optionally fact-check with subagents, then post.

## Routing (decide before drafting)

Three flavors. Pick exactly one:

1. **Reply to an existing comment** — the user is answering a thread (gave a comment URL, said "reply to <reviewer>", "answer this comment"). Post as a note under the existing discussion. Don't relocate the reply to a different line, even if a different line would anchor better.
2. **New line comment** — a NEW comment AND the feedback is about a specific file/line of code. This is the default for any new comment that critiques, questions, or suggests a change to code. Anchor it on the exact line the comment is about. If you don't know the line yet, find it before posting (read the diff or the file).

   **CRITICAL: the anchor line MUST match the comment's subject.** Before finalizing an anchor, read the target line and confirm the code AT that line is what the comment describes. Common mis-anchor patterns to avoid:
   - Anchoring on the FIRST line in a block of related lines when the comment is about the LAST one (or vice versa). Pick the line whose code the reader will look at to understand the comment.
   - Anchoring on a nearby line (e.g. a validation guard) when the comment is actually about a different construct (e.g. the vendor call several lines later). If the comment says "wrap gocloak errors" and mentions `MapAPIError`, the anchor must be the line where the gocloak call happens (e.g. `o.client.CreateUser(...)`), NOT the line where the earlier `nil` guard runs. Reader lands on the anchor first; that line must ground the comment.
   - Anchoring on a `+` line that happens to be nearby but doesn't itself demonstrate the issue. When the comment references multiple sites (":127, :134, :139"), pick the line where the underlying pattern is clearest, not the numerically-first one.
   - When drafting from a review report that cites multiple line numbers, re-read each cited line and pick the primary anchor deliberately. Don't default to the first number in the list.

   Concrete check before posting: read the anchor line's code, restate what it does in one sentence, then re-read the comment body. If the sentence and the body don't naturally connect ("this line does X. the comment says Y about X"), the anchor is wrong; find the right line and rewrite the block.
3. **Top-level MR/PR comment** — a NEW comment AND there is no specific line of code to anchor on (general questions about the MR, scope/approach feedback that spans the whole change, status updates, "ready for review" pings). Only use this when no line could carry the same comment.

Hard rule: if the draft references a file, function, variable, or specific code behaviour, it MUST be a line comment, not a top-level comment. Top-level is the fallback only when the comment is genuinely MR-wide.

## Tool

Pick from the URL: `github.com` → `gh`, `gitlab.*` → `glab`. PR `#N` is gh; MR `!N` or any gitlab.* URL is glab. Ask if unclear.

## Voice (non-negotiable)

Read like a tired engineer on Slack, not a memo:

- **As short as possible.** Replies are ideally one word ("done", "fixed", "yep"). Aim for the fewest words that close the thread. If you wrote more than one sentence, ask whether each one is doing work that the reader actually needs. Never reference commit shas. Never restate what changed. The reviewer can see the diff.
- **Plain words.** No fancy vocab. Say "matters", not "is load-bearing". Say "before the loop", not "prior to iteration".
- **Simple grammar.** Short sentences. No semicolons. No nested "which" clauses. One idea per sentence.
- **Lowercase.** Even product names (snowflake, not Snowflake).
- **No greetings.** No "hey", "hi", "thanks", "thanks for the look".
- **No em dashes** or double-hyphens (`--`). Use a period or comma.
- **No formal hedges.** Skip "happy to revisit", "let me know if", "open to other approaches", "appreciate the feedback".
- **No bullets, no headings, no code blocks** unless you really need to quote a snippet.
- **Position first.** Then the reason. Then maybe one clarification. Stop.
- **Contractions.** i'd, doesn't, isn't.
- **Backticks for every code identifier.** Function names, type names, package names, method names, variable names, error codes, gRPC codes, HTTP status codes, JSON field names, config keys, CLI flags, file paths — wrap in backticks. GitHub / GitLab render backtick spans as monospace, which visually separates code from prose and makes the comment easier to scan. Concrete: write `` `MapAPIError` `` not `MapAPIError`, `` `IsAlreadyExistsError` `` not `IsAlreadyExistsError`, `` `codes.Unknown` `` not `codes.Unknown`, `` `*gocloak.APIError` `` not `*gocloak.APIError`, `` `pkg/config/config.yaml:418` `` not `pkg/config/config.yaml:418`. Exceptions: don't backtick prose that names a concept generically ("the users endpoint", "the auth flow", "the pagination cursor"); backticks are for THIS SPECIFIC identifier the reader can grep for. Regular English words never get backticks.
- **No unusual noun shortenings.** A human reads this. Do NOT use uncommon slang like `caps` (for capabilities) or `impl` (for implementation) — spell them out. Widely-recognized industry shortenings ARE fine because every developer already reads them without translation: `docs`, `auth`, `env`, `repo`, `config`, `sync`, `spec`, `api`, `oauth`, `scim`, `url`. The dividing line: if a new hire would need a second to unpack it, use the full word.

Also fine either way: established code-identifier shortenings that appear as-is in the codebase (`ctx`, `req`, `resp`, `err`, `ok`, package names). The reader sees them in the diff, no translation needed.

- **No internal-tooling refs in the answer body.** Never mention `claude.md`, `CLAUDE.md`, `work claude.md`, `~/.claude`, `.claude/lazy`, the review skill by name, or any other internal-tooling artifact. The PR author doesn't know or care about our review pipeline — those refs leak our process into their diff. If the position is grounded in a rule, state the rule in plain terms and (see next bullet) link the public source. Applies to `- answer:` and `- shorter_answer:` bodies. `- context:` is display-only and can mention internal artifacts freely.
- **If the answer cites a rule / spec / standard, the shorter_answer MUST carry the same doc link.** Public doc URLs are the single most useful thing in a review comment — they let the author verify the claim without asking. Keep every URL from `- answer:` also in `- shorter_answer:`, verbatim. **URLs do not count toward any length limit** (the 50/75-char wrap rules ignore them). If the rule has no public URL (internal-only), state the position without citing the rule at all — do not name-drop internal-only rules.

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

   ### auto-new-day override

   When the session was dispatched by the `auto-new-day` skill (a per-window `gh` write-shim is installed under `~/work/.auto-new-day/guards/<TICKET>/bin/gh`), every write call must prepend `AUTO_NEW_DAY_APPROVED=1` to bypass the block. The skill's `AskUserQuestion` confirmation IS the approval that earns the override — once the user clicks "Post it", set the env var on the post command. The shim emits a stderr audit line each time the override is used.

   ```bash
   AUTO_NEW_DAY_APPROVED=1 gh api repos/.../comments -X POST ...
   ```

   Outside auto-new-day sessions the env var is a no-op (no shim on `$PATH` is reading it), so this is safe to set unconditionally on every post the skill makes.

   ### GitHub (`gh`)

   **Reply to an existing review comment:**
   ```bash
   AUTO_NEW_DAY_APPROVED=1 gh api repos/OWNER/REPO/pulls/PULL_NUMBER/comments \
     -X POST \
     -f body="<the approved draft>" \
     -F in_reply_to=COMMENT_ID
   ```

   **New line comment on a file:**
   ```bash
   AUTO_NEW_DAY_APPROVED=1 gh api repos/OWNER/REPO/pulls/PULL_NUMBER/comments \
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
   AUTO_NEW_DAY_APPROVED=1 gh api repos/OWNER/REPO/issues/PULL_NUMBER/comments \
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

When the user asks to mark a set of comments at once (e.g. "answer all of <reviewer>'s comments", "mark all as done/fixed"), the default confirmation is a tmux pane with an editable draft file (see below). An editable file beats a wall of `AskUserQuestion` options every time: the operator can tweak wording, drop blocks, or SKIP the ones they don't want with a normal text editor instead of a modal picker.

Fallback shape when tmux is NOT available (`$TMUX` unset):

- **N ≤ 2** → single `AskUserQuestion` showing a comment-id → reply table with the **verbatim** body for each.
- **N > 2** → still surface the drafts, but stack them in one `AskUserQuestion` prompt with the verbatim bodies. Warn the user inline that editing isn't possible without tmux.

Either way, the user's "post" decision happens AFTER they see the verbatim bodies. Skip per-reply confirmation and fact-checking once they say go. Each successful post still records to `references/examples.md`.

The batch-mode confirmation is REQUIRED, not optional. A prior plan listing reply intent in summary form (e.g. "reply 'done' to threads X/Y/Z") is not a substitute — the bodies must be shown literally. If the user said "go ahead" or "do it" without seeing the bodies, surface them and ask again.

### Tmux-pane draft mode (default)

When tmux is available (`$TMUX` set), always swap the AskUserQuestion table for an editable draft file in a sibling tmux **pane**, regardless of batch size. This is the default path.

**Single draft file, one block per finding.** Every reply or new comment the skill is asked to draft in one invocation goes into ONE draft file with a `# block N` per finding. Never write one draft file per finding, and never open the draft in a separate tmux window. The operator wants to see every candidate reply on one screen so they can scan, edit, or `SKIP` each in the same editor buffer without switching windows. When a caller (`pr-code-review` post-loop, `pr-comment-fix` batch, or the operator asking to answer several threads at once) hands the skill multiple targets, the skill batches them into a single draft; if the caller hands them in one at a time, the skill still reserves the file and appends new blocks to it on the next invocation within the same session (see step 3 for the append-vs-new-file rule).

1. Build ONE file under `/tmp/`:
   - `/tmp/add-comment-drafts-<PR_OR_MR>-<TIMESTAMP>.md` — human-editable, one block per reply. All post metadata (target file/line, thread id) lives in the draft's bullets. No sidecar JSON. The `.md` extension is deliberate: `---` separators render as horizontal rules and the bullet fields render as a list, giving free syntax highlighting.

2. **File header (single occurrence, once per file, ABOVE the first `---`).** Two h1 sections in this order: the how-to block (h1 + h2 instructions), then a `# Comments` h1 that carries the metadata lines AND every `---`-delimited comment block below. Both live above / around the blocks and are not repeated per-block:

   ```
   # how to use this file

   ## each `---`-delimited block is one PR comment to post
   ## edit `- answer:` to change the body
   ## set `- answer: SKIP` (or empty the value, or delete the whole block) to drop it
   ## `- shorter_answer:` is display-only, copy over `- answer:` if you prefer the shorter one
   ## `- context:` is display-only
   ## `- comment:` (only in reply blocks) is what the reviewer said, display-only
   ## `- answer:` is ALWAYS the last item in a block
   ## when done, tell me "post" (in the claude pane) — i re-read this file, post the survivors, then clean up

   # Comments

   title: <PR / MR title verbatim>
   author: <PR-or-MR author's login>
   pr: <full URL to the PR / MR>

   ---

   <block 1 bullets>

   ---

   <block 2 bullets>

   ---
   ```

   Rules:
   - `# how to use this file` is the first h1. Do NOT stuff a PR-flavored h1 up here (`# PR #14 draft replies — ...` is the wrong shape); the how-to gets the h1 slot.
   - Each instruction below the h1 is its own h2 (`## <instruction>`). One h2 per instruction. Do NOT collapse them into bullets under a single h2 heading, and do NOT keep them as plain-text comment lines (`# - ...`).
   - `# Comments` is the second h1. Everything from `# Comments` down to the end of the file lives inside this section: the three metadata lines AND every `---`-delimited block.
   - Under `# Comments` (with a blank line above), three plain-text metadata lines in this exact order: `title:`, `author:`, `pr:`. No `#` prefix — they're not headings.
   - `title:` is the PR / MR title verbatim (from `gh pr view <N> --json title --jq .title` or `glab mr view --output json | jq -r .title`). If it already starts with a ticket id or prefix, leave it as-is.
   - `author:` is the PR/MR author's GitHub / GitLab login (`gh pr view <N> --json author --jq .author.login` / `glab mr view --output json | jq -r .author.username`). It appears ONCE at the top; do NOT repeat it per-block.
   - `pr:` is the full URL to the PR / MR.
   - The parser reads all three for display; none of them affect posting.

3. Block shape in the draft file. Blocks are separated by `---` on its own line, with **one blank line above AND one blank line below every `---` separator** — no headings, no anchor HTML comments. Each block is a small set of bullet lines. Which bullets are present determines what the parser does with the block. **Bullet order matters: `- answer:` is ALWAYS the last bullet in every block.**

**The blank-line rule around every `---` is mandatory.** It gives every block a visual gap in the editor, keeps horizontal-rule rendering clean in markdown viewers, and stays scannable in nvim / less. When parsing, whitespace-only lines directly adjacent to any `---` are treated as part of the separator and stripped before block-content evaluation. A block whose content (after stripping) contains no `- ` bullets counts as deleted / empty (see step 5 skip rules).

   **New line comment** (about a specific file/line):
   ```
   ---

   - file: <path>:<line>
   - kind: new-line (<SEVERITY> <CONF>% ✓<N>)
   - context: <what we did / decided / verified — display only>
   - shorter_answer: |
       <same point, cut roughly in half, wrapped at 50 cols>
   - answer: |
       <the proposed comment body, wrapped at 50 cols if it exceeds one line>

   ---
   ```

   **Reply to an existing thread** (`- thread_id:` present, `- file:` absent):
   ```
   ---

   - thread_id: <comment id or discussion id>
   - kind: reply
   - comment: <what the reviewer raised — display only, verbatim or paraphrased>
   - context: <what we did about it — display only>
   - shorter_answer: |
       <same reply, cut roughly in half>
   - answer: |
       <the reply body>

   ---
   ```

   **Top-level PR/MR comment** (neither `- file:` nor `- thread_id:`):
   ```
   ---

   - kind: top-level
   - context: <what this comment addresses — display only>
   - shorter_answer: |
       <same point, cut roughly in half>
   - answer: |
       <the comment body>

   ---
   ```

   Bullet semantics:
   - `- file:` → presence signals "new line comment". Accept `path:line` or two separate bullets `- path:` + `- line:`. The commit id is resolved at post time from the PR head SHA (`gh api repos/<owner>/<repo>/pulls/<N> --jq .head.sha`), so no `- commit:` bullet is needed.
   - `- side:` → `RIGHT` (post-change) or `LEFT` (pre-change). Optional; defaults to `RIGHT`.
   - `- thread_id:` → presence signals "reply to existing thread".
   - `- kind:` → display-only, one of `new-line`, `reply`, `top-level`, optionally followed by a parenthesized severity/confidence tag for review batches (`new-line (BLOCKER 95% ✓1)`). The parser derives the actual kind from the presence rules below, not from this bullet.
   - `- comment:` → **only present on reply blocks.** Display-only. On new-line and top-level blocks, do NOT include a `- comment:` bullet — the new comment IS the reply, there's no reviewer statement to quote.
   - `- answer:` → the body that will actually be posted. **ALWAYS the last bullet in the block.** Editable. Set to `SKIP` (case-insensitive), leave empty, or delete the whole block to drop it.
   - `- shorter_answer:` → a **considerably shorter, simpler, human-readable** alternate of `- answer:`. The goal is aggressive compression: drop side notes, drop restated symbol names once the reader can see the anchor line, drop the second half of any "or better..." fork. If the answer is 4-5 lines, aim for 1-2 lines of prose. Plain words over jargon. Half the words is a floor, not the target — go tighter than half when you can. **The parser ignores this bullet.** It exists only so the operator can eyeball two lengths side by side and copy/paste over `- answer:` if the shorter one reads better.
     - **Links (URLs) are always allowed and do not count against the length.** Keep the spec URL from the answer, on its own line at the end, exactly as-is. Don't strip URLs to save characters.
     - Keep the same nouns spelled out ("capabilities" not "caps", "documentation" not "docs"); do NOT trade brevity for slang or abbreviations.
     - If genuinely no shorter version is possible without losing the meaning, write `- shorter_answer: (no shorter version)` and leave `- answer:` as the only draft.
   - `- context:` → display-only. The parser ignores changes to it. Can be multiline (same block-scalar shape as answers below).

   **Multiline bullets (`- answer:`, `- shorter_answer:`, `- context:`).** When the body exceeds ~75 characters, format it as a YAML-style block scalar with the `|` marker, indented, wrapped at a **75-character column limit**:

   ```
   - context: |
       first line wraps at 75 chars max
       second line wraps at 75 chars max

   - shorter_answer: |
       first line wraps at 75 chars max
       second line wraps at 75 chars max

   - answer: |
       first line wraps at 75 chars max
       second line wraps at 75 chars max
   ```

   When the body fits in ≤ 75 chars, keep it inline: `- answer: done.` — same rule for `- context:` and `- shorter_answer:`.

   **Blank line between a multiline bullet and the next bullet.** After the last indented line of any `|` block scalar, insert one blank line before the next `-` bullet. This gives the operator's eye a clean break between the multiline body and the next field, so blocks stay easy to scan while editing. When two consecutive bullets are both single-line, no blank line is required (though harmless if present).

   The 75-char wrap is the standard soft column limit; it keeps the draft file scannable in any tmux pane and matches the typical editor gutter. The parser strips the `|` marker and joins lines with single spaces (preserving intentional blank lines inside the body as paragraph breaks; blank lines BETWEEN bullets are structural whitespace and not part of any bullet's value). Spec URLs at the end of an answer body should sit on their own line to avoid being wrapped mid-URL — URL length does not count against the 75-char limit.

   Kind detection is by bullets present, in this order: `- thread_id:` → reply; else `- file:` → new-line; else → top-level. Two of them present at once is an error; the parser aborts and asks the operator to fix.

   Block index is positional (order of `---`-separated chunks in the file). Since there is no sidecar, deleting a whole block simply removes that entry from the batch. Rearranging blocks is fine (each is self-describing).

3. Open the draft file in a tmux **pane** using the operator's editor. Always split off Claude's pane; never `new-window`. Anchor on `$TMUX_PANE` per the global tmux rules. The direction depends on whether Claude already has a right-side neighbour:

   ```bash
   editor="${VISUAL:-${EDITOR:-nvim}}"

   # Detect whether Claude's pane has anything to its right. Compare the
   # right edge of Claude's pane to the window width; if there's another
   # pane past Claude's right edge (typical: hunk, htop, log tail), split
   # vertically so that neighbour stays at full height. Otherwise split
   # horizontally with the draft claiming 70% on the right.
   pane_info=$(tmux display-message -t "$TMUX_PANE" -p '#{pane_right} #{window_width}')
   claude_right=$(echo "$pane_info" | awk '{print $1}')
   window_width=$(echo "$pane_info" | awk '{print $2}')
   if [ "$claude_right" -lt "$((window_width - 1))" ]; then
     # Something is to the right of Claude → open below.
     tmux split-window -v -l 60% -t "$TMUX_PANE" "$editor /tmp/add-comment-drafts-<PR>-<TS>.md"
   else
     # Nothing to Claude's right → open on the right at 70%.
     tmux split-window -h -l 70% -t "$TMUX_PANE" "$editor /tmp/add-comment-drafts-<PR>-<TS>.md"
   fi
   ```

   Rules:
   - **Never open the draft in a new tmux window.** The operator will not switch windows to review a batch of drafts. The pane keeps everything on one screen.
   - **Default: right-side pane at 70% width** (`-h -l 70%`). The editor gets the bigger share since the operator will be scanning and editing the draft; Claude shrinks to ~30%.
   - **Fallback: split below at 60% height** (`-v -l 60%`) when a right-side pane already exists (typical: `hunk` diff, `htop`, log tail). Preserves the neighbour at full height.
   - **Append, don't spawn a new draft file, on a same-session second invocation.** If a draft file from THIS session already exists (grep `/tmp/add-comment-drafts-<PR>-*` and pick the newest whose timestamp is within the last hour), append the new blocks to that file (parse the existing sidecar, extend it, save both under the same timestamp basename) and reuse the existing pane rather than opening a second one. The operator ends up with a single draft file that grows as findings arrive.

4. Surface a one-line "edit then say 'post'" message in chat, then call `AskUserQuestion` with three options: **Post all** (post every non-SKIP block), **Cancel** (drop the batch), **Skip the bot blocks** (filter `- author:` matching `*[bot]` and post the rest).

5. On "Post", re-read the draft file. Split it on `---` lines into blocks (an empty block between two adjacent `---` counts as "the operator deleted this one"). For each block, apply the body-resolution + skip rules:

   **Body-resolution priority** (which bullet becomes the posted text):
   1. If `- answer:` is present with a non-empty body that isn't `SKIP` → post `- answer:`.
   2. Else if `- shorter_answer:` is present with a non-empty body that isn't `SKIP` and isn't the sentinel `(no shorter version)` → post `- shorter_answer:`. This is the "prefer the shorter one" shortcut — the operator can delete the `- answer:` bullet (or set it to empty/`SKIP`) to opt into the shorter form without hand-copying the body.
   3. Else drop the block.

   **Skip rules** (any one drops the whole block; nothing posts):
   - Block is empty (no bullets between the surrounding `---` lines).
   - BOTH `- answer:` AND `- shorter_answer:` are missing/empty/`SKIP`/`(no shorter version)`. (If only one is present and valid, it wins per the priority above.)

   For every block that survives, determine the post kind from the bullets present (see step 2's "Kind detection" rule): `- thread_id:` → reply; else `- file:` → new-line; else → top-level. Then POST via the matching endpoint from step 6. Record each posted body to `references/examples.md` as usual (record the resolved body — the one that actually posted, not both).

   The draft file is the source of truth. There is no sidecar to fall back to; deleting a block IS the gesture for "don't post this one," deleting only `- answer:` IS the gesture for "post the shorter one," and the parser respects both without further prompting.

6. After the loop, clean up the draft file (`rm -f /tmp/add-comment-drafts-<PR>-<TS>.md`).

A worked example of the file shape:

```
# how to use this file

## each `---`-delimited block is one PR comment to post
## edit `- answer:` to change the body
## set `- answer: SKIP` (or empty the value, or delete the whole block) to drop it
## `- shorter_answer:` is display-only, copy over `- answer:` if you prefer it
## `- context:` is display-only
## `- comment:` (only in reply blocks) is what the reviewer said, display-only
## `- answer:` is ALWAYS the last item in a block
## when done, tell me "post" — i re-read this file, post the survivors, then clean up

# Comments

title: [CXH-1234] Fix partial-failure guard on grant
author: mateoHernandez123
pr: https://github.com/conductorone/baton-example/pull/12

---

- thread_id: 3494400256
- kind: reply
- comment: grant returns 200 even on partial failure, add a guard on errors == []
- context: addressed by 695d6a8. pkg/config/config.yaml:418 now requires members non-empty AND errors empty.
- shorter_answer: (no shorter version)
- answer: done.

---

- thread_id: 3494400267
- kind: reply
- comment: deleting the last Owner returns 400, map it
- context: openapi documents only 204/401/403/404/409/429 for DELETE /members/{id}. live curl returned 409. kept 409, tightened the message.
- shorter_answer: openapi has no 400 here. kept 409 with a wider message.
- answer: |
    no 400 in the openapi. kept 409, expanded the message to cover self / last owner /
    scim.

---

- file: pkg/config/config.yaml:418
- kind: new-line
- context: linked to the customer-outage postmortem in #ops
- shorter_answer: |
    worth a one-line comment here. semantic-patch returns 200 on partial failure, easy
    to lose track of.
- answer: |
    worth a one-line comment above this saying "reject when errors is non-empty,
    semantic-patch returns 200 on partial failure". easy to lose track of
    otherwise.

---
```

Things to notice:
1. `# author:` and `# pr:` appear ONCE in the header, not per-block. Author is the PR/MR author's login.
2. There is no `- commit:` bullet on new-line blocks — the parser resolves the head SHA from the PR at post time.
3. The `- comment:` bullet only appears on **reply** blocks (what the reviewer said). New-line and top-level blocks omit it.
4. `- answer:` is always the LAST bullet in every block.
5. Answers longer than ~50 chars use the YAML `|` block-scalar form, indented, wrapped at a 50-char column limit. Short answers stay inline (`- answer: done.`).
6. `shorter_answer` stays in the same voice (lowercase, plain words, contractions), just tighter. Keep full nouns. "capabilities" not "caps", "documentation" not "docs", "openapi" is fine because it's the schema-file name the reader will recognize.

Everything the parser needs is in the file header + each block's bullets. Rearranging blocks is fine (each block is self-describing). If a block is missing required bullets for its kind (e.g. `- file:` present but no `- answer:` at all), the parser aborts on that block with a clear error and skips it — other blocks still post.

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
- **Line comment anchored on the wrong line.** The anchor is on a line that doesn't demonstrate the issue the comment is about (typical failure: the comment mentions a specific function like `o.client.CreateUser(...)` but the anchor is on an unrelated validation guard several lines earlier because that was the first `+` line in the block). Concrete check before posting: read the anchor line's code, restate what it does in one sentence, then re-read the comment. If they don't naturally connect ("this line does X, comment is about Y where X is Y"), the anchor is wrong. Fix it before the post, not after — a mis-anchored comment surfaces on the wrong construct in the reviewer's UI and looks like an LLM stapling.
- **Bare code identifiers instead of backticks.** Function names, type names, error codes, gRPC codes, field names, package paths all need `` `backticks` `` in the posted body. GitHub renders them as monospace; without backticks they blend into prose and the reader has to squint. See the Voice section's backtick rule.
- **Zsh globbing the `position[...]` brackets in glab.** Quote the whole `-F "position[key]=value"` argument. Unquoted, zsh hits "no matches found" and the curl never runs.

## When NOT to use this skill

- The user wants a long, formal response. Use plain composition.
- The user is accepting the suggestion. Skip the comment, do the code change.
- The user wants a regular code comment in a file. This skill is for PR/MR review comments only.