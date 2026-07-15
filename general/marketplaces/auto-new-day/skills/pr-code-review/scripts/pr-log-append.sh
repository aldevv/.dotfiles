#!/usr/bin/env bash
# pr-log-append.sh - append a review entry to <REPO_DIR>/.pr/<PR_NUM>.md
#
# Called from pr-code-review Step 5c. Creates the per-PR log file with a
# header if it doesn't exist yet, then appends one new "## <date> (head: <sha>)"
# section listing surfaced findings and filtered-FALSE claims. Future re-reviews
# read this log at Step 1b so they can skip lines already commented on, avoid
# re-litigating filtered claims, and focus on what's new since the last SHA.
#
# Idempotent in spirit (header is only written on first call), but each
# invocation appends a new section regardless. Don't call it twice per run.

set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: pr-log-append.sh \
  --pr-log <path>        absolute path to <REPO_DIR>/.pr/<PR_NUM>.md
  --pr-num <N>           PR number
  --title <title>        PR title (for header on first call)
  --url <url>            full PR URL (for header on first call)
  --author <login>       PR author GitHub login (for header on first call)
  --head <sha>           full 40-char HEAD SHA at review time (parseable by Step 1b)
  --agents <N>           review agent count
  --verifiers <V>        total verifier-agent count across all findings
  --count <C>            adaptive count chosen by Step 2 (or operator override)
  --effort <E>           low|medium|high
  [--findings <tsv>]     TSV: sev<TAB>conf<TAB>verified<TAB>file:line<TAB>headline
  [--filtered <tsv>]     TSV: angle<TAB>claim<TAB>reason  (verifier FALSE drops)
  [--archive <path>]     path to the full report written at Step 5b

Prints the log path on stdout. Exits non-zero on bad args.
EOF
  exit 2
}

pr_log=""; pr_num=""; title=""; url=""; author=""; head_sha=""
agents=""; verifiers=""; count=""; effort=""
findings=""; filtered=""; archive=""

while [ $# -gt 0 ]; do
  case "$1" in
    --pr-log)    pr_log="$2"; shift 2 ;;
    --pr-num)    pr_num="$2"; shift 2 ;;
    --title)     title="$2"; shift 2 ;;
    --url)       url="$2"; shift 2 ;;
    --author)    author="$2"; shift 2 ;;
    --head)      head_sha="$2"; shift 2 ;;
    --agents)    agents="$2"; shift 2 ;;
    --verifiers) verifiers="$2"; shift 2 ;;
    --count)     count="$2"; shift 2 ;;
    --effort)    effort="$2"; shift 2 ;;
    --findings)  findings="$2"; shift 2 ;;
    --filtered)  filtered="$2"; shift 2 ;;
    --archive)   archive="$2"; shift 2 ;;
    -h|--help)   usage ;;
    *)           echo "unknown arg: $1" >&2; usage ;;
  esac
done

for v in pr_log pr_num title url author head_sha agents verifiers count effort; do
  if [ -z "${!v}" ]; then
    echo "missing required arg: --${v//_/-}" >&2
    usage
  fi
done

# Sanity-check the SHA shape so Step 1b's `grep -oE 'head: [0-9a-f]{7,40}'` keeps working.
case "$head_sha" in
  *[!0-9a-f]*|"") echo "invalid head sha: $head_sha" >&2; exit 3 ;;
esac
if [ "${#head_sha}" -lt 7 ]; then
  echo "head sha too short (need >=7 chars): $head_sha" >&2
  exit 3
fi

mkdir -p "$(dirname "$pr_log")"

if [ ! -f "$pr_log" ]; then
  cat > "$pr_log" <<EOF
# PR #$pr_num: $title

URL: $url
Author: $author

EOF
fi

b=0; mj=0; mn=0
if [ -n "$findings" ] && [ -f "$findings" ] && [ -s "$findings" ]; then
  b=$(awk -F'\t' 'toupper($1)=="BLOCKER"' "$findings" | wc -l | tr -d ' ')
  mj=$(awk -F'\t' 'toupper($1)=="MAJOR"'   "$findings" | wc -l | tr -d ' ')
  mn=$(awk -F'\t' 'toupper($1)=="MINOR"'   "$findings" | wc -l | tr -d ' ')
fi
total=$((b + mj + mn))
today=$(date +%Y-%m-%d)

{
  printf '\n## %s (head: %s)\n' "$today" "$head_sha"
  printf 'Agents: %s review + %s verifiers (count=%s, effort=%s)\n' \
    "$agents" "$verifiers" "$count" "$effort"
  printf 'Surfaced: %s findings (%s BLOCKER, %s MAJOR, %s MINOR)\n' \
    "$total" "$b" "$mj" "$mn"
  if [ -n "$archive" ]; then
    printf 'Archive: %s\n' "$archive"
  fi
  printf '\n### Surfaced (do not re-flag the same line unless code changed)\n'
  if [ "$total" -gt 0 ]; then
    awk -F'\t' '{ printf "- %s %s %s %s %s\n", $1, $2, $3, $4, $5 }' "$findings"
  else
    printf '(none)\n'
  fi
  if [ -n "$filtered" ] && [ -f "$filtered" ] && [ -s "$filtered" ]; then
    printf '\n### Filtered FALSE / low-confidence (do not re-litigate)\n'
    awk -F'\t' '{ printf "- %s: %s (%s)\n", $1, $2, $3 }' "$filtered"
  fi
} >> "$pr_log"

echo "$pr_log"
