export NOCOC=true
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export UNCRUSTIFY_CONFIG="$XDG_CONFIG_HOME/uncristify/config.cfg"
export EDITOR=nvim
export VISUAL=nvim
# export LESS="-isSMRQJ -j.5" for middle screen when searching
export LESS="-isSMRQJ"
# export PAGER='bat'
export PAGER='less'
export READER=zathura
# export MANPAGER="less"
# export MANPAGER="sh -c 'col -bx | bat -l man -p'"
# export MANPAGER="nvim -c ' set ft=man' -"
export TERMINAL=st
export TERM=st
export DEFAULT_DMENU_FONT="Cascadia:style=Italic"
export WINEPREFIX="$HOME/.local/share/wine"
export COLORTERM=truecolor
# export BAT_PAGER='less -R'
export BAT_PAGER='less -R'
export BAT_CONFIG_PATH="$XDG_CONFIG_HOME/bat/config"
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/rg/.ripgreprc"
# you can source sxhkd & here if you login from console
export SXHKD_SHELL="/bin/zsh"
export PMY_RULE_PATH="$XDG_CONFIG_HOME/pmy/"
# export SI=https://meet.google.com/ixe-gxnu-ovp
export NVIM_LISTEN_ADDRESS=/tmp/nvimsocket
export BROWSER=firefox
export WALL="$HOME/Pictures/Wallpapers/all_time"
export EXP="/opt/exploitdb/exploits"
export WORD="/opt/wordlists"
export BOOKS="$HOME/Documents/Books"
export MASTER="$HOME/master"
export PROJECTS="$MASTER/projects"
export MAIN="$PROJECTS/main"
export MICRO="$PROJECTS/micro"
export WORK="$MASTER/work"
export CLASS="$MASTER/classes"
export LEARN="$MASTER/learn"
export VOLUMES="$MASTER/volumes"
export GAMES="$MASTER/games"
export PLAYGROUND="$MASTER/playground"
export REMOTES="$MASTER/remotes"
export BACKUPS="$HOME/.local/share/.backups"
export PROGRAMS="$HOME/.local/programs"
export SUCKLESS="$PROGRAMS/suckless"
export WIKI="$HOME/.local/share/wiki"
export TRASH="$HOME/.local/share/Trash/files"
export PASSWORD_STORE_DIR="$HOME/.local/share/.pass"
export SECRETS_EXTENSION=".scr"
export SECRETS_DIR=".local/share/.gitscr"
export NVIM_LOG_FILE="$HOME/.config/nvim/log/log"

export PYTHONPATH="$PYTHONPATH:$PROGRAMS/cpython/Tools/gdb:$PROGRAMS/cpython"

export SCRIPTS="$HOME/.local/share/scripts"
export SHARED="$SCRIPTS/shared"
export UTILITIES="$SCRIPTS/utilities"
export AUTOMATION="$SCRIPTS/automation"
export APPS="$SCRIPTS/apps"
export OS="$SCRIPTS/os/bootstrap"
export FILES="$SCRIPTS/files"

[[ -f $UTILITIES/linux/get_package_manager ]] \
    && export PKG=$($UTILITIES/linux/get_package_manager) \
    && export PKG_INSTALL=$($UTILITIES/linux/get_package_manager "install")


export PROXYCHAINS_CONF_FILE="$XDG_CONFIG_HOME/proxychains/proxychains.conf"

#qt5ct colorscheme
export GTK_THEME='Nordic-darker'
export QT_QPA_PLATFORMTHEME="qt5ct"
# export QT_STYLE_OVERRIDE=qt5ct-style
#breaks copyq
# export QT_QPA_PLATFORMTHEME="gtk2"
# export QT_PLUGIN_PATH=/usr/lib/qt5/plugins

# BETTER ADD SYMLINKS

# export PREFIX_DIR="$PROGRAMS/prefix-installs"
# if [[ -d $PREFIX_DIR ]]; then
#     for dir in "$PREFIX_DIR"/*; do
#         dir=${dir:A}
#         if [[ -d "$dir/bin" ]]; then
#             PATH="$dir/bin:$PATH"
#         fi
#         if [[ -d "$dir/share/man" ]]; then
#             MANPATH="$dir/share/man:$MANPATH"
#         fi
#         if [[ -d "$dir/lib" ]]; then
#             LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$dir/lib"
#         fi
#         if [[ -d "$dir/lib/pkgconfig" ]]; then
#             PKG_CONFIG_PATH="$dir/lib/pkgconfig:$PKG_CONFIG_PATH"
#         fi
#     done
# fi

