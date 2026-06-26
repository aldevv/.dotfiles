if [[ -n "$SSH_CONNECTION" ]]; then
    AUSSIEGEEK_HOST_COLOR="%F{12}"  # bright blue (SSH)
else
    AUSSIEGEEK_HOST_COLOR="%F{9}"   # bright red (local)
fi
PROMPT='%F{12}[ %F{11}%n%F{15}@${AUSSIEGEEK_HOST_COLOR}%m %F{15}%~$(git_prompt_info)%F{11}$(rvm_prompt_info)$(_hunk_pr_indicator)%F{12} ]%f
$ '
# git theming (raw bright-green escape so echo-based git_prompt_info works)
ZSH_THEME_GIT_PROMPT_PREFIX=$'\e[92m('
ZSH_THEME_GIT_PROMPT_SUFFIX=")"
ZSH_THEME_GIT_PROMPT_CLEAN="✓"
ZSH_THEME_GIT_PROMPT_DIRTY="✗"
