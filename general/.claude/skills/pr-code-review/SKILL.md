---
name: pr-code-review
description: Multi-angle review of one OR more GitHub PRs. Spawns a configurable number of parallel diff-anchored subagents per PR (default 6 standing angles + 1 conditional external-API verifier; user can override). Loads applicable CLAUDE.md / CLAUDE.local.md / lazy rules from cwd, walking up to home, before fanning out, and passes the loaded rules to every subagent. After the review agents return, spawns a second parallel verification pass that has DIFFERENT subagents fact-check every factual claim against the actual code, dependencies, or external docs. Each consolidated finding ships with a confidence percentage (0-100%) and a ✓ marker if a separate verifier confirmed it. Opens Hunk with ALL findings attached first, then asks the operator a yes/no whether to reduce to the most important + highest-confidence findings (the skill picks an integer between 1 and 5 based on confidence and importance), then walks each surviving finding with the user for Yes-post / Edit / Skip. Trigger on "/pr-code-review <pr-or-list>", "code review this PR with N subagents", "review these PRs with subagents", "do a multi-angle review of PR #N", or any explicit request to deeply review one or more PRs. Use `pr-code-review` for explicit PRs with operator-in-the-loop comment posting. Sibling skills (project-scoped batch drivers like `pr-code-review-all`) call this skill under the hood.
argument-hint: <pr-or-list> [count=<N>] (e.g. https://github.com/owner/repo/pull/80, "owner/repo#80 owner/other-repo#42 count=9", or "9 <url1> <url2>")
---

# pr-code-review

Multi-PR multi-angle review with verified findings, confidence scoring, and operator-in-the-loop comment posting. One or more PRs per invocation. Each subagent flags only issues anchored to `+` lines in the diff. Each factual claim is independently fact-checked by a different subagent before the operator sees the table. The operator approves each finding before it lands on the PR.

See `references/examples.md` for sample findings, comment phrasing, and ask/post loop output.

## When to run

- User types `/pr-code-review <pr>` or `/pr-code-review N <pr1> <pr2> ...` and asks to "review this PR with subagents" / "review these PRs with N subagents".
- User pastes one or more PR URLs and asks for a deep review with posted comments.

Do NOT trigger for:
- A drive-by skim where the user only wants prose feedback (just review inline).
- Reviewing the user's own PR before opening it (use project-specific pre-PR validators when available).

## Inputs

One or more PR references, in any of these shapes per PR:
- `https://github.com/<org>/<repo>/pull/<N>`
- `<org>/<repo>#<N>`
- `#<N>` (only if cwd is inside the repo clone)

Multiple PRs are space-separated in the arg string. Order does not matter; agents fan out across all PRs in parallel.

Optional flags inside the arg string:
- A bare leading integer (`9 <urls...>`) OR `count=<N>` → number of subagents per PR. Default `6` standing angles + `1` conditional external-API verifier. Valid range `3..12`. Clamp silently outside that range.
- `target_session=<tmux-session>` — when set, the inner `hunk` call opens its TUI as a new window inside that session. Forwarded by sibling batch drivers.
- `force_new_window=true` — when set without `target_session`, the inner `hunk` call opens a new window in the current session regardless of pane count.

This skill ignores the hunk pass-throughs itself and forwards them verbatim when it invokes `Skill(hunk)` in the open-Hunk step.

Parse each PR reference to `OWNER`, `REPO`, `PR_NUM`. If any reference is malformed, ask the user.

## Step 0. Multi-PR dispatcher (skipped for single PR)

If MORE than one PR was passed AND `target_session` was NOT passed in (i.e. this is an operator-driven multi-PR run, not a batch driver calling us), the current session acts as a dispatcher: it does no review work itself. Instead it opens a tmux session called `<folder>-code-review` (where `<folder>` is `basename "$(pwd)"` slugified) and spawns one window per PR with a fresh `claude --dangerously-skip-permissions` instance reviewing that single PR.

Why: each PR's review is independent, can take minutes, and benefits from running in its own claude context. The operator attaches to the session and watches each PR in its own window without cross-contamination.

Implementation:

**Prefer the shipping `review` util** at `$SCRIPTS/shared/utilities/review` (or wherever the operator keeps it on `$PATH`). It handles slugifying the folder name, dispatching each URL into its own window, switching the operator to the session if already in tmux (or printing `tmux attach` if not), and works under any `tmux base-index`. Just call:

```bash
review "<space-separated PR/MR URLs>"
```

If `review` is not on PATH, fall back to the inline equivalent below. The fallback must:
- capture the placeholder window's actual index (`tmux list-windows -F '#{window_index}' | head -n1`) instead of hardcoding `:0`, since `base-index` can be `0` or `1`
- end with `tmux switch-client -t "$session"` when `$TMUX` is set, or `echo "attach with: tmux attach -t $session"` otherwise

```bash
folder=$(basename "$PWD" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')
[ -z "$folder" ] && folder="review"
session="${folder}-code-review"

placeholder_idx=
if ! tmux has-session -t "$session" 2>/dev/null; then
  tmux new-session -d -s "$session" -n placeholder
  placeholder_idx=$(tmux list-windows -t "$session" -F '#{window_index}' | head -n1)
fi

posted=0
for url in "${pr_urls[@]}"; do
  win_name=$(name_for "$url")  # e.g. <repo>-<N>
  cmd="claude --dangerously-skip-permissions '/pr-code-review ${url}'"
  if [ -n "$placeholder_idx" ] && [ $posted -eq 0 ]; then
    tmux rename-window -t "${session}:${placeholder_idx}" "$win_name"
    tmux send-keys     -t "${session}:${placeholder_idx}" "$cmd" C-m
  else
    tmux new-window -t "${session}:" -n "$win_name" "$cmd"
  fi
  posted=$((posted + 1))
done

echo "dispatched $posted PRs to tmux session '${session}'"
if [ -n "${TMUX:-}" ]; then
  tmux switch-client -t "$session"
else
  echo "attach with: tmux attach -t ${session}"
fi
```

After dispatching, exit the skill. Do not proceed to Step 0a / Step 1 / etc. on the original claude. Those steps belong to the per-PR claude instances in the spawned windows, each of which sees ONE PR url via `/pr-code-review <url>` and runs the single-PR flow end-to-end.

If `target_session` IS set (batch mode driven by a sibling skill), proceed to Step 0a as before. The parent owns the session layout, and per-PR Hunk windows go inside that session.

If only ONE PR was passed, proceed to Step 0a directly. The dispatcher mode is multi-PR-only.

## Step 0a. Load applicable CLAUDE.md rules BEFORE fanning out

The review agents need the same project rules the main session uses. This skill ALWAYS loads:

1. **Home CLAUDE.md** — `~/CLAUDE.md` (global rules) and `~/CLAUDE.local.md` if it exists.
2. **Ancestor CLAUDE.md walk** — from `cwd` up to `$HOME`, include every `CLAUDE.md` / `CLAUDE.local.md` found along the way. This picks up project-root and intermediate-scope rules without enumerating them by hand.
3. **Repo-local CLAUDE.md** — once `REPO_DIR` is resolved (Step 0b below), also load `$REPO_DIR/CLAUDE.md` and `$REPO_DIR/CLAUDE.local.md` if they exist.
4. **Lazy files whose triggers fire for the review work itself.** Many CLAUDE.md files in the ancestor walk point at `.claude/lazy/*.md` rule files with `**Read when**` clauses. Walk each loaded CLAUDE.md, collect any `.claude/lazy/*.md` references, and load each one whose trigger fires on the current work. Triggers commonly relevant to this skill:
   - "running `gh` subcommands" (the skill runs many)
   - file-pattern triggers that match files touched in any PR's diff (test files, CI workflows, package directories, action handlers, etc.)
   - any explicit "PR review" / "code review" trigger
   Err broader on a match: a wasted load is fine, a silently-missed load is not.

Build one **CONTEXT_PACK** containing the full text of every loaded file, with a header per file showing the source path. Write it to `/tmp/pr-review-context-pack.md` and also keep the in-memory string. The pack feeds into each subagent prompt at Step 3.

**The coordinator (this skill) decides per agent how to pass rules to subagents.** Pick from:

1. **Inline full text.** Embed the relevant CLAUDE.md section(s) directly in the agent's prompt body. Best for short, must-read rules every agent needs (e.g. project-wide style or correctness rules that apply across angles). All standing agents should get these inline.
2. **Path-index only.** List the loaded files by path and tell the agent to `Read` whichever match its lens. Best for thick reference docs the agent may or may not need. The agent loads on demand from `/tmp/pr-review-context-pack.md` or the original path.
3. **Both.** Inline the must-read block + an index of additional files. Default for the standing six angles.

Subagents MAY walk the CLAUDE.md tree themselves if their prompt instructs them to, but the coordinator should bias toward pre-loading. The reason: every subagent walking the tree means N × ancestor-walk cost. The coordinator already did it once; reuse that work.

For each angle, decide which loaded files matter. Examples:
- **error-handling** agent: inline any project-wide error-propagation rules; path-index deeper language/framework references that may or may not apply.
- **pagination** agent: inline any project-wide pagination/list-iteration rules; path-index framework specifics.
- **tests** agent: path-index any test/CI rule files; nothing inlined unless the project has hard rules every test must follow.
- **API surface** agent: don't pass CLAUDE.md rules (they don't help with vendor docs); pass vendor doc URLs from the PR description instead.

