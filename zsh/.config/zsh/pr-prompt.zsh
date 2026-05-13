# Show your open PRs for the current repo on the prompt, comma-separated and
# clickable via OSC 8.
#
# Cache: ~/.cache/hunk/repo-prs.tsv
#   <repo-toplevel>\t<num>|<url>,<num>|<url>,...\t<timestamp>
#   second column is `-` when checked-and-empty (avoids re-hitting the API).
#
# Reads are sync (cheap awk lookup); refreshes happen in a detached
# background subshell so the prompt never blocks on gh/glab.

zmodload zsh/datetime 2>/dev/null
setopt prompt_subst

typeset -g _HUNK_PR_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/hunk/repo-prs.tsv"
typeset -g _HUNK_PR_TTL=120  # seconds before a row is considered stale

_hunk_pr_refresh() {
  local key="$1" toplevel="$2"
  local origin host prs
  origin=$(git -C "$toplevel" remote get-url origin 2>/dev/null) || return
  host=""
  if   [[ "$origin" =~ '^https?://([^/]+)/' ]]; then host="${match[1]}"
  elif [[ "$origin" =~ '^[^/:@]+@([^:]+):'  ]]; then host="${match[1]}"
  fi

  prs="-"
  case "$host" in
    *github*)
      if (( $+commands[gh] )) && (( $+commands[jq] )); then
        # Collect search authors: @me plus the owner of every non-origin remote
        # (so PRs opened from a personal fork show up even when gh is logged in
        # as a different identity). Dedupe with typeset -U.
        local -aU authors=("@me")
        local r ru owner
        for r in ${(f)"$(git -C "$toplevel" remote 2>/dev/null)"}; do
          [[ "$r" == "origin" ]] && continue
          ru=$(git -C "$toplevel" remote get-url "$r" 2>/dev/null) || continue
          owner=""
          if [[ "$ru" =~ '[:/]([A-Za-z0-9_.-]+)/[A-Za-z0-9_.-]+(\.git)?/?$' ]]; then
            owner="${match[1]}"
          fi
          [[ -n "$owner" ]] && authors+=("$owner")
        done

        local -a rows=()
        local a one
        for a in "${authors[@]}"; do
          one=$(cd "$toplevel" && gh pr list --author "$a" --state open \
                  --json number,url \
                  --jq '.[] | "\(.number)|\(.url)"' 2>/dev/null)
          [[ -n "$one" ]] && rows+=(${(f)one})
        done
        if (( ${#rows} > 0 )); then
          # Sort by PR number desc, dedupe (set -u on the number key).
          prs=$(printf '%s\n' "${rows[@]}" | sort -t'|' -k1,1nr -u | paste -sd, -)
        fi
      fi
      ;;
    *gitlab*)
      if (( $+commands[glab] )) && (( $+commands[jq] )); then
        prs=$(cd "$toplevel" && glab mr list --mine --output json 2>/dev/null \
              | jq -r '[.[] | "\(.iid)|\(.web_url)"] | join(",")' 2>/dev/null)
      fi
      ;;
    *) return ;;
  esac
  [[ -z "$prs" || "$prs" == "null" ]] && prs="-"

  mkdir -p "${_HUNK_PR_CACHE:h}"
  [[ -f "$_HUNK_PR_CACHE" ]] || : > "$_HUNK_PR_CACHE"
  local tmp="${_HUNK_PR_CACHE}.$$"
  awk -F'\t' -v k="$key" '$1!=k' "$_HUNK_PR_CACHE" > "$tmp" 2>/dev/null
  printf '%s\t%s\t%s\n' "$key" "$prs" "$EPOCHSECONDS" >> "$tmp"
  mv "$tmp" "$_HUNK_PR_CACHE"
}

_hunk_pr_indicator() {
  local toplevel line prs ts age key
  toplevel=$(git rev-parse --show-toplevel 2>/dev/null) || return
  [[ -n "$toplevel" ]] || return
  key="$toplevel"

  if [[ -f "$_HUNK_PR_CACHE" ]]; then
    line=$(awk -F'\t' -v k="$key" '$1==k {print; exit}' "$_HUNK_PR_CACHE" 2>/dev/null)
  fi
  if [[ -n "$line" ]]; then
    IFS=$'\t' read -r _ prs ts <<<"$line"
    age=$(( EPOCHSECONDS - ts ))
  else
    age=999999
  fi

  # Refresh in a detached subshell — never blocks the prompt.
  if (( age > _HUNK_PR_TTL )); then
    ( _hunk_pr_refresh "$key" "$toplevel" & ) >/dev/null 2>&1
  fi

  [[ -z "$prs" || "$prs" == "-" ]] && return

  # Build " PRs #N, #M, #K" with each number wrapped in an OSC 8 hyperlink.
  # %{...%} marks the escape bytes as zero-width so zsh doesn't miscount the
  # prompt width.
  local OSC_OPEN=$'\e]8;;' ST=$'\e\\'
  local pair num url parts=()
  for pair in ${(s:,:)prs}; do
    num="${pair%%|*}"
    url="${pair#*|}"
    if [[ -n "$url" && "$url" != "$num" ]]; then
      parts+=("%{${OSC_OPEN}${url}${ST}%}#${num}%{${OSC_OPEN}${ST}%}")
    else
      parts+=("#${num}")
    fi
  done

  local label="PRs"
  (( ${#parts} == 1 )) && label="PR"

  # Leading space so callers can splice $(_hunk_pr_indicator) inline without
  # emitting a stray space when the function has nothing to say. %B/%b is bold.
  print -rn -- " %B${label} ${(j:, :)parts}%b"
}
