#!/usr/bin/env bash
#
# Shared helpers for show-id.sh and show-summary.sh. Sourced, not executed.
#
# The caller must set $self to its own absolute path before calling pick_id,
# because fzf's preview re-invokes the caller as `<self> --preview <id>`.

cfg="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
# Claude Code slugs the cwd by turning every non-alphanumeric char into '-'
slug=$(pwd | sed 's/[^a-zA-Z0-9]/-/g')
dir="$cfg/projects/$slug"

# portable file mtime as epoch seconds (GNU stat, then BSD stat)
mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1"; }
# portable epoch -> "YYYY-MM-DD HH:MM" (GNU date, then BSD date)
fmtdate() { date -d "@$1" '+%Y-%m-%d %H:%M' 2>/dev/null || date -r "$1" '+%Y-%m-%d %H:%M'; }

# newest_transcript: path of the most recently written .jsonl for this cwd, or ""
newest_transcript() { ls -t "$dir"/*.jsonl 2>/dev/null | head -1 || true; }

# resolve_id <interactive>: echo the id to act on.
#   - Inside a Claude session, $CLAUDE_CODE_SESSION_ID is exported into every
#     command Claude runs (and into `!` shells), so it's the authoritative
#     current id — no transcript guessing.
#   - Outside a session: an interactive terminal (<interactive> = 1) gets the
#     fzf picker; a non-tty (piped) falls back to the newest transcript.
# Pass <interactive> in from the top-level script: computing [ -t 1 ] here would
# see this function's captured stdout, not the caller's real one. Returns 1 with
# no output when there are no conversations at all; empty output means the picker
# was cancelled.
resolve_id() {
	local interactive=$1 newest picked
	if [ -n "${CLAUDE_CODE_SESSION_ID:-}" ]; then
		printf '%s' "$CLAUDE_CODE_SESSION_ID"
		return 0
	fi
	newest=$(newest_transcript)
	if [ "$interactive" = 1 ] && command -v fzf >/dev/null 2>&1 && [ -n "$newest" ]; then
		picked=$(pick_id) || true
		printf '%s' "$picked"
		return 0
	fi
	[ -n "$newest" ] || return 1
	basename "$newest" .jsonl
}

# summarize <jsonl>: one-line summary — the generated title, else the last
# prompt, else "(untitled)".
summarize() {
	local jf=$1 t
	t=$(jq -r 'select(.type=="ai-title")|.aiTitle' "$jf" 2>/dev/null | tail -1)
	[ -n "$t" ] || t=$(jq -r 'select(.type=="last-prompt")|.lastPrompt' "$jf" 2>/dev/null | tail -1)
	[ -n "$t" ] || t="(untitled)"
	printf '%s' "$t" | tr '\n' ' '
}

# summary_for <id>: summarize the transcript with that id, or "" if it's gone.
summary_for() {
	local jf="$dir/$1.jsonl"
	[ -f "$jf" ] || return 0
	summarize "$jf"
}

# maybe_preview "$@": when invoked as `--preview <id>`, render that conversation
# for the fzf preview pane and exit. Otherwise return so the caller continues.
maybe_preview() {
	[ "${1:-}" = "--preview" ] || return 0
	local jf="$dir/${2:-}.jsonl"
	[ -f "$jf" ] || {
		echo "no transcript for ${2:-}"
		exit 0
	}
	echo "id:       $2"
	echo "updated:  $(fmtdate "$(mtime "$jf")")"
	echo "messages: $(jq -rc 'select(.type=="user" or .type=="assistant")' "$jf" 2>/dev/null | wc -l | tr -d ' ')"
	echo
	echo "Title:"
	jq -r 'select(.type=="ai-title")|.aiTitle' "$jf" 2>/dev/null | tail -1
	echo
	echo "Last prompt:"
	jq -r 'select(.type=="last-prompt")|.lastPrompt' "$jf" 2>/dev/null | tail -1 | cut -c1-500
	exit 0
}

# list_sessions: one row per conversation for this cwd, newest first, as
# "id<TAB>date  title". Shared by the fzf picker and the show-sessions script.
list_sessions() {
	local jf
	for jf in $(ls -t "$dir"/*.jsonl 2>/dev/null); do
		printf '%s\t%s  %s\n' "$(basename "$jf" .jsonl)" "$(fmtdate "$(mtime "$jf")")" "$(summarize "$jf" | cut -c1-80)"
	done
}

# pick_id: fzf picker over this dir's conversations; echoes the chosen id.
# fzf draws on /dev/tty, so this is safe to capture with $(...). Returns 130 on
# cancel, 1 when fzf is missing. fzf shows field 2 (date + title) and passes the
# hidden id (field 1) to the preview and the selection.
pick_id() {
	command -v fzf >/dev/null || return 1
	local sel
	sel=$(list_sessions | fzf \
		--delimiter='\t' --with-nth=2 \
		--preview="'$self' --preview {1}" \
		--preview-window='down,55%,wrap' \
		--prompt='conversation> ' \
		--header='pick a conversation — Enter selects, Esc cancels') || return 130
	printf '%s' "$sel" | cut -f1
}
