---
name: skill-md-improver
description: Spawn 5 parallel critique agents to review a SKILL.md from distinct angles (triggering accuracy, workflow executability, organization, composition/delegation, guardrails & portability), synthesize the findings into a tiered punch-list, and apply the changes the user picks. Triggers on "/skill-md-improver", "improve this skill", "review my skill", "audit my skill", "audit skill", "audit this SKILL.md", "make this skill better", "have agents look at the skill", or any explicit request for a multi-angle SKILL.md review. Do NOT trigger for typo passes or single-step tweaks (direct edit is faster). On contested triggers vs `skill-creator:skill-creator`: `skill-creator` is the right call for scaffolding a new skill from scratch AND for eval-driven iteration with quantitative benchmarks (test prompts, with-skill vs baseline runs, pass-rate scoring, programmatic description-triggering optimization). `skill-md-improver` is the right call for a qualitative multi-angle audit of an existing SKILL.md — no eval harness, no benchmark scoring, just 5 lensed critics and a tiered punch-list. If the user wants to *score* or *eval* the skill, defer to `skill-creator`. Sibling skills for related artifacts — `readme-md-improver` (READMEs), `hook-review` (Claude Code hooks), `neovim-plugin-review` (nvim plugins) — defer to those when the target is one of those artifact types.
argument-hint: "[path-to-skill-md]" — optional. Defaults to ./SKILL.md when invoked from inside a skill folder. Pass an explicit path otherwise (e.g. `~/.claude/skills/foo/SKILL.md` or `~/.dotfiles/general/.claude/skills/foo/SKILL.md`).
---

# skill-md-improver

Multi-agent SKILL.md review: 5 critique angles in parallel, synthesized into a tiered punch-list, then applied with user confirmation. Sister skill to `readme-md-improver`, shaped the same way but lensed at SKILL.md files.

## Files

