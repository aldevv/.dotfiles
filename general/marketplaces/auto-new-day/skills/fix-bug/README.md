# fix-bug

Multi-agent root-cause-and-fix workflow for any non-trivial bug.

## Args

- `[N1/N2/N3]` — investigator / reviewer / validator counts. Default `12/6/3`.
- `[reference]` — ticket URL, stack trace, PR URL, or free-text description of the symptom.
- `--date <date>` — `today` / `yesterday` / `"june 16"` / ISO. Defaults to today. Drives the resume manifest lookup.
- `--force` — bypass the resume check; always redo the work.
- `--skip-hunk` — skip Phase 7 (Hunk) and the snapshot/manifest write at Phase 9. Used by wrapper skills that own the closing tail.

## What it does

- Phase 0: triage + summarize.
- Phase 1: N1 parallel investigation agents (one hypothesis each).
- Phase 2: synthesize a plan with per-symptom confidence.
- Phase 3: N2 parallel review agents (distinct critique angles).
- Phase 4: revise the plan from reviewer findings.
- Phase 5: orchestrator implements (no agents).
- Phase 6: N3 parallel validation agents.
- Phase 7: open the diff in `/report` with status-marked notes.
- Phase 8: `/lazy-gaps` audit.
- Phase 9 (conditional): per-run snapshot + completion manifest write so a re-dispatch fast-paths to Hunk.

## See also

- `references/dispatch-resume.md` — shared resume contract used by sibling skills.
- `~/.claude/skills/fix-bug-work/` — connector-flavored wrapper.
