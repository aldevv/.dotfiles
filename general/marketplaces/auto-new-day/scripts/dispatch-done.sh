#!/usr/bin/env bash
# dispatch-done.sh
# Per-dispatch completion manifest. Lets a dispatched child claude record
# "this dispatch completed at <ts>; here are the artifacts and how to re-open
# them in Hunk". A re-dispatch (same ticket, same day) reads the manifest and
# fast-paths to the report + Hunk instead of redoing the multi-agent work.
#
# Manifest path: $AUTO_NEW_DAY_DATE_DIR/dispatch/<TICKET>.done.json
#                (or review-<WINDOW>.done.json for AUTO-inreview-others)
#
# Three subcommands:
#
#   path --ticket <ID>           Print the manifest path (does not check existence).
#   path --window <NAME>         Same, for review-session windows. Use the bare
#                                window name like baton-foo-42 (NOT review-...).
#   path --repo <NAME>           Same, for repo-keyed manifests (generic skills run
#                                outside a ticket/window context). Manifest filename
#                                is `repo-<NAME>.done.json`.
#
#   check --ticket <ID>          Exit 0 if the manifest exists, 1 otherwise.
#   check --window <NAME>        Same, for review windows.
#   check --repo <NAME>          Same, for repo-keyed.
#                                Use this from a work skill's Step 0 to gate the
#                                fast-path.
#
#   write --ticket <ID> ...      Write the manifest. Required:
#                                  --verdict yes|no
#                                  --reason "<one short line>"
#                                Optional:
#                                  --diff-range <git-range>     (default: main..HEAD)
#                                  --pr-feedback <path>         (for /report re-open)
#                                  --commits "<sha sha sha>"    (space-separated)
#                                  --artifact <kind>=<path>     (repeatable; kind is
#                                                                free-form: validate-connector,
#                                                                my-connector-review,
#                                                                baton-admin-review, etc.)
#                                Use `--window <NAME>` instead of `--ticket` for review windows.
#                                Use `--repo <NAME>` instead of `--ticket` for repo-keyed.
#
# Common optional args (path / check / write):
#   --date <phrase>              Resolve the target date via scripts/resolve-date.sh
#                                ("today", "yesterday", "june 16", "2026-06-16").
#                                Overrides $AUTO_NEW_DAY_DATE_DIR. Defaults to today
#                                when both --date and $AUTO_NEW_DAY_DATE_DIR are unset.
#
# Always best-effort: failures never abort the dispatched child. Exits 0 on
# success, 1 on missing manifest (check), 2 on bad args.
#
# Requires: jq. Either $AUTO_NEW_DAY_DATE_DIR or --date must resolve to a valid
# date dir (defaults to today when both are absent).

set -u

SUB="${1:-}"
[ -n "$SUB" ] || { echo "dispatch-done.sh: missing subcommand (path|check|write)" >&2; exit 2; }
shift

KEY=""          # ticket id, window name, or repo name
KEY_KIND=""     # "ticket", "window", or "repo"
DATE_PHRASE=""
VERDICT=""
REASON=""
DIFF_RANGE="main..HEAD"
PR_FEEDBACK=""
COMMITS=""
declare -a ARTIFACT_KV=()

while [ $# -gt 0 ]; do
  case "$1" in
    --ticket)      KEY="${2:-}"; KEY_KIND=ticket; shift 2 ;;
    --window)      KEY="${2:-}"; KEY_KIND=window; shift 2 ;;
    --repo)        KEY="${2:-}"; KEY_KIND=repo;   shift 2 ;;
    --date)        DATE_PHRASE="${2:-}"; shift 2 ;;
    --verdict)     VERDICT="${2:-}"; shift 2 ;;
    --reason)      REASON="${2:-}"; shift 2 ;;
    --diff-range)  DIFF_RANGE="${2:-}"; shift 2 ;;
    --pr-feedback) PR_FEEDBACK="${2:-}"; shift 2 ;;
    --commits)     COMMITS="${2:-}"; shift 2 ;;
    --artifact)    ARTIFACT_KV+=( "${2:-}" ); shift 2 ;;
    -h|--help)     sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)             echo "dispatch-done.sh: unknown arg: $1" >&2; exit 2 ;;
  esac
done

