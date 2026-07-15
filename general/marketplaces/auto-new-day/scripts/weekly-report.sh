#!/usr/bin/env bash
# weekly-report.sh
# Maintains a rolling, management-facing weekly summary of what the auto-new-day
# sweep did, and surfaces it in the AUTO_weekly_report tmux session via mdp.
#
# The weekly file is high-level ONLY: one dated section per sweep, plain
# bullets of what was done (fixes dispatched, reviews done, PRs approved/merged,
# new work started). No implementation detail, no file paths, no ticket bodies.
#
# One file per ISO week: ~/work/.auto-new-day/weekly/<ISO-year>-W<ISO-week>.md
#
# Subcommands:
#   upsert --date <YYYY-MM-DD> [--bullets-file <f>]
#       Upsert (idempotent, keyed by date heading) a section for <date> into
#       that date's ISO-week file. Bullets come from --bullets-file or stdin,
#       one markdown bullet per line ("- ..."). Re-running for the same date
#       REPLACES that date's section (so same-day re-runs never duplicate).
#       Prints the absolute week-file path on stdout.
#
#   show [--date <YYYY-MM-DD>] [--file <path>] [--no-mdp]
#       Open (or refresh) the AUTO_weekly_report tmux session with one window
#       that renders the week file in mdp (browser, best-effort) AND shows it
#       in a less pager (with MDP_TARGET set so the operator can re-render with
#       the lesskey M-binding). --date resolves the week file; --file overrides.
#       --no-mdp skips the browser render (kept in-terminal only).
#
# Best-effort and idempotent. Never aborts the sweep: on any internal error it
# prints a one-line warning to stderr and exits 0 (except on bad args -> exit 1).

set -u

ROOT="${AUTO_NEW_DAY_STATE_DIR:-$HOME/.local/state/auto-new-day}/weekly"
SESSION="AUTO_weekly_report"

warn() { echo "weekly-report: $*" >&2; }
die() {
	echo "weekly-report: $*" >&2
	exit 1
}

week_file_for_date() {
	local d="$1" iso
	iso=$(date -d "$d" +%G-W%V 2>/dev/null) || return 1
	printf '%s/%s-report.md\n' "$ROOT" "$iso"
}

# report_day_for_week <YYYY-MM-DD> -> the weekday (YYYY-MM-DD) the weekly readout
# should auto-open on: normally Friday, but the last non-holiday weekday of the
# week when Friday (and/or earlier days) are US federal OR Colombian public
# holidays (e.g. Good Friday, which lands Friday with Maundy Thursday the day
# before, walks the readout back to Wednesday). Falls back to plain Friday if
# python3 is unavailable.
report_day_for_week() {
	local today="$1"
	if ! command -v python3 >/dev/null 2>&1; then
		date -d "$today -$(($(date -d "$today" +%u) - 5)) days" +%F 2>/dev/null || echo "$today"
		return
	fi
	python3 - "$today" <<'PY'
import sys, datetime
def nth_weekday(y, m, wd, n):
    d = datetime.date(y, m, 1)
    return d + datetime.timedelta(days=(wd - d.weekday()) % 7 + 7 * (n - 1))
def last_weekday(y, m, wd):
    nm = datetime.date(y + 1, 1, 1) if m == 12 else datetime.date(y, m + 1, 1)
    d = nm - datetime.timedelta(days=1)
    return d - datetime.timedelta(days=(d.weekday() - wd) % 7)
def observed(d):
    r = {d}
    if d.weekday() == 5: r.add(d - datetime.timedelta(days=1))   # Sat -> Fri
    elif d.weekday() == 6: r.add(d + datetime.timedelta(days=1)) # Sun -> Mon
    return r
def us_holidays(y):
    hs = set()
    for m, day in [(1, 1), (6, 19), (7, 4), (11, 11), (12, 25)]:
        hs |= observed(datetime.date(y, m, day))
    hs |= {nth_weekday(y, 1, 0, 3), nth_weekday(y, 2, 0, 3), last_weekday(y, 5, 0),
           nth_weekday(y, 9, 0, 1), nth_weekday(y, 10, 0, 2), nth_weekday(y, 11, 3, 4)}
    return hs
def easter(y):
    a = y % 19; b = y // 100; c = y % 100; d = b // 4; e = b % 4
    f = (b + 8) // 25; g = (b - f + 1) // 3
    h = (19 * a + b - d - g + 15) % 30; i = c // 4; k = c % 4
    l = (32 + 2 * e + 2 * i - h - k) % 7; m = (a + 11 * h + 22 * l) // 451
    mo = (h + l - 7 * m + 114) // 31; da = ((h + l - 7 * m + 114) % 31) + 1
    return datetime.date(y, mo, da)
def co_holidays(y):
    # Colombian holidays that can land on Fri/Thu: fixed-date (not moved to
    # Monday) + Maundy Thursday + Good Friday. Emiliani-law holidays always land
    # on Monday, so they never affect a Fri->Thu shift and are omitted.
    hs = {datetime.date(y, m, d) for m, d in [(1, 1), (5, 1), (7, 20), (8, 7), (12, 8), (12, 25)]}
    ea = easter(y)
    hs |= {ea - datetime.timedelta(days=3), ea - datetime.timedelta(days=2)}
    return hs
def holidays(y):
    return us_holidays(y) | co_holidays(y)
today = datetime.date.fromisoformat(sys.argv[1])
monday = today - datetime.timedelta(days=today.weekday())
friday = monday + datetime.timedelta(days=4)
hol = holidays(monday.year) | holidays(friday.year)
d, target = friday, friday
while d >= monday:
    if d not in hol:
        target = d; break
    d -= datetime.timedelta(days=1)
print(target.isoformat())
PY
}

