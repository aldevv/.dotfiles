# Git rules

## "Remove from git" = `git rm --cached`

"Remove from git" / "untrack" / "stop tracking" means index only. Use `git rm --cached <path>` (add `-r` for dirs) and add the path to `.gitignore`. Plain `git rm` also deletes the working-tree file; only use it when I say "delete".

## PR/MR readiness

Do NOT say "ready for PR/MR", "ready to ship", "good to go", or any equivalent unless I ran the change and observed the new behavior end-to-end. Static checks (build, lint, tests, audits) prove the code compiles, not that it works.

If I can't run it end-to-end, say so before the user opens the PR/MR: "Static checks pass. I have NOT run this end-to-end because <reason>. OK to ship unverified?"

## Commits & PRs

**NEVER** mention Claude or add `Co-Authored-By: Claude` in commit messages or PR descriptions.

## CRITICAL: Never post PR/MR comments without per-comment approval

Drafting is fine; posting (`gh pr comment`, `gh pr review`, `gh api .../comments`, `glab mr note`) requires per-comment approval right before the post. "yes" to a compound question covers code/commit/push only; the comment is a separate gate. Bot replies count.

Before drafting or posting any PR/MR comment, invoke the `add-comment` skill.
