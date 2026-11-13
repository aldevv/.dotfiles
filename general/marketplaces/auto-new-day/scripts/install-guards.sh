#!/usr/bin/env bash
# Install per-window mechanical guards for an auto-new-day dispatched session.
# Creates a `bin/gh` write-shim (optional) and a `hooks/pre-push` hook inside
# the given guards directory. Both files are made executable. Idempotent.
#
# Usage:
#   install-guards.sh <guards-dir> [--with-gh-shim]
#
# Without --with-gh-shim: only the pre-push hook is installed (used by the
# AUTO-inreview-others review session, which needs gh writes to remain
# reachable so the review wrapper skill can post operator-approved comments).
#
# With --with-gh-shim: the pre-push hook AND a gh write-shim are installed
# (used by AUTO-inreview and AUTO-inprogress, which must hard-block
# any gh write because the operator pushes manually after reviewing).
#
# Per-call override: every block honors AUTO_NEW_DAY_APPROVED=1. Skills like
# add-comment that gate posts on explicit operator approval (verbatim draft
# shown via AskUserQuestion, then "Post it" clicked) set this env var on the
# single allowed call. Each override is logged to stderr.
#
# Push gate: inside a dispatched window ($AUTO_NEW_DAY_DATE_DIR set), the
# override does NOT lift `git push` or `gh pr create` on its own. It also needs
# a passing checklist file written by the skill for the exact commit:
#   $AUTO_NEW_DAY_DATE_DIR/dispatch/<$AUTO_NEW_DAY_TICKET>.checklist.json
#   {"head": "<full sha>",
#    "items": [{"name": "...", "pass": true, "evidence": "..."}],
#    "operator_approved": "<verbatim operator words, or empty>"}
# Accepted when head == the commit being pushed (for git push, the commit must
# not already be on a remote branch), and every item passes or operator_approved is set.
# Without $AUTO_NEW_DAY_TICKET, any checklist in that dir whose head matches.

set -u

die() { echo "install-guards.sh: $*" >&2; exit 1; }

GUARDS_DIR=${1:-}
WITH_SHIM=0
case "${2:-}" in
  --with-gh-shim) WITH_SHIM=1 ;;
  "") ;;
  *) die "unknown arg: $2 (try --with-gh-shim)" ;;
esac
[ -n "$GUARDS_DIR" ] || die "need <guards-dir> as first arg"

mkdir -p "$GUARDS_DIR/hooks"

# pre-push: every session, always. Honors AUTO_NEW_DAY_APPROVED=1.
cat > "$GUARDS_DIR/hooks/pre-push" <<'HOOK'
#!/usr/bin/env bash