cmd_upsert() {
	local DATE="" BULLETS_FILE=""
	while [ $# -gt 0 ]; do
		case "$1" in
		--date)
			shift
			DATE=${1:-}
			;;
		--bullets-file)
			shift
			BULLETS_FILE=${1:-}
			;;
		*) die "upsert: unknown arg $1" ;;
		esac
		shift
	done
	[ -n "$DATE" ] || die "upsert: --date required"

	local WF
	WF=$(week_file_for_date "$DATE") || {
		warn "bad date '$DATE'"
		exit 0
	}
	mkdir -p "$ROOT" 2>/dev/null || {
		warn "cannot mkdir $ROOT"
		exit 0
	}

	# bullets: from file or stdin
	local BULLETS
	if [ -n "$BULLETS_FILE" ]; then
		[ -f "$BULLETS_FILE" ] || {
			warn "bullets file not found: $BULLETS_FILE"
			exit 0
		}
		BULLETS=$(cat "$BULLETS_FILE")
	else
		BULLETS=$(cat)
	fi
	[ -n "$BULLETS" ] || BULLETS="- (no dispatchable work this sweep)"

	local WEEKDAY MON_START
	WEEKDAY=$(date -d "$DATE" +%a 2>/dev/null || echo "")
	# Monday of that ISO week (for the header)
	local DOW
	DOW=$(date -d "$DATE" +%u 2>/dev/null || echo 1)
	MON_START=$(date -d "$DATE -$((DOW - 1)) days" +%Y-%m-%d 2>/dev/null || echo "$DATE")

	# Create the file with a plain, copy-pastable title if missing.
	if [ ! -f "$WF" ]; then
		printf '# Weekly report — week of %s\n' "$MON_START" >"$WF"
	fi

	# Each day is a top-level bullet; the day's entries are nested sub-bullets.
	local HEADING="- **$DATE (${WEEKDAY})**"
	local TMP
	TMP=$(mktemp) || {
		warn "mktemp failed"
		exit 0
	}
	# Drop any existing section for this date: from its `- **DATE**` line up to
	# the next day bullet (also `- **`) or EOF. Sub-bullets are indented (`  -`)
	# so they never match the section delimiter.
	awk -v h="$HEADING" '
    BEGIN { skip=0 }
    /^- \*\*/ {
      if ($0 == h) { skip=1; next }
      else if (skip==1) { skip=0 }
    }
    { if (skip==0) print }
  ' "$WF" >"$TMP" 2>/dev/null || {
		warn "awk upsert failed"
		rm -f "$TMP"
		exit 0
	}

	# Indent every non-empty bullet line by two spaces so it nests under the day.
	local NESTED
	NESTED=$(printf '%s\n' "$BULLETS" | awk '{ if (length($0)) print "  " $0; else print "" }')

	{
		# trim trailing blank lines from the kept content, then re-add exactly one
		# blank line before the new day group (keeps the file clean across re-runs)
		awk 'NF{last=NR} {line[NR]=$0} END{for(i=1;i<=last;i++) print line[i]}' "$TMP"
		printf '\n%s\n%s\n' "$HEADING" "$NESTED"
	} >"$WF" 2>/dev/null || {
		warn "write failed"
		rm -f "$TMP"
		exit 0
	}
	rm -f "$TMP"

	printf '%s\n' "$WF"
}

