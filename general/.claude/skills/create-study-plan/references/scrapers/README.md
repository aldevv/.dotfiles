# Scrapers

Per-platform course-curriculum scrapers, dispatched from `scripts/fetch-curriculum.sh`. The dispatcher inspects the URL hostname and runs the matching script in `scripts/scrapers/`. Each platform has a sibling doc in this directory.

## Supported platforms

| Platform | URL pattern | Script | Strategy | Doc |
| --- | --- | --- | --- | --- |
| Udemy | `udemy.com/course/<slug>` | `scripts/scrapers/udemy.sh` | Public curriculum API via [yossijaki/udemy-course-curriculum-scraper](https://github.com/yossijaki/udemy-course-curriculum-scraper) | [udemy.md](udemy.md) |

## When the dispatcher refuses a URL

`scripts/fetch-curriculum.sh` exits with code 69 and a hint if the URL hostname isn't in the table above. When Claude (orchestrating the skill) hits that exit code, it should:

1. Tell the user the platform isn't supported yet.
2. Ask whether they want it added now. If yes, follow the "Adding a new platform" steps below.
3. Otherwise, switch to cert-only mode (no `curriculum.md` produced).

## Adding a new platform

1. Investigate how to scrape that platform's curriculum:
   - Does it expose a public API endpoint? Check vendor API docs (preferred, fast, no auth).
   - Is the curriculum rendered in static HTML and reachable without auth? `curl` plus a small HTML parser.
   - Is it JS-rendered or auth-gated? Use Playwright via the MCP plugin (`browser_navigate` + `browser_snapshot`).

2. Write `scripts/scrapers/<platform>.sh` satisfying the contract below. Keep platform-specific logic inside the script; the dispatcher must stay dumb.

3. Write `references/scrapers/<platform>.md` documenting:
   - URL pattern handled (regex).
   - API endpoint(s) / DOM structure / scraping approach.
   - Auth requirements, rate limits, gotchas.
   - Upstream tool used, if any, with license and pinned commit.

4. Add a `case` branch to `scripts/fetch-curriculum.sh` routing the new hostname pattern to the new script.

5. Add a row to the table at the top of this file.

6. Smoke-test against a real course URL before declaring the integration done.

## Scraper contract

Every `scripts/scrapers/<platform>.sh` must satisfy:

- **Arguments**: `<course-url> [output-dir]`. `output-dir` defaults to `$PWD`.
- **Side effects**: write `<output-dir>/curriculum.md`. Optionally also write `<output-dir>/curriculum.txt` (plain-text mirror, line-per-item).
- **`curriculum.md` format**:
  - Sections as H2: `## <section title>` (legacy `## Unidad N: <title>` also accepted, since the original Udemy scraper writes that form).
  - Lectures as a numbered list under each section: `1. <lecture title>`.
- **Exit codes**:
  - `0` on success.
  - `64` for bad arguments or invalid URL.
  - `69` for missing system dependency (`python3`, `requests`, network, etc.).
  - `1` for any scrape failure (empty result, upstream error, etc.).
- **Output streams**: progress and status messages to stderr only. Stdout is reserved (kept clean so future callers can capture structured output).
- **Idempotence**: overwriting an existing `curriculum.md` is allowed and expected.
- **No mutation outside `<output-dir>`** except for a per-platform cache directory under `${XDG_CACHE_HOME:-$HOME/.cache}/`.

If the platform exposes lecture durations, video IDs, transcripts, or other metadata, write them to a sibling file (e.g. `curriculum.json`) - do not pollute `curriculum.md` with them. Downstream consumers expect the markdown to be navigable by humans.

## Failure-mode etiquette

If a scraper detects the user pasted a URL pattern it can almost handle (e.g. Udemy's `/draft/` or `/learn/` paths that aren't `/course/`), it should print a one-line explanation to stderr before exiting `64` rather than failing opaquely. Help the orchestrator help the user.
