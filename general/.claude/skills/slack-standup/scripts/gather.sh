#!/usr/bin/env bash
# Print what the operator did on GitHub on one day: PRs opened, commits
# pushed, reviews and comments left. Read-only.
# Usage: gather.sh [YYYY-MM-DD] [owner]   (defaults: today, every owner;
# STANDUP_GH_OWNER sets a default owner)
set -euo pipefail
DAY="${1:-$(date +%F)}"
OWNER="${2:-${STANDUP_GH_OWNER:-}}"
OWNER_ARGS=()
[ -n "$OWNER" ] && OWNER_ARGS=(--owner "$OWNER")
ME="$(gh api user --jq .login)"
SINCE="$(date -u -d "$DAY 00:00" +%FT%TZ)"
UNTIL="$(date -u -d "$DAY 00:00 +1 day" +%FT%TZ)"

{
  gh search prs --author=@me "${OWNER_ARGS[@]}" --updated ">=$DAY" --limit 100 --json url --jq '.[].url'
  gh search prs --commenter=@me "${OWNER_ARGS[@]}" --updated ">=$DAY" --limit 100 --json url --jq '.[].url'
  gh search prs --reviewed-by=@me "${OWNER_ARGS[@]}" --updated ">=$DAY" --limit 100 --json url --jq '.[].url'
} | sort -u | while read -r url; do
  repo="$(echo "$url" | cut -d/ -f4-5)"; num="${url##*/}"
  inline="$(gh api "repos/$repo/pulls/$num/comments?per_page=100" --paginate \
    --jq "[.[]|select(.user.login==\"$ME\" and .created_at>=\"$SINCE\" and .created_at<\"$UNTIL\")]|length" | paste -sd+ | bc)"
  gh pr view "$url" --json title,author,state,createdAt,mergedAt,reviews,comments,commits | jq -r \
    --arg me "$ME" --arg s "$SINCE" --arg u "$UNTIL" --arg url "$url" --arg inl "${inline:-0}" '
    def today(t): t >= $s and t < $u;
    ([.reviews[]|select(.author.login==$me and today(.submittedAt))|.state]|unique) as $rv
    | ([.comments[]|select(.author.login==$me and today(.createdAt))]|length) as $c
    | ([.commits[]|select(.authors[0].login==$me and today(.committedDate))|.messageHeadline]) as $cm
    | select(($rv|length)+$c+($cm|length)+($inl|tonumber) > 0 or (.author.login==$me and (today(.createdAt) or today(.mergedAt // ""))))
    | "\($url)\n  title: \(.title)\n  author: \(.author.login)  state: \(.state)  opened_today: \(today(.createdAt))  merged_today: \(today(.mergedAt // ""))\n  my_reviews: \($rv|join(",")) my_comments: \($c) my_inline_replies: \($inl)\n  my_commits: \($cm|length) \($cm[0:5]|join(" | "))"'
done
