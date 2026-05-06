# Neovim config

Personal Neovim config, managed as the `nvim` Stow package in `~/.dotfiles`. Files here are symlinked into `~/.config/nvim/`.

## Load order

`init.lua` is the entry point:
1. `vim.loader` cache + bootstraps `lazy.nvim` into `stdpath('data')/lazy/`.
2. `require("utils.lua.globals")` — globals used everywhere.
3. **Root user** short-circuits to a minimal config (`ui` + `config.automation` + `keybindings`) and returns. Editing as root yields a stripped-down setup.
4. `NVIM_DEBUG=1` env loads `plugins-debug` instead of the full plugin set — use it to bisect plugin issues.
5. Normal path: `require("config")` (settings + automation) → `lazy.setup("plugins", ...)` → `keybindings` → `ui`.

The lazy spec passes `dev = { path = "~/repos/github.com/rest-nvim", ... }` so any plugin under that path is loaded from disk instead of GitHub.

## Layout

- `lua/config/` — non-plugin runtime: `settings.lua` (vim options), `automation/` (autocmds, filetype overrides), `plugins/<name>.lua` (per-plugin config bodies).
- `lua/plugins/*.lua` — lazy.nvim specs grouped by topic (`ai`, `lsp-plugins`, `git`, `frontend`, `backend`, `treesitter`, `telescope`, `ui`, `mini`, `markdown`, `dap`, `neotest`, `org`, `colors`, `images`, `snippets`, `whichkey`). `lazy.setup("plugins", ...)` auto-imports every file in this dir.
- `lua/keybindings/` — split by area (`telescope.lua`, `harpoon.lua`, `lsp.lua`, `ai.lua`, `fugitive.lua`, `term.lua`, `text-objs.lua`, `Sbindings.lua`, `legacy.lua`, …). `init.lua` is the orchestrator.
- `lua/ui/` — `init.lua` + folding setup (`folding.lua`).
- `lua/utils/lua/` — Lua helpers (`float.lua`, `lazy.lua`, `globals.lua`, `misc.lua`, `lsp.lua`, `telescope.lua`, `windows.lua`, `highlight.lua`, …).
- `lua/utils/vanilla/` — pure-vimscript utilities (e.g. quickfix/location toggles).
- `lua/plugins-debug.lua` — minimal spec for `NVIM_DEBUG=1`.
- `lua/plugins.lua` — **legacy**, not the active spec dir; the active spec is the `plugins/` directory above.
- `lua/shortcuts.lua` — wired in via `pcall` so a missing `~/.config/shortcuts/` does not break startup.
- `after/plugin/` — runs after plugins (`formatoptions.vim`, `fugitive.lua`, `settings.lua`).
- `ftplugin/`, `plugin/skeleton.vim`, `ftdetect/`, `spell/`, `my_snippets/` — standard runtime dirs.
- `scripts/`, `md-preview.nvim/` — markdown-preview tmux integration (in development).

## Plugin spec convention

Every spec in `lua/plugins/*.lua` uses this idiom for config:

```lua
local function req(module)
  return function(name, opts) require(module) end
end
return {
  { "owner/plugin", config = req("config.plugins.<name>") },
}
```

So the lazy spec only declares the plugin and dependencies; the actual setup body lives at `lua/config/plugins/<name>.lua`. When adding a plugin that needs config, put the spec in `lua/plugins/<topic>.lua` and the body in `lua/config/plugins/<name>.lua`.

LSP/completion specifically lives under `lua/config/plugins/lsp/` (`lsp.lua`, `blink.lua`, `formatters.lua`, `lang_opts.lua`, `defaults_opts.lua`, `lsp-signature.lua`). DAP under `lua/config/plugins/dap/`.

## Colemak remap (READ THIS BEFORE TOUCHING KEYBINDINGS)

Keybindings in `lua/keybindings/init.lua` assume **Colemak-DH** by default. The remap swaps motion keys:

- `n` = down (was `j`), `e` = up (was `k`)
- `j` = end-of-word (was `e`)
- `l` = enter insert mode (was `i`); `i` = select-inside text-object (was `l` is unused)
- `gk` = `gn`, `cj` = `ce`
- `N` in normal mode = join lines (preserves cursor); `N`/`E` in visual = move block down/up
- `n`/`e` push to jumplist when count > 1

Set `USE_QWERTY=1` in the env to skip the remap (the colemak-only block is gated on `not os.getenv("USE_QWERTY")`). When writing or reading keymaps, remember `n`/`e`/`j`/`l`/`i` mean different things than upstream docs assume.

## Leader scheme

