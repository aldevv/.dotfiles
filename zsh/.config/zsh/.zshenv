
# >>> pnpm bin (added by copilot) >>>
# Ensure pnpm's global bin is on PATH for interactive and login shells
if [ -d "$HOME/.local/share/pnpm/bin" ]; then
  case ":$PATH:" in
    *":$HOME/.local/share/pnpm/bin:") ;;
    *) export PATH="$HOME/.local/share/pnpm/bin:$PATH";;
  esac
fi
# <<< pnpm bin (added by copilot) <<<
. "/home/kanon/.local/share/bob/env/env.sh"
