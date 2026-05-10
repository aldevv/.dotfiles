---
name: neovim-plugin-review
description: Spawn 5 parallel critique agents to review a Neovim plugin from distinct angles (lifecycle/integration, Lua/Neovim API correctness, cross-platform & external deps, hot-path performance, tests & docs), synthesize the findings into a tiered punch-list, and apply the changes the user picks. Triggers on "/neovim-plugin-review", "/nvim-plugin-review", "review my neovim plugin", "audit my nvim plugin", "audit this plugin before release", "give my nvim plugin a once-over", "is my plugin ready to publish", or any explicit request for a multi-angle Neovim plugin review. Use this specifically when the artifact is a Neovim plugin tree (has `lua/<name>/`, `plugin/<name>.{lua,vim}`, `doc/<name>.txt`, or `lua/<name>/health.lua`) and the user wants the full breadth, not a focused tweak. Sibling skills — `simplify` (single-pass code cleanup of a recent diff), `hook-review` (Claude Code hooks, not nvim plugins), `code-review:code-review` (PR review of a diff), `improve-readme-md` (README-only review — defer to it when the only complaint is the README). Do NOT trigger for typo passes, single-function tweaks, init.lua user configs that aren't published as plugins, generic Lua libraries with no Neovim API surface (love2d games, plain Lua libs), or README-only requests.
argument-hint: "[path-to-plugin-root]" — optional. Defaults to the current repo root. Pass a subdirectory if the plugin lives inside a monorepo (e.g. `nvim/myplugin`).
allowed-tools:
  - Bash
  - Read
  - Agent
  - Skill
  - AskUserQuestion
---

# neovim-plugin-review

Multi-angle review of a Neovim plugin. Five agents run in parallel, each focused on one dimension of plugin quality; afterwards the findings are tiered, the user picks scope, and the agreed changes are applied.

**User input**: $ARGUMENTS

## When to use

- User says "review my neovim plugin", "audit this nvim plugin", "look at this lua plugin", or invokes `/neovim-plugin-review`.
- The artifact is a published or publishable plugin — has at least one of `lua/<name>/`, `plugin/<name>.{lua,vim}`, `doc/<name>.txt`, or a plugin-spec snippet in the README.
- The user wants the *full* multi-angle critique, not a focused tweak.

## When NOT to use

- Typo passes, single-function changes, or "rename this variable" — direct edit is faster.
- Personal `init.lua` config (not a plugin tree) — there's no plugin contract to audit.
- Pure Lua libraries with no Neovim API surface — the angles below assume `vim.*` usage.
- Right after a /simplify pass on the same code — you'd just re-flag what was already addressed.

## Steps

### 1. Locate the plugin root and gather context

Parse `$ARGUMENTS`:
- Path-like → resolve to absolute, verify it exists.
- Empty → use `pwd` (assume current repo).

**Verify it looks like a plugin** before spending agent budget. Check for at least one of:
- `lua/<name>/init.lua`
- `plugin/<name>.{lua,vim}`
- `doc/<name>.txt`
- `lua/<name>/health.lua` (a `:checkhealth` provider — strong signal of a real plugin)

If none of those exist, ask the user to confirm the path before fanning out — five agents on a non-plugin is wasted work. If the only thing the user actually wants reviewed is the README, hand off to `improve-readme-md` instead.

Run **in parallel** to gather context the agents will need:
- `Read` the entry module (`lua/<name>/init.lua` or `plugin/<name>.{lua,vim}`).
- `Read` any module under `lua/<name>/` if the entry splits across files.
- `Read` `README.md` (install snippets feed angles 1 and 5).
- `Read` `Makefile` / `justfile` / `.luarc.json` / `stylua.toml` if present.
- `Read` `tests/` layout (one or two specs is enough — angle 5 will look at the rest).
- `Read` `doc/<name>.txt` if present.
- `git log --oneline -20` — recent commit messages give a sense of churn and conventions.
- `git ls-files` (or `find . -maxdepth 3 -type f -name '*.lua'`) — short tree.

Detect the **target Neovim version** signal: scan for `vim.uv` (0.10+), `vim.system` (0.10+), `vim.iter` (0.10+), `vim.lsp.config` (0.11+), `vim.snippet` (0.10+). Capture the floor; angles 2 and 4 use it.

Detect the **plugin manager target(s)** the README documents (lazy.nvim, packer, vim-plug, mini.deps, rocks.nvim) — angle 1 will cross-check install snippets against the plugin's actual layout (`build`, `dependencies`, `cmd`, `event`, `ft`).

### 2. Spawn all 5 agents in parallel

**Send a single message with five `Agent` tool calls.** Each agent is briefed independently — it has no memory of this conversation, so the prompt must be self-contained. Every prompt must include:

