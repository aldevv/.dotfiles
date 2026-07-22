#!/usr/bin/env bash
# rtm-window.sh
# Build (or replace) one parked tmux window (ready-to-merge or follow-up).
#
# Three shapes, selected by --status:
#   merged   -> left pane: a claude session cd'd to the repo; right pane: a pager
#               (less) showing the ticket description under a big "MERGED!" banner.
#               Use after the sweep auto-merged an approved PR (guards.merge opt-in).
#   parked   -> left pane: a plain login shell parked on the PR branch; right pane:
#               the same pager under a "READY TO MERGE" banner. The default when
#               guards.merge is blocked (sweep did not merge).
#   followup -> left pane: a claude session on the branch (--dangerously-skip-
#               permissions, seeded with the body, told to wait) so the operator can
#               say "push"/"open the PR"/"merge"; right pane: a pager under a "NEEDS
#               YOU" banner with the ticket summary + recommended actions, and, when
#               --review-diff is given, a Hunk pane below it on those local changes.
#               Use for an own-work item already worked by a prior sweep (skip/resume)
#               so the operator sees what to do, in a window not chat.
#
# The pager body is read from --body-file (ticket id/title/url/description, caller
# supplies it). This script only prepends the banner + a status line and opens it.
#
# Usage:
#   rtm-window.sh --session <s> --window <w> --repo-dir <d> --body-file <f> \
#                 --status <merged|parked> [--branch <b>] [--merged-by <login>] \
#                 [--merged-at <iso>] [--out-dir <dir>]
#
# Dedupes by window name (replaces an existing same-named window so a re-run
# reflects current state). Exits 0 on success, 1 on bad args / tmux failure.

set -u

SESSION="" WINDOW="" REPO_DIR="" BODY_FILE="" STATUS="" BRANCH=""
MERGED_BY="" MERGED_AT="" OUT_DIR="" REVIEW_DIFF=""
while [ $# -gt 0 ]; do
  case "$1" in
    --session)     SESSION="${2:-}";     shift 2 ;;
    --window)      WINDOW="${2:-}";      shift 2 ;;
    --repo-dir)    REPO_DIR="${2:-}";    shift 2 ;;
    --body-file)   BODY_FILE="${2:-}";   shift 2 ;;
    --status)      STATUS="${2:-}";      shift 2 ;;
    --branch)      BRANCH="${2:-}";      shift 2 ;;
    --merged-by)   MERGED_BY="${2:-}";   shift 2 ;;
    --merged-at)   MERGED_AT="${2:-}";   shift 2 ;;
    --out-dir)     OUT_DIR="${2:-}";     shift 2 ;;
    --review-diff) REVIEW_DIFF="${2:-}"; shift 2 ;;
    *) echo "rtm-window.sh: unknown arg: $1" >&2; exit 1 ;;
  esac
done
for v in SESSION WINDOW REPO_DIR BODY_FILE STATUS; do
  [ -n "${!v}" ] || { echo "rtm-window.sh: --${v,,} required" >&2; exit 1; }
done
[ -f "$BODY_FILE" ] || { echo "rtm-window.sh: body-file not found: $BODY_FILE" >&2; exit 1; }
command -v tmux >/dev/null 2>&1 || { echo "rtm-window.sh: tmux missing" >&2; exit 1; }

OUT_DIR="${OUT_DIR:-$(dirname "$BODY_FILE")}"
mkdir -p "$OUT_DIR"
PAGER_FILE="$OUT_DIR/$WINDOW.page.txt"

banner_merged() {
  cat <<'BANNER'
 ███╗   ███╗███████╗██████╗  ██████╗ ███████╗██████╗ ██╗
 ████╗ ████║██╔════╝██╔══██╗██╔════╝ ██╔════╝██╔══██╗██║
 ██╔████╔██║█████╗  ██████╔╝██║  ███╗█████╗  ██║  ██║██║
 ██║╚██╔╝██║██╔══╝  ██╔══██╗██║   ██║██╔══╝  ██║  ██║╚═╝
 ██║ ╚═╝ ██║███████╗██║  ██║╚██████╔╝███████╗██████╔╝██╗
 ╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═════╝ ╚═╝
BANNER
}
banner_ready() {
  cat <<'BANNER'
 ██████╗ ███████╗ █████╗ ██████╗ ██╗   ██╗  ████████╗ ██████╗
 ██╔══██╗██╔════╝██╔══██╗██╔══██╗╚██╗ ██╔╝  ╚══██╔══╝██╔═══██╗
 ██████╔╝█████╗  ███████║██║  ██║ ╚████╔╝      ██║   ██║   ██║
 ██╔══██╗██╔══╝  ██╔══██║██║  ██║  ╚██╔╝       ██║   ██║   ██║
 ██║  ██║███████╗██║  ██║██████╔╝   ██║        ██║   ╚██████╔╝
 ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝    ╚═╝        ╚═╝    ╚═════╝
                         M E R G E
BANNER
}
banner_action() {
  cat <<'BANNER'
 ███╗   ██╗███████╗███████╗██████╗ ███████╗    ██╗   ██╗ ██████╗ ██╗   ██╗
 ████╗  ██║██╔════╝██╔════╝██╔══██╗██╔════╝    ╚██╗ ██╔╝██╔═══██╗██║   ██║
 ██╔██╗ ██║█████╗  █████╗  ██║  ██║███████╗     ╚████╔╝ ██║   ██║██║   ██║
 ██║╚██╗██║██╔══╝  ██╔══╝  ██║  ██║╚════██║      ╚██╔╝  ██║   ██║██║   ██║
 ██║ ╚████║███████╗███████╗██████╔╝███████║       ██║   ╚██████╔╝╚██████╔╝
 ╚═╝  ╚═══╝╚══════╝╚══════╝╚═════╝ ╚══════╝       ╚═╝    ╚═════╝  ╚═════╝
BANNER
}

