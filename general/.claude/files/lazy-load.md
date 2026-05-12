# Lazy-load conventions (links, detail files, and TOC)

**Load this when:** generating an audit/quality/review report that names file paths, OR writing/editing a `SKILL.md` that has a `references/` folder, OR writing a `CLAUDE.md` / `SKILL.md` over ~100 lines. Applies whether the active skill is `claude-md-improver`, `skill-md-improver`, `readme-md-improver`, `hook-review`, `neovim-plugin-review`, or any custom report-style flow.

## File references in reports

When referencing a file in any report output (file-by-file assessment headers, the "Issues" list, "Update:" section headers, the "Files found" list, diff captions), use markdown link syntax `[path](path)`. The `[]` display text and the `()` target are typically the same path. The path stays readable as plain text, AND becomes clickable when the report is opened in a markdown viewer (e.g. `mdp`).

Example report section:
```
#### 1. [./CLAUDE.md](./CLAUDE.md) (Project Root)
**Score: 85/100 (Grade: B)**

**Issues:**
- [src/auth/middleware.ts](src/auth/middleware.ts): session token storage flagged by legal
- [.goreleaser.yaml](.goreleaser.yaml): ldflag targets a non-existent symbol
```

Skip the link wrapper for inline file mentions inside running prose (a sentence that names a file once for context). Use it for structural references (anything that's a header, a list item, or a "look here" pointer the reader is likely to follow).

## Detail files index (for SKILL.md with `references/`)

When a `SKILL.md` has a `references/` folder with files that should only load on a specific trigger, group them at the top of the SKILL.md under a `## Detail files (load on demand)` section. Each entry uses this shape:

```
- [references/<file>.md](references/<file>.md). **Read when:** <specific trigger>.
```

The `**Read when:**` clause must name a concrete phase or condition, not a vague "when relevant" or "for more detail":

- **Good:** "Read when: computing per-criterion scores in Phase 2 and you need the full rubric for one of the six criteria."
- **Good:** "Read when: implementing or modifying connector actions (`actions.go`, `BatonActionSchema`, `--invoke-action`)."
- **Bad:** "Read when: scoring is needed."
- **Bad:** "For more context."

Above the list, one sentence reminding the reader that these are on-demand, e.g. "Each file has a specific trigger. Do not pre-load; pull it in only when its trigger fires."

## Table of Contents

For any `SKILL.md` or `CLAUDE.md` over ~100 lines, add a `## Table of Contents` after the H1 (or after the Detail files index, if both are present). Use flat anchor links in document order. GitHub anchor rules: lowercase, spaces become hyphens, drop colons and most punctuation, keep ampersands as `--`.

Example:
```
## Table of Contents
- [Machine connection notes](#machine-connection-notes)
- [CRITICAL: Memory Files](#critical-memory-files)
- [Workflow](#workflow)
  - [Phase 1: Discovery](#phase-1-discovery)
  - [Phase 2: Quality Assessment](#phase-2-quality-assessment)
```

Skip the TOC for short files (under ~100 lines) where scrolling beats a navigation widget.

## Why this lives outside any one skill

The same convention applies across multiple skills that produce reports or write skill prose. Centralizing it here means:
- Plugin-provided skills (`claude-md-management:claude-md-improver`, etc.) stay untouched. Plugin updates don't wipe local conventions.
- One file to edit when the convention evolves; every skill that loads this reference picks up the new rule.
- A skill that doesn't load this file falls back to its built-in formatting, which is fine.