- The plugin root path and a one-line layout summary
- The detected Neovim version floor (from step 1)
- Inline contents of files relevant to that angle (don't make the agent re-walk the tree)
- **Lens owned**: one of the five
- **Lenses NOT owned**: list the other four explicitly so the agent doesn't drift
- **Citations**: every concrete claim references `<file>:<line>`
- **Length**: under 300 words
- **Format**: `Findings (bulleted) → Severity (low/med/high) → file:line → Concrete fix or replacement snippet`

Use `subagent_type: "general-purpose"` and `model: "sonnet"` for all five — analysis, not heavy reasoning.

### Agent 1 — Lifecycle & plugin-manager integration

- `setup(opts)` ergonomics: idempotency on second call, partial-table merge semantics, sensible defaults, type-validation of inputs (clear error vs silent coercion).
- Side effects on `require()`: top-level work that should be deferred to `setup()` or first-use (autocmd registration, file I/O, network probes, executable shells).
- Plugin-manager compatibility: README install snippets for lazy.nvim / packer / vim-plug match the actual entrypoint and `build` step. `cmd`/`event`/`ft` lazy-load triggers wire the right user commands and autocmds.
- Build steps: do they assume a toolchain (Go, Rust, node) the user might not have? Is there a fallback or a clear precondition? Are they idempotent and async (jobstart) or do they freeze nvim?
- Health & install: is there a `:checkhealth <plugin>` provider? A `:<Plugin>Install` user command? A passive nudge if a required external binary is missing?
- Dispose: do autocmd groups get cleaned up on reload? On `VimLeavePre`? Is there a `M.close()` / teardown path?

### Agent 2 — Lua / Neovim API correctness

- `vim.api.*` vs `vim.fn.*`: prefer `vim.api` where available; flag `vim.fn` calls that have an `api` equivalent (e.g. `vim.fn.bufnr()` vs `vim.api.nvim_get_current_buf()`).
- `vim.uv` vs `vim.loop`: floor matters. `local uv = vim.uv or vim.loop` is the portable form; flag bare `vim.loop` if the floor is 0.10+.
- `vim.schedule_wrap` discipline: any `uv` callback that touches `vim.api`/`vim.fn` MUST be wrapped. Flag missing wraps.
- Autocmds: must use `nvim_create_augroup` with `clear = true` (or explicit `nvim_del_augroup_by_id`); buffer-local autocmds for buffer-scoped behavior; `pattern` correctness (e.g. `*.md` vs filetype `markdown`).
- Keymaps: `vim.keymap.set` (modern) vs `vim.api.nvim_set_keymap` (legacy); `silent`, `desc`, `noremap` defaults; conflict with `<Plug>` mappings and user remappings.
- Job handling: `jobstart` exit handling, stdout/stderr buffering choice, `on_exit` cleanup of state, double-close races on uv handles (`is_closing()` check), pipe vs detach semantics.
- Error paths: errors surfaced via `vim.notify` with proper levels, no bare `error()` that aborts the autocmd chain, no swallowed pcalls hiding bugs.

### Agent 3 — Cross-platform & external dependencies

- OS branching: `linux` / `macos` / `windows` (don't forget windows — at minimum a clean "unsupported" message). Detection via `vim.uv.os_uname().sysname` or `jit.os`.
- Shell escaping: `vim.fn.shellescape` for any value that hits `vim.fn.system`. Flag string concatenation into shell commands.
- Executable detection: `vim.fn.executable("foo") == 1` before invoking `foo`; document each external dep in the README.
- Optional deps: graceful degradation when an optional binary (e.g. `xdotool`, `wmctrl`, `lsof`, `rg`, `fd`) is missing — fallback or skip with a debug log, not a crash.
- WM / desktop assumptions (Linux): which WMs are tested, what happens on unknown WMs (i3 vs xmonad vs wayland sway vs hyprland). Don't auto-position on unknown.
- Path handling: `vim.fs.joinpath` / `vim.fn.fnamemodify` instead of hand-built `"/" .. foo`.
- Terminal vs GUI: any TUI-only assumptions (kitty, alacritty) that break in neovide / VimR.

### Agent 4 — Performance / hot paths

- Startup cost: top-level `require()` fanout, file I/O at module load, eager autocmd registration. Recommend lazy-require for modules only used after a user-triggered action (browser launchers, install scripts, big config tables).
- Per-event hot paths: `CursorMoved`, `CursorMovedI`, `TextChanged`, `InsertCharPre` — these fire constantly. Any work in those callbacks must be debounced, throttled, or short-circuited.
- Debounce / throttle: `vim.uv` timer pattern; double-close race on cancel; identical-value dedupe (don't ship the same scroll line twice).
- Shell-out cost: `vim.fn.system` is synchronous — flag uses on hot paths. Prefer `vim.system` (0.10+) async, or `jobstart`.
- Allocation churn: tables created per-event, closures captured per-event when a static one would do.
- Buffer ops: prefer `nvim_buf_get_lines(buf, start, end_, ...)` for ranges over `nvim_buf_get_lines(buf, 0, -1, ...)` + filter.
- Autocmd patterns that fire too widely (`*` vs `*.md` vs filetype).

### Agent 5 — Tests & docs

- Tests: presence of `tests/` (plenary.busted, mini.test, vusted). Coverage of the entry module, edge cases, error paths. Stubbing patterns for `vim.fn.*` / `vim.notify` (does the test suite isolate IO?). Smoke tests for IPC / external-process flows that pure stubbed tests can't catch.
- CI: GitHub Actions / equivalent that runs the test suite on a real Neovim. Matrix across versions if the floor is forward-compatible.
- README: install snippets per plugin manager, requirements (Neovim version, external binaries), configuration table with defaults, a quickstart, screenshots/asciinema if the plugin has UX. Cross-check claims against the code (defaults, keymaps).
- `:help <plugin>`: presence of `doc/<name>.txt` with vimdoc tags / anchors. Without it `:help` won't find the plugin.
- CHANGELOG and version policy: SemVer or rolling? Tagged releases? Compatibility statement (Neovim version floor).
- Code comments: WHY comments where the invariant is non-obvious (timer races, IPC contracts, single-instance constraints), absent where names already explain.

### 3. Synthesize into a tiered punch-list

After all 5 return, sort findings into tiers:
- **Strong signals** — flagged by ≥2 agents from different lenses (e.g. hot-path AND lifecycle both flag `setup()` shelling out at startup). Almost always merit action.
- **Standalone strong signals** — high-impact items only one agent surfaced, with concrete cost/benefit.
- **Real bugs** — anything in agents 1–3 that's a fact-check failure (README claims a default the code doesn't ship; install snippet wires `build` to a target that doesn't exist; `vim.uv` used without the fallback on a 0.9 floor).
- **Low priority / skip** — cargo-cult suggestions that don't fit the plugin's scope (`:checkhealth` on a 50-line plugin with no external deps; vimdoc generator on a plugin nobody installs via `:help`).

**Delete-vs-fix.** A flagged section sometimes deserves removal, not expansion. A health-check provider on a trivial plugin is noise; a 200-line README on a 100-line plugin is friction. Before adding scaffolding to fix a finding, ask whether the surface should exist at all.

Present the synthesis with the four tiers, then use `AskUserQuestion` with 3–4 scope options:
- "strong signals + bugs (recommended)"
- "everything except skip tier"
- "bugs only — minimum-risk pass"
- "show me the full per-agent reports first"

Do **not** edit before this step.

### 4. Apply selected changes

- Apply edits to the plugin source directly.
- If a finding implies a paired README/docs change (new option, renamed keymap), patch both in the same pass.
- If `tests/` exists, run the test suite after editing (`make test`, `make test-lua`, or whatever the project's Makefile/justfile defines). If no tests exist, surface that as one of the synthesis findings rather than silently skipping.
- For heavy additions (full vimdoc, CHANGELOG, GitHub Actions workflow) — pause and confirm before scaffolding.

**Concrete techniques that tend to work for Neovim plugins:**

- **Lazy-require submodules behind their callsites.** `local browser = require("...browser")` inside `M.open()` instead of at the top of `init.lua` shaves startup for users who never trigger that path.
- **Replace top-level autocmd registration with `setup()`-time registration.** Top-level work hits every nvim launch; `setup()` runs once and the user controls when.
- **Add a `:<Plugin>Install` command + passive nudge** instead of shelling out at setup. Plugin-spec `build = ":<Plugin>Install"` is the idiomatic install path for any binary the plugin needs.
- **Wrap any `vim.uv` callback that touches `vim.api`/`vim.fn` in `vim.schedule_wrap`.** Failing to do so causes intermittent "Cannot use vim.api in fast event" errors.
- **Dedupe autocmd groups with `nvim_create_augroup(..., { clear = true })`.** Plugin reloads otherwise stack handlers and fire each callback N times.

## Composition

- **Subagents**: invoked via `Agent` tool with `subagent_type=general-purpose`. They are scoped Agent calls, not separate skills, because each one needs a custom angle prompt.
- **Test runner / formatter**: invoked inline by the main agent after edits. No separate skill is involved.
- **Pairs well with**: `simplify` after this skill produces a diff — `/simplify` will catch any leftover comment rot or hacky patterns the lens-based review didn't surface. They are complementary, not redundant.

## Guardrails

- **Always 5 agents, always parallel.** The point is angle separation; running fewer is solving the wrong problem.
- **Don't spawn agents until step 1 is done.** Reading the entry module and tests in the main agent first prevents the subagents from each re-reading the same files.
- **Don't apply edits without explicit user confirmation.** Step 4 ends with a question, not an edit spree.
- **For plugins under 200 lines** (single `init.lua`, no submodules, no tests), this skill is overkill. Recommend a direct read + targeted edits instead — say so up front in the synthesis.
- **For plugins with no README**, angle 5 will dominate — surface that in the synthesis ("docs missing entirely") rather than dribbling it across each agent's report.
