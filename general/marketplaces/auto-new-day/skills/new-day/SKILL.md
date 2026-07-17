---
name: new-day
description: Morning triage engine. Discovers the work assigned to you on GitHub (issues + PRs across a configured repo list), classifies each item into four buckets, and fans the actionable ones out to tmux windows where a child claude does the work, commits locally, and NEVER pushes or opens a PR. You read the results later. Buckets, approvers, repos, and the dispatched skill all come from a dispatch profile (no domain knowledge is hardcoded). Triggers on "/auto-new-day", "run my morning triage", "check my in-review PRs", "check my assigned issues", "any new comments on my PRs", "did anyone approve my PRs", "do my morning reviews". Do NOT trigger for a single named PR (use a direct review), or to pick from a team backlog. This is the generic engine; a domain pack (e.g. auto-new-day-work) can supply its own profile + skills on top.
argument-hint: '[<date> | --date <date> | --show [<date>] | --reset <ITEM> | --dry-run | --force | --fast]'
---

# auto-new-day (engine)

Triage your open GitHub work in one unattended pass and dispatch the actionable items to tmux windows. This is the domain-neutral engine: everything specific to a person or project comes from a **dispatch profile**, and the ticket source is GitHub (`gh`), not any one tracker.

## Project memory (in force for the engine AND every dispatched child)

This skill runs from a plugin cache dir, so state it plainly: the engine and every child it spawns operate under the operator's memory files, and MUST consult them:

- `$HOME/CLAUDE.md` (global) plus the nearest ancestor project `CLAUDE.md` / `CLAUDE.local.md` walking up from the working dir. Read them before classifying or dispatching.
- Their `.claude/lazy/*.md` indices (`$HOME/CLAUDE.md` → `~/.claude/lazy/`; a project file → its sibling `.claude/lazy/`). Load a lazy file when its **Read when** trigger matches the current step; don't bulk-load. Each dispatched child inherits this via its cwd (the repo under `working_root`), so it picks up the project `CLAUDE.md` automatically, and the worker skill loads the triggered lazy files.

## Profile resolution (do this first)

Load the active profile once, at the top, before anything else:

1. `$AUTO_NEW_DAY_PROFILE` if set (a path to a profile JSON).
2. else `~/.config/auto-new-day/profile.json` if it exists (a domain pack's `setup` writes this).
3. else `${CLAUDE_PLUGIN_ROOT}/profiles/default.json` (the built-in GitHub profile).

Profile fields:

- `working_root` — dir where repo checkouts live (branches get checked out here). `~/src`, `~/work`, etc.
- `state_dir` — where sweep state lives (`state.json`, `dates/`, `done/`, `markers/`, `guards/`, `weekly/`). Exported as `AUTO_NEW_DAY_STATE_DIR`; env wins, else this, else `~/.local/state/auto-new-day`. Set it to an existing state dir (e.g. `~/work/.auto-new-day`) to reuse prior dedupe/resume history. A leading `~` is expanded.
- `tz` — IANA timezone for the weekly-report day + the systemd timer's `OnCalendar` (empty = system local time). Read by `launch --install` and `weekly-report.sh`.
- `gh_account` — the `gh` auth account to use (`gh auth switch -u <acct>`), or null for the current one.
- `ticket_source` — `"github"` for this engine. (`"linear"` is reserved for a domain pack that overrides discovery.)
- `discovery` — `{ assignee, repos[], issue_states[], pr_states[], max_pr_age_days? }`. `repos` is the list of `OWNER/REPO` (or globs under `working_root`) the sweep scans. `assignee` is usually `@me`. `max_pr_age_days` (optional, 0/absent = no cap) drops teammate-review (`inreview-others`) PRs opened more than that many days ago, UNLESS you engaged with the PR before it crossed that age (see `triage.sh` `pr-too-old`).
- `buckets` — prose classification rules for `inreview` / `inprogress` / `inreview-others` / `ready-to-merge`. The engine reads these as the definition of each bucket.
- `bucket_skills` — `{ bucket -> slash-command }` the engine dispatches per bucket. Default: `/auto-new-day:impl` for all dispatched buckets. `ready-to-merge` has none (plain shell). A value may also be a label-routing map (see "bucket_skills map form" under the Linear backend).
- `review_chain` — extra skills a review window runs before the main review skill (generic `[]`).
- `approvers` — GitHub logins whose APPROVED review moves a PR to `ready-to-merge` and clears it from the teammate-review candidate set.
- `caps` — `{ review_prs_per_sweep }` (default 5).
- `guards` — `{ push, pr_create, pr_comment, merge }`, all `"blocked"` by default. Drives which guard machinery each bucket gets. `merge` also accepts `"auto-on-clean-approval"`: Step 7d then auto-merges an approved PR that passes the clean-approval check instead of parking a shell (see Step 7d). Absent or `"blocked"` keeps the never-merge default.

Resolve paths + export the profile values the helper scripts read, once at the top:

```bash
export AUTO_NEW_DAY_SCRIPTS_DIR="${CLAUDE_PLUGIN_ROOT}/scripts"
export AUTO_NEW_DAY_STATE_DIR="${AUTO_NEW_DAY_STATE_DIR:-<profile.state_dir, ~-expanded, else $HOME/.local/state/auto-new-day>}"
# from the resolved profile JSON:
export AUTO_NEW_DAY_WORKING_ROOT="<profile.working_root>"
export AUTO_NEW_DAY_APPROVERS="<profile.approvers, space-joined>"          # e.g. "btipling johnallers ggreer"
export AUTO_NEW_DAY_APPROVERS_NAME_RE="<profile.approvers_name_re or empty>"
export AUTO_NEW_DAY_MAX_PR_AGE_DAYS="<profile.discovery.max_pr_age_days or 0>"  # 0 = no age cap
SCRIPTS="$AUTO_NEW_DAY_SCRIPTS_DIR"
STATE_DIR="$AUTO_NEW_DAY_STATE_DIR"
[ -n "<profile.gh_account>" ] && gh auth switch -u "<profile.gh_account>"
```

Every `dates/`, `done/`, `markers/`, `guards/`, `weekly/`, and `state.json` path derives from `$STATE_DIR`. `triage.sh`, `reset-ticket.sh`, and `snapshot-inrepo.sh` read `AUTO_NEW_DAY_WORKING_ROOT` + `AUTO_NEW_DAY_APPROVERS` (`triage.sh` also reads `AUTO_NEW_DAY_MAX_PR_AGE_DAYS`); the launcher reads `AUTO_NEW_DAY_SLASH` / `AUTO_NEW_DAY_TZ`.

## CRITICAL: the sweep itself NEVER blocks on a question

The sweep runs unattended on a morning timer. NEVER call `AskUserQuestion` or any interactive prompt anywhere in the sweep. When a judgment call comes up (stale marker vs new feedback, dirty checkout, resume-vs-fresh), make the best defensible guess, act, and record it in the Step 6 report with a `⚠️` so the operator can override after the fact. "When in doubt, best-guess and flag it" is the rule; "when in doubt, ask" is forbidden. This binds even when run by hand.

## CRITICAL: local-only contract (binds every dispatched child)

Enforced by BOTH prompt text AND mechanical guards set up in the window bootstrap.

1. **NEVER push.** No `git push` in any form. Commits stay local until the operator pushes.
2. **NEVER create a PR.** No `gh pr create`.
3. **NEVER ask the operator mid-flight.** A blocked child writes one line to `$STATE_DIR/dates/<DATE>/dispatch/<ITEM>.blocked.md`, finishes what it safely can, and exits.
4. **PR comments/reviews are bucket-dependent.** Own-work buckets (`inreview`, `inprogress`) hard-block `gh pr comment` / `gh pr review` / write `gh api`. The teammate-review bucket (`inreview-others`) leaves the token reachable but the review skill never posts (contract, not shim).

Mechanical guards (installed before the child starts, via `install-guards.sh`):

- `git config --local remote.origin.pushurl 'no-push://auto-new-day-blocks-this'` in ALL dispatched sessions.
- `core.hooksPath` → a shared per-profile hooks dir with a `pre-push` that exits 1.
- a `gh` write-shim on `$PATH` in the own-work sessions only, rejecting every write subcommand and write `gh api`.
- `AUTO_NEW_DAY_APPROVED=1` is the documented per-call override (stderr audit line); the operator uses it to authorize a specific push/post. Absent that, default-deny holds.

These catch an honest-but-forgetful child, not an adversarial one (inline `--no-verify`, absolute `/usr/bin/gh`, etc. are known, accepted escape hatches). The contract is defence-in-depth, not a sandbox.

## Dispatched skills

Every dispatched window runs `bucket_skills[<bucket>]` from the profile. The generic default is `/auto-new-day:impl` for `inreview` / `inprogress` / `inreview-others`. A domain pack overrides these (e.g. a connector pack maps `inprogress` bug-labeled items to its own bug skill). `ready-to-merge` runs no child; it is the operator's own shell parked on the branch.

## Modes (parse once, at the top)

Alongside profile + path resolution, parse the argument tail once and cache booleans:

- `--dry-run` / `-n` (or `AUTO_NEW_DAY_DRY_RUN=1`): discovery runs (read-only), the per-day create.md is written with a `-dryrun` infix, but NO tmux spawn, NO side-effect files, NO state writes. Safe to repeat.
- `--force` / `-f`: bypass the marker dedupe check so items re-dispatch even if a marker says they were handled; also forwarded to the child so its resume fast-path is bypassed.
- `--fast`: children run their normal parallel-subagent fan-outs. Default (no `--fast`) injects `--no-subagents` + `NO_SUBAGENTS=1` so unattended runs cost one pass of tokens, not N.
- `--date <date>` or a bare date phrase (`today`, `yesterday`, `june 16`, `2026-06-16`): replay a saved day's plan from `dates/<DATE>-create.md`, re-spawning any windows not already running. No discovery, no `gh`. Resolve with `${SCRIPTS}/resolve-date.sh`.
- `--show [<date>]`: read-only. Print that day's persisted report plus a per-window outcome overlay (done / blocked / in-flight / lost read from `dates/<DATE>/dispatch/`). No spawn, no state writes.
- `--reset <ITEM>`: shell out to `${SCRIPTS}/reset-ticket.sh <ITEM>` to wipe every dedupe artifact for one item, then exit (no sweep).

Mutual exclusion: `--date` / `--show` / `--reset` are mutually exclusive with each other; `--dry-run` and `--force` compose with `--date`. Bail with a one-line `ERROR:` on an illegal combination.

## Preconditions

- `gh` authenticated (as `gh_account` if the profile names one; `gh auth switch -u <acct>` if needed).
- `jq` and `tmux` on `$PATH`.

Bail with a clear one-line error if any fails.

## Error-handling contract

The sweep fires headless; a single `gh` blip must not crash it. Every `gh` call in discovery (Steps 2-4) is wrapped log-and-continue: on failure, append one line to `$STATE_DIR/sweep.log`, record the skip, and move to the next item. EXCEPTION: the FIRST call (identity + the initial `gh issue list`) is terminal, bail with `ERROR:` + exit 1 (if GitHub is fully down, fail loud, do not write a green report). Skipped items are tagged `(data partial: <reason>)` in the report and do NOT advance their `lastCheckedAt`.

## Step 0.5. Idempotent re-run (fast-path)

If a sweep already ran today (`dates/<TODAY>-create.md` exists AND `state.json.lastSweepAt` is today), or an explicit `--date` was given, do NOT redo discovery. Parse the per-day create.md and re-spawn any windows missing from their tmux session via `${SCRIPTS}/tmux-dispatch.sh`. No `gh`, no state writes. This is the same machinery date-replay uses; see the create.md format below (`## AUTO-<bucket>` → `### Window: <name>` → a `#### bootstrap` block + a `#### claude invocation` line).

## Step 0.7. Pre-sweep cleanup

`${SCRIPTS}/gc-stale-windows.sh` rename-archives any dispatch window whose per-window log is older than a week (best-effort, always exits 0). Session names come from the profile's buckets.

## Step 1. Resolve identities

- **You:** the `gh` account (`gh api user --jq .login`), matched against `discovery.assignee` when it is `@me`.
- **Approvers:** `approvers[]` from the profile. An APPROVED review from any of these logins clears a PR (moves it to `ready-to-merge`, removes it from the teammate-review set). Cache matched logins in memory to short-circuit later PRs.

## Step 1b/1c. Checkpoint + history

`mkdir -p $STATE_DIR/dates/<TARGET_DATE>/{dispatch,markers}`. Write the dispatch plan to `dates/<TARGET_DATE>-create.md` BEFORE creating any tmux session, so a session never exists empty. Install the shared guards once per profile:

```bash
"$SCRIPTS/install-guards.sh" "$STATE_DIR/guards/own-work" --with-gh-shim
"$SCRIPTS/install-guards.sh" "$STATE_DIR/guards/review"
```

Snapshot prior in-repo artifacts with `${SCRIPTS}/snapshot-inrepo.sh --to "$DATE_DIR"` (best-effort). Skipped in dry-run.

## Step 2. Discover your assigned work (GitHub)

Over `discovery.repos` (or every repo matched under `working_root`):

- **Assigned issues** (drive `inprogress`): `gh issue list --repo <r> --assignee "<assignee>" --state <issue_states> --json number,title,url,labels,updatedAt`.
- **Your open PRs** (drive `inreview` / `ready-to-merge`): `gh pr list --repo <r> --author "@me" --state <pr_states> --json number,title,url,headRefName,updatedAt,reviewDecision,labels`, or `gh search prs --author @me --state open` across repos in one call.

Tag each with its source. A PR you authored is a candidate for `inreview` / `ready-to-merge`. To decide whether an assigned issue already has a PR, resolve its linked PR via GraphQL `issue.closedByPullRequestsReferences` (fallback: `gh pr list --search "<issue-url> in:body"`): no linked PR means `inprogress` unstarted; a linked PR authored by someone else means `inprogress` unverified. This linkage is best-effort, GitHub only links PRs that close or reference the issue, so a related-but-unlinked PR can misclassify as unstarted; flag it in the report.

There is no "promote a Todo into In Progress" fallback: plain GitHub issues have no portable status column, so a genuinely empty morning simply dispatches nothing to `inprogress` (a tracker-backed domain pack can add its own backlog promotion).

## Step 2c. Teammate PRs needing your review (`inreview-others`)

`gh search prs --review-requested @me --state open` (or per-repo `gh pr list --search "review-requested:@me"`). For each: skip if already approved by an `approvers[]` login; skip self-authored; skip if you already engaged (submitted a review / comment / inline reply) AND nothing newer has landed since (compute `myLatestActivityAt` from `gh pr view --json reviews,comments` + inline `gh api .../comments`, compare against the latest commit + others' comments). Sort by `updatedAt` desc, cap at `caps.review_prs_per_sweep`.

## Step 3. Resolve PR state for each own item

`gh pr view <url> --json reviews,author,number,headRefName,headRefOid,baseRefName,updatedAt`. Determine:

- **approval**: an APPROVED review whose `author.login` is in `approvers[]`.
- **changes-requested**: `CHANGES_REQUESTED` reviews newer than `state.json[item].lastCheckedAt`.
- **foreign commits**: per-commit authors from `gh api repos/<o>/<r>/pulls/<n>/commits`; a commit is foreign if its author login is set and is not your account. On new foreign commits, fast-forward the local branch with `${SCRIPTS}/pull-foreign-commits.sh <repo-dir> <num> <branch> --log <log>` (safe: stashes a dirty tree, skips a diverged branch). Foreign commits are surfaced but do NOT by themselves escalate a quiet item.
- **unresolved bot threads**: the GraphQL `reviewThreads` query (isResolved/isOutdated); unresolved non-outdated bot threads count as actionable.

## Step 4. New activity since last check

For non-approved items, merge PR conversation comments + inline review-thread comments newer than `lastCheckedAt`. Tag `isBot` (login matches `*[bot]`, `dependabot*`, `renovate*`, `github-actions*`, `coderabbitai*`, ...) and `isSelf` (your account). A comment is human-authored iff `!isBot && !isSelf`; only those count as actionable.

## Step 5. Classify (first match wins)

- **inprogress (unstarted)** — an assigned issue with no linked PR. Dispatches to Step 7b.
- **ready-to-merge (approved)** — an APPROVED review from an `approvers[]` login. Wins over everything. Step 7d: parks a plain-shell window by default, or (when `guards.merge == "auto-on-clean-approval"` and the PR passes the clean-approval check) auto-merges it and opens a claude session + MERGED pager. No child skill either way.
- **inprogress (unverified-pr)** — not approved AND the linked PR's author is not you (someone/a bot opened it on your issue). Assess-then-finish on the PR branch (Step 7b).
- **inreview (actionable)** — not approved, your own PR, AND ≥1 of: a new human comment, a new CHANGES_REQUESTED review, or an unresolved bot thread. Dispatches to Step 7. (Escape hatch: drop comments/CRs at or before `myLatestActivityAt` — you already replied; the ball is in the reviewer's court.)
- **quiet** — none of the above. One-line report, no dispatch.

A domain pack can refine `inprogress` into sub-workflows by label (via `bucket_skills` + the pack's classifier); the generic engine dispatches `bucket_skills[bucket]` for all of them.

## Linear backend (`ticket_source: "linear"`)

When the active profile sets `ticket_source: "linear"` (the connector work profile), Steps 1-5 discover + classify via Linear (`mcp__plugin_linear_linear__*`) instead of `gh`, reproducing the original connector sweep exactly. Everything from Step 6 on (report, dispatch, guards, marker/resume, state, weekly) is unchanged. Extra `discovery` field for this backend: `team` (e.g. "Connector Horizon").

- **Step 1 (identity).** Current user via `list_users`, matched by the operator's email; cache `me.id`. Approvers: the `approvers[]` GitHub logins clear a PR (a connector's code still lives on GitHub, so approval is still read from `gh pr view` reviews); an optional `approvers_name_re` enables the Linear-name fallback.
- **Step 2 (my work).** `list_issue_statuses` on `team`; keep review statuses (name contains "review") and in-progress statuses (contains "progress", plus `Doing`/`Started`). `list_issues` with team + `assignee=me.id` + those statuses, **paginate until `hasNextPage == false`**, dedupe by id, tag `stage`. Capture `identifier,url,title,updatedAt,labels[],stage`. **Re-verify `assignee.id == me.id`** per result (the MCP filter is flaky); drop mismatches.
- **Step 2b (Todo fallback).** If zero in-progress tickets survive, promote ONE `Todo` ticket (drop urgent/high, then shortest title, fewest labels, oldest) via `save_issue(state=In Progress)` and treat it as a fresh unstarted-impl candidate. Skipped in dry-run (it writes).
- **Step 2c (teammate PRs).** `list_issues` team + in-review statuses, filter `assignee.id != me.id` (drop bot assignees), resolve each linked PR via `list_diffs`, then the same `gh pr view` approval/engagement checks and `caps.review_prs_per_sweep` cap as the GitHub backend.
- **Step 3 (PR resolve).** Per ticket, `list_diffs` → most-recent open PR (+ head branch + repo dir). Approval, changes-requested, foreign-commits, and bot-thread detection all use `gh` exactly as the GitHub backend.
- **Step 4 (new activity).** Merge Linear comments (`list_comments`, newer than `lastCheckedAt`) with the PR conversation + inline review comments. `isSelf` matches the operator's gh logins (PR) / email (Linear).
- **Step 5 (classify + workflow).** Same five labels. For `unstarted-impl` / `unverified-pr`, compute a `workflow` from the ticket's Linear labels to pick which inprogress skill to dispatch, honoring the `bucket_skills.inprogress` map (below). `triage.sh` receives `--linear-status` / `--linear-assignee` / `--me-linear` so its ticket-left-status and reassigned discard cases fire on Linear state.

**`bucket_skills` map form.** A bucket value may be a plain string (dispatch that skill) OR `{ "default": "<skill>", "by_label": [ { "match": "<regex>", "skill": "<skill>" }, ... ] }`. For the map form, test each `by_label.match` (case-insensitive) against the item's labels in order; first hit wins, else `default`. The generic GitHub profile uses plain strings; the work profile uses the map on `inprogress` to reproduce the original bug/new-connector/impl routing.

## Step 6. Report

A single markdown doc printed to the sweep pane AND written to `dates/<TARGET_DATE>-report.md`. Grouped by where work was dispatched (dispatched sections first; approved + quiet as compact bullets after). Real markdown, bullet-first, omit empty sections. No em-dashes or double-hyphens. `⚠️` / `⚠️⚠️` is the warning ladder for best-guess judgment calls. A `warnings:` tail block lists any skipped `gh` calls.

## Step 6.7. Same-repo worktree isolation

After all three dispatch lists are built and marker-filtered, before any spawn, group surviving windows by repo dir. Any repo with two or more windows this sweep gets `USE_WORKTREE=true`: that child works in `~/worktrees/<repo>/<branch>` (guards re-applied inside) so two children never fight over one working tree. Deterministic, never prompts the operator.

## Step 7 / 7b / 7c. Dispatch

The three dispatched buckets share one shape (per-window build → side-effect files → append to create.md → spawn):

1. **Build the window list.** For each item, run `${SCRIPTS}/triage.sh` (dispatch / resume / skip / discard). It checks the marker (skip if fresh, unless `--force`), runs `marker.sh is-abandoned` for crash recovery, and searches prior dates for a resume manifest. Drop skipped items with a one-line note.
2. **Side-effect files (real run only).** Write the dispatch payload JSON under `$DATE_DIR/dispatch/`, write the marker (`${SCRIPTS}/marker.sh write ...`) to the in-repo `.<bucket>/<ITEM>.md`, the per-date copy, and the `$DATE_DIR/markers/` mirror. Record `markerPath` in `state.json`.
3. **Append to create.md.** One `## AUTO-<bucket>` section, one `### Window: <name>` per item, each with a `#### bootstrap` block (`${SCRIPTS}/bootstrap-window.sh --profile <own-work|review> --date-dir <d> --repo-dir <r> [--ticket <t> | --window <w>] --final-cwd <working_root>`) and a `#### claude invocation` line (`claude "<bucket_skills[bucket]> [--no-subagents] <arg>"`). Keep this format stable, it is what Step 0.5 / date-replay parse.
4. **Spawn (real run only).** `${SCRIPTS}/tmux-dispatch.sh <session> <win> <cwd> <bootstrap-cmd> <slash-invocation> --log <path>`. It creates the session on the first window and dedupes by window name. Use `${SCRIPTS}/refresh-decision.sh` to decide dispatch / skip / poke / replace for an already-running window.

Bucket → session → profile → skill:

- `inreview` → `AUTO-inreview` → guards `own-work` (with gh shim) → `bucket_skills.inreview`.
- `inprogress` → `AUTO-inprogress` → guards `own-work` → `bucket_skills.inprogress`. The `unverified-pr` variant tells the child to assess the existing PR first, then finish gaps as local commits.
- `inreview-others` → `AUTO-inreview-others` → guards `review` (no gh shim) → `bucket_skills["inreview-others"]`, prefixed by any `review_chain` skills. Never posts, never asks.

## Step 7d. Approved → AUTO-ready-to-merge

One window per approved PR (deduped). Reconcile away windows whose PR later merged or lost approval.

Default (`guards.merge` absent or `"blocked"`): a plain-shell window parked on the PR branch with a merge-readiness summary. No child claude, the sweep NEVER merges.

Opt-in (`guards.merge == "auto-on-clean-approval"`): the sweep MAY merge, but ONLY when the PR passes the clean-approval check. For each approved PR (`gh pr view <url> --json reviews,comments,mergeable,mergeStateStatus,state,statusCheckRollup`):

1. Approved by an `approvers[]` login (already true to be in this bucket); record the latest such APPROVED `submittedAt` as `approvedAt`.
2. NO comment authored by any `approvers[]` login after `approvedAt` — across conversation comments, review-body comments, and inline review-thread comments. A follow-up from an approver means the ball may be back in your court; do NOT auto-merge, fall back to a parked shell and flag it.
3. Not already merged/closed, `mergeable != CONFLICTING`, and no failing/pending required checks in `statusCheckRollup` (all green/neutral/skipped). Any red or pending check → do NOT merge, park + flag.

If all three hold, merge with the repo's configured method (e.g. `gh pr merge <url> --squash`), then build the window with `${SCRIPTS}/rtm-window.sh --status merged` (a claude session cd'd to the repo on the left, a `less` pager on the right showing the ticket description under a big MERGED banner + who/when merged). If any check fails, build it with `--status parked` instead and note why in the Step 6 report. A non-approver comment after approval does NOT block the merge (only `approvers[]` follow-ups do). Record the merge (`mergedBy`, `mergedAt`) in `state.json` and archive the ticket in Step 8. For every PR merged this way, ALSO record a weekly-report line under "Worked on": `${SCRIPTS}/weekly-report.sh add-item --date <DATE> --section "Worked on" --key <pr-url> --bullet "[<repo>#<n>](<pr-url>) <title> ([<ticket>](<ticket-url>))"` (Step 9). Match the report's markdown-link bullet style and embed `<pr-url>` in the bullet so the `--key` dedup finds it on re-runs. A merged item belongs under "Worked on" like any other work you did; it is not flagged differently.

`rtm-window.sh` args: `--session AUTO-ready-to-merge --window <w> --repo-dir <d> --body-file <f> --status <merged|parked> [--branch <b>] [--merged-by <login>] [--merged-at <iso>]`. The body-file is the caller-written ticket id/title/url/summary; the script prepends the banner + status line and opens the pager pane.

## Step 8. Persist state + archive

Write `state.json` via `${SCRIPTS}/state-write.sh` (flock-serialized): per-item `lastCheckedAt` for items still in an active state, `reviewedPRs[<url>]` for teammate PRs. Reconcile against the current discovery: any item that left active status moves to `done/<ITEM>.json` and its `markerPath` is `rm -f`'d. Skipped-on-error items do NOT advance. Skipped entirely in dry-run and date-replay.

## Step 9. Weekly report

`${SCRIPTS}/weekly-report.sh upsert --date <DATE>` appends a date-keyed bullet summary of the sweep to `$STATE_DIR/weekly/<ISO-week>-report.md` (idempotent per date). Then ALWAYS run `${SCRIPTS}/weekly-report.sh show --if-friday` to surface it: that opens (or refreshes) the `AUTO_weekly_report` tmux session with the week file rendered in `mdp` (browser, best-effort) AND opened in the operator's viewer (neovim when present, else a `less` pager). The `--if-friday` gate makes it a no-op except on the week's report day (normally Friday; the last non-holiday weekday otherwise, computed in `tz`), so it is safe to run every sweep. Best-effort, never aborts the sweep.

**Skipped items never appear in the weekly report.** Any item the operator marked skipped, a `$STATE_DIR/done/<key>.done.json` with `outcome: "skipped"` (written by `mark_done.sh`), is excluded: `weekly-report.sh generate` drops it, and no dispatch/recording path may `add-item` it. This is distinct from other `done/` records (`outcome` merged / approved / left-status), which are NOT skips and stay. A review also only earns a "Reviewed teammate PRs" line when the operator actually posted an approval or comment on it (the sweep never posts), so a drafted-but-unposted or skipped review is never recorded.

## Output discipline

The sweep's own chat output is the report (Step 6) plus the spawn results. No narration between steps beyond one-line status. The operator reads the report and attaches the sessions they care about:

```bash
tmux attach -t AUTO-inreview
tmux attach -t AUTO-inprogress
tmux attach -t AUTO-inreview-others
tmux attach -t AUTO-ready-to-merge
```