If `cwd` is outside any project checkout (e.g. running this skill from `~`), still load home + any ancestor-walk rules; the per-repo CLAUDE.md is filled in once `REPO_DIR` resolves per PR.

## Step 0b. Resolve the local checkout (per PR)

For each PR, the diff and the inline-comment workflow both need a local clone. The skill tries common checkout locations in priority order, falling back to a fresh clone in `$HOME/repos` (or the operator's preferred root if one is set in `$PROJECTS` / `$CODE` / similar env vars).

```bash
# Try common locations the operator already uses, then clone if none match.
candidates=(
  "$HOME/work/$REPO"          # work-scope checkouts, if any
  "$HOME/repos/$REPO"
  "${PROJECTS:-$HOME/projects}/$REPO"
  "${CODE:-$HOME/code}/$REPO"
)
REPO_DIR=""
for c in "${candidates[@]}"; do
  [ -d "$c/.git" ] && { REPO_DIR="$c"; break; }
done
if [ -z "$REPO_DIR" ]; then
  REPO_DIR="${PROJECTS:-$HOME/repos}/$REPO"
  gh repo clone "$OWNER/$REPO" "$REPO_DIR"
fi
cd "$REPO_DIR"
git fetch origin "pull/$PR_NUM/head:pr-$PR_NUM" -f
git checkout "pr-$PR_NUM"
```

The `-f` covers the case where the local clone already has a `pr-<N>` branch from a prior run.

When multiple PRs are passed, run the per-PR checkout sequentially (different repos can't safely `cd` in parallel inside the same shell). Each PR's diff lands in `/tmp/pr-<N>.diff` so the agents stay isolated.

Also reload the CONTEXT_PACK from Step 0a now that `$REPO_DIR/CLAUDE.md` is reachable. Append the repo-local file if present.

## Step 1. Fetch PR metadata and diff (per PR, in parallel across PRs)

For each PR, in a single message run these in parallel:

```bash
gh api "repos/$OWNER/$REPO/pulls/$PR_NUM" \
  --jq '{title, body, head: .head.sha, base: .base.ref, additions, deletions, changed_files, author: .user.login}' \
  > "/tmp/pr-$PR_NUM.meta.json"

git diff "origin/$(jq -r .base /tmp/pr-$PR_NUM.meta.json)...pr-$PR_NUM" > "/tmp/pr-$PR_NUM.diff"

gh api repos/$OWNER/$REPO/pulls/$PR_NUM/comments --jq '.[] | {path, line, body: (.body[0:200])}' > /tmp/pr-$PR_NUM.existing-comments.json
gh api repos/$OWNER/$REPO/issues/$PR_NUM/comments  --jq '.[] | {body: (.body[0:300])}'           > /tmp/pr-$PR_NUM.existing-issue-comments.json
```

If the project has well-known noise paths the diff should exclude (generated files, vendored code, lockfiles), pass a path filter to `git diff` here. Detect them from `.gitattributes`, `.gitignore`, or the project's CLAUDE.md rather than hardcoding any path list.

Note the `head` SHA. Every inline comment must be posted with `commit_id` equal to the PR head (FULL SHA, not abbreviated; `gh` rejects abbreviated commit IDs with `commit_id is not part of the pull request`).

## Step 2. Decide the agent count

- If the user explicitly passed `count=<N>` or a leading integer in the arg string, use that (clamped to `3..12`).
- Otherwise default to `6` standing angles + `1` conditional external-API verifier (= 7 effective max).
- The same count applies uniformly to every PR in the batch. Don't pick different counts per PR unless the user asks.

When the user requests N > 7 (default angles + 1 conditional), extend with extra angles in this order (skip the next once N is reached):

8. **Memory & performance under load** — page-size caps, per-resource sort cost, peak heap on large datasets.
9. **Concurrency & thread-safety** — concurrent calls, mutable cache state, goroutine/thread spawn paths.
10. **Backwards compatibility & migration risk** — public-ID / schema / capability stability, behavior change for existing callers or customers.
11. **Security & CI** — secret exposure, CI gate regressions, workflow secret references, dependency injection of trust.
12. **Data integrity & index/key correctness** — map-key collision risk, cross-type ID conflation, validation-invariant dependence.

(The eight angles above are NOT mutually exclusive with the standing six; pick the next-most-relevant one if the PR touches the area.)

When N < 6, drop the standing angles from the bottom up (tests/regression first, then data model, then pagination), keeping correctness + API surface + error handling as the irreducible floor.

## Step 3. Spawn N parallel review agents (per PR, all PRs in one message)

Launch every agent for every PR in a SINGLE message (parallel Agent tool calls), `run_in_background: true`. For two PRs at count=9, that's 18 agents in one batch. The runtime handles them concurrently.

Each prompt MUST include this hard constraint verbatim:

> **HARD CONSTRAINT:** only flag issues anchored to a `+` line in `/tmp/pr-<N>.diff`. Every finding MUST cite a `+` line. Skip concerns about unchanged code, even if PR behavior depends on it. Report `file:post-image-line` and the one-line excerpt of the `+` line so the user can verify it lives in the diff.

Each prompt MUST include this verification preamble verbatim:

> **VERIFICATION RULE:** every claim you make about runtime behavior, framework / SDK behavior, vendor API, or rule violation will be re-checked by a different subagent. Do NOT assert behavior you have not directly traced in the code or read in the spec. If you are uncertain, say so explicitly with a confidence percentage (0-100%) on the finding. Confidence below 60% should not be a finding. It's a question; reword as "verify this against X" rather than asserting the bug.

Each prompt MUST include the CONTEXT_PACK from Step 0a, either inline at the top (preferred for short packs) or as a path to `/tmp/pr-review-context-pack.md` with the instruction "read this file first." Subagents are NOT expected to walk the CLAUDE.md tree themselves; the main skill already did that.

Each prompt MUST include the existing-comments JSON path (`/tmp/pr-<N>.existing-comments.json` + `/tmp/pr-<N>.existing-issue-comments.json`) and instruct the agent to drop overlaps with already-posted comments.

The six standing angles (specialize each prompt around the PR's actual content, but the lens stays constant):

1. **Code correctness** — bug-fix logic, off-by-one, nil/None deref, type-mismatch in added lines. Does each claimed fix actually do what the description says?
2. **API surface** — verify new endpoints, JSON / response fields, and protocol-level shapes against the vendor's OpenAPI / Postman / official docs. Flag UNBACKED claims. Use WebFetch / WebSearch.
3. **Error handling** — swallowed errors, lost root causes, wrong error types or codes for the path, ambiguous return shapes. Whether the project requires specific wrapping / error codes / connector-prefix conventions comes from the loaded CLAUDE.md / lazy-rule context, not from this skill.
4. **Pagination & control flow** — does new list / iterator / streaming code page correctly? Off-by-one. Duplicate emission across pages. Infinite-loop or unbounded-buffer risk. Cursor / token / offset shape matches the upstream contract.
5. **Data model & contracts** — does the new code's data shape match its downstream consumers? ID stability, parent/child invariants, expandable/foreign-key targets that actually exist, type/trait correctness, schema or annotation drift between producer and consumer.
6. **Tests & regression risk** — does the PR add coverage for the changed behavior? Run the project's standard `build` and `lint` commands and report failures. Backwards-compat of any public identifier or schema field that downstream callers might depend on.

Severity tiers across all six: **BLOCKER / MAJOR / MINOR**.

Each finding now also carries an **agent-side confidence percentage (0-100%)**. The agent reports its own initial estimate; the verification step in Step 4 either confirms (✓) or revises it. The output shape per finding is:

```
{
  "agent": "<angle name>",
  "severity": "BLOCKER|MAJOR|MINOR",
  "confidence_pct": 0-100,
  "file": "path/to/file.go",
  "line": 67,
  "excerpt": "<the + line>",
  "claim": "<one-sentence assertion about behavior or rule>",
  "consequence": "<user-visible effect if claim is true>",
  "fix": "<concrete change>",
  "verifiable_by": "<file or doc URL or function the verifier should consult>"
}
```

**Do NOT flag the operator's personal style preferences.** The CONTEXT_PACK may include the operator's writing style rules (em-dash bans, comment policy, log-level preferences, naming conventions, vocabulary lists). Those are personal-config preferences, not PR-review concerns for someone else's PR. Drop entirely:
- Punctuation preferences (em-dashes, double-hyphens, semicolons in prose).
- Log-level preferences (e.g. Warn vs Debug).
- Comment style preferences: presence of any comment, comment placement, multi-line docstrings, narrative comments.
- String-literal style preferences (lowercase, no trailing periods, etc.).
- Variable casing / abbreviation preferences inherited from the operator's CLAUDE.md.

If the PR author also happens to follow these rules, that's fine; they'll see them in CI or their own review. The agent's job is to catch correctness, API, data-model, control-flow, and test issues. NOT to enforce the operator's writing style on someone else.

What you DO flag stays the same: correctness bugs, missing/wrong error types where the PROJECT (not the operator's personal config) requires them, wrong endpoints, JSON-tag mismatches, pagination shape mismatches, actually-swallowed errors, data-model issues, missing tests on changed behavior.

**Severity calibration — these are NOT blockers:**
- A naming-only nit (variable name, constant-vs-literal). MINOR.
- A doc-link URL pointing at a stale family when the spec still resolves. MINOR.
- A non-stylistic readability concern (e.g. an extracted helper would make a 50-line function clearer). MINOR.

BLOCKER is reserved for: panics, data loss, wrong authentication, broken core semantics, a wrong vendor URL / method that produces 404 at runtime, a serialization mismatch that silently drops data. If you cannot describe the user-visible failure in one sentence, it is not a BLOCKER.

Word caps: 500-700 each. Output shape per finding as above.

### Agent 7 (conditional): External-API doc verifier

**Spawn this agent when the diff introduces a new external API call.** Detection signals (any one is enough):

- A new endpoint constant or path literal in client/transport code (e.g. `"/v1/users/%s/roles"`).
- A new method that calls the HTTP client, constructs an outbound URL, or wraps a vendor SDK call.
- A new HTTP method constant (`POST` / `PUT` / `DELETE` / `PATCH`) on a `+` line in a client file.
- A new request-payload or response struct (with JSON / serialization tags) tied to a new endpoint.
- A new query parameter or required header on a `+` line in client code.

If NONE of those signals appear, do NOT spawn this agent. Agent 2 (API surface) already covers field-level checks on existing endpoints.

When spawned, the agent's prompt is:

> Review PR #<N> in <org>/<repo> for **external API call correctness**. The PR is checked out at <REPO_DIR> on branch pr-<N>. The diff is at /tmp/pr-<N>.diff. Read the CONTEXT_PACK before forming claims.
>
> The PR introduces one or more NEW external API calls. Your job: verify each new call against the vendor's official documentation. For every new call (`+` line in client code), confirm ALL of:
>
> 1. **URL exists** — the exact path is documented (cite the doc URL).
> 2. **HTTP method matches** — POST / GET / PUT / DELETE / PATCH per the spec.
> 3. **Path params** — name, position, type match the spec.
> 4. **Query params** — every query key is documented; required ones are present.
> 5. **Request payload** — serialization tags on the request struct match the spec (field names, types, required vs optional).
> 6. **Response shape** — serialization tags on the response struct match the spec.
> 7. **Auth / headers** — required auth scheme and any vendor-specific headers (e.g. `Idempotency-Key`, `X-Tenant-Id`) are present.
> 8. **Pagination contract** — if the endpoint paginates, the cursor / `has_more` / `after` / offset shape matches what the new code reads.
>
> Use WebFetch / WebSearch against the official vendor docs and OpenAPI / Postman spec. Do NOT pattern-match from REST conventions or sibling projects; cite the actual spec for every claim.
>
> **HARD CONSTRAINT + VERIFICATION RULE** (same as the other agents): every finding must anchor to a `+` line in `/tmp/pr-<N>.diff`, must include a confidence percentage, and will be re-checked by a separate verifier subagent. Report `file:line` + `+` excerpt + 1-3 sentence issue + concrete fix + the doc URL that proves your claim. Severity: BLOCKER (URL / method / required-field wrong, doesn't exist) / MAJOR (optional-field mismatch, header missing, payload shape drift) / MINOR (naming nit, missing-but-unused field). Under 600 words.

This agent's output merges into the consolidated punch-list at Step 5 just like the others.

## Step 4. Verification round (parallel, ≥1 different subagent per finding)

Once all review agents return, **spawn at least one verification agent per finding** in a single message, parallel, `run_in_background: true`. Every verifier MUST be a DIFFERENT `Agent` invocation than the reviewer that produced the finding (don't reuse the same agentId; the system already routes new Agent calls to fresh contexts).

### Verifier count scales with importance

Don't use a single verifier for every finding. The coordinator picks the count per finding based on severity and the agent's reported confidence:

| Original finding                                  | Verifiers to spawn |
| ------------------------------------------------- | ------------------ |
| BLOCKER, any confidence                           | **3 verifiers** (consensus check)   |
| MAJOR with agent confidence ≥ 80%                 | **2 verifiers**                     |
| MAJOR with agent confidence 60-79%                | **1 verifier**                      |
| MINOR, any confidence                             | **1 verifier**                      |
| Any finding that makes a CLAUDE.md-rule claim     | **+1 extra** (one verifier reads the rule file independently) |
| Any finding citing vendor API behavior            | **+1 extra** (one verifier fetches the doc independently)     |

The "+1 extra" stacks on top of the base count, so a BLOCKER that asserts framework retry behavior gets 3 base + 1 source-reader = 4 verifiers; a MAJOR that asserts an OpenAPI shape gets 2 base + 1 doc-fetcher = 3.

Fire all verifiers across all findings in ONE message. A PR with 5 findings (1 BLOCKER, 2 MAJOR-high, 2 MINOR) plus one CLAUDE-rule claim and one vendor-API claim → 3 + 2+2 + 1+1 + 1 + 1 = 11 verifiers in parallel.

### Aggregating multi-verifier results

When multiple verifiers cover one finding, aggregate by majority + confidence:

- **All verifiers VERIFIED** → final confidence = mean of verifier confidences, marker = `✓<N>` (N = total verifiers, ALL agreeing).
- **Majority VERIFIED, minority NUANCED** → final confidence = mean of VERIFIED verifiers, marker = `✓<K>/<N>` (K = VERIFIED count, N = total verifiers); body must mention the nuance from the dissenting verifier.
- **Split (50/50 VERIFIED vs FALSE/NUANCED<60%)** → DROP the finding; log the disagreement in `/tmp/pr-<N>-verification.md` so the operator can review.
- **Majority FALSE** → DROP the finding.
- **All FALSE** → DROP the finding without ambiguity.

For a single-verifier finding (MINOR or MAJOR<80%), the rules from the previous spec apply unchanged: VERIFIED keeps it (marker = `✓1`), FALSE drops it, NUANCED ≥60% keeps it (marker = `✓1` with nuance in body), NUANCED <60% drops.

**Marker shape recap:** the operator should be able to glance at the marker and know how many independent subagents looked at the claim and how many agreed.
- `✓1` — one verifier, agreed.
- `✓3` — three verifiers, all three agreed.
- `✓2/3` — three verifiers, two agreed (one NUANCED dissent retained in body).

Each verifier prompt:

> You are independently fact-checking ONE claim from a multi-angle PR review. You did not produce this claim. Your only job is to confirm or refute it.
>
> **Claim:** <agent's claim verbatim>
> **Anchored at:** <file>:<line> in PR #<N> at <REPO_DIR>, diff /tmp/pr-<N>.diff
> **Excerpt:** <the + line the original agent cited>
> **Claimed consequence:** <agent's stated consequence>
> **Verifiable by:** <agent's `verifiable_by` field>
> **Initial agent confidence:** <agent_confidence_pct>%
>
> Verify by reading source code, vendored / dependency code, or fetching external docs (WebFetch). Trace the actual runtime path or read the actual spec. Do NOT take the claim at face value.
>
> If the claim references framework / SDK behavior (e.g. "the framework retries on error X"), READ the relevant source under `$REPO_DIR/vendor/` (Go), `node_modules/` (JS), site-packages / venv (Python), or wherever the project vendors dependencies. Cite the file:line that proves or disproves it.
>
> If the claim references vendor API behavior, fetch the relevant doc page with WebFetch and quote the relevant section.
>
> If the claim references a CLAUDE.md / project-rule, check the loaded CONTEXT_PACK; do not invent the rule.
>
> Return one of:
> - **VERIFIED** + revised confidence (0-100%) + 1-2 sentences citing the evidence
> - **FALSE** + 1-2 sentences explaining why the claim does not hold (with citation)
> - **NUANCED** + revised confidence + 1-2 sentences explaining the gap (e.g. "claim is true only when X; PR is in the X=false case")
>
> Word cap: 200 words.

The verifier output sets the FINAL confidence percentage and the ✓ marker:
- **VERIFIED** → final confidence = verifier's revised confidence, ✓ marker present.
- **NUANCED** with confidence ≥ 60% → keep as a finding with verifier's confidence, ✓ marker present but the body must include the nuance.
- **NUANCED** with confidence < 60% → drop the finding entirely. It's a question, not a bug.
- **FALSE** → drop the finding entirely. Do NOT surface it to the operator. Add a one-liner to the verification log so the operator can see what was filtered.

The verification log lives at `/tmp/pr-<N>-verification.md` and is preserved for audit:

```
## Verification log for PR #<N>

| Original Agent | Claim (short) | Verdict | Final Conf | Reason |
| -------------- | ------------- | ------- | ---------- | ------ |
| correctness    | un-coded error skips framework retry | FALSE | n/a | framework retry.go:60 only retries codes A+B |
| api-surface    | endpoint X is v2-only                | VERIFIED | 88% | vendor docs confirm; PR docs.mdx also states |
```

This log is NOT shown to the operator inline (it'd be noise); only summarized in the final wrap.

## Step 5. Consolidate

Now build the punch-list from surviving (VERIFIED + qualifying NUANCED) findings. For each:

- `severity` (BLOCKER / MAJOR / MINOR)
- `confidence_pct` (final, from verifier)
- `verified` (always `true` here, since FALSE / <60% NUANCED were dropped. The ✓ goes on every surfaced finding by construction.)
- `file`
- `line` (post-image, must correspond to a `+` line in the diff)
- `body` (the comment as it will be posted. See "Comment phrasing" below.)

Dedupe overlapping findings across review agents on the same PR: two agents flagging the same line collapse to one row. Keep the higher severity and the higher final confidence. Use `references/examples.md` for examples of merged vs split findings.

**Drop overlaps with existing PR comments** using `/tmp/pr-<N>.existing-comments.json` and `/tmp/pr-<N>.existing-issue-comments.json` from Step 1. For any consolidated finding that matches an existing comment on the same `file:line` (or the same conceptual issue, even at a nearby line), drop it from the punch-list. The user has already seen it; re-flagging looks like the skill didn't read the PR.

### Comment phrasing

Comments are inline review notes, not essays. Match the operator's existing style on the repo (informal, lowercase, no em-dashes, no emojis).

- **1-3 sentences max.** State the issue, then the fix.
- **No re-quoting the code.** GitHub already shows the line.
- **Reference other files by `file:line`** when the issue spans more than the anchor line.
- **Forbidden punctuation:** em-dash `—` and double-hyphen `--`.
- **NEVER reference the operator's personal config or rules.** No "CLAUDE.md says", no "project rule says", no "the rules in ~/CLAUDE.md", no quoting of personal style configs. The PR author does not know the operator's CLAUDE.md; they should not need to. State the bug directly: what's wrong + the fix. If the only reason something is wrong is that the operator's config disallows it, the finding probably shouldn't be a comment at all, or post it as a low-severity nit phrased as a preference, not a rule citation.
- **NEVER reference internal docs paths** like `~/CLAUDE.md` or `.claude/lazy/*.md` inside a comment body. The PR author can't read those files.
- **Don't appeal to authority.** "this violates X" is weaker than "this drops the email key on unmarshal, so Message() loses the most useful field". Show the consequence; let the consequence carry the argument.
- **DO cite official vendor docs when the finding was verified against them.** Format: bare URL at the end of the comment, no `[label](url)` markdown. Single link: `(spec: https://docs.vendor.com/reference/foo)`. Multiple: `(spec: https://docs.vendor.com/reference/foo, https://docs.vendor.com/reference/bar)`. The PR author should be able to confirm the claim by clicking the link. Applies ONLY to claims actually verified, never invent a URL to make the comment look authoritative.

Examples in `references/examples.md`.

## Step 5b. Persist the consolidated report

Before opening Hunk or asking the operator anything, write the full consolidated report (all surviving findings) to a stable on-disk path so the operator can revisit it later. This ALWAYS happens, even if the operator later picks to reduce or skip all findings.

**Path:**

```
${REVIEWS_DIR:-$HOME/.reviews}/<repo>/<YYYY-MM-DD>/<author>/<pr-N>-<slug>.md
```

- `REVIEWS_DIR` is an optional env var the operator can set to relocate the archive (e.g. work-scoped under `$HOME/work/.reviews` if they want work and personal reviews separated). Default is `$HOME/.reviews`.
- `<repo>` = `$REPO`.
- `<YYYY-MM-DD>` = today, `$(date +%Y-%m-%d)`.
- `<author>` = the GitHub login of the PR's author, from `jq -r .author /tmp/pr-$PR_NUM.meta.json` (fetched in Step 1).
- `<pr-title-slug>` = sanitized PR title: lowercase, replace any non-alnum run with `-`, trim leading/trailing `-`, cap at 120 chars. Prefix with the PR number for uniqueness: `pr-<N>-<slug>.md`.

```bash
REPORT_DIR="${REVIEWS_DIR:-$HOME/.reviews}/$REPO/$(date +%Y-%m-%d)/$AUTHOR"
mkdir -p "$REPORT_DIR"
SLUG=$(jq -r '.title' "/tmp/pr-$PR_NUM.meta.json" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' \
  | cut -c1-120)
REPORT_PATH="$REPORT_DIR/pr-$PR_NUM-$SLUG.md"
```

**Contents (Markdown):** the report MUST include, in order:

1. Header line: `# PR #<N>: <title>` and a metadata block listing PR URL, author, base/head SHA, agent count, verifier counts, run timestamp.
2. The findings table from Step 6a (verbatim, same Sev / Conf / ✓ / File:Line / Headline columns).
3. One subsection per finding with the FULL comment body, the diff excerpt, the verifier verdict(s), and the resolved confidence. BLOCKERs first, MAJORs next, MINORs last.
4. Link to the verification audit log at `/tmp/pr-<N>-verification.md` and instruction to copy it into the same persisted dir if the operator wants the FALSE-drop history retained.
5. List of agents that ran (angles) and their individual report paths (`/tmp/pr-<N>.agent<K>.md`) so the operator can dig deeper.

Write the report BEFORE opening Hunk or asking the reduce question. The operator may interrupt at any point and the on-disk artifact survives.

The `reviews` CLI util (commonly at `$SCRIPTS/shared/utilities/reviews`) fzf-picks any report under `${REVIEWS_DIR:-$HOME/.reviews}/` by date or across all dates.

## Step 6. Print findings table + open Hunk with EVERY finding attached

The operator decides what to post by scanning the full picture once: a table of every surviving finding plus an open Hunk TUI showing every comment on its diff anchor. Do NOT filter or ask anything yet — open ALL findings first, then ask in Step 7.

### Step 6a. Print the findings table

Print one Markdown table per PR to the user before opening Hunk. Columns:

| # | Sev | Conf | Verified | File:Line | Headline |
| - | --- | ---- | -------- | --------- | -------- |
| 1 | BLOCKER | 92% | ✓3      | src/foo.go:42 | wrong type breaks downstream consumer |
| 2 | MAJOR   | 78% | ✓2      | src/bar.go:18 | items emitted twice across pages |
| 3 | MAJOR   | 73% | ✓2/3    | src/qux.go:55 | role mapping mismatch (1 nuance) |
| 4 | MINOR   | 65% | ✓1      | src/baz.go:91 | repeated literal could be a const |

Rules:
- BLOCKERs first, MAJORs next, MINORs last. Within tier, sort by confidence desc.
- The Verified column shows `✓<N>` when all N verifiers agreed, or `✓<K>/<N>` when K of N agreed (one or more NUANCED). Every surfaced row carries a marker by construction (FALSE / low-confidence-NUANCED rows were dropped at Step 4). The number tells the operator how much scrutiny the finding got.
- Headline is the one-line lede of the comment body (under ~70 chars). Not the full body.
- `#` matches the order the ask loop will walk in Step 8.
- If a PR has zero surviving findings, print one line per PR saying so. Continue to other PRs.

### Step 6b. Open Hunk with ALL findings

After all tables print, invoke the `hunk` skill in its **fast path** with EVERY finding (no pre-filter). One Hunk session per PR if multiple PRs are in scope.

**Before calling Skill(hunk), write the full comment batch to `/tmp/pr-<N>-comments.json`** using `newLine` anchors so each comment lands on the exact `+` line it references (never on a hunk position that resolves to an unchanged context line):

```bash
cat > /tmp/pr-<N>-comments.json <<'JSON'
{
  "comments": [
    {"filePath": "src/foo.go", "newLine": 67,
     "summary": "BLOCKER (92% ✓3): <one-line headline>",
     "rationale": "<the full comment body from Step 5>"},
    ...
  ]
}
JSON
```

Rules for the JSON:
- One entry per surviving finding from Step 5, in the same order as the table (BLOCKERs first, MAJORs next, MINORs last). NO filtering happens yet.
- `newLine` MUST match the exact `file:line` from the consolidated finding, and that line MUST be a `+` line in `/tmp/pr-<N>.diff`. If the finding describes a range, pick the most specific anchor inside the range.
- Use `oldLine` instead only for findings about a deleted line.
- NEVER use `hunkNumber` for diff-anchored findings.
- The `summary` field includes the confidence + ✓ marker so the operator sees verification status in the Hunk TUI title.

Hunk's fast path validates every anchor before applying. If you fed it a misaligned line, the apply aborts with a `MISSING ADD <file>:<line>` message; rebuild the JSON with the correct anchor and retry.

Then invoke the hunk skill once per PR:

```
Skill(hunk, args: "comments_json=/tmp/pr-<N>-comments.json range=origin/<base>...pr-<N> target_session=<forwarded if set> force_new_window=<forwarded if set>")
```

Capture the apply output — it lists one `commentId` per attached comment in the form `mcp:<session>:<index>`. Save the mapping `finding_# → commentId` to `/tmp/pr-<N>-commentids.tsv` (one row per finding, columns: `<#>\t<commentId>`). Step 7 needs it to prune dropped findings out of the Hunk session.

For multi-PR runs and no `target_session`, each Hunk invocation opens a new window in the current tmux session (the operator switches between them with the standard tmux window-switch keys).

### Step 6c. Skipping Hunk

Skip Step 6b only if `tmux` or the `hunk` CLI isn't available; print one line saying which is missing and continue to Step 7. The findings table from Step 6a still prints regardless.

### Batch-mode shortcut

If `target_session=<name>` was passed in, the operator is not driving this Claude. A sibling batch driver is moving on to the next PR. In that mode:
1. Still print the findings table to the calling parent.
2. Open Hunk as a new window inside `target_session` for each PR with EVERY finding attached (no reduce step).
3. Skip Step 7 (the reduce ask) AND Step 8 (the ask-then-post loop) entirely. The ask loop runs in a spawned Claude instance in a left pane next to the Hunk window (see batch-mode pane spawn at the end of Step 8). The batch driver only opens the full view; the operator chooses what to post when they attach.

## Step 7. Ask the operator whether to reduce findings (yes/no)

Hunk is now open with every finding attached. The operator can scan them in the TUI. Before walking the ask-then-post loop, ALWAYS ask via `AskUserQuestion`:

```
question: "<N> findings open in Hunk. Reduce to the most important + highest-confidence ones, or walk all of them?"
header:   "Reduce"
options:
  - "No, walk all <N>" (recommended when total ≤ 5)
  - "Yes, reduce" (recommended when total > 5)
```

The recommended option flips on volume: ≤5 → walk all (no reduction needed); >5 → reduce (avoids drowning the operator in low-impact MINORs).

### Step 7a. If the operator picks "Yes, reduce"

YOU (the coordinator) decide the survivor count. Pick an integer in `[1, 5]` based on the actual finding mix:

- **All BLOCKERs always survive**, up to the cap of 5.
- Fill remaining slots with MAJORs in descending confidence order.
- Fill the final slot(s) with MINORs ONLY when they have ≥ 85% confidence AND describe a concrete fix the author can apply in under 10 lines.
- If only 1 finding clears these bars, keep 1. If 5 BLOCKERs exist, keep 5.

Worked sizing:
- 1 BLOCKER + 4 MAJORs + 6 MINORs → keep 5 (BLOCKER + top 4 MAJORs by confidence).
- 0 BLOCKERs + 2 MAJORs + 8 MINORs → keep 2-3 (both MAJORs, plus 1 MINOR if it meets the high-confidence concrete-fix bar).
- 3 BLOCKERs + 0 others → keep 3 (all BLOCKERs, no padding).
- 0 BLOCKERs + 0 MAJORs + 4 MINORs all ≥ 85% → keep 1-2 (no need to surface every MINOR even if they qualify; pick the most impactful).

State the count you picked and one-sentence rationale in chat ("Reducing to 3: 1 BLOCKER + 2 MAJORs by confidence."). Do NOT ask the operator to confirm the count — you decide.

Prune the dropped findings from the Hunk session via `/tmp/pr-<N>-commentids.tsv`:

```bash
for cid in $(awk -v keep="<keep-csv>" 'BEGIN{split(keep, K, ","); for(k in K) S[K[k]]=1} !($1 in S) {print $2}' /tmp/pr-<N>-commentids.tsv); do
  hunk session comment rm "" "$cid" --repo "<REPO_ROOT>"
done
```

The empty first positional is required: `hunk session comment rm` takes `[sessionId]` then `<commentId>`; `--repo` replaces session lookup but the slot still needs `""`.

After pruning, also drop the dropped rows from the in-memory punch-list so Step 8 only walks survivors. The dropped findings stay in the persisted report at `${REVIEWS_DIR:-$HOME/.reviews}/.../pr-<N>-<slug>.md` and in the verification log at `/tmp/pr-<N>-verification.md` so the operator can recover them later.

### Step 7b. If the operator picks "No, walk all"

No pruning. Hunk stays as-is. Proceed straight to Step 8 with every finding.

## Step 8. Ask-then-post loop

**MANDATORY: read the `add-comment` skill before drafting or posting any comment in this step.** Run `Skill(add-comment)` once at the top of Step 8 (or `Read ~/.claude/skills/add-comment/SKILL.md` directly) so the voice rules, fact-check policy, examples corpus, and per-comment confirmation requirement are loaded. The skill is the source of truth for:
- Voice (1-3 sentences, lowercase, no em-dash, no greetings, plain words)
- The `references/examples.md` corpus of approved phrasings (skim it; reuse what fits)
- When to spawn fact-check verifier subagents for a draft (factual claims yes, opinions no)
- The exact `gh api ...` shape for line comments, replies, and top-level PR comments
- The MANDATORY per-comment confirmation rule (per-batch approval in summary form does NOT cover the literal posted text)

You can either (a) invoke `add-comment` per approved finding to do the actual draft+confirm+post, or (b) inline the post call here but follow add-comment's voice and confirmation rules exactly. Skipping the read is the regression that produced robot-flavored drafts in past sessions.

### Step 8a. Read operator's Hunk notes as feedback for the agent

Between Step 7 and now the operator may have opened Hunk and written their own notes on the diff. **These are NOT PR comments to post.** They are feedback / instructions / questions directed at the agent (you) about the agent's drafts. Read them, act on them, then adjust the agent drafts before walking the per-finding ask loop.

```bash
hunk session comment list --repo "$REPO_DIR" --type user --json
```

Returns `{"comments":[{noteId, filePath, newRange:[start,end], body, ...}, ...]}`. For each user note, locate the agent draft anchored at the same `file:line` (or nearest) and interpret the note as a directive on that draft:

- **Question** ("can we verify X?", "did you check Y?") → go verify X / Y; do the research; report back what you found; then update or drop the agent draft based on the answer.
- **Correction** ("this is wrong because Z", "actually Z") → drop or rewrite the draft; do not argue.
- **Tone / phrasing direction** ("shorter", "less hedgy", "frame as a question") → rewrite the draft accordingly.
- **Drop signal** ("not worth flagging", "skip this one") → drop the draft from the punch-list before the ask loop.
- **New direction** ("look at <other thing> instead") → investigate the new direction, possibly add a finding, drop the original.

After acting on every note, surface a short recap to the operator: which drafts changed, which were dropped, what you verified. THEN proceed to Step 8b with the updated punch-list.

When the user-notes list is empty, skip this sub-step entirely and proceed straight to Step 8b.

Never post a user-authored Hunk note as a PR comment. The operator's voice in Hunk is for steering the agent, not for the PR author.

### Step 8b. Agent-drafts ask loop

For each finding (BLOCKERs first, then MAJORs, then MINORs), use **AskUserQuestion** with three options:

- `Yes, post it` (the recommended option, listed first)
- `Edit first` (user dictates the rewrite, then re-ask)
- `Skip` (don't post; move on)

**Show the full comment body inline in the question text**, fenced with `---` lines, in addition to the `preview` field. The preview box can be missed; the question text is the primary surface the user reads. Include the confidence + ✓ marker in the header so the operator can use it as a sanity check on whether to trust the finding:

```
question: "Post this on <file>:<line>?\n\n---\n<comment body>\n---"
header:   "BLOCKER 1, 92% ✓3"  /  "MAJOR 2, 78% ✓2"  /  "MAJOR 3, 73% ✓2/3"  /  "MINOR 4, 65% ✓1"
preview:  <same comment body, wrapped at ~60 cols>
```

### Length budget — short by default

Aim for **one to two sentences, ~30 words**. Lead with the bug, end with the fix. Cut anything else.

- Drop "verify in dev"-style suggestions.
- Drop "either X or Y" alternatives unless both are non-obvious; pick the better one and recommend it.
- Drop background sentences that re-state what the code says.
- A reader who's already in the diff doesn't need recap, they need the punch.

If the user replies "much shorter", "trim", "too long", or similar on any draft, cut by ~50% and re-ask. Two iterations is the budget; if you can't get it short enough the finding is probably stapled together from two issues, split it.

On "Yes, post it":

```bash
gh api "repos/$OWNER/$REPO/pulls/$PR_NUM/comments" \
  -X POST \
  -F commit_id="$HEAD_SHA" \
  -F path="$FILE" \
  -F line="$LINE" \
  -F side=RIGHT \
  -F body="$BODY" \
  --jq '.html_url'
```

Print the returned `html_url` so the user can verify. If `gh` returns `commit_id is not part of the pull request`, you used an abbreviated SHA; refetch the full SHA via `gh api repos/$OWNER/$REPO/pulls/$PR_NUM/commits --jq '.[-1].sha'`.

**Append every approved comment to `references/examples.md`** so the corpus grows with the operator's actual voice. After a successful post, edit `~/.claude/skills/pr-code-review/references/examples.md` to add the new entry under the matching category section (Correctness / Data model / Error handling / API surface / Pagination / Tests / Style nits). Format:

```
**<short label>** (`<file>:<line>`)
> <comment body, verbatim>
```

If no category section matches, create one. Keep entries ordered by recency (newest at the top of its section). This is the only way the examples corpus stays a true reference of what the operator actually ships, not what an LLM thought was a good idea.

Edits to `Skip` and `Edit first` outcomes are NOT appended (only posted comments). If the user edits a draft and then approves the edited version, append the FINAL approved body, not the original draft.

On "Edit first": ask the user what to change, rewrite the body, re-run the same AskUserQuestion with the updated preview. Do not auto-post after an edit.

On "Skip": move on, no API call.

### Multi-line anchors

If the finding spans a range, post with `start_line` + `line` + `start_side` + `side`:

```bash
gh api "repos/$OWNER/$REPO/pulls/$PR_NUM/comments" \
  -X POST \
  -F commit_id="$HEAD_SHA" \
  -F path="$FILE" \
  -F start_line="$START" -F start_side=RIGHT \
  -F line="$END"          -F side=RIGHT \
  -F body="$BODY" \
  --jq '.html_url'
```

### PR-level findings (no anchor)

For findings that genuinely have no `+` line anchor (e.g. "no tests added"), post a regular issue comment instead of a review comment:

```bash
gh pr comment "$PR_NUM" --repo "$OWNER/$REPO" --body "$BODY"
```

The ask still happens, just the API endpoint differs.

### Batch-mode: spawn the comment-poster pane

When `target_session=<name>` was passed in and Hunk is open in that session, leave a per-PR Claude instance waiting in the LEFT pane next to the Hunk window so the operator can walk through confirmations later by attaching to the session. Run this immediately after Hunk's fast-path apply returns (end of Step 6b), before exiting the skill. In batch mode the reduce ask (Step 7) is owned by that spawned Claude, not this one.

1. Write a per-PR context file:
   ```bash
   cat > /tmp/pr-<N>-context.md <<EOF
   # PR <pr-url>
   - owner/repo: <OWNER>/<REPO>
   - pr number: <PR_NUM>
   - head sha (full 40): <HEAD_SHA>
   - base ref: <BASE>
   - head ref: <HEAD>
   - comments json: /tmp/pr-<N>-comments.json
   - diff: /tmp/pr-<N>.diff
   - verification log: /tmp/pr-<N>-verification.md
   EOF
   ```
2. Capture the hunk window's index from the prior `tmux new-window -P -F '#{window_index}'` call.
3. Split that window with a left pane running a fresh `claude` instance to walk each comment via AskUserQuestion and post on approval.

That left pane sits idle waiting for the user. When the user runs `tmux attach -t <name>` and walks to that window, the spawned Claude prompts them via AskUserQuestion. Each PR has its own independent comment-poster instance; they don't share state.

## Step 9. Wrap

After every PR's ask loop finishes (or immediately after Step 6b in batch mode, since the reduce-ask and ask-then-post both run in the spawned-pane Claude there), print ONE summary block:

```
posted <K> comments across <M> PR(s):
  PR #<N1>: <K1> posted, <S1> skipped, <F1> filtered as FALSE / low-confidence
  PR #<N2>: <K2> posted, <S2> skipped, <F2> filtered
reports:
  ${REVIEWS_DIR:-$HOME/.reviews}/<repo1>/<date>/<author1>/pr-<N1>-<slug1>.md
  ${REVIEWS_DIR:-$HOME/.reviews}/<repo2>/<date>/<author2>/pr-<N2>-<slug2>.md
audit logs: /tmp/pr-<N1>-verification.md, /tmp/pr-<N2>-verification.md, ...
(browse with `reviews`, fzf picks any report from today; `reviews --all` for any date)
```

Nothing else. No recap of skipped findings, no encouragement.

## Failure modes

- **`gh` refuses `commit_id`**: you abbreviated the SHA. Use the full 40-char SHA from `gh api .../pulls/<N>/commits | jq '.[-1].sha'`.
- **`line` out of diff range**: GitHub rejects inline comments on lines GitHub doesn't show as changed. Either move the anchor to an actual `+` line, or fall back to a PR-level issue comment.
- **Local clone missing**: clone into a checkout root the operator already uses (see Step 0b). Don't review from a worktree if the dev-env files may not be mirrored.
- **PR force-pushed mid-review**: refetch `pr-<N>` (`git fetch origin pull/<N>/head:pr-<N> -f`), re-run Step 1 to get the new HEAD SHA, and warn the user that prior posted comments may now be on stale lines.
- **Verification round drops every finding**: not a failure; print "no surviving findings on PR #<N> after independent verification. Full audit at /tmp/pr-<N>-verification.md" and skip to the next PR. The verification log shows which claims were filtered and why.
- **Subagent over-claims**: if an agent reports confidence ≥ 90% on a behavior claim that the verifier marks FALSE, log it in the verification audit. Repeated over-claims from the same angle indicate the prompt needs tightening, open the SKILL.md to update.

## Composition

- **Pre-flight:** CLAUDE.md / lazy-rule loading at Step 0a. This is mandatory; subagents do not walk the CLAUDE.md tree themselves.
- **Verification:** Step 4 fans out one verifier per finding in parallel. This is mandatory before the operator sees any finding.
- **Downstream:** `hunk` (Step 6b) opens the diff with consolidated review notes attached in a new tmux window per PR, before the reduce ask in Step 7.
- **Sibling skills:**
  - Project-scoped batch drivers (e.g. `pr-code-review-all` under work) discover a set of PRs and call this skill with their URLs. They are the breadth pass; this skill is the depth-on-one-or-a-few pass.
  - `add-comment` (post one specific reply) composes inside this skill's ask-then-post step; you can call out to it for tricky multi-thread replies.
