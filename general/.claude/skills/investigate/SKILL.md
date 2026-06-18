---
name: investigate
description: |
  Run a parallel research investigation on any topic — API fields, object schemas,
  vendor rules, protocol behaviors, SDK patterns, error codes, internal company
  systems, etc. Combines public web search with MCP-backed sources (Atlassian,
  Linear, Notion, Slack, GitHub, Hodor-routed providers, etc.) when the question is
  about private or internal content.

  AUTO-INVOKE (without the user needing to say "use the skill") whenever the user says
  any of: "investigate", "look up the docs", "check the docs on", "look for the docs",
  "search online for", "find out if X exists", "confirm X", "is X documented",
  "does X support Y", "what does the API say about", "look online", "research X",
  "find info on", "check if X is a thing", "can we query X", "what fields does X have",
  "look in confluence for", "find the jira ticket about", "is there an RFC for",
  "what do our internal docs say about".

  Do NOT invoke for questions answerable from local files, grep, or knowledge already in
  context. Only invoke when an online or MCP-backed search is the right tool.

argument-hint: "<topic to investigate>"
---

# Investigate Skill

## Overview

Fan out 1, 3, 6, or 12 parallel research agents to answer a question, then synthesize
their findings into a single curated answer with sources. Each agent searches either
the public web or a connected MCP server (Atlassian, Linear, Notion, Slack, GitHub,
Hodor-routed providers, etc.), depending on what the question is actually about.
Save findings to `.investigations/` in the current working directory.

## Step 1 — Calibrate agent count

Before spawning any agents, decide how many to launch based on three signals:

| Signal | 1 agent | 3 agents | 6 agents | 12 agents |
|---|---|---|---|---|
| **Scope** | Single public fact, quote, or well-known doc page | Single field, object, or rule | One API surface (several related fields/endpoints) | Multiple APIs, versions, or vendor layers |
| **Confidence needed** | Sanity check, no real risk | Low-stakes clarification | Implementation decision | Critical correctness (security, data loss, billing) |
| **Contradiction risk** | None expected, one canonical source | Source is likely authoritative and unambiguous | Some community vs. official doc tension possible | Known divergence between versions, SDKs, or regions |

Default to 3. Drop to 1 for trivially simple lookups: a single public fact, a quote from a known
person, a public-figure's blog post or pinned tweet, a well-documented API field with no version
ambiguity. Promote to 6 if the question spans more than one object/endpoint OR if prior attempts
returned conflicting results. Promote to 12 if correctness is critical AND sources are known to be
inconsistent (e.g. deprecated + new API both exist for the same concept).

State the chosen count and the reason in one sentence before spawning.

## Step 2 — Check whether MCP-backed sources are relevant

Before assigning agent roles, decide whether any **connected MCP servers** can answer
the question better than (or in addition to) public web search. Private knowledge bases
behind an MCP often hold the actual answer when the question is about internal systems,
company processes, or vendor-specific configurations.

**Rubric — does any MCP apply?**

| Signal | MCPs probably help | MCPs probably don't help |
|---|---|---|
| **Subject** | Internal company process, private docs, an Epic/employer-specific service, a customer ticket, an engineering RFC, a Slack discussion | Public API, RFC standard, open-source library internals, vendor SDK behaviour |
| **CWD / context** | Inside a work repo, a corporate environment, a path the user routinely uses for $employer work | Outside work paths (personal projects, dotfiles, open-source clones) |
| **Vocabulary in the question** | Names an internal team, service, channel, ticket prefix, or product nickname only employees would recognize | Names a public vendor, open-source project, or generic protocol |
| **Auto-invoke triggers fired** | "how does our X work", "what does engineering say about Y", "is there a ticket for Z", "find the RFC for…", "internal docs on…" | "what does the API say about", "is X documented" (generic, public-facing) |

**Discovery — what's actually available right now:**

- Skim the current tool index for MCP-provided tools: any `mcp__*` namespace, any
  vendor-tagged provider tools (Atlassian, Linear, Notion, GitHub, Slack, Snowflake,
  Grafana, etc.).
- If a Hodor-style meta-tool index is present (`hodor_search_tools`,
  `hodor_list_providers`), call one of them once with a capability-shaped query (e.g.
  `"search confluence for X"`, `"find linear issues about Y"`) to see whether a
  matching provider is connected.
- For any candidate MCP, name the specific tool(s) you'd call: e.g. Atlassian
  `searchConfluenceUsingCql` / `searchJiraIssuesUsingJql` / `search` (Rovo);
  Linear `search_issues`; Notion `search`; GitHub `search_code` /
  `search_issues`; Slack `search_messages`.

