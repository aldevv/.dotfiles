# Find recommended course (investigate query template)

Use this template when invoking the `investigate` skill in step 6 of the flow. The investigate skill spawns parallel web research agents and returns synthesized findings; this file is the prompt you hand it.

## Variables

- `{CERT_NAME}` - e.g. "SnowPro Core"
- `{CERT_CODE}` - e.g. "COF-C03"
- `{CERT_PAGE_URL}` - official vendor page for the cert
- `{STUDY_GUIDE_PATH}` - absolute path to the downloaded study guide (for grounding context)
- `{DOMAIN_TABLE}` - markdown table of domains and weightings (copy the table from the WebSearch results in step 4 / the in-progress README dossier). Format:

      | # | Domain | Weight |
      | --- | --- | --- |
      | 1 | Snowflake AI Data Cloud Features and Architecture | 31% |
      | 2 | ... | ...% |

## Prompt body

Pass this as the investigate query verbatim, with substitutions applied:

```
Find the best course (any platform) for studying for the {CERT_NAME} ({CERT_CODE}) certification exam. The course will be the user's primary video resource alongside the official study guide.

PLATFORM-NEUTRAL: Udemy, Coursera, Pluralsight, YouTube, edX, A Cloud Guru, vendor-native academies (Snowflake University, AWS Skill Builder, MS Learn, etc.), and independent instructors' sites are all in scope. Do NOT bias toward any specific platform. Rank purely by quality, alignment, and community sentiment.

Selection criteria, in priority order:

1. ALIGNMENT WITH THE OFFICIAL EXAM. The exam covers these domains and weightings (verbatim from the vendor):
{DOMAIN_TABLE}

   A course that systematically covers every domain - especially the higher-weight ones - ranks higher. A course that's heavy on a low-weight domain but skips a high-weight one ranks lower. Official cert page for cross-referencing: {CERT_PAGE_URL}

2. COMMUNITY RECOMMENDATIONS. Sources to consult:
   - r/{CERT_NAME with spaces removed}, r/certifications, r/AWSCertifications, r/Snowflake, etc. - any cert-relevant subreddits in the past 18 months.
   - dev.to / Medium / personal blog posts where the author passed the exam.
   - YouTube reviews and "how I passed X" videos.
   - Vendor community forums (snowflake.com/community for SnowPro, repost.aws for AWS, etc.).
   - LinkedIn posts from certified individuals.
   - GitHub awesome-* lists.
   - certificationhq, ExamTopics, certforums, freecodecamp roundups.

   Community signals are positive but must be FLAGGED in the output, separate from alignment-based reasoning. Some popular courses are popular for non-alignment reasons (early-to-market, charismatic instructor, low price, language); flag those caveats.

3. RECENCY. Courses updated within the last 18 months strongly preferred. Exams refresh (e.g. SnowPro Core C03 replaced C02 in Feb 2026; AWS exam codes refresh on a cycle); outdated courses miss new topics.

4. LENGTH SANITY. Mid-range certs: 15-30 hours of video is normal. <10h is suspiciously thin (probably misses topics); >50h is probably padded. Calibrate to cert depth and domain count.

5. INSTRUCTOR CREDIBILITY. Vendor employees / vendor-certified MVPs / authors of the official prep material outrank generic course farms when content is similar.

Output format - return up to 3 candidates ranked by your overall judgment. For each:

- URL (must be a real, currently-listed course - verify the link resolves).
- Title and instructor.
- Platform.
- Length in hours; last updated date.
- Price (USD if known, "free" if free, "unknown" if you couldn't determine).
- COVERAGE ANALYSIS: for each official domain by name, state strong / medium / weak / missing.
- WHY RECOMMENDED, labeled EXPLICITLY as one of:
  - "study-guide alignment" - alignment with official domains drove this pick.
  - "community recommendation" - popular and well-reviewed, alignment unverified.
  - "both" - alignment AND community signals support this pick.
- COMMUNITY SIGNAL: 1-2 sentences summarizing community sentiment, with at least 2 source URLs cited inline (Reddit thread URLs, blog post URLs, etc.). If no community data was found, say "no community data found".
- CONCERNS / CAVEATS: dated content, missing topics, instructor reputation issues, language (e.g. course is Spanish-only), paywall after preview, etc.

Important: the consumer of your output will surface the "WHY RECOMMENDED" labels and community-signal URLs directly to a human user. The user needs to see WHICH signals drove WHICH ranking so they can weigh them. Do not collapse all signals into a vague endorsement.
```
