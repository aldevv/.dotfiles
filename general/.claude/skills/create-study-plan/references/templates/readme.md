# README dossier template

Use this skeleton for `<out-dir>/README.md` (step 7 of the create-study-plan flow). Fill from WebSearch / WebFetch / Playwright findings. Skip any section where you genuinely couldn't find official information rather than inventing it; mark `_(not found in official sources)_` in that case.

## Skeleton

```markdown
# <Cert Name> (<exam code>)

<One-paragraph intro: what the cert validates, current exam version, when it went live and what it replaces, vendor.>

## Files in this folder

- `<study-guide-filename>` - official vendor study guide (downloaded from <vendor URL>).
- `curriculum.md` - section + lecture titles from the course `<course title>` on <platform> (<course URL>).  _(omit if no course was scraped)_
- `curriculum.txt` - same content as `curriculum.md`, plain-text form without markdown headers.  _(omit if no course was scraped, or if the platform's scraper doesn't produce a txt mirror)_
- `study-plan.md` - objective-by-objective walkthrough of the exam, in informal style. The main learning artifact.
- `.planning/<domain-slug>.md` - per-domain lesson-pack plans (one file per domain). Internal scaffolding; the lessons are the user-facing output.
- `lessons/<domain-slug>/subject_<N>_<slug>.md` - deep lessons, one file per subject. Read top-to-bottom or jump by name.

## Official resources

- Cert page: <url>
- Study guide PDF: <url>
- Free prep course: <url>
- Practice exams: <url>
- <any other vendor-official link: hands-on lab, free trial, community forum>

## Recommended course _(present only when the skill ran the find-course investigate step)_

**Selected:** <Course title> by <instructor> · <platform> · [link](<url>)

- Length: <hours>; updated <date>
- Why: <study-guide alignment | community recommendation | both>
- Coverage vs official domains: strong on <domains>, weak on <domains>
- Community signal: <1-2 sentences>. Sources: [<thread/post title>](<url>), [<...>](<url>).
- Caveats: <dated content, missing topics, etc.>

<If runner-ups were returned, list them in the same shape under a "Runner-ups" sub-heading. Otherwise omit.>

## Exam shape

| Field | Value |
| --- | --- |
| Format | <multiple choice / scenario / lab / mixed> |
| Questions | <N> |
| Time | <N minutes> |
| Passing score | <X / Y or percentage> |
| Validity | <N years> |
| Cost | <$N> |
| Languages | <list> |
| Delivery | <online proctored / test center / both> |
| Prerequisite | <recommended experience> |

## Domains & weightings

| # | Domain | Weight |
| --- | --- | --- |
| 1 | <domain name> | <N>% |
| 2 | ... | ...% |
| ... | ... | ...% |

## Related certifications

- <Advanced / next-step tracks, sibling tracks, prerequisite tracks. Bullet list.>

## Sources

- [<title>](<url>)
- ...
```

## Rules

- Markdown tables are mandatory for exam shape and domains-and-weightings. No bullet substitutes.
- Weights in the domain table must sum to 100% (or note the discrepancy with `_(vendor's published weights sum to N%)_` if they don't).
- Order rows in the domain table by weight descending, ties broken by the vendor's published order.
- The "Files in this folder" list reflects what the skill actually produced. Drop the `study-plan.md`, `.planning/`, or `lessons/` line if a phase was skipped (e.g. cert-only mode with no course scraped still produces all three; phase 9 declined entirely would drop the `.planning/` and `lessons/` lines).
- Sources at the bottom: only the URLs you actually fetched to produce the README (vendor pages plus the third-party summary if you used one). Skip URLs you only saw in search results without reading.
