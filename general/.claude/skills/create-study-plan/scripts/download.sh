#!/usr/bin/env bash
set -euo pipefail

# Download a single URL to <output-path>, follow redirects, fail on non-2xx,
# verify the resulting file is non-empty, and print its detected MIME type.
#
# Usage: download.sh <url> <output-path>

if [[ $# -ne 2 ]]; then
    echo "usage: $0 <url> <output-path>" >&2
    exit 64
fi

url="$1"
out="$2"

mkdir -p "$(dirname "$out")"

curl -sSL --fail --max-time 120 -o "$out" "$url"

if [[ ! -s "$out" ]]; then
    echo "error: $out is empty after download" >&2
    exit 1
fi

# `file` is unreliable for PDF page counts (often reports wrong number).
# Use MIME-only output, which is accurate, and print bytes from stat.
mime=$(file --brief --mime-type "$out" 2>/dev/null || echo "unknown")
bytes=$(stat -c%s "$out" 2>/dev/null || stat -f%z "$out")
echo "wrote $out ($mime, $bytes bytes)" >&2
