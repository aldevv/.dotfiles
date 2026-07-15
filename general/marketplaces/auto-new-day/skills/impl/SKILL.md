---
name: impl
description: Generic "do the work" skill the auto-new-day engine dispatches into a tmux window. Takes a GitHub issue URL (implement it from scratch), a PR URL you authored (address the review feedback), or a PR someone else opened on your issue (assess it, then finish the gaps). Works in the already-checked-out repo, makes the change, and commits locally. NEVER pushes, NEVER opens or comments on a PR, NEVER asks a question mid-run (it writes a blocked note and exits instead), per the auto-new-day local-only contract. Triggers when auto-new-day dispatches "/auto-new-day:impl <url>", or when you run it by hand on a single GitHub issue/PR you want worked locally. A domain pack can ship a more specialized skill and point its profile's bucket_skills at that instead.
argument-hint: <github-issue-or-pr-url> [--no-subagents]
---

# impl

The generic worker the auto-new-day engine hands one item to. It runs inside a dispatched tmux window: the bootstrap has already switched the `gh` account, checked out the right branch, set cwd to the repo, and installed the push/PR guards. Your job is to make the change and commit it locally.

## Contract (inherited from auto-new-day, non-negotiable)

- **NEVER push.** No `git push` in any form. Commits stay on the local branch.
- **NEVER open or comment on a PR.** No `gh pr create` / `gh pr comment` / `gh pr review`. The guards block these; do not work around them.
- **NEVER ask the operator anything.** If you are blocked (ambiguous ask, missing context, a real design decision), write one line to `$AUTO_NEW_DAY_DATE_DIR/dispatch/<ITEM>.blocked.md` saying what you could not do and why, finish whatever you safely can, and exit. No prompts, no `read -p`, no waiting.
- **`--no-subagents`** (flag or `NO_SUBAGENTS=1`): do the work sequentially in this session with a `TaskCreate` list instead of spawning parallel subagents. This is the default under an unattended sweep.

## Step 0. Load project memory

Before touching anything, load the operator memory that governs this repo (it lives outside this plugin, so it's on you to read it): `$HOME/CLAUDE.md` (global) and the nearest ancestor `CLAUDE.md` / `CLAUDE.local.md` walking up from cwd. Then consult their `.claude/lazy/*.md` indices and load a file when its **Read when** trigger matches your current step (build, comment, debug, API call, etc.), not up front. These carry the conventions, guardrails, and per-task references your change must follow.

## Step 1. Figure out what you were handed

The argument is a GitHub URL. Classify it:

- **Issue URL** (`/issues/<n>`) → implement it from scratch. You are on a fresh branch for this issue.
- **PR URL you authored** → address the review feedback on it. You are on the PR branch.
- **PR URL someone else authored** (a teammate or a bot opened it on your issue) → assess whether it actually completes the issue and works, then finish the missing pieces as local commits on the PR branch.

Read it: `gh issue view <url> --json title,body,labels,comments` or `gh pr view <url> --json title,body,headRefName,reviews,comments,files`. For a PR, also read the unresolved review threads (`gh api repos/<o>/<r>/pulls/<n>/comments` + the GraphQL `reviewThreads` query for resolved/outdated state) and the diff (`gh pr diff <url>`).

## Step 2. Understand before changing

- Read the issue/PR body and acceptance criteria. Read the surrounding code the ask touches. Match the repo's existing conventions.
- For a review-feedback PR: for each human comment and CHANGES_REQUESTED point, decide the concrete fix. For each unresolved bot finding, first judge real-vs-false-positive; fix the real ones, and note the false positives in your summary (do not post anything).
- For an assess-a-foreign-PR: build + test it, check it against the issue's acceptance criteria, and list what is missing before you touch anything.

## Step 3. Do the work

- Make the smallest change that satisfies the ask. Follow the repo's style and tests.
- Run the repo's build + tests if they exist and are cheap; verify the change does what the issue asked (do not just assume). Fix what you broke.
- Preserve any foreign commits already on the branch, do not rebase them away.

## Step 4. Commit locally, then stop

- Commit with a clear message describing the change. Do NOT push. Do NOT open/refresh a PR.
- Write the completion manifest so a same-day re-dispatch fast-paths instead of redoing the work: `"$AUTO_NEW_DAY_SCRIPTS_DIR/dispatch-done.sh" write --key <ITEM> --outcome <done|partial> --reason "<one line>"` (the bootstrap exports `$AUTO_NEW_DAY_SCRIPTS_DIR`, `$AUTO_NEW_DAY_DATE_DIR`, and the item key).
- Print a short summary to the pane: what you changed, what you verified, any bot findings you judged false, and anything you left for the operator. This summary is what the operator reads in the morning; the diff is on the local branch for them to review and push.

## When you cannot proceed

Write `$AUTO_NEW_DAY_DATE_DIR/dispatch/<ITEM>.blocked.md` with one line on the blocker, do whatever is safely doable (e.g. partial commit + note), record `--outcome partial`, and exit cleanly. The operator handles blockers when they sit down.
