---
name: pr-comment-fix
description: Single-pass automated reviewer-bot feedback handler for a PR/MR. Spawned by the `pr-watch` PostToolUse hook in a fresh tmux window inside a throwaway git worktree on a `pr-review-fix-<short_sha>` branch when a review bot (github-actions on GitHub, the configured GitLab review bot on GitLab) posts a review with actionable findings tied to HEAD. Trigger on `/pr-comment-fix` (the hook's first user message starts with this), or when the user explicitly asks for "handle the review bot feedback on this PR", "fix the bot's review", "the reviewer bot flagged things, look at them". Do NOT invoke manually unless you are inside a `pr-review-fix-*` worktree spawned by `pr-watch` — the skill assumes the worktree, the throwaway branch, and the context block that the hook injects. Sibling: `pr-ci-fix` handles red CI builds, not review-bot comments.
argument-hint: "The hook injects a context block (URL, Platform, Commit, Blocking, Suggestions, Apply policy, Worktree, Fix branch, Main checkout, PR branch, Review-body file) followed by the review body. If invoked manually, paste an equivalent block + body."
---

# pr-comment-fix

You were spawned by the `pr-watch` hook into a fresh git worktree on a throwaway branch `pr-review-fix-<short_sha>`, created off the exact commit the bot reviewed. The operator's main checkout still has the PR branch checked out elsewhere — do NOT switch branches in their checkout and do NOT touch their working tree.

Your job is **one** single, evidence-driven pass on the bot's findings. The bot is often wrong. Verify before fixing. After one pass, you ask whether to merge and you stop.

## Context block

The first user message after `/pr-comment-fix` contains a header block, then the review body:

```
URL: <pr/mr url>
Platform: github | gitlab
Commit: <head sha>
Blocking: <int>      # number of blocking findings the bot flagged
Suggestions: <int>   # number of non-blocking suggestions
Apply policy: <text> # how to handle findings the bot flagged (see below)
Worktree: <absolute path to your cwd>
Fix branch: pr-review-fix-<short_sha>
Main checkout: <operator's main checkout dir>
PR branch: <branch checked out in the main checkout>
Review body file: <path to a .md file containing the review body verbatim>
---
<review body inline>
---
```

Read those values once and refer back to them by name. Don't re-derive them.

## Apply policy

The hook computes the policy from `Blocking`/`Suggestions`:

- **Blocking > 0**: apply ALL surviving findings (blocking AND suggestions) in one pass, no per-finding confirmation.
- **Blocking == 0, Suggestions > 0**: for EACH surviving finding, use `AskUserQuestion` BEFORE making any change. Group closely related findings into one question if helpful; otherwise one question per finding. Only apply findings the user approves.

The exact policy text is in the context block — defer to it if it disagrees with this summary.

## Workflow

1. **Confirm the worktree.** `pwd` should match `Worktree`. `git rev-parse --abbrev-ref HEAD` should print `Fix branch`. If either disagrees, STOP and tell the user.

2. **Read the review body** (inline in the context block, also saved to `Review body file`). Identify each distinct finding. Read the cited code locations in the worktree before doing anything else.

3. **VERIFY EVERY FINDING BEFORE TOUCHING CODE.** The investigation is mandatory, not optional, even for findings that "look obvious". Skipping it is the failure mode this skill exists to prevent. Treat each finding as a *claim*, not a fact. Run investigations in parallel across findings (one tool message with multiple calls) whenever they're independent.

   For each finding, pick the right investigation mode based on scope:

   - **OUTSIDE the source code** (vendor API behavior, SDK/library docs, external service contract, protocol semantics, "feature X isn't supported", error-code meanings, scope/permission requirements, anything that requires looking up documentation we don't own): invoke the `/investigate` skill to research the claim online. Group related claims that share the same docs target into one investigation; otherwise one investigation per claim.

   - **INSIDE the source code** (logic bug, dead code, wrong call, missing check, naming, control flow, mishandled error, anything answerable by reading this repo): spawn parallel `Explore` agents to independently verify the claim against the actual code. Size the fan-out by complexity:
     - **3 agents** for SIMPLE findings (single function, narrow scope, one file, obvious to confirm or refute)
     - **6 agents** for MEDIUM findings (multi-file change, cross-cutting concern, requires tracing a handful of callers)
     - **12 agents** for VERY COMPLEX findings (architectural claim, deep call graph, subtle invariant, contested behavior, anything where you'd want a quorum before believing the bot)

   Each Explore agent reports independently. A finding survives only if the investigation confirms it; if the evidence contradicts the bot, mark the finding as a **phantom** and disqualify it.

4. **Classify surviving findings** as either:
   - (a) **CLEAR** — the fix is obvious, low-risk, and doesn't require a judgment call.
   - (b) **AMBIGUOUS** — multiple reasonable fixes, design tradeoff, or insufficient context.

5. **Apply per the Apply policy** on surviving findings. Build/test locally (Go: `go build ./... && go test ./... -count=1`; Node/Python/etc.: the project's standard commands).

6. **Commit on `Fix branch`.** Separate small commits per finding is fine, or one cohesive commit. Stage only files you actually changed. NEVER `git add -A` or `git add .`.

7. **Ring the tmux bell** (`printf '\a'`) and print a short summary:
   - which findings you investigated and how (which used `/investigate`, which used 3 / 6 / 12 `Explore` agents and why)
   - which findings were DISQUALIFIED as phantoms (with the evidence that refuted them)
   - which SURVIVING findings were CLEAR vs. AMBIGUOUS
   - why each AMBIGUOUS item is ambiguous
   - what you actually changed

8. **Ask the user via `AskUserQuestion`** what to do with `Fix branch`. Offer three options:
   - (a) merge into `PR branch` AND push
   - (b) merge only (no push)
   - (c) leave the fix branch in place

   If merge: `git -C <Main checkout> merge --no-edit <Fix branch>`. On success and option (a), follow with `git -C <Main checkout> push`. Report both outputs verbatim. On merge failure (dirty tree, conflict, anything else): report exact git output and STOP. Do NOT retry, do NOT `git merge --abort` and retry, do NOT push. On push failure: report and STOP. Do NOT `--force`.

9. **End your turn.** Do NOT loop back waiting for further input.

## Hard rules

- NEVER fix a finding you haven't investigated. Step 3 is mandatory.
- Treat every finding as a claim, not a fact. If the investigation refutes it, say so explicitly in the summary instead of "fixing" a phantom.
- Push only when option (a) was selected in step 8, or when the operator separately tells you to push. Never auto-push as a default wrap-up. If the operator says "push" after the fact, run `git -C <Main checkout> push` from the main checkout on the PR branch.
- One pass only. After the merge prompt, end your turn.
- Never switch branches, never force-push, never rebase, never amend, never `git add -A`.
- The only merge is the single `git merge --no-edit <Fix branch>` invocation in step 8, only if the user said yes.
- Never skip hooks (`--no-verify`) or bypass signing.
- Never touch `vendor/` or generated files unless that IS the fix.
- Output: under 200 words at the end, summarize what you changed, whether the merge into `PR branch` ran, and whether you pushed (only if the operator asked).
