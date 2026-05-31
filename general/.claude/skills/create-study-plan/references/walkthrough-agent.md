# Walkthrough agent prompt template

Use this template when spawning a `general-purpose` subagent in step 8 to write `study-plan.md`. ONE agent; sequential after step 7 (it can read the README dossier for context). Substitute every `{VAR}` with the real value before sending.

## Variables

- `{CERT_NAME}` - e.g. "SnowPro Core"
- `{CERT_CODE}` - e.g. "COF-C03"
- `{OUT_DIR}` - absolute path to the study folder
- `{STUDY_GUIDE_PATH}` - absolute path to the downloaded study guide (PDF or HTML)
- `{CURRICULUM_PATH}` - absolute path to `curriculum.md`, or the literal string `N/A` if no course is in play
- `{README_PATH}` - absolute path to the README dossier written in step 7
- `{TEMPLATE_PATH}` - absolute path to the walkthrough template, normally `~/.claude/skills/create-study-plan/references/templates/walkthrough.md`

## Prompt body

```
You are writing the top-level study-plan walkthrough for the {CERT_NAME} ({CERT_CODE}) exam. The user reads this file before diving into the per-domain lesson packs; it's the most-read artifact in the study folder. The bar for tone and concision is highest here.

Context:
- Cert: {CERT_NAME} ({CERT_CODE})
- Study guide (truth source): {STUDY_GUIDE_PATH}
- Course curriculum (cross-reference for lecture pointers): {CURRICULUM_PATH}
- README dossier (cert overview, domain table, official links - already written): {README_PATH}
- Walkthrough template + rules: {TEMPLATE_PATH}
- Output file to write: {OUT_DIR}/study-plan.md

Task:
1. Read {TEMPLATE_PATH} for the skeleton, per-block rules, tone calibration, and cross-referencing rules.
2. Read {README_PATH} for the cert name, exam version, and the domain table (in weight-descending order).
3. Read {STUDY_GUIDE_PATH}. For a PDF >10 pages, walk it with the Read tool's `pages:` parameter; otherwise read whole. Extract every objective and sub-topic the vendor lists, verbatim where possible.
4. If {CURRICULUM_PATH} is not "N/A", read it. You'll cite section + video numbers per topic.
5. Write {OUT_DIR}/study-plan.md per the template. Order domains weight-descending (match the README's domain table order).
6. Confirm the file path and line count in your reply. Don't paste the full file contents back.

Hard rules:
- Cover every objective in the study guide. If you find an objective that doesn't fit cleanly into a per-topic block, split it; never silently drop it.
- One-sentence what-it-is per topic, then 2-6 need-to-know bullets, then the course line. That's it. The template's per-block rules are non-negotiable.
- Code blocks for SQL/CLI/syntax worth memorizing only. Skip code blocks for conceptual topics.
- If `curriculum.md` does not exist (cert-only mode), omit the `Course:` line entirely on every topic. Don't write "Not in course curriculum." for every topic in cert-only mode - that's noise.
- No em-dashes, double-hyphens as prose punctuation, emoji, motivational text, or "good luck!" sign-offs.
- Overwrite protection: if {OUT_DIR}/study-plan.md already exists, check whether it's an earlier dossier from this skill (starts with `# {CERT_NAME} study plan`). If yes, overwrite. If anything else, write to `{OUT_DIR}/<cert-slug>-study-plan.md` instead (e.g. `snowpro-core-c03-study-plan.md`). Do NOT ask the user mid-flow; pick the alt filename and report it in the reply.

Output:
- One line confirming the file path you wrote to.
- One line with the line count.
- One line listing any objective you could not cleanly place (rare; usually means the vendor's structure surprised you).
- Nothing else. Don't echo the file contents.
```
