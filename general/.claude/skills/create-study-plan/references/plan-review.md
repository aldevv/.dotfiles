# Plan reviewer prompt template

Use this template when spawning a single `Explore` (read-only) subagent in phase 9c. ONE agent reviews ALL domain plans at once. Substitute every `{VAR}` with the real value before sending.

## Variables

- `{CERT_NAME}`, `{CERT_CODE}`
- `{OUT_DIR}` - absolute path to the study folder
- `{STUDY_GUIDE_PATH}` - absolute path to the study guide
- `{CURRICULUM_PATH}` - absolute path to `curriculum.md`, or `N/A`
- `{DOMAIN_TABLE}` - markdown table of domains (vendor number, name, weight, slug). Drop straight from the README. Example:

      | # | Domain | Weight | Slug |
      | --- | --- | --- | --- |
      | 1 | Snowflake AI Data Cloud Features and Architecture | 31% | 1-snowflake-ai-data-cloud-features-and-architecture |
      | 2 | Account Management and Data Governance | 20% | 2-account-management-and-data-governance |
      | ... |

## Prompt body

```
You are reviewing per-domain lesson-pack plans for the {CERT_NAME} ({CERT_CODE}) exam. You are read-only; you do not edit files. You return a structured per-domain review report in your final message; the orchestrator (Claude) applies the fixes.

Context:
- Cert: {CERT_NAME} ({CERT_CODE})
- Study guide (truth source): {STUDY_GUIDE_PATH}
- Curriculum (for verifying course refs): {CURRICULUM_PATH}
- Domains under review:
{DOMAIN_TABLE}
- Plans to review (one file per domain): {OUT_DIR}/.planning/<domain-slug>.md, for every domain-slug in the table above.

Process:
1. Read every plan file under {OUT_DIR}/.planning/.
2. Read the study guide. Use Read with `pages:` if PDF >10 pages.
3. Read the curriculum if it exists.
4. For each domain, work through the criteria below and write a per-domain review block.

Per-domain review criteria:

1. Coverage. Every objective the study guide lists for this domain must be addressed by some subject in the plan. Flag any missing objective verbatim.
2. Weight calibration. Subject count must fit the weight bracket:
   - >=30% expects 6-10 subjects
   - 20-29% expects 4-7
   - 10-19% expects 3-5
   - <10% expects 2-4
   Flag if the count is outside the bracket.
3. Course reference accuracy. For each `Course: §N ... · Video M: ...` line, verify the lecture exists in the curriculum at that section and video. Flag mismatches.
4. "Not in course curriculum." honesty. For any subject marked as such, scan the curriculum for obviously related lectures. If one exists, flag it as a missed citation.
5. Non-overlap. No two subjects should cover the same objective. Flag duplicates.
6. Subject titles and slugs. Titles should be specific (not "Misc topics", "Other"). Every subject must have a `Slug:` line, lowercased, hyphen-separated, derived from the title.
7. Verbatim objectives. The plan's objective bullets must match the study guide word-for-word. Flag paraphrases.

Output (return as your final message, do not write any file):

    # Plan review: {CERT_NAME} ({CERT_CODE})

    ## Domain <N>: <name>

    Verdict: PASS | NEEDS_FIXES | MAJOR_REWORK

    ### Coverage gaps
    - <verbatim objective from study guide not in the plan>
      _(empty list is fine)_

    ### Weight calibration
    - <PASS or "N subjects is outside the <W>% bracket; expect X-Y">

    ### Course reference issues
    - subject_<N>: <issue>
      _(empty list is fine)_

    ### Slug / title issues
    - subject_<N>: <issue>
      _(empty list is fine)_

    ### Other findings
    - <duplicate coverage, paraphrased objectives, etc.>

    ### Recommended fixes
    - <concrete edit the orchestrator should apply>

    ## Domain <N+1>: ...
    (same shape)

Verdict rules:
- PASS: zero gaps, zero ref issues, weight calibration in range, slugs present.
- NEEDS_FIXES: small issues addressable by inline edits to the plan file.
- MAJOR_REWORK: missing >2 objectives, weight calibration off by >50%, missing slugs across multiple subjects, or pervasive structural problems. The orchestrator will re-spawn the plan agent for that domain with your findings.

Final note: produce one block per domain. Don't editorialize between blocks. Don't suggest cross-domain refactors here; this review is per-domain.
```
