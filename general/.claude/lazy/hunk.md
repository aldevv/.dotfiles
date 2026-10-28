# Hunk

## Explaining a diff in hunk

- "Open it in hunk" means the hunk TUI with session notes, not the qa pane or PR comments. Launch it yourself: `tmux split-window -h -l 70% -c <repo> "hunk diff <base>...<head> -- <files>; read"`, then wait for `hunk session list` to show it.
- Add notes in one batch: `hunk session comment apply --repo <repo> --stdin` with `{"comments":[{"filePath","newLine"|"oldLine","summary","rationale"}]}`. `summary` (the note title) is `<TICKET>: <ticket title from Jira>`, `rationale` is the short explanation.
- Upgrade: `npm install -g --prefix ~/.local hunkdiff@latest --registry=https://registry.npmjs.org/` (the default npm registry rejects the saved login). The ansible task uses `creates`, so it never upgrades.
- `owner-private runtime state is unsafe or malformed`: move `$XDG_RUNTIME_DIR/hunk-mcp` aside (left by an old version with 775 perms).
