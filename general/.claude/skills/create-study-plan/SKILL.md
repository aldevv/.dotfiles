---
name: create-study-plan
description: Build complete study materials for a certification, exam, or course. Inputs can be (a) a Udemy course URL, (b) a certification / exam name or code, or (c) both. Downloads the official vendor study guide, then (when no course URL was supplied) uses the `investigate` skill to recommend the best-aligned course by combining study-guide coverage with community sentiment (and labels which signals came from where), writes a `README.md` cert dossier (exam shape table, domains-and-weightings table, official links, recommended course block), writes a `study-plan.md` informal walkthrough cross-referenced with course lectures, then runs a four-phase parallel subagent pipeline to produce a per-domain plan in `.planning/<domain>.md` and a deep lesson pack at `lessons/<domain>/subject_N.md`. Plans are reviewed in parallel before implementation; lessons are reviewed in parallel (one agent per domain) after implementation. Higher-weight domains get more subjects and deeper lessons. If a course URL is given, dumps the full course syllabus to `curriculum.md` via the platform scraper dispatcher (Udemy wired up today). If only a URL is given, infers the target certification from the curriculum and fetches its guide; if inference is ambiguous, asks the user. Triggers on "/create-study-plan", "create a study plan for <X>", "get the official study guide for <cert>", "fetch the exam guide for <cert>", "build study materials for <udemy URL>", "find the official syllabus for the <cert> exam", or a Udemy course URL paired with study/exam/cert intent. Do NOT trigger for a bare URL with no study/cert intent, or for non-certification general-knowledge queries.
argument-hint: <udemy-url-and/or-cert-name> [output-dir]
---

# create-study-plan

Build everything needed to study for a cert from zero. Five artifacts:

1. **Official study guide** (always). The vendor's exam guide, downloaded into the output dir.
2. **`curriculum.md`** (when a course URL is given, or when one was picked via the find-course step). Full section + lecture list from the course, produced by the scraper dispatcher.
3. **`README.md` dossier** (always). Cert summary, exam shape table, domain weightings, official links, sources. Tables preferred.
4. **`study-plan.md` walkthrough** (always, when a cert is identified). Objective-by-objective notes in informal style: "what it is + need to know + course reference."
5. **Per-domain lesson packs** (always, when a cert is identified). `.planning/<domain>.md` plans + `lessons/<domain>/subject_N.md` deep lessons, produced and reviewed by parallel subagents. Higher-weight domains get more subjects and deeper coverage.

## Inputs

The user can pass any combination of:

- A course URL (`https://www.udemy.com/course/<slug>/` today; more platforms via the dispatcher contract in `references/scrapers/README.md`).
- A certification or exam name (e.g. "SnowPro Core", "CKA", "AWS Solutions Architect Associate", "SAA-C03", "AZ-104").
- An output directory (defaults to `$PWD`).

- If the user gives only a URL, infer the cert from the curriculum once it's fetched. If inference is ambiguous (course doesn't clearly map to one cert, or maps to a non-cert topic), ask before guessing.
- If the user gives only a cert name, run step 6 (find recommended course via the `investigate` skill) after the study guide is downloaded.

## Flow

1. **Resolve output dir.** Default `$PWD`. Create if missing.

2. **If a course URL is given**, run the curriculum fetcher:

   ```bash
   ~/.claude/skills/create-study-plan/scripts/fetch-curriculum.sh <url> <out-dir>
   ```

   The script is a dispatcher that routes to a platform-specific scraper in `scripts/scrapers/` (Udemy is the only one wired up today). Produces `curriculum.md` (and `curriculum.txt` when the scraper writes one).

   If the dispatcher exits with code 69 (unsupported platform), it prints a hint pointing at `references/scrapers/README.md`. Integration is mechanical given the contract there (write `scripts/scrapers/<platform>.sh`, write `references/scrapers/<platform>.md`, add a `case` branch in the dispatcher). Default behavior: ask the user "platform X isn't wired up yet, want me to add a scraper for it now?" If yes, follow the README's recipe inline, then retry step 2. Cert-only mode is a fallback, not the first answer.

3. **Determine the certification.**
   - If the user passed a cert name/code, use that verbatim.
   - Else, read `curriculum.md` and infer: section titles, opening sections, vendor keywords. A Snowflake course covering architecture / loading / time travel / streams / access management is SnowPro Core; a Kubernetes course covering kubeadm / etcd / RBAC / networking is CKA; etc.
   - If you can't pin it to a single cert with confidence, ask the user. Do NOT guess silently.
   - If the course isn't cert-aligned (e.g. "Python for Beginners"), say so and stop after step 2.

