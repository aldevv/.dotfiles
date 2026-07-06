# lazy-gaps

Audits a set of PR-review comments / bug findings / lessons against your `CLAUDE.md` + lazy files, then proposes / applies edits to close the gaps.

## Args

- `[source]` — one of:
  - path to a dispatch JSON (`~/work/.auto-new-day/dispatch/<TICKET>.json`)
  - PR URL whose comments to audit
  - free text, one item per line
- `[scope=work|all|auto]` — which lazy files the audit walks:
  - `work` = only `$HOME/work/CLAUDE.md` + `$HOME/work/.claude/lazy/*.md`
  - `all` = work files plus global `~/CLAUDE.md` + `~/.claude/lazy/**/*.md`
  - `auto` (default) = ancestor walk from cwd

## What it does

- For each item: classify as COVERED-AND-CORRECT / COVERED-BUT-WRONG-OR-OUTDATED / NOT-COVERED.
- Decide whether the gap is worth a rule.
- Update an existing lazy file or create a new one (with operator approval per item).

## See also

- Sibling: `claude-md-save` (single-rule save), `claude-md-simplify` (restructure).
