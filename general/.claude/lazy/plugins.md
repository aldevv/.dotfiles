# Claude Code plugins (how to deal with them)

General reference for authoring + managing Claude Code plugins. My concrete instances (the `~/marketplaces/` layout, the auto-new-day engine + work pack) live in [`marketplaces.md`](marketplaces.md); this file is the mechanism, reusable for any plugin.

## What a plugin is

A plugin bundles skills (and optionally agents, hooks, MCP servers, LSP servers, scripts, references) and is distributed through a **marketplace**. A marketplace is a directory (or repo) with a manifest listing one or more plugins. The simplest useful unit is a **single-plugin marketplace**: one directory that is both the marketplace and the plugin.

## Anatomy

```
<marketplace-dir>/
├── .claude-plugin/
│   ├── marketplace.json     # marketplace manifest (lists plugins)
│   └── plugin.json          # this plugin's manifest
├── skills/<skill>/SKILL.md  # skills the plugin ships
├── scripts/                 # optional helper scripts
├── references/              # optional runtime-read markdown
└── profiles/ | agents/ | ...# whatever the plugin needs
```

- **`marketplace.json`** (must live under `.claude-plugin/`): `name`, `owner`, and `plugins[]`. Each plugin entry has a `source` (`"./"` for a flattened single-plugin marketplace where the plugin sits at the marketplace root). May also carry `allowCrossMarketplaceDependenciesOn: ["<marketplace>", ...]` to permit dependencies that resolve to other marketplaces.
- **`plugin.json`**: `name`, `version`, and optional `dependencies`. Keep `name` matching how it's invoked.

## Skill namespacing

Plugin skills are ONLY reachable as `/<plugin>:<skill>`. There is no bare `/<skill>` form for a skill that lives in a plugin. If muscle memory wants a bare command, ship a tiny **launcher shim** as a personal (non-plugin) skill that just delegates to `/<plugin>:<skill>` (that's how bare `/auto-new-day` survives).

## Dependencies (including cross-marketplace)

A plugin declares dependencies in `plugin.json`:

```json
{ "dependencies": ["<plugin>@<marketplace>"] }
```

- **Marketplace-qualify the dependency** (`plugin@marketplace`). A bare `["<plugin>"]` resolves within the SAME marketplace and won't find a plugin in another one.
- When the dependency is in a different marketplace, the depending marketplace must allowlist it: `allowCrossMarketplaceDependenciesOn: ["<other-marketplace>"]` in its `marketplace.json`.
- With both enabled, skills call across plugins by namespaced name (`/other-plugin:skill`) and they resolve. Transitive enable of dependencies needs a recent Claude Code (works on 2.1.2xx).

## Source vs cache (the thing that trips you up)

Claude Code does NOT run the source. On `install` it copies the source into a versioned cache and runs THAT:

- **Source of truth (edit here):** the marketplace dir.
- **Runtime copy (never edit):** `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/…` — edits here vanish on the next install.
- **Registry:** `~/.claude/plugins/{known_marketplaces,installed_plugins}.json`.
- `${CLAUDE_PLUGIN_ROOT}` is set for skills at runtime but is NOT exported into the Bash tool's shell, so a skill's bash blocks must resolve paths with a hardcoded fallback, never rely on that env var in a `bash` call.

## The version-keyed cache gotcha

`claude plugin marketplace update <name>` reports success but does **NOT** re-copy when the plugin `version` is unchanged. The cache is keyed by version (`…/<plugin>/<version>/`), so a same-version update only re-validates + re-registers; it never overwrites the existing version dir. Edit source, run `update`, and the runtime stays stale.

Apply a change one of two ways:

```bash
# A. cleanest — bump "version" in .claude-plugin/plugin.json, then:
claude plugin marketplace update <marketplace>
#    this is also the only way a FRESH session / a timer reliably picks up the change.

# B. force in place at the same version:
rm -rf ~/.claude/plugins/cache/<marketplace>/<plugin>/<version>
claude plugin install <plugin>@<marketplace>   # only `install` copies source -> cache
```

Then `/reload-plugins` in the running session. Always VERIFY instead of trusting the "✔ Successfully updated" line:

```bash
grep -r <the-thing-you-changed> ~/.claude/plugins/cache/<marketplace>/
```

## The CLI (commands I've used)

```bash
claude plugin validate <path>                 # validate a marketplace/plugin dir
claude plugin marketplace add <path-or-repo>  # register a marketplace
claude plugin marketplace update <name>       # re-validate/register (see version gotcha)
claude plugin marketplace remove <name>
claude plugin marketplace list                # registered marketplaces + source paths
claude plugin install <plugin>@<marketplace>  # copy source -> cache, enable
claude plugin uninstall <plugin>@<marketplace>
claude plugin list                            # installed plugins + enabled state
claude plugin details <plugin>                # a plugin's skills/agents/hooks
```

In-session: `/reload-plugins` reloads plugins from cache; `/reload-skills` reloads skills.

## Plugins and project memory (CLAUDE.md)

A skill runs from the cache dir, outside any project tree, so it can't rely on cwd auto-loading the right `CLAUDE.md`. Make the memory dependency explicit in the skill body: state which `CLAUDE.md` (+ its `.claude/lazy/*.md`) the skill operates under and load lazy files on their **Read when** triggers. Dispatched child sessions still inherit the project `CLAUDE.md` via their cwd; the explicit note is the backstop.

## Where to keep sources

- Public/shareable plugin → in dotfiles, symlinked into `~/marketplaces/` so it's versioned + synced.
- Private plugin → a git clone under `~/marketplaces/` directly (can't go in public dotfiles).
- Keep global lazy docs generic; project-specific plugin notes live in that project's scope.

## My instances

- **auto-new-day** — the morning-triage engine (generic) + a private work pack layered on it. Full layout, sweep specifics, and the global-vs-work doc split: [`marketplaces.md`](marketplaces.md); the design write-up is in the wiki at `notes/ai/claude/automation-plugin.md`.