**Decide — one of three outcomes:**

1. **Web only** — the question is public-facing and MCPs add nothing. Proceed to Step 3
   with the original web-only role assignments.
2. **MCP only** — the question is entirely about private/internal content and a public
   web search would be noise. Replace all web agent roles with MCP-backed roles.
3. **Mixed** — both apply. Reserve a fraction of agent slots for MCP-backed searches
   (typically 1 of 3, 2 of 6, or 3–4 of 12) and keep the rest on web.

State the decision and which MCP tools you'll route through in one sentence before
moving on. Worked example: `Decision: mixed (5 web, 1 MCP). Routing the MCP agent
through Atlassian search (Rovo + CQL) because the question names "fn-build-updater"
which is an internal Epic system documented in Confluence.`

## Step 2b — Decide whether to add a code-search wave

A code-search wave is a SEPARATE batch of 3, 6, or 12 agents that runs IN ADDITION
to the main investigation agents from Step 1. It does only one thing: hunt public
GitHub + GitLab for existing code that implements (or attempts) the thing being
investigated. The main wave answers "what do the docs/spec/community say"; the
code-search wave answers "what does the wire look like when someone actually
wrote it."

**Rubric — does the question warrant a code-search wave?**

| Signal | Add a code-search wave | Skip it |
|---|---|---|
| **Subject** | API endpoint shapes, request/response field layouts, header semantics, error envelopes, pagination, auth flows, SDK call patterns, protocol wire formats, schemas, undocumented vendor quirks | Pure policy/process questions, internal company tickets, non-code documentation, vendor pricing, marketing claims, RFC text alone |
| **Why it helps** | A real implementation is often the only source of truth when docs are silent or contradict each other | If no one would ever write code about this, a code-search wave is noise |
| **Auto-include triggers** | "what does the API actually return", "is X documented anywhere", "how does Y behave in practice", "find an example implementation", any question whose answer would normally be confirmed by reading source code |  |

If the question has a code dimension at all, default to ADDING a code-search wave.
The cost of an unnecessary code-search wave is bounded (a few minutes of
parallel agents); the cost of missing real wire evidence on a code question is
much larger. Only skip when the question is unambiguously non-code.

**Hard precondition: `mcp__grep__searchGitHub` must be available.** Before
launching any code-search agents, confirm the tool is in the current tool
index. If it is not present, STOP, do not fall back to plain WebSearch, and
tell the user something like:

```
The code-search wave requires the GitHub grep MCP (`mcp__grep__searchGitHub`).
Install it from https://github.com/grep-app/grep-mcp (or the equivalent
provider in your Claude Code settings) and re-run the investigation.
```

The main investigation wave may still run without the code-search wave, but
ask the user whether they want to proceed without code evidence or fix the
MCP first. Do not silently skip the code-search wave when Step 2b said it
was needed.

**Size the code-search wave independently** from the main investigation wave,
using the same 3 / 6 / 12 rubric from Step 1. The two waves are sized on their
own merits; a question can warrant 3 main agents + 6 code-search agents, or
6 + 3, or 12 + 12, etc.

State the code-search wave count and its rationale in one sentence before
spawning. Worked example: `Decision: 6 main agents (web+MCP from Step 2) +
6 code-search agents, because the question asks how a specific SCIM PATCH
path expression behaves against an undocumented host, so real outbound
client code on GitHub + GitLab is load-bearing evidence.`

## Step 3 — Assign agent roles

Each agent gets a distinct search angle so they don't duplicate each other.

**For 1 agent (trivially simple lookup):**
- Single agent on whichever lane fits best (web or one MCP). No role specialization. The agent runs one focused search and returns the verbatim answer with sources. Skip cross-checking; if the canonical source is silent or ambiguous, escalate to 3 agents.

**For 3 agents (web-only baseline):**
- Agent A: Official vendor developer docs (reference pages, API docs)
- Agent B: Official vendor SDK / code samples / official GitHub repos
- Agent C: Community + changelog (forums, release notes, third-party guides)

**For 6 agents** (A–C above plus):
- Agent D: Alternative official docs entry point (e.g. product help vs. developer docs)
- Agent E: Search via a different query phrasing / synonym for the same concept
- Agent F: Cross-check — explicitly look for contradictions or deprecation notices

**For 12 agents** (A–F above plus):
- Agent G–L: Per-version, per-region, per-SDK-language, per-API-generation coverage;
  assign each a distinct slice of the search surface stated in the question.

**MCP-backed agent roles** (swap in when Step 2 says "MCP only" or "mixed"):

