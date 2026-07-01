---
name: auto-pr-ci-fix
description: Single-shot, minimal CI failure fixer for a PR/MR. Spawned by the `pr-watch` PostToolUse hook in a fresh tmux window inside a throwaway git worktree on a `ci-fix-<short_sha>` branch. Trigger on `/auto-pr-ci-fix` (the hook's first user message starts with this), or when the user explicitly asks for "a minimal CI fix", "fix the failing CI on this branch", "the CI watcher fired, fix it". Do NOT invoke manually unless you are inside a `ci-fix-*` worktree spawned by `pr-watch`, the skill assumes the worktree, the throwaway branch, and the context block that the hook injects. Sibling: `auto-pr-comment-fix` handles automated review-bot feedback, not CI red builds.
argument-hint: "The hook injects a context block (URL, Platform, Commit, Failing, Worktree, Fix branch, Main checkout, PR branch, Hook log, Log command). If invoked manually, paste an equivalent block."
---

# auto-pr-ci-fix

You were spawned by the `pr-watch` hook into a fresh git worktree on a throwaway branch `ci-fix-<short_sha>`, created off the exact commit whose CI failed. The operator's main checkout still has the PR branch checked out elsewhere, do NOT switch branches in their checkout and do NOT touch their working tree.

Your job is **one** single, minimal fix attempt. After that, you ask whether to merge and you stop.

## Context block

The first user message after `/auto-pr-ci-fix` contains a block like:

```
URL: <pr/mr url>
Platform: github | gitlab
Commit: <head sha>
Failing: <comma-separated check/job names>
Worktree: <absolute path to your cwd>
Fix branch: ci-fix-<short_sha>
Main checkout: <operator's main checkout dir>
PR branch: <branch checked out in the main checkout>
Hook log: <path to the hook's log>
Log command: <how to fetch failed log lines for one run>
```

Read those values once and refer back to them by name. Don't re-derive them.

## Workflow

1. **Confirm the worktree.** `pwd` should match `Worktree`. `git rev-parse --abbrev-ref HEAD` should print `Fix branch`. If either disagrees, STOP and tell the user, do not start fixing in the wrong place.

2. **Read the common-fixes log FIRST, before any diagnosis.** The log lives at `~/.claude/skills/auto-pr-ci-fix/references/common-fixes.md` and is gitignored (operator-local memory). If the file exists, load it into working memory now so every Signature is in mind before you look at any logs. If the file is missing, skip silently and keep going.

3. **Fetch failed log lines for every failing check/job.** Use `Log command`. GitHub: `gh run view <id> --log-failed | tail -200`. GitLab: `glab ci view <job-id>` or `glab ci trace <job-id>`. Look at the actual error output, not just the job name. As you read the log lines, scan them against the Signatures loaded in step 2 (case-sensitive substring match). If ANY Signature matches, apply that entry's recorded Fix straight away and skip to step 7 (commit); do not categorize, do not diagnose further. If nothing matches, continue to step 4 and (once resolved) create/append per step 9.

4. **Diagnose the root cause.** Apply the SMALLEST possible fix. No refactors, no architecture changes, no unrelated files. If you find a category below, follow it; otherwise treat it as a code-level failure and apply a tight fix.

5. **Categorize.** Three buckets, three different responses:

   a. **Vendor / credentials / external service** (HTTP 401, 403, 404 from a third-party API, "Forbidden", "Unauthorized", "Permission denied", "Failed permission authorization checks", trial-expired banners, OAuth scope errors, expired tokens, IP-allowlist denials, vendor-side 5xx outages, anything where the local code is fine but the secret/credential the CI is using has gone stale).

      Do NOT change code. Instead:
      - Find the operator's `.envrc` (look at `Main checkout/.envrc` first, then walk up the tree). If present, list the variables in it that look like CI-bound credentials (anything that matches a `secrets.*` reference in the workflow file; common shapes: `*_API_KEY`, `*_APP_KEY`, `*_TOKEN`, `*_SECRET`, `*_HOST`, `*_URL`).
      - Compare the workflow file's `env:` block / `with:` block against `.envrc`. If the names match, the CI repo secrets are likely stale — the operator's local creds are the source of truth.
      - If the failing endpoint is one a vendor trial typically restricts, check the project's `CLAUDE.local.md` for trial / credential notes (look for words like "trial", "expired", "rotate", "regenerate").
      - Test the relevant endpoint with the local creds (`curl` with the auth headers from `.envrc`). If local creds work where CI's don't, that confirms stale repo secrets.
      - Report findings to the user with a concrete proposal: "rotate repo secrets `X`, `Y`, `Z` to the values in `<path>/.envrc`". Do NOT rotate them yourself unless the user explicitly says yes — secrets rotation is operator-owned.
      - If the workflow file ALSO hardcodes IDs (entitlement UUIDs, role IDs, user IDs) that belong to the old credential's account, those will also be stale after rotation. Verify each hardcoded ID exists in the new account; if not, propose a workflow edit alongside the secrets rotation.
      - Stop after reporting. Do NOT commit a code change for a credentials failure.

   b. **Flake** (intermittent network blip, sporadic timeout with no clear code-level cause, "could not resolve host", DNS hiccup, vendor outage that's already recovered, a test that's known-flaky on this repo).

      Do NOT edit code, do NOT re-run anything. STOP and tell the user it looks like a flake.

   c. **Genuine code-level failure** (compile error, test assertion, lint error introduced by this PR, missing import, type mismatch, etc.). Apply the smallest fix. One file if possible. No unrelated edits.

6. **Build and test locally** (only for category 5c). Use the project's standard commands: Go = `go build ./... && go test ./... -count=1`; Node = `npm test` or `pnpm test`; Python = `pytest`. If the project has a Makefile / `bin/` target / `.envrc` alias for build+test, prefer that.

7. **Commit on `Fix branch`** with a short imperative message (`fix <thing>`). Stage only the files you actually changed. NEVER `git add -A` or `git add .`.

8. **Ring the tmux bell** (`printf '\a'`) and print a 2-3 sentence summary: what category, what changed (or what was reported without changing), and whether tests pass locally.

9. **Update the common-fixes log if this was novel.** Only when step 3 found no matching entry AND you resolved a real failure in step 5 (either category 5a with an actionable rotate step OR category 5c with a code fix). Skip when: the failure was a step 5b flake (no fix to record), step 3 already matched, or the fix was too repo-specific to help another project.

   If `~/.claude/skills/auto-pr-ci-fix/references/common-fixes.md` does not exist, create it (including the parent `references/` dir if needed) with this exact header, then append the entry after the marker:

   ~~~markdown
   # auto-pr-ci-fix common-fixes log

   Persistent, machine-local memory of resolved CI failures. Gitignored: operator entries are usually work-specific and never travel with dotfiles. The skill reads this file in step 3 and appends to it in step 9. Append-only. Never delete, edit, or reorder entries; if a fix is superseded, add a new entry below and mark the old Fix line `superseded by <date>`.

   ## Entry template

   ```
   ### <date> <short human title>
   Category: <5a credentials | 5c code>
   Signature: <exact unique substring / error code / job name to grep from failed logs>
   Repo hint: <repo name | any | monorepo subpath>
   Pipeline: <workflow name, job name, and workflow file path, e.g. `<Workflow Name>` workflow, `<job_name>` job (`.github/workflows/<file>.yaml`)>
   Fix: <one-line action; for code fixes, name the file and verb>
   Notes: <optional; link to a Linear ticket, vendor status page, or the failing run URL>
   ```

   Match rules: `Signature` is a case-sensitive substring grep against the fetched failed logs; no regex, no fuzzy match. A signature that only fires in one repo must carry a `Repo hint` naming that repo; use `any` when portable. When two entries could match, prefer the newer (later) one.

   ## Entries

   <!-- Append new entries below this line. -->
   ~~~

   Keep entries tight: one signature line, one fix line. If the same category-5a rotation keeps recurring for the same vendor, escalate to the operator (add a Notes line pointing at the ticket) instead of stacking near-duplicate entries.

10. **Ask the user via `AskUserQuestion`** whether to merge `Fix branch` into `PR branch` (and push). If they say yes:
    ```
    git -C <Main checkout> merge --no-edit <Fix branch>
    ```
    On success, follow with `git -C <Main checkout> push`. Report both outputs verbatim. On merge failure (dirty tree in main checkout, conflict, anything else): report the exact git output and STOP. Do NOT retry, do NOT `git merge --abort` and retry, do NOT push. On push failure: report and STOP. Do NOT `--force`. If they say no, leave the fix branch in place.

11. **End your turn.** Do NOT re-run CI. Do NOT loop back waiting for further input.

## Hard rules

- Never open a new PR or MR. Never change reviewers, labels, or assignees.
- Never switch branches in the main checkout. Never rebase, never force-push, never amend.
- The only merge you may perform is the single `git merge --no-edit <Fix branch>` invocation in step 10, only if the user said yes. The only push is the single `git push` from `Main checkout` immediately after that merge succeeds.
- Never touch `vendor/` or other generated files unless that IS the bug.
- Never skip hooks (`--no-verify`) or bypass signing.
- One fix attempt total. After the merge prompt, end your turn.
- The categories above are mutually exclusive. Pick one. Do not "fix" a credentials failure by changing code, do not "verify" a flake by re-running, do not turn a genuine code bug into a credentials report.
- `references/common-fixes.md` is machine-local persistent memory (gitignored, created on first append). Read it in step 3 if it exists; skip the lookup silently if it doesn't. In step 9, create it from the header template above when it's missing, then append. Never delete or reorder existing entries, only append.
