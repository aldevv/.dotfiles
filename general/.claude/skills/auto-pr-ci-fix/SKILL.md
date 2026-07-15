---
name: auto-pr-ci-fix
description: Single-shot, minimal CI failure fixer for a PR/MR. Spawned by the `pr-watch` PostToolUse hook in a fresh tmux window inside a throwaway git worktree on a `ci-fix-<short_sha>` branch. Trigger on `/auto-pr-ci-fix` (the hook's first user message starts with this), or when the user explicitly asks for "a minimal CI fix", "fix the failing CI on this branch", "the CI watcher fired, fix it". Do NOT invoke manually unless you are inside a `ci-fix-*` worktree spawned by `pr-watch`, the skill assumes the worktree, the throwaway branch, and the context block that the hook injects. Sibling: `auto-pr-comment-fix` handles automated review-bot feedback, not CI red builds.
argument-hint: "The hook injects a context block (URL, Platform, Commit, Failing, Worktree, Fix branch, Main checkout, PR branch, Hook log, Log command). If invoked manually, paste an equivalent block."
---

# auto-pr-ci-fix

You were spawned by the `pr-watch` hook into a fresh git worktree on a throwaway branch `ci-fix-<short_sha>`, created off the exact commit whose CI failed. The operator's main checkout still has the PR branch checked out elsewhere, do NOT switch branches in their checkout and do NOT touch their working tree.

Your job is **one** single, minimal fix attempt. After that, you either merge autonomously (matched-signature code fix, pre-approved) or ask whether to merge (novel fix), then stop.

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

3. **Fetch failed log lines for every failing check/job.** Use `Log command`. GitHub: `gh run view <id> --log-failed | tail -200`. GitLab: `glab ci view <job-id>` or `glab ci trace <job-id>`. Look at the actual error output, not just the job name. As you read the log lines, scan them against the Signatures loaded in step 2 (case-sensitive substring match).

   **Signature match, Category `5c code`:** the operator has pre-approved autonomous end-to-end execution for this path. Apply the entry's recorded Fix, then run the autonomous branch in step 3a. Do not categorize, do not diagnose further, do not call `AskUserQuestion`.

   **Signature match, Category `5a credentials`:** run the autonomous rotation branch in step 3b. Rotation is no longer operator-owned once the credential-verification precondition passes; if it fails, fall back to step 5a's report path.

   **No signature match:** continue to step 4 and, once resolved, create/append per step 9.

   **3a. Autonomous branch (matched 5c signature only).** After applying the recorded Fix:
   1. Build and test locally per step 6. If build or tests fail, STOP and report the failure verbatim; do NOT keep trying alternative fixes, do NOT fall through to novel-fix diagnosis.
   2. Commit on `Fix branch` per step 7 (subject: `fix <thing> (auto)`; stage only the files you changed).
   3. Skip step 9 (the entry already exists; do not duplicate).
   4. `git -C <Main checkout> merge --no-edit <Fix branch>`. On failure, report the exact git output and STOP; do NOT retry, do NOT `--abort` and retry.
   5. `git -C <Main checkout> push`. If the operator has a local push guard (e.g. `remote.origin.pushurl` set to a `no-push://...` scheme, or a hook that vetoes push) AND the current tmux session name starts with `AUTO-`, bypass the guard by pushing to the fetch URL directly with `AUTO_NEW_DAY_APPROVED=1 git -C <Main checkout> push <fetch-url> HEAD:<PR branch>`. The `AUTO_NEW_DAY_APPROVED=1` env-var is the operator's documented override contract for `auto-new-day` (harmless on machines that don't use it). Do NOT bypass the guard in non-`AUTO-` sessions. On any other failure, report and STOP; do NOT `--force`.
   6. **Auto-approve gate.** Read the current tmux session name (`tmux display-message -p '#S'` from inside the worktree). If it starts with `AUTO-`, the session is running autonomously and the operator has pre-approved PR/MR approval on matched-signature fixes. Approve the PR/MR now:
      - GitHub: `gh pr review <PR number extracted from URL> --approve --repo <owner>/<repo>` (optionally pass `--body "auto-approved after common-fix push"`).
      - GitLab: `glab mr approve <MR IID> --repo <path>`.
      On approval failure, report and continue to step 7 anyway; do NOT retry, do NOT fall back to a different reviewer command. Skip silently when the session name does NOT start with `AUTO-` (regular operator sessions keep approval manual), or when tmux is not running / the command fails to return a session name. Do NOT approve outside this gate under any circumstances.
   7. Ring the tmux bell (`printf '\a'`) and print a **prominent completion notice** the operator cannot miss. Include: a visible header `AUTONOMOUS COMMON-FIX PUSHED`, the matched Signature verbatim, the entry title from `common-fixes.md`, the new commit sha, the merge/push outputs, and (when the auto-approve gate fired) an `APPROVED` line naming the reviewer command used. Format the header on its own line, all caps, so it stands out in the tmux scrollback.
   8. End your turn. Do NOT invoke `AskUserQuestion`, do NOT re-run CI.

   **3b. Autonomous rotation branch (matched 5a signature only).** Reached ONLY when step 3 already matched an existing 5a entry in `common-fixes.md`; novel 5a failures always go through the operator-owned report path in step 5a. After matching:
   1. **Verify local creds.** Read `Main checkout/.envrc` (walk up if missing). Identify the credential the workflow's `secrets.*` reference maps to. Hit the exact URL that returned 401/403 in the failed log with those local creds. Response MUST be 2xx AND MUST NOT contain the matched Signature substring in the body. If the verification fails, ABORT the autonomous branch and fall through to step 5a's report path; do NOT rotate.
   2. **Recreate fixtures if the entry / `CLAUDE.local.md` documents them.** Run the documented create commands, capture the new resource IDs. On any non-2xx from these creates, ABORT to the report path.
   3. **Rotate the repo secret** with the verified local value. GitHub: `gh secret set <NAME> --repo <owner>/<repo> --body "<value from .envrc>"`. GitLab: `glab variable set <NAME> --repo <path> --value "<value>"`. Rotate ONLY the specific secret named in the workflow's `secrets.*` reference; never bulk-rotate. On failure, report and STOP; do NOT retry.
   4. **Patch the workflow file** on `Fix branch` if step 2 produced new resource IDs (or if the matched entry documents a workflow edit). Stage only the files you changed.
   5. Commit on `Fix branch` (subject: `fix <thing> (auto)`). If step 4 produced no diff (rotation-only), skip the commit and skip steps 6-7's merge/push; then jump to step 8's auto-approve gate and step 9's notice. There's nothing to merge for a rotation-only fix, and CI re-runs pick up the new secret on its own.
   6. `git -C <Main checkout> merge --no-edit <Fix branch>`. On failure, report and STOP.
   7. `git -C <Main checkout> push`. Same guard-bypass behavior as step 3a's push: when the current tmux session name starts with `AUTO-` and a local push guard is in the way, retry with `AUTO_NEW_DAY_APPROVED=1 git -C <Main checkout> push <fetch-url> HEAD:<PR branch>`. On any other failure, report and STOP; do NOT `--force`.
   8. **Auto-approve gate.** Same as step 3a's auto-approve gate: fire only when `tmux display-message -p '#S'` starts with `AUTO-`.
   9. Ring the tmux bell and print the **prominent completion notice**. Header: `AUTONOMOUS COMMON-FIX ROTATED` (rotation-only) or `AUTONOMOUS COMMON-FIX ROTATED + PUSHED` (with workflow edits). Include the matched Signature, entry title, name of the rotated secret, any recreated fixture IDs, commit sha (if any), merge/push outputs (if any), and the `APPROVED` line when the auto-approve gate fired.
   10. End your turn. Do NOT invoke `AskUserQuestion`, do NOT re-run CI.

