# Review guidance — what to comment, how to write it

When to read this: at Round 3 of the `hunk` workflow, before deciding what (if anything) to apply.

## Comment scope — only complex flows and difficult paths

**The bar is high.** Default to applying nothing.

### CRITICAL: every note is a call to action OR a call to inaction — never trivia

A Hunk note earns its spot only when it tells the reader ONE of these two things clearly:

1. **"You should change X"** (actionable). Say what to change.
2. **"You don't need to do anything here — and here's what breaks if you touch it."** (inaction). State that no action is needed AND the consequence of reverting or "cleaning up" the line.

If the note doesn't fit one of those two shapes, delete it. Raw facts about the vendor API, the algorithm, the config value — with no "so if you change this, X breaks" — are trivia. The reader can look those facts up. What they cannot look up is which lines are load-bearing.

**CRITICAL: the summary line must state action-or-inaction in plain English.** Terse tag openers (`intentional:`, `heads-up:`, `note:`, `fyi:`) fail this rule — they're jargon that assumes the reader already knows the convention. The summary is the ONE chat-line the reader sees at the anchor point; it has to answer "should I do something?" without them having to open the rationale.

- Actionable summary shapes: `should <X>`, `<X> should be <Y>`, `please <do X>`, `would you mind <X>ing here?`, `suggest: <X>`.
- Inaction summary shapes: `no action needed — <one-line what-this-is>`, `nothing to do here — this is the <feature/fix>`, `leave as-is — <reason>`.

Never lead the summary with a bare jargon tag. If the summary reads "intentional: X" or "heads-up: Y", rewrite it to "no action needed — X" or a similarly plain-English action-tagged form.

**Self-test before applying every non-actionable note**: finish the sentence "if the reader ignores this note and reverts / rewrites the line, ___". If the answer is "the <TICKET> bug returns" or "we widen the access-control boundary" or "the retry path stops working", the note is earned. If the answer is "nothing measurable" or "they'd just have a slightly different constant", it's trivia — cut it.

**Where the consequence lives in the rationale.** Don't append a redundant closing sentence like "reverting this line brings <TICKET> back". Embed the consequence inside the mechanism explanation: describing WHAT the old code would do wrong (`"matching it treated every failure as a duplicate"`) is the consequence, expressed naturally. A separate closer restates what the reader already knows and adds noise. If the mechanism explanation doesn't make the consequence obvious, the mechanism explanation is what needs fixing — not a closer bolted on.

### Apply when

- **Complex flows** — fan-out/await, retry loops with subtle conditions, async patterns, recursion, non-obvious state transitions. One brief shape-of-the-flow note at the entry point ("this fans out N tasks then awaits all, retrying any that return WouldBlock"). Never per-step narration. Still pair with a consequence when the flow's shape is load-bearing ("collapsing this back to a single call re-introduces the race that caused CXH-NNNN").
- **Difficult paths** — a non-obvious invariant the reader has to hold in their head, a subtle ordering requirement, a workaround for a specific bug or platform quirk, a control-flow edge that's easy to misread. Same rule: name the consequence of getting it wrong, not just the fact.

### Do NOT comment on

- Behavioral changes obvious from the diff itself (return-shape changes, new branches a careful reader will catch).
- Cross-file invariants, rollout footguns, test gaps, env-var changes. Those belong in the PR description, not in Hunk.
- Pure renames, signature widening, comment-only changes, generated files.
- Anything a careful read of the function makes obvious.
- Trivia — a note that states a fact the reader could look up (vendor error codes, endpoint names, algorithm names) with no call-to-action and no consequence-if-changed. This is the most common failure mode and the hardest to catch, because trivia notes feel useful when you write them. Apply the self-test above.

## Content — explain the code, not the history of how you got here

**The reviewer may not have your context.** They probably haven't read the ticket, the sibling MR you're mirroring, your pre-flight queries, or the chat where you decided what to do. A note that opens with "intentional: 8 entries here vs 6 in ST DISP-2914" or "mirrors the approach from PR #482" expects all of that as background and gives the reviewer nowhere to land.

**Lead with what the code does.** Plain words. Then, if it's still useful, note why it diverges from a sibling or what the alternative would be.

