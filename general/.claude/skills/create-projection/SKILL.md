---
name: create-projection
description: Create a `.projections.json` for any project so vim-projectionist (`:A`, `:Etype`) and the `prj` Ruby CLI can jump between key files (e.g. `model.go` ↔ `controller.go`, `connector.go` ↔ `config.go` ↔ `cmd/*/main.go`). Triggers on "/create-projection", "create a projection", "set up projectionist", "I want :A to jump between X and Y", "wire up projection types for this project".
---

# Create projection

Generate a single `.projections.json` at the project root that handles both vim-projectionist navigation and the `prj` Ruby CLI. Default to **per-project** files — they avoid the `s:match` limitation entirely and never need a sidecar `.nvim.lua`.

## When to use

User asks for any of:
- Fast jumping between paired files (`:A` to alternate, `:Etype name` to open by type).
- A projectionist setup for the current repo.
- A `prj edit <type> <name>` shortcut from the shell.

If the user invokes `/create-projection` with no clarification, ask 1-2 targeted questions before writing anything. Don't guess file types from the codebase silently.

## Decision flow

1. **Locate the project root.** Walk up from `cwd` to the nearest `.git`, `go.mod`, `package.json`, `pyproject.toml`, `Cargo.toml`, `Gemfile`, etc. The root is where `.projections.json` lands.
2. **Ask the user what types they want** (use AskUserQuestion if not obvious from context). Each type needs:
   - A short name (e.g. `model`, `controller`, `connector`, `config`).
   - A glob pattern relative to project root with **at most one `*`** (more on this below).
   - Optional alternates (other paths to cycle to via `:A`).
3. **Write `<root>/.projections.json`.**
4. **Verify** the file resolves correctly:
   - In a headless nvim test (without `-u`, since `-u` skips exrc/heuristics): `nvim --headless -c 'edit <file>' -c 'echo projectionist#query_file("alternate")' -c 'qa!'`.
   - With `prj` CLI if installed: `EDITOR=echo prj edit <type> <name>`.
5. **Tell the user what commands they get** — `:A`, `:Aname`, `:Sname`/`:Vname`/`:Tname`, `prj edit <name>`.

## Hard rule: vim-projectionist accepts only one `*` per pattern

`autoload/projectionist.vim:s:match` rejects patterns with more than one `*` (silently — `:A` returns "No alternate file" with no error). The other accepted form is `prefix**infix*suffix`, which is rarely what you want.

**Always design patterns with exactly one `*`** and put them at the project root. Examples that work:

```json
{
  "pkg/connector/connector.go": { "type": "connector", "alternate": "pkg/config/config.go" },
  "pkg/config/config.go":       { "type": "config",    "alternate": "pkg/connector/connector.go" },
  "cmd/*/main.go":              { "type": "cmd",       "alternate": ["pkg/connector/connector.go", "pkg/config/config.go"] },
  "app/models/*.go":            { "type": "model",     "alternate": "app/controllers/{}_controller.go" },
  "app/controllers/*_controller.go": { "type": "controller", "alternate": "app/models/{}.go" }
}
```

Patterns that **silently break vim** (avoid unless `prj`-only):
- `proj-*/cmd/*/main.go` — two `*`.
- `**/*.test.ts` — `**` outside the special form.

## Useful placeholders in `alternate` templates

- `{}` — value of the wildcard captured from the current pattern. Single `*` only.
- `{1}`, `{2}` — indexed wildcards (only with the rare `prefix**infix*suffix` form).
- `{project|basename}` — last segment of the project root path. Useful when the project name appears inside paths (e.g. cmd dir matches the project dir name).
- `{file|basename}`, `{file|dirname}` — operate on the current buffer.

Example using `{project|basename}` — alternate from `connector.go` to `cmd/<project>/main.go`:

```json
"pkg/connector/connector.go": {
  "type": "connector",
  "alternate": ["pkg/config/config.go", "cmd/{project|basename}/main.go"]
}
```

## When the user wants a workspace-level file across many sibling projects

(e.g. `~/work/baton-*/` with many connectors, single config to rule them all.)

Two-file workaround, since vim-projectionist won't match multi-`*` patterns:

1. **`<workspace>/.projections.json`** — multi-`*` patterns. The `prj` CLI handles these (`build_glob` substitutes the first `*` and globs the rest). Vim's `:Etype name` cross-project also works via simple substitution. **`:A` does NOT work from this file.**
2. **Per-project `.projections.json`** at each child — single-`*` patterns, gives `:A` within a project.

Single source of truth: keep one master and `ln -sfn ../.projections-master.json <child>/.projections.json` for each child. Add `.projections.json` to `~/.config/git/ignore` so untracked symlinks don't clutter `git status`.

**Avoid the `g:projectionist_heuristics` route** unless the user explicitly wants it. It works but requires `.nvim.lua` + `:trust` re-run on every edit, and that's friction for marginal gain over symlinks.

## CLI: `prj` (Ruby gem `projectionist`)

If the user wants shell-level navigation:

```bash
gem install --user-install projectionist          # installs the `prj` binary
export PATH="$HOME/.local/share/gem/ruby/<ver>/bin:$PATH"
prj types                                          # list registered types
prj edit <type> <name>                             # open file matching <type> with <name>
```

`prj edit` walks up from cwd looking for `.projections.json`, so the per-project file is found first (correct scoping).

`prj list` is broken in `projectionist-0.3.0` (gem bug). Don't recommend it.

## Vim plugin install (only if not already present)

Lazy.nvim spec — drop it in `lua/plugins/<topic>.lua` (or wherever the user keeps lazy specs):

```lua
"tpope/vim-projectionist",
```

Optional telescope picker (warns: 0.1.x of the plugin uses removed `telescope.utils.get_default`; shim it):

```lua
{
  "adalessa/telescope-projectionist.nvim",
  dependencies = { "nvim-telescope/telescope.nvim", "tpope/vim-projectionist" },
  config = function()
    local tu = require("telescope.utils")
    if not tu.get_default then
      tu.get_default = function(v, d) if v == nil then return d end return v end
    end
    require("telescope").load_extension("projectionist")
  end,
},
```

## Verifying the file works

After writing, always test before declaring done. Real-usage check (do **not** pass `-u`, that skips exrc):

```bash
cd <project-root>
nvim --headless \
  -c 'edit <a-file-matching-a-pattern>' \
  -c 'echo projectionist#query_file("alternate")' \
  -c 'echo projectionist#query("type")' \
  -c 'qa!'
```

Both should return non-empty results. If `query_file('alternate')` returns `[]`, the pattern didn't match — most often because of >1 `*`.

## What NOT to do

- Don't write `.nvim.lua` heuristics by default. Per-project `.projections.json` covers the same ground without trust friction.
- Don't generate patterns with two or more `*`. They will silently fail in vim.
- Don't create `.projections.json` files outside the project root unless the user explicitly asked for a workspace-level file.
- Don't add `Co-Authored-By` or any AI mention if asked to commit the result.
