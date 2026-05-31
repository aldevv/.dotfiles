---
name: create-study-plan
description: Build study materials for a certification/exam or course URL: download the official study guide, extract domain weightings, optionally find a recommended course, and generate a README dossier, study-plan.md, and per-domain lesson packs. Triggers: /create-study-plan, "create a study plan for <X>", "study for <cert>", or a course URL paired with study intent.
argument-hint: [<course-url>] [<cert-name-or-code>] [output-dir]
---

# create-study-plan

Build everything needed to study for a cert from zero. Five artifacts:

1. **Official study guide** (always). The vendor's exam guide, downloaded into the output dir.
2. **`curriculum.md`** (when a course URL is given, or when one was picked via the find-course step). Full section + lecture list from the course, produced by the scraper dispatcher.
3. **`README.md` dossier** (always). Cert summary, exam shape table, domain weightings, official links, sources. Tables preferred.
4. **`study-plan.md` walkthrough** (always, when a cert is identified). Objective-by-objective notes in informal style: "what it is + need to know + course reference."
5. **Per-domain lesson packs** (always, when a cert is identified). `.planning/<domain>.md` plans + `lessons/<domain>/subject_<N>_<slug>.md` deep lessons, produced by per-domain writer subagents (one agent per domain). A single review agent checks all plans before lessons get written; lesson review is opt-in. Higher-weight domains get more subjects and deeper coverage.

## Table of contents

