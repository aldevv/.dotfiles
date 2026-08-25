---
name: find-bug
description: >
  Investigate a reported bug down to root cause: a ticket, an error string, a
  "X is broken for user Y" report, or a symptom with no obvious source. Drives a
  fixed evidence order — pin the artifact, build a timeline, separate symptom from
  cause, correlate telemetry, split trigger from defect — and reports findings
  labelled measured-vs-inferred with mitigations. Triggers on "investigate this
  ticket", "find the bug", "why is X failing", "root cause this", "what's causing
  X", "users can't Y", or a pasted ticket URL / error payload.

  Not for a bug already visible in a diff under review (use a code review skill),
  a compile error whose answer is in the output, or "add logging so I can see X".
  "Investigate" aimed at docs or vendor behavior rather than a failure belongs to
  `investigate`. Inside $WORK, `find-bug-work` wins: it has the real telemetry
  sources.
user-invocable: true
argument-hint: "<ticket URL, error string, or symptom description>"
---

# find-bug

Root-cause an incoming bug report using evidence, in an order that stops you from
guessing. The method is source-agnostic: it names the *kind* of evidence to get at
each step, not the tool. If a project-specific sibling skill exists (e.g.
`find-bug-work`), that one owns the concrete commands and this one owns the order.

## Ground rules

- **Read-only until the root cause is agreed.** Investigation never mutates the
  system under investigation. Any fix, restart, purge, or config change is a
  separate step the user authorizes.
- **Label every claim `measured` or `inferred`.** A measured claim has a command
  and its output behind it. An inferred claim is a reading of code or a
  correlation. Never present the second as the first.
- **Absence is evidence.** A record that should exist and does not tells you the
  failure happened *before* the write that would have created it. This is often
  the single most locating fact you will get.
- **Don't stop at the first plausible cause.** The first thing that looks wrong is
  usually a symptom of the thing that is wrong. Keep pulling until you reach
  something that explains the *timing* as well as the failure.

## Step 1 — Pin the artifact

Extract and write down, verbatim:

- the exact error string and payload (not a paraphrase)
- every identifier in the report (entity ID, hostname, request ID, username)
- the timestamp the reporter hit it, normalized to UTC
- who reported it, and whether anyone said "we have several reports of this"

That last one is a branch point: one reporter means start narrow, multiple means
start with the shared dependency.

## Step 2 — Locate the entity in the system of record

Look the identifier up in the authoritative store and record its current state.
Answer: does the thing exist, what state is it in, when did it last change, and
who or what changed it. A surprising amount of "it's broken" is "it is in the
state someone put it in".

## Step 3 — Build the timeline

Two questions, in this order:

1. **Is this actor's history consistent with the report?** Pull the entity's own
   audit/event history. Look for the operation that was supposed to happen and is
   missing (see: absence is evidence).
2. **Is it isolated or systemic?** Aggregate the *success path* by hour over the
   last few days, not the error path. A success rate that goes from steady to zero
   at a specific hour localizes the break far better than reading error logs
   does, and it tells you whether you are debugging one user or an outage.

If the success rate broke at a specific time, everything after this is about
"what changed at that time".

## Step 4 — Rule out the boring causes

Before theorizing, check in this order, because each is cheap and each would make
the rest of the investigation moot:

- **A deploy.** When did the affected component last ship? If the break time and
  the deploy time don't match, stop blaming code changes.
- **A config or credential change**, including expiries.
- **An upstream/provider incident** or quota.
- **A resource ceiling**: CPU, memory, connections, disk, queue depth, IOPS on
  every dependency in the request path, not just the obvious one.

## Step 5 — Trace the error string through the code

Find the exact site that emits the reported string, then enumerate *every* branch
that reaches it. Write them out. For each, note what evidence would confirm or
exclude it. This converts "it returns 500" into a short list of candidate causes
you can test.

Pay attention to shared resources threaded through the whole handler: a request
context with a deadline, a connection pool, a shared client. A slow call early in
a handler can make a *later, unrelated* call fail, and the reported error will
name the innocent second call. This is the single most common way a bug report
points at the wrong subsystem.

## Step 6 — Get the real error from telemetry

The user-visible string is a wrapper. Find the underlying one. Work through
whatever the project actually has, cheapest first: an error tracker with an API,
a log aggregator, metrics, the DB's own audit trail, CI history.