# cmd_add_item: idempotent single-bullet merge into a day's section, keyed by a
# stable substring (the PR/issue URL). Unlike upsert (which REPLACES the whole
# day section), this MERGES one bullet under a named subheading, so several
# dispatched skills can each record their own line on the same day without
# clobbering each other. Re-running with the same --key updates that bullet in
# place. Creates the file, the day heading, and the subheading as needed.
cmd_add_item() {
	local DATE="" SECTION="" KEY="" BULLET=""
	while [ $# -gt 0 ]; do
		case "$1" in
		--date) shift; DATE=${1:-} ;;
		--section) shift; SECTION=${1:-} ;;
		--key) shift; KEY=${1:-} ;;
		--bullet) shift; BULLET=${1:-} ;;
		*) die "add-item: unknown arg $1" ;;
		esac
		shift
	done
	[ -n "$DATE" ] || die "add-item: --date required"
	[ -n "$SECTION" ] || die "add-item: --section required"
	[ -n "$BULLET" ] || die "add-item: --bullet required"
	command -v python3 >/dev/null 2>&1 || {
		warn "python3 not found; skipping add-item"
		exit 0
	}

	local WF
	WF=$(week_file_for_date "$DATE") || { warn "bad date '$DATE'"; exit 0; }
	mkdir -p "$ROOT" 2>/dev/null || { warn "cannot mkdir $ROOT"; exit 0; }

	local WEEKDAY DOW MON_START
	WEEKDAY=$(date -d "$DATE" +%a 2>/dev/null || echo "")
	DOW=$(date -d "$DATE" +%u 2>/dev/null || echo 1)
	MON_START=$(date -d "$DATE -$((DOW - 1)) days" +%Y-%m-%d 2>/dev/null || echo "$DATE")

	WR_FILE="$WF" WR_DATE="$DATE" WR_WEEKDAY="$WEEKDAY" WR_MON="$MON_START" \
		WR_SECTION="$SECTION" WR_KEY="$KEY" WR_BULLET="$BULLET" \
		python3 - <<'PY' || { warn "add-item merge failed"; exit 0; }
import os, io

wf   = os.environ["WR_FILE"]
date = os.environ["WR_DATE"]
wkd  = os.environ["WR_WEEKDAY"]
mon  = os.environ["WR_MON"]
sec  = os.environ["WR_SECTION"]
key  = os.environ.get("WR_KEY", "")
bul  = os.environ["WR_BULLET"]

heading = f"- **{date} ({wkd})**"
sub     = f"  - **{sec}:**"
item    = f"    - {bul}"
placeholder = "- (no dispatchable work this sweep)"

try:
    with open(wf) as f:
        lines = f.read().splitlines()
except FileNotFoundError:
    lines = [f"# Weekly report — week of {mon}"]

def is_day(l):  return l.startswith("- **")
def is_sub(l):  return l.startswith("  - **")

# canonical subheading order within a day: Worked on always before reviews.
SECTION_ORDER = ["Worked on", "Reviewed teammate PRs"]
def rank(title):
    return SECTION_ORDER.index(title) if title in SECTION_ORDER else len(SECTION_ORDER)

# locate (or create) the day block
try:
    h = lines.index(heading)
except ValueError:
    while lines and lines[-1].strip() == "":
        lines.pop()
    if lines:
        lines.append("")
    lines += [heading, sub, item]
    with open(wf, "w") as f:
        f.write("\n".join(lines) + "\n")
    print(wf)
    raise SystemExit(0)

end = len(lines)
for i in range(h + 1, len(lines)):
    if is_day(lines[i]):
        end = i
        break

# drop the "(no dispatchable work)" placeholder once real work lands
kept = [l for l in lines[h + 1:end] if l.strip() != placeholder]
lines[h + 1:end] = kept
end = h + 1 + len(kept)

# locate (or create) the subheading within the day block
sub_idx = None
for i in range(h + 1, end):
    if lines[i].strip() == f"- **{sec}:**":
        sub_idx = i
        break
if sub_idx is None:
    # insert the new subheading in canonical order: before the first existing
    # subheading that ranks after it (so "Worked on" lands above reviews).
    newrank = rank(sec)
    at = None
    for i in range(h + 1, end):
        s = lines[i].strip()
        if s.startswith("- **") and s.endswith(":**") and rank(s[4:-3]) > newrank:
            at = i
            break
    if at is None:
        at = end
        while at - 1 > h and lines[at - 1].strip() == "":
            at -= 1
    lines[at:at] = [sub, item]
    with open(wf, "w") as f:
        f.write("\n".join(lines) + "\n")
    print(wf)
    raise SystemExit(0)