checklist_ok() {
  # $1 = commit sha being pushed / PR'd; $2 = "push" to also require the
  # commit not be on a remote yet (gh pr create runs after the push).
  local sha=$1 mode=${2:-} dir f
  [ -n "${AUTO_NEW_DAY_DATE_DIR:-}" ] || return 0
  command -v jq >/dev/null || { echo "jq not found, push gate cannot verify the checklist"; return 1; }
  dir="$AUTO_NEW_DAY_DATE_DIR/dispatch"
  if [ -n "${AUTO_NEW_DAY_TICKET:-}" ]; then
    f="$dir/$AUTO_NEW_DAY_TICKET.checklist.json"
  else
    f=$(grep -l "\"$sha\"" "$dir"/*.checklist.json 2>/dev/null | head -1)
  fi
  [ -n "$f" ] && [ -f "$f" ] || { echo "no checklist file (${f:-$dir/*.checklist.json}); write it for $sha first"; return 1; }
  [ "$(jq -r '.head // ""' "$f")" = "$sha" ] || { echo "checklist head $(jq -r '.head // "none"' "$f") is not the commit being pushed ($sha); re-run the checklist"; return 1; }
  if [ "$mode" = "push" ] && git branch -r --contains "$sha" 2>/dev/null | grep -q .; then
    echo "commit $sha is already on a remote branch, nothing new to push"; return 1
  fi
  if [ -n "$(jq -r '.operator_approved // ""' "$f")" ]; then
    echo "push gate: operator approval recorded in $f" >&2; return 0
  fi
  local failed
  failed=$(jq -r 'if ((.items // []) | length) == 0 then "checklist has no items" else ([.items[] | select(.pass != true) | .name] | join(", ")) end' "$f")
  [ -z "$failed" ] || { echo "checklist items not passing: $failed"; return 1; }
  echo "push gate: all checklist items pass in $f" >&2
  return 0
}

if [ "${AUTO_NEW_DAY_APPROVED:-}" = "1" ]; then
  zero=0000000000000000000000000000000000000000
  while read -r _lref lsha _rref _rsha; do
    [ "$lsha" = "$zero" ] && continue
    if ! why=$(checklist_ok "$lsha" push); then
      echo "auto-new-day skill: push blocked by the push gate: $why" >&2
      exit 1
    fi
  done
  echo "auto-new-day skill: push override accepted (AUTO_NEW_DAY_APPROVED=1)" >&2
  exit 0
fi
echo "auto-new-day skill: push forbidden in dispatched sessions; commits stay local. (set AUTO_NEW_DAY_APPROVED=1 to override)" >&2
exit 1
HOOK
chmod +x "$GUARDS_DIR/hooks/pre-push"

# gh write-shim: only own-work sessions. Blocks the destructive gh
# subcommands. Reads (gh pr view, gh api -X GET, etc.) pass through to the
# real gh by stripping the guards dir off PATH before exec.
# AUTO_NEW_DAY_APPROVED=1 lifts the block per-call with a stderr audit line.
if [ "$WITH_SHIM" = "1" ]; then
  mkdir -p "$GUARDS_DIR/bin"
  cat > "$GUARDS_DIR/bin/gh" <<'SHIM'
#!/usr/bin/env bash
SUB="$1 $2"

checklist_ok() {
  # $1 = commit sha being pushed / PR'd; $2 = "push" to also require the
  # commit not be on a remote yet (gh pr create runs after the push).
  local sha=$1 mode=${2:-} dir f
  [ -n "${AUTO_NEW_DAY_DATE_DIR:-}" ] || return 0
  command -v jq >/dev/null || { echo "jq not found, push gate cannot verify the checklist"; return 1; }
  dir="$AUTO_NEW_DAY_DATE_DIR/dispatch"
  if [ -n "${AUTO_NEW_DAY_TICKET:-}" ]; then
    f="$dir/$AUTO_NEW_DAY_TICKET.checklist.json"
  else
    f=$(grep -l "\"$sha\"" "$dir"/*.checklist.json 2>/dev/null | head -1)
  fi
  [ -n "$f" ] && [ -f "$f" ] || { echo "no checklist file (${f:-$dir/*.checklist.json}); write it for $sha first"; return 1; }
  [ "$(jq -r '.head // ""' "$f")" = "$sha" ] || { echo "checklist head $(jq -r '.head // "none"' "$f") is not the commit being pushed ($sha); re-run the checklist"; return 1; }
  if [ "$mode" = "push" ] && git branch -r --contains "$sha" 2>/dev/null | grep -q .; then
    echo "commit $sha is already on a remote branch, nothing new to push"; return 1
  fi
  if [ -n "$(jq -r '.operator_approved // ""' "$f")" ]; then
    echo "push gate: operator approval recorded in $f" >&2; return 0
  fi
  local failed
  failed=$(jq -r 'if ((.items // []) | length) == 0 then "checklist has no items" else ([.items[] | select(.pass != true) | .name] | join(", ")) end' "$f")
  [ -z "$failed" ] || { echo "checklist items not passing: $failed"; return 1; }
  echo "push gate: all checklist items pass in $f" >&2
  return 0
}

allow_write() {
  if [ "${AUTO_NEW_DAY_APPROVED:-}" = "1" ]; then
    echo "auto-new-day skill: override accepted (AUTO_NEW_DAY_APPROVED=1) for gh $SUB" >&2
    return 0
  fi
  return 1
}
case "$SUB" in
  "pr create"|"pr edit"|"pr comment"|"pr review"|"pr merge"|"pr close"|"pr reopen"|"pr ready"|"pr lock"|"pr unlock"|"pr review-delete"|"pr update-branch"\
  |"issue create"|"issue edit"|"issue comment"|"issue close"|"issue reopen"|"issue lock"|"issue unlock"\
  |"release create"|"release edit"|"release delete"|"release upload"\
  |"secret set"|"secret delete"|"variable set"|"variable delete"\
  |"workflow run"|"workflow enable"|"workflow disable"\
  |"ruleset create"|"ruleset edit"|"ruleset delete")
    if ! allow_write; then
      echo "auto-new-day skill: forbidden gh subcommand: gh $SUB (set AUTO_NEW_DAY_APPROVED=1 to override)" >&2; exit 1
    fi
    if [ "$SUB" = "pr create" ] && ! why=$(checklist_ok "$(git rev-parse HEAD 2>/dev/null)"); then
      echo "auto-new-day skill: gh pr create blocked by the push gate: $why" >&2; exit 1
    fi ;;
esac
if [ "$1" = "api" ]; then
  # gh api defaults to GET. It becomes a write if any of:
  #   -X POST | --method POST | -X=POST | --method=POST  (and same for PATCH/DELETE/PUT)
  #   target endpoint is "graphql"          (always POSTs)
  #   any -f / --field / -F / --raw-field is present without an explicit -X GET
  api_write=0
  api_explicit_get=0
  for arg in "$@"; do
    case "$arg" in
      -X|--method)
        api_next_is_verb=1 ;;
      -X*|--method=*)
        verb=${arg#-X}; verb=${verb#--method=}
        case "$verb" in
          POST|PATCH|DELETE|PUT) api_write=1 ;;
          GET) api_explicit_get=1 ;;
        esac
        api_next_is_verb=0 ;;
      POST|PATCH|DELETE|PUT)
        if [ "${api_next_is_verb:-0}" = "1" ]; then api_write=1; fi
        api_next_is_verb=0 ;;
      GET)
        if [ "${api_next_is_verb:-0}" = "1" ]; then api_explicit_get=1; fi
        api_next_is_verb=0 ;;
      graphql)
        api_write=1 ;;
      -f|--field|-F|--raw-field|--input)
        # field flags imply POST unless an explicit GET was set
        if [ "$api_explicit_get" = "0" ]; then api_write=1; fi ;;
      *) api_next_is_verb=0 ;;
    esac
  done
  if [ "$api_write" = "1" ]; then
    if ! allow_write; then
      echo "auto-new-day skill: forbidden gh api write: $* (set AUTO_NEW_DAY_APPROVED=1 to override)" >&2; exit 1
    fi
  fi
fi
PATH=$(echo "$PATH" | tr ':' '\n' | grep -v 'auto-new-day/guards' | paste -sd:) exec gh "$@"
SHIM
  chmod +x "$GUARDS_DIR/bin/gh"
fi
