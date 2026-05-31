# Dotfiles rules

## CRITICAL: Saving dotfiles changes
When the user says "save the changes in my dotfiles" (or any equivalent), they mean these folders:
- `~/.dotfiles/` (dotfiles)
- `~/notes/` (personal notes)
- `~/wiki/` (personal wiki)
- `~/.local/share/ansible/` (ansible configs)

**Prefer the `sync-dotfiles` skill** for the dotfiles repo specifically; it's faster (skips submodules) and delegates to `sync-dotfiles-full` on the monthly threshold or when a submodule is uninitialized. Fall back to `personal-push-all` only when the user explicitly asks for the broader notes/wiki/ansible sweep in addition to dotfiles.