# find the end of this subheading's sub-block
sub_end = end
for i in range(sub_idx + 1, end):
    if is_sub(lines[i]) or is_day(lines[i]):
        sub_end = i
        break

# update in place when the key already appears, else append
found = None
if key:
    for i in range(sub_idx + 1, sub_end):
        if key in lines[i]:
            found = i
            break
if found is not None:
    lines[found] = item
else:
    at = sub_end
    while at - 1 > sub_idx and lines[at - 1].strip() == "":
        at -= 1
    lines[at:at] = [item]

with open(wf, "w") as f:
    f.write("\n".join(lines) + "\n")
print(wf)
PY
}

cmd_show() {
	local DATE="" FILE="" DO_MDP=1 ONLY_FRIDAY=0
	while [ $# -gt 0 ]; do
		case "$1" in
		--date)
			shift
			DATE=${1:-}
			;;
		--file)
			shift
			FILE=${1:-}
			;;
		--no-mdp) DO_MDP=0 ;;
		--if-friday) ONLY_FRIDAY=1 ;;
		*) die "show: unknown arg $1" ;;
		esac
		shift
	done

	# --if-friday: auto-open gate for the daily sweep. Opens on the week's report
	# day (normally Friday; the last non-holiday weekday when Friday is a US
	# federal holiday, e.g. Thursday). No-op the rest of the week. Manual `show`
	# (without the flag) always opens. Day computed in America/Bogota.
	if [ "$ONLY_FRIDAY" = "1" ]; then
		local TODAY_LOCAL TARGET_DAY
		if [ -n "${AUTO_NEW_DAY_TZ:-}" ]; then
			TODAY_LOCAL=$(TZ="$AUTO_NEW_DAY_TZ" date +%F 2>/dev/null || date +%F)
		else
			TODAY_LOCAL=$(date +%F)
		fi
		TARGET_DAY=$(report_day_for_week "$TODAY_LOCAL")
		if [ "$TODAY_LOCAL" != "$TARGET_DAY" ]; then
			echo "weekly-report: not the weekly report day (target $TARGET_DAY), skipping auto-open"
			exit 0
		fi
	fi

	local WF="$FILE"
	if [ -z "$WF" ]; then
		[ -n "$DATE" ] || DATE=$(date +%Y-%m-%d)
		WF=$(week_file_for_date "$DATE") || {
			warn "bad date '$DATE'"
			exit 0
		}
	fi
	[ -f "$WF" ] || {
		warn "week file not found: $WF"
		exit 0
	}

	command -v tmux >/dev/null 2>&1 || {
		warn "tmux not found; skipping show"
		exit 0
	}

	local MDP_CALL=""
	if [ "$DO_MDP" = "1" ] && command -v mdp >/dev/null 2>&1; then
		MDP_CALL="mdp '$WF' >/dev/null 2>&1 || true; "
	fi
	# Window command: render in mdp (best-effort browser), then park in a less
	# pager (MDP_TARGET lets the lesskey M-binding re-render the original file),
	# then drop to an interactive shell so the window stays usable.
	local WINCMD="zsh -lc \"export MDP_TARGET='$WF'; ${MDP_CALL}less -R '$WF'; exec \${SHELL:-zsh} -i\""

	if ! tmux has-session -t "$SESSION" 2>/dev/null; then
		tmux new-session -d -s "$SESSION" -n weekly "$WINCMD" &&
			echo "weekly-report: opened $SESSION" ||
			warn "failed to create $SESSION"
	else
		# Refresh in place with respawn-window -k. Killing the only window would
		# destroy the session, so we restart the pane command instead.
		if tmux respawn-window -k -t "$SESSION:weekly" "$WINCMD" 2>/dev/null; then
			echo "weekly-report: refreshed $SESSION"
		else
			tmux new-window -t "$SESSION" -n weekly "$WINCMD" 2>/dev/null &&
				echo "weekly-report: refreshed $SESSION (new window)" ||
				warn "failed to refresh $SESSION"
		fi
	fi
}

SUB=${1:-}
shift 2>/dev/null || true
case "$SUB" in
upsert) cmd_upsert "$@" ;;
add-item) cmd_add_item "$@" ;;
show) cmd_show "$@" ;;
report-day) report_day_for_week "${1:-$(date +%F)}" ;;
*) die "usage: weekly-report.sh {upsert|add-item|show|report-day} ..." ;;
esac
