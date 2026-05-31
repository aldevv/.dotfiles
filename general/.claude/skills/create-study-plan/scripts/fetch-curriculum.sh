#!/usr/bin/env bash
set -euo pipefail

# Dispatch a course URL to the right scraper in scripts/scrapers/.
# Per-platform contract and how to add a new platform: see
# references/scrapers/README.md.
#
# Usage: fetch-curriculum.sh <course-url> [output-dir]
# Output: <output-dir>/curriculum.md (+ curriculum.txt when the scraper writes one)

if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Usage: $0 <course-url> [output-dir]" >&2
    exit 64
fi

url="$1"
out_dir="${2:-$PWD}"
script_dir="$(cd "$(dirname "$0")" && pwd)"

case "$url" in
    *udemy.com/course/*)
        platform=udemy
        ;;
    *)
        cat >&2 <<EOF
error: unsupported course platform for URL: $url

Supported today:
  - udemy.com/course/<slug>

To add a new platform, see:
  $script_dir/../references/scrapers/README.md

Quick version: implement scripts/scrapers/<platform>.sh, document it at
references/scrapers/<platform>.md, then add a case branch above.
EOF
        exit 69
        ;;
esac

scraper="$script_dir/scrapers/$platform.sh"
if [[ ! -x "$scraper" ]]; then
    echo "error: scraper not found or not executable: $scraper" >&2
    exit 70
fi

exec "$scraper" "$url" "$out_dir"
