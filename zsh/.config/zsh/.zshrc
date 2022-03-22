#==============
# setopt KSH_GLOB
#==============
# enables: rm -- !(*.dmg|*.txt)
#-------------o---------------

#=====================
setopt GLOB_DOTS
setopt extended_glob
#=====================
# enables: rm -- ^*.dmg, rm -- ^*.(dmg|txt)
#-------------o---------------

# adds completion to alias arguments
setopt complete_aliases

# only source if you dont login from a terminal
# source ~/.zprofile
#COLEMAK DOTFILES
#!  https://rgoswami.me/posts/colemak-dots-refactor/
#
#autoload -U colors && colors   # Load colors
#PS1="%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[blue]%}%M %{$fg[magenta]%}%~%{$fg[red]%}]%{$reset_color%}$%b "

nomyzsh() {autoload -Uz compinit && compinit}
export SXHKD_SHELL="/usr/bin/sh"
[ -d "$HOME/.oh-my-zsh" ] &&
	export ZSH="$HOME/.oh-my-zsh" ||
	nomyzsh

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
#echo $RANDOM_THEME
#ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )
#ZSH_THEME="random"
#
# ZSH_THEME="af-magic"
#ZSH_THEME="agnoster"
# ZSH_THEME="amuse"
# ZSH_THEME="daivasmara"
[[ $(whoami) == root ]] &&
	ZSH_THEME="robbyrussell" ||
	ZSH_THEME="aussiegeek_edited"

# Preferred editor for local and remote sessions
[[ -n $SSH_CONNECTION ]] &&
	color echo "came to visit? enjoy your stay"

#==========
#FUNCTIONS
#==========
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
echo -ne '\e[5 q'                # Use beam shape cursor on startup.
preexec() { echo -ne '\e[5 q'; } # Use beam shape cursor for each new prompt.

# # in archlinux put the archlinux plugin!
# docker adds completion for docker commands, same docker compose
##set history size
export HISTSIZE=25000
export HISTFILE="$HOME/.cache/zsh/.zsh_history"
# plugins=(copybuffer dirhistory jsontools)
plugins=(
	docker
	docker-compose
    zsh-autosuggestions
    zsh-syntax-highlighting
)
. $ZSH/oh-my-zsh.sh

#==============
# KEYBINDINGS
#==============
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

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# this makes autocompletion work on aliased programs
unsetopt completealiases


# comment this for faster loads

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

# PATH
[[ -d "/usr/local/bin" ]] &&
	export PATH="/usr/local/bin:$PATH"


bindkey -s "^n" "stn^M"
bindkey -s 'f' '$UTILITIES/tmux/tmux-sessionizer^M' # projects and work
bindkey -s 'p' 'vf ^M'
bindkey -s 'P' '. cf ^M'
bindkey -s 'a' 'vf $HOME/.config ^M'
bindkey -s 'A' '. cf $HOME/.config ^M'
bindkey -s 'z' 'vf  "$LEARN"^M'
bindkey -s 'z' '. cf  "$LEARN"^M'
bindkey -s 'm' 'vf  "$SCRIPTS"^M'
bindkey -s 'M' '. cf  "$SCRIPTS"^M'
bindkey -s 'o' '!\$^M'
bindkey -s 'O' '!*^M'
bindkey -s 't' '**	'
# tested, this shows stderr correctly on new terminal window
bindkey -s '.' 'setsid st &>/dev/null^M'
bindkey -s 'r' 'setsid st ranger &>/dev/null^M'

_fzf_compgen_path() {
	fd --hidden --follow . "$1"
}
# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
	fd --type d --hidden --follow . "$1"
}

. /usr/share/fzf/key-bindings.zsh
. /usr/share/fzf/completion.zsh

# ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE
#ZSH_AUTOSUGGEST_STRATEGY
#
# [[ -d $PROGRAMS/zsh-plugins/zsh-syntax-highlighting ]] &&
# 	. $PROGRAMS/zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# [[ -d $PROGRAMS/zsh-plugins/zsh-autosuggestions ]] &&
# 	. $PROGRAMS/zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh

# autosuggestions keybindings
# autosuggest-accept: Accepts the current suggestion.
# autosuggest-execute: Accepts and executes the current suggestion.
# autosuggest-clear: Clears the current suggestion.
# autosuggest-fetch: Fetches a suggestion (works even when suggestions are disabled).
# autosuggest-disable: Disables suggestions.
# autosuggest-enable: Re-enables suggestions.
# autosuggest-toggle: Toggles between enabled/disabled suggestions.

bindkey "^ " autosuggest-execute
# bindkey "^" autosuggest-toggle
#TODO find alternative to lesskey (deprecated)
# lesskey $HOME/.config/colemak-less
# aliases
alias src_=". $ZDOTDIR/.zshrc"
. $ZDOTDIR/.aliases
. $ZDOTDIR/.auto_aliases

# fnm
nvml() {
	. "$NVM_DIR/nvm.sh"
}
nvmL() {
	export NVM_DIR="$HOME/.config/nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
	[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion
}

fnml() {
    export PATH=/home/kanon/.fnm:$PATH
    eval "`fnm env`"
}
# install https://github.com/relastle/pmy
# config
#https://github.com/relastle/pmy/wiki/Gallery#git-cherry-pickcp
eval "$(pmy init)"