- **Bad** (assumes context the reviewer doesn't have, jargon-loaded):
  > intentional: 8 entries here vs 6 in ST DISP-2914, no top re-grant block. pre-flight on prod CONFIG showed two legacy grants already COMPLETED on this role, so they get folded in to make the file the single source of truth.

- **Good** (explains the mechanism in plain words, then the divergence):
  > the `WHERE NOT EXISTS` skips any grant_sql that already has a COMPLETED row in the log, so re-running the file is safe and only `galileo_dedup_ro` actually inserts a new PENDING row. the other 7 entries are already COMPLETED in prod and just sit here as a manifest of what the role should hold. (ST DISP-2914 added a separate top-of-file INSERT for `galileo_dedup_ro` to bypass the same guard because it had a stale COMPLETED row from a prior grant+revoke; prod doesn't.)

Self-test before applying: imagine a reviewer who has only the diff in front of them. Does the note tell them what the code does and why? If they'd have to leave Hunk and read another MR, ticket, or chat thread before your note made sense, rewrite it. Comparisons to a sibling are fine, but they go *after* the standalone explanation, not in place of it.

Jargon trap: words like "idempotent guard", "single source of truth", "stale row", "fold in", "manifest" carry meaning *for you* because you just lived through deciding to use them. To a fresh reader they're labels for ideas that haven't been introduced yet. Either name the mechanism in plain words ("WHERE NOT EXISTS skips X") or define the term in the same sentence you use it.

## Tone — short, informal, plain words

When you do apply a comment:

- **Hard length cap.** `summary` is ONE chat-line (~80 chars, no period). `rationale` is one or two short sentences MAX. If you wrote three sentences, delete the third. If the rationale is over 35 words, cut it. Verbosity is the most common failure mode — re-read after writing and cut at least one phrase.
- **No padding.** Cut "this is", "note that", "we have", "in order to", "additionally", "as a result", "such that", "for the purposes of". Cut every "v1 / v2 polish" hedge. Cut every "live-verified / empirically reproduced" boilerplate (the reviewer doesn't need your testing methodology in a code note). Cut every "see also line X" cross-reference unless the cross-reference is the whole point of the note.
- **Plain words.** Write like you'd tell a colleague over chat. Lowercase, contractions, fragments are fine. Skip "moreover", "thus", "ensure that", "deliberately maintains", "asymmetric invariant", "subsequently".
- **No academic phrasing.** Drop "the system MUST", "this REQUIRES that", capitalized RFC verbs. Imperatives don't belong in informational notes (see "Be unambiguous about who you're talking to" below).
- `summary` is a chat-line headline (~80 chars, no period). `rationale` is the "why" in one or two short sentences. Don't restate the summary.

### Length self-test before applying

Read your rationale out loud. If it sounds like a stand-up update or a slack message, you're done. If it sounds like a design doc, cut it in half and re-read. Repeat until it sounds like a slack message.

Concrete examples (each pair is the SAME finding, before/after the cut):

Too long (~50 words, padded):
> "LD's bulk PATCH /api/v2/members returns 200 even when individual members fail (e.g. SCIM-managed member, self-edit). The previous success_condition treated 200 as unconditional success and silently dropped failures. This commit adds a CEL guard on role grant + revoke that requires non-empty members and empty errors."

Right size (~20 words):
> "LD's bulk PATCH returns 200 even on per-member failure. The CEL guard catches the silent-success case via members + errors."

Too long (~60 words, includes methodology):
> "LD's bulk semantic-patch endpoint returns 200 on partial failure with errors:[{memberId: msg}] and the failed memberIDs absent from members[]. has() wraps size() so the expression stays safe if LD ever drops a field. Live-verified: success path empirically exercised; partial-fail was walked against the recorded response shape rather than a live test."

Right size (~20 words):
> "LD returns 200 with errors:[{id:msg}] on partial fail. has() guards size() against missing field. revoke at L452 is the same."

## PR-feedback mode — one short note per addressed reviewer thread

If the caller hands you a `pr_feedback` payload (e.g. `fix-bug` Phase 7b passing the End-of-phase summary, or any skill handing you a JSON file with reviewer threads addressed in this branch), or you detect a PR-feedback context yourself (see "Round 1 — context detection" in `SKILL.md`), attach ONE hunk note per addressed thread in addition to whatever complex-flow / feature-explanation note you'd normally leave.

Each thread becomes one short note anchored on the line of the fix, NOT the line of the original comment. Format:

- **summary** (~80 chars, no period): `<First-name>: <one-line paraphrase of how we fixed it>`. Use the reviewer's first name or login, not their full name — keeps the chat-line short.
- **rationale** (four lines, blank line between each, no padding):
  - Line 1: `fixed: yes — <short clause>` or `fixed: no — <short clause>` — did this branch actually address the comment? First line so the operator sees at a glance whether the thread is resolved. The clause names what the `+` line at THIS anchor does (for `yes`) or why it wasn't a code change (for `no`). This matters because the diff shown is the full PR (`origin/<base>...HEAD`), so the `+` line is the cumulative result, not visibly "your commit" — the `fixed:` clause is what ties the anchor line to the reviewer's thread. Be honest: `yes` ONLY when the resolving change is actually present at this anchor. Use `no` when it's "not a code change" (you're explaining the current code is already correct, or punting to the operator); pair a `no` with a recommended-action naming what's still owed. E.g. `fixed: yes — this line now returns codes.AlreadyExists` / `fixed: no — current code is already correct, needs a reply not a change`.
  - Line 2: `they said: "<comment text — VERBATIM and COMPLETE>"`. Quote the reviewer 1:1: paste their comment exactly as written, do NOT paraphrase, summarize, or truncate it (no `…`). The operator wants to read the real words at the anchor, not your compression of them.
  - Line 3: `recommended action: <shortest possible>` — what the operator still owes on THIS thread, in as few words as possible. E.g. `reply + push`, `reply, then decide on <X>`, `nothing, push`.
  - Line 4: `<permalink to the comment / review / ticket>`.
- **Anchor**: `filePath` + `newLine` of the fix. The caller's payload should carry this; if it only carries the original comment's line, look at the diff and pick the closest `+` line in the same file.

Worked example. PR thread:

> bjorn-c1 on `pkg/config/config.yaml:422`: "Grant uses the bulk semantic-patch endpoint which returns 200 even on partial failure. Add a success_condition guard checking errors == []."

Fix landed at `pkg/config/config.yaml:418`. Hunk note:

```json
{
  "filePath": "pkg/config/config.yaml",
  "newLine": 418,
  "summary": "bjorn: added the CEL guard for 200+errors partial-fail",
  "rationale": "fixed: yes — this line now guards on errors == []\n\nthey said: \"Grant uses the bulk semantic-patch endpoint which returns 200 even on partial failure. Add a success_condition guard checking errors == [].\"\n\nrecommended action: reply + push\n\nhttps://github.com/conductorone/baton-launchdarkly/pull/9#discussion_r1234567890"
}
```

Note: the comment is quoted 1:1 (full, unedited — the operator recognizes their own words), the recommended-action line is as short as it can be, and the link is last so it's one-click reachable. No methodology, no v2-polish hedge, no cross-references, no mechanism essay.

When there's also a complex-flow / feature-explanation note to attach (the existing "explain complex flows" behavior), include BOTH: one Feature Explanation orientation note at the top of the diff plus one note per addressed reviewer thread. The reviewer-thread notes attach at their own anchor lines.

### Be unambiguous about who you're talking to

A Hunk note is read by the reviewer (and possibly the PR author). It's NOT a code comment, NOT a TODO for future-you, and NOT an instruction the reviewer can act on. So avoid bare imperatives like "don't unify these" or "remember to X". The reviewer can't tell whether you're telling them, the PR author, or some hypothetical future maintainer, and they can't act on any of those.

Instead:

- **Explain what the code is doing and why** (informational, the most common case). Phrase as "this works like X because Y", or open with `intentional:` / `heads-up:` if the thing might look like a bug at first glance.
- **Flag something the PR author should change** (actionable). Phrase as "this should be X" or "would [the PR author] mind doing Y here". Say it's a suggestion if it's a suggestion.
- If you find yourself writing an imperative aimed at no one in particular, it's a code comment, not a review note. Drop it.

### Don't narrate the act of reviewing

Write the observation, not a description of the act of writing it. Cut:

- "flagging this so…"
- "noting that…"
- "calling this out because…"
- "just FYI…"
- "for the reviewer's awareness…"

The comment **is** the flag/note/call-out. Saying "I am flagging this" is the same kind of noise as "I am writing this paragraph". A reviewer doesn't need to be told that the comment exists; they're reading it.

If you need a one-word signal that a note is informational and needs no action, the compact options are `intentional:`, `heads-up:`, or just letting the explanation speak for itself.

Direct consequence: if you write a note describing a deliberate-looking-weird thing, end with the *consequence of getting it wrong* rather than meta-talk. "unifying these would break X" is better than "flagging so future-me doesn't unify these."

## Worked example

The diff: an install function checks `paths.mdp_bin()` (in-tree only) while the runtime resolver `paths.resolve_mdp()` accepts in-tree OR `$PATH`. The asymmetry is deliberate.

Bad (formal, jargon, redundant):
> "Install check is in-tree-only; runtime resolve falls back to $PATH. Keep them asymmetric."
> "M.run() short-circuits on paths.mdp_bin() (not mdp_available()) on purpose: :MdPreviewInstall must always produce the self-contained..."

Bad-but-better (informal, but ambiguous; who is "don't unify" aimed at?):
> "install always grabs the in-tree copy; runtime takes whatever's around. don't unify these with `mdp_available()`."

Still bad (meta-narration; "flagging" describes the act of commenting):
> rationale ends with: "flagging so it doesn't look like a bug worth unifying later."

Still too long (correct content, but padded for a simple observation):
> summary: "intentional: install short-circuits on in-tree only, runtime resolver takes in-tree OR $PATH"
> rationale: "the check here is `paths.mdp_bin()`, not `paths.mdp_available()`. if install also short-circuited on a global `mdp`, `:MdPreviewInstall` would silently do nothing for anyone who'd already `go install`'d the binary, so they'd never get the self-contained in-tree copy. `resolve_mdp()` at runtime accepts either, so those users still work without re-installing. unifying the two checks would break the install step for them."

Good (chat-line, length matches complexity):
> summary: "intentional: install checks in-tree only, runtime takes either"
> rationale: "if install short-circuited on global `mdp` too, users with a pre-existing `go install` would never get the in-tree copy. `resolve_mdp()` still handles them at runtime."
