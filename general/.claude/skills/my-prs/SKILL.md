---
name: my-prs
description: >
  Show your in-review Linear tickets alongside their GitHub PRs and each PR's
  merge + approval state, as one compact table: ticket, PR link, merged yes/no,
  approved yes/no, and which reviewers approved. Read-only: never posts, merges,
  resolves, or changes ticket state. Triggers on "/my-prs", "show my prs",
  "my in-review tickets and their PRs", "are my PRs merged", "which of my PRs are
  approved", "who approved my PRs", "my PR approval status", "status of my open
  PRs". Scans every in-review ticket assigned to you across ALL teams by default,
  so a ticket that moved teams is never dropped. Optional arg: a Linear team name
  to narrow the display to one team. Preconditions: the Linear
  MCP, `gh` authed to the account that can see the PRs, and `jq`. To read one PR's
  comments use `show-comments`; to review a PR use `pr-code-review`; to dispatch
  work on these tickets use `auto-new-day`. This skill only reports status.
argument-hint: "[linear-team-name]  (optional; default scans all your teams, pass one to narrow the display)"
---

# my-prs

One table: your in-review Linear tickets, the GitHub PR(s) linked to each, and whether each PR is merged and approved (and by whom). Read-only.

## When to use vs siblings
- **This skill**: a cross-ticket status readout. "where do all my in-review tickets stand, are the PRs merged/approved."
- `show-comments`: dump the comments on ONE PR. `pr-code-review`: produce a review of a PR. `auto-new-day`: the full morning sweep that dispatches work. None of those is a plain "are my PRs merged and approved" list, and this skill never writes.

## Step 0 — Preconditions + config
- Linear MCP tools (`mcp__plugin_linear_linear__*`) reachable, `gh` authenticated, `jq` on `$PATH`. Bail with a one-line error if any is missing.
- If `~/.config/auto-new-day/profile.json` exists, read one optional value from it (best-effort):
  - `.approvers_team` (e.g. `ConductorOne/connector-approvers`) -> used in Step 4 to tag which approvers are official approvers vs anyone else.

  The profile team does NOT scope this skill: the scan is always workspace-wide by assignee (Step 2), so a ticket that migrated teams stays visible. No profile is fine; the approver/other tag is just skipped.

## Step 1 — Resolve your Linear identity
Resolve your Linear user id once and cache it. The MCP's `assignee` filter is flaky, so you need the id to re-verify results:
- Prefer the MCP's own authenticated-user lookup if one is exposed (a `me`/viewer query), so identity doesn't hinge on the local git config.
- Otherwise `list_users` and match your work email (`git config user.email`); keep `me.id`. If the email match finds nothing, say so and stop rather than guessing a user.

## Step 2 — Find your in-review tickets
**Always query workspace-wide by assignee — never scope the query to one team.** A ticket that gets renumbered and moved to another team (e.g. CXH-2467 → CXF-297 on a different team) is still yours and still in review; a team-scoped query silently drops it. The scan is by assignee, so cross-team tickets stay visible.
- `list_issues` with `assignee = me.id` and NO team, keeping only review statuses: a started status whose name contains "review" (case-insensitive). Prefer `state: "In Review"` to narrow server-side when your teams use that standard name; otherwise fetch your assigned issues and filter in-code by the name-contains-"review" rule. This is one query, not one-per-team.
- **Paginate until `hasNextPage == false`** and dedupe by id.
- **Re-verify `assignee.id == me.id` on every result** and drop mismatches (the server-side filter misses sometimes).
- Capture `identifier`, `url`, `title`, `team`, `state/status` per ticket. If none survive, say "no in-review tickets assigned to you" and stop.
- **Optional narrowing (opt-in only):** if `$ARGUMENTS` names a team, filter the workspace-wide results down to that team *after* the scan. The profile team is NOT used to scope the query — it never narrows by default, so an off-team ticket is never hidden unless the operator explicitly asks for one team.