4. **Diagnose the root cause.** Apply the SMALLEST possible fix. No refactors, no architecture changes, no unrelated files. If you find a category below, follow it; otherwise treat it as a code-level failure and apply a tight fix.

5. **Categorize.** Three buckets, three different responses:

   a. **Vendor / credentials / external service** (HTTP 401, 403, 404 from a third-party API, "Forbidden", "Unauthorized", "Permission denied", "Failed permission authorization checks", trial-expired banners, OAuth scope errors, expired tokens, IP-allowlist denials, vendor-side 5xx outages, anything where the local code is fine but the secret/credential the CI is using has gone stale).

      **Novel 5a is operator-owned.** This step runs only when step 3 found no matching entry. Do NOT rotate any secret and do NOT change code. Instead:
      - Find the operator's `.envrc` (look at `Main checkout/.envrc` first, then walk up the tree). If present, list the variables in it that look like CI-bound credentials (anything that matches a `secrets.*` reference in the workflow file; common shapes: `*_API_KEY`, `*_APP_KEY`, `*_TOKEN`, `*_SECRET`, `*_HOST`, `*_URL`).
      - Compare the workflow file's `env:` block / `with:` block against `.envrc`. If the names match, the CI repo secrets are likely stale — the operator's local creds are the source of truth.
      - If the failing endpoint is one a vendor trial typically restricts, check the project's `CLAUDE.local.md` for trial / credential notes (look for words like "trial", "expired", "rotate", "regenerate").
      - Test the relevant endpoint with the local creds (`curl` with the auth headers from `.envrc`). If local creds work where CI's don't, that confirms stale repo secrets.
      - Report findings to the user with a concrete proposal: "rotate repo secrets `X`, `Y`, `Z` to the values in `<path>/.envrc`". Novel 5a rotation is operator-owned; do NOT rotate on your own even if verification succeeds. Autonomous rotation is only unlocked once a matching 5a entry exists in `common-fixes.md` (step 3b's precondition).
      - If the workflow file ALSO hardcodes IDs (entitlement UUIDs, role IDs, user IDs) that belong to the old credential's account, those will also be stale after rotation. Verify each hardcoded ID exists in the new account; if not, propose a workflow edit alongside the secrets rotation.
      - Stop after reporting. Do NOT commit a code change for a credentials failure. On the NEXT run (once step 9 has appended a 5a entry for this signature), step 3b will handle rotation autonomously.

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

   Keep entries tight: one signature line, one fix line. Do NOT put code comments (`//`, `#`, `/* */`, docstrings) inside any code snippet in an entry; the reasoning is obvious from the surrounding prose, so write the bare call/identifier and let the Fix/Notes text carry the why. If the same category-5a rotation keeps recurring for the same vendor, escalate to the operator (add a Notes line pointing at the ticket) instead of stacking near-duplicate entries.

10. **Novel-fix approval gate.** Only runs when step 3 found no matching signature (matched 5c fixes already merged+pushed in step 3a; matched 5a fixes stopped at the report). Ask the user via `AskUserQuestion` whether to merge `Fix branch` into `PR branch` (and push). If they say yes:
    ```
    git -C <Main checkout> merge --no-edit <Fix branch>
    ```
    On success, follow with `git -C <Main checkout> push`. Same guard-bypass rule as steps 3a/3b's push: when the current tmux session name starts with `AUTO-` and a local push guard blocks the plain command (e.g. `remote.origin.pushurl` set to a `no-push://...` scheme or a hook that vetoes push), retry with `AUTO_NEW_DAY_APPROVED=1 git -C <Main checkout> push <fetch-url> HEAD:<PR branch>`. The operator's explicit "yes" to this prompt covers the guard bypass in `AUTO-` sessions. Non-`AUTO-` sessions do NOT bypass. Report both outputs verbatim. On merge failure (dirty tree in main checkout, conflict, anything else): report the exact git output and STOP. Do NOT retry, do NOT `git merge --abort` and retry, do NOT push. On any other push failure: report and STOP. Do NOT `--force`. If they say no, leave the fix branch in place.

11. **End your turn.** Do NOT re-run CI. Do NOT loop back waiting for further input.

## Hard rules

- Never open a new PR or MR. Never change reviewers, labels, or assignees. PR/MR approval is allowed only via step 3a's or 3b's auto-approve gate (matched signature, current tmux session name starts with `AUTO-`), never anywhere else in this skill.
- Repo secret rotation is allowed only via step 3b's autonomous branch, and only when both (a) the failure matches an existing 5a entry in `common-fixes.md` and (b) the credential-verification precondition on the failing endpoint has passed. Novel 5a failures stay operator-owned per step 5a.
- Never switch branches in the main checkout. Never rebase, never force-push, never amend.
- The only merge you may perform is a single `git merge --no-edit <Fix branch>` invocation, either in step 3a (matched 5c signature, pre-approved) or in step 10 after the user says yes. The only push is the single `git push` from `Main checkout` immediately after that merge succeeds. Exactly one merge+push per run, never both branches.
- Never touch `vendor/` or other generated files unless that IS the bug.
- Never skip hooks (`--no-verify`) or bypass signing.
- One fix attempt total. After the merge prompt, end your turn.
- The categories above are mutually exclusive. Pick one. Do not "fix" a credentials failure by changing code, do not "verify" a flake by re-running, do not turn a genuine code bug into a credentials report.
- `references/common-fixes.md` is machine-local persistent memory (gitignored, created on first append). Read it in step 3 if it exists; skip the lookup silently if it doesn't. In step 9, create it from the header template above when it's missing, then append. Never delete or reorder existing entries, only append.
