if [[ -n "$SSH_CONNECTION" ]]; then
    AUSSIEGEEK_HOST_COLOR="%F{12}"  # bright blue (SSH)
else
    AUSSIEGEEK_HOST_COLOR="%F{9}"   # bright red (local)
fi
PROMPT='%F{12}[ %F{11}%n%F{15}@${AUSSIEGEEK_HOST_COLOR}%m %F{15}%~$(git_prompt_with_sync)%F{11}$(rvm_prompt_info)$(_hunk_pr_indicator)%F{12} ]%f
$ '
# git theming (raw bright-green escape so echo-based git_prompt_info works)
ZSH_THEME_GIT_PROMPT_PREFIX=$'\e[92m('
ZSH_THEME_GIT_PROMPT_SUFFIX=")"
ZSH_THEME_GIT_PROMPT_CLEAN="✓"
ZSH_THEME_GIT_PROMPT_DIRTY=$'\e[91m✗\e[92m'

git_prompt_with_sync() {
  local base
  base=$(_omz_git_prompt_info)
  [[ -z "$base" ]] && return
  local sync="" no_upstream=0
  local counts ahead behind
  if git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' &>/dev/null; then
    counts=$(git rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null)
    if [[ -n "$counts" ]]; then
      behind=${counts%%$'\t'*}
      ahead=${counts##*$'\t'}
      if (( ahead > 0 && behind > 0 )); then
        sync=$'\e[91m⇅'
      elif (( ahead > 0 )); then
        sync=$'\e[91m↑'"$ahead"
      elif (( behind > 0 )); then
        sync=$'\e[91m↓'"$behind"
      fi
    fi
  else
    no_upstream=1
    sync=$'\e[91m?'
  fi
  if (( no_upstream )); then
    base=${base/"${ZSH_THEME_GIT_PROMPT_CLEAN})"/)}
  fi
  if [[ -n "$sync" ]]; then
    printf '%s%s\e[92m)' "${base%)}" "$sync"
  else
    printf '%s' "$base"
  fi
}
