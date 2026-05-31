# Plan agent prompt template

Use this template when spawning a `general-purpose` subagent in phase 8b. Substitute every `{VAR}` with the real value before sending.

## Variables

- `{CERT_NAME}` - e.g. "SnowPro Core"
- `{CERT_CODE}` - e.g. "COF-C03"
- `{DOMAIN_NUMBER}` - e.g. "1"
- `{DOMAIN_NAME}` - e.g. "Snowflake AI Data Cloud Features and Architecture"
- `{DOMAIN_SLUG}` - e.g. "1-snowflake-ai-data-cloud-features-and-architecture"
- `{WEIGHT}` - e.g. "31"
- `{OUT_DIR}` - absolute path to the study folder
- `{STUDY_GUIDE_PATH}` - absolute path to the downloaded study guide (PDF or HTML)
- `{CURRICULUM_PATH}` - absolute path to `curriculum.md`, or the literal string `N/A` if no Udemy URL was given

## Prompt body to send to the subagent

```
You are drafting a lesson-pack plan for ONE domain of the {CERT_NAME} ({CERT_CODE}) exam. The orchestrator (Claude in the create-study-plan skill) will hand the plan to a downstream agent that writes the actual lessons; your job is the plan, not the lessons.

Context:
- Cert: {CERT_NAME} ({CERT_CODE})
- Domain: {DOMAIN_NUMBER}. {DOMAIN_NAME}
- Domain weight: {WEIGHT}%
- Study guide (source of truth): {STUDY_GUIDE_PATH}
- Course curriculum (cross-reference for lecture pointers): {CURRICULUM_PATH}
- Output file to write: {OUT_DIR}/.planning/{DOMAIN_SLUG}.md

Task:
1. Read the study guide. If it is a PDF >10 pages, use the Read tool with the `pages:` parameter to walk through it.
2. Extract every objective the vendor lists under this exact domain. Verbatim.
3. Group objectives into subjects. One subject = one lesson file. Subjects should be cohesive (one concept area) and non-overlapping.
4. For each subject, identify the matching course lecture(s) from {CURRICULUM_PATH} (if it is not "N/A"). Use case-insensitive keyword match on the lecture titles. If multiple lectures match, list all of them.
5. Calibrate subject count to the {WEIGHT}% domain weight:
   - >=30%: 6 to 10 subjects, deep coverage
   - 20-29%: 4 to 7 subjects
   - 10-19%: 3 to 5 subjects
   - <10%: 2 to 4 subjects
6. Write {OUT_DIR}/.planning/{DOMAIN_SLUG}.md using the exact format below.

Output format (write this file, nothing else):

    # Domain {DOMAIN_NUMBER}: {DOMAIN_NAME} ({WEIGHT}%)

    Total subjects: <N>
    Depth calibration: <one sentence justifying the count given the weight>

    ## subject_1: <short descriptive title>

    Scope: <1-2 sentences on what this lesson covers>

    Objectives covered (verbatim from the study guide):
    - <objective>
    - <objective>

    Course: §<N> <Unidad title> · Video <M>: <video title>
      _or_
    Not in course curriculum.

    Depth: short | medium | long

    ## subject_2: ...

Hard rules:
- Use the EXACT objective wording from the study guide. Do not paraphrase.
- If {CURRICULUM_PATH} is "N/A", omit the `Course:` / `Not in course curriculum.` line entirely (cert-only mode).
- If the curriculum has no match, write `Not in course curriculum.` - do not hedge with "possibly relates to..."
- Write the file with the Write tool. Do not output the contents in your reply; only confirm the file path and the number of subjects you planned.
```
