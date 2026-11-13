# Review rules

## CRITICAL: Verify review findings with subagents

When I ask you to review something (a PR, a diff, a chunk of code, a design doc, an architecture sketch), **every non-trivial finding must be verified by a subagent before you report it to me.** Use multiple subagents in parallel for anything complex or important. False positives are not acceptable: a confidently-stated claim that turns out to be wrong wastes more time than no review at all.

"Non-trivial" means anything beyond a typo, an obvious style nit, or a one-line surface observation. Behavioral claims, regression claims, security claims, performance claims, "this breaks rule X" claims all require verification.

When in doubt, verify. The cost of a wasted subagent call is minutes; the cost of a wrong assertion is your credibility for the rest of the session.

## CRITICAL: Behavioral claims need reproduction, not source-reading

For a claim about how a system BEHAVES at runtime (an error message, a retry, a serialization, timing, a runtime quirk), verification means reproducing it end-to-end and observing the actual output. Reading or tracing the source is not verification: several agents can read the same code and confidently agree on the wrong answer, so N subagents that all source-traced and none ran the code is N guesses, not a check. Their agreement is not evidence.

Before you tell a teammate (or me) they're wrong about a behavior, reproduce their exact case first: build the real artifact at the version actually in use (the pinned dependency, not `main`/HEAD), trigger the exact path, and look at what it actually produces. One real run outranks any amount of static analysis and settles the disagreement. Only assert they're wrong after it fails to reproduce; if you genuinely can't run it, call the claim unverified rather than rebutting it from source.

## CRITICAL: What to report, what to skip

Precision comes from explicit criteria, not from "only report high-confidence findings".

**Report:** correctness bugs (wrong output, crash, data loss, broken edge case), security issues, regressions against current behavior, breaking changes for existing users/config, a violated rule from a loaded CLAUDE.md / rules / lazy file (cite it), missing error handling at a trust boundary, a test that cannot fail.

**Skip:** style and formatting a linter owns, naming preferences, "could be cleaner" refactors with no defect, patterns that match the surrounding code, speculative perf with no measured or obvious hot path, anything already flagged by another reviewer on the same line.

**Severity (for my own findings; for someone else's comments use the severity they stated):**
- **Blocker:** wrong behavior or data/security impact on a real path. E.g. a pagination loop that drops the last page; a token logged in plaintext.
- **Major:** real defect on a narrower path, or a rule violation that will bite later. E.g. a 5xx swallowed so the job reports success; a new required permission with no docs update.
- **Minor:** correct today but fragile or misleading. E.g. an error message missing the operation name; a magic string that should be a constant per a loaded rule.
- **Nit:** only if the user asked for nits.

## CRITICAL: Evidence level and verification count on every finding

Every review finding (whether posted in chat, drafted as a comment, or written into a report) carries an **evidence level** and a **`✓N` count**. No confidence percentages: self-reported percentages are uncalibrated and mean nothing checkable.

Evidence levels, strongest first:
- `reproduced`: ran it (test, curl, real binary at the pinned version) and observed the claimed behavior.
- `cited`: quoted from an authoritative spec or doc (OpenAPI, vendor docs, a loaded rule file), with the link or file:line.
- `traced`: read the code path end to end with file:line for each hop, but did not run it.
- `inferred`: pattern-matched or reasoned without tracing the full path.
- `unverified`: no check possible (code/spec not accessible). Say why.

`✓N` is the number of independent verifiers, broken down by the evidence each one reached when they differ: `✓3 (1 reproduced, 2 traced)`. Agreement between verifiers who only `traced` is weaker than one `reproduced`; never present `✓3 traced` as stronger than `✓1 reproduced`. The finding's level is the strongest level any verifier reached.

Minimums: behavioral/runtime claims need `reproduced`, or are reported as `traced` with "not reproduced: <reason>". API-surface claims need `cited`. Everything non-trivial needs `✓1` or higher; `✓0` is only for trivial nits.

Example formats:
- `[reproduced ✓2] <claim>`
- `[traced ✓3] <claim>. Not reproduced: needs production data.`
- Summary: `5 findings: 2 reproduced, 1 cited, 2 traced. All ✓2+.`

If verifiers disagree, surface the disagreement in the row and downgrade the level; don't average it silently.

## CRITICAL: Present findings as a table

Always present review/code-review issues and findings as a table in chat output (one row per finding), never as a prose list. Applies to every review, any repo. Include **Evidence** and `✓N` as their own columns so each row satisfies the evidence rule above.

Every such table MUST also carry a **Status** column showing done vs not done (`✅ done` / `⚠️ not done` / `🔄 pending` / `deferred`), so I can tell at a glance which items are resolved. Add a **Severity** column too: for my own findings use the definitions above; for someone else's comments use the severity they stated (a reviewer/bot glyph like 🔴/🟠/🟡, a stated Blocking/Major/Minor/Nit, or a review state), `-` for rows with none, and never invent a severity a human didn't state. Applies to any table of findings, PR/MR comments, issues, or work items, not just formal reviews.

## Workflow

1. Read the artifact under review yourself first.
2. Draft findings privately; drop anything on the skip list.
3. For each non-trivial finding, spawn a subagent (or several in parallel for important/complex items) to independently verify the claim. Tell each verifier the evidence level it must reach (reproduce for behavior, cite for API claims) and to report the level it actually reached.
4. Adjust, downgrade, or drop findings based on subagent results.
5. Report only the surviving findings, each tagged with evidence level, `✓N`, and severity.

Walking back a wrong claim later costs more than spending the extra minute on verification up front.
