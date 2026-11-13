# Changelog

Newest first. One entry per `.claude-plugin/plugin.json` version; the pre-commit check (`scripts/check-changelog.sh`) refuses a commit that changes plugin files without a version bump and a matching entry here.

**Rollback:** find the commit that set a version with `git log --oneline -S'"version": "<X>"' -- <plugin>/.claude-plugin/plugin.json`, then `git revert <sha>` (or `git checkout <sha> -- <plugin>/<file>` for one file), bump the version, add an entry here, and reinstall (`claude plugin marketplace update <m> && claude plugin update <p>@<m>`).

## 0.1.25 (2026-11-13)
- New `scripts/prs-status-tray` (pystray): a speech-bubble tray icon, green while `prs-status.timer` is on and grey when off. Its menu turns the timer on/off, runs a check now, opens the log, and lists each open PR with who commented last (click opens the PR). `--install` links it into `~/.local/bin`.
- `prs-status` stores `lastHumanBy` per PR; a plain `prs-status` run (no flags) is now read-only, so a manual check can't swallow events before the timer routes them.

## 0.1.24 (2026-11-13)
- New `scripts/prs-status`: every 15 min (`prs-status.timer`, weekdays 06:00 to 21:00 in the profile `tz`) it snapshots your open PRs and routes new human comments/reviews, CI turning red, or a new conflict. The live claude window already on that PR gets a message (checked that it went busy); otherwise a new `AUTO-inreview` window runs `bucket_skills.inreview --recheck`. A failed dispatch is retried next tick.
- `launch-auto-new-day.sh --install` also installs and enables `prs-status.timer` and links `~/.local/bin/prs-status`.
- `new-day` Step 8 runs `prs-status --baseline` so the timer only reacts to activity after the sweep.
- `gh api` list calls for PR comments / reviews / commits now page through everything (`--paginate --slurp` + `jq add`). GitHub pages at 30, so a busy PR silently dropped its newest reviews; `pr-code-review` reads the head SHA from `gh pr view --json headRefOid` instead of `commits[-1]`.

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
