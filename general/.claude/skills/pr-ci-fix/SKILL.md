---
name: pr-ci-fix
description: Single-shot, minimal CI failure fixer for a PR/MR. Spawned by the `pr-watch` PostToolUse hook in a fresh tmux window inside a throwaway git worktree on a `ci-fix-<short_sha>` branch. Trigger on `/pr-ci-fix` (the hook's first user message starts with this), or when the user explicitly asks for "a minimal CI fix", "fix the failing CI on this branch", "the CI watcher fired, fix it". Do NOT invoke manually unless you are inside a `ci-fix-*` worktree spawned by `pr-watch` — the skill assumes the worktree, the throwaway branch, and the context block that the hook injects. Sibling: `pr-comment-fix` handles automated review-bot feedback, not CI red builds.
argument-hint: "The hook injects a context block (URL, Platform, Commit, Failing, Worktree, Fix branch, Main checkout, PR branch, Hook log, Log command). If invoked manually, paste an equivalent block."
---

# pr-ci-fix

You were spawned by the `pr-watch` hook into a fresh git worktree on a throwaway branch `ci-fix-<short_sha>`, created off the exact commit whose CI failed. The operator's main checkout still has the PR branch checked out elsewhere — do NOT switch branches in their checkout and do NOT touch their working tree.

Your job is **one** single, minimal fix attempt. After that, you ask whether to merge and you stop.

## Context block

The first user message after `/pr-ci-fix` contains a block like:

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

1. **Confirm the worktree.** `pwd` should match `Worktree`. `git rev-parse --abbrev-ref HEAD` should print `Fix branch`. If either disagrees, STOP and tell the user — do not start fixing in the wrong place.

2. **Fetch failed log lines for every failing check/job.** Use `Log command` — GitHub: `gh run view <id> --log-failed | tail -200`. GitLab: `glab ci view <job-id>` or `glab ci trace <job-id>`. Look at the actual error output, not just the job name.

3. **Diagnose the root cause.** Apply the SMALLEST possible fix. No refactors, no architecture changes, no unrelated files. If you find a category below, follow it; otherwise treat it as a code-level failure and apply a tight fix.

4. **Categorize.** Three buckets, three different responses:

   a. **Vendor / credentials / external service** (HTTP 401, 403, 404 from a vendor API, "Forbidden", "Unauthorized", "Permission denied", "Failed permission authorization checks", trial-expired banners, OAuth scope errors, expired tokens, IP-allowlist denials, vendor-side 5xx outages, anything where the connector code is fine but the secret/credential the CI is using has gone stale).

      Do NOT change code. Instead:
      - Find the operator's `.envrc` (look at `Main checkout/.envrc` first, then walk up the tree). If present, list the variables in it that look like CI-bound credentials (anything that matches a `secrets.*` reference in the workflow file — common names: `BATON_*`, `*_API_KEY`, `*_APP_KEY`, `*_TOKEN`, `*_SITE`, `*_HOST`).
      - Compare the workflow file's `env:` block / `with:` block against `.envrc`. If the names match, the CI repo secrets are likely stale — the operator's local creds are the source of truth.
      - If the failing endpoint is one a vendor trial typically restricts, check the project's `CLAUDE.local.md` for trial / credential notes (look for words like "trial", "expired", "rotate", "regenerate").
      - Test the relevant endpoint with the local creds (`curl` with the auth headers from `.envrc`). If local creds work where CI's don't, that confirms stale repo secrets.
      - Report findings to the user with a concrete proposal: "rotate repo secrets `X`, `Y`, `Z` to the values in `<path>/.envrc`". Do NOT rotate them yourself unless the user explicitly says yes — secrets rotation is operator-owned.
      - If the workflow file ALSO hardcodes IDs (entitlement UUIDs, role IDs, user IDs) that belong to the old credential's account, those will also be stale after rotation. Verify each hardcoded ID exists in the new account; if not, propose a workflow edit alongside the secrets rotation.
      - Stop after reporting. Do NOT commit a code change for a credentials failure.

   b. **Flake** (intermittent network blip, sporadic timeout with no clear code-level cause, "could not resolve host", DNS hiccup, vendor outage that's already recovered, a test that's known-flaky on this repo).

      Do NOT edit code, do NOT re-run anything. STOP and tell the user it looks like a flake.

   c. **Genuine code-level failure** (compile error, test assertion, lint error introduced by this PR, missing import, type mismatch, etc.). Apply the smallest fix. One file if possible. No unrelated edits.

5. **Build and test locally** (only for category 4c). Use the project's standard commands: Go = `go build ./... && go test ./... -count=1`; Node = `npm test` or `pnpm test`; Python = `pytest`. If the project has a Makefile / `bin/` target / `.envrc` alias for build+test, prefer that.

6. **Commit on `Fix branch`** with a short imperative message (`fix <thing>`). Stage only the files you actually changed. NEVER `git add -A` or `git add .`.

7. **Ring the tmux bell** (`printf '\a'`) and print a 2-3 sentence summary: what category, what changed (or what was reported without changing), and whether tests pass locally.

8. **Ask the user via `AskUserQuestion`** whether to merge `Fix branch` into `PR branch` (and push). If they say yes:
   ```
   git -C <Main checkout> merge --no-edit <Fix branch>
   ```
   On success, follow with `git -C <Main checkout> push`. Report both outputs verbatim. On merge failure (dirty tree in main checkout, conflict, anything else): report the exact git output and STOP. Do NOT retry, do NOT `git merge --abort` and retry, do NOT push. On push failure: report and STOP. Do NOT `--force`. If they say no, leave the fix branch in place.

9. **End your turn.** Do NOT re-run CI. Do NOT loop back waiting for further input.

## Hard rules

- Never open a new PR or MR. Never change reviewers, labels, or assignees.
- Never switch branches in the main checkout. Never rebase, never force-push, never amend.
- The only merge you may perform is the single `git merge --no-edit <Fix branch>` invocation in step 8, only if the user said yes. The only push is the single `git push` from `Main checkout` immediately after that merge succeeds.
- Never touch `vendor/` or other generated files unless that IS the bug.
- Never skip hooks (`--no-verify`) or bypass signing.
- One fix attempt total. After the merge prompt, end your turn.
- The categories above are mutually exclusive. Pick one. Do not "fix" a credentials failure by changing code, do not "verify" a flake by re-running, do not turn a genuine code bug into a credentials report.
