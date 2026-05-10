---
name: improve-readme-md
description: Spawn 5 parallel critique agents to review a README from distinct angles (first impression, information architecture, install correctness, content gaps, ecosystem comparison), synthesize the findings into a tiered punch-list, and apply the changes the user picks. Triggers on "/improve-readme-md", "improve the readme", "review my readme", "audit the readme", "make the readme better", "have agents look at the readme", or any request for a multi-angle README review. Do NOT trigger for typo passes, single-section tweaks, or when the user just wants a one-line edit — direct edits are faster than a 5-agent fan-out.
argument-hint: "[path-to-readme]" — optional. Defaults to ./README.md at the repo root. Pass a different path for a non-root README (e.g. crates/foo/README.md, docs/README.md).
---

# improve-readme-md

Multi-agent README review: 5 critique angles in parallel, synthesized into a tiered punch-list, then applied with user confirmation.

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

Pick 1–3 exemplar READMEs from the same ecosystem so angle 5 has concrete reference points. Examples (use judgment, not a fixed list):

| Manifest | Ecosystem | Common exemplars |
| --- | --- | --- |
| `Cargo.toml` | Rust CLI/lib | ripgrep, fd, bat, zoxide, eza |
| `package.json` | Node/JS/TS | vite, esbuild, zod, hono |
| `pyproject.toml` / `setup.py` | Python | rich, httpx, ruff |
| `go.mod` | Go | cobra, bubbletea, charm libraries |
| (web framework / SaaS starter) | varies | depend on framework |

If the project type is unclear, ask the user which 1–2 exemplars to compare against before fanning out.

### 3. Spawn all 5 agents in parallel

Send a **single message with five `Agent` tool calls** so they run concurrently. Each agent gets a different angle, and each prompt names the angles the others own so they don't overlap.

**Angle 1 — First impression / hook.** Tagline strength, jargon definition (does the first paragraph define domain terms?), visual hook (asciinema/GIF/screenshot), badge meaningfulness, where the value prop lands.

**Angle 2 — Information architecture / structure.** Section order, heading hierarchy (`#` vs `##` consistency), where deep guides live (inline vs `docs/`), table-of-contents threshold, where Contributing should live.

**Angle 3 — Install correctness + onboarding.** Cross-check every install method against the install script and release workflow. Verify supported platforms match the release matrix. PATH guidance, post-install verification (`<tool> --version`), Windows / PowerShell variants, MSRV / version pinning, libc detection.

**Angle 4 — Content gaps / completeness.** What a reader expects but doesn't find: License section, quickstart sequence, command/API cheat-sheet, supported integrations, screenshots, ecosystem badges, changelog link.

**Angle 5 — Compare to exemplary READMEs in the same ecosystem.** Which conventions from the chosen exemplars (step 2) does this README miss? For each: name the convention, the exemplar that does it well, whether to adopt at this project's scope, and the cost/benefit. Tell the agent it may use `WebFetch` on at most 2–3 exemplars — don't browse the whole ecosystem.

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

## Composition

- **Subagents**: invoked via `Agent` tool with `subagent_type=general-purpose`. They are scoped Agent calls, not separate skills, because each one needs a custom angle prompt.
- **Doc extraction**: if synthesis ends in "extract usage/contributing/troubleshooting to `docs/`", the main agent writes those files inline — no separate skill is involved.
- This skill does not delegate to other skills.

## Guardrails

- Never spawn fewer than 5 agents — the value is in angle separation. If you'd skip one, you're solving the wrong problem (probably a single-section edit, in which case use a direct edit).
- Don't spawn agents until step 1 (read README, manifest, install script) is done. Otherwise subagents waste reads on context the main agent already has.
- Don't apply edits without explicit user confirmation. Step 5 ends with a question, not an edit spree.
- For brand-new READMEs (file barely exists), this skill is overkill — recommend `/init` or a direct draft instead.