- Agent M (Atlassian): Confluence + Jira search via Rovo `search` first, then
  `searchConfluenceUsingCql` and `searchJiraIssuesUsingJql` for follow-ups. Pull and
  read pages with `getConfluencePage` / `getJiraIssue`. Cite Confluence URLs and Jira
  keys.
- Agent N (Linear / Notion / Slack / similar): use the matching MCP's search tool with
  one capability-shaped query, then fetch top results in full. Cite stable URLs.
- Agent O (Hodor-routed): use `hodor_search_tools` → `hodor_describe_tool` →
  `hodor_execute_tool` to access any provider not otherwise wired up directly.

When using mixed mode, instruct MCP-backed agents that web search is out of scope and
vice versa — keep the lanes clean.

### Code-search wave roles (additional, only if Step 2b said yes)

These agents are a separate batch from A–O above. Their lane is strictly public
source code: GitHub via the `mcp__grep__searchGitHub` MCP tool (literal grep over
all public GitHub code) and GitLab via WebSearch (`site:gitlab.com`,
`site:gitlab.io`) plus the GitLab project search API. They do NOT read vendor
docs, MCP-private content, or community blogs. Every claim cites a specific
repo file URL with line numbers.

**For 3 code-search agents (baseline):**
- Agent CS-1 (GitHub vendor-specific): hunt repos that name the exact vendor /
  API / endpoint in question. Best when there's a chance someone has already
  implemented this exact integration. Use `mcp__grep__searchGitHub` with
  vendor-named queries (URLs, env-var names, header strings).
- Agent CS-2 (GitHub pattern / spec-shape): hunt for the protocol or shape
  even when no one has implemented this exact vendor. Use queries shaped like
  the wire format (e.g. `application/scim+json`, `members[value eq`,
  `urn:ietf:params:scim:api:messages:2.0:Error`). Prefer language filters that
  match the target codebase.
- Agent CS-3 (GitLab + mirrored repos): WebSearch with `site:gitlab.com` and
  `site:gitlab.io` plus targeted GitLab project search. Many enterprise
  integrations live on GitLab and never appear in GitHub. Also catch repos
  mirrored from GitLab to GitHub.

