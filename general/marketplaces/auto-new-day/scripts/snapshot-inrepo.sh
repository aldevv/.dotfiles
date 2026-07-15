#!/usr/bin/env bash
# snapshot-inrepo.sh
# Archive the current state of a repo's .inreview/ / .inprogress/ /
# .inreview-others/ artifacts into per-date subdirs INSIDE those same folders.
#
# The per-date layout:
#
#   <repo>/.inreview/<DATE>/
#   ├── <TICKET>.md                          (copy of <repo>/.inreview/<TICKET>.md)
#   ├── validate-connector/<TICKET>.md       (copy of the sibling-skill output)
#   ├── my-connector-review/<TICKET>.md
#   └── baton-admin-review/<TICKET>.md
#   <repo>/.inprogress/<DATE>/<TICKET>.md
#   <repo>/.inreview-others/<DATE>/<TICKET>.md
#
# Each `<repo>/.inreview/<TICKET>.md` (flat, top-level) remains the cross-day
# dedupe marker — that file's existence is what tells the next sweep "this
# ticket already has a dispatched window."  The <DATE>/ subdir is purely
# additive history.
#
# Two modes:
#
# 1. Sweep-start mode (default): walks ~/work/baton-*/ and snapshots EVERY
#    repo's three artifact dirs. Used by auto-new-day Step 1c.  Captures the
#    END state of all prior dispatches before the new sweep can overwrite.
#
# 2. Single-repo mode (--repo <dir>): snapshots ONE repo.  Used by a dispatched
#    work skill (fix-bug-work / impl-work / newconnector) at the END of
#    its run, when it sees AUTO_NEW_DAY_DATE_DIR exported by the dispatch
#    bootstrap.  Captures THIS run's freshly-written artifacts before they can
#    be overwritten by a later same-ticket re-run.
#
# Always best-effort: cp failures (permission, broken symlink) never abort.
# Always exits 0 unless the args are malformed.
#
# When AUTO_NEW_DAY_DATE_DIR is given via --to, also copies the artifacts into
# $AUTO_NEW_DAY_DATE_DIR/inrepo-snapshot/<repo>/<sub>/ for operator convenience
# (so they can grep one tree instead of N repos).  This is optional belt-and-
# braces; the in-repo <DATE>/ subdir is the canonical history.

set -u

DATE_RE='^[0-9]{4}-[0-9]{2}-[0-9]{2}$'

usage() {
  cat >&2 <<EOF
usage:
  snapshot-inrepo.sh --date <YYYY-MM-DD>                                 # sweep-start
  snapshot-inrepo.sh --date <YYYY-MM-DD> --repo <repo-dir>               # single-repo
  snapshot-inrepo.sh --to <date-dir>                                     # sweep-start, also mirror to date-dir
  snapshot-inrepo.sh --to <date-dir> --repo <repo-dir>                   # single-repo, also mirror to date-dir
EOF
  exit 2
}

DATE=""
DATE_DIR=""
REPO_DIR=""

while [ $# -gt 0 ]; do
  case "$1" in
    --date)  DATE="${2:-}"; shift 2 ;;
    --to)    DATE_DIR="${2:-}"; shift 2 ;;
    --repo)  REPO_DIR="${2:-}"; shift 2 ;;
    -h|--help) usage ;;
    *)       echo "unknown arg: $1" >&2; usage ;;
  esac
done

if [ -z "$DATE" ] && [ -n "$DATE_DIR" ]; then
  DATE=$(basename "${DATE_DIR%/}")
fi
[[ "$DATE" =~ $DATE_RE ]] || { echo "ERROR: bad or missing --date / --to (got '$DATE')" >&2; usage; }

snap_one_repo() {
  local repo_dir="$1"
  [ -d "$repo_dir" ] || return 0
  local repo_name
  repo_name=$(basename "${repo_dir%/}")
  local sub
  for sub in .inreview .inprogress .inreview-others; do
    local src="${repo_dir%/}/$sub"
    [ -d "$src" ] || continue
    local in_repo_dst="${src%/}/$DATE"
    mkdir -p "$in_repo_dst" 2>/dev/null || true

    # Copy the flat marker + every non-date-named subdir's contents into the
    # per-date in-repo archive. Skip any existing <DATE>/ subdir to avoid
    # snapshotting our own history recursively.
    local entry
    for entry in "$src"/*; do
      [ -e "$entry" ] || continue
      local name
      name=$(basename "$entry")
      [[ "$name" =~ $DATE_RE ]] && continue
      if [ -d "$entry" ]; then
        # nested sibling-skill dir, e.g. validate-connector/
        mkdir -p "$in_repo_dst/$name" 2>/dev/null || true
        cp -a "$entry/." "$in_repo_dst/$name/" 2>/dev/null || true
      else
        cp -a "$entry" "$in_repo_dst/" 2>/dev/null || true
      fi
    done

    # Operator-convenience: symlink $DATE_DIR/inrepo-snapshot/<repo>/<bucket>
    # to the in-repo per-date archive we just populated. No duplicate writes;
    # grep-friendly tree under one root.
    if [ -n "$DATE_DIR" ]; then
      local dd_parent="$DATE_DIR/inrepo-snapshot/$repo_name"
      mkdir -p "$dd_parent" 2>/dev/null || true
      ln -sfn "$in_repo_dst" "$dd_parent/$sub" 2>/dev/null || true
    fi
  done
}

if [ -n "$REPO_DIR" ]; then
  snap_one_repo "$REPO_DIR"
else
  shopt -s nullglob
  for repo_dir in "${AUTO_NEW_DAY_WORKING_ROOT:-$PWD}"/*/; do
    snap_one_repo "$repo_dir"
  done
fi

exit 0
