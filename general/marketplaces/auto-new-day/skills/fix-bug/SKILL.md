---
name: fix-bug
description: Multi-agent root-cause-and-fix workflow for any non-trivial bug in any codebase. Phase 1 spawns 12 parallel investigation agents (each a distinct hypothesis), phase 2 synthesizes a detailed plan, phase 3 spawns 6 parallel review agents (distinct critique angles), phase 4 revises the plan, phase 5 the orchestrator implements, phase 6 spawns 3 validation agents. Every plan and the final validation MUST include a numeric confidence score (0-100%) per symptom, with explicit gaps and assumptions called out, especially when the bug couldn't be reproduced end-to-end. Counts default to 12/6/3 but accept overrides as the first argument. Triggers on "/auto-new-day:fix-bug", "fix this bug with N agents", "spawn agents to figure out X", "investigate this bug using N agents", "do a multi-agent debug", "use the fix-bug skill", or any ticket / stack-trace / repro paired with explicit multi-agent debugging intent. AUTO-INVOKE when the user pairs a substantial bug context (Linear/Jira URL, GitHub issue, log excerpt, stack trace, reproducer) with phrasing like "figure out why this is happening and fix it", "use N subagents to debug", "spawn investigators". Do NOT trigger for trivial bugs (typo, syntax error, one-line fix the model can see immediately), code reviews of an existing diff (use code-review), read-only investigations (use a plain Agent call), or bugs where the user has already identified the root cause and just wants the edit applied.
argument-hint: "[N1/N2/N3] [reference] [--skip-hunk] [--no-subagents]" — N1/N2/N3 are agent counts for investigation/review/validation (defaults 12/6/3; pass "8/4/2" for lighter, "16/8/4" for heavier). Reference is the bug source (Linear URL, ticket ID, stack trace, repro path, free text). `--skip-hunk` ends the skill at Phase 6 (no Hunk invocation); use when a caller wraps fix-bug and wants to run its own pre-Hunk tail. `--no-subagents` (or `NO_SUBAGENTS=1` in env) collapses every parallel `Agent(...)` spawn into a sequential `TaskCreate` list in the main session (slower, cheaper). All optional; the orchestrator will ask if missing.
---

# fix-bug

Generic multi-agent debug-and-fix workflow. Designed for non-trivial bugs where the root cause is unclear and the fix is risky. Spawns parallel critique agents at three phases (investigation, review, validation) so the operator gets independent verifications of every claim before code lands.

**User input**: $ARGUMENTS

## Subagent execution mode (`--no-subagents` / `NO_SUBAGENTS=1`)

Default: the parallel-agent fan-outs described below fire as designed (fastest wall time, highest token cost). Passing `--no-subagents` in `$ARGUMENTS`, OR setting `NO_SUBAGENTS=1` in the environment, replaces EVERY `Agent(...)` parallel-spawn step in this skill (Phase 1 investigation, Phase 3 review, Phase 6 validation) with a `TaskCreate` list executed sequentially by the main session — one task per would-be subagent role, same brief, same synthesis at the end. Trades wall time for token cost (no context duplication across N subagents). `auto-new-day` sets this by default; its `--fast` flag suppresses it.

## CRITICAL: Validation loop in `--no-subagents` mode

When `--no-subagents` is active, Phase 6 (validation) MUST run as a **repeated checklist**, not a single sequential pass. A single pass in the same session shares context with the implementation, so from the operator's perspective it counts as `✓1` — the fix was written and "checked" by the same head. That's not validation.

Policy (applies whenever `--no-subagents` / `NO_SUBAGENTS=1` is set):

- Build a **VALIDATION_CHECKLIST** at the start of Phase 6 with one row per validation task the parallel agents would have done: reproduce the original bug on the unpatched code, run the patched code against the same repro, exercise the golden path, exercise edge cases, run the test suite the plan called out, verify each symptom listed in the Phase 2 "Confidence breakdown". Each row lists the specific command / action, the expected outcome, and the pass counter.
- Run the checklist end-to-end **at least three times** (default `VALIDATION_PASSES=3`; the operator may override with `passes=<N>` in `$ARGUMENTS`, clamped to `2..5`; the third positional-arg slot `N1/N2/N3` still governs the "how many roles per pass" fan-out — passes multiply on top of that). Each pass is a fresh sweep. Do NOT stop early on the first green pass, and do NOT skip rows on later passes because an earlier pass passed them.
- Each independent pass counts as `+1` toward the finding's `✓N` marker. `✓3` in sequential mode means three independent re-checks in the SAME session, each performed after clearing local scratch state (re-read the plan, re-read the diff, re-run the repro from scratch, form the verdict without looking at earlier passes' answers).
- If any pass FLIPS a verdict (e.g. green → red or vice versa), surface the disagreement in the Phase 6 report and lower the confidence — do NOT quietly average. Two out of three still leaves the fix uncertain; say so.
- Symptoms flagged BLOCKER by the Phase 2 confidence breakdown ALWAYS get the full pass count. Non-blocker symptoms may cap at `VALIDATION_PASSES=2` when the operator opts in via `--fast-minor`, otherwise they run the full count too.
- The mandatory confidence-breakdown table in Phase 6 must reflect the multi-pass result: each symptom's confidence is the WORST verdict across passes, not the best.

Why: `--no-subagents` exists to save tokens on runs no human is watching in real time (typically `auto-new-day`). Cheap wall time is fine to spend on multiple sequential re-checks; the alternative is shipping `✓1` fixes that were validated by the same head that wrote them.

## When this skill earns its cost

This skill spends 20+ agent invocations. Use it when the bug has any of:

- Multiple plausible root causes the operator can't disambiguate by reading code alone.
- Production-only symptoms (works locally, breaks in prod).
- Cross-cutting concerns (vendor API, async / concurrency, race conditions, lambda / serverless behavior, distributed state).
- A history of failed fix attempts (the obvious fix didn't work).
- A regression where the operator doesn't know what changed.
- A fix that touches a high-blast-radius surface (auth, billing, data integrity, customer-visible behavior).

Do NOT use for: typos, off-by-one in a small function, syntax errors, "make this function do X" feature requests, code reviews of an existing diff (use `code-review:code-review`), or any bug the operator could fix in under 5 minutes by reading the code directly.

## Lazy-file loading (every phase, not just Phase 5)

Both the orchestrator and every spawned agent consult the lazy indices for the cwd: the global `~/CLAUDE.md` Lazy load list, plus the nearest ancestor `CLAUDE.md` / `CLAUDE.local.md` walking up from the working directory (e.g. `$HOME/work/CLAUDE.md` for work bugs). Each entry has a `**Read when**` clause; load the file when its trigger matches the current step, and don't bulk-load up front.

Triggers most likely to fire in this skill:

- **Phase 1 investigation** — when an angle is debug-intent (A8 race, A17 profile, A18 logs, A19 test gaps, or any "why is X wrong / what does this struct contain"), load `~/.claude/lazy/code/debugging.md`. When an angle touches a third-party API (A11 network, A14 docs/specs), load `~/.claude/lazy/external-apis.md`. Pass the relevant trigger to each agent prompt so the agent loads what it needs.
- **Phase 5 implementation** — BEFORE the first `Write`/`Edit`, load `~/.claude/lazy/code/code.md`. If the fix spans multiple files in coordinated ways (cross-file refactor, layer reshuffle), also load `~/.claude/lazy/code/design.md`. If the implementation adds a debug helper / `String()` / `__repr__` / log statement, load `~/.claude/lazy/code/debugging.md`. Project-local lazy files in the ancestor walk also apply — check the project's index for surface-specific files (e.g. `.claude/lazy/golang-connectors.md`, `.claude/lazy/testing.md`).
- **Phase 6 validation** — the validators do not write source, but if they need to run the build/test commands documented in a project lazy file (e.g. a connector's `cli-commands.md` or `testing.md`), include the trigger pointer in the validator prompt.

After a compaction summary the lazy files are evicted; re-load any whose trigger still applies in the next phase.

## Confidence reporting (mandatory)

Every plan (Phase 2), revised plan (Phase 4), and final validation (Phase 6) MUST emit a numeric confidence score per symptom that the bug is actually fixed. The operator-facing summary MUST lead with this score; don't bury it.

The score answers: "if we ship this branch right now, how sure am I that the customer-visible symptom goes away?" It is NOT "did the build pass" or "did the unit tests pass". Those are inputs, not the answer.

### Tiers and caps

Use one of these tiers as the starting point, then apply caps.

- **Empirically verified end-to-end.** The fix was run against the failing environment AND the customer-visible symptom was observed to disappear. Starts at 90%.
- **Indirectly verified.** Code analysis + unit tests + a proxy reproducer (lowered page size, mock server, scaled-down repro, etc.) confirm the mechanism, but the actual customer symptom was not observed. Starts at 70%.
- **Inferred from code analysis only.** No runtime verification of any kind. Starts at 50%.

Then apply these caps (each one binds independently — take the minimum):

- Bug couldn't be reproduced locally at any scale: cap at 70%.
- No access to the failing environment (prod-only, customer tenant, paid-plan feature, account-specific config): cap at 75% on any symptom that requires that environment.
- Root cause is hypothesized but not directly observed in a debugger / log / probe: cap at 85%.
- Defense-in-depth was deferred (a guard that would catch the same bug class in a different shape is in a follow-up ticket): cap at 90%.
- Fix relies on a vendor / framework / runtime behavior the operator cannot independently verify against a doc, spec, or live probe: cap at 80%.
- Math in the ticket (counts, percentages, before/after numbers) doesn't fully reconcile with the proposed root cause: cap at 80% on the affected symptom.
- Fix only changes behavior at a specific scale (>N users, only under contention, only on lambda, etc.) and the test environment couldn't reach that scale: cap at 80%.

Bonuses (small, additive after caps):

- Bug was reproduced locally AND the fix verified locally: +5%.
- Reproducer landed in the test suite as a regression test that fails before the fix and passes after: +5%.
- Independent doc backing from 2+ sources (e.g. two doc-hunter agents agreeing): +5%.
- Both branches of a flag/path exercised (with and without): +5%.

Hard floor: any symptom that wasn't observed end-to-end CANNOT score above 90%.
Hard ceiling absent end-to-end: ≤90%. Reserve >90% for "I watched the failing symptom disappear."

### Per-symptom breakdown

When the bug has multiple symptoms or affects multiple environment shapes (different tenant sizes, different user roles, different config flags), score each one separately. **The composite score is the MINIMUM of the per-symptom scores, not the average.** A 95% fix on symptom B doesn't help if symptom A is still at 60%.

### Required output format

In every plan and every validation report, include a section with this exact shape:

```
## Confidence breakdown

Overall: <N>% confident this branch fixes the bug as described.
Composite is the minimum across symptoms.

| Symptom | Confidence | Verified by | Assumptions | Gaps |
|---------|-----------|-------------|-------------|------|
| <S1>    | <N>%      | <empirical / indirect / inferred + one-line method> | <list of things we treated as true without verifying> | <what we couldn't test> |
| <S2>    | <N>%      | ... | ... | ... |

### What we did NOT test
- <gap 1>: risk if assumption is wrong = <what breaks for the user>
- <gap 2>: risk if assumption is wrong = <what breaks for the user>

### Closest test to the production symptom
<one paragraph: what proxy test we ran, why it's a proxy and not the real thing, and what the gap means in operator-visible terms>

### What would push confidence to 100%
- <action 1>: estimated gain = +<N>%
- <action 2>: estimated gain = +<N>%
```

### Forbidden phrasings

Per `~/.dotfiles/general/.claude/rules/git.md`, don't say "ready to ship", "looks good", "no blockers", "safe to merge" unless every symptom is at empirical-verified tier (≥90% per the caps above). Static checks pass + inferred confidence ≤85% is "OK to ship unverified if the operator accepts the gap" — say that explicitly, don't dress it up.

## Attribution in reports (mandatory)

Every plan, revised plan, implementation summary, and validation report MUST attribute each addressed item back to the person who raised it. The operator needs to know whose comment / review / ticket each change resolves — both so they can reply to that person at PR review time, and so they can spot if any voice was missed.

What counts as an "item" with an author:
- A PR conversation comment → `author.login` (e.g. `bjorn-c1`).
- A PR review (CHANGES_REQUESTED / COMMENTED / APPROVED) → reviewer's `author.login`, and the review's overall `body` if non-empty.
- A PR inline review comment on a line of code → `user.login`.
- A Linear ticket comment → the comment's `user.name`.
- The ticket itself (initial description / repro) → the ticket's `creator` or `assignee.name`, whichever raised the bug.
- A stack trace or log excerpt pasted by the operator → the operator (use a clear handle like `operator`).

Rules:
- Use the person's NAME (display name) when available; fall back to login / handle if not. Never anonymize ("a reviewer said…", "someone asked…") when the source data has an identity.
- For every Proposed change in Phase 2 / 4, list the author(s) whose item(s) the change resolves. One author per change is normal; multiple authors when several people raised overlapping concerns.
- In the Phase 5 implementation summary, the operator-facing recap is one block per addressed item with required fields `author:`, `issue:`, `comment:`, `fix:`, `link:`, blocks separated by `---`. See the Phase 5 "End-of-phase summary" subsection for the exact format and worked examples.
- If a change resolves a concern from MULTIPLE people, list all of them; conversely, if an item from a person could NOT be addressed (ambiguous, needs design input, out of scope), surface that explicitly with the author's name in the "Open questions" / "Deferred" section.
- Validation reports (Phase 6) likewise cite the originator when a finding maps to a specific reviewer's comment ("V1: still doesn't address `bjorn-c1`'s point about the gRPC code — see PR comment 2026-06-26T08:11Z").

This is non-negotiable in operator-facing artifacts. Internal phase-handoff notes don't need attribution, but anything written to `/tmp/fix-bug-*` and anything echoed to chat at the end of a phase does.

## Parse arguments

Split `$ARGUMENTS` on whitespace. The first token, if it matches the regex `^[0-9]+(/[0-9]+){0,2}$`, is the counts spec. Default counts: `12/6/3`. The remainder of the input is the bug reference.

Examples:

- `8/4/2 https://linear.app/foo/issue/BAR-123` → counts `8/4/2`, reference is the URL.
- `https://linear.app/foo/issue/BAR-123` → counts `12/6/3`, reference is the URL.
- `Customer reports 5xx on POST /widgets after deploy` → counts `12/6/3`, reference is the description.
- (empty) → ask the operator for the reference.

If counts are unusual (e.g. fewer than 3/2/1 or more than 24/12/6), confirm with the operator before spawning.

## Phase 0 — triage (orchestrator only, no agents)

Before spawning anything, the orchestrator collects the bug context and presents a summary to the operator. This avoids burning agent time on a vague brief.

1. **Read the reference.** If it's a URL: `WebFetch` (or the relevant MCP tool, e.g. `linear:get_issue` for `linear.app/*/issue/*`). If it's a file path: `Read`. If it's free text: extract symptoms, expected vs actual behavior, affected component, repro steps.
2. **Locate the offending code.** Grep / glob / Read the most likely files. Cap at ~5 minutes of read-only investigation — the agents will go deep, the orchestrator just needs to know where to point them.
3. **Summarize for the operator** in 5-10 sentences:
   - One-line symptom.
   - Scope: which component, which scale (single user, all users, specific tenants).
   - Suspected files / functions (file:line).
   - Open hypotheses (≥ 2; if only one, this might not need the skill).
   - What the operator should expect: "I'll spawn N agents to investigate distinct angles; expected wall-clock ~5-15 min."
4. **Get a go-ahead.** If counts are non-default, the reference is unusual, or the bug looks like it might not need the full flow, ask before continuing.

Output of Phase 0: a short briefing message to the operator. Do NOT write files yet — the synthesizer in Phase 2 owns the plan artifact.

## Phase 1 — investigation fan-out (N1 agents, default 12)

Spawn N1 agents in a single message with parallel `Agent` tool calls. All `run_in_background: true` so the orchestrator can react to early returns.

### Angle taxonomy (pick N1 distinct angles)

Pick angles that map to the open hypotheses from Phase 0. Each angle becomes one agent. The list below is a pool — don't use angles that don't apply, and add domain-specific angles if the bug calls for them.

- **A1 Reproduce locally** — write a minimal reproducer (mock server, unit test, script) that exhibits the symptom deterministically. If repro fails, that itself is signal.
- **A2 Locate offending code** — grep / read for the exact code path the symptom flows through. Returns file:line for every suspected step.
- **A3 Regression bisect** — `git log`/`git bisect` between last-known-good and broken. If the operator says "v1.2 worked, v1.3 broke", look at the diff.
- **A4 Diff legacy vs current** — same as A3 but qualitative: what behaviors changed between the two versions?
- **A5 Downstream callers** — who calls the broken code? Could the bug be in a caller misusing the API?
- **A6 Upstream dependencies** — does the bug live in a vendor library, framework, runtime, or external service? Look at vendor / node_modules / venv / Cargo.lock for recent updates.
- **A7 Error handling audit** — search for `catch`, `recover`, `except`, `error.swallowed`, `// TODO`, `if err != nil { _ = err }`. Swallowed errors are bugs hiding in plain sight.
- **A8 Concurrency / race** — `goroutine`, `Thread`, `await`, `Promise.all`, mutex / lock / semaphore usage. Look for unsynchronized shared state, missing `defer Unlock`, double-locks.
- **A9 Resource lifecycle** — file handles, sockets, db connections, allocations. Look for leaks, double-free, use-after-free, premature close.
- **A10 Data shape / schema** — JSON tags, ORM mappings, proto definitions. Look for field-name drift, type mismatches, optional vs required, encoding mismatches.
- **A11 Network / API / IPC boundary** — HTTP wire format, gRPC, message queues. Use `curl -v`, network tap, or read the spec.
- **A12 Configuration / env** — `.env`, `config.yaml`, feature flags, runtime knobs. Did a flag flip silently?
- **A13 Security / authz / authn** — does the user have the permissions the code assumes? Token expiry? Scope mismatch?
- **A14 Docs / specs / contracts** — verify the code's API claims against the official docs (vendor, RFC, OpenAPI). Use `WebFetch`, context7 MCP, or vendor llms.txt.
- **A15 Peer-codebase comparison** — does another similar project handle this case correctly? What do they do differently?
- **A16 Known anti-patterns** — grep the CLAUDE.md / style guide / common-pitfalls doc for documented bad patterns; check if the code matches any.
- **A17 Profile / measure** — pprof, flame graphs, browser perf panel, structured logs. Does the bug appear at scale, on slow connections, under contention?
- **A18 Observability / logs** — search prod logs (if accessible) or local debug runs for the specific symptom event. Capture the surrounding context.
- **A19 Test gaps** — does any existing test cover the failing scenario? Should one be added now?
- **A20 Synthesis pre-cache** — the last agent reads the same source files the orchestrator will use in Phase 2, so the synthesis is fast when findings land. This agent's "report" is just confirmation it has the files cached; its real value is making Phase 2 quick.

Pick angles that span the bug's likely surface. For a vendor-API regression, lean on A1, A11, A14, A15. For a race condition, lean on A8, A17, A18. The point is variety: identical agents are wasted parallelism.

### Investigation agent prompt template

Each prompt should include:

```
You are <agent name>, one of N1 parallel investigators on this bug.

Bug context (verbatim from the operator's reference):
<paste ticket / description / repro>

Symptom: <one-line>
Suspected scope: <component>
Open hypotheses (the panel as a whole is testing these):
<list>

YOUR ANGLE: <one of A1-A20 above, customized to this bug>

Your specific job:
<3-6 bullet points the agent must answer, with file:line references where possible>

Run in the working directory at <repo path>.

CRITICAL hard rules:
- Verify or refute the hypothesis. Both are valuable — a clean negative result narrows the search.
- Cite file:line for every code claim. Cite URL + section for every external claim.
- Do NOT propose a fix yet — only diagnose.
- Do NOT modify any source files. Read-only investigation.
- Report under <N> words. Confidence-tag your verdict (HIGH / MEDIUM / LOW).
- If your angle doesn't apply (e.g. "no concurrency in this code"), say so explicitly and return early.

Report format:
- Hypothesis: <restate>
- Verdict: CONFIRMED / REFUTED / INCONCLUSIVE / NOT-APPLICABLE
- Evidence: <bulleted, with file:line / URL>
- Open questions for the panel: <if any>
```

Word cap suggestion: 500 words per agent. Tighten to 300 for narrow angles, expand to 700 for synthesis pre-cache.

### Reacting to findings

As agents return, watch for:

- **Convergence**: 3+ agents independently point to the same root cause → high-confidence diagnosis.
- **Smoking gun**: a single agent produces a deterministic reproducer or doc-citation that explains the symptom → near-certain root cause.
- **Contradiction**: two agents propose mutually exclusive causes → spawn a tie-breaker agent in Phase 2 or run a diagnostic probe yourself.
- **Scattered**: agents all return INCONCLUSIVE → the angles were wrong; consider a second mini-fanout with new angles before moving to Phase 2.

While waiting for the slow tail, brief the operator on early returns. Don't poll silently.

## Phase 2 — plan synthesis (orchestrator writes `/tmp/fix-bug-plan-<id>.md`)

`<id>` is a short slug, ideally the ticket ID (e.g. `BAR-123`) or a timestamp.

The plan is detailed and operator-facing. Structure:

```
# Bug fix plan — <id>: <one-line symptom>

## Ticket / reference recap
<paste-or-summarize from the ticket / log / description. List the author(s)
who raised it: the ticket creator, every commenter (Linear + PR), every
reviewer who left CHANGES_REQUESTED. One line per voice; cite name, source,
and a short excerpt. Example:
- bjorn-c1 (PR review #42, CHANGES_REQUESTED, 2026-06-26T08:11Z): "the gRPC
  code is wrong — use DeadlineExceeded, not ResourceExhausted"
- John Allers (Linear comment, 2026-06-25T15:22Z): "split the test-server
  change into its own commit"
- jane-doe (PR inline comment on pkg/foo/bar.go:42): "nit: rename `x` to `xs`"
>

## Root cause (from investigation)
<paragraph + evidence chain citing which agents confirmed what>

## Proposed changes
For each change, include:
- File:line
- Addressed by: <name(s) — pull from the recap above; cite every person whose
  concern this change resolves. If a change does NOT resolve anyone's concern
  and is just orchestrator initiative, say so explicitly ("orchestrator
  initiative: <why>") so the operator can decide whether to keep it.>
- Before / after code sketch (≤ 30 lines)
- Why this is the right fix (1-3 sentences)
- Confidence (HIGH / MEDIUM / LOW)
- Blast radius (what else could this affect?)

## Rejected alternatives
List the fixes the panel considered and explain why each was rejected. This
prevents the reviewer agents in Phase 3 from re-proposing them.

## Test plan
- New tests (unit / integration / mock-server / e2e).
- Existing tests that need updating.
- Manual verification steps.

## Open questions for the operator
<things that need human judgment before implementation — backwards-compat
calls, scope decisions, etc.>

## Confidence breakdown
(Required. Use the format from the "Confidence reporting" section above.
Score each symptom separately, apply the caps, and surface every gap and
assumption. Composite = minimum across symptoms.)
```

The plan is read-only at this stage. Do not implement until Phase 4 approval.

## Phase 3 — review fan-out (N2 agents, default 6)

Spawn N2 reviewers in parallel. Each attacks the plan from a distinct angle. Default angles:

- **R1 Correctness** — does the proposed fix actually resolve the original symptom? Walk the code paths.
- **R2 Doc / spec verification** — every external claim (API behavior, vendor field name, RFC clause) backed by a citable source?
- **R3 Blast radius** — what else could break? Performance, rate limits, downstream callers, customers in different configurations.
- **R4 Test coverage** — does the test plan actually catch a future regression of THIS bug? Are there missing edge cases?
- **R5 Backwards compatibility** — what existing state / behavior changes for current users? Is this a breaking change? Does it need a migration?
- **R6 Alternative fixes** — is the plan picking the best fix? Are there cheaper / safer / smaller-blast-radius options the panel missed?

For larger N2, add: R7 Security review, R8 Observability (logging/metrics for future debugging), R9 Documentation (release notes, runbooks).

### Review agent prompt template

```
You are <reviewer name>, one of N2 parallel reviewers of a bug-fix plan.

Plan location: /tmp/fix-bug-plan-<id>.md

Read it in full first. Then read the source files it touches (it cites
file:line throughout — open them).

YOUR ANGLE: <one of R1-R9 above>

Specifically answer:
<3-7 targeted questions for this angle>

Report under <N> words. Output format:
- Issues, sorted by severity (BLOCKING / IMPORTANT / NIT).
- For each issue: file:line, what's wrong, suggested fix (one-liner).
- One overall verdict: APPROVE / REQUEST-CHANGES / REJECT.

Do NOT modify the plan or any source file. You're reviewing, not editing.
```

Word cap suggestion: 700 words per reviewer.

### Reacting to reviews

- BLOCKING items → must address before implementation.
- IMPORTANT items → discuss with the operator, get explicit accept/defer.
- NIT items → fold in if cheap, defer otherwise.
- If a reviewer proposes a fundamentally better fix (e.g. Reviewer 6 surfaces an alternative the panel missed), pause Phase 4 and ask the operator: "Reviewer suggests X instead of Y. Want to revise the plan?"

## Phase 4 — plan revision (orchestrator writes `/tmp/fix-bug-plan-<id>-v2.md`)

The revised plan must:

- Address every BLOCKING item with an explicit response (accepted / rejected with reason / deferred to follow-up).
- Note every change from v1 in a "What changed" section at the top.
- Re-state confidence levels (they should generally go up after review; if they go down, that's a signal to investigate further before implementing).
- Include any **diagnostic probes** the panel recommended. These are tiny, low-risk experiments to disambiguate competing hypotheses. Run them before committing to a code shape.

Once written, get explicit operator approval before Phase 5. If the operator wants more research or different angles, loop back to a targeted mini-fanout (3-5 agents) rather than redoing the full Phase 1.

## Phase 5 — implementation (orchestrator only, no agents)

The orchestrator applies the changes. Follow the local language / project conventions (gofmt, prettier, black, rustfmt, etc.). Use `TaskCreate` / `TaskUpdate` to track each change as a separate task.

For each change:

1. Apply the edit (`Edit` / `Write`).
2. Build (`go build`, `npm run build`, `cargo check`, etc.).
3. Run the test plan from Phase 4.
4. Lint (`golangci-lint`, `eslint`, `ruff`, `clippy`).
5. If anything fails, fix forward — do not silently skip.

Track which file is in which state. Resist the urge to make "while I'm here" cleanup changes that aren't in the plan — those are separate refactors.

### End-of-phase summary (operator-facing, mandatory)

After every change has been applied + built + tested, print a recap to chat with one block per addressed item, blocks separated by `---`. Each block has FIVE required fields, in this exact order:

```
author: <display name>
issue: <one-sentence paraphrase of what they raised>
comment: <short verbatim snippet from the comment, ≤120 chars, truncate with … if longer>
fix: <one-sentence what changed, with file:line>
link: <permalink to the comment / review / ticket>
```

The `comment:` field is non-optional. It carries the verbatim text the reviewer wrote so the operator can recognise each item without clicking through to the source. If the original is multi-paragraph, take the first sentence (or the most operational sentence) and truncate; the full text is one click away via `link:`. If the source is a Linear ticket description or a freeform stack-trace paste with no quotable line, write `comment: (no verbatim text — see link)` rather than omitting the field.

Worked example:

```
author: Bjorn Tipling
issue: gRPC code on the rate-limit path is wrong — ResourceExhausted tells the SDK to give up; use DeadlineExceeded so it retries.
comment: "the gRPC code is wrong — use DeadlineExceeded, not ResourceExhausted, so the SDK retries"
fix: pkg/auth/middleware.go:42 — switched ResourceExhausted → DeadlineExceeded; updated the matching error-wrap in pkg/auth/errors.go:18.
link: https://github.com/example/repo/pull/42#discussion_r1234567890
---
author: Jane Doe
issue: nit — rename `x` to `xs` in iterateThings(), plural reads better.
comment: "nit: rename `x` to `xs`, plural reads better here"
fix: pkg/foo/bar.go:128 — renamed `x` to `xs` throughout iterateThings (3 sites).
link: https://github.com/example/repo/pull/42#discussion_r1234567891
---
author: John Allers
issue: split the test-server change into its own commit so the review boundary is clean.
comment: "can you split the test-server change into its own commit"
fix: no code change; reorganised the local commit history — test-server diff is now commit 2 of 2.
link: https://linear.app/example/issue/CXH-1235#comment-abc123
```

Rules for each field:
- `author:` is the display name (e.g. "Bjorn Tipling", "John Allers"). Fall back to gh login only when the source has no display name.
- `issue:` is your paraphrase, not a copy-paste of the comment. Keep it to one sentence; the goal is for the operator to read the recap and recognise what each person asked.
- `fix:` cites `file:line` and explains what changed in one sentence. If the resolution is a non-code change (reorganised commits, deferred to follow-up ticket, etc.), say so explicitly. Three sub-cases for the level of detail to include:
  - **Trivial change** (rename, typo, one-line tweak, swap a constant): the one-sentence `fix:` line on its own is enough. No snippet, no warning.
  - **Non-trivial but explainable in a short snippet** (≤ 15 lines): include a fenced code block on the line BELOW `fix:` showing the gist of the change. Use the diff-fragment style or before/after — whichever reads cleaner. The snippet exists to save the operator a `git diff` round trip when they're skimming, not to reproduce the diff verbatim.
  - **Genuinely complex change** (cross-file refactor, subtle invariant rework, anything where a 15-line snippet would mislead more than help): leave OFF the snippet and END the `fix:` line with a full-caps warning so the operator knows to actually open the diff before approving. Use the literal phrase `` `COMPLEX CHANGE PAY ATTENTION ⚠️⚠️` `` (inline code, backtick-wrapped, the two warning emojis included).

  Worked examples for each sub-case:

  ```
  author: Jane Doe
  issue: nit — rename `x` to `xs` in iterateThings(), plural reads better.
  comment: "nit: rename `x` to `xs`, plural reads better here"
  fix: pkg/foo/bar.go:128 — renamed `x` to `xs` throughout iterateThings (3 sites).
  link: https://github.com/example/repo/pull/42#discussion_r1234567891
  ---
  author: Bjorn Tipling
  issue: gRPC code on the rate-limit path is wrong — ResourceExhausted tells the SDK to give up; use DeadlineExceeded so it retries.
  comment: "the gRPC code is wrong — use DeadlineExceeded, not ResourceExhausted, so the SDK retries"
  fix: pkg/auth/middleware.go:42 — switched ResourceExhausted → DeadlineExceeded so the SDK retry path fires.
  ```go
  // before
  return uhttp.WrapErrors(codes.ResourceExhausted, "rate limited", err)
  // after
  return uhttp.WrapErrors(codes.DeadlineExceeded, "rate limited", err)
  ```
  link: https://github.com/example/repo/pull/42#discussion_r1234567890
  ---
  author: Alice Smith
  issue: auth session-store integration needs to move from in-memory to persistent; current shape leaks tokens across tenants under high concurrency.
  comment: "the session-store needs to move from in-memory to persistent — current shape leaks tokens across tenants under high concurrency"
  fix: pkg/auth/session.go + 6 other files — rewrote the session layer to use attrs.Session, threaded through every grant/revoke path, moved the in-memory cache behind a TTL-bounded write-through wrapper. `COMPLEX CHANGE PAY ATTENTION ⚠️⚠️`
  link: https://github.com/example/repo/pull/42#pullrequestreview-2345678900
  ```
- `link:` is the permalink to the source item:
  - PR conversation comment: `https://github.com/<owner>/<repo>/pull/<num>#issuecomment-<id>`
  - PR review (entire review): `https://github.com/<owner>/<repo>/pull/<num>#pullrequestreview-<id>`
  - PR inline review comment: `https://github.com/<owner>/<repo>/pull/<num>#discussion_r<id>`
  - Linear ticket comment: `https://linear.app/<workspace>/issue/<id>#comment-<commentId>`
  - Linear ticket itself (no specific comment): the ticket URL
  When running under auto-new-day, the source IDs are in the dispatch JSON's `feedback[]` entries; construct the URL from the IDs there. If a link genuinely cannot be constructed, write `link: (no permalink available)` rather than omitting the field.

### Defer policy — bias toward "just do it"

Before writing a `Deferred:` block for any item, apply this rule:

**Default: do NOT defer. Apply the change in this pass.** Even if the item is technically outside the immediate bug's scope, if it is a simple safe change, do it now — a deferred fix that could have taken ten seconds becomes a note the operator must chase later. Concrete things that MUST NOT be deferred:

- Updating an error string / log message / user-visible wording.
- Adding permission metadata (`capabilityPermissions(...)`, IAM scopes, OAuth scope lists) that was missing.
- Creating or renaming a small helper function.
- Fixing a broken import, missing return, dead variable, or obviously wrong constant.
- One-line doc / comment / README correction.
- Adding a nil check, gRPC code, or context propagation that was clearly missed.
- Any change of roughly three lines or fewer that carries no design decision.

**Defer ONLY when the item is genuinely complex or difficult.** Concrete triggers for a real defer:

- Adding a new feature, user-visible flow, or new API surface.
- Adding a new resource type / builder / provisioning surface / capability.
- A non-trivial refactor: moving files across packages, redesigning a client, rewriting sync semantics.
- A design call the operator has to make (which endpoint, which auth model, which capability shape).
- Anything that requires a separate ticket, a live tenant that's not available, paid-tier access, or vendor coordination.
- Anything blocked upstream by another team's managed file, an unmerged spec, or missing docs.

When in doubt, do the change. A wrongly-not-deferred simple edit is at worst a small extra diff; a wrongly-deferred simple edit costs the operator's follow-up cycle.

The `defer reason:` line must read as either "this genuinely needs its own effort because X" (name the concrete blocker) OR, if you cannot articulate that, drop the defer and apply the change instead.

If any item could NOT be addressed, append a "Deferred:" section after the last `---`, formatted the same way but with `fix:` replaced by `defer reason:` and `link:` retained:

```
Deferred:

author: Alice Smith
issue: refactor the entire auth subsystem to use the new session-store API.
comment: "we should move the whole auth subsystem off the in-memory session store and onto the new attrs.Session API"
defer reason: out of scope for this PR; the auth subsystem refactor is its own multi-PR project. Recommend opening a follow-up ticket.
link: https://github.com/example/repo/pull/42#discussion_r1234567892
```

Under auto-new-day specifically, also append the deferred block(s) to `~/work/.auto-new-day/dispatch/<TICKET_ID>.blocked.md` so the morning report surfaces the count.

This recap is the artifact the operator uses to reply to each reviewer at PR-comment-resolution time. Each block maps 1:1 to a "Resolve" click in the PR review UI; the `link:` field is the one the operator clicks to jump straight to that conversation.

## Phase 6 — validation fan-out (N3 agents, default 3)

Spawn N3 final validators in parallel. They review the IMPLEMENTED diff, not the plan.

- **V1 Correctness** — does the applied fix actually resolve the original symptom? If a reproducer was built in Phase 1, does it now pass?
- **V2 Regression check** — do other related code paths still work? Specifically look at what the plan said was OUT of scope and confirm those areas weren't touched accidentally.
- **V3 Completeness** — loose ends: open follow-up tickets, doc updates, release notes, observability, runbook entries. Anything the operator should do before merging.

### Validation agent prompt template

```
You are <validator name>, one of N3 final validators.

Diff to validate: <path to patch file or branch reference>
Plan it implements: /tmp/fix-bug-plan-<id>-v2.md
Original bug context: <one-paragraph recap>

YOUR ANGLE: <V1, V2, or V3 above>

Read the diff in full first. Run the build + test + lint commands yourself
(do not trust the orchestrator's claim that they pass). Then answer:

<3-5 targeted questions for this angle>

Report under <N> words. Output format:
- BLOCKING / IMPORTANT / NIT items with file:line.
- Build / test / lint results (paste the relevant output).
- Per-symptom confidence score using the "Confidence reporting" tiers and
  caps (empirical / indirect / inferred starting tier, then minus caps for
  every unverified path). One row per symptom. Cite WHAT you actually ran
  (or couldn't) for each verdict.
- Verdict: SAFE-TO-MERGE / FIX-FIRST / NEEDS-DISCUSSION.

A SAFE-TO-MERGE verdict is incompatible with any symptom score below 85% on
the empirical tier or 75% on the indirect tier. If the score is lower than
that, the verdict is FIX-FIRST (run the missing test) or NEEDS-DISCUSSION
(the operator has to accept the gap explicitly).

Do NOT modify any source file. You're verifying, not editing.
```

Word cap suggestion: 600 words per validator.

### Reacting to validation

- All three say SAFE-TO-MERGE → write a short summary to the operator and stop. Do NOT auto-commit or auto-push (that's an explicit operator decision per the global Git rules in `~/.dotfiles/general/.claude/rules/git.md`).
- Any BLOCKING item → loop back to Phase 5 (fix forward), then re-run Phase 6 (the same 3 agents or a smaller set targeted at the changed area).
- Any IMPORTANT item → surface to the operator, ask for accept/defer.
- One validator says NEEDS-DISCUSSION → bring that finding to the operator before deciding.

### Consolidating confidence

After all three validators return, the orchestrator combines their per-symptom scores into a single Confidence breakdown table (same format as Phase 2). Rules:

- For each symptom, take the MINIMUM score across the three validators. A validator who said "I couldn't actually run the failing path" pulls the score down even if the other two were optimistic.
- The composite score is the minimum across symptoms.
- Surface this number FIRST in the operator-facing summary. Don't lead with "all checks pass" — lead with "Composite confidence: N%, breakdown follows."
- If the composite is below 85%, the operator-facing summary must explicitly name the closest empirical test that's still missing (e.g. "no run against >100-member tenant", "couldn't reproduce on prod-only timezone", "fix relies on vendor behavior we couldn't probe"). Offer concrete options to close the gap (spin up a paid plan, ask the original reporter to test, ship with monitoring).

The operator gets the truth, not a pep talk. A 70% confident fix is fine to ship if the operator accepts the risk; saying "ready to merge" when the score is 70% is not.

## Phase 7 — open the implemented diff in Hunk

After Phase 6's validators return (or the operator accepts a sub-95% composite), invoke the `report` skill against the implemented diff so the operator returning to the session has a one-click review of every change that landed. Do this BEFORE printing the operator-facing summary; the summary should reference the Hunk tmux window by name.

**`--skip-hunk` short-circuit.** If `--skip-hunk` was passed in `$ARGUMENTS`, skip Phase 7 entirely and exit after the operator-facing summary at the end of Phase 6. Callers that wrap fix-bug and run their own pre-Hunk tail use this to keep ordering correct (e.g. a wrapper that invokes `/auto-new-day:fix-bug ... --skip-hunk`, runs its own project-specific validation, then calls `hunk` itself so extra reports show up alongside the diff). The summary in `--skip-hunk` mode says `Hunk skipped (caller will open it)` instead of naming a window.

**Hunk-note status markers (mandatory).** For every note this skill attaches via `hunk`, anchored to a comment / CHANGES_REQUESTED item / validator finding, include a status block at the top of the note body so the operator can scan the diff and immediately tell what's resolved:

```
fixed:    yes | no
deferred: yes | no
done:     yes | no
reason:   <one short line — REQUIRED if any of: fixed=no, done=no, or deferred=yes>
```

- `fixed: yes` — the implementation directly resolved the issue (apply for almost every Phase 5 change tied to a Phase 1/3 finding).
- `deferred: yes` — the operator-facing summary names a follow-up; the issue is acknowledged but not addressed in this diff (use sparingly).
- `done: yes` — sub-task complete (e.g. "regression test added", "doc updated"). Distinct from `fixed:` which targets the original symptom.

**The `reason:` line is REQUIRED on any note where `fixed: no`, `done: no`, or `deferred: yes` — i.e. anywhere the operator can't just read "all green" and move on.** One short line ("vendor docs unreachable, retrying tomorrow"; "needs >100-member tenant to reproduce, parking until prod test"; "out of scope of this ticket — opened CXH-NNNN to track"). Omit `reason:` only when all three flags are `fixed: yes / done: yes / deferred: no` (the unambiguously-done case).

Set the three flags independently. A typical fix-bug note ends up `fixed: yes / deferred: no / done: yes` (no reason needed). A deferred item is `fixed: no / deferred: yes / done: no` with a `reason:` line explaining the punt.

- Pass the diff range that matches what fix-bug actually added this run, not the whole feature branch. The operator wants to see the FIXES, not re-review the full PR.
  - **Addressing review feedback on an already-pushed branch** (the common `auto-new-day` / "fix PR comments" case): use `origin/<branch>..HEAD` so Hunk shows ONLY the commits this run added on top of the current PR head. The operator focuses on what changed since the reviewers last saw it.
  - **Fresh branch with nothing pushed yet**: use `<base>..HEAD` (typically `main..HEAD`).
  - Pick the range by checking the upstream: `git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null` resolves to `origin/<branch>` when the branch tracks a remote head. If that's set AND `git rev-list --count "@{u}..HEAD"` > 0, default to `@{u}..HEAD`. Otherwise fall back to `<base>..HEAD`.
  - If the operator explicitly asked for the full PR diff ("show me everything", "full diff"), honor that with `<base>..HEAD` regardless.

- **Hand the recap to Hunk as a `pr_feedback` payload.** Build a JSON file at `/tmp/fix-bug-pr-feedback-<id>.json` from the End-of-phase recap blocks (Phase 5's `author / issue / comment / fix / link` data), one entry per addressed thread. The schema lives in `~/.claude/skills/report/SKILL.md` → "PR-feedback path". Mapping is one-to-one from the recap fields to the schema:
  - recap `author` → `author` (display name) and `author_handle` (the gh / glab login, derived from the link's host + slug if not already known)
  - recap `comment` → `comment`
  - recap `fix` → `fix_summary` (drop the `file:line —` prefix; just the "what changed" phrase)
  - recap `fix`'s `file:line` → `fix_file` + `fix_line` (parse from the prefix)
  - recap `link` → `thread_link`

  Skip Deferred-block entries (they don't have a fix line in the diff). Then invoke Hunk with `pr_feedback=/tmp/fix-bug-pr-feedback-<id>.json` in `$ARGUMENTS`. Hunk's Round 1 detection picks up the path and attaches one short note per entry in addition to its usual Feature Explanation + complex-flow notes.
- Do NOT manually open tmux / `git diff | less` / `delta` and call it "hunk". The `hunk` skill owns the tmux + notes-attached flow; this skill delegates and trusts it.
- If `hunk` (or `tmux`) is unavailable in the current session (explicit operator opt-out, headless CI run, sandbox without tmux), fall back to printing `git log --oneline <base>..HEAD` + `git diff --stat <base>..HEAD` in the summary and note the fallback reason. Don't reimplement the Hunk UX.
- In a push-blocked session (e.g. dispatched by `auto-new-day`), Hunk still runs locally; the operator reviews the diff on return and pushes manually.

The summary printed after Phase 7 names the Hunk window the operator should attach to, and lists the composite confidence number FIRST per the Consolidating-confidence rules above.

## Phase 8 — audit lazy-file coverage

After Hunk is open, invoke the `lazy-gaps` skill with the dispatched feedback list (or, if the bug wasn't review-driven, the per-symptom finding list from Phase 6) as the source. This closes the loop: every actionable item either becomes a persisted rule the next dispatched run picks up, or is logged as "intentionally not worth a rule".

- Pass `scope=auto` (default; cwd's ancestor walk picks the right files). When called by `fix-bug-work`, the wrapper passes `scope=work` instead.
- Skip Phase 8 entirely when invoked with `--skip-hunk` (`fix-bug-work` runs its own scoped invocation as part of its tail).
- Skip Phase 8 when Phase 5 made zero edits (nothing to draw rules from) or when the bug was a pure runtime / vendor-side issue with no portable lesson.
- The lazy-gaps skill owns its own per-item approval gate; do NOT pre-approve edits in this skill's voice.

## Phase 0c / Phase 9 — Dispatch resume hooks

This skill participates in the shared dispatch-resume contract (operator-facing `--date <date>` / `--force` args plus a manifest read at start and write at end). See [`references/dispatch-resume.md`](references/dispatch-resume.md) for the full block, key derivation, and skip conditions.

- **Phase 0c** runs the start-of-run resume check BEFORE Phase 0 triage. If a prior manifest exists (and `--force` was not passed), fast-path: re-invoke `/report` with the saved `diffRange` + `prFeedbackPath`, print the saved verdict / reason / artifacts, exit. No agent fan-out.
- **Phase 9** runs at the end (after Phase 7 / Hunk + Phase 8 / lazy-gaps): the per-run snapshot command (`eval "$AUTO_NEW_DAY_SNAPSHOT_CMD" || true` when set) AND the manifest write so the next dispatch can fast-path.

Skip both hooks when invoked with `--skip-hunk` — a calling wrapper owns the close in that path (avoids double-write).

Both `--date` and `--force` must be accepted in this skill's `$ARGUMENTS` parsing and threaded to `dispatch-done.sh` via the `--date "$DATE"` flag.

## Output artifacts

When the cwd is inside a git repo, write the operator-only artifacts under `<repo>/.inreview/<DATE>/auto-new-day:fix-bug/<key>/` so the dispatch-resume contract (auto-new-day's per-date archive) picks them up. Otherwise, fall back to `/tmp` (operator outside a repo, no archive needed).

```
<repo>/.inreview/<DATE>/auto-new-day:fix-bug/<key>/
├── plan-v1.md         # initial plan (Phase 2)
├── plan-v2.md         # revised plan (Phase 4)
└── validation.md      # validators' consolidated findings (Phase 6)
```

Where `<DATE>` = `--date` arg or today, and `<key>` = the manifest key derived per `references/dispatch-resume.md` (ticket id from branch when in a `cxh-NNNN-...` branch, else repo basename).

Fallback layout (cwd not in a repo):
- `/tmp/fix-bug-plan-<id>.md` — initial plan (Phase 2).
- `/tmp/fix-bug-plan-<id>-v2.md` — revised plan (Phase 4).
- `/tmp/fix-bug-validation-<id>.md` — validators' consolidated findings (Phase 6).

These files are **operator-only**. Do NOT `git add` them. They are not part of the PR; `.inreview/` is gitignored globally. If the operator wants any of this in the PR description, they will copy-paste it themselves.

## Don't-do list

- Don't spawn investigation agents before Phase 0 (triage). The summary makes the rest 2x cheaper.
- Don't write the plan before all (or nearly all) investigation agents return. Early synthesis bakes in unconfirmed hypotheses.
- Don't skip Phase 4 if reviewers raised BLOCKING items. The whole point of the review phase is to catch those.
- Don't auto-commit or auto-push. Even with all-green validation, the operator owns the commit + PR decision.
- Don't reuse agent angles. Two agents with the same prompt is parallelism waste.
- Don't extend `$ARGUMENTS` parsing into a full DSL — if the operator's input is unusual, just ask them.
- Don't write multi-paragraph "thinking out loud" between phases. Operator gets one short transition message per phase.
- Don't run the skill for trivial bugs. The 20+ agent overhead is wasted on a one-line fix.
- Don't claim ≥95% confidence on a symptom that wasn't observed end-to-end. Per the caps in "Confidence reporting", static checks + mocks + scaled-down repros top out at 90%. Anything above is reserved for "I watched the failing symptom disappear on the failing environment."
- Don't average per-symptom confidence scores. The composite is the MINIMUM. A fix that's 95% on one symptom and 60% on another is a 60% fix overall.
- Don't bury the confidence number. Lead with it in the operator-facing summary.

## When validation disagrees

If two of three validators say SAFE-TO-MERGE and one says FIX-FIRST, the answer is FIX-FIRST. The validator who flagged the issue has the burden of proof; the operator can override, but the default is to address every flagged BLOCKING item before merge.

If all three disagree on a fundamental question (e.g. "is the fix correct"), that's a Phase 1 failure — the root cause was misdiagnosed. Loop back to a fresh investigation fanout with new angles informed by what the validators saw.

## Sibling skills

- `code-review:code-review` — single-pass code review of an existing diff. Use that for "review this PR", NOT for "find the bug".
- `hook-review`, `neovim-plugin-review`, `readme-md-improver`, `skill-md-improver` — artifact-specific multi-agent reviews. Use one of those when the artifact is a hook / nvim plugin / README / SKILL.md respectively.
- `simplify` — single-pass code cleanup of a recent diff. Run after Phase 5 if the orchestrator's edits left rough patches; do NOT run during a phase.

## Notes for future maintainers

- The 12/6/3 default is calibrated to "medium-complex production bug". Trivial bugs don't need the skill; truly gnarly bugs (security incidents, data-loss regressions) might benefit from a heavier fanout (24/12/6).
- The angle taxonomy in Phase 1 is a pool, not a checklist. A bug with no concurrency doesn't need A8; a bug with no external API doesn't need A11/A14. Pick what applies.
- The review angles in Phase 3 are more universal — every bug benefits from R1-R6. Add R7+ for high-blast-radius changes.
- The validation phase is intentionally smaller. By the time the code is implemented, the panel is checking the work, not searching for new failure modes.