4. **Find the official study guide URL.** WebSearch + WebFetch:
   - Search for the canonical vendor exam page (see vendor patterns below).
   - The URL MUST be on the vendor's official domain. Reject third-party study guides (vmexam, certsafari, scribd, etc.) for the canonical download. They're fine as cross-references in chat, never as the saved artifact.
   - Prefer PDF over HTML. If the official asset is HTML only, save the rendered page.

   **Playwright is a first-class fallback** for anything WebFetch can't handle. Use it freely when needed; do not stop at "WebFetch returned a form" and ask the user. Concrete scenarios:
   - WebFetch returns a marketing form instead of the asset. Navigate to the URL, then `browser_snapshot` to read the DOM. Snowflake's pattern: the thank-you URL with `?pdf_name=<X>` already exposes the real CDN PDF link without filling the form.
   - The download link is JS-generated and absent from HTML source. `browser_navigate` then `browser_evaluate` / `browser_snapshot` to read the resolved `href`.
   - The vendor genuinely gates the asset behind a name/email form. `browser_fill_form` with the user's data, `browser_click` submit, then read the resulting page. Before filling any form: confirm with the user what email/name to use (the user's work email is sensitive; don't volunteer it).
   - Cookie banners or "accept terms" interstitials. `browser_click` them out of the way before snapshotting.
   - Inspect network traffic with `browser_network_requests` when the click triggers a download that the snapshot doesn't surface.

   After Playwright extracts the real URL, hand it to `scripts/download.sh` (curl is faster than Playwright's downloader and keeps the artifact path predictable).

5. **Download the guide:**

   ```bash
   ~/.claude/skills/create-study-plan/scripts/download.sh <official-url> <out-dir>/<filename>
   ```

   - Filename: preserve the upstream basename when it's meaningful (e.g. `SnowProCoreStudyGuideC03.pdf`). Otherwise use `<cert-slug>-study-guide.<ext>`.
   - The script enforces non-empty output and prints the detected file type.

6. **Find a recommended course (when no course URL was supplied).** Skip this step if the user already passed a URL. Otherwise, this is where the skill picks a course to study alongside the official guide.

   Invoke the `investigate` skill (parallel web research) with the prompt template at `~/.claude/skills/create-study-plan/references/find-course.md`, filled in with the cert name + code, the official domain/weighting table, the downloaded study-guide path, and the official cert page URL. Investigate returns up to 3 candidate courses ranked by alignment with the study guide plus community sentiment, with each signal labeled.

   Platform-neutral: any platform is fair game (Udemy, Coursera, Pluralsight, YouTube, edX, vendor-native academies, etc.). The investigate skill should rank by quality and alignment, not by "is this Udemy?". If the chosen candidate is on a platform the scraper dispatcher doesn't know about, apply the same "add a scraper inline" flow from step 2 - integration is mechanical given the contract in `references/scrapers/README.md`.

   Present the top 1-3 candidates to the user with the labels intact (study-guide alignment vs community recommendation vs both, with source links for community signals). Ask:
   - Use the top recommendation (default).
   - Paste a different URL.
   - Skip course entirely (cert-only mode).

   If the user picks a URL, loop back to step 2 to scrape it (adding a scraper inline if the platform is new). Either way, record the investigate findings (rationale, community-vs-alignment labels, source links) under a "Recommended course" section in the README dossier in step 7.

7. **Write `README.md` dossier** to the output dir. See the template below. Markdown tables are mandatory for exam shape and domains-and-weightings (the user is explicit about this).

   Before writing, check whether `<out-dir>/README.md` already exists:
   - If absent, write it.
   - If present and clearly an earlier dossier from this skill (starts with the cert name H1 and has the same structure), overwrite.
   - If present and looks like user-authored content (anything else), do NOT clobber. Ask the user, or save the dossier as `<cert-slug>-README.md` (e.g. `snowpro-core-c03-README.md`) and report the alternative filename in the final summary.

8. **Write `study-plan.md` walkthrough** to the output dir. This is the main learning artifact and the bar is highest here.

   Build it from the downloaded study guide:
   - Read the PDF/HTML guide. For PDFs use the `Read` tool with `pages:` if the file is >10 pages; otherwise read whole.
   - Extract the domain structure and every objective/sub-topic the vendor lists.
   - For each objective, draft a tiny per-topic block per the template below.

   Cross-reference with the course:
   - If `curriculum.md` exists, match each objective to course lectures by keyword on the lecture title (case-insensitive, tolerate slight wording differences). The course's section numbers + video numbers are already in `curriculum.md` (`## Unidad N: <title>` and `<M>. <video title>`).
   - If you find a match, cite as `Course: §N <Unidad title> · Video M: <video title>`.
   - If no lecture clearly maps to the objective, write `Not in course curriculum.` Don't hedge with "maybe related to" - either it's covered or it's not.
   - If a course lecture maps to an objective but the title is approximate, still cite it. If the match is genuinely ambiguous, cite the best candidate and add `(approximate match)`.
   - If `curriculum.md` does not exist (cert-only mode), omit the `Course:` line entirely. Don't write "Not in course curriculum." in that mode.

   Style rules (the user is explicit about this):
   - Short and easy to scan. Bullets over paragraphs. No filler.
   - Informal register: "you need to know", "this is the load command", "watch out for". Not "It is important to understand that..."
   - One-sentence what-it-is per topic, then 2-6 need-to-know bullets, then the course line. That's it.
   - Use fenced code blocks for SQL/CLI/syntax that's worth memorizing.
   - Do NOT pad with motivational text, learning-strategy advice, or "good luck on the exam" sign-offs.

   Overwrite protection: same rule as `README.md`. If `study-plan.md` exists and isn't an earlier dossier from this skill, save as `<cert-slug>-study-plan.md` and tell the user.

9. **Per-domain lesson packs (parallel subagent pipeline).** This is the deep, expensive phase. Four sub-phases, parallelism within each. Always runs once a cert is identified; warn the user once at the start ("spawning ~N agents across 4 phases, takes a few minutes") and proceed without further prompting.

   **9a. Setup**
   - Read the domains table from `README.md` to get domain list, weights, and ordering.
   - Sluggify each domain name: lowercase, replace any non-`[a-z0-9]` run with `-`, prefix with the domain number. e.g. `1-snowflake-ai-data-cloud-features-and-architecture`.
   - `mkdir -p <out-dir>/.planning <out-dir>/lessons/<each-domain-slug>`.

   **9b. Plan phase (parallel)** - one `general-purpose` agent per domain.
   - For each domain, fill the template at `~/.claude/skills/create-study-plan/references/plan-agent.md` with the domain's variables (cert, domain number, name, weight, slug, out-dir, study-guide filename).
   - Send all N `Agent()` calls in a single message so they run concurrently. Brief each agent with the filled-in prompt; ask them to write `.planning/<domain-slug>.md`.
   - Wait for all to return.

   **9c. Plan review (parallel)** - one `Explore` agent per plan.
   - For each plan written in 9b, fill the template at `references/plan-review.md` and spawn an `Explore` (read-only) agent. Send all calls in one message.
   - Collect their findings (returned in messages). For each plan whose verdict is `NEEDS_FIXES`, patch the plan inline by editing it. For `MAJOR_REWORK`, re-spawn the plan-creation agent for that domain with the reviewer's findings appended to the prompt. Re-review only if a major rework happened (capped at one extra cycle to bound cost).

   **9d. Lesson phase (parallel)** - one `general-purpose` agent per subject across all domains.
   - Parse each finalized plan to extract the list of subjects (each gets a number, title, scope, objectives, course refs, depth).
   - For every subject, fill the template at `references/lesson-agent.md` and spawn an agent that writes `lessons/<domain-slug>/subject_<N>.md`.
   - Send all calls (could be 20-50 agents) in a single message. Group into batches of at most 20 per message if the count exceeds 20, to keep individual tool-call payloads manageable, but launch the batches back-to-back without waiting.

   **9e. Lesson review (parallel)** - one `Explore` agent per domain (NOT per lesson).
   - For each domain, spawn an `Explore` agent with the template at `references/lesson-review.md`. The agent reads every file under `lessons/<domain-slug>/` and the corresponding plan.
   - All N agents launched in one message.
   - For each domain whose verdict is `NEEDS_FIXES`, patch the affected lesson files inline (Claude edits, not a subagent). For `MAJOR_REWORK` of a specific subject, re-spawn that subject's lesson agent with the reviewer's findings. Capped at one extra cycle.

   **Failure handling:** if any subagent returns an error or empty output, retry that single agent once with the same prompt. If it fails again, log the gap in the final report (don't block other domains).

10. **Report to the user:**
    - Path to study guide and detected type (PDF / HTML).
    - Path to `curriculum.md` if generated (with section/lecture counts) and the course that was used (recommended-and-confirmed vs user-supplied).
    - Path to the README dossier.
    - Path to `study-plan.md` (or alt filename if a collision was avoided).
    - Per-domain summary: subjects planned, lessons written, review verdicts.
    - The inferred (or supplied) cert name.
    - Any open review items or retry failures.

## README.md template

Use this structure. Fill from WebSearch / WebFetch / Playwright findings. Skip any section where you genuinely couldn't find official information rather than inventing it; mark `_(not found in official sources)_` in that case.

```markdown
# <Cert Name> (<exam code>)

<One-paragraph intro: what the cert validates, current exam version, when it went live and what it replaces, vendor.>

## Files in this folder

- `<study-guide-filename>` - official vendor study guide (downloaded from <vendor URL>).
- `curriculum.md` - section + lecture titles from the course `<course title>` on <platform> (<course URL>).  _(omit if no course was scraped)_
- `curriculum.txt` - same content, plain-text form.  _(omit if no course was scraped, or if the platform's scraper doesn't produce a txt mirror)_

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

Rules:
- Weights in the domain table must sum to 100% (or note the discrepancy with `_(vendor's published weights sum to N%)_` if they don't).
- Order rows in the domain table by weight descending, ties broken by the vendor's published order.
- Sources at the bottom: only the URLs you actually fetched to produce the README (vendor pages plus the third-party summary if you used one). Skip URLs you only saw in search results without reading.

## study-plan.md template

Use this skeleton. Keep blocks tight; the file should read like notes a friend wrote, not a textbook.

````markdown
# <Cert> study plan

What this is: every objective the exam covers, in plain language, with a pointer to the matching course video where one exists.

Read top to bottom or jump to whatever you want. The bullets are the "you need to know this" list. If you can answer them out loud, move on.

## 1. <Domain name> (<weight>%)

### <Objective / topic title>

<One informal sentence: what this thing is.>

- <Need-to-know bullet.>
- <Another.>
- <Watch out for: ...>

Course: §<N> <Unidad title> · Video <M>: <video title>

### <Next topic>

<One sentence.>

- <Bullet.>

Not in course curriculum.

## 2. <Next domain> (<weight>%)
...
````

Per-block rules:
- One-sentence what-it-is. Plain language. If you can't compress it to one sentence, you don't understand it yet; read the guide again.
- 2-6 need-to-know bullets. No more. If a topic genuinely needs more, split into two sub-topics.
- Code blocks for SQL/CLI/syntax worth memorizing (e.g. `COPY INTO ... FROM @stage`, `kubectl get pods -A`). Skip code blocks for conceptual topics.
- Course line is one line, not a paragraph. Either `Course: §N <title> · Video M: <title>` or `Not in course curriculum.`
- No "Sources" or "Further reading" section. The README has those.
- No emoji. No motivational text. No "good luck!"

Tone calibration ("informal, easy"):
- Use second person ("you can do X"), contractions ("don't", "it's"), short sentences.
- Prefer verbs over nominalizations ("you load data" not "the loading of data").
- Concrete > abstract: name the actual command, error code, or limit, not "various options exist".

## Vendor patterns (known officials)

Use these as priors when searching. They aren't exhaustive; always verify the page is current and on the vendor's domain.

| Vendor | Where the official guide lives |
| --- | --- |
| Snowflake (SnowPro) | `info.snowflake.com/SnowPro-Study-Guide-Form_Updated-Thank-You-Page.html?pdf_name=<NameOfPDF>` exposes the AEM CDN PDF in the DOM (no form fill required). |
| AWS | `aws.amazon.com/certification/certified-<slug>/` links an "Exam Guide" PDF. |
| Google Cloud | `cloud.google.com/certification/guides/<slug>` (HTML exam guide; no PDF). |
| Microsoft (Azure / M365) | `learn.microsoft.com/en-us/credentials/certifications/exams/<exam-id>/` plus the Skills Outline PDF linked from that page. |
| CompTIA | `comptia.org/certifications/<cert>` -> "Exam Objectives" PDF. |
| CNCF (CKA / CKAD / CKS) | `github.com/cncf/curriculum` (PDFs in repo). |
| HashiCorp | `developer.hashicorp.com/certifications/<product>` -> "Exam objectives" page. |
| Cisco | `learningnetwork.cisco.com/s/<cert>-exam-topics` -> blueprint PDF. |

If the cert isn't in the table, fall back to: `WebSearch "<cert name> official exam guide site:<vendor-domain>"` and verify the result is on a vendor-owned domain before downloading.

## What this skill does NOT do (yet)

- No schedule, no per-week pacing across the lesson packs.
- No spaced-repetition flashcards or progress tracking.
- No practice questions / mock exams generated from the lessons.
- Only Udemy is wired up in the scraper dispatcher today. The architecture is platform-agnostic - `scripts/scrapers/` + `references/scrapers/README.md` define the contract for adding more. Cert-only mode works regardless of platform.

Extensions land in this same skill, so additions go here (new platform scrapers under `scripts/scrapers/`, new reference files in `references/`, new helper scripts beside the existing ones) rather than a fork.

## Attribution

Upstream Udemy scraper: <https://github.com/yossijaki/udemy-course-curriculum-scraper> (GPL-3.0). The skill clones and runs it; it does not vendor the code.