- [Files](#files)
- [Prerequisites](#prerequisites)
- [Inputs](#inputs)
- [When NOT to use](#when-not-to-use)
- [Flow](#flow)
- [Attribution](#attribution)

## Files

Paths below assume the canonical install at `~/.claude/skills/create-study-plan/`. If the skill lives somewhere else, resolve paths relative to that root.

- `SKILL.md` (this file) - the workflow.
- `scripts/download.sh` - curl wrapper used in step 5.
- `scripts/fetch-curriculum.sh` - platform dispatcher used in step 2. Routes by URL hostname into `scripts/scrapers/`.
- `scripts/scrapers/<platform>.sh` - per-platform curriculum scrapers (Udemy today).
- `scripts/safe-write-path.sh` - resolves the overwrite-protection rule for README / study-plan artifacts; used by steps 7 and 8.
- `references/scrapers/README.md` - dispatcher contract; how to add a new platform.
- `references/vendor-patterns.md` - priors for finding official study-guide URLs; read at step 4.
- `references/find-course.md` - prompt template passed to the `investigate` skill in step 6.
- `references/walkthrough-agent.md` - prompt template for the step 8 walkthrough subagent.
- `references/plan-agent.md` - prompt template for phase 9b plan agents (also defines the plan-file schema).
- `references/plan-review.md` - prompt template for the phase 9c reviewer.
- `references/lesson-agent.md` - prompt template for phase 9d lesson agents.
- `references/lesson-review.md` - prompt template for the phase 9e reviewers.
- `references/templates/readme.md` - skeleton for the README dossier (read at step 7).
- `references/templates/walkthrough.md` - skeleton for `study-plan.md` (read by the walkthrough subagent at step 8).

## Prerequisites

- `curl`, `file`, `python3` with the `requests` library (Udemy scraper).
- Playwright MCP plugin (for step 4 fallbacks).
- WebSearch + WebFetch tools (host-provided).
- The skill calls scripts via `~/.claude/skills/create-study-plan/scripts/...`; if the skill is installed elsewhere, substitute the install root.

## Inputs

The user can pass any combination of:

- A course URL (`https://www.udemy.com/course/<slug>/` today; more platforms via the dispatcher contract in `references/scrapers/README.md`).
- A certification or exam name (e.g. "SnowPro Core", "CKA", "AWS Solutions Architect Associate", "SAA-C03", "AZ-104").
- An output directory (defaults to `$PWD`).

- If the user gives only a URL, infer the cert from the curriculum once it's fetched. If inference is ambiguous (course doesn't clearly map to one cert, or maps to a non-cert topic), ask before guessing.
- If the user gives only a cert name, run step 6 (find recommended course via the `investigate` skill) after the study guide is downloaded.

## When NOT to use

- The user wants only flashcards, practice questions, or a mock exam. This skill doesn't generate those.
- The user wants a pacing calendar or week-by-week schedule. Not produced here.
- A bare course URL with no exam / cert / study intent. Fall through to a non-cert tool.
- A non-certification general-knowledge query ("teach me Snowflake"). Use a generic research or tutorial flow.
- The course isn't cert-aligned (general intro, language tutorial). Stop after `curriculum.md` and tell the user.

## Flow

1. **Resolve output dir.** Default `$PWD`. Create if missing.

2. **If a course URL is given**, run the curriculum fetcher:

   ```bash
   ~/.claude/skills/create-study-plan/scripts/fetch-curriculum.sh <url> <out-dir>
   ```

   The script is a dispatcher that routes to a platform-specific scraper in `scripts/scrapers/` (Udemy is the only one wired up today). Produces `curriculum.md` (and `curriculum.txt` when the scraper writes one).

   If the dispatcher exits with code 69 (unsupported platform), it prints a hint pointing at `references/scrapers/README.md`. Default behavior: ask the user "platform X isn't wired up yet, want me to add a scraper for it now?" If yes, read `references/scrapers/README.md` first, follow the full "Adding a new platform" recipe there, then retry step 2. Cert-only mode is a fallback, not the first answer.

3. **Determine the certification.**
   - If the user passed a cert name/code, use that verbatim.
   - Else, read `curriculum.md` and infer: section titles, opening sections, vendor keywords. A Snowflake course covering architecture / loading / time travel / streams / access management is SnowPro Core; a Kubernetes course covering kubeadm / etcd / RBAC / networking is CKA; etc.
   - If you can't pin it to a single cert with confidence, ask the user. Do NOT guess silently.
   - If the course isn't cert-aligned (e.g. "Python for Beginners"), say so and stop after step 2.

4. **Find the official study guide URL.** WebSearch + WebFetch:
   - Search for the canonical vendor exam page. Use `references/vendor-patterns.md` as priors for where official guides live on each vendor's domain.
   - The URL MUST be on the vendor's official domain. Reject third-party study guides (vmexam, certsafari, scribd, etc.) for the canonical download. They're fine as cross-references in chat, never as the saved artifact.
   - Prefer PDF over HTML. If the official asset is HTML only, save the rendered page.

   **Playwright is a first-class fallback** for anything WebFetch can't handle. Use it freely when needed; do not stop at "WebFetch returned a form" and ask the user. Concrete scenarios:
   - WebFetch returns a marketing form instead of the asset. Navigate to the URL, then `browser_snapshot` to read the DOM. Snowflake's pattern: the thank-you URL with `?pdf_name=<X>` already exposes the real CDN PDF link without filling the form.
   - The download link is JS-generated and absent from HTML source. `browser_navigate` then `browser_evaluate` / `browser_snapshot` to read the resolved `href`.
   - The vendor genuinely gates the asset behind a name/email form. `browser_fill_form` with the user's data, `browser_click` submit, then read the resulting page. Before filling any form: confirm with the user what email/name to use (the user's work email is sensitive; don't volunteer it).
   - Cookie banners or "accept terms" interstitials. `browser_click` them out of the way before snapshotting.
   - Inspect network traffic with `browser_network_requests` when the click triggers a download that the snapshot doesn't surface.

   After Playwright extracts the real URL, hand it to `scripts/download.sh` (curl is faster than Playwright's downloader and keeps the artifact path predictable).

   **Fail fast if no official guide can be found.** If WebSearch, WebFetch, AND Playwright all fail to surface a downloadable URL on the vendor's official domain (after a reasonable number of attempts, not infinite retry), STOP. Do not continue to step 5+ with a guess or a third-party source. Tell the user exactly what was tried (search queries, URLs visited, why each path failed) and exit the flow. The official study guide is the truth source for the rest of the pipeline; without it, the produced artifacts would be unreliable.

5. **Download the guide:**

   ```bash
   ~/.claude/skills/create-study-plan/scripts/download.sh <official-url> <out-dir>/<filename>
   ```

   - Filename: preserve the upstream basename when it's meaningful (e.g. `SnowProCoreStudyGuideC03.pdf`). Otherwise use `<cert-slug>-study-guide.<ext>`.
   - The script enforces non-empty output and prints `wrote <path> (<mime>, <bytes> bytes)` to stderr; nothing goes to stdout.

   **Then extract the domain table.** Open the downloaded guide (PDF: use Read with `pages:` for >10 pages) and pull the vendor's official "EXAM DOMAIN AND WEIGHTINGS" section. Capture each row as `(vendor number, domain name, weight %)`. This table is the source of truth for the README dossier (step 7), the `investigate` prompt (step 6), and the per-domain pipeline (step 9). Hold it in working memory through the rest of the flow; do not re-derive it from web search results.

6. **Find a recommended course (when no course URL was supplied).** Skip this step if the user already passed a URL. Otherwise, this is where the skill picks a course to study alongside the official guide.

   Invoke the `investigate` skill via the `Skill` tool (`skill: investigate`, args: the filled-in prompt body) using the template at `~/.claude/skills/create-study-plan/references/find-course.md`. Fill in the cert name + code, the domain/weighting table extracted in step 5, the downloaded study-guide path, and the official cert page URL. Investigate returns up to 3 candidate courses ranked by alignment with the study guide plus community sentiment, with each signal labeled.

   Platform-neutral: any platform is fair game (Udemy, Coursera, Pluralsight, YouTube, edX, vendor-native academies, etc.). The investigate skill should rank by quality and alignment, not by "is this Udemy?". If the chosen candidate is on a platform the scraper dispatcher doesn't know about, apply the same "add a scraper inline" flow from step 2 - integration is mechanical given the contract in `references/scrapers/README.md`.

   Present the top 1-3 candidates to the user with the labels intact (study-guide alignment vs community recommendation vs both, with source links for community signals). Ask:
   - Use the top recommendation (default).
   - Paste a different URL.
   - Skip course entirely (cert-only mode).

   If the user picks a URL, loop back to step 2 to scrape it (adding a scraper inline if the platform is new). Either way, record the investigate findings (rationale, community-vs-alignment labels, source links) under a "Recommended course" section in the README dossier in step 7.

7. **Write `README.md` dossier** to the output dir. Read the template at `~/.claude/skills/create-study-plan/references/templates/readme.md` for the full skeleton and the rules around mandatory tables, weight sorting, and the sources list.

   Step 7 always runs. Never skip it, even when there's a filename collision; pick an alt name instead.

   Resolve the target path via the helper (handles the overwrite-protection rule uniformly with step 8). The third arg is an extended-regex pattern matched against the first line (H1) of an existing file:

   ```bash
   target=$(~/.claude/skills/create-study-plan/scripts/safe-write-path.sh \
     "<out-dir>/README.md" "<cert-slug>" '^# <Cert Name> \(<exam-code>\)$')
   ```

   The helper returns `<out-dir>/README.md` when the path is free or its H1 matches a prior dossier from this skill, and `<out-dir>/<cert-slug>-README.md` otherwise (no prompt). If the alt filename fired, record it in step 10's report.

   Then fill the template and write to `$target`. The "Recommended course" block (template lines 29-39) must be populated from step 6's investigate findings (selected course, why, coverage, community signal + source URLs, caveats). Skip the block only if step 6 was skipped (URL supplied by the user) or the user opted out of the course recommendation.

8. **Write `study-plan.md` walkthrough** via a subagent. This is the main learning artifact and the bar is highest here, so it gets its own focused agent rather than running in the orchestrator's context.

   Resolve the target path the same way as step 7. The walkthrough template starts with `# <Cert Name> study plan`, so use that as the H1 pattern:

   ```bash
   target=$(~/.claude/skills/create-study-plan/scripts/safe-write-path.sh \
     "<out-dir>/study-plan.md" "<cert-slug>" '^# <Cert Name> study plan$')
   ```

   Spawn one `general-purpose` agent using `references/walkthrough-agent.md`. Fill in the variables (cert name + code, paths to the study guide, `curriculum.md` or `N/A`, README dossier, walkthrough template, **and the resolved target path** from the helper). The agent reads the template at `references/templates/walkthrough.md`, reads the guide and curriculum, and writes the file at the path you pass in. Don't ask the agent to re-check overwrite protection; the helper already decided.

   Step 8 always runs once a cert is identified.

9. **Per-domain lesson packs (subagent pipeline).** This is the deep, expensive phase. Five sub-phases (9a setup, 9b plan, 9c plan review, 9d lesson, 9e lesson review). 9b and 9d run domain-parallel; 9c is one agent over all plans; 9e is opt-in. 9a-9d always run once a cert is identified; warn the user once at the start ("spawning ~N+2 agents across the lesson pipeline, takes a few minutes") and proceed without further prompting. 9e prompts before running.

   **9a. Setup**
   - Read the domains table from the README dossier written in step 7. Use the path step 7 actually wrote to (either `<out-dir>/README.md` or the alt `<out-dir>/<cert-slug>-README.md` if the overwrite-protection branch fired). Also read the study guide PDF to get each domain's **vendor number** (the `1.0`, `2.0`, etc. labels printed under "EXAM DOMAIN AND WEIGHTINGS").
   - Sluggify each domain name using the **vendor's domain number**, not the README's weight-sorted display order. So Snowflake's "2.0 Account Management and Data Governance" stays `2-account-management-and-data-governance` even when the README sorts it third by weight. Anchoring slugs to vendor numbering keeps directory names aligned with the study-guide pages.
   - Lowercase the domain name, replace any non-`[a-z0-9]` run with `-`, prefix with the vendor's domain number. Strip the `.0` suffix (`1.0` -> `1`).
   - `mkdir -p <out-dir>/.planning <out-dir>/lessons/<each-domain-slug>`.

   **9b. Plan phase (parallel)** - one `general-purpose` agent per domain.
   - For each domain, fill the template at `~/.claude/skills/create-study-plan/references/plan-agent.md` with the domain's variables (cert, domain number, name, weight, slug, out-dir, study-guide filename).
   - Send all N `Agent()` calls in a single message so they run concurrently. Brief each agent with the filled-in prompt; ask them to write `.planning/<domain-slug>.md`.
   - Wait for all to return.

   **9c. Plan review (single agent)** - one `Explore` agent reviews **all plans at once**.
   - Spawn a single `Explore` (read-only) agent using `references/plan-review.md`. The agent reads every plan in `.planning/`, the study guide, and `curriculum.md`, then returns a per-domain verdict.
   - The reviewer's report has one section per domain (PASS / NEEDS_FIXES / MAJOR_REWORK). Before patching any `NEEDS_FIXES` plan inline, read `references/plan-agent.md` so the plan-file schema (subject blocks, `Slug:` line, `Course:` line, depth labels) is in the orchestrator's context. Then patch the plan by editing the file directly. For each `MAJOR_REWORK` domain, re-spawn the plan-creation agent for that domain with the reviewer's findings appended. Re-review only if a major rework happened (capped at one extra cycle).

   **9d. Lesson phase (parallel)** - one `general-purpose` agent per domain. The agent writes every lesson file for its domain in one shot, so the agent count matches the domain count (typically 4-8), not the subject count (typically 30-50).
   - For each domain, read the finalized plan at `.planning/<domain-slug>.md` and pass its full content to the agent via the template at `references/lesson-agent.md`.
   - The agent's job is to write `lessons/<domain-slug>/subject_<N>_<subject-slug>.md` for every subject in the plan. The subject slug is part of the plan (each subject in `.planning/<domain-slug>.md` carries a `Slug:` line); the agent reads it from there and uses it in the filename. Example: `subject_3_snowpipe.md`, `subject_7_micro-partitions-and-clustering.md`. The number gives natural sort order; the slug makes the filename readable when listing.
   - Lessons within a domain are written by one agent, so cross-references and tone stay consistent.
   - Send all N domain calls in a single message so they run concurrently. Wait for all to return.

   **9e. Lesson review (opt-in, parallel)** - this phase is **not run automatically**. After 9d returns, ask the user: "Lesson review will spawn one Explore agent per domain to check coverage / style / fabrications across the lessons. It's optional. Run it?". Only proceed if the user says yes.
   - If yes: for each domain, spawn an `Explore` agent with the template at `references/lesson-review.md`. The agent reads every file under `lessons/<domain-slug>/` and the corresponding plan. All N agents launched in one message.
   - For each domain whose verdict is `NEEDS_FIXES`, patch the affected lesson files inline (Claude edits, not a subagent). For `MAJOR_REWORK`, re-spawn the domain's lesson agent with the reviewer's findings appended to the prompt; the re-spawn rewrites only the broken subjects, leaving the passing ones untouched. Capped at one extra cycle.
   - If the user says no: skip 9e entirely, and note in step 10's report that lesson review was declined.

   **Failure handling:** if any subagent returns an error or empty output, retry that single agent once with the same prompt. If it fails again, record the gap in step 10's report with: the domain name, the phase that failed (9b plan / 9d lesson / 9e review), the error message returned, and which artifacts are missing as a result (e.g. "`.planning/3-account-management.md` not written; lesson phase for this domain skipped"). Don't block other domains.

10. **Report to the user:**
    - Path to study guide and detected MIME type.
    - Path to `curriculum.md` if generated (with section/lecture counts) and the course that was used (recommended-and-confirmed vs user-supplied).
    - Path to the README dossier (call out the alt filename if step 7's collision branch fired).
    - Path to `study-plan.md` (or alt filename if a collision was avoided).
    - Per-domain summary: subjects planned, lessons written (full filenames including slug), plan-review verdict, lesson-review verdict (or "declined" if 9e was opted out).
    - The inferred (or supplied) cert name.
    - Any open review items, retry failures, or skipped phases.

## Attribution

Upstream Udemy scraper: <https://github.com/yossijaki/udemy-course-curriculum-scraper> (GPL-3.0). The skill clones and runs it; it does not vendor the code.

Scope: today this skill produces the guide + dossier + walkthrough + per-domain lesson packs. It does not produce pacing calendars, flashcards, or practice exams. Extensions land in this same skill (new platform scrapers under `scripts/scrapers/`, new reference files in `references/`).
