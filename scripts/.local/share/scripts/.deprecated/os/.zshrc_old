setopt KSH_GLOB
# only source if you dont login from a terminal
# source ~/.zprofile
#COLEMAK DOTFILES
#!  https://rgoswami.me/posts/colemak-dots-refactor/
#
#autoload -U colors && colors   # Load colors
#PS1="%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[blue]%}%M %{$fg[magenta]%}%~%{$fg[red]%}]%{$reset_color%}$%b "
export SXHKD_SHELL="/usr/bin/sh"
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# the cursor is after the path, which is a pain
# ZSH_THEME="af-magic"
#ZSH_THEME="agnoster"
# ZSH_THEME="amuse"
# ZSH_THEME="daivasmara"
[[ $(whoami) == root ]] && ZSH_THEME="robbyrussell"  || ZSH_THEME="aussiegeek"


# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )


#functions
#to open man in vim
# function manv() {
#     for arg in "$@"; do
        # nvim -c 'execute "normal! :let no_man_maps = 1\<cr>:runtime ftplugin/man.vim\<cr>:Man '"${arg}"'\<cr>:wincmd o\<cr>"'
    # done
# }


# Change cursor shape for different vi modes.
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
     [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'
  elif [[ ${KEYMAP} == main ]] ||
       [[ ${KEYMAP} == viins ]] ||
       [[ ${KEYMAP} = '' ]] ||
       [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select
zle-line-init() {
    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
    echo -ne "\e[5 q"
}
zle -N zle-line-init
echo -ne '\e[5 q' # Use beam shape cursor on startup.
preexec() { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt.



# Add wisely, as too many plugins slow down shell startup.
# # in archlinux put the archlinux plugin!

# docker adds completion for docker commands, same docker compose
plugins=(docker)
# z is a command that takes you to the most probable folder
export HISTFILE="$XDG_CONFIG_HOME/.zsh_history"
source $ZSH/oh-my-zsh.sh
. $HOME/.config/zshPlugAlias
#https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/vscode
#
#==============
# Keybindings

# so you can use backspace after esc
# Enable Ctrl-x-e to edit command line
autoload -U edit-command-line
# Vi style:
zle -N edit-command-line
bindkey -v

#to fix the backspace problem
bindkey "^?" backward-delete-char
#to fix the backspace shift problem
bindkey "^[[127;2u" backward-delete-char

#to fix the space shift problem, inserts a space
bindkey -s "^[[32;2u" " "
bindkey -s "^[i" "^[OC"
bindkey -s "^[h" "^[OD"

# to delete word using ctrl and backspace
bindkey "^[[127;5u" backward-delete-word

# Colemak.
bindkey -M vicmd "h" backward-char
bindkey -M vicmd "n" down-line-or-history
bindkey -M vicmd "e" up-line-or-history
bindkey -M vicmd "i" forward-char
bindkey -M vicmd "l" vi-insert
bindkey -M vicmd "L" vi-insert-bol
bindkey -M vicmd "k" vi-repeat-search
bindkey -M vicmd "K" vi-rev-repeat-search
bindkey -M vicmd "0" beginning-of-line
bindkey -M vicmd "$" end-of-line
bindkey -M vicmd "j" vi-forward-word-end
bindkey -M vicmd "J" vi-forward-blank-word-end
bindkey -M vicmd v edit-command-line
# Sane Undo, Redo, Backspace, Delete.
bindkey -M vicmd "u" undo
bindkey -M vicmd "U" redo
bindkey -M vicmd "^?" backward-delete-char
bindkey -M vicmd "^[[3~" delete-char

# Use vim keys in tab complete menu:
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'e' vi-up-line-or-history
bindkey -M menuselect 'i' vi-forward-char
bindkey -M menuselect 'n' vi-down-line-or-history
bindkey -v '^?' backward-delete-char

# export MANPATH="/usr/local/man:$MANPATH"

#
# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"
#
# less keybindings
lesskey $HOME/.config/colemak-less

source ~/.aliases
# unsetopt completealiases
nvml() {
. "$NVM_DIR/nvm.sh"
}
# MAKES IT SLOW

#completion and highlighting
# source ~/.config/completion_fzf.zsh
#
# fpath=($PROGRAMS/zsh-completions/src $fpath)
# autoload -U compinit && compinit
[[ -d $PROGRAMS/zsh-syntax-highlighting ]] && source $PROGRAMS/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
doge() {
  _fzf_complete --multi --reverse --prompt="doge> " -- "$@" < <(
    echo very
    echo wow
    echo such
    echo doge
  )
}

# rga-fzf() {
# 	RG_PREFIX="rga --files-with-matches"
# 	local file
# 	file="$(
# 		FZF_DEFAULT_COMMAND="$RG_PREFIX '$1'" \
# 			fzf --sort --preview="[[ ! -z {} ]] && rga --pretty --context 5 {q} {}" \
# 				--phony -q "$1" \
# 				--bind "change:reload:$RG_PREFIX {q}" \
# 				--preview-window="70%:wrap"
# 	)" &&
# 	echo "opening $file" &&
# 	xdg-open "$file"
# }

# ripgrep-all with preview
# check bat-extras : https://github.com/eth-p/bat-extras
# .r() {
# 	RG_PREFIX="rga --files-with-matches"
	# fzf --sort --preview="[[ ! -z {} ]] && rga --pretty --context 5 {q} {}" \
	# local file
	# file="$(
		# FZF_DEFAULT_COMMAND="$RG_PREFIX '$1'" \
              # fzf --sort --preview="[[ ! -z {} ]] && bat --color always {} | rg --pretty --context 5 {q} 2>/dev/null" \
				# --phony -q "$1" \
				# --bind "change:reload:$RG_PREFIX {q}" \
				# --preview-window="70%:wrap"
	# )" &&
	# echo "opening $file" &&
	# xdg-open "$file"
# }
[[ -d "/usr/local/bin" ]] && export PATH="/usr/local/bin:$PATH"

bindkey -s "^n" "stn^M"
bindkey -s 'p' 'file=$(fd . -t f -I -H | fzf -d / --with-nth -5,-4,-3,-2,-1); [ -n "$file" ] && nvim "$file"^M'
bindkey -s 'w' 'file=$(fd . -t f -I -H "$WORK" | fzf -d / --with-nth -3,-2,-1); [ -n "$file" ] && nvim "$file"^M'
bindkey -s 'c' 'file=$(fd . -t f -I -H "$CLASS" | fzf -d / --with-nth -3,-2,-1); [ -n "$file" ] && nvim "$file"^M'
bindkey -s 'M' 'file=$(fd . -t f -I -H "$MASTER" | fzf -d / --with-nth -3,-2,-1); [ -n "$file" ] && nvim "$file"^M'
bindkey -s 's' 'file=$(fd . -t f -I -H "$SCRIPTS" | fzf -d / --with-nth -3,-2,-1); [ -n "$file" ] && nvim "$file"^M'
bindkey -s 'P' 'file=$(fd . -t f -I -H "$PROJECTS" | fzf -d / --with-nth -3,-2,-1); [ -n "$file" ] && nvim "$file"^M'
bindkey -s 'l' 'file=$(fd . -t f -I -H "$LEARN" | fzf -d / --with-nth -3,-2,-1); [ -n "$file" ] && nvim "$file"^M'
bindkey -s 'o' '!\$^M'
bindkey -s 'O' '!*^M'
bindkey -s 't' '**	'
# tested, this shows stderr correctly on new terminal window
bindkey -s '.' 'setsid st &>/dev/null^M'
bindkey -s 'r' 'setsid st ranger &>/dev/null^M'
_fzf_compgen_path() {

  excluded=".git node_modules plugged .env __pycache__ .wine .npm .icons .vscode */nvm/backups .cache undodir __pycache__ **/node_modules/* env envs "
  fd --hidden --follow --exclude "$excluded" . "$1"
}
# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  excluded=".git node_modules plugged .env __pycache__ .wine .npm .icons .vscode */nvm/backups .cache undodir __pycache__ **/node_modules/* env envs "
  fd --type d --hidden --follow --exclude "$excluded" . "$1"
}
# export NVM_DIR="$HOME/.config/nvm"
[ -f "$HOME/.config/.fzf.zsh" ] && source "$HOME/.config/.fzf.zsh"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
#
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
