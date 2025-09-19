# Claude Code Configuration

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

## Notes
- Uses environment variables for key paths (check shortcuts in `~/.config/shortcuts/`)
- Dotfiles are symlinked from `~/.dotfiles/` using GNU Stow
- Prefers systemd services over autostart desktop files
- System uses `xautolock` (not systemd-logind) for user-input-only idle detection
- **IMPORTANT**: Do not touch work-related files/directories unless explicitly requested
- **Auto-push**: Run `personal-push-all` after updating personal files (no secrets/sensitive data)