---
name: create-study-plan
description: Build complete study materials for a certification, exam, or course. Inputs can be (a) a course URL (Udemy supported today; other platforms via the dispatcher contract in `references/scrapers/README.md`), (b) a certification / exam name or code, or (c) both. Downloads the official vendor study guide, then (cert-only mode) uses the `investigate` skill to recommend the best-aligned course by combining study-guide coverage with community sentiment (with each signal labeled). Writes a `README.md` cert dossier (exam shape table, domains-and-weightings table, official links, recommended course block) and a `study-plan.md` informal walkthrough cross-referenced with course lectures, then runs a per-domain subagent pipeline to produce `.planning/<domain>.md` plans and `lessons/<domain>/subject_<N>_<slug>.md` deep lessons (one writer agent per domain, ~4-8 agents total). A single review agent checks all plans before lesson-writing; lesson review is opt-in after lessons are written. Higher-weight domains get more subjects and deeper coverage. If a course URL is given, dumps the full course syllabus to `curriculum.md` via the platform scraper dispatcher. If only a URL is given, infers the target certification from the curriculum; if inference is ambiguous, asks the user. Triggers on "/create-study-plan", "create a study plan for <X>", "get the official study guide for <cert>", "fetch the exam guide for <cert>", "build study materials for <course URL>", "find the official syllabus for the <cert> exam", or a course URL paired with study/exam/cert intent. Do NOT trigger for a bare URL with no study/cert intent, or for non-certification general-knowledge queries.
argument-hint: <course-url-and/or-cert-name> [output-dir]
---

# create-study-plan

Build everything needed to study for a cert from zero. Five artifacts:

1. **Official study guide** (always). The vendor's exam guide, downloaded into the output dir.
2. **`curriculum.md`** (when a course URL is given, or when one was picked via the find-course step). Full section + lecture list from the course, produced by the scraper dispatcher.
3. **`README.md` dossier** (always). Cert summary, exam shape table, domain weightings, official links, sources. Tables preferred.
4. **`study-plan.md` walkthrough** (always, when a cert is identified). Objective-by-objective notes in informal style: "what it is + need to know + course reference."
5. **Per-domain lesson packs** (always, when a cert is identified). `.planning/<domain>.md` plans + `lessons/<domain>/subject_<N>_<slug>.md` deep lessons, produced by per-domain writer subagents (one agent per domain). A single review agent checks all plans before lessons get written; lesson review is opt-in. Higher-weight domains get more subjects and deeper coverage.

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

7. **Write `README.md` dossier** to the output dir. Read the template at `~/.claude/skills/create-study-plan/references/templates/readme.md` for the full skeleton and the rules around mandatory tables, weight sorting, and the sources list.

   Step 7 always runs. Never skip it, even when there's a filename collision; pick an alt name instead.

   Before writing, check whether `<out-dir>/README.md` already exists:
   - **Absent:** write `README.md`.
   - **Present and clearly an earlier dossier from this skill** (the H1 matches the cert name and the second-line H2 is `## Files in this folder`): overwrite.
   - **Present and anything else** (user-authored or unrecognized): write to `<cert-slug>-README.md` (e.g. `snowpro-core-c03-README.md`) without prompting. Surface the alt filename in step 10's report so the user knows what happened. Do NOT ask mid-flow ("should I clobber?") and do NOT skip; alt filename always wins over the prompt.

8. **Write `study-plan.md` walkthrough** via a subagent. This is the main learning artifact and the bar is highest here, so it gets its own focused agent rather than running in the orchestrator's context.

   Spawn one `general-purpose` agent using `references/walkthrough-agent.md`. Fill in the variables (cert name + code, paths to the study guide, `curriculum.md` or `N/A`, README dossier, walkthrough template). The agent reads the template at `references/templates/walkthrough.md`, reads the guide and curriculum, and writes `<out-dir>/study-plan.md`. Overwrite-protection works the same way as step 7 (alt filename `<cert-slug>-study-plan.md` if a non-skill file is in the way); the agent handles this itself per its prompt.

   Step 8 always runs once a cert is identified.

9. **Per-domain lesson packs (subagent pipeline).** This is the deep, expensive phase. Five sub-phases (9a setup, 9b plan, 9c plan review, 9d lesson, 9e lesson review). 9b and 9d run domain-parallel; 9c is one agent over all plans; 9e is opt-in. 9a-9d always run once a cert is identified; warn the user once at the start ("spawning ~N+2 agents across the lesson pipeline, takes a few minutes") and proceed without further prompting. 9e prompts before running.

   **9a. Setup**
   - Read the domains table from `README.md` to get the domain list and weights. Also read the study guide PDF to get each domain's **vendor number** (the `1.0`, `2.0`, etc. labels printed under "EXAM DOMAIN AND WEIGHTINGS").
   - Sluggify each domain name using the **vendor's domain number**, not the README's weight-sorted display order. So Snowflake's "2.0 Account Management and Data Governance" stays `2-account-management-and-data-governance` even when the README sorts it third by weight. Anchoring slugs to vendor numbering keeps directory names aligned with the study-guide pages.
   - Lowercase the domain name, replace any non-`[a-z0-9]` run with `-`, prefix with the vendor's domain number. Strip the `.0` suffix (`1.0` -> `1`).
   - `mkdir -p <out-dir>/.planning <out-dir>/lessons/<each-domain-slug>`.

   **9b. Plan phase (parallel)** - one `general-purpose` agent per domain.
   - For each domain, fill the template at `~/.claude/skills/create-study-plan/references/plan-agent.md` with the domain's variables (cert, domain number, name, weight, slug, out-dir, study-guide filename).
   - Send all N `Agent()` calls in a single message so they run concurrently. Brief each agent with the filled-in prompt; ask them to write `.planning/<domain-slug>.md`.
   - Wait for all to return.

   **9c. Plan review (single agent)** - one `Explore` agent reviews **all plans at once**.
   - Spawn a single `Explore` (read-only) agent using `references/plan-review.md`. The agent reads every plan in `.planning/`, the study guide, and `curriculum.md`, then returns a per-domain verdict.
   - The reviewer's report has one section per domain (PASS / NEEDS_FIXES / MAJOR_REWORK). For each `NEEDS_FIXES` domain, patch the plan inline by editing it. For each `MAJOR_REWORK` domain, re-spawn the plan-creation agent for that domain with the reviewer's findings appended. Re-review only if a major rework happened (capped at one extra cycle).

   **9d. Lesson phase (parallel)** - one `general-purpose` agent per domain. The agent writes every lesson file for its domain in one shot, so the agent count matches the domain count (typically 4-8), not the subject count (typically 30-50).
   - For each domain, read the finalized plan at `.planning/<domain-slug>.md` and pass its full content to the agent via the template at `references/lesson-agent.md`.
   - The agent's job is to write `lessons/<domain-slug>/subject_<N>_<subject-slug>.md` for every subject in the plan. The subject slug is part of the plan (each subject in `.planning/<domain-slug>.md` carries a `Slug:` line); the agent reads it from there and uses it in the filename. Example: `subject_3_snowpipe.md`, `subject_7_micro-partitions-and-clustering.md`. The number gives natural sort order; the slug makes the filename readable when listing.
   - Lessons within a domain are written by one agent, so cross-references and tone stay consistent.
   - Send all N domain calls in a single message so they run concurrently. Wait for all to return.

   **9e. Lesson review (opt-in, parallel)** - this phase is **not run automatically**. After 9d returns, ask the user: "Lesson review will spawn one Explore agent per domain to check coverage / style / fabrications across the lessons. It's optional. Run it?". Only proceed if the user says yes.
   - If yes: for each domain, spawn an `Explore` agent with the template at `references/lesson-review.md`. The agent reads every file under `lessons/<domain-slug>/` and the corresponding plan. All N agents launched in one message.
   - For each domain whose verdict is `NEEDS_FIXES`, patch the affected lesson files inline (Claude edits, not a subagent). For `MAJOR_REWORK`, re-spawn the domain's lesson agent with the reviewer's findings appended to the prompt; the re-spawn rewrites only the broken subjects, leaving the passing ones untouched. Capped at one extra cycle.
   - If the user says no: skip 9e entirely, and note in step 10's report that lesson review was declined.

   **Failure handling:** if any subagent returns an error or empty output, retry that single agent once with the same prompt. If it fails again, log the gap in the final report (don't block other domains).

10. **Report to the user:**
    - Path to study guide and detected MIME type.
    - Path to `curriculum.md` if generated (with section/lecture counts) and the course that was used (recommended-and-confirmed vs user-supplied).
    - Path to the README dossier (call out the alt filename if step 7's collision branch fired).
    - Path to `study-plan.md` (or alt filename if a collision was avoided).
    - Per-domain summary: subjects planned, lessons written (full filenames including slug), plan-review verdict, lesson-review verdict (or "declined" if 9e was opted out).
    - The inferred (or supplied) cert name.
    - Any open review items, retry failures, or skipped phases.

## Templates (load on demand)

- `references/templates/readme.md` - skeleton + rules for the README dossier. Read at step 7.
- `references/templates/walkthrough.md` - skeleton + rules for `study-plan.md`. Read by the walkthrough subagent at step 8 (you don't need to load it directly in the orchestrator).

## Vendor patterns (known officials)

Use these as priors when searching. They aren't exhaustive; always verify the page is current and on the vendor's domain.

| Vendor | Where the official guide lives |
| --- | --- |
| Snowflake (SnowPro) | Two URLs to know. The modern cert page `learn.snowflake.com/en/certifications/<cert-slug>/` shows a "Download Now" button gated by a JS handler (no `.pdf` href in static DOM, so WebFetch sees nothing). The legacy thank-you page `info.snowflake.com/SnowPro-Study-Guide-Form_Updated-Thank-You-Page.html?pdf_name=<NameOfPDF>` still resolves the AEM CDN PDF in the DOM as of 2026: Playwright-navigate, `browser_evaluate` to scan the HTML for `publish-p*.adobeaemcloud.com/.../<NameOfPDF>.pdf`, then hand to `download.sh`. Try the legacy URL first - it's cheaper than wrestling the modern page's JS button. WebSearch will probably surface the modern URL first; don't take that as authoritative for the download. |
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
