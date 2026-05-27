---
name: investigate
description: |
  Run a parallel web research investigation on any topic — API fields, object schemas,
  vendor rules, protocol behaviors, SDK patterns, error codes, etc.

  AUTO-INVOKE (without the user needing to say "use the skill") whenever the user says
  any of: "investigate", "look up the docs", "check the docs on", "look for the docs",
  "search online for", "find out if X exists", "confirm X", "is X documented",
  "does X support Y", "what does the API say about", "look online", "research X",
  "find info on", "check if X is a thing", "can we query X", "what fields does X have".

  Do NOT invoke for questions answerable from local files, grep, or knowledge already in
  context. Only invoke when an online search is the right tool.

argument-hint: "<topic to investigate>"
---

# Investigate Skill

## Overview

Fan out 3, 6, or 12 parallel web-search agents to answer a research question, then
synthesize their findings into a single curated answer with sources. Save findings to
`.investigations/` in the current working directory.

## Step 1 — Calibrate agent count

Before spawning any agents, decide how many to launch based on three signals:

| Signal | 3 agents | 6 agents | 12 agents |
|---|---|---|---|
| **Scope** | Single field, object, or rule | One API surface (several related fields/endpoints) | Multiple APIs, versions, or vendor layers |
| **Confidence needed** | Low-stakes clarification | Implementation decision | Critical correctness (security, data loss, billing) |
| **Contradiction risk** | Source is likely authoritative and unambiguous | Some community vs. official doc tension possible | Known divergence between versions, SDKs, or regions |

Default to 3. Promote to 6 if the question spans more than one object/endpoint OR if prior
attempts returned conflicting results. Promote to 12 if correctness is critical AND sources
are known to be inconsistent (e.g. deprecated + new API both exist for the same concept).

State the chosen count and the reason in one sentence before spawning.

## Step 2 — Assign agent roles

Each agent gets a distinct search angle so they don't duplicate each other.

**For 3 agents:**
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

## Step 3 — Launch agents

Spawn all agents in a single message with `run_in_background: true`.

Each agent prompt must include:
1. The exact question to answer.
2. Its assigned search angle (from Step 2).
3. This output contract:

```
Return:
- ANSWER: one-paragraph direct answer (or "not found" if nothing useful was found)
- CONFIDENCE: Definitive | Likely | Unconfirmed | Contradicted
- SOURCES: bulleted list of URLs with a one-line description of what each confirms
- CONTRADICTIONS: any conflicting claims found (empty if none)
```

## Step 4 — Synthesize

After all agents return, produce a single user-facing report.

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
2. **Sources** — bulleted list; every claim must trace to at least one URL. No source = omit
   the claim.
3. **Caveats** (only if present) — things that might invalidate the answer in specific
   contexts (version, region, plan tier, etc.).

**Confidence label rules:**
- **Definitive**: multiple independent sources agree and at least one is official docs or
  an official SDK. Use this label in the report.
- **Likely**: one authoritative source + corroborating community evidence, no contradictions.
- **Unconfirmed**: found in community only, or single source with no corroboration.
- **Contradicted**: sources disagree. Surface both claims and their sources; do NOT pick a
  winner — tell the user to verify.

Never suppress a contradiction to make the answer look cleaner.

## Step 5 — Save findings

After producing the report, save it to `.investigations/` in the current working directory.

File naming: `.investigations/<YYYY-MM-DD>-<slug>.md` where slug is a short kebab-case
summary of the question (e.g. `2026-05-27-sage-intacct-logindisabled-ws-users.md`).

File format:

```markdown
# <question>

_Investigated: <date> | Confidence: <label> | Agents: <count>_

## Answer

<the answer section verbatim>

## Sources

<sources list verbatim>

## Caveats

<caveats if any>
```

Create `.investigations/` if it doesn't exist. Never commit this folder — it is covered by
the global gitignore (`.investigations/`).

## Step 6 — Report to user

End the response with one of:
- `Investigation: successful` — at least one Definitive or Likely finding.
- `Investigation: partial` — some useful findings but gaps remain; list what's still unknown.
- `Investigation: unsuccessful` — nothing useful found; list what was searched.

Then add: `Saved to .investigations/<filename>.md`
