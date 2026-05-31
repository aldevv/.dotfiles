# Udemy scraper

## URL pattern

`https?://(www\.)?udemy\.com/course/<slug>/?`

The slug is the segment after `/course/`. Trailing slash optional.

Out of scope: `/draft/`, `/learn/`, `/instructor/` paths, private / unlisted courses (the API returns 404).

## Strategy

Uses Udemy's public, unauthenticated curriculum endpoints:

1. `GET https://www.udemy.com/api-2.0/courses/<slug>/` -> JSON containing `id` (the numeric course ID).
2. `GET https://www.udemy.com/api-2.0/courses/<id>/public-curriculum-items/?page_size=1000` -> JSON with `results` array.

Each result item has a `_class` field. The scraper handles two:

- `chapter`: a section. Has `title`. Becomes `## Unidad N: <title>` in the output (Spanish heading is a quirk of the upstream script; downstream consumers accept both `## Unidad N: ...` and generic `## ...`).
- `lecture`: a video / item within the current chapter. Has `title`. Becomes a numbered list item under the most-recent chapter.

Other `_class` values exist (`quiz`, `practice`, `coding-exercise`) but the upstream script ignores them.

Items are returned in display order, so the parser walks linearly and groups lectures under the most-recent chapter.

## Upstream tool

[yossijaki/udemy-course-curriculum-scraper](https://github.com/yossijaki/udemy-course-curriculum-scraper). License: GPL-3.0.

The skill clones the repo shallow into `${XDG_CACHE_HOME:-$HOME/.cache}/udemy-course-curriculum-scraper/` on first use and reuses the cached copy after. The source is **not vendored** into the skill; GPL would copyleft this entire skill.

## Wrapping

`scripts/scrapers/udemy.sh` is a thin bash wrapper that:

- Validates the URL with a regex.
- Checks `python3` is on `PATH` and `requests` is importable.
- Clones the upstream repo if the cache is missing.
- `cd`s into the output dir (the upstream script writes `curriculum.md` and `curriculum.txt` relative to cwd) and pipes the URL to `scraper.py` via stdin.
- Verifies `curriculum.md` is non-empty after the scrape.

## Quirks

- The upstream `scraper.py` prompts for the URL on stdin (`input()`); the wrapper feeds it via `echo "$url" | python3 ...`. The interactive prompt still prints to stderr but is harmless.
- Section headings are written as `## Unidad N: <title>` (the upstream is Spanish). Downstream consumers in this skill (step 8b of `SKILL.md`, the plan agent prompt) tolerate both this and plain `## <title>`.
- `page_size=1000` is large enough for every Udemy course as of 2026; the upstream does not paginate beyond that. If a future course exceeds 1000 items, this would silently truncate - watch for it.
- No authentication is required for public courses. Private / unlisted courses return 404 and the upstream script exits with a Spanish error string.

## Failure modes

| Symptom | Cause | Wrapper exit |
| --- | --- | --- |
| "URL does not look like a Udemy course page" | Regex match fails | `64` |
| "python3 not on PATH" / "'requests' module missing" | System dependency missing | `69` |
| Upstream prints "No se pudo obtener el ID del curso" | Slug invalid or course private (404) | upstream exits, wrapper exits `1` |
| Upstream prints "No se pudo obtener el contenido del curso" | Curriculum API returned non-200 | upstream exits, wrapper exits `1` |
| `curriculum.md` empty after scrape | API returned 200 with empty `results` | `1` |

## Future-proofing

If Udemy retires the `public-curriculum-items` endpoint or the upstream repo goes stale, replacement options in order of preference:

1. Fork the upstream Python script into a maintained mirror and update the cache URL.
2. Re-implement the two API calls directly in `udemy.sh` using `curl` + `jq` (drops the Python + GPL dependency).
3. Fall back to Playwright on `udemy.com/course/<slug>/` and parse the rendered curriculum panel.
