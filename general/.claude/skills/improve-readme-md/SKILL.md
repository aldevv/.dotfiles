---
name: improve-readme-md
description: Spawn 5 parallel critique agents to review a README from distinct angles (first impression, information architecture, install correctness, content gaps, ecosystem comparison), synthesize the findings into a tiered punch-list, and apply the changes the user picks. Triggers on "/improve-readme-md", "improve the readme", "review my readme", "audit the readme", "make the readme better", "have agents look at the readme", or any request for a multi-angle README review. Do NOT trigger for typo passes, single-section tweaks, or when the user just wants a one-line edit — direct edits are faster than a 5-agent fan-out.
argument-hint: "[path-to-readme]" — optional. Defaults to ./README.md at the repo root. Pass a different path for a non-root README (e.g. crates/foo/README.md, docs/README.md).
---

# improve-readme-md

Multi-agent README review: 5 critique angles in parallel, synthesized into a tiered punch-list, then applied with user confirmation.

## Files

- [`SKILL.md`](SKILL.md) — this file. Workflow, agent angles, concrete techniques.
- [`references/exemplar-readmes.md`](references/exemplar-readmes.md) — 12 distilled exemplar READMEs across ecosystems. Backs angle-5 (ecosystem comparison). Carries a refresh policy with `Last fetched` dates and dead-repo substitution candidates.
- [`references/avoid.md`](references/avoid.md) — Bad → Better antipatterns. Read during step 6 when applying changes — the **Better** form usually points at the specific replacement shape.
- [`references/github-markdown.md`](references/github-markdown.md) — Positive reference for GitHub-flavored markdown features (alerts, video embedding via `user-attachments`, GIF / YouTube fallbacks). Read when those come up in step 6.

## Table of contents