# if [[ -d $PROGRAMS ]]; then
#     for dir in "$PROGRAMS"/*; do
#         if [[ -d "$dir/man" ]]; then
#             MANPATH="$dir/man:$MANPATH"
#         fi

#         if [[ -d "$dir/bin" ]]; then
#             PATH="$dir/bin:$PATH"
#         fi
#     done
# fi
# export PATH MANPATH LD_LIBRARY_PATH PKG_CONFIG_PATH

#and this is how I uninstall programs in the prefix-install directory :
#rm -rf ~/.user-prefixes/nvim

#======================================
# WORK
#======================================
#
# export PYTHONPATH="$WORK/PPE/tensorflow-api/models/research:$WORK/PPE/tensorflow-api/models/research/slim:$WORK/PPE/tensorflow-api/models:$PYTHONPATH"
#export PYTHONPATH="$WORK/PPE/workplace/train/images/models/research:$WORK/PPE/workplace/train/images/models/research/slim:$WORK/PPE/workplace/train/images/models:$PYTHONPATH"
#
#
# use node_module binaries
export PATH="$PATH:./node_modules/.bin"
nvm_path="$HOME/.config/nvm/versions/node"
# if [[ -d "$nvm_path" ]]; then
    # node=$(ls $nvm_path | sed -n -E '/v[0-9]+\.[0-9]+\.[0-9]+$/p' | sort -r  | sed '1q')
    # if [ ! -z "$node" ]; then
        # export NODE_PATH="$nvm_path/$node/bin"
    # else
        # export NODE_PATH=""
    # fi
    # export PATH="$PATH:$NODE_PATH"
# fi

export CABAL_CONFIG="$XDG_CONFIG_HOME/cabal/config"
export CABAL_DIR="$PROGRAMS/cabal"

export JDK_HOME="/usr/lib64/openjdk-11"
export JAVA_HOME="$JDK_HOME"
export PATH="$PATH:$JAVA_HOME/bin"

export CARGO_HOME="$HOME/.local/share/rust/cargo"
export RUSTUP_HOME="$HOME/.local/share/rust/rustup"

export GOPATH=$HOME/.local/share/go

export GEM_HOME=$HOME/.local/share/gem

export PYENV_ROOT="$HOME/.local/share/.pyenv"
export PIPENV_VENV_IN_PROJECT="enabled"


export PATH="$GOROOT/bin:$CARGO_HOME/bin:${PATH}:$JAVA_HOME/bin:$GOPATH/bin:$GEM_HOME/ruby/3.0.0/bin"
export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:${PATH}"
#=============================================================================

#====
#WINE
#====
export DISPLAY=:0

#====
#FZF
#====
export FZF_CTRL_R_OPTS='--no-preview'
export FZF_COMPLETION_TRIGGER='º'
export RG_IGNORE_FILE="$XDG_CONFIG_HOME/rg/.ignore"
export FD_IGNORE_FILE="$XDG_CONFIG_HOME/fd/.ignore"
export RG_DEFAULT_FOR_FZF="rg --files --hidden --no-heading --smart-case --follow --ignore-file $RG_IGNORE_FILE  --"
export FD_DEFAULT_FOR_FZF="fd --type f --follow -uuu --ignore-file $FD_IGNORE_FILE"
export FZF_DEFAULT_COMMAND=$FD_DEFAULT_FOR_FZF

# export FZF_DEFAULT_OPTS='--bind=ctrl-e:up,ctrl-n:down'
export FZF_DEFAULT_OPTS=" --height=75% --layout=reverse --multi --bind=ctrl-e:preview-up,ctrl-n:preview-down,alt-e:up,alt-n:down,+:toggle-preview,ctrl-a:select-all+accept --preview='[[ \$(file --mime {}) =~ binary ]] && echo {} is a binary file || (bat --style=numbers --color=always {} || cat {}) > /dev/null | head -200' --preview-window=50%:rounded:wrap"
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
export LD_LIBRARY_PATH=.:/usr/local/lib
export MLIBS="$FILES/mlibs"
export C_INCLUDE_PATH=.:$MLIBS
