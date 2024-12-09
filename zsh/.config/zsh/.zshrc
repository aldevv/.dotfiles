# Per-command profiling:
# zmodload zsh/datetime
# setopt promptsubst
# PS4='+$EPOCHREALTIME %N:%i> '
# exec 3>&2 2> startlog.$$
# setopt xtrace prompt_subst

# work
[[ -f ~/.config/.aliases_work ]] && . ~/.config/.aliases_work

#==============
# setopt KSH_GLOB
#==============
# enables: rm -- !(*.dmg|*.txt)
#-------------o---------------

#=====================
setopt extended_glob
#=====================
# enables: rm -- ^*.dmg, rm -- ^*.(dmg|txt)
#-------------o---------------

# adds completion to alias arguments
unsetopt complete_aliases

# only source if you dont login from a terminal
# source ~/.zprofile
#COLEMAK DOTFILES
#!  https://rgoswami.me/posts/colemak-dots-refactor/
#
#autoload -U colors && colors   # Load colors
#PS1="%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[blue]%}%M %{$fg[magenta]%}%~%{$fg[red]%}]%{$reset_color%}$%b "

if [[ -d "$HOME/.oh-my-zsh" ]];then
	export ZSH="$HOME/.oh-my-zsh" ||
    if [[ -n "$(command -v compinit)" ]];then
        autoload -Uz compinit && compinit
    fi
fi


# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
#echo $RANDOM_THEME
#ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )
#ZSH_THEME="random"
#
# ZSH_THEME="af-magic"
#ZSH_THEME="agnoster"
# ZSH_THEME="amuse"
# ZSH_THEME="daivasmara"
if [[ $(whoami) != root ]]; then
	ZSH_THEME="aussiegeek_edited"
	# ZSH_THEME="amuse"
else
	ZSH_THEME="afowler"
fi

# Preferred editor for local and remote sessions
[[ -n $SSH_CONNECTION ]] && color echo "came to visit? enjoy your stay"

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
[ ! -d "$HOME/.cache/zsh" ] &&\
    mkdir -p "$HOME/.cache/zsh"
# plugins=(copybuffer dirhistory jsontools)
plugins=(
	git
  zsh-autosuggestions
  zsh-syntax-highlighting
  fzf-zsh-plugin # to update version, delete the ~/.fzf folder
)

# if [[ "$(hostname)" != "hagane" ]]; then
#     plugins+=('kube-ps1')
# fi
# if [[ "$(hostname)" != "hagane" ]]; then
#     plugins+=('kube-ps1')
# fi
. "$ZSH/oh-my-zsh.sh"


if grep -q "kube-ps1" <<<"$plugins"; then
  KUBE_PS1_SYMBOL_PADDING=true
  PROMPT='$(kube_ps1) '$PROMPT
fi

#==============
# KEYBINDINGS
#==============
# KEYTIMEOUT makes entering normal mode instant
KEYTIMEOUT=1 
# so you can use backspace after esc
# Enable Ctrl-x-e to edit command line
# Vi style:
bindkey -v

[[ -f ~/.fzf/bin/fzf ]] && eval "$(fzf --zsh)"
# bindkey '^R' history-incremental-search-backward
# use this for patterns, globs etc
# bindkey '^R' history-incremental-pattern-search-backward

#to fix the backspace problem
bindkey "^?" backward-delete-char
#to fix the backspace shift problem
bindkey "^[[127;2u" backward-delete-char

#to fix the space shift problem, inserts a space
bindkey -s "^[[32;2u" " "
bindkey -s "^[i" "^[OC"
bindkey -s "^[h" "^[OD"
# Yank to the system clipboard
function vi-yank-xclip {
    zle vi-yank
   echo "$CUTBUFFER" | xclip -sel clipboard
}

zle -N vi-yank-xclip
bindkey -M vicmd 'y' vi-yank-xclip



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
bindkey '^[.' insert-last-word

bindkey -r  'lw' 
bindkey -r  'lW' 
bindkey -r  'la' 

bindkey -M viopp 'lw' select-in-word
bindkey -M viopp 'lW' select-in-blank-word
bindkey -M viopp 'la' select-in-shell-word

bindkey -M vicmd "v" visual-mode
bindkey -M vicmd "" edit-command-line

