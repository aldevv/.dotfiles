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
send_mail() {
	cd "$HOME" && timeout 300 direnv exec "$HOME" bash -c 'node "$1" send --to "$PERSONAL_EMAIL" --subject "$2" --body "$(cat "$3")" "${@:4}"' _ \
		"$GMAIL" "Car deals Madrid $TODAY" "$BODY" "${attachments[@]}" >>"$LOG" 2>&1
}

already_sent() {
	cd "$HOME" && timeout 120 direnv exec "$HOME" node "$GMAIL" search "in:sent subject:\"Car deals Madrid $TODAY\"" 1 2>/dev/null | grep -q "Car deals Madrid $TODAY"
}

send_mail || { sleep 60; already_sent || send_mail; }
