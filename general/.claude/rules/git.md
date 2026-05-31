# Git rules

## "Remove from git" = `git rm --cached`

"Remove from git" / "untrack" / "stop tracking" means index only. Use `git rm --cached <path>` (add `-r` for dirs) and add the path to `.gitignore`. Plain `git rm` also deletes the working-tree file; only use it when I say "delete" or "rm".

## PR/MR readiness

Do NOT say "ready for PR/MR", "looks ready", "ready to ship/merge", "you can open the PR/MR", "good to go", "no blockers", or any equivalent unless I ran the change and observed the new behavior end-to-end.

Static checks (build, lint, tests, audits, validation reports) prove the code compiles, not that it works. Pattern-matching the diff is not testing.

If I can't run it end-to-end, say so explicitly before the user opens the PR/MR: "Static checks pass. I have NOT run this end-to-end because <reason>. OK to ship unverified?"

## Commits & PRs

**NEVER** mention Claude or add `Co-Authored-By: Claude` in commit messages or PR descriptions.
