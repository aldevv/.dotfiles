#!/usr/bin/env bash
# PreToolUse hook for Bash: blocks a GitHub review (re-)request aimed at a
# reviewer whose latest review on that PR is APPROVED. Re-requesting an
# approver clears their approval from the PR's review state.
# Covers `gh api .../pulls/<n>/requested_reviewers` and `gh pr edit --add-reviewer`.
# Fails open (allows) when the PR or its reviews can't be resolved.
set -uo pipefail

input=$(cat)
cmd=$(jq -r '.tool_input.command // ""' <<<"$input")

case "$cmd" in
  *requested_reviewers* | *--add-reviewer*) ;;
  *) exit 0 ;;
esac

repo="" num="" logins=()

if [[ "$cmd" =~ repos/([^/[:space:]]+)/([^/[:space:]]+)/pulls/([0-9]+)/requested_reviewers ]]; then
  # A DELETE on requested_reviewers removes a request; nothing to guard.
  if grep -qE -- '(-X|--method)[[:space:]]*DELETE' <<<"$cmd"; then exit 0; fi
  repo="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
  num="${BASH_REMATCH[3]}"
  while read -r l; do [[ -n "$l" ]] && logins+=("$l"); done < <(
    grep -oE 'reviewers\[\]=[^"'"'"'[:space:]]+' <<<"$cmd" | cut -d= -f2)
elif [[ "$cmd" =~ gh[[:space:]]+pr[[:space:]]+edit[[:space:]]+([^[:space:]]+) ]]; then
  target="${BASH_REMATCH[1]}"
  if [[ "$target" =~ github\.com/([^/]+/[^/]+)/pull/([0-9]+) ]]; then
    repo="${BASH_REMATCH[1]}" num="${BASH_REMATCH[2]}"
  else
    num="$target"
    if [[ "$cmd" =~ (-R|--repo)[[:space:]=]+([^[:space:]]+) ]]; then
      repo="${BASH_REMATCH[2]}"
    else
      dir=$(jq -r '.cwd // ""' <<<"$input")
      if [[ "$cmd" =~ (^|[[:space:];&|])cd[[:space:]]+([^[:space:];&|]+) ]]; then
        d="${BASH_REMATCH[2]}"; d="${d/#\~/$HOME}"; [[ -d "$d" ]] && dir="$d"
      fi
      repo=$(cd "${dir:-.}" 2>/dev/null && gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null)
    fi
  fi
  while read -r l; do [[ -n "$l" ]] && logins+=("$l"); done < <(
    grep -oE -- '--add-reviewer[[:space:]=]+[^[:space:]]+' <<<"$cmd" |
      sed -E 's/--add-reviewer[[:space:]=]+//; s/["'"'"']//g' | tr ',' '\n')
fi

[[ -n "$repo" && "$num" =~ ^[0-9]+$ && ${#logins[@]} -gt 0 ]] || exit 0

# Latest decisive review per user; COMMENTED after an approval doesn't revoke it.
approved=$(gh api "repos/$repo/pulls/$num/reviews" --paginate 2>/dev/null | jq -rs '
  add // [] | map(select(.state == "APPROVED" or .state == "CHANGES_REQUESTED" or .state == "DISMISSED"))
  | group_by(.user.login) | map(last) | map(select(.state == "APPROVED") | .user.login) | .[]') || exit 0

blocked=()
for l in "${logins[@]}"; do
  [[ "$l" == */* ]] && continue   # team reviewer, no per-user approval
  grep -qxiF -- "$l" <<<"$approved" && blocked+=("$l")
done
[[ ${#blocked[@]} -eq 0 ]] && exit 0

reason="Blocked: ${blocked[*]} already approved $repo#$num. Re-requesting review from an approver clears that approval. Drop them from the request (keep any other reviewers) and tell the operator they were skipped."
jq -nc --arg r "$reason" \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
