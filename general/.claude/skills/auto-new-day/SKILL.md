---
name: auto-new-day
description: Bare-name launcher for the morning-triage engine. Preserves the typed `/auto-new-day` invocation now that the engine lives in a plugin (plugin skills are only reachable as `/auto-new-day:new-day`, which breaks muscle memory). Triggers on "/auto-new-day", "run my morning triage", "do my morning reviews", "check my in-review PRs", "check my assigned issues". All this skill does is hand off to the plugin engine, forwarding any arguments. Do NOT put engine logic here; it lives in the `auto-new-day` plugin's `new-day` skill.
argument-hint: '[<date> | --date <date> | --show [<date>] | --reset <ITEM> | --dry-run | --force | --fast]'
---

# auto-new-day (launcher)

This is a one-hop launcher so the short `/auto-new-day` still works. The real engine is the `new-day` skill in the `auto-new-day` plugin.

When invoked, immediately invoke the plugin engine skill **`auto-new-day:new-day`**, forwarding every argument this launcher received verbatim (`$ARGUMENTS`). Do not do any triage work here, do not re-implement discovery or dispatch, just delegate.

If the `auto-new-day` plugin is not installed/enabled, say so in one line and point the user at `claude plugin install auto-new-day@auto-new-day` (and, for the connector workflow, the `auto-new-day-work` pack). Do not fall back to any local copy.
