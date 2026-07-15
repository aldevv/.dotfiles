#!/usr/bin/env bash
# Launch the auto-new-day sweep in $TERMINAL (fallback kitty) with tmux attached.
# Invoked by auto-new-day-sweep.service on weekday mornings (America/Bogota;
# inspect the schedule with --show-time, change it with --set-time HH:MM).
# When the user sits down, they open the terminal window and see the sweep
# report in the AUTO-new-day tmux session (one `sweep` window). Four sibling
# sessions get created lazily by the sweep when they have work:
# AUTO-inreview (own In-Review tickets needing comment-fix, dispatched to
# /fix-bug-work + /report), AUTO-inprogress (unstarted In Progress tickets,
# dispatched to /<workflow>), AUTO-inreview-others (up to 5 teammate PRs
# that need review, dispatched to /pr-code-review-work), and
# AUTO-ready-to-merge (own PRs already approved by Bjorn/John/Geoff, one plain-shell
# window each parked on the PR branch so the operator can merge; no claude,
# the sweep never merges). The launcher only manages AUTO-new-day's lifecycle;
# the other four live across days so the operator doesn't lose in-flight
# reviews or multi-day impl work on the next morning tick.

set -u

# --- args ---
DRY_RUN=0
INSTALL=0
SHOW_TIME=0
SET_TIME=""
FORCE=0
DATE_PHRASE=""
# Case-insensitive: lowercase the env var before matching.
case "$(printf '%s' "${AUTO_NEW_DAY_DRY_RUN:-}" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')" in
  1|true|yes) DRY_RUN=1 ;;
esac
case "$(printf '%s' "${AUTO_NEW_DAY_FORCE:-}" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')" in
  1|true|yes) FORCE=1 ;;
esac
DATE_TOKENS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run|-n)  DRY_RUN=1 ;;
    --force|-f)    FORCE=1 ;;
    --install)     INSTALL=1 ;;
    --show-time)   SHOW_TIME=1 ;;
    --date)
      shift
      [ -z "${1:-}" ] && { echo "ERROR: --date requires a value" >&2; exit 1; }
      DATE_TOKENS+=( "$1" )
      ;;
    --set-time)
      shift
      SET_TIME="${1:-}"
      if [ -z "$SET_TIME" ]; then
        echo "ERROR: --set-time requires HH:MM (e.g. --set-time 06:30)" >&2
        exit 1
      fi
      ;;
    -h|--help)
      cat <<'EOF'
Usage: launch-auto-new-day.sh [--dry-run | --force | --install | --show-time | --set-time HH:MM | --date <date> | <date> [<date>...]]

Without flags: opens $TERMINAL (fallback kitty) attached to a fresh tmux
session running the /auto-new-day sweep.

--dry-run (or AUTO_NEW_DAY_DRY_RUN=1):
  - uses tmux session "AUTO-new-day-dryrun" so a real run isn't disturbed
  - the sweep runs discovery only and writes the per-day create.md
    checkpoint at ~/work/.auto-new-day/dates/<date>-dryrun-create.md;
    no per-ticket tmux session is spawned and no child claude is launched
  - skips all state writes

--force (or AUTO_NEW_DAY_FORCE=1):
  - ignores the per-repo dispatch markers (.inreview/, .inprogress/,
    .inreview-others/) so tickets and PRs are re-dispatched even if a
    marker says they were already handled
  - existing markers are left in place; new ones are still written on
    dispatch
  - composes with --dry-run

--date <date>  or  positional <date> tokens:
  - replays the dispatch plan saved at ~/work/.auto-new-day/dates/<DATE>-create.md
  - accepts: today, yesterday, "june 16", "last friday", 2026-06-16, etc.
    Multi-word phrases can be passed as separate positional args
    (e.g. `launch-auto-new-day.sh june 16`) or quoted with --date.
  - no Linear MCP calls, no gh PR fetches; re-spawns any windows from the
    saved plan that aren't already in their tmux session
  - mutually exclusive with --install / --show-time / --set-time