{
  if [ "$STATUS" = "merged" ]; then
    banner_merged
    echo
    echo "  Auto-merged by the morning sweep."
    [ -n "$MERGED_BY" ] && echo "  merged by: $MERGED_BY"
    [ -n "$MERGED_AT" ] && echo "  merged at: $MERGED_AT"
  elif [ "$STATUS" = "followup" ]; then
    banner_action
    echo
    echo "  Already worked in a prior sweep. Nothing was re-dispatched."
    echo "  Read the current state + recommended actions below, then act."
    [ -n "$BRANCH" ] && echo "  branch: $BRANCH"
  else
    banner_ready
    echo
    echo "  Approved by an approver. The sweep did NOT merge (parked for you)."
    [ -n "$BRANCH" ] && echo "  branch: $BRANCH"
  fi
  echo
  echo "======================================================================"
  echo
  cat "$BODY_FILE"
} > "$PAGER_FILE"

# Replace any existing same-named window so a re-run reflects current state.
if tmux has-session -t "$SESSION" 2>/dev/null \
   && tmux list-windows -t "$SESSION" -F '#{window_name}' | grep -qx "$WINDOW"; then
  tmux kill-window -t "$SESSION:$WINDOW" 2>/dev/null || true
fi

# Left pane command.
if [ "$STATUS" = "merged" ]; then
  # A bare claude session, cd'd to the repo. No auto prompt (idle, ready for you).
  LEFT="cd '$REPO_DIR'; clear; echo 'ready-to-merge: $WINDOW — PR merged. right pane has the ticket + MERGED banner.'; exec claude --dangerously-skip-permissions"
elif [ "$STATUS" = "followup" ]; then
  # A claude session on the branch, seeded with the follow-up context so the
  # operator can just say "push" / "open the PR" / "merge". It is told to WAIT:
  # this is the operator's session, not an autonomous child, so it must not push
  # or open/merge a PR until the operator says so.
  CO=""
  [ -n "$BRANCH" ] && CO="git checkout '$BRANCH' 2>/dev/null; "
  SEED="Follow-up window for $WINDOW. Read $BODY_FILE for the ticket, current state, and recommended actions. Any local changes are under review in the Hunk pane to your right. Summarize the state and recommended actions for me in a few lines, then WAIT. Do NOT run git push, gh pr create, or gh pr merge until I explicitly tell you to."
  LEFT="cd '$REPO_DIR'; ${CO}clear; exec claude --dangerously-skip-permissions '$SEED'"
else
  CO=""
  [ -n "$BRANCH" ] && CO="git checkout '$BRANCH' 2>/dev/null; "
  LEFT="cd '$REPO_DIR'; ${CO}exec \"\$SHELL\" -l"
fi

# Create the window (create session on first window).
if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux new-window -t "$SESSION:" -n "$WINDOW" -c "$REPO_DIR" "$LEFT" || { echo "rtm-window.sh: new-window failed" >&2; exit 1; }
else
  tmux new-session -d -s "$SESSION" -n "$WINDOW" -c "$REPO_DIR" "$LEFT" || { echo "rtm-window.sh: new-session failed" >&2; exit 1; }
fi

MAIN_PANE=$(tmux list-panes -t "$SESSION:$WINDOW" -F '#{pane_id}' | head -1)
if [ "$STATUS" = "followup" ]; then
  # claude top-left; the "NEEDS YOU" pager below it (twice the normal 20% pager, so
  # -p 40); Hunk (reviews) as a full-height right column.
  if [ -n "$REVIEW_DIFF" ]; then
    tmux split-window -h -p 55 -t "$MAIN_PANE" -c "$REPO_DIR" "hunk diff '$REVIEW_DIFF' --exclude-untracked || exec \"\$SHELL\" -l" \
      || { echo "rtm-window.sh: split-window (hunk) failed" >&2; exit 1; }
  fi
  tmux split-window -v -p 40 -t "$MAIN_PANE" -c "$REPO_DIR" "less -R '$PAGER_FILE'" \
    || { echo "rtm-window.sh: split-window (pager) failed" >&2; exit 1; }
else
  # merged / parked: pager on the right (original layout).
  tmux split-window -h -t "$SESSION:$WINDOW" -c "$REPO_DIR" "less -R '$PAGER_FILE'" \
    || { echo "rtm-window.sh: split-window (pager) failed" >&2; exit 1; }
fi
tmux select-pane -t "$MAIN_PANE" 2>/dev/null || true

echo "rtm-window: $STATUS $SESSION:$WINDOW"
