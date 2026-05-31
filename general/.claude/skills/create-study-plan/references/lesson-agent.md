# Lesson agent prompt template

Use this template when spawning a `general-purpose` subagent in phase 8d. Substitute every `{VAR}` with the real value before sending.

## Variables

- `{CERT_NAME}`, `{CERT_CODE}`
- `{DOMAIN_NUMBER}`, `{DOMAIN_NAME}`, `{DOMAIN_SLUG}`, `{WEIGHT}`
- `{SUBJECT_NUMBER}` - integer, e.g. "3"
- `{SUBJECT_TITLE}` - from the plan, e.g. "Stages and the COPY command"
- `{SUBJECT_SCOPE}` - the Scope line from the plan
- `{SUBJECT_OBJECTIVES}` - newline-separated bullet list of verbatim study-guide objectives this lesson covers
- `{SUBJECT_COURSE_REFS}` - the Course: line from the plan, or `Not in course curriculum.`, or omit entirely in cert-only mode
- `{SUBJECT_DEPTH}` - `short` | `medium` | `long`
- `{OUT_DIR}` - absolute path to the study folder
- `{STUDY_GUIDE_PATH}` - absolute path to the study guide
- `{PLAN_PATH}` - `{OUT_DIR}/.planning/{DOMAIN_SLUG}.md`
- `{STUDY_PLAN_PATH}` - `{OUT_DIR}/study-plan.md`

## Prompt body

```
You are writing ONE lesson file for the {CERT_NAME} ({CERT_CODE}) exam. The user is studying for this exam and will read your lesson directly. Write it like a tight, informal blog post written by a friend who already knows the material.

Context:
- Cert: {CERT_NAME} ({CERT_CODE})
- Domain: {DOMAIN_NUMBER}. {DOMAIN_NAME} ({WEIGHT}% of exam)
- Subject: subject_{SUBJECT_NUMBER} - {SUBJECT_TITLE}
- Scope (from the plan): {SUBJECT_SCOPE}
- Objectives this lesson must cover (verbatim from the study guide):
{SUBJECT_OBJECTIVES}
- Course refs (from the plan): {SUBJECT_COURSE_REFS}
- Depth: {SUBJECT_DEPTH}
- Output path: {OUT_DIR}/lessons/{DOMAIN_SLUG}/subject_{SUBJECT_NUMBER}.md
- Study guide (truth source): {STUDY_GUIDE_PATH}
- Plan for this domain: {PLAN_PATH}
- Top-level walkthrough for tone reference: {STUDY_PLAN_PATH}

Task:
1. Read the study guide sections covering the objectives above. If the guide is silent on a detail you need, run ONE WebSearch on the vendor docs (e.g. `site:docs.snowflake.com "<term>"`) and one WebFetch on the most relevant result. Cite the URL inline if you used one.
2. Read {STUDY_PLAN_PATH} to match the tone (informal, second person, short sentences).
3. Write the lesson file using the Write tool. Output ONLY the file; do not paste the full lesson back in your reply, just confirm the path and length.

Lesson structure (use these section names, in this order; skip sections that don't apply):

    # subject_{SUBJECT_NUMBER}: {SUBJECT_TITLE}

    **TL;DR:** 1-3 bullets, one sentence each, summarizing what you'll know after reading this.

    ## What it is

    1-3 short paragraphs explaining the concept. Plain language. Analogies are welcome if they fit.

    ## Hands-on

    Fenced code blocks for the actual SQL / CLI / config the exam will test. Each block is preceded by a one-line description of what it does.

    ## Watch out for

    Gotchas, exam traps, defaults that surprise people, off-by-one limits. Bullets.

    ## Try this _(optional)_

    A 2-3 step hands-on exercise the reader can run against a free-tier account or sandbox.

    ## Course

    A single line: the {SUBJECT_COURSE_REFS} value verbatim. If `{SUBJECT_COURSE_REFS}` is empty (cert-only mode), omit this section entirely.

Style rules (NON-NEGOTIABLE):
- Informal, second person. "you'll set up", "watch out for", "you can use". Not "It is recommended that the user...".
- Tight. No filler. No "in this lesson we will cover...". Dive in.
- Use markdown tables when comparing >2 options or values.
- No emoji anywhere.
- No "Sources" / "Further reading" sections (those belong in the top-level README).
- No motivational sign-offs ("good luck!", "you've got this!").
- No em-dashes or double-hyphens as prose punctuation; use commas / parentheses / colons instead. CLI flags like `--force` are fine.

Length targets:
- short: 80-200 lines
- medium: 200-400 lines
- long: 400-700 lines
Going significantly over the upper bound means you padded; trim it.

Hard rules:
- Every concept must be backed by the study guide or a cited vendor doc URL. If you can't find a source, omit the claim - do not invent.
- Every objective in {SUBJECT_OBJECTIVES} must be addressed somewhere in the lesson. If you finish a draft and an objective is uncovered, add a section before writing the file.
- Code blocks must be valid (parseable) for the language they declare. Don't write `sql` blocks that the actual vendor SQL wouldn't accept.
```
