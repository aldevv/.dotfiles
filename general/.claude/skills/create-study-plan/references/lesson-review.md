# Lesson reviewer prompt template

Use this template when spawning an `Explore` (read-only) subagent in phase 9e. One reviewer per DOMAIN, NOT per lesson. Substitute every `{VAR}` with the real value before sending.

## Variables

- `{CERT_NAME}`, `{CERT_CODE}`
- `{DOMAIN_NUMBER}`, `{DOMAIN_NAME}`, `{DOMAIN_SLUG}`, `{WEIGHT}`
- `{OUT_DIR}` - absolute path to the study folder
- `{STUDY_GUIDE_PATH}` - absolute path to the study guide
- `{PLAN_PATH}` - `{OUT_DIR}/.planning/{DOMAIN_SLUG}.md`

## Prompt body

```
You are reviewing ALL lesson files for ONE domain of the {CERT_NAME} ({CERT_CODE}) exam. You are read-only; you do not edit files. You return a structured per-domain review in your final message; the orchestrator (Claude) applies fixes or re-spawns lesson agents.

Context:
- Cert: {CERT_NAME} ({CERT_CODE})
- Domain: {DOMAIN_NUMBER}. {DOMAIN_NAME} ({WEIGHT}%)
- Lessons to review: every file under {OUT_DIR}/lessons/{DOMAIN_SLUG}/
- Plan to compare against: {PLAN_PATH}
- Study guide (truth source): {STUDY_GUIDE_PATH}

Process:
1. List the lesson files. Confirm one file per subject in the plan, no extras, no gaps.
2. Read the plan. For each planned subject, open the corresponding lesson file and check criteria below.
3. Spot-check 2-3 lessons against the study guide for factual accuracy.

Per-lesson criteria (apply to each lesson):

a. Coverage: every objective the plan says this lesson covers is actually addressed in the body.
b. Structure: has TL;DR, What it is, Hands-on (if applicable), Watch out for, Course (or none in cert-only mode). No "Sources" section.
c. Style: informal, second person, no filler, no emoji, no motivational text, no em-dashes / double-hyphens as prose punctuation.
d. Length: roughly matches the plan's depth label (short 50-120, medium 100-220, long 200-400 lines). Lessons that cover every objective with concrete bullets / tables / code can land at the lower end and still be complete; only flag a length issue if a lesson is below the lower bound AND missing content, or significantly over the upper bound (which usually means padding).
e. Code blocks: valid syntax for the declared language, with vendor-correct commands and SQL.
f. Course ref: matches the plan exactly (or absent if cert-only mode).
g. No fabrications: any claim not in the study guide is backed by a cited vendor URL.

Cross-cutting criteria (apply across all lessons in this domain):

h. Tone consistency: lessons feel like they came from one author.
i. Redundancy: no two lessons cover the same objective in significant overlap.
j. Weight calibration: total lesson length across the domain is proportional to {WEIGHT}%. (Roughly: 30%+ domains get more total lines than 10% domains.)

Lesson files follow the pattern `subject_<N>_<slug>.md` (the slug comes from the plan's `Slug:` line). Refer to lessons by their subject number plus title in the review, not by raw filename.

Output (return as final message; do not edit anything):

    ## Review: lessons/{DOMAIN_SLUG}/

    Verdict: PASS | NEEDS_FIXES | MAJOR_REWORK

    ### Files reviewed
    - subject_1 (<filename>): <title> (<line count>) - PASS | issues
    - subject_2 (<filename>): ...

    ### Per-lesson findings
    - subject_<N>: <specific issue, citing line numbers or sections when useful>
    - ...
      _(empty list is fine)_

    ### Cross-cutting findings
    - <tone breaks, redundancy, weight calibration, missing files, extra files>
      _(empty list is fine)_

    ### Recommended fixes
    - <"Edit lesson X to ..." for inline edits, or>
    - <"Re-spawn subject_<N> with feedback: <feedback>" for full rewrites>

Verdict rules:
- PASS: every lesson passes per-lesson criteria, cross-cutting clean.
- NEEDS_FIXES: small issues, inline edits will resolve. The orchestrator (Claude) will edit the files directly.
- MAJOR_REWORK: at least one lesson is fundamentally off (missing >1 objective, wrong subject, fabricated content) and needs a full re-write. The orchestrator will re-spawn the lesson agent for those specific subjects.
```