--install:
  - installs the user systemd unit files from references/systemd/
  - enables and starts auto-new-day-sweep.timer (Mon..Fri morning America/Bogota)
  - prints the next scheduled fire
  - safe to re-run; just refreshes the installed copies

--show-time:
  - prints the OnCalendar line from the installed timer file
  - prints the next scheduled fire (systemctl --user list-timers)
  - read-only

--set-time HH:MM:
  - rewrites OnCalendar in BOTH the installed timer file and the source copy
    under references/systemd/ (so a later --install does not regress it)
  - keeps Mon..Fri and America/Bogota
  - runs daemon-reload, restarts the timer, suppresses Persistent catch-up,
    prints the next scheduled fire
EOF
      exit 0
      ;;
    *)
      # Anything else is treated as a positional date token. Multiple are joined
      # back into one phrase by resolve-date.sh, so `june 16` works without quoting.
      DATE_TOKENS+=( "$1" )
      ;;
  esac
  shift
done
if [ ${#DATE_TOKENS[@]} -gt 0 ]; then
  DATE_PHRASE="${DATE_TOKENS[*]}"
fi

log() { printf '%s %s\n' "$(date -Iseconds)" "$*" >&2; }

# --- install mode (setup, then exit) ---
if [ "$INSTALL" = "1" ]; then
  SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
  SRC_DIR="$SKILL_DIR/references/systemd"
  DST_DIR="$HOME/.config/systemd/user"

  if [ ! -f "$SRC_DIR/auto-new-day-sweep.service" ] || [ ! -f "$SRC_DIR/auto-new-day-sweep.timer" ]; then
    echo "ERROR: unit files not found under $SRC_DIR" >&2
    exit 1
  fi

  # Install defaults come from the active profile (env still overrides), so
  # `--install` after `setup` auto-wires the timer to the same state dir /
  # working root / timezone the sweep uses.
  _prof="${AUTO_NEW_DAY_PROFILE:-$HOME/.config/auto-new-day/profile.json}"
  # $1=jq path into the profile; empty if unset/missing; expands a leading ~.
  _pget() { [ -f "$_prof" ] && jq -r "$1 // empty" "$_prof" 2>/dev/null | sed "s#^~#$HOME#"; }
  _sd="${AUTO_NEW_DAY_STATE_DIR:-$(_pget .state_dir)}"; _sd="${_sd:-$HOME/.local/state/auto-new-day}"
  _wr="${AUTO_NEW_DAY_WORKING_ROOT:-$(_pget .working_root)}"; _wr="${_wr:-$HOME}"
  _tzval="${AUTO_NEW_DAY_TZ:-$(_pget .tz)}"; _tz="${_tzval:+ $_tzval}"

  echo "==> creating dirs (state dir: $_sd)"
  mkdir -p "$DST_DIR" "$HOME/.cache/auto-new-day-sweep" \
           "$_sd/dispatch" "$_sd/done"

  echo "==> stopping timer (if running) to avoid mid-cp race"
  systemctl --user stop auto-new-day-sweep.timer 2>/dev/null || true

  echo "==> installing unit files (substituting launcher path, dirs, timezone, slash)"
  # A domain pack can point the unit's ExecStart at its own entrypoint (which
  # then delegates back here); default is this launcher.
  _launcher="${AUTO_NEW_DAY_LAUNCHER:-$SKILL_DIR/scripts/launch-auto-new-day.sh}"
  _slash="${AUTO_NEW_DAY_SLASH:-/auto-new-day:new-day}"
  for _u in auto-new-day-sweep.service auto-new-day-sweep.timer; do
    sed -e "s#__LAUNCHER__#$_launcher#g" \
      -e "s#__WORKING_ROOT__#$_wr#g" \
      -e "s#__STATE_DIR__#$_sd#g" \
      -e "s#__TZ__#$_tz#g" \
      -e "s#__SLASH__#$_slash#g" \
      "$SRC_DIR/$_u" >"$DST_DIR/$_u"
  done

  echo "==> reloading systemd"
  systemctl --user daemon-reload

  echo "==> enabling timer"
  systemctl --user enable --now auto-new-day-sweep.timer

  echo "==> next fire:"
  systemctl --user list-timers auto-new-day-sweep.timer --no-pager
  echo
  echo "done. test now with: $0 --dry-run"
  exit 0
fi

# --- show/set schedule mode (inspect or update timer, then exit) ---
TIMER_DST="$HOME/.config/systemd/user/auto-new-day-sweep.timer"
TIMER_SRC="$(cd "$(dirname "$0")/.." && pwd)/references/systemd/auto-new-day-sweep.timer"

if [ "$SHOW_TIME" = "1" ]; then
  if [ ! -f "$TIMER_DST" ]; then
    echo "ERROR: timer file not installed: $TIMER_DST" >&2
    echo "Run $0 --install first." >&2
    exit 1
  fi
  echo "Schedule (from $TIMER_DST):"
  grep -E '^OnCalendar=' "$TIMER_DST" | sed 's/^/  /'
  echo
  systemctl --user list-timers auto-new-day-sweep.timer --no-pager 2>/dev/null || true
  exit 0
fi

if [ -n "$SET_TIME" ]; then
  if ! printf '%s' "$SET_TIME" | grep -qE '^([01][0-9]|2[0-3]):[0-5][0-9]$'; then
    echo "ERROR: invalid HH:MM: $SET_TIME (expected 00:00..23:59)" >&2
    exit 1
  fi
  new_line="OnCalendar=Mon..Fri *-*-* ${SET_TIME}:00${AUTO_NEW_DAY_TZ:+ $AUTO_NEW_DAY_TZ}"
  changed=0
  for f in "$TIMER_DST" "$TIMER_SRC"; do
    if [ ! -f "$f" ]; then
      echo "warning: $f does not exist; skipping" >&2
      continue
    fi
    if ! grep -qE '^OnCalendar=' "$f"; then
      echo "warning: no OnCalendar= line in $f; skipping" >&2
      continue
    fi
    sed -i -E "s|^OnCalendar=.*|${new_line}|" "$f"
    echo "==> updated $f"
    changed=1
  done
  if [ "$changed" = "0" ]; then
    echo "ERROR: no timer files updated" >&2
    exit 1
  fi
  # Bump the Persistent stamp to now so e.g. changing the time at 10:00 to
  # "09:00" does not immediately fire today's missed-09:00 catch-up.
  stamp="$HOME/.local/share/systemd/timers/stamp-auto-new-day-sweep.timer"
  mkdir -p "$(dirname "$stamp")" 2>/dev/null || true
  touch "$stamp" 2>/dev/null || true
  systemctl --user daemon-reload
  systemctl --user restart auto-new-day-sweep.timer 2>/dev/null || true
  echo "==> next fire:"
  systemctl --user list-timers auto-new-day-sweep.timer --no-pager
  exit 0
fi

# --- session + log paths ---
SESSION=AUTO-new-day
[ "$DRY_RUN" = "1" ] && SESSION=AUTO-new-day-dryrun
LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/auto-new-day-sweep"
SWEEP_LOG="$LOG_DIR/sweep.log"
[ "$DRY_RUN" = "1" ] && SWEEP_LOG="$LOG_DIR/sweep-dryrun.log"
STATE_DIR="${AUTO_NEW_DAY_STATE_DIR:-$HOME/.local/state/auto-new-day}"
LOCK_FILE="$STATE_DIR/.sweep.lock"
SENTINEL_DIR="$LOG_DIR/sentinels"
mkdir -p "$LOG_DIR" "$STATE_DIR/dispatch" "$STATE_DIR/done" "$SENTINEL_DIR"

[ "$DRY_RUN" = "1" ] && log "DRY RUN: tmux session=$SESSION, log=$SWEEP_LOG"
[ "$FORCE" = "1" ]   && log "FORCE: ignoring per-repo dispatch markers"

# 1. Rotate the previous day's sweep log so the user gets a clean scrollback
#    each morning. Keep the last 7 daily rotations; older ones are deleted.
if [ -s "$SWEEP_LOG" ]; then
  mv -f "$SWEEP_LOG" "${SWEEP_LOG}.$(date -r "$SWEEP_LOG" +%F 2>/dev/null || date +%F).old"
fi
ls -1t "${SWEEP_LOG}".*.old 2>/dev/null | tail -n +8 | xargs -r rm -f --

# 2. Need a graphical session to render a terminal. Touch a sentinel so the
#    user's interactive shell can surface "the morning sweep had no DISPLAY"
#    on next login instead of failing silently.
if [ -z "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ]; then
  date -Iseconds > "$SENTINEL_DIR/NO_DISPLAY"
  log "no DISPLAY/WAYLAND_DISPLAY; skipping (no graphical session)"
  exit 0
fi
rm -f "$SENTINEL_DIR/NO_DISPLAY"

# 3. Preflight: every binary the sweep depends on must resolve under THIS
#    process's PATH (which is the systemd unit's PATH when fired from the
#    timer). Failing here writes a FAILED sentinel and exits non-zero so the
#    unit's exit status reflects reality, instead of opening an empty pane
#    nine hours later.
fail() {
  date -Iseconds > "$SENTINEL_DIR/FAILED"
  printf 'FAILED %s\n' "$*" >> "$SENTINEL_DIR/FAILED"
  log "ERROR: $*"
  exit 1
}
for bin in tmux jq git gh claude; do
  command -v "$bin" >/dev/null 2>&1 || fail "missing required binary: $bin (PATH=$PATH)"
done
rm -f "$SENTINEL_DIR/FAILED"

# 4. Pick terminal: $TERMINAL if set+available, otherwise kitty, then st.
term=${TERMINAL:-}
if [ -z "$term" ] || ! command -v "$term" >/dev/null 2>&1; then
  for cand in kitty st alacritty foot wezterm xterm; do
    if command -v "$cand" >/dev/null 2>&1; then term="$cand"; break; fi
  done
fi
if [ -z "$term" ] || ! command -v "$term" >/dev/null 2>&1; then
  fail "no terminal available (TERMINAL=${TERMINAL:-unset}, kitty/st/alacritty/foot/wezterm/xterm all missing)"
fi

# 5. Acquire a non-blocking lock so a manual `/auto-new-day` triggered while the
#    timer's sweep is still running can't double-write state.json. Holds the
#    lock for the lifetime of this script (released on exit).
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  log "another sweep is already running (lock: $LOCK_FILE); exiting"
  exit 0
fi
# Remove the lock file when the launcher exits cleanly. The FD-held flock
# survives unlink, so a racing second launcher's flock -n still correctly
# fails while we're alive; the file just isn't left lying around afterwards.
trap 'rm -f "$LOCK_FILE" 2>/dev/null || true' EXIT

# 6. Safe kill of the previous AUTO-new-day session. If yesterday's session
#    still has non-sweep windows (a manual mid-day re-run, or an ad-hoc
#    window the operator opened in it), DON'T destroy them; rename the
#    session aside so the user can `tmux attach -t AUTO-new-day-prev-<date>`
#    later. Today's sweep then gets a clean session.
if tmux has-session -t "$SESSION" 2>/dev/null; then
  non_sweep=$(tmux list-windows -t "$SESSION" -F '#{window_name}' 2>/dev/null | grep -vxE 'sweep|placeholder' | wc -l | tr -d ' ')
  if [ "${non_sweep:-0}" -gt 0 ]; then
    archive="${SESSION}-prev-$(date +%F-%H%M)"
    log "previous $SESSION has $non_sweep non-sweep window(s); renaming to $archive"
    tmux rename-session -t "$SESSION" "$archive" || true
  else
    log "killing stale $SESSION (no in-flight work)"
    tmux kill-session -t "$SESSION" 2>/dev/null || true
  fi
fi

# 7. Plan: start claude INTERACTIVELY (no prompt arg) inside the pane, then
#    type the slash command into claude's prompt via a second send-keys.
#    Rationale: passing the slash command as a positional arg to claude
#    makes it run as a one-shot and exit when the prompt completes. We want
#    claude to STAY OPEN after the sweep finishes so the operator can ask
#    follow-up questions or just read the report. If the operator manually
#    closes claude (/exit, Ctrl-D), control returns to the pane's default
#    shell — combined with `remain-on-exit on` and the pane process being
#    just a regular shell, the pane stays as a usable terminal.
#
#    NOTE: do not pipe claude's stdout (e.g. `| tee`) — claude detects
#    non-TTY and skips its interactive TUI, which manifests as a "frozen"
#    pane. Logging is done out-of-band via `tmux pipe-pane` below, which
#    captures pane output without breaking the pane's TTY-ness.
SLASH_CMD="${AUTO_NEW_DAY_SLASH:-/auto-new-day:new-day}"
[ "$DRY_RUN" = "1" ] && SLASH_CMD="$SLASH_CMD --dry-run"
[ "$FORCE" = "1" ]   && SLASH_CMD="$SLASH_CMD --force"
if [ -n "$DATE_PHRASE" ]; then
  # Validate the date phrase BEFORE we spawn anything; resolve-date.sh prints
  # a usage hint on stderr and exits 1 if it can't parse.
  RESOLVED_DATE=$("$(dirname "$0")/resolve-date.sh" $DATE_PHRASE) \
    || fail "bad date phrase: $DATE_PHRASE"
  SLASH_CMD="$SLASH_CMD --date $RESOLVED_DATE"
  log "date replay requested: $DATE_PHRASE -> $RESOLVED_DATE"
fi

# 8. Create the session detached, wire the log via pipe-pane, wait briefly
#    for the pane's shell to draw its prompt, then start claude interactively.
#    Wait again for claude's TUI to render before sending the slash command.
#    The short sleeps avoid races where send-keys fires before readline (or
#    claude's input loop) is ready and the leading keystrokes get eaten.
log "creating tmux session $SESSION; piping pane to $SWEEP_LOG"
tmux new-session -d -s "$SESSION" -c "${AUTO_NEW_DAY_WORKING_ROOT:-$PWD}" -n sweep \
  || fail "tmux new-session $SESSION failed"
tmux set-option -t "$SESSION" remain-on-exit on >/dev/null 2>&1 || true
tmux pipe-pane -t "${SESSION}:sweep" -o "cat >> '$SWEEP_LOG'" \
  || fail "tmux pipe-pane to $SWEEP_LOG failed"
sleep 0.3
# Verified on claude v2.1.140: passing the slash command as a positional argv
# (`claude "/slash ..."`) launches claude with the prompt pre-filled, claude
# runs the slash command, and STAYS INTERACTIVE afterwards (older notes about
# argv being "one-shot" were wrong for current versions). This avoids the
# bracketed-paste race in two-step send-keys (where the first Enter closes
# the paste without submitting). Using send-keys to type the launch command
# is still required so the shell-fallthrough on claude-exit works.
tmux send-keys -t "${SESSION}:sweep" "claude --dangerously-skip-permissions \"$SLASH_CMD\"" C-m \
  || fail "tmux send-keys (claude + slash argv) to $SESSION:sweep failed"

# 9. Attach via the terminal. kitty takes the command as positional args;
#    everything else (st, alacritty, foot, wezterm, xterm) takes -e. Don't
#    `exec` — we want this script to exit cleanly so systemd marks the unit
#    finished after launch, instead of "active" for the entire day while the
#    terminal window is open. Run the terminal in the background and detach.
log "launching $term attached to $SESSION"
case "$(basename "$term")" in
  kitty)
    setsid "$term" --title "auto-new-day-sweep" tmux attach -t "$SESSION" </dev/null >/dev/null 2>&1 &
    ;;
  *)
    setsid "$term" -e tmux attach -t "$SESSION" </dev/null >/dev/null 2>&1 &
    ;;
esac
disown 2>/dev/null || true
exit 0
