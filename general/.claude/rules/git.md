# Git rules

## "Remove from git" = `git rm --cached`

"Remove from git" / "untrack" / "stop tracking" means index only. Use `git rm --cached <path>` (add `-r` for dirs) and add the path to `.gitignore`. Plain `git rm` also deletes the working-tree file; only use it when I say "delete".

## PR/MR readiness

Do NOT say "ready for PR/MR", "ready to ship", "good to go", or any equivalent unless I ran the change and observed the new behavior end-to-end. Static checks (build, lint, tests, audits) prove the code compiles, not that it works.

If I can't run it end-to-end, say so before the user opens the PR/MR: "Static checks pass. I have NOT run this end-to-end because <reason>. OK to ship unverified?"

## Commits & PRs

**NEVER** mention Claude or add `Co-Authored-By: Claude` in commit messages or PR descriptions.

## PR descriptions outside the work folder

For PRs in repos OUTSIDE `~/work` / `$WORK` (personal projects, OSS contributions, dotfiles, etc.):

1. **Check for a PR template first.** Look for, in order: `.github/PULL_REQUEST_TEMPLATE.md`, `.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE/*.md`, `docs/pull_request_template.md`, `PULL_REQUEST_TEMPLATE.md` at repo root. If any exists, fill it section-by-section instead of writing free-form prose. The template wins over any custom shape this rule otherwise suggests.
2. **If no template exists**, the body MUST include a short **Why** section in addition to the one-line outcome.
3. **Length discipline applies to both shapes.** Each filled template section and the Why line stay as short as possible: one short phrase or sentence per section, never more. The Why answers "why was this change made" in plain language (motivation, problem solved, user need), not implementation notes.

Inside `~/work` the rules in `~/work/.claude/lazy/gh.md` apply instead: no Why section, no template-fill (work PRs do not use templates). A work-scoped rule may override this section locally.

## CRITICAL: Never post PR/MR comments without per-comment approval

Drafting is fine; posting (`gh pr comment`, `gh pr review`, `gh api .../comments`, `glab mr note`) requires per-comment approval right before the post. "yes" to a compound question covers code/commit/push only; the comment is a separate gate. Bot replies count.

**Before drafting OR posting any PR/MR comment you MUST invoke the `add-comment` skill. This is not optional, and it applies even when I only ask for a draft.** Do NOT hand-write a reply as freehand chat prose. `add-comment` owns the draft format, the optional fact-check, and the post gate; drafting a comment any other way is a rule violation.

## CRITICAL: "draft" is not "post"

When I say "draft" / "draft a comment" / "draft this" / "draft a reply" / "draft for <X>", invoke the `add-comment` skill to produce the draft (draft-only mode), which surfaces the draft for me, then stop. Do NOT skip the skill and type the reply inline yourself. No `gh` / `glab` posting, no `AskUserQuestion` with a "Post it" option, no examples-log append. The post phase begins only when I separately say "post" / "post it" / "send it" / equivalent. Bundling them (drafting + post-option AskUserQuestion in one move) cuts me out of the gate I asked for.