## Step 3 — Resolve the GitHub PR(s) per ticket
- For each ticket, `list_diffs` (Linear attachments) and pull out the GitHub PR URL(s). A ticket can have zero, one, or several.
- Zero PRs -> keep the ticket in the table with `PR = (none yet)`, so an in-review ticket with no PR is visible, not dropped.
- More than one PR -> one table row per PR under the same ticket.

## Step 4 — PR merge + approval state (GitHub)
For each PR URL, one read-only call:
```bash
gh pr view "<pr-url>" --json state,mergedAt,mergedBy,reviewDecision,mergeStateStatus,reviews \
  --jq '{
    merged: (.state == "MERGED"),
    mergedBy: (.mergedBy.login // null),
    decision: .reviewDecision,
    mergeState: .mergeStateStatus,
    approvers: [ .reviews[] ]
      | group_by(.author.login)
      | map(
          (map(select(.state != "COMMENTED")) | sort_by(.submittedAt) | last) as $latest
          | select($latest != null and $latest.state == "APPROVED")
          | $latest.author.login
        )
  }'
```
- `merged` -> the Merged column (`state == "MERGED"`).
- `approvers` -> the logins whose effective review is `APPROVED`. **Ignore `COMMENTED` reviews when deciding**: on GitHub a plain comment left after an approval does NOT revoke it, only a later `CHANGES_REQUESTED` or `DISMISSED` does. So take each author's most recent review that isn't `COMMENTED`; they approve only if that one is `APPROVED`. Empty list -> not approved. (`reviewDecision` is often empty on repos without required-review rules, so don't rely on it for the approver list, only for the `changes requested` label.)
- Keep `decision` (`APPROVED` / `CHANGES_REQUESTED` / empty) and `mergeState` for the summary line.
- Under an `auto-new-day` `AUTO-*` session a write-shim can block even read `gh`; prefix with `AUTO_NEW_DAY_APPROVED=1` and drop the first stderr banner line if present. A normal session needs no prefix.
- If a `gh` call fails (deleted PR, auth), don't crash the whole run: mark that row `PR state: unavailable (<reason>)` and continue.

### Approved-with-an-ask check (run this for any PR that shows approved)
An approval is not merge-ready if the approver attached a request to it. People routinely approve and then say "one thing before merge" or "please also address X" in the same breath, and a bare APPROVED state hides that. So for every approver, look for a review body or a comment they left **at or after** their approval timestamp:
- their approval review's own `body` (`gh pr view <url> --json reviews`),
- their conversation comments (`gh api repos/<o>/<r>/issues/<n>/comments`),
- their inline review-thread comments (`gh api repos/<o>/<r>/pulls/<n>/comments`).

Compare each timestamp to that approver's approval time. If they asked for anything ("open threads worth a pass before merge", "address Felipe's threads first", "one last thing"), the ball is back in the author's court: the PR is approved-but-not-done. Surface it (Step 5) and never treat it as a clean merge.

### Approver tagging (only when `approvers_team` was found in Step 0)
Resolve the team's members once: `gh api "orgs/<org>/teams/<team>/members" --paginate --jq '.[].login'` (split `approvers_team` on `/` into org and team-slug). Then tag each approver login in the Approved-by column: an official approver renders plain, anyone else gets a `(non-approver)` suffix, so an approval that does not actually clear the PR is visible. Skip this tagging silently if the lookup fails.

## Step 5 — Render the table
One row per PR (or per PR-less ticket), grouped so a ticket's rows sit together. Sort: unmerged-and-unapproved first (needs attention), then approved-not-merged, then merged last.

`Ticket | Title | PR | Merged | Approved | Approved by`

- `Ticket`: `[CXH-1234](ticket-url)`. When your results span more than one team, append the team in parens (`[CXF-297](url) (Connector Flux)`) so a ticket that lives on a different team than the rest is obvious at a glance.
- `Title`: short, truncate to ~50 chars.
- `PR`: `[repo#N](pr-url)`, or `(none yet)`.
- `Merged`: `yes` when merged, `no` when not (or `unavailable` on a failed lookup).
- `Approved`: `✅` when the approver list is non-empty, else `no`. When `reviewDecision == CHANGES_REQUESTED`, show `changes requested` instead of a bare `no`. When the approved-with-an-ask check (Step 4) found the approver left a request at/after approving, show `✅ (check: <approver> asked for more)` so an approval that is not actually merge-ready stands out.
- `Approved by`: comma-separated approver logins (with the `(non-approver)` tag from Step 4 when applicable), or `-`.

## Step 6 — Summary line
One line under the table: total tickets, how many PRs, how many merged, how many approved-but-not-merged (ready to merge), how many still need an approval, and any tickets with no PR yet. Call out the ones waiting on you to merge vs waiting on a reviewer.

## Step 6b — Recommended actions table
Close with a small `Recommended actions` table, one row per PR that still needs something, so the next move on each is obvious at a glance. Keep it as small as possible: drop any PR that needs nothing from you (merged, or approved-and-clean waiting only on a reviewer with no ask back to you), and if every PR is done render a single line `Nothing to do.` instead of an empty table.

`PR | Next action`

- `PR`: `[repo#N](pr-url)`.
- `Next action`: the shortest concrete verb phrase for the ball that's in your court, e.g. `address github-actions changes`, `address <reviewer>'s ask, then merge`, `ping <reviewer> for review`, `merge` (approved + clean + you own the merge), `open a PR`. One phrase, no prose.

## Step 7 — "create a new release" (operator command)
When the operator says **"create a new release"** for a merged/approved connector PR shown in the table, run this three-part workflow (this is the one write path in this skill, gated on that explicit phrase):
1. **Cut a release** for the connector(s) of the relevant merged PR(s): `gh release create vX.Y.Z --target main --title "vX.Y.Z" --generate-notes -R ConductorOne/<repo>`. Version = next patch above the latest tag (`gh api repos/ConductorOne/<repo>/tags`); a brand-new axiomatic connector's first release is `v0.0.1`. Always `--generate-notes` (compact per-PR notes, stays under the registry 10k changelog limit), never a bare `git tag && git push`. Full rules: `$HOME/work/.claude/lazy/releases.md` §3 (classic) / §4 (axiomatic).
2. **Move the connector's Linear ticket(s) to `Validation`** (Linear `save_issue` with `state: "Validation"`).
3. **Reassign the ticket(s) to Manuel** (Manuel Traversaro Sasia, id `d5452641-fe73-44a6-bcb1-46d9d2201259`) — he owns connector validation (`save_issue` `assignee`).

This reassign + status move is an explicit operator-triggered action, so it is exempt from the read-only guardrail below and from the auto-new-day no-reassign ban (which only binds the unattended sweep). Reply with the release link(s) plus a one-line confirmation that the ticket(s) moved to Validation under Manuel.

## Guardrails
- **Before merging any PR (whenever the operator says "merge"), run the approved-with-an-ask check (Step 4) on that PR first.** An APPROVED state alone is not a green light: read whatever the approver wrote alongside or after their approval. If they said "open threads worth a pass before merge", "address X first", or any "one last thing", the PR is not clean to merge, hold it and tell the operator what the approver still wants. This skill itself never merges, but this is the gate the operator relies on before they do.
- **Read-only by default. Never** merge, post, resolve, dismiss, or change Linear ticket state. No `gh pr merge` / `gh pr review` / `gh pr comment` / `gh api ... -X POST|PUT|PATCH` / any Linear `save_*`/`update_*`. If the operator wants to act, hand off: `add-comment` (reply), or `auto-new-day` (dispatch work); merging is theirs to trigger. The single exception is Step 7's "create a new release" command, which the operator triggers explicitly.
- Truncate titles; keep the table scannable. Don't paste PR bodies or review text.