**For 6 code-search agents** (CS-1 through CS-3 above plus):
- Agent CS-4 (GitHub language slice): repeat CS-2 with a second language filter
  (e.g. CS-2 ran Go + TypeScript; CS-4 covers Python + Java + Ruby + C#).
- Agent CS-5 (GitHub tests/fixtures): hunt `testdata/`, `fixtures/`,
  `__snapshots__`, `cassettes/`, `*_test.{ts,go,py,rb,java}`. Recorded wire
  samples are gold for "what does the response actually look like" questions.
- Agent CS-6 (GitHub deprecations / failed attempts / forks): repos with
  `archived`, `deprecated`, README warnings, and forks with active branches.
  Counter-evidence often lives in forks.

**For 12 code-search agents** (CS-1 through CS-6 above plus):
- CS-7 (GitHub: same-vendor SDKs in N other languages, one agent per language slice).
- CS-8 (GitHub: vendor's own org for first-party samples, examples, fixtures).
- CS-9 (GitHub: known IdP / orchestrator repos that integrate with the vendor, e.g. Terraform providers, Pulumi, ConductorOne baton-*, Stitchflow).
- CS-10 (GitLab: enterprise org search via `gitlab.com/explore` keywords).
- CS-11 (GitHub: gists + small one-shot scripts. Often capture wire traces
  that big repos abstract away.).
- CS-12 (GitHub cross-check / contradictions): explicitly hunt for repos that
  do the OPPOSITE of the dominant pattern surfaced by CS-1..CS-11, so the
  synthesis step sees both sides.

When using a code-search wave alongside the main wave, instruct the code-search
agents that vendor docs, MCP servers, and community blog posts are OUT of scope
for them, and instruct the main-wave agents that public source-code grep is the
code-search wave's job. Keep the lanes clean so findings don't duplicate.

## Step 4 — Launch agents

Spawn all agents in a single message with `run_in_background: true`. If you
decided in Step 2b to add a code-search wave, spawn BOTH waves in the same
message (main wave plus code-search wave together) so they run fully in
parallel. Don't serialize them.

Each agent prompt must include:
1. The exact question to answer.
2. Its assigned search angle (from Step 3) — including which specific MCP tool(s) to
   call, if any, and an explicit "do NOT use web search" / "do NOT use MCP tools" /
   "do NOT search public source code" instruction matching its lane. Code-search
   agents get the inverse: "do NOT read vendor docs, MCP content, or community
   blogs; cite only specific GitHub / GitLab file URLs with line ranges."
3. This output contract:

```
Return:
- ANSWER: one-paragraph direct answer (or "not found" if nothing useful was found)
- CONFIDENCE: Definitive | Likely | Unconfirmed | Contradicted, PLUS a numeric percentage 0–100
  (e.g. "Likely (~80%)"). If the answer has multiple sub-claims, give per-claim numbers too.
- SOURCES: bulleted list of URLs with a one-line description of what each confirms
- CONTRADICTIONS: any conflicting claims found (empty if none)
```

The numeric percentage is mandatory. Map the label to an honest number — don't just pick the
midpoint of the band. If the strongest source is an official spec corroborated by working code,
that's ~95%. If it's one community blog post and nothing else, that's ~40%. Surface uncertainty
in the number; the synthesizer aggregates these across agents.

## Step 5 — Synthesize

After all agents return (main wave AND, if launched, the code-search wave),
produce a single user-facing report. Treat code-search findings as another
class of evidence: weave them into the Answer/Sources sections, do not
section them off into a separate "code search" silo. When a code-search
finding contradicts a docs-based finding, surface the contradiction
explicitly. Real wire evidence in working code usually wins over silent
or ambiguous docs, but call out which is which.

**The very first line of the report MUST be a verdict line — bold, unambiguous, one sentence.**
This is the most important part. The user should not have to read past the first line to know
whether the thing they asked about exists or not.

Verdict line formats (pick one):
- `**Found:** <one-sentence summary of what was found>`
- `**Not found:** <one-sentence explanation of why — e.g. "Sage does not have per-object permission identifiers; all user objects share a single 'Users' permission.">`
- `**Conflicting evidence:** <one sentence naming the conflict>`

After the verdict line, add the rest of the report:

1. **Answer** — the actual finding. Keep it short:
   - Simple factual answer (a field name, a boolean, a URL): one line.
   - Moderately complex (several related facts): a short bulleted list, no more than 5 bullets.
   - Complex (multiple layers, caveats, version differences): a short prose paragraph plus
     a caveats sub-section. Still aim for under 150 words total.

   **Every claim (or sub-claim if the answer is multi-part) gets a numeric confidence in parentheses immediately after it**, e.g. "POST body is a JSON array (~98%)" or "last-Owner deletion returns 400 (~50%)". The headline confidence (top-of-report) is the lowest per-claim number — never average. If the user can only act on one sentence, they need to see the weakest link.

2. **Sources** — bulleted list; every claim must trace to at least one URL. No source = omit
   the claim.
3. **Caveats** (only if present) — things that might invalidate the answer in specific
   contexts (version, region, plan tier, etc.).

**Confidence label + percentage rules:**

| Label | Numeric band | When to use |
|---|---|---|
| **Definitive** | 90–100% | Multiple independent sources agree AND at least one is official docs / official SDK / canonical implementation, with no counter-evidence. |
| **Likely** | 65–90% | One authoritative source + corroborating community evidence; no hard contradictions; or a canonical implementation but no live test. |
| **Unconfirmed** | 30–65% | Community-only source, OR one source with no corroboration, OR contradictory third-party guides. |
| **Contradicted** | 0–30% | Sources disagree. Surface BOTH claims with their sources; do NOT pick a winner — tell the user to verify. |

Pick the number honestly inside the band. Don't anchor to the midpoint just because the band is wide. "I read it on one blog" is 35%, not 50%. "Official spec + working SDK code + a fixture" is 95%, not 80%. The number is supposed to be lossy compression of "what would I bet that this is right" — if you wouldn't bet your salary at 95%, write 80%.

Never suppress a contradiction to make the answer look cleaner. Never round up to make the report look more decisive.

## Step 6 — Save findings

After producing the report, save it to `.investigations/` in the current working directory.

File naming: `.investigations/<YYYY-MM-DD>-<slug>.md` where slug is a short kebab-case
summary of the question (e.g. `2026-05-27-sage-intacct-logindisabled-ws-users.md`).

File format:

```markdown
# <question>

_Investigated: <date> | Headline confidence: <label> (~NN%) | Agents: <count>_

## Answer

<the answer section verbatim, with per-claim percentages>

## Sources

<sources list verbatim>

## Caveats

<caveats if any>
```

Create `.investigations/` if it doesn't exist. Never commit this folder — it is covered by
the global gitignore (`.investigations/`).

## Step 7 — Validate live (optional)

After saving, check whether the findings are *testable* against reality cheaply. If yes,
run the test now and append the results to the saved file under a `## Live validation
(<date>)` section. Bump each finding's confidence percentage based on what the live test
showed (confirmed → 95–100%; refuted → flip the claim and note the refutation; partial →
narrow the % toward the band that matches the new evidence).

Skip this step entirely when the question was inherently non-testable: a definition,
a policy decision, a historical fact, a "should we do X" question, anything where there
is no command, endpoint, or filesystem state that would change the answer.

### Decide whether to validate

Run live validation when ALL of these hold:
- The findings describe a concrete behavior that can be exercised (an API endpoint, a
  CLI command, a library call, a file/path claim, a config flag).
- Running the test is cheap and reversible (no destructive operation, no shared-state
  side effect that can't be cleaned up).
- The cost of being wrong is non-trivial: the user is going to act on the findings
  (write code, ship config, brief a customer).

Skip when ANY of these hold:
- The test would require a sacrificial resource we can't recreate (e.g. deleting the
  last Owner of a real tenant).
- The test would touch a shared / production system without isolation.
- The user is just doing background reading and hasn't asked for a decision.
- The findings are already at 95%+ from independent sources AND the marginal cost of
  doubt is small.

If you're unsure, ask the user with one short question rather than skipping silently.

### How to run the test

Pick the smallest test that disambiguates the lowest-confidence finding(s) first. Don't
test the 95% claims to "be thorough" — test the 50% claim that will actually change
behavior.

Common test shapes:

- **HTTP / REST API findings.** Reach for `curl` (or the closest dedicated MCP if one
  is connected). For each finding:
  - Pick a read-only probe first (auth sanity, list endpoint shape). If reads fail, no
    point in attempting writes.
  - For writes (POST/PATCH/DELETE), always create a clearly-throwaway resource (e.g.
    `cxh1490-probe-<timestamp>@example.com` for a member create), then clean it up in
    the same script.
  - Capture the real status code AND a head of the response body — both shape the
    plan's error-handling.
  - **Credentials.** If credentials are needed and not already in env / `.envrc`,
    invoke the `get-api-credentials` skill — it knows the Playwright + 1Password flow
    for retrieving API tokens for a given vendor. Use `Skill` with
    `skill: get-api-credentials, args: <vendor-or-connector-name>`, or in tmux spawn
    a sibling pane via the `tmux` skill running
    `claude '/get-api-credentials <name>'`. Do NOT ask the user for credentials as
    the first move when get-api-credentials could fetch them.
  - **Token scope.** If a probe returns 403 with `{access:{action:..., resource:...}}`,
    that error body *itself* is a finding — it names the exact permission required.
    Record it. The probe failed at validating the success path but succeeded at
    pinning the permission name.

- **CLI / shell findings.** Run the command in a temp directory or with `--dry-run`
  / equivalent if it exists. Capture stdout/stderr verbatim.

- **Library / SDK findings.** Write a 5–10 line script (`/tmp/probe.<ext>`) that calls
  the documented API and prints the result. Run it. Don't add it to the repo.

- **File / path findings.** `stat`, `ls`, `cat` are enough. If the finding is "config
  X lives at path Y", confirm Y exists and has the expected shape.

### What to record

Append a section to the saved investigation file, NOT in the chat-only response, so the
record survives:

```markdown
## Live validation (<date>)

Ran against <tenant / system identifier>. Token / scope / environment:
<one line of context — e.g. "Reader-scoped LD token, free-tier tenant">.

**Confirmed:**
- <claim>: <one-line summary of probe + result> → confidence now ~NN% (was ~MM%).

**Refuted / corrected:**
- <claim>: <real behavior>; updating finding to <new claim> (~NN%).

**Could not test:**
| Probe | Reason |
|---|---|
| <name> | <why — token scope, tenant plan, would touch shared state, etc.> |

**Implications:**
- <one-line summary of which downstream actions / plans need to change>.
```

The "Could not test" table is just as important as "Confirmed" — it tells the next
reader what's still soft.

### Re-state the verdict if anything moved

If the live run flipped a high-confidence finding, update the headline verdict at the
top of the saved file in place (don't just append a contradiction). The file should
read top-to-bottom as the current best answer; the live-validation section is the
audit trail.

## Step 8 — Report to user

End the response with one of:
- `Investigation: successful` — at least one Definitive or Likely finding (and, if Step
  7 ran, live validation confirmed it).
- `Investigation: partial` — some useful findings but gaps remain; list what's still
  unknown (and, if Step 7 ran, list what could not be tested).
- `Investigation: unsuccessful` — nothing useful found; list what was searched.

Then add: `Saved to .investigations/<filename>.md`
