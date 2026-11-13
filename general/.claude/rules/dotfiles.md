# Dotfiles rules

## CRITICAL: Saving dotfiles changes
When the user says "save the changes in my dotfiles" (or any equivalent), they mean these folders:
- `~/.dotfiles/` (dotfiles)
- `~/notes/` (personal notes)
- `~/wiki/` (personal wiki)
- `~/.local/share/ansible/` (ansible configs)

**Prefer the `sync-dotfiles` skill** for the dotfiles repo specifically; it's faster (skips submodules) and delegates to `sync-dotfiles-full` on the monthly threshold or when a submodule is uninitialized. Fall back to `personal-push-all` only when the user explicitly asks for the broader notes/wiki/ansible sweep in addition to dotfiles.

## CRITICAL: Work content never goes into dotfiles
The dotfiles folders above are personal and synced across machines. NEVER write employer-specific content into them: work skills, work notes, company/vendor/product names, work tool names, or comments explaining a setting by a work requirement. It goes in the work tree instead (`~/work/.claude/skills/`, `~/work/.claude/lazy/`, `~/work/CLAUDE.md`).
- Before writing to any dotfiles path, ask: is this work-specific? If yes, put it in `~/work`. If a personal file must change for a work reason (e.g. a GNOME setting a work compliance check needs), change the value only and keep the wording generic.
- Example: a skill that fixes a work login check belongs in `~/work/.claude/skills/`; an ansible task that shortens the screen lock for a work policy is named after the setting, not the company or tool.
- Same rule for skills: see `~/.claude/lazy/skills.md` (global skills stay employer-neutral).
