# Git rules

## "Remove from git" = `git rm --cached`

"Remove from git" / "untrack" / "stop tracking" means index only. Use `git rm --cached <path>` (add `-r` for dirs) and add the path to `.gitignore`. Plain `git rm` also deletes the working-tree file; only use it when I say "delete" or "rm".

## PR/MR readiness

Do NOT say "ready for PR/MR", "looks ready", "ready to ship/merge", "you can open the PR/MR", "good to go", "no blockers", or any equivalent unless I ran the change and observed the new behavior end-to-end.

Static checks (build, lint, tests, audits, validation reports) prove the code compiles, not that it works. Pattern-matching the diff is not testing.

If I can't run it end-to-end, say so explicitly before the user opens the PR/MR: "Static checks pass. I have NOT run this end-to-end because <reason>. OK to ship unverified?"

## Commits & PRs

**NEVER** mention Claude or add `Co-Authored-By: Claude` in commit messages or PR descriptions.

## CRITICAL: Never post PR/MR comments without per-comment approval

Drafting is fine; posting (`gh pr comment`, `gh pr review`, `gh api .../comments`, `glab mr note`, etc.) requires me to approve the exact text right before the post. "yes" to a compound question ("apply fix and reply to the bot?") covers code/commit/push only, the comment is a separate gate. Bot replies count.

Before drafting or posting any PR/MR comment, invoke the `add-comment` skill. The skill owns the workflow: confirm, optionally fact-check, post via gh/glab.
