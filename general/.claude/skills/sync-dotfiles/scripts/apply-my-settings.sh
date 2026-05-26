#!/usr/bin/env bash
# Merge ~/.claude/my-settings.json into ~/.claude/settings.json.
#
# my-settings.json is treated as a managed overlay on settings.json:
# each apply re-renders settings.json as (settings minus prev-applied
# my-settings) then deep-merges current my-settings on top.
#
#   New entries        -> added to settings.
#   Removed entries    -> stripped from settings, but only when the
#                         value in settings still matches what was
#                         previously applied. User-edited values are
#                         left alone.
#   Scalar updates     -> overwrite settings (my-settings wins).
#   Arrays             -> union (settings entries first, my-settings
#                         entries appended).
#   Settings-only keys -> preserved untouched.
#
# Prev-applied content is cached at
# ~/.cache/sync-dotfiles/my-settings-applied.json. If the current
# my-settings.json is byte-identical to the cache, the script exits 2
# with no work.
#
# Exits:
#   0  success (settings.json updated or already current)
#   1  error (missing tool / unreadable input / invalid JSON)
#   2  skipped (my-settings.json unchanged since last apply)

set -euo pipefail

SRC="${HOME}/.claude/my-settings.json"
DST="${HOME}/.claude/settings.json"
CACHE_DIR="${HOME}/.cache/sync-dotfiles"
PREV="${CACHE_DIR}/my-settings-applied.json"

[ -f "$SRC" ] || { echo "apply-my-settings: $SRC missing"; exit 1; }
command -v jq >/dev/null || { echo "apply-my-settings: jq is required"; exit 1; }

if [ -f "$PREV" ] && cmp -s "$SRC" "$PREV"; then
  echo "apply-my-settings: my-settings.json unchanged since last apply, skipping"
  exit 2
fi

mkdir -p "$CACHE_DIR"

if [ ! -f "$DST" ]; then
  cp "$SRC" "$DST"
  cp "$SRC" "$PREV"
  echo "apply-my-settings: $DST didn't exist, copied my-settings.json wholesale"
  exit 0
fi

jq -e . "$SRC" >/dev/null 2>&1 \
  || { echo "apply-my-settings: $SRC is not valid JSON"; exit 1; }
jq -e . "$DST" >/dev/null 2>&1 \
  || { echo "apply-my-settings: $DST is not valid JSON"; exit 1; }

if [ -f "$PREV" ]; then
  jq -e . "$PREV" >/dev/null 2>&1 \
    || { echo "apply-my-settings: $PREV is corrupted, delete and retry"; exit 1; }
  prev_json=$(cat "$PREV")
else
  prev_json='{}'
fi

tmp=$(mktemp -p "$(dirname "$DST")" settings.json.XXXXXX)
trap 'rm -f "$tmp"' EXIT

jq --argjson prev "$prev_json" --slurpfile addition "$SRC" '
  # Remove from $base anything $old previously contributed, but only
  # when the value still matches (so user edits are preserved).
  def strip($base; $old):
    if ($base | type) == "object" and ($old | type) == "object" then
      reduce ($old | keys[]) as $k (
        $base;
        if (has($k) | not) then .
        elif (.[$k] | type) == "object" and ($old[$k] | type) == "object" then
          (.[$k] | strip(.; $old[$k])) as $sub
          | if $sub == {} then del(.[$k]) else .[$k] = $sub end
        elif (.[$k] | type) == "array" and ($old[$k] | type) == "array" then
          (.[$k] - $old[$k]) as $rem
          | if $rem == [] then del(.[$k]) else .[$k] = $rem end
        elif .[$k] == $old[$k] then
          del(.[$k])
        else .
        end
      )
    else $base
    end;

  # Deep-merge $b on top of $a. Arrays union, scalars from $b win.
  def extend($a; $b):
    if ($a | type) == "object" and ($b | type) == "object" then
      reduce (($a | keys) + ($b | keys) | unique | .[]) as $k (
        {};
        .[$k] = (
          if ($a | has($k)) and ($b | has($k)) then extend($a[$k]; $b[$k])
          elif ($a | has($k)) then $a[$k]
          else $b[$k]
          end
        )
      )
    elif ($a | type) == "array" and ($b | type) == "array" then
      $a + ($b - $a)
    else $b
    end;

  extend(strip(.; $prev); $addition[0])
' "$DST" > "$tmp"

if [ ! -s "$tmp" ] || ! jq -e . "$tmp" >/dev/null 2>&1; then
  echo "apply-my-settings: merged result is empty or invalid JSON, aborting"
  exit 1
fi

if cmp -s "$tmp" "$DST"; then
  echo "apply-my-settings: no diff after merge"
else
  chmod --reference="$DST" "$tmp"
  mv -f "$tmp" "$DST"
  echo "apply-my-settings: settings.json updated"
fi
cp "$SRC" "$PREV"
exit 0