- [`SKILL.md`](SKILL.md) — this file. Workflow, agent angles, concrete techniques.
- [`references/conventions.md`](references/conventions.md) — distilled rules from `~/CLAUDE.md`'s "Skills" section (portability, composability, frontmatter checklist, standard layout). Backs angle-1 and angle-5.
- [`references/avoid.md`](references/avoid.md) — Bad → Better antipatterns for SKILL.md content (bloated descriptions that don't disambiguate, steps that rely on author-only context, helpers that should be skills, etc.). Read during step 5 when applying changes.

## Table of contents

- [When to use](#when-to-use)
- [When NOT to use](#when-not-to-use)
- [Steps](#steps)
  - [1. Locate the SKILL file and gather context](#1-locate-the-skill-file-and-gather-context)
  - [2. Spawn all 5 agents in parallel](#2-spawn-all-5-agents-in-parallel)
  - [3. Per-agent boundaries](#3-per-agent-boundaries)
  - [4. Synthesize into a tiered punch-list](#4-synthesize-into-a-tiered-punch-list)
  - [5. Apply selected changes](#5-apply-selected-changes)
- [Composition](#composition)
- [Guardrails](#guardrails)

## When to use

- User says "improve this skill", "review my skill", "audit my skill", "audit this SKILL.md", "make this skill better", or invokes `/skill-md-improver`.
- The user wants a *thorough* multi-perspective critique of an existing SKILL.md — not a typo pass, not a description tweak, not an eval-driven scoring run.

## When NOT to use

- **Brand-new skill from scratch** → `skill-creator:skill-creator` scaffolds the folder + frontmatter.
- **Eval-driven iteration / benchmark scoring** → `skill-creator` runs the with-skill vs baseline harness and produces quantitative pass-rate / time / token deltas. `skill-md-improver` produces a qualitative punch-list with no scoring.
- **Programmatic description-triggering optimization** → also `skill-creator` (`run_loop.py`). `skill-md-improver`'s angle-1 critic flags description issues but doesn't optimize them in a loop.
- Typo, grammar, or single-step tweaks → direct edit.
- Hooks → `hook-review`. READMEs → `readme-md-improver`. Neovim plugins → `neovim-plugin-review`.
- The skill folder exists but `SKILL.md` is near-empty (a stub) → recommend `skill-creator` first, then come back here once there's substance to review.

## Steps

### 1. Locate the SKILL file and gather context

- Default to `./SKILL.md` if invoked from a skill folder. Otherwise require an explicit path.
- Read the SKILL.md in full **first** — subagents shouldn't repeat this.
- Read alongside it, only what's needed:
  - Sibling files in the skill folder: `references/*.md`, `scripts/*` (any). Detail in the body should match what these files actually contain.
  - Other skills in the same parent — `ls ~/.claude/skills/` for installed user-level skills, and (on the author's machine) `ls ~/.dotfiles/general/.claude/skills/` for the dotfiles source. Both are listed because the stowed location is the canonical install and the dotfiles location is the editable source; checking either alone misses skills the other has. Cross-check sibling-skill descriptions to spot trigger collisions.
  - `references/conventions.md` first (hand-distilled cache of `~/CLAUDE.md`'s Skills section). Only re-read `~/CLAUDE.md` itself when you suspect the cache is stale — e.g. the user mentions a new convention in the conversation, or the cache references a rule that no longer reads as load-bearing in `~/CLAUDE.md`.
  - Any `lib/` or helper scripts the skill claims to use, to verify they exist and match the body's description.

### 2. Spawn all 5 agents in parallel

Send a **single message with five `Agent` tool calls** so they run concurrently. Each gets a different angle; each prompt names the angles the others own so they don't overlap.

**Angle 1 — Triggering accuracy / frontmatter.** Does the `description` spell out concrete signals that should invoke this skill? Are trigger phrases specific (not generic "use this for X")? Do "Do NOT trigger" cases name sibling skills and explain who wins on contested triggers? Is `argument-hint` accurate (matches actual arg parsing in steps)? Is `name` the same as the folder? Frontmatter checklist — cross-check against `references/conventions.md`.

**Angle 2 — Workflow executability.** Can a cold Claude session run this start-to-finish from the SKILL.md alone? Are steps numbered and in order? Are preconditions stated up front? Are inputs and outputs of each step clear? Does any step rely on knowledge that's only in a reference file or in the author's head? Are the step boundaries crisp (no "and also" buried mid-step)?

**Angle 3 — Organization & structure.** Top-of-file TOC + Files section? Detail correctly factored between SKILL.md and `references/`? `scripts/` used when there are runnable helpers? File lengths reasonable (SKILL.md not bloated past ~200 lines)? Heading hierarchy consistent? Does the skill point at its reference files at the right step (not just in a trailing footnote)? Are reference files single-purpose (e.g. `avoid.md` only antipatterns, not mixed with positive recipes)?

**Angle 4 — Composition & delegation.** Does the skill delegate to a sibling skill where a sibling already covers the work? Are handshake flags (`/tmp/.<skill-name>-ok`) used appropriately when a hook needs to gate on validation? Does it duplicate logic that should be extracted to a shared helper or sub-skill? Any overlap with sibling skills that should be resolved by delegation rather than copy-paste? Cross-check against the composition patterns in `references/conventions.md`.

**Angle 5 — Guardrails, portability & edge cases.** Clear "When NOT to use"? What happens on precondition failure (missing args, missing tool, dirty repo)? Are guardrails imperatives, not vague suggestions? **Portability** — no hardcoded user paths (must use `$HOME`, `$WORK`, `$PROJECTS`, `$CODE`, `~/`), no machine-specific identifiers, OS branches behind `case "$os" in linux|arch) ... ;; macOS|darwin) ... ;; esac`, no embedded secrets. External binaries the skill calls must be declared as preconditions or guaranteed by the user's ansible role.

### 3. Per-agent boundaries

Every prompt must include:

- **Lens owned**: one of the five.
- **Lenses NOT owned**: list the other four explicitly. Tell the agent to defer those to other reviewers.
- **Citations**: every concrete claim references `SKILL.md:N` (or other file:line in the skill folder).
- **Length**: under 250 words.
- **Form**: bullets, with replacement text where they'd reword something.
- **Model**: `sonnet` — analysis, not heavy reasoning.

### 4. Synthesize into a tiered punch-list

Sort findings into tiers:

- **Strong signals** — flagged by ≥2 agents. Almost always merit action.
- **Standalone strong signals** — high-impact items only one agent surfaced, with concrete cost/benefit.
- **Real bugs** — broken anchor links, frontmatter triggers that contradict step-1 preconditions, references to files that don't exist, helpers documented in the body but missing from `lib/` or `scripts/`. Treat as bugs, not opinions.
- **Low priority / skip** — over-engineering for the skill's actual scope (don't propose a `scripts/` folder for a 60-line prose-only skill).

Present the synthesis with the four tiers, then use `AskUserQuestion` with 4 scope options: "strong signals + bugs (recommended)", "everything except skip tier", "bugs only", "strong only". Do **not** edit before this step.

### 5. Apply selected changes

- For heavy additions (worked examples, decision tables, scripted helpers) extract to `references/<topic>.md` or `scripts/<name>.{sh,py}` and link from SKILL.md. Keep SKILL.md a workflow, not a manual.
- After editing, re-read SKILL.md front to back to catch broken anchors, stale TOC entries, file-reference rot, mismatched step numbers.
- Worked **Bad → Better** antipatterns for common SKILL.md sins live in `references/avoid.md` — read them when applying changes; the **Better** form usually points at the specific replacement shape.
- Post-edit handoff to `skill-creator:skill-creator`: see Composition below.

## Composition

- **Subagents**: invoked via `Agent` with `subagent_type=general-purpose`. They are scoped Agent calls, not separate skills, because each one needs a custom angle prompt.
- **Post-edit handoff to `skill-creator:skill-creator`**: when frontmatter (description, argument-hint, name) or delegation changed in step 5, hand off to `skill-creator` for the description-triggering / overlap pass — it's the canonical referee per the user's `~/CLAUDE.md` convention. Don't duplicate that work here.
- This skill does not delegate to other review skills (`readme-md-improver`, `hook-review`, `neovim-plugin-review`) — they're for different artifact types.

## Guardrails

- Never spawn fewer than 5 agents — the value is in angle separation. If you'd skip one, you're solving the wrong problem (probably a single-section edit, in which case use a direct edit).
- Don't spawn agents until step 1 (read SKILL.md, sibling files, neighbouring skills, conventions) is done. Otherwise subagents waste reads on context the main agent already has.
- Don't apply edits without explicit user confirmation. Step 4 ends with a question, not an edit spree.
- For stub / brand-new SKILL.md (file barely exists), this skill is overkill — recommend `skill-creator:skill-creator` first.
