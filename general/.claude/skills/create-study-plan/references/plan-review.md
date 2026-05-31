# Plan reviewer prompt template

Use this template when spawning an `Explore` (read-only) subagent in phase 8c. Substitute every `{VAR}` with the real value before sending.

## Variables

- `{CERT_NAME}`, `{CERT_CODE}`
- `{DOMAIN_NUMBER}`, `{DOMAIN_NAME}`, `{DOMAIN_SLUG}`, `{WEIGHT}`
- `{OUT_DIR}` - absolute path to the study folder
- `{STUDY_GUIDE_PATH}` - absolute path to the study guide
- `{CURRICULUM_PATH}` - absolute path to `curriculum.md`, or `N/A`

## Prompt body

```
You are reviewing ONE per-domain lesson-pack plan for the {CERT_NAME} ({CERT_CODE}) exam. You are read-only; you do not edit files. You return a structured review report in your final message; the orchestrator (Claude) applies the fixes.

Context:
- Cert: {CERT_NAME} ({CERT_CODE})
- Domain: {DOMAIN_NUMBER}. {DOMAIN_NAME} ({WEIGHT}%)
- Plan to review: {OUT_DIR}/.planning/{DOMAIN_SLUG}.md
- Study guide (truth source): {STUDY_GUIDE_PATH}
- Curriculum (for verifying course refs): {CURRICULUM_PATH}

Review criteria (work through each):

1. Coverage. Open the study guide, list every objective for domain {DOMAIN_NUMBER}. Compare to the plan. Flag any objective the plan didn't address.
2. Weight calibration. Subject count must fit the {WEIGHT}% weight bracket:
   - >=30% expects 6-10 subjects
   - 20-29% expects 4-7
   - 10-19% expects 3-5
   - <10% expects 2-4
   Flag if the count is outside the bracket.
3. Course reference accuracy. For each `Course: §N ... · Video M: ...` line in the plan, verify the lecture actually exists in {CURRICULUM_PATH} with the cited section and video number. Flag mismatches.
4. "Not in course curriculum." honesty. For any subject marked as not in the course, scan {CURRICULUM_PATH} for any obviously related lecture title. If one exists, flag it as a missed citation.
5. Non-overlap. Two subjects should not cover the same objective. Flag duplicates.
6. Subject titles. Should be specific (not "Misc topics", "Other", etc.).

Output (return as your final message, do not write any file):

    ## Review: domain {DOMAIN_NUMBER} ({DOMAIN_SLUG})

    Verdict: PASS | NEEDS_FIXES | MAJOR_REWORK

    ### Coverage gaps
    - <verbatim objective from study guide not in the plan>
    - ...
      _(empty list is fine)_

    ### Weight calibration
    - <PASS or "N subjects is outside the {WEIGHT}% bracket; expect X-Y">

    ### Course reference issues
    - subject_<N>: <issue>
    - ...
      _(empty list is fine)_

    ### Other findings
    - <duplicate coverage, vague titles, etc.>

    ### Recommended fixes
    - <concrete edit the orchestrator should apply>
    - ...

Verdict rules:
- PASS: zero gaps, zero ref issues, weight calibration in range.
- NEEDS_FIXES: small issues addressable by inline edits to the plan file.
- MAJOR_REWORK: missing >2 objectives, or weight calibration off by >50%, or pervasive structural problems. The orchestrator will re-spawn the plan agent for this domain with your findings.
```
