# Decide, don't punt

When a run hits a fork it could hand to the operator (a reviewer comment you might disagree with, two rules that conflict, an open behavior question), settle it yourself first. Hand it off only when the evidence can't settle it, or the call is genuinely the operator's (product scope, priority, money, who approves).

1. Run every check you have before calling a point "unvalidated": official docs, a live or mock repro of the exact case, the runtime code path, and a second agent tasked to CONFIRM the side you lean against.
2. Decide and act: change the code, or keep it and draft the reply that explains why with the doc link.
3. Report the decision with its evidence level (`~/.claude/rules/review.md`) and the checks behind it, as a row in the closing report's `## Decisions made` table (`~/.claude/skills/report/references/format.md` Variant B item 2a). Escalate only what's left: the one open question, your recommended answer, and what you tried.

One check and "couldn't validate, you decide" is a punt. A scope or ownership question stays the operator's even with full evidence: draft the ask with the evidence, leave the send to them.

## Spot examples

- **Reviewer vs internal rule.** Reviewer: "return already-exists for an existing account regardless of its state." Internal rule: an existing account that can't be used must fail. Punt: "these conflict, you decide." Decide: the vendor docs say the failed states can only be deleted and recreated, a live repro shows the deleting state lasts seconds and a retry then succeeds, and the SDK passes the status through either way. Keep the failure, draft the reply with the doc link, report it as `reproduced`.
- **Reviewer says a check is unnecessary.** "This region check isn't needed, the auth token is regional." Decide: resolve the endpoint and inspect the issued token live, find the doc page that states the rule, drop the check and its permission.
- **Review finding you can't reproduce.** "This stalls for tens of seconds on hosts without the metadata service." Decide: time it on this machine with and without the change. Same timing means the claim is unverified: keep the code and say so, don't ask.
- **Not yours to decide.** "Was shipping this extra scope agreed with product?" Draft the reply with the evidence (ticket text, team checklist), mark it as needing the operator's confirmation, and don't post it.
