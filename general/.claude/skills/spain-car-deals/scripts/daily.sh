#!/usr/bin/env bash
# Daily run: headless claude runs the skill in daily mode, which writes the report; this script mails it.
set -uo pipefail

GMAIL="$HOME/.claude/skills/personal-manage/scripts/gmail.js"
OUT="$HOME/.cache/spain-car-deals"
TODAY=$(date +%F)
BODY="$OUT/report-$TODAY.txt"
TABLE="$OUT/report-$TODAY.html"
LOG="$OUT/log-$TODAY.txt"

mkdir -p "$OUT"
cd "$HOME" && claude -p "/spain-car-deals daily" --dangerously-skip-permissions --model opus >"$LOG" 2>&1

if [ ! -s "$BODY" ]; then
	printf 'The daily car search wrote no report. Last output:\n\n%s\n' "$(tail -20 "$LOG")" >"$BODY"
fi

attachments=()
[ -s "$TABLE" ] && attachments+=("$TABLE")

export PWCORE
PWCORE=$(ls -d "$HOME"/.npm/_npx/*/node_modules/playwright-core | tail -1)
MAIL_PORT=9398
MAIL_PROFILE="$OUT/gmail-profile"

close_mail_browser() {
	node -e "require(process.env.PWCORE).chromium.connectOverCDP('http://localhost:$MAIL_PORT',{timeout:10000}).then(async b=>{await (await b.newBrowserCDPSession()).send('Browser.close')}).catch(()=>{}).finally(()=>process.exit(0))"
}

start_mail_browser() {
	close_mail_browser
	rsync -a --delete --exclude 'Singleton*' --exclude '*Cache*' --exclude 'Service Worker' \
		"$HOME/.cache/ms-playwright/personal-gmail/" "$MAIL_PROFILE/"
	setsid nohup /opt/google/chrome/chrome --user-data-dir="$MAIL_PROFILE" --remote-debugging-port=$MAIL_PORT \
		--no-first-run --no-default-browser-check --headless=new about:blank >/dev/null 2>&1 &
	for _ in $(seq 30); do curl -s "localhost:$MAIL_PORT/json/version" >/dev/null && return; sleep 0.5; done
}

send_mail() {
	cd "$HOME" && GMAIL_CDP_PORT=$MAIL_PORT timeout 300 direnv exec "$HOME" bash -c 'node "$1" send --to "$PERSONAL_EMAIL" --subject "$2" --body "$(cat "$3")" "${@:4}"' _ \
		"$GMAIL" "Car deals Madrid $TODAY" "$BODY" "${attachments[@]}" >>"$LOG" 2>&1
}

already_sent() {
	cd "$HOME" && GMAIL_CDP_PORT=$MAIL_PORT timeout 120 direnv exec "$HOME" node "$GMAIL" search "in:sent subject:\"Car deals Madrid $TODAY\"" 1 2>/dev/null | grep -q "Car deals Madrid $TODAY"
}

NTFY="$HOME/.claude/skills/ntfy-manage/scripts/ntfy-manage"
start_mail_browser
trap close_mail_browser EXIT
if ! { send_mail || { sleep 60; already_sent || send_mail; }; }; then
	head -c 1500 "$BODY" | "$NTFY" send -t "car deals: email failed, report in $OUT" -p high >/dev/null
	exit 1
fi
