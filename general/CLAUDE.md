# Claude Code Configuration

## Machine connection notes
Per-machine connection info, SSH aliases, and deploy recipes live in `~/CLAUDE-machines.md` (gitignored, machine-local). Read it when the user mentions `mac`, `titan`, or other host aliases, or asks how to push code/configs between machines.

## CRITICAL: Memory Files
**NEVER create memory files.** Do not write to `~/.claude/projects/*/memory/` or create any `MEMORY.md` or memory files of any kind. The user does not use the memory system.

## CRITICAL: Playwright Browser Issues
**NEVER ask the user to do anything with the browser.** Use the Playwright MCP plugin tools directly — they handle browser launch automatically.
- **NEVER delete** `~/.cache/ms-playwright/mcp-chrome-*` — contains Okta session data
- If browser is frozen or errors out: call `browser_close`, then retry — Chrome relaunches automatically

## Development Environment
- **Repos**: `~/repos` - Git repositories
- **Projects**: `$PROJECTS` - Active project work
- **Code**: `$CODE` - Code directory
- **Dotfiles**: `~/.dotfiles` - Configuration management

## Key Configurations
- **Neovim**: `~/.config/nvim/init.lua` (main config at `.v`)
- **Zsh**: `~/.config/zsh/.zshrc` (`.z`)
- **Tmux**: `~/.config/tmux/tmux.conf` (`.t`)
- **Aliases**: `~/.config/.aliases` (`.a`)

## Automation & Tools
- **Ansible**: `~/.local/share/ansible/local.yml` (`.an`)
  - Uses role-based structure with core/auth roles
  - Tasks organized in `tasks/` directory by category (system/, install/, build/)
  - Variables for environment paths (WORK, PROJECTS, CODE, etc.)
- **Scripts**: `$SCRIPTS` - Custom scripts directory
- **Automation**: `$AUTOMATION` - Automation scripts
- **Utilities**: `$UTILITIES` - Utility programs

## Build Environment
- **Builds**: `$BUILDS` - Build outputs
- **Suckless**: `$SUCKLESS` - Suckless tools (dwm, st)
- **QMK**: `~/qmk_firmware` - Keyboard firmware

## Commands to Remember
- **Lint/Typecheck**: Check project for standard commands (npm run lint, ruff, etc.)
- **Auto-suspend**: Managed via systemd service `xautolock@kanon.service`
- **Stow**: Use `cd ~/.dotfiles && stow <folder>` to manage symlinks
- **Shortcuts**: File shortcuts in `~/.config/shortcuts/sf`, dir shortcuts in `sd`
- **Personal Push**: `personal-push-all` or `dgpA` - pushes changes from main folders (notes|wiki|dotfiles|ansible)

## Work Environment
- **Work Directory**: `$WORK` - Work-related projects
- **Work Aliases**: `~/.config/.aliases_work` (`.aw`)
- **Work Startup**: `~/.config/.startup_work` (`.sw`)

## Skills
- **Default location**: `$HOME/.claude/skills/<skill-name>/SKILL.md` — use this for all skills unless the skill is tightly coupled to a specific project
- **Project-specific** (rare): `.claude/skills/<skill-name>/SKILL.md` inside the repo — only when the skill depends on files, tooling, or context that only makes sense within that one project

## Reference Files
Reference docs live under `~/.claude/files/` (dotfiles source: `~/.dotfiles/general/.claude/files/`). Read these before guessing or asking, when relevant:
- **`~/.claude/files/hook-debugging.md`** — debugging Claude Code hooks. Read when a hook isn't behaving (silent exits, matcher confusion, `set -e` aborts, manual test recipe, output JSON shape).

## Commits & PRs
- **NEVER** mention Claude or add `Co-Authored-By: Claude` in commit messages or PR descriptions


## Notes
- Uses environment variables for key paths (check shortcuts in `~/.config/shortcuts/`)
- Dotfiles are symlinked from `~/.dotfiles/` using GNU Stow
- Prefers systemd services over autostart desktop files
- System uses `xautolock` (not systemd-logind) for user-input-only idle detection
- **IMPORTANT**: Do not touch work-related files/directories unless explicitly requested
- **CRITICAL**: when I tell you to save the changes in my dotfiles, I mean these folders, and
    to use the personal-push-all command
  - `~/.dotfiles/` (dotfiles)
  - `~/notes/` (personal notes)
  - `~/wiki/` (personal wiki)
  - `~/.local/share/ansible/` (ansible configs)
  - This command commits AND pushes changes from all personal folders
