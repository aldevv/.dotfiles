if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then . $HOME/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer

if command -v pmy &>/dev/null; then
    eval "$(pmy init)"
fi


if [[ -d $HOME/.local/share/fnm ]]; then
    export PATH=$HOME/.local/share/fnm:$PATH
    eval "`fnm env`"
fi


if [[ -f  "$CARGO_HOME/env" ]]; then 
    CARGO_HOME=${CARGO_HOME:-$HOME/.cargo}
    . "$CARGO_HOME/env"
fi

[[ -f "$HOME/.ghcup/env" ]] && source "$HOME/.ghcup/env" # ghcup-env

load_direnv() {
    eval "$(direnv hook zsh)"
}
[[ -n "$(command -v direnv)" ]] &&  load_direnv


# NOTE: leave this last
load_pyenv() {
    eval "$(pyenv init -)"
    eval "$(pyenv init --path)"
    eval "$(pyenv virtualenv-init -)"
}
# NOTE: this might slow down tmux when opening a folder with .python-version file
[[ -f .python-version && -n "$(command -v pyenv)" ]] && load_pyenv
