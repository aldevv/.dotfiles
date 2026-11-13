#!/usr/bin/env bash
# post-merge-runs.sh
# Flag workflow runs that are red on the merge commit of a PR you merged
# recently (deploy / apply / release jobs that only run after merge, so no
# open-PR check ever sees them). A run that was re-run to green drops out.
#
# Best-effort: a failed gh call logs to stderr and the script still exits 0.
#
# Usage: post-merge-runs.sh [--days N]   (default 3, or $AUTO_NEW_DAY_POST_MERGE_DAYS)
# Output: one TSV line per red run: <pr-url> <pr-title> <workflow> <conclusion> <run-url>

set -o pipefail

DAYS="${AUTO_NEW_DAY_POST_MERGE_DAYS:-3}"
[ "${1:-}" = "--days" ] && DAYS="${2:-$DAYS}"
SINCE=$(date -u -d "-${DAYS} days" +%F)

prs=$(gh search prs --author=@me --merged --merged-at=">=${SINCE}" --limit 100 \
  --json url,title,repository --jq '.[]|[.url, .repository.nameWithOwner, .title]|@tsv') \
  || { echo "post-merge-runs: gh search failed" >&2; exit 0; }

while IFS=$'\t' read -r url repo title; do
  [ -n "$url" ] || continue
  sha=$(gh pr view "$url" --json mergeCommit --jq '.mergeCommit.oid // empty') \
    || { echo "post-merge-runs: pr view failed: $url" >&2; continue; }
  [ -n "$sha" ] || continue
  gh api "repos/${repo}/actions/runs?head_sha=${sha}&event=push&per_page=100" \
    --jq '.workflow_runs[] | select(.conclusion as $c | ["failure","timed_out","startup_failure","action_required"] | index($c)) | [.name, .conclusion, .html_url] | @tsv' \
    | while IFS=$'\t' read -r wf concl run_url; do
      printf '%s\t%s\t%s\t%s\t%s\n' "$url" "$title" "$wf" "$concl" "$run_url"
    done
done <<< "$prs"
exit 0
