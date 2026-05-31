#!/usr/bin/env bash
set -euo pipefail

# Pick the right path to write an artifact to, given the overwrite-protection
# rules used by the create-study-plan skill.
#
# Rules:
#   - If <target> does not exist: print <target>.
#   - If <target> exists AND its first line (H1) matches <h1-regex>: it's a
#     prior dossier from this skill; print <target> (caller will overwrite).
#   - Otherwise: print <target-dir>/<cert-slug>-<basename> (caller writes to
#     the alt filename without prompting).
#
# <h1-regex> is a basic extended-regex pattern anchored against the first line.
# Examples (single-quote them in callers to avoid shell expansion):
#   '^# SnowPro Core \(COF-C03\)$'          # README dossier
#   '^# SnowPro Core study plan$'           # study-plan walkthrough
#
# Usage: safe-write-path.sh <target-path> <cert-slug> <h1-regex>

if [[ $# -ne 3 ]]; then
    echo "usage: $0 <target-path> <cert-slug> <h1-regex>" >&2
    exit 64
fi

target="$1"
cert_slug="$2"
h1_regex="$3"

target_dir="$(dirname "$target")"
target_base="$(basename "$target")"

if [[ ! -e "$target" ]]; then
    echo "$target"
    exit 0
fi

h1="$(head -n 1 "$target" 2>/dev/null || true)"

if grep -qE "$h1_regex" <<<"$h1"; then
    echo "$target"
    exit 0
fi

echo "${target_dir}/${cert_slug}-${target_base}"