# insert mode
bindkey '^H' backward-kill-word

# in visual mode move right with i
bindkey -M visual "i" vi-forward-char
bindkey -M visual "l" vi-insert


# Compilation flags
# export ARCHFLAGS="-arch x86_64"

doge() {
	_fzf_complete --multi --reverse --prompt="doge> " -- "$@" < <(
		echo very
		echo wow
		echo such
		echo doge
	)
}

# control
bindkey -s "^n" "stn^M"
# alt
bindkey -s 'w' 'nw^M' # wiki
bindkey -s 'N' '$UTILITIES/grep/lgnotes^M' # projects and work
bindkey -s 'f' '$UTILITIES/tmux/nf^M' # projects and work
bindkey -s 'd' '$UTILITIES/tmux/nd^M' # start something new
bindkey -s 't' '$UTILITIES/tmux/nt^M' # notes
bindkey -s 'l' '$UTILITIES/tmux/nt learn^M' # notes
bindkey -s 'q' '$UTILITIES/tmux/ant^M' # notes
bindkey -s 'T' '$UTILITIES/tmux/ant todo^M' # notes
bindkey -s 'I' '$UTILITIES/tmux/ant ideas^M' # notes
bindkey -s 'g' '$UTILITIES/tmux/nf ~/repos 3^M' # projects and work
# bindkey -s 'p' 'vf ^M'
bindkey -s '^p' 'vf ^M'
bindkey -s '^g' 'vfg ^M'
bindkey -s 'D' 'vf $HOME/.config ^M'
# bindkey -s 'z' 'vf  "$LEARN"^M'
# bindkey -s 'z' '. cf  "$LEARN"^M'
bindkey -s 'm' 'scripts^M'
bindkey -s 'M' 'runscript^M'
# bindkey -s 'M' '. cf  "$SCRIPTS"^M'
bindkey -s 'o' '**	'
bindkey -s 'j' 'gwts^M' # projects and work
# tested, this shows stderr correctly on new terminal window

# this is used for previous command
# bindkey -s '.' 'setsid st &>/dev/null^M'
bindkey -s 'r' 'live_grep^M'
bindkey -s 'R' 'setsid st ranger &>/dev/null^M'

_fzf_compgen_path() {
	fd --hidden --follow . "$1"
}
# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
	fd --type d --hidden --follow . "$1"
}

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


# -- less 
# New less versions will read this file directly
export LESSKEYIN="$HOME/.config/colemak-less"

# Only run lesskey if less version is older than v582
#less_ver=$(less --version | awk '{print $2;exit}')
#autoload -Uz is-at-least
#if ! is-at-least 582 $less_ver; then
#  # Old less versions will read this transformed file
#  lesskey $LESSKEYIN
#fi
#unset less_ver


# install https://github.com/relastle/pmy
# config
#https://github.com/relastle/pmy/wiki/Gallery#git-cherry-pickcp

# shellcheck source=/dev/null
[[ -f "$ZDOTDIR/.aliases" ]] && . "$ZDOTDIR/.aliases" # old aliases
[[ -n "$ZDOTDIR" ]] && fpath=($ZDOTDIR/completions $fpath)  

# shellcheck source=/dev/null
[[ -f ~/.config/.aliases ]] && . ~/.config/.aliases # new aliases
[[ -f "$ZDOTDIR/.auto_aliases" ]] && . $ZDOTDIR/.auto_aliases
[[ -f ~/.opam/ ]] && eval $(opam env)


# put settings here, since oh-my-zsh sets it's own settings

setopt EXTENDED_HISTORY
setopt INC_APPEND_HISTORY_TIME  # Write to the history file immediately, not when the shell exits.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
export HISTFILE="$HOME/.cache/zsh/.zsh_history"
export HISTSIZE=500000
export SAVEHIST=$HISTSIZE
setopt appendhistory
setopt INC_APPEND_HISTORY  
setopt SHARE_HISTORY

#
# End profiling (uncomment when necessary)
#

# Per-command profiling:

# unsetopt xtrace
# exec 2>&3 3>&-

if command -v aws_completer &>/dev/null; then
    autoload bashcompinit && bashcompinit
    complete -C '/usr/local/bin/aws_completer' aws
fi
#
# source $HOME/programs/forgit/forgit.plugin.zsh