**Correlate `firstSeen` timestamps.** Two independent-looking error signatures
that first appeared in the same second are one cause, not two. This is the
highest-value trick in the whole method: it collapses a list of symptoms into a
single event and hands you the break time for free.

## Step 7 — Explain the timing, not just the failure

You have the root cause when your explanation covers *why now*. "There's a
missing index" does not explain a Tuesday-at-14:08 break by itself; "there's a
missing index and the table crossed N rows / traffic doubled / a retry loop
started writing to it" does. If you can't explain the timing, you have found a
contributing condition, not the cause. Say so plainly rather than overclaiming.

## Step 8 — Split trigger from defect

Separate:

- **the trigger**: usually external and not your bug (capacity shortage, provider
  error, a spike, a bad input)
- **the defect**: the code that turns a recoverable trigger into a lasting
  failure

Both go in the report, labelled. Fixing only the trigger means it recurs; fixing
only the defect leaves the trigger to fire again. Classic shapes of the second
kind, worth checking for explicitly:

- a retry with no cap and no dead-letter path, turning a transient into a
  permanent loop, often while writing a record per attempt
- an error-handling branch that is itself broken, so the fallback never runs
- an unbounded per-item query inside a loop over a growing collection
- a missing index on a table that only recently got big

## Step 9 — Report

Delegate the write to the **`report`** skill's "Written report on disk" section in
**report-only mode** — it owns the layout, and report-only means no Hunk pane, no
tmux, no diff. Do not hand-compose the path; the script is the contract:

```bash
REPORT=$("$HOME/.claude/skills/report/scripts/report-path.sh" "<TICKET>-<slug>")
```

It creates the folder and prints the file to write. It handles the numbering
(`report-1.md`, `report-2.md`, … never a bare `report.md`, so a second investigation
of the same ticket the same day can't clobber the first), and in an `AUTO-` dispatch
session it inserts the stage as a path segment. Use the ticket key when there is one
(`ITH-500951-workstation-start-500`), otherwise `no-ticket-<slug>`. Raw query output,
screenshots and metric dumps go in the same folder beside the report.

`$HOME/reports/` is outside every repo on purpose: an investigation write-up is a
session artifact, not a project deliverable, and must never be committed. Never
write one into a repo working tree.

Lead with the one-line root cause. Then:

- **Findings table**, one row per finding, each with its evidence and a
  `measured` / `inferred` label
- **Timeline** in UTC, from first symptom to now
- **Blast radius**: who is affected, how many, still ongoing or not
- **Recommended actions**, ordered by leverage, split into "now" (mitigation that
  unblocks users, lowest risk first) and "follow-up" (the actual defects)
- **What you did not check**, explicitly. An unexamined branch stated out loud is
  useful; one left silent is a trap.

Do not claim verification you didn't do. If a claim rests on reading code rather
than observing behavior, say which.

## Step 10 — Summary via `mdp-explain`

The report is the record; nobody skims a record. After writing it, invoke
**`mdp-explain`** to produce a short diagram-first explainer and write it to
`summary.md` in the same folder as the report:

```
<report folder>/
├── report-1.md     # the full evidence trail
└── summary.md      # the 2-minute version, rendered in the browser
```

Tell `mdp-explain` explicitly to write `summary.md` at that path rather than its
default tempfile, point it at the report file(s) as source, and name the two diagrams
worth having: **where the failure actually surfaces** in the request path (usually not
where the error message points), and **the cause chain** from trigger through to
user-visible symptom. It renders the result via `mdp`.

When one incident spans several reports, write one `summary.md` covering all of them
at the shared parent (`$HOME/reports/<date>/summary.md`) instead of one per folder;
a reader chasing "what broke today" wants a single entry point.

Regenerating a summary is cheap: re-invoke `mdp-explain` on the same path and it
overwrites, so a corrected report can get a corrected summary without cleanup.

## Composition

- Project-specific sibling (e.g. `find-bug-work`) owns the concrete sources and
  commands; it should call this skill for the order of operations rather than
  restating it.
- When credentials or network access are needed to reach a source, delegate to
  the environment's connection skill rather than inlining auth steps.
- When the answer needs external docs (a provider's API contract, an error code's
  meaning), delegate to `investigate`.
