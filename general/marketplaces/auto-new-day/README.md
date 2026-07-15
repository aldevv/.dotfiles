# auto-new-day

Morning triage for your work. One sweep discovers what's assigned to you, classifies it, and fans the actionable items out to child agents that do the work and commit locally (never push). You sit down later and read the results.

This is the generic engine. It's GitHub-based by default and knows nothing domain-specific: what it discovers, how it classifies, and which skill it dispatches all come from a **dispatch profile** (`profiles/default.json`). Point it at your repos, or install a domain pack (like `auto-new-day-work`) that supplies its own profile and skills.

## Status

Engine + `/impl` skill authored, all 16 scripts ported and profile-driven (state dir, working root, approvers, and paths come from env/profile; no domain knowledge baked in). Not yet run end-to-end. See the build plan at `~/work/.claude/skills/auto-new-day/PLUGIN-SPLIT-PLAN.md`.

## Install (once the engine lands)

```bash
claude plugin marketplace add ~/marketplaces/auto-new-day
claude plugin install auto-new-day@auto-new-day
```

## Configure

Edit `profiles/default.json` (or point `$AUTO_NEW_DAY_PROFILE` / `~/.config/auto-new-day/profile.json` at your own): set `discovery.repos`, `working_root`, and optionally `approvers`. The `guards` block keeps children commit-only.
