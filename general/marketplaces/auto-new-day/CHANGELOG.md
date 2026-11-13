# Changelog

Newest first. One entry per `.claude-plugin/plugin.json` version; the pre-commit check (`scripts/check-changelog.sh`) refuses a commit that changes plugin files without a version bump and a matching entry here.

**Rollback:** find the commit that set a version with `git log --oneline -S'"version": "<X>"' -- <plugin>/.claude-plugin/plugin.json`, then `git revert <sha>` (or `git checkout <sha> -- <plugin>/<file>` for one file), bump the version, add an entry here, and reinstall (`claude plugin marketplace update <m> && claude plugin update <p>@<m>`).

## 0.1.23 (2026-11-12)
- Removed employer and work-pack references from comments, docs, and examples across scripts, skills, and references (ticket IDs, repo and vendor names, logins, wrapper skill names, `~/work` paths); the code is unchanged.
- `check-domain-neutral.sh` denylist also catches wrapper skill names, more ticket prefixes, SDK type names, and reviewer logins.
- `pr-code-review`: the log-root step resolved scripts from a path that no longer exists; it now uses `${AUTO_NEW_DAY_SCRIPTS_DIR:-${CLAUDE_PLUGIN_ROOT}/scripts}`.

## 0.1.22 (2026-11-12)
- Stop hook: recognize slash-command prompts stored as `<command-name>` tags and skip meta entries, so the check fires on dispatched runs.

## 0.1.21 (2026-11-12)
- Push gate: inside a dispatched window, `AUTO_NEW_DAY_APPROVED=1` no longer lifts `git push` / `gh pr create` alone; the guard needs `$AUTO_NEW_DAY_DATE_DIR/dispatch/<TICKET>.checklist.json` for the exact commit with every item passing (or `operator_approved`). Contract in `scripts/install-guards.sh`.
- New plugin hooks (`hooks/hooks.json`), dispatched windows only: Stop hook blocks a turn that ends by asking the operator to decide; SessionStart hook injects the profile's `session_context_files`, split into chunks under the hook-output cap.
- `new-day` documents both.

## 0.1.20 (2026-11-12)
- `decide-dont-punt.md`: evidence level instead of a percentage; settled forks go in the closing report's `## Decisions made` table.

## 0.1.19 (2026-11-12)
- `pr-code-review`: split verifier results keep a finding only when a confirming verifier reached `reproduced`/`cited` (replaces `NUANCED<60%`).

## 0.1.18 (2026-11-12)
- `pr-code-review`: rule-based approve verdict (first matching rule wins) replaces the `approve_pct` score.

## 0.1.17 (2026-11-12)
- Findings carry an evidence level and `✓N` from `~/.claude/rules/review.md` instead of a confidence percentage; `fix-bug` reports evidence per symptom.

Earlier versions: `git log -- general/marketplaces/auto-new-day`.
