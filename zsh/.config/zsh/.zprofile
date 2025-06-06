#!/bin/zsh

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export EDITOR=nvim
export VISUAL=nvim
export LESS="-isSMRQJ"
# export LESS="-isSMRQJ -j.5" for middle screen when searching
export PAGER='less'
# export PAGER='bat'
export READER=zathura
# export MANPAGER="less"
# export MANPAGER="sh -c 'col -bx | bat -l man -p'"
# export MANPAGER="nvim -c ' set ft=man' -"
if [[ -n $(command -v st) ]]; then
    export TERMINAL=st
    export TERM=tmux-256color
fi 
export DEFAULT_DMENU_FONT="Cascadia:style=Italic"
export COLORTERM=truecolor
export BAT_PAGER='less -R'
export BAT_CONFIG_PATH="$XDG_CONFIG_HOME/bat/config"
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/rg/.ripgreprc"
export BROWSER=firefox
export WALL="$HOME/Pictures/Wallpapers/all_time"
export EXP="/opt/exploitdb/exploits"
export PROJECTS="$HOME/projects"
export WORK="$HOME/work"
export NOTES="$HOME/notes"
export ATOMIC="$HOME/notes/atomic"
export REPOS="$HOME/repos"
export LEARN="$HOME/learn"
export BOOKS="$HOME/books"
export VOLUMES="$HOME/volumes"
export CODE="$HOME/code"
export REMOTES="$HOME/remotes"
export BACKUPS="$HOME/.local/share/.backups"
export PROGRAMS="$HOME/programs"
export BUILDS="$HOME/.local/builds"
export SUCKLESS="$PROGRAMS/suckless"
export WIKI="$HOME/.local/share/wiki"
export DOTFILES="$HOME/.dotfiles"
export TRASH="$HOME/.local/share/Trash/files"
export PASSWORD_STORE_DIR="$HOME/.local/share/.pass"
export SECRETS_EXTENSION=".scr"
export NVIM_LOG_FILE="$HOME/.config/nvim/log/log"
export NVIM_LISTEN_ADDRESS=/tmp/nvimsocket
export NIXPKGS_ALLOW_UNFREE=1

export CDPATH="$PROGRAMS:$WORK:$REPOS:$REPOS/github.com/:$PROJECTS"

export SCRIPTS="$HOME/.local/share/scripts"
export SHARED="$SCRIPTS/shared"
export UTILITIES="$SCRIPTS/utilities"
export AUTOMATION="$SCRIPTS/automation"
export APPS="$SCRIPTS/apps"
export FILES="$SCRIPTS/files"

if [[ $OSTYPE !=  "darwin"* ]]; then
[[ -f $UTILITIES/linux/get_package_manager ]] \
    && export PKG=$($UTILITIES/linux/get_package_manager) \
    && export PKG_INSTALL=$($UTILITIES/linux/get_package_manager "install")
fi

export PYENV_ROOT="$HOME/.local/share/.pyenv"
export WINEPREFIX="$HOME/.local/share/wine"
export SXHKD_SHELL="/bin/bash"
export PMY_RULE_PATH="$XDG_CONFIG_HOME/pmy/"
export UNCRUSTIFY_CONFIG="$XDG_CONFIG_HOME/uncristify/config.cfg"

#qt5ct colorscheme
# export GTK_THEME='Nordic-darker'
# export QT_QPA_PLATFORMTHEME="qt5ct"

#======================================
# WORK
#======================================
export GOPATH=$HOME/.local/share/go
# export GEM_HOME=$HOME/.local/share/gem
# export PIPENV_VENV_IN_PROJECT="enabled"


export PATH="$CARGO_HOME/bin:$JAVA_HOME/bin:$GOPATH/bin:$PATH"
export PATH="$PYENV_ROOT/bin:${PATH}"
#=============================================================================

#====
#WINE
#====
# export DISPLAY=:0

#====
#FZF
#====
exp_if_cmd(){
    local cmd="$1"
    shift
    [ -n $(command -v "$cmd") ] \
        && export "$*" && return 0
    return 1
}
export FZF_CTRL_R_OPTS='--no-preview'
export FZF_COMPLETION_TRIGGER='º'

export RG_DEFAULT_FOR_FZF="rg --files --hidden --no-heading --smart-case --follow --"
export FD_DEFAULT_FOR_FZF="fd --follow --hidden"

exp_if_cmd "fd" FZF_DEFAULT_COMMAND=$FD_DEFAULT_FOR_FZF
[ "$?" = 1 ] && exp_if_cmd "rg" FZF_DEFAULT_COMMAND=$RG_DEFAULT_FOR_FZF

# export FZF_DEFAULT_OPTS='--bind=ctrl-e:up,ctrl-n:down'
FZF_BINDS="alt-g:first,alt-G:last,alt-E:preview-up,alt-N:preview-down,alt-e:up,alt-n:down,+:toggle-preview,ctrl-a:select-all+accept"
FZF_PREV="'[[ \$(file --mime {}) =~ binary ]] && echo {} is a binary file || (bat --style=numbers --color=always {} || cat {}) > /dev/null | head -199'"
export FZF_DEFAULT_OPTS="
--ansi --height=75% --layout=reverse --multi 
--bind "$FZF_BINDS"
--preview "$FZF_PREV" 
--preview-window 50%:wrap
"

# to unhide preview window, change to --preview-window=right:hidden:wrap"
# for prompt at the bottom, change layout to "default"


# alt r -> cd into selected dir
# ctrl t -> paste selected into command line(multiple)
# ctrl r -> paste command from history
#colors less
export  LESS_TERMCAP_mb=$'\e[1;31m'
export  LESS_TERMCAP_md=$'\e[1;31m'
export  LESS_TERMCAP_me=$'\e[0m'
export  LESS_TERMCAP_se=$'\e[0m'
# export  LESS_TERMCAP_so=$'\e[1;44;33m' # better no color
export  LESS_TERMCAP_ue=$'\e[0m'
export  LESS_TERMCAP_us=$'\e[1;32m'

#=======================================
# LIBS
#=======================================
# export LD_LIBRARY_PATH=.:/usr/local/lib
# export MLIBS="$FILES/mlibs"
# export C_INCLUDE_PATH=.:$MLIBS

#=================================================

# already sourced from xprofile
[[ -d "$UTILITIES" ]] && export PATH="$(find -L $UTILITIES -type d | tr '\n' ':')$PATH"
[[ -d "$AUTOMATION" ]] && export PATH="$(find -L $AUTOMATION -type d | tr '\n' ':')$PATH"
[[ -d "$APPS" ]] && export PATH="$(find -L $APPS -type d | tr '\n' ':')$PATH"
[[ -d "$SHARED" ]] && export PATH="$(find -L $SHARED -type d | tr '\n' ':')$PATH"
[[ -d "$SCRIPTS/work" ]] && export PATH="$(find -L $SCRIPTS/work -type d | tr '\n' ':')$PATH"

export AWS_PAGER=""

# add flutter
[[ -d "$PROGRAMS/flutter" ]] && export PATH="$(find $PROGRAMS/flutter $PROGRAMS/android-studio -maxdepth 1 -type d -iname 'bin' | tr '\n' ':')$PATH"

dbcli() {
    docker exec -it compose_py3_db_1 dbcli migrate --service-name newgaldb.devgp --migrations-version $1
}