# Resolve the date dir: --date wins; else $AUTO_NEW_DAY_DATE_DIR; else today.
SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="${AUTO_NEW_DAY_STATE_DIR:-$HOME/.local/state/auto-new-day}"
if [ -n "$DATE_PHRASE" ]; then
  if RESOLVED=$("$SCRIPTS_DIR/resolve-date.sh" $DATE_PHRASE 2>/dev/null); then
    DATE_DIR="$STATE_DIR/dates/$RESOLVED"
  else
    echo "dispatch-done.sh: could not resolve --date '$DATE_PHRASE'" >&2
    exit 2
  fi
elif [ -n "${AUTO_NEW_DAY_DATE_DIR:-}" ]; then
  DATE_DIR="$AUTO_NEW_DAY_DATE_DIR"
else
  DATE_DIR="$STATE_DIR/dates/$(date +%Y-%m-%d)"
fi

[ -n "$KEY" ] || { echo "dispatch-done.sh: --ticket, --window, or --repo required" >&2; exit 2; }

case "$KEY_KIND" in
  ticket) MANIFEST_PATH="$DATE_DIR/dispatch/${KEY}.done.json" ;;
  window) MANIFEST_PATH="$DATE_DIR/dispatch/review-${KEY}.done.json" ;;
  repo)   MANIFEST_PATH="$DATE_DIR/dispatch/repo-${KEY}.done.json" ;;
  *)      echo "dispatch-done.sh: missing --ticket / --window / --repo" >&2; exit 2 ;;
esac

case "$SUB" in
  path)
    echo "$MANIFEST_PATH"
    ;;
  check)
    [ -f "$MANIFEST_PATH" ] || exit 1
    exit 0
    ;;
  write)
    [ -n "$VERDICT" ] || { echo "dispatch-done.sh: --verdict required for write" >&2; exit 2; }
    [ -n "$REASON" ]  || { echo "dispatch-done.sh: --reason required for write" >&2; exit 2; }
    case "$VERDICT" in
      yes|no) ;;
      *) echo "dispatch-done.sh: --verdict must be yes|no (got: $VERDICT)" >&2; exit 2 ;;
    esac
    command -v jq >/dev/null 2>&1 || { echo "dispatch-done.sh: jq not on PATH" >&2; exit 2; }
    mkdir -p "$(dirname "$MANIFEST_PATH")" 2>/dev/null || true

    # Build the artifacts object from --artifact kind=path entries.
    # Use bash parameter expansion (not awk) to avoid OFS-driven leading spaces.
    ART_JSON='{}'
    for kv in "${ARTIFACT_KV[@]+"${ARTIFACT_KV[@]}"}"; do
      [ -n "$kv" ] || continue
      art_kind="${kv%%=*}"
      art_path="${kv#*=}"
      ART_JSON=$(jq -n \
        --arg k "$art_kind" --arg p "$art_path" --argjson cur "$ART_JSON" \
        '$cur + {($k): $p}')
    done

    # Build the commits array from space-separated --commits. Empty string -> [].
    if [ -n "$COMMITS" ]; then
      COMMITS_JSON=$(printf '%s' "$COMMITS" | jq -R 'split(" ") | map(select(length>0))')
    else
      COMMITS_JSON='[]'
    fi

    TS=$(date -Iseconds)

    jq -n \
      --arg ts        "$TS" \
      --arg key       "$KEY" \
      --arg keyKind   "$KEY_KIND" \
      --arg verdict   "$VERDICT" \
      --arg reason    "$REASON" \
      --arg diffRange "$DIFF_RANGE" \
      --arg prFb      "$PR_FEEDBACK" \
      --argjson art      "$ART_JSON" \
      --argjson commits  "$COMMITS_JSON" \
      '{
         completedAt: $ts,
         key:         $key,
         keyKind:     $keyKind,
         verdict:     $verdict,
         reason:      $reason,
         commits:     $commits,
         artifacts:   $art,
         hunkArgs: ({ diffRange: $diffRange }
                     + (if ($prFb | length) > 0 then {prFeedbackPath: $prFb} else {} end))
       }' > "$MANIFEST_PATH.partial" \
      && mv "$MANIFEST_PATH.partial" "$MANIFEST_PATH"
    ;;
  *)
    echo "dispatch-done.sh: unknown subcommand: $SUB (expected path|check|write)" >&2
    exit 2
    ;;
esac
