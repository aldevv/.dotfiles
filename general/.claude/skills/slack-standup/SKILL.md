---
name: slack-standup
description: Draft my reply for a team's virtual standup thread in Slack, a few short bullets of what I did today, built from my real GitHub and issue-tracker activity. Triggers on "/slack-standup", "standup", "give me a standup", "write my standup", "what do I say in standup", "standup from today's work". Optional args are a day (`yesterday`, `2026-11-10`; default today) and a GitHub owner to scope to. Prints the text for me to paste and never posts to Slack. Not for a weekly report or a PR status table.
argument-hint: "[day] [github-owner]" e.g. `yesterday`, `2026-11-10 my-org` (defaults: today, every owner, or `$STANDUP_GH_OWNER`)
---

# slack-standup

Turns what I actually did today into a short standup reply, in the style people use in a standup thread. Read-only: it prints the text and I paste it myself (Slack writes are forbidden, see `~/.claude/rules/slack.md`).

## Step 1. Resolve the day and scope

No arg means today (local time). Resolve `yesterday` or a date with `date -d`. A second arg (or `$STANDUP_GH_OWNER`) scopes GitHub to one owner. If cwd sits under a project tree whose `CLAUDE.md` names a `gh` account to use, switch to it first (`gh auth switch -u <account>`).

## Step 2. Gather what I did (facts only)

Only things I did that day count. A PR that others touched while I did nothing on it doesn't count.

1. **GitHub:** `scripts/gather.sh <YYYY-MM-DD> [owner]` (relative to this skill's directory). For each PR I touched, it prints whether I opened it or merged it that day, plus my commits, reviews, PR comments and inline replies.
2. **Issue tracker, if one is connected** (a Linear, Jira or similar MCP server): list issues assigned to me and updated that day. Keep only status moves I made that day (picked something up, moved it to review or validation) and issues I created. Skip this step when no tracker is connected.
3. **Local work not on GitHub yet:** if an `auto-new-day` sweep report exists for the day (`$AUTO_NEW_DAY_STATE_DIR/dates/<day>-report.md`, else `state_dir` from `~/.config/auto-new-day/profile.json`), skim it for local-only work worth a line (a fix committed but not pushed). Skip the sweep's own bookkeeping (windows opened, drafts written).

Drop:
- review drafts that were never posted
- sweep or tooling noise
- anything I can't point to a commit, comment, review, PR or status change for

## Step 3. Write the bullets

Match the usual standup-thread style. Examples of the target shape:

```
fixed review comments on the billing service PR
payments: merged the retry PR and moving it to QA
search: new open PR, fixed comments
code reviews
```

```
fixing the API docs PRs #125 and #127
finished load test validation: 9 PASS / 5 FAIL
2 tickets filed for the failures
```

Rules:
- 3 to 6 bullets, one line each. Lead with the project or component name when there is one (`payments:`, `search:`).
- One bullet per piece of work, not per PR. Group a main PR and its companion config or docs PR together.
- Say the outcome in plain words: opened a PR, fixed review comments, merged, moved to QA or validation, released, reviewed.
- Ticket ids and PR numbers only when they help someone find it. No links.
- Teammate reviews collapse into one bullet (`code reviews`, or `reviewed <name>'s PRs`) and appear only if a review or comment was actually posted.
- Optional last bullet for what's next or waiting (`#119 and #122 waiting on reviews`). Leave it out when there's nothing.
- No greeting, no sign-off, no em dashes.

## Step 4. Humanize and print

Run the draft through the `humanize` skill (required for any Slack text, per `~/.claude/rules/writing-style.md`). Then print the final bullets in a plain code block so I can copy them, plus one line under it naming anything left out and why (e.g. "skipped: review drafts, never posted"). Don't post, don't draft into Slack.
