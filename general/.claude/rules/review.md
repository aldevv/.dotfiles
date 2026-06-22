# Review rules

## CRITICAL: Verify review findings with subagents

When I ask you to review something (a PR, a diff, a chunk of code, a design doc, an architecture sketch), **every non-trivial finding must be verified by a subagent before you report it to me.** Use multiple subagents in parallel for anything complex or important. False positives are not acceptable: a confidently-stated claim that turns out to be wrong wastes more time than no review at all.

"Non-trivial" means anything beyond a typo, an obvious style nit, or a one-line surface observation. Behavioral claims, regression claims, security claims, performance claims, "this breaks rule X" claims all require verification.

When in doubt, verify. The cost of a wasted subagent call is minutes; the cost of a wrong assertion is your credibility for the rest of the session.

## CRITICAL: Confidence indicator on every finding

Every review finding (whether posted in chat, drafted as a comment, or written into a report) must carry two things:

- **A confidence percentage** (`0%`–`100%`) reflecting how sure you are after verification.
- **A `✓N` marker** where `N` is the number of subagents that independently checked the finding. `✓0` means unverified (only allowed for trivial nits; everything else must be `✓1` or higher).

Example formats that satisfy this rule:
- `Finding: <claim>. Confidence 85% ✓3.`
- `[92% ✓2] <claim>`
- A summary line: `5 findings reported: 3× ✓3, 2× ✓1. Confidence range 70–95%.`

If multiple subagents disagree, surface the disagreement and lower the confidence; don't average it silently. If a subagent could not verify because the relevant code/spec wasn't accessible, say so explicitly and mark the finding `✓0 (unverifiable)`, don't pretend it was checked.

## Workflow

1. Read the artifact under review yourself first.
2. Draft findings privately.
3. For each non-trivial finding, spawn a subagent (or several in parallel for important/complex items) to independently verify the claim against the actual code/docs.
4. Adjust or drop findings based on subagent results.
5. Report only the surviving findings, each tagged with confidence % and `✓N`.

Walking back a wrong claim later costs more than spending the extra minute on verification up front.
