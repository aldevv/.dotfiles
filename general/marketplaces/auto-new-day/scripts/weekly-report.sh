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

# rebuild_slack <weekfile>
# Regenerate the "## Slack summary" section at the bottom of the week file: a
# single fenced code block (so mdp renders a copy button) holding two plain-text
# lists with NO day headings — "Done this week:" (every "Worked on" bullet) and
# "Code reviews:" (every "Reviewed teammate PRs" bullet), deduped, markdown links
# flattened to their text. Idempotent: strips any prior Slack section first.
rebuild_slack() {
	local wf="$1"
	[ -f "$wf" ] || return 0
	command -v python3 >/dev/null 2>&1 || return 0
	WR_FILE="$wf" python3 - <<'PY' 2>/dev/null || true
import os, re
wf = os.environ["WR_FILE"]
lines = open(wf).read().splitlines()

# Drop any existing Slack section (from its heading to EOF).
cut = len(lines)
for i, l in enumerate(lines):
    if l.strip() == "## Slack summary":
        cut = i
        break
body = lines[:cut]

DAY = re.compile(r"^- \*\*\d{4}-\d{2}-\d{2}")   # "- **2026-07-17 (Fri)**"

def flatten(s):
    s = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", s)        # [text](url) -> text
    return s.strip()

def key_of(item, section):
    # "Done" is ticket-scoped (one work item per ticket, so an in-progress line
    # and its later merged line collapse to one). "Code reviews" is PR-scoped
    # (two PRs on one ticket stay separate). Fall back to repo#n, then full text.
    if section == "done":
        m = re.search(r"\b[A-Z][A-Z0-9]+-\d+\b", item)   # any TRACKER-123 ticket id
        if m:
            return m.group(0)
    m = re.search(r"[A-Za-z0-9._-]+#\d+", item)
    return m.group(0) if m else item

# order[section] preserves first-seen key order; seen[section][key] holds the
# latest text for that key (a re-review or later day wins the wording).
order = {"done": [], "reviews": []}
seen = {"done": {}, "reviews": {}}
section = None
for l in body:
    s = l.strip()
    if s == "- **Worked on:**":
        section = "done"; continue
    if s == "- **Reviewed teammate PRs:**":
        section = "reviews"; continue
    if DAY.match(s):
        section = None; continue
    if s.startswith("- **") and s.endswith(":**"):   # any other subheading
        section = None; continue
    if section and s.startswith("- "):
        raw = s[2:]
        if section == "reviews":
            # Code reviews are the PR link only, as Slack mrkdwn <url|repo#N>
            # (no author, no description). Skip a review with no PR link.
            m = re.search(r"\[([^\]]+)\]\((https?://[^)]+)\)", raw)
            if m:
                text, url = m.group(1), m.group(2)
            else:
                u = re.search(r"(https?://\S+)", raw)
                if not u:
                    continue
                url = u.group(1)
                t = re.search(r"[A-Za-z0-9._-]+#\d+", raw)
                text = t.group(0) if t else url
            item, k = f"[{text}]({url})", url
        else:
            # Worked-on: link the PR as a markdown link [repo#N](url) (Slack's
            # composer converts pasted markdown links; the API-only <url|text>
            # form does NOT render on a human paste) and keep the description; a
            # one-off (no PR link) stays plain text.
            m = re.search(r"\[([^\]]+)\]\((https?://[^)]+)\)", raw)
            if m:
                text, url = m.group(1), m.group(2)
                rest = re.sub(r"\s{2,}", " ", flatten(raw[:m.start()] + raw[m.end():])).strip()
                item = f"[{text}]({url}) {rest}".strip()
            else:
                item = flatten(raw)
            if not item:
                continue
            k = key_of(item, section)
        if k not in seen[section]:
            order[section].append(k)
        seen[section][k] = item

done = [seen["done"][k] for k in order["done"]]
reviews = [seen["reviews"][k] for k in order["reviews"]]

# One-offs = Done items that are not pull requests (no repo#n): ad-hoc or
# unexpected work. Listed before the PR items, and one-offs sharing a leading
# word collapse onto one line ("<word> a" + "<word> b" -> "<word> a, b").
oneoffs, prs = [], []
for it in done:
    (prs if re.search(r"[A-Za-z0-9._-]+#\d+", it) else oneoffs).append(it)
grouped, tails = [], {}
for it in oneoffs:
    parts = it.split(None, 1)
    head, tail = parts[0], (parts[1] if len(parts) > 1 else "")
    if head not in tails:
        tails[head] = []
        grouped.append(head)
    if tail:
        tails[head].append(tail)
oneoff_lines = [f"{h} {', '.join(tails[h])}" if tails[h] else h for h in grouped]
done = oneoff_lines + prs

out = list(body)
while out and out[-1].strip() == "":
    out.pop()
out += ["", "## Slack summary", "", "```text"]
out.append("Done this week:")
out += [f"- {x}" for x in done] or ["- (nothing yet)"]
out += ["", "Code reviews:"]
out += [f"- {x}" for x in reviews] or ["- (none yet)"]
out.append("```")
open(wf, "w").write("\n".join(out) + "\n")
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

	rebuild_slack "$WF"
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
	rebuild_slack "$WF"
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
	# In-terminal viewer: neovim (the operator's editor) when present, else a less
	# pager. MDP_TARGET is exported for the less lesskey M-binding fallback.
	local VIEWER
	if command -v nvim >/dev/null 2>&1; then
		VIEWER="nvim '$WF'"
	else
		VIEWER="less -R '$WF'"
	fi
	# Window command: render in mdp (best-effort browser), open the file in the
	# viewer, then drop to an interactive shell so the window stays usable.
	local WINCMD="zsh -lc \"export MDP_TARGET='$WF'; ${MDP_CALL}${VIEWER}; exec \${SHELL:-zsh} -i\""

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

# cmd_mdp / cmd_open: open a week file directly in one viewer. `mdp <date>`
# renders it in mdp (browser); `open <date>` edits it in neovim. Date is
# optional (defaults to today's week file).
cmd_mdp() {
	local WF
	WF=$(week_file_for_date "${1:-$(date +%F)}") || die "bad date '${1:-}'"
	[ -f "$WF" ] || die "week file not found: $WF"
	command -v mdp >/dev/null 2>&1 || die "mdp not found on PATH"
	mdp "$WF"
}
cmd_open() {
	local WF
	WF=$(week_file_for_date "${1:-$(date +%F)}") || die "bad date '${1:-}'"
	[ -f "$WF" ] || die "week file not found: $WF"
	command -v nvim >/dev/null 2>&1 || die "nvim not found on PATH"
	exec nvim "$WF"
}
# cmd_generate: rebuild a week file from the durable per-day dispatch manifests
# (`$DATES_DIR/<DATE>/dispatch/*.json` that have a sibling `*.done.json`, i.e.
# work that actually completed). Recovery tool for a lost/corrupt week file.
# Own-work payloads (have a `ticket`) become "Worked on" lines; `review-*`
# payloads become "Reviewed teammate PRs" links. Best-effort: bullets use the
# PR title, and free one-offs (non-PR work with no manifest) are NOT
# recoverable. Rebuilds the Slack section at the end. Overwrites the week file.
cmd_generate() {
	local DATE="${1:-$(date +%F)}" WF
	WF=$(week_file_for_date "$DATE") || die "bad date '$DATE'"
	command -v python3 >/dev/null 2>&1 || die "python3 required"
	local DOW MON DATES_DIR
	DATES_DIR="${AUTO_NEW_DAY_STATE_DIR:-$HOME/.local/state/auto-new-day}/dates"
	DOW=$(date -d "$DATE" +%u 2>/dev/null || echo 1)
	MON=$(date -d "$DATE -$((DOW - 1)) days" +%Y-%m-%d)
	WR_WF="$WF" WR_MON="$MON" WR_DATES="$DATES_DIR" python3 - <<'PY' || die "generate failed"
import os, re, json, glob, datetime
wf   = os.environ["WR_WF"]
mon  = datetime.date.fromisoformat(os.environ["WR_MON"])
root = os.environ["WR_DATES"]

def repo_n(url):
    m = re.search(r"github\.com/[^/]+/([^/]+)/pull/(\d+)", url or "")
    return f"{m.group(1)}#{m.group(2)}" if m else None

# Items the operator marked skipped (a done/<key>.done.json with
# outcome=="skipped") never belong in the weekly report.
done_dir = os.path.join(os.path.dirname(root), "done")
def is_skipped(key):
    for fn in (f"{key}.done.json", f"{key}.json"):
        p = os.path.join(done_dir, fn)
        if os.path.exists(p):
            try:
                if (json.load(open(p)) or {}).get("outcome") == "skipped":
                    return True
            except Exception:
                pass
    return False

lines = [f"# Weekly report — week of {mon.isoformat()}"]
for i in range(7):
    d = (mon + datetime.timedelta(days=i)).isoformat()
    dd = os.path.join(root, d, "dispatch")
    if not os.path.isdir(dd):
        continue
    worked, reviews = [], []
    for pj in sorted(glob.glob(os.path.join(dd, "*.json"))):
        if pj.endswith(".done.json"):
            continue
        base = pj[:-5]
        if not os.path.exists(base + ".done.json"):
            continue                                  # only completed work
        try:
            p = json.load(open(pj))
        except Exception:
            continue
        name = os.path.basename(base)
        key = name[len("review-"):] if name.startswith("review-") else name
        if is_skipped(key):
            continue
        pr = p.get("prUrl") or ""
        rn = repo_n(pr)
        if name.startswith("review-"):
            if rn and pr:
                reviews.append(f"    - [{rn}]({pr})")
        else:
            title = p.get("title") or p.get("prTitle") or ""
            ticket = p.get("ticket") or ""
            iu = p.get("issueUrl") or p.get("linearUrl") or ""
            if rn and pr:
                head = f"[{rn}]({pr})"
            elif ticket and iu:
                head = f"[{ticket}]({iu})"
            else:
                head = title or name
            suffix = f" ([{ticket}]({iu}))" if ticket and iu and rn else ""
            worked.append(f"    - {head} {title}{suffix}".rstrip())
    if not worked and not reviews:
        continue
    wd = (mon + datetime.timedelta(days=i)).strftime("%a")
    lines += ["", f"- **{d} ({wd})**"]
    if worked:
        lines.append("  - **Worked on:**"); lines += worked
    if reviews:
        lines.append("  - **Reviewed teammate PRs:**"); lines += reviews
open(wf, "w").write("\n".join(lines) + "\n")
print(wf)
PY
	rebuild_slack "$WF"
	printf '%s\n' "$WF"
}

# cmd_path: print the week file's path (for `$(weekly-report.sh path)`). Prints
# the resolved path whether or not the file exists yet.
cmd_path() {
	local WF
	WF=$(week_file_for_date "${1:-$(date +%F)}") || die "bad date '${1:-}'"
	printf '%s\n' "$WF"
}

SUB=${1:-}
shift 2>/dev/null || true
case "$SUB" in
upsert) cmd_upsert "$@" ;;
add-item) cmd_add_item "$@" ;;
show) cmd_show "$@" ;;
slack) rebuild_slack "$(week_file_for_date "${1:-$(date +%F)}")" ;;
mdp) cmd_mdp "$@" ;;
open) cmd_open "$@" ;;
path) cmd_path "$@" ;;
generate) cmd_generate "$@" ;;
report-day) report_day_for_week "${1:-$(date +%F)}" ;;
*) die "usage: weekly-report.sh {upsert|add-item|show|slack|mdp|open|path|generate|report-day} ..." ;;
esac
