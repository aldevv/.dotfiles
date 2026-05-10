# Anti-patterns: Bad → Better worked examples

Companion to `SKILL.md`. Each entry pairs a real **Bad** form with the **Better** rewrite, sourced from skills the author has reviewed. The rule names match the angle descriptions in `SKILL.md` — this file carries the worked detail so `SKILL.md` stays scannable.

**When to read this**: during step 5 (apply selected changes), after the user picks a scope. Skim the entries that match the patterns you're about to fix — the **Better** form usually points at the specific replacement shape.

---

## Description that names a category instead of trigger phrases

The frontmatter `description` is the prompt the harness uses to decide whether to invoke. Generic categorizations don't trigger; concrete phrases do.

**Bad**:

```yaml
description: A skill for reviewing READMEs. Use when the user wants a README review.
```

A reader skimming the available-skills list sees "README review" and moves on. The dispatcher never matches phrases like "audit my readme", "make the readme better", "have agents look at the readme" against this description — they're not in the text.

**Better**:

```yaml
description: Spawn 5 parallel critique agents to review a README from distinct angles (first impression, information architecture, install correctness, content gaps, ecosystem comparison), synthesize the findings into a tiered punch-list, and apply the changes the user picks. Triggers on "/improve-readme-md", "improve the readme", "review my readme", "audit the readme", "make the readme better", "have agents look at the readme", or any request for a multi-angle README review. Do NOT trigger for typo passes, single-section tweaks, or when the user just wants a one-line edit — direct edits are faster than a 5-agent fan-out.
```

**Why it wins**: the description spells out the *shape* (5-agent fan-out → synthesis → apply), the trigger phrases the user is likely to say, and the negative cases. The dispatcher has surfaces to match against; the "Do NOT trigger" line keeps it from being invoked for typo passes that don't justify a fan-out.

---

## Description that omits sibling-skill disambiguation

When sibling skills share triggers — even partially — the description must name them and explain who wins on contested phrasing.

**Bad** — a new `improve-skill-md` skill that ignores `skill-creator:skill-creator`'s overlap:

```yaml
description: Review a SKILL.md and suggest improvements. Triggers on "/improve-skill-md", "review my skill", "audit this skill".
```

Both skills match "review my skill". The dispatcher picks arbitrarily; the user gets surprising behaviour.

**Better** — explicit disambiguation:

```yaml
description: ...spawn 5 parallel critique agents... Do NOT trigger for brand-new skill scaffolding (use `skill-creator:skill-creator` instead — it scaffolds frontmatter + folder layout from scratch), or quick description-triggering checks (also `skill-creator` — it's narrower and faster for a one-shot description optimization). Sibling skills for related artifacts — `improve-readme-md` (READMEs), `hook-review` (Claude Code hooks), `neovim-plugin-review` (nvim plugins) — defer to those when the target is one of those artifact types.
```

**Why it wins**: names every sibling that shares triggers, says who wins on contested phrasing, and explains the boundary (scaffolding vs audit). The dispatcher has the disambiguation it needs.

---

## Steps that depend on author-only context

A workflow step that assumes the reader knows something only the author knows ("the usual pattern", "as we discussed") — a cold Claude session can't execute it.

**Bad**:

```markdown
### 2. Fan out the angles

Spawn the usual 5 agents, one per angle. Make sure they don't overlap.
```

What angles? What model? How long should each prompt be? What stops them overlapping? The step is documentation for the author, not instruction for the executor.

**Better** — spell out the inputs every step needs:

```markdown
### 2. Spawn all 5 agents in parallel

Send a single message with five `Agent` tool calls. Each gets a different angle; each prompt names the angles the others own so they don't overlap.

**Angle 1 — First impression / hook.** Tagline strength, jargon definition, visual hook...
**Angle 2 — Information architecture.** Section order, heading hierarchy...
...

Every prompt must include: lens owned, lenses NOT owned (list the other four), citations (`README.md:N` form), length cap (under 250 words), form (bullets with replacement text), model (`sonnet`).
```

**Why it wins**: a cold session has every input it needs — angles, prompt anatomy, length cap, model choice. No author-only context.

---