- [When to use](#when-to-use)
- [When NOT to use](#when-not-to-use)
- [Steps](#steps)
  - [1. Locate the README and gather context](#1-locate-the-readme-and-gather-context)
  - [2. Detect the ecosystem and pick exemplars for angle 5](#2-detect-the-ecosystem-and-pick-exemplars-for-angle-5)
  - [3. Spawn all 5 agents in parallel](#3-spawn-all-5-agents-in-parallel)
  - [4. Per-agent boundaries](#4-per-agent-boundaries)
  - [5. Synthesize into a tiered punch-list](#5-synthesize-into-a-tiered-punch-list)
  - [6. Apply selected changes](#6-apply-selected-changes)
- [Composition](#composition)
- [Guardrails](#guardrails)

## When to use

- User says "improve the readme", "review my readme", "audit the readme", "make the readme better", or invokes `/improve-readme-md`.
- The user wants a *thorough* multi-perspective critique, not a typo pass.

## When NOT to use

- Typo, grammar, or single-section tweaks → direct edit is faster.
- "Add an X section" with X already specified → direct edit.
- Private/work repos where subagents would need creds to fetch reference material → fall back to a single-angle review the main agent does inline.

## Steps

### 1. Locate the README and gather context

- Default to `README.md` at the repo root. Use the user's argument if given.
- Read the README in full **first** (don't delegate this — subagents shouldn't repeat it).
- Read alongside it, only what's needed for context:
  - The project's package manifest (`Cargo.toml`, `package.json`, `pyproject.toml`, `go.mod`, `mix.exs`, `Gemfile`, etc.) — to detect the ecosystem.
  - Any existing `docs/`, `CONTRIBUTING.md`, or root `CLAUDE.md` — so the agents don't propose duplicating what's already there.
  - Any install script (`install.sh`, `Makefile` install target) and CI/release workflow (`.github/workflows/release.yml` etc.) — angle 3 cross-checks against these.

### 2. Detect the ecosystem and pick exemplars for angle 5

Read `references/exemplar-readmes.md` (sibling of this SKILL.md). It carries 12 distilled exemplars — Rust CLI, Go CLI, TS lib, framework — with per-entry tagline shape, section order, install style, standout patterns, and "When to cite this exemplar" lines. Use the **Quick-pick table** at the top to choose 1–3 in-ecosystem exemplars for the target README.

**Before citing an exemplar, check freshness and liveness** (per the file's "Refresh policy"):

- If the entry's `Last fetched` is more than 12 months ago, re-fetch the README via `WebFetch`, update the distillation, and bump the `Last fetched` date in the same commit.
- Quick liveness check: `curl -s https://api.github.com/repos/<owner>/<repo>` → if `archived: true`, status is 404, or `pushed_at` is more than 12 months stale, treat the repo as **dead**. Substitute an actively-maintained in-ecosystem exemplar (the Refresh policy section lists candidates per ecosystem), drop the dead row from the file's quick-pick table and per-repo section, and update the cross-cutting patterns section if it cited the dead exemplar. Note the substitution in a one-line comment under the new entry's `Last fetched` line.
- Both staleness fixes happen as part of *this* skill run — don't postpone. The exemplar must be current at the moment angle-5 cites it.

If the project type doesn't match any ecosystem in the file (e.g. Elixir/Phoenix, Haskell, Zig), ask the user which 1–2 exemplars to compare against before fanning out, and consider adding the new ecosystem to `references/exemplar-readmes.md` for future runs.

### 3. Spawn all 5 agents in parallel

Send a **single message with five `Agent` tool calls** so they run concurrently. Each agent gets a different angle, and each prompt names the angles the others own so they don't overlap.

**Angle 1 — First impression / hook.** Tagline strength, jargon definition (does the first paragraph define domain terms?), visual hook (asciinema/GIF/screenshot/video), badge meaningfulness, where the value prop lands. **If a video is embedded**, check it uses the working pattern — bare `https://github.com/user-attachments/assets/<uuid>` URL on its own line, OR a GIF under `docs/`. A `<video src="...raw.githubusercontent.com/.../demo.mp4">` tag renders as nothing on github.com (the sanitizer strips it) — flag this as a real bug, not a style nit.

**Angle 2 — Information architecture + section internals.** Section order, heading hierarchy (`#` vs `##` consistency), where deep guides live (inline vs `docs/`), table-of-contents threshold, where Contributing should live. **Also scrutinizes *internal* section structure** — not just the H2 sequence: flat paragraph blocks that jam ≥3 unrelated topics together (each topic invisible to Cmd-F), H3s whose entire body is one paragraph that doesn't justify a heading, key/flag enumerations written as comma-strings when a table would be scannable, implementation-detail H3s (e.g. exhaustive lists of binary names or flag values) that should compress to a sentence and let `--help` / config comments carry the detail. The smell test: "could a reader find each topic by skimming, or are three topics hiding inside one prose block?"

**Angle 3 — Install correctness + onboarding.** Cross-check every install method against the install script and release workflow. Verify supported platforms match the release matrix. PATH guidance, post-install verification (`<tool> --version`), Windows / PowerShell variants, MSRV / version pinning, libc detection.

**Angle 4 — Content gaps / completeness.** What a reader expects but doesn't find: License section, quickstart sequence, command/API cheat-sheet, supported integrations, screenshots, ecosystem badges, changelog link.

**Angle 5 — Compare to exemplary READMEs in the same ecosystem.** Which conventions from the chosen exemplars (step 2) does this README miss? For each: name the convention, the exemplar that does it well, whether to adopt at this project's scope, and the cost/benefit. Pass the agent the relevant entries from `references/exemplar-readmes.md` (already distilled — saves a round-trip). It may also use `WebFetch` on at most 2–3 exemplars when the distillation is stale or doesn't cover what's being asked — don't browse the whole ecosystem.

### 4. Per-agent boundaries

Every prompt must include:

- **Lens owned**: one of the five.
- **Lenses NOT owned**: list the other four explicitly. Tell the agent to defer those to other reviewers.
- **Citations**: every concrete claim references `README.md:N` (or other file:line).
- **Length**: under 250 words (300 for angle 5).
- **Form**: bullets, with replacement text where they'd reword something.
- **Model**: `sonnet` — analysis, not heavy reasoning. Keeps cost reasonable.

### 5. Synthesize into a tiered punch-list

After all 5 return, sort findings into tiers:

- **Strong signals** — flagged by ≥2 agents. Almost always merit action.
- **Standalone strong signals** — high-impact items only one agent surfaced, with concrete cost/benefit.
- **Real bugs** — anything in angle 3 that's a fact-check failure (install method points to a target the release matrix doesn't ship, etc.). Treat as bugs, not opinions.
- **Low priority / skip** — cargo-cult suggestions that don't fit the project scope (no "How it works" diagram for a 200-line CLI).

**Delete-vs-fix.** A fact-check failure doesn't always mean "correct the line." Sometimes the right move is to delete the section. A precise platform/arch table that mirrors the release matrix is technically correct *and* may be noise the README doesn't need. Before adding detail to fix a bug, ask whether the section should exist at all — small-project READMEs almost always favor deletion.

Present the synthesis with the four tiers, then use `AskUserQuestion` with 3–4 scope options (e.g. "strong signals + bugs (recommended)", "everything except skip tier", "bugs only", "strong only"). Do **not** edit before this step.

### 6. Apply selected changes

- For heavy additions (full usage guide, contributing guide, troubleshooting) — extract to `docs/<topic>.md` and link from the README. Keep the README a hook, not a manual.
- After editing, re-read the README front-to-back to catch newly-introduced inconsistencies (broken links, mismatched headings, stale claims).
- If install instructions changed, also patch `install.sh` and any related script — angle 3 findings often imply paired script edits.

**Concrete techniques that tend to work:**

- **Tighten the tagline by leading with a verb** ("turns coding katas into a daily habit:", not "A small CLI for daily coding-kata practice that…"). Pull domain-jargon definitions out of the tagline into a `> blockquote` pull-out underneath, so the tagline keeps its punch.
- **Collapse N overlapping sections into one.** `Features` + `Templates` + `Subcommands` is almost always one `Commands` section with a table; the bullet list of features tends to repeat the tagline and quickstart. Resist the urge to add a new heading whenever a new fact appears.
- **Drop CI workflow badges.** Tests/Releases workflow status badges are signal for maintainers, not for visitors evaluating whether to install. Keep the version badge (crates.io / npm / pypi), the license badge, and at most one downloads/popularity signal.
- **Quickstart before Install.** Hook before commitment. The reader needs to see the inner loop before being asked to run a curl-pipe.
- **Break flat paragraph blocks that pack ≥3 unrelated topics.** Either promote each to its own H3 when each is independently load-bearing, or hoist the most distinctive one out and drop the rest under `### Notes`. Smell test: a reader Cmd-F-ing for one of those topics wouldn't find it because the heading doesn't name it.
- **Turn key/flag enumerations into a table when an alt-mapping is involved.** A two-column `Default / Alt` table makes the mapping obvious in one glance; comma-strings only work when there's no alternate to align against. **Corollary**: include unchanged-on-alt rows in the *same* table — repeat the default in the alt column. Don't split half the reference into a prose afterthought; that fragments the lookup.
- **An H3 whose body is a list of implementation-detail binaries or flags is too heavy.** Compress to a sentence and let `--help` or source carry the enumeration. Exhaustive lists belong in code, not the README.
- **Don't pre-document runtime UX the reader only encounters in context.** Lines like "the installer warns if X" or "the CLI prints a banner on first run" describe behavior the user meets at runtime — at which point the runtime UX is its own teacher. Either give the reader an actionable instruction *now* ("Add `~/.local/bin` to your `PATH`") or drop the line. Documenting what stdout will print is filler.
- **Embedding a video.** GitHub strips `<video>` tags whose `src` isn't from `github.com/user-attachments` or `user-images.githubusercontent.com`, and a bare `raw.githubusercontent.com/.../demo.mp4` URL renders as a plain link, not a player. Use a `user-attachments` URL (renders inline on github.com only), a GIF under `docs/` (renders everywhere a README ends up), or a YouTube thumbnail (long walk-throughs). The `user-attachments` workflow requires a manual drag-drop the skill can't perform — surface the steps to the user and wait for the URL. See `references/github-markdown.md` for the full workflow and `references/avoid.md` for the stripped-`<video>` antipattern.
- **Use GitHub-flavored alerts for callouts.** Replace `**Note:**`, plain `> Note:`, or emoji-prefixed callouts with the native alert syntax (`> [!NOTE]`, `> [!TIP]`, `> [!IMPORTANT]`, `> [!WARNING]`, `> [!CAUTION]`) — github.com renders styled icon-bearing boxes; off-GitHub renderers fall back to plain blockquotes. Pick semantics deliberately: `[!IMPORTANT]` for must-notice info (security caveats, required env vars), `[!NOTE]` for neutral facts (supported platforms), `[!CAUTION]` only when the user could actually lose data. See `references/github-markdown.md` for the syntax and the full type-to-use-case table.

Worked **Bad → Better** antipatterns for each of the patterns above live in `references/avoid.md` — read them when applying changes, the **Better** form usually points at the specific replacement shape. Positive reference for GitHub-flavored markdown features (alerts, video embeds, future additions) lives in `references/github-markdown.md`.

## Composition

- **Subagents**: invoked via `Agent` tool with `subagent_type=general-purpose`. They are scoped Agent calls, not separate skills, because each one needs a custom angle prompt.
- **Doc extraction**: if synthesis ends in "extract usage/contributing/troubleshooting to `docs/`", the main agent writes those files inline — no separate skill is involved.
- This skill does not delegate to other skills.

## Guardrails

- Never spawn fewer than 5 agents — the value is in angle separation. If you'd skip one, you're solving the wrong problem (probably a single-section edit, in which case use a direct edit).
- Don't spawn agents until step 1 (read README, manifest, install script) is done. Otherwise subagents waste reads on context the main agent already has.
- Don't apply edits without explicit user confirmation. Step 5 ends with a question, not an edit spree.
- For brand-new READMEs (file barely exists), this skill is overkill — recommend `/init` or a direct draft instead.
