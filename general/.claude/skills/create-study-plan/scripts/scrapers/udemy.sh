#!/usr/bin/env bash
set -euo pipefail

# Fetch a Udemy course syllabus by delegating to
# yossijaki/udemy-course-curriculum-scraper. The upstream repo is cloned
# into a cache dir on first run and reused after that.
#
# Usage: fetch-curriculum.sh <udemy-course-url> [output-dir]
# Output: <output-dir>/curriculum.md and <output-dir>/curriculum.txt
# Defaults: output-dir = $PWD

UPSTREAM_URL="https://github.com/yossijaki/udemy-course-curriculum-scraper.git"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/udemy-course-curriculum-scraper"

usage() {
    echo "Usage: $0 <udemy-course-url> [output-dir]" >&2
    echo "  url must look like https://www.udemy.com/course/<slug>/" >&2
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
    usage
    exit 64
fi

url="$1"
out_dir="${2:-$PWD}"

if [[ ! "$url" =~ udemy\.com/course/[^/]+ ]]; then
    echo "error: URL does not look like a Udemy course page: $url" >&2
    usage
    exit 64
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "error: python3 not on PATH" >&2
    exit 69
fi

if ! python3 -c "import requests" >/dev/null 2>&1; then
    echo "error: python3 'requests' module missing. install with: pip install --user requests" >&2
    exit 69
fi

if [[ ! -d "$CACHE_DIR/.git" ]]; then
    echo "cloning $UPSTREAM_URL -> $CACHE_DIR" >&2
    mkdir -p "$(dirname "$CACHE_DIR")"
    git clone --depth 1 "$UPSTREAM_URL" "$CACHE_DIR" >&2
fi

mkdir -p "$out_dir"
out_dir_abs="$(cd "$out_dir" && pwd)"

(
    cd "$out_dir_abs"
    echo "$url" | python3 "$CACHE_DIR/scraper.py"
)

if [[ ! -s "$out_dir_abs/curriculum.md" ]]; then
    echo "error: curriculum.md missing or empty after scrape" >&2
    exit 1
fi

echo "wrote $out_dir_abs/curriculum.md" >&2
echo "wrote $out_dir_abs/curriculum.txt" >&2