## Reference file mixing antipatterns with positive recipes

A single reference file that holds both "things to avoid" and "things to do instead" muddies its job. Critics looking for antipatterns wade through positive recipes; authors looking for how-to-do-it recipes wade through Bad examples.

**Bad** — `references/avoid.md` carrying both Bad → Better antipattern pairs *and* a standalone "Use GitHub-flavored alerts for callouts" section with a type-picker table.

The alerts section is a feature-recommendation, not a Bad → Better pair. A critic angle scanning for antipatterns has to skip past it; a step-6 application checking the alerts feature has to scan past unrelated antipatterns.

**Better** — split by purpose:

- `references/avoid.md` — Bad → Better antipattern pairs only. Pure diagnosis.
- `references/<feature-area>.md` — positive recipes (e.g. `references/github-markdown.md` for alerts + video embedding + future GitHub features).

In SKILL.md, the trailing pointer line names both files with their distinct roles:

```markdown
Worked **Bad → Better** antipatterns live in `references/avoid.md`. Positive reference for GitHub-flavored markdown features lives in `references/github-markdown.md`.
```

**Why it wins**: each reference file has one job. Critics know exactly which file to load for which question.

---

## Helper documented in the body but missing from `scripts/` / `lib/`

The SKILL.md describes a helper, but the folder doesn't contain it (or vice versa — a helper exists with no body documentation).

**Bad** — SKILL.md step 4 says:

```markdown
### 4. Validate

Run `scripts/validate.sh` against the artifact. Exit 0 means clean.
```

…but `ls scripts/` returns `pack.sh upload.sh`. No `validate.sh`. The step is unrunnable; the author meant to add it.

**Better** — match the body to the folder, or add the missing helper:

- If `validate.sh` is a real step, write it under `scripts/validate.sh` with the documented exit semantics.
- If validation is meant to happen inline, drop the `scripts/validate.sh` reference and describe the inline check.

Either way, the body and the folder agree.

**Why it wins**: a cold session reading the SKILL.md can take any step at face value. Drift between body and folder is a real bug, not a style nit — flag it in the punch-list as such.

---

## A skill that copy-pastes logic a sibling already covers

A skill that reimplements a flow another skill already runs — instead of delegating — duplicates maintenance and drifts.

**Bad** — a `nightly-sync` skill that:

```markdown
### 3. Pull dotfiles

git -C ~/.dotfiles pull --rebase
cd ~/.dotfiles && for d in */; do stow "$d"; done
git -C ~/.dotfiles add -A && git commit -m "..." && git push
```

…when `sync-dotfiles` already does exactly this with conflict handling, restow logic, and machine-tagged commits.

**Better** — delegate:

```markdown
### 3. Sync dotfiles

Run the `sync-dotfiles` skill. It handles pull, conflict resolution, restow, and the machine-tagged commit. If it returns non-zero, surface its output and stop.
```

**Why it wins**: one source of truth for the sync logic. When `sync-dotfiles` adds (say) submodule handling, `nightly-sync` gets it for free. Skill conventions ("composable") call this out explicitly — when two skills' flows share a branch, delegate, don't copy.

---

## A skill with `scripts/` containing one tiny helper that should have stayed inline

The standard layout allows `scripts/`, but adding the folder for one 8-line shell snippet is premature structure.

**Bad** — skill folder layout:

```
my-skill/
├── SKILL.md
└── scripts/
    └── check.sh        # 8 lines — just curls a URL and exits 0/1
```

The 8 lines could live inline in SKILL.md as a fenced code block the executor copy-runs. The folder buys nothing but a layer of indirection.

**Better** — inline the snippet in the relevant step, drop `scripts/`:

```markdown
### 2. Check connectivity

```sh
if ! curl -fsS https://api.example.com/health > /dev/null; then
  echo "API unreachable"; exit 1
fi
```
```

**When `scripts/` *is* the right call**: the helper is non-trivial (≥30 lines, branchy, has its own error handling), it's reused across multiple steps, or it's worth invoking manually outside the skill flow. None of those apply to an 8-line health check.

**Why it wins**: simpler folder. The next skill author reading this one doesn't infer "we always have a scripts/" from one tiny helper.
