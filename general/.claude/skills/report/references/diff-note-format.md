# Hunk note format (canonical, shared)

The single spec for how any skill writes Hunk notes. Every skill that attaches notes via the
`hunk` fast path (`pr-code-review`, `pr-code-review-work`, `fix-bug-work`, `impl-connector`,
`newconnector`, …) follows this — do not keep a private copy. The closing report/verdict that
these notes roll up into is defined in the sibling `format.md`.

Two note kinds share one rule set: **review findings** (something is wrong in the diff) and
**own-work status notes** (what this change did / what a reviewer comment was answered with).
Both are SHORT and both lead with a machine-readable marker.

---

## 1. Batch shape

```json
{
  "comments": [
    { "filePath": "pkg/foo/bar.go", "newLine": 67, "summary": "<marker> <headline>", "rationale": "<short body>" }
  ]
}
```

- Anchor on a REAL changed line: `newLine` for a `+` line (default), `oldLine` for a `-` line.
  Never anchor by `hunkNumber` alone (it lands on a context line). Validate every anchor before applying.
- `summary` = marker + one-line headline (< ~70 chars total after the marker). It shows in the TUI list.
- `rationale` = the body. Keep it TIGHT (see §4).

---

## 2. The marker (leads every `summary`)

### Review finding → `[<SEVERITY> <evidence> ✓N]`
- `<SEVERITY>` ∈ `BLOCKER` / `MAJOR` / `MINOR` / `NIT`, `<evidence>` is the evidence level, and `✓N`
  is the verifier count with its per-level breakdown. Definitions, minimums, and what to report or
  skip live in `~/.claude/rules/review.md` (sections "What to report, what to skip" and "Evidence
  level and verification count"); do not restate them here. `✓0` only for a trivial nit.
- Example: `[MAJOR cited ✓2] users(search:{email}) not in the vendor's documented schema`.
- **Headline = the defect in ONE concrete phrase, like a bug title.** Name the thing that is
  wrong; do not narrate how you found it or hedge whether it counts. `GrantableTo contains a
  non-principal resource type` — NOT `the entitlements are GrantableTo role and Grants() emits
  role-principal grants, which may contradict the policy that…`. The "why it's wrong / is it
  really a problem / confirm-with-owner" reasoning goes in the body (kept minimal) or the report,
  never in the headline. If you can't state the defect in one phrase, you don't understand it well
  enough to file it — keep digging, don't pad. This is the phrase the reader scans; a long or
  hedged one makes them re-derive the point, which is the exact failure to avoid.
- **One finding = one marked note.** A given finding carries its `[<SEVERITY> …]` marker on
  EXACTLY ONE note, so a reader can count findings by counting markers. Never stamp the same
  severity marker on multiple lines for one finding. If a finding genuinely spans two sites, mark
  the primary note and leave the other as an UNMARKED pointer (`see <file>:<line>`) — or, better,
  just leave the one note. This keeps the severity tally honest and the list scannable.

### Own-work status note → `[<STATUS>· <evidence>]`
- `<STATUS>` ∈ `FIXED` / `PARTIAL` / `DEFERRED` / `NEEDS-VERIFY` / `RISK`.
- `<evidence>` = evidence level that the change is correct / the bug is fixed, per
  `~/.claude/rules/review.md` ("Evidence level and verification count"). Use the per-symptom level
  from `fix-bug` when present.
- Add a severity tag `(RISK: <BLOCKER|MAJOR|MINOR>)` ONLY when the note is flagging a regression /
  risk the reviewer must weigh; ordinary "did X" notes carry no severity.
- PR-feedback reply notes also name the reviewer: `[FIXED · reproduced] <reviewer>: <what answered them>`.
- Example: `[PARTIAL · traced] retry path still untested against a live 429`.

### Orientation note (exempt)
Exactly one `Feature Explanation: <headline>` note at the top of the diff carries NO marker.
It is orientation, not a finding/status. Everything else carries a marker.

---

## 3. "Not reproduced" honesty
A note whose evidence level is below `reproduced` on a runtime-behavior claim MUST say in one line
why it was not reproduced (e.g. "needs production data"), per `~/.claude/rules/review.md`.

---

## 4. Length — keep notes short (a human reads these)
The note is a signpost on the diff for a HUMAN, not an essay. Target: **headline + 1-3 sentences.**
Lead the body's first sentence with the essence — what's wrong + the one-line fix — so the reader
gets the point before any qualification. Push policy/edge-case/"confirm-with-owner" nuance to the
last sentence or the report; never open with it. Draft the body, then cut it in half. If the explanation is longer than the code it points at, cut
again. A note over ~5 lines is suspect; move the long-form reasoning to the report / context file
and leave the note as the pointer. The marker + headline must be readable in the TUI list without
expanding. Plain words over jargon. Emojis are welcome when they speed understanding (the severity
glyph in the marker, ✅/⛔ for a status) — never decorative, at most one per line.

**When a link backs the finding, let the link carry the proof.** If the body cites a reference URL
(a spec, doc, standard, upstream issue) that shows the finding is real, the note shrinks to
essentially `[marker] <headline>` plus that link. Do NOT restate or quote what the link says, and
do NOT narrate how you found it: the reader clicks the link for the evidence, so paragraphs above
it are noise. A long note sitting next to a supporting link is the exact overrun this section
exists to prevent: cut until only the defect and the link remain.

Put the link in its OWN PARAGRAPH at the END of the body: separate it from the prose above with a
BLANK LINE (a double newline), never trailing a sentence. Use a labelled line, e.g. `docs: <url>`
(or `ref: <url>` / `spec: <url>`), so it is visually set off and easy to click. One reference
paragraph, last; if there are two links, put them on consecutive lines in that same trailing block.