- `<leader>` = `<Space>` (set in `lua/plugins.lua` and the root branch of `init.lua`).
- Mnemonic prefixes documented at the top of `keybindings/init.lua`:
  - `<leader>,` → configuration (`,L*` lazy, `,l*` lsp, `,M*` mason, `,n*` null-ls, `,t*` treesitter, `,f*` fun/leetcode/apm, `,m*` markdown).
  - `<leader>.` → commands (`.dgp*` dotfile pushes, `.v*` reload/source/luafile, `.s*` shell shebang/spawn, `.an*` ant note, `.r` ranger, `.st` terminal, `.br` README).
  - `<leader>o` → diagnostics (in lsp keymaps).
- `s` is a personal prefix in normal mode for file/window/netrw commands (`sf*` create file/dir, `ss`/`sS`/`st`/`sT`/`sv`/`sV` netrw, `sd` `:bd`, `sc` lcd, `sy*` yank path, `sm` maximize, `sT` toggle transparency, `so*` toggles).
- `<leader><leader>` → run-things (`d`/`D` dispatch, `s`/`S` start, `r`/`R` entr, `g`/`G` go run, `p`/`P` python, `t*` todo files, `x` luafile current).
- `<c-q>` quickfix prefix, `<c-l>` location-list prefix (the default `<c-l>` is intentionally deleted before the prefix is set up).
- `<cr>` toggles folds (`za`); overridden in qf/cmdwin via autocmd so `<cr>` keeps its native behavior there.

`<F1>` opens this keybindings file directly — handy for self-edits.

## Settings highlights (`lua/config/settings.lua`)

Defaults that diverge from upstream and matter for behavior:
- `splitright`/`splitbelow` true.
- `textwidth = 95`, `colorcolumn = "100"`, `shiftwidth = 2`, `expandtab` on.
- Persistent `undofile` + timestamped `backup` (`bex` set to `@<date>.<HH:MM>` in a `BufWritePre` autocmd).
- `exrc` enabled — local `.nvim.lua`/`.exrc` files in cwd will execute.
- `cmdheight = 0`, `showmode = false`, `laststatus = 2` (per-window), `pumblend = 10`, `spell = true`.
- `inccommand = "nosplit"`, `jumpoptions = "stack"`, `updatetime = 250`, `timeoutlen = 700`.
- `grepprg = "rg --vimgrep --no-heading --smart-case"`.
- Diagnostics: virtual text limited to ≥Warning, `update_in_insert = false` (intentional — avoids ghost-text overlap with cmp).
- Python hosts hardcoded (`/usr/bin/python[3]` on Linux, `/usr/local/bin/python[3]` on macunix).
- `mdx` files are treated as `markdown` via `vim.filetype.add`.

## Automation (`lua/config/automation/`)

Autocmds with non-obvious side effects:
- **Format on save** for `js,jsx,mjs,java,c,cpp,hs,json,ts,tsx,rs,go,html,svelte,vue,py,sh,lua,tf,tfvars` via `vim.lsp.buf.format()` on `BufWritePre`. Comment in source warns this slows saves — disable here if a formatter misbehaves.
- Trailing whitespace stripped on save for `.vim` and `.lua`.
- `BufEnter *` removes `r`,`o`,`t` from `formatoptions` (no auto-comment-continuation, no autowrap).
- Saving `config.h` runs `CompileSuck` — rebuilds whichever suckless tool's directory you are in.
- Saving `dwmstatus` restarts the status bar.
- Saving `*.Xresources` merges via `xrdb`; saving `*sxhkdrc` SIGUSRs sxhkd.
- Saving `sf`/`sd` runs `$AUTOMATION/shortcuts`.
- Saving `$NOTES/*.md` triggers a dotfiles push via `Dispatch`.
- LspAttach on `*/dwm-flexipatch/config.h` immediately stops the LSP (it mis-highlights that file).
- `.envrc` opens as `bash`; `.projections.json` as `projections.json` syntax json.

## Adding a plugin

1. Drop the spec in `lua/plugins/<topic>.lua` (pick the topic file matching the plugin's domain; create a new one only if none fit).
2. If it needs setup, write the body in `lua/config/plugins/<name>.lua` and reference it via `config = req("config.plugins.<name>")`.
3. Lazy auto-imports the new spec on next start. `:Lazy sync` to install.
4. Keymaps for the plugin go in `lua/keybindings/<area>.lua` (or a new file required from `keybindings/init.lua`), not inline in the spec.

## Lock file

`lazy-lock.json` pins plugin commits and is committed to the repo — sync across machines depends on it. `:Lazy update` rewrites it; `:Lazy restore` re-applies it. Treat changes to it as deliberate.
