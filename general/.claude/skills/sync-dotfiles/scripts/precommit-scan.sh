#!/usr/bin/env bash
# KEEP IN SYNC with general/.claude/skills/sync-dotfiles-full/scripts/precommit-scan.sh.
# Both copies must remain byte-identical. Co-located per the dotfiles "scripts
# live with their skill" rule; the duplication is a small, accepted cost.
#
# Pre-commit scan for the sync-dotfiles skills. Reads filenames from stdin or
# argv and:
#   1. auto-deletes self-looping symlinks (ELOOP) in default mode, or BLOCKS
#      them in --loop-only mode (see Loop semantics below),
#   2. blocks files with a secret-suspicious filename,
#   3. blocks files containing secret-suspicious content.
#
# Exit codes: 0 = all clean (loops removed, nothing else flagged),
#             7 = at least one file blocked.
#
# Order matters: the symlink-loop check MUST run before the content grep,
# because a looping symlink makes `grep "$f"` fail silently with ELOOP
# (returns "no match"). Without the guard, dotfiles commit dda112d8 turned
# `claude-version` into a `f -> f` symlink, the secret scan let it through,
# and every machine that pulled it broke .xprofile via PATH ELOOP.
#
# Loop semantics differ by mode:
#   default     local loops are leftover artifacts (a stow misfire, an
#               aborted edit) with nothing recoverable since they point at
#               themselves. Remove and continue.
#   --loop-only post-merge guard. The loop is in a commit just merged from
#               upstream, so it lives in HEAD on this machine and would be
#               propagated by the next push. Block; the SKILL.md path tells
#               the user to `git reset --hard` to unwind the merge.
#
# password-store entries (.gpg files in a pass tree) are encrypted ciphertext.
# They skip the filename heuristic only when --prefix=personal (the private
# submodule); anywhere else they're blocked to prevent leakage into a public
# repo. Content check still runs (catches stray key blocks); raw keyrings
# (secring/pubring/private-keys-v1.d) are always blocked.
#
# Flags:
#   --loop-only      Skip secret checks (used post-merge, where we only care
#                    about loops introduced upstream). Also flips loop
#                    handling to BLOCK instead of auto-fix, see Loop
#                    semantics above.
#   --prefix=<path>  Prepend <path>/ to BLOCKED messages. Used by
#                    sync-dotfiles-full when scanning submodules in parallel
#                    so output identifies which repo flagged.

set -e

loop_only=0
prefix=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --loop-only) loop_only=1; shift ;;
    --prefix=*)  prefix="${1#--prefix=}/"; shift ;;
    --)          shift; break ;;
    -*)          echo "unknown flag: $1" >&2; exit 2 ;;
    *)           break ;;
  esac
done

status=0

is_password_store_entry() {
  local f="$1"
  case "$f" in *.gpg) ;; *) return 1 ;; esac
  case "$f" in
    */.password-store/*|*/password-store/*|*/.pass/*) return 0 ;;
  esac
  local dir
  dir=$(dirname -- "$f")
  while [ "$dir" != "/" ] && [ "$dir" != "." ] && [ -n "$dir" ]; do
    [ -e "$dir/.gpg-id" ] && return 0
    dir=$(dirname -- "$dir")
  done
  return 1
}

scan_one() {
  local f="$1" display
  [ -z "$f" ] && return 0
  display="${prefix}${f}"

  if [ -L "$f" ] && stat -L "$f" 2>&1 | grep -qi 'too many levels'; then
    if [ "$loop_only" = "1" ]; then
      echo "BLOCKED: looping symlink in $display -> $(readlink "$f")"
      status=7
    else
      echo "auto-fix: removed looping symlink $display -> $(readlink "$f")"
      rm -f "$f" || { echo "  (failed to remove $display; manual cleanup needed)"; status=7; }
    fi
    return 0
  fi

  [ "$loop_only" = "1" ] && return 0

  if echo "$f" | grep -qiE '(^|/)(secring|pubring)\.(gpg|kbx)$|(^|/)private-keys-v1\.d/'; then
    echo "BLOCKED: GPG keyring file: $display"
    status=7
    return 0
  fi

  if is_password_store_entry "$f"; then
    if [ "$prefix" != "personal/" ]; then
      echo "BLOCKED: password-store entry outside personal/ submodule: $display"
      status=7
      return 0
    fi
  elif echo "$f" | grep -qiE '\.(env|pem|key|p12|pfx|ppk|gpg)$|^\.env(\.|$)|secret|password|credential|private_key|id_rsa|id_dsa|id_ed25519'; then
    echo "BLOCKED: suspicious filename: $display"
    status=7
    return 0
  fi

  if [ -r "$f" ] && grep -qiE \
       'BEGIN (RSA |DSA |EC |OPENSSH )?PRIVATE KEY|BEGIN PGP (PRIVATE|PUBLIC) KEY BLOCK|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|xox[baprs]-[A-Za-z0-9]|password\s*=\s*\S+|api[_-]?key\s*[=:]\s*[A-Za-z0-9/+]{16,}|secret\s*[=:]\s*[A-Za-z0-9/+]{16,}' \
       "$f" 2>/dev/null; then
    echo "BLOCKED: secret content in $display"
    status=7
    return 0
  fi
}

if [ "$#" -gt 0 ]; then
  for f in "$@"; do scan_one "$f"; done
else
  while IFS= read -r f; do scan_one "$f"; done
fi

exit "$status"
