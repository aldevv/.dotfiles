#!/usr/bin/env bash
# notify.sh
# Cross-platform Claude Code notification hook.
#   macOS  -> osascript (display notification)
#   Linux  -> notify-send (freedesktop / GTK)
#
# Wired in ~/.claude/settings.json to:
#   Stop                              -> notify.sh stop
#   PermissionRequest                 -> notify.sh permission
#   PostToolUse (AskUserQuestion)     -> notify.sh question
#
# Also callable from other hooks/scripts via the custom mode:
#   NOTIFY_TITLE="..." NOTIFY_BODY="..." \
#     [NOTIFY_SUBTITLE="..."] [NOTIFY_SOUND="Glass"] [NOTIFY_URGENCY="normal"] \
#     notify.sh custom
#
# When inside tmux, the title is replaced with "session -> window" and the
# original title becomes the subtitle (macOS) or body prefix (Linux).

set -euo pipefail

event="${1:-}"
cat >/dev/null 2>&1 || true

tmux_info=""
if [[ -n "${TMUX:-}" && -n "${TMUX_PANE:-}" ]] && command -v tmux >/dev/null 2>&1; then
  session="$(tmux display-message -p -t "$TMUX_PANE" '#S' 2>/dev/null || true)"
  window="$(tmux display-message -p -t "$TMUX_PANE" '#W' 2>/dev/null || true)"
  [[ -n "$session" && -n "$window" ]] && tmux_info="${session} -> ${window}"
fi

case "$event" in
  stop)
    base_title="Claude Code"
    status="Done"
    body="Claude finished its turn"
    sound="Glass"
    urgency="low"
    fg="#dddddd"
    ;;
  permission)
    base_title="Claude Code"
    status="Needs your approval"
    body="Claude is waiting for permission"
    sound="Funk"
    urgency="critical"
    ;;
  question)
    base_title="Claude Code"
    status="Asked a question"
    body="Claude is waiting on your answer"
    sound="Funk"
    urgency="critical"
    ;;
  custom)
    base_title="${NOTIFY_TITLE:-Claude Code}"
    status="${NOTIFY_SUBTITLE:-}"
    body="${NOTIFY_BODY:-}"
    sound="${NOTIFY_SOUND:-Glass}"
    urgency="${NOTIFY_URGENCY:-normal}"
    bg="${NOTIFY_BG:-}"
    ;;
  *)
    base_title="Claude Code"
    status=""
    body="Hook fired (unknown event: ${event:-none})"
    sound="Glass"
    urgency="normal"
    ;;
esac

if [[ -n "$tmux_info" ]]; then
  title="$tmux_info"
  if [[ -n "$status" ]]; then
    subtitle="${base_title}: $status"
  else
    subtitle="$base_title"
  fi
else
  title="$base_title"
  subtitle="$status"
fi

case "$(uname -s)" in
  Darwin)
    # osascript host (Script Editor) is Apple-signed, so notifications
    # actually reach the user. To make notifications persist past the
    # ~3s banner default, flip Script Editor to "Alerts" in
    # System Settings -> Notifications (one-time).
    TITLE="$title" SUBTITLE="$subtitle" MSG="$body" SOUND="$sound" \
      osascript -e 'display notification (system attribute "MSG") with title (system attribute "TITLE") subtitle (system attribute "SUBTITLE") sound name (system attribute "SOUND")' \
      >/dev/null 2>&1 || true
    ;;
  Linux)
    if command -v notify-send >/dev/null 2>&1; then
      ns_body="$body"
      [[ -n "$subtitle" ]] && ns_body="${subtitle}
${body}"
      hints=()
      if [[ -n "${bg:-}" ]]; then
        # dunst-specific colour hints; harmless on other notifiers.
        hints+=(-h "string:bgcolor:$bg" -h "string:frcolor:$bg" -h "string:fgcolor:${fg:-#ffffff}")
      elif [[ -n "${fg:-}" ]]; then
        hints+=(-h "string:fgcolor:$fg")
      fi
      # 5-minute floor; notification daemons may ignore for urgency=critical
      # (which stays indefinite per freedesktop spec). Either satisfies
      # "at least 5 minutes".
      notify-send -u "$urgency" -t 300000 -a claude-code "${hints[@]}" "$title" "$ns_body" >/dev/null 2>&1 || true
    fi
    ;;
esac
