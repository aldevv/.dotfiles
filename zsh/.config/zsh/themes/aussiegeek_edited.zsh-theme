if [[ -n "$SSH_CONNECTION" ]]; then
    AUSSIEGEEK_HOST_COLOR="$fg[blue]"
else
    AUSSIEGEEK_HOST_COLOR="$fg[red]"
fi
PROMPT='$fg_bold[blue][ $fg[yellow]%n$fg[white]@${AUSSIEGEEK_HOST_COLOR}%m $fg[white]%~$(git_prompt_info)$fg[yellow]$(rvm_prompt_info)$(_hunk_pr_indicator)$fg_bold[blue] ]$reset_color
$ '
# git theming
ZSH_THEME_GIT_PROMPT_PREFIX="$fg_bold[green]("
ZSH_THEME_GIT_PROMPT_SUFFIX=")"
ZSH_THEME_GIT_PROMPT_CLEAN="✓"
ZSH_THEME_GIT_PROMPT_DIRTY="✗"
