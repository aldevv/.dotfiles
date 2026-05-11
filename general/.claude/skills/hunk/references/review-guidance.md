# Review guidance — what to comment, how to write it

When to read this: at Round 3 of the `hunk` workflow, before deciding what (if anything) to apply.

## Comment scope — only complex flows and difficult paths

**The bar is high.** Default to applying nothing.

Apply when:

- **Complex flows** — fan-out/await, retry loops with subtle conditions, async patterns, recursion, non-obvious state transitions. One brief shape-of-the-flow note at the entry point ("this fans out N tasks then awaits all, retrying any that return WouldBlock"). Never per-step narration.
- **Difficult paths** — a non-obvious invariant the reader has to hold in their head, a subtle ordering requirement, a workaround for a specific bug or platform quirk, a control-flow edge that's easy to misread.

Do NOT comment on:

- Behavioral changes obvious from the diff itself (return-shape changes, new branches a careful reader will catch).
- Cross-file invariants, rollout footguns, test gaps, env-var changes. Those belong in the PR description, not in Hunk.
- Pure renames, signature widening, comment-only changes, generated files.
- Anything a careful read of the function makes obvious.

## Tone — short, informal, plain words

When you do apply a comment:

- **Match length to complexity.** A simple observation gets a one-line rationale. A genuinely complex flow can get two or three sentences. Don't pad simple things with caveats, restatements, or background. If the rationale repeats the summary in longer words, cut the rationale.
- **Plain words.** Write like you'd tell a colleague over chat. Lowercase, contractions, fragments are fine. Skip "moreover", "thus", "ensure that", "deliberately maintains", "asymmetric invariant", "subsequently", "in order to".
- `summary` is a chat-line headline (~80 chars, no period). `rationale` is the "why" in one or two sentences. Don't restate the summary.

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
