if [[ $OSTYPE == 'darwin'* ]]; then
  export PATH="/opt/homebrew/bin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:$PATH"
fi

load_nix() {
  if [[ ! -e $HOME/.nix-profile/etc/profile.d/nix.sh ]]; then 
    return
  fi
  . $HOME/.nix-profile/etc/profile.d/nix.sh
}
load_nix

load_cargo() { 
  if [[ ! -n $CARGO_HOME ]] || [[ ! -f  "$CARGO_HOME/env" ]]; then 
    return
  fi

  CARGO_HOME=${CARGO_HOME:-$HOME/.cargo}
  . "$CARGO_HOME/env"
}
load_cargo

load_ghcup() { 
  if [[ ! -f "$HOME/.ghcup/env" ]]; then 
    return
  fi
  . "$HOME/.ghcup/env" # ghcup-env
}
load_ghcup


load_direnv() {
  if ! command -v direnv &>/dev/null; then
    return
  fi 
  eval "$(direnv hook zsh)"
}
load_direnv

load_pyenv() {
  if [[ ! -f .python-version ]] || ! command -v pyenv &>/dev/null; then
    return
  fi
  eval "$(pyenv init -)"
  eval "$(pyenv init --path)"
  eval "$(pyenv virtualenv-init -)"
}
load_pyenv

load_brew() {
  if [[ ! -d "/home/linuxbrew/.linuxbrew/bin" ]]; then
    return
  fi
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
}
load_brew

load_fly() { 
  if [[ ! -d $HOME/.fly  ]] || ! command -v fly &>/dev/null; then
    return
  fi
  export FLYCTL_INSTALL="/home/kanon/.fly"
  export PATH="$FLYCTL_INSTALL/bin:$PATH"
}
load_fly 

load_fnm() { 
  if [[ ! -d $HOME/.local/share/fnm ]]; then
    return
  fi
  export PATH=$HOME/.local/share/fnm:$PATH
  eval "$(fnm env --use-on-cd --shell zsh)" 2>/dev/null
}
load_fnm

load_ng() { 
  if ! command -v ng &>/dev/null; then
    return
  fi
  source <(ng completion script)
}
load_ng

load_bun() {
  if [[ ! -d "$HOME/.bun" ]]; then
    return
  fi
  source "$HOME/.bun/_bun"
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
}
load_bun


misc() { 
  [[ -f "$HOME/.turso/turso" ]] && export PATH="$HOME/.turso:$PATH"

  [[ -d "$HOME/.pulumi/bin" ]] && export PATH="$HOME/.pulumi/bin:$PATH"

  [[ -d "$HOME/.tfenv/bin" ]] && export PATH="$HOME/.tfenv/bin:$PATH"
}
misc

export PATH="$HOME/.local/share/bob/nvim-bin:$PATH"
export PATH="/usr/local/go/bin:$PATH"
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
