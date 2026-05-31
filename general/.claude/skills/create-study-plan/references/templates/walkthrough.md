# study-plan.md walkthrough template

Use this skeleton for `<out-dir>/study-plan.md` (step 8 of the create-study-plan flow). The file should read like notes a friend wrote, not a textbook.

## Skeleton

````markdown
# <Cert> study plan

What this is: every objective the exam covers, in plain language, with a pointer to the matching course video where one exists.

Read top to bottom or jump to whatever you want. The bullets are the "you need to know this" list. If you can answer them out loud, move on.

## 1. <Domain name> (<weight>%)

### <Objective / topic title>

<One informal sentence: what this thing is.>

- <Need-to-know bullet.>
- <Another.>
- <Watch out for: ...>

Course: §<N> <Unidad title> · Video <M>: <video title>

### <Next topic>

<One sentence.>

- <Bullet.>

Not in course curriculum.

## 2. <Next domain> (<weight>%)
...
````

## Per-block rules

- One-sentence what-it-is. Plain language. If you can't compress it to one sentence, you don't understand it yet; read the guide again.
- 2-6 need-to-know bullets. No more. If a topic genuinely needs more, split into two sub-topics.
- Code blocks for SQL/CLI/syntax worth memorizing (e.g. `COPY INTO ... FROM @stage`, `kubectl get pods -A`). Skip code blocks for conceptual topics.
- Course line is one line, not a paragraph. Either `Course: §N <title> · Video M: <title>` or `Not in course curriculum.` In cert-only mode (no `curriculum.md`), omit the course line entirely - don't write "Not in course curriculum." for every topic.
- No "Sources" or "Further reading" section. The README has those.
- No emoji. No motivational text. No "good luck!"

## Tone calibration ("informal, easy")

- Use second person ("you can do X"), contractions ("don't", "it's"), short sentences.
- Prefer verbs over nominalizations ("you load data" not "the loading of data").
- Concrete > abstract: name the actual command, error code, or limit, not "various options exist".

## Cross-referencing with the course

- Match each objective to course lectures by keyword on the lecture title (case-insensitive, tolerate slight wording differences). The course's section numbers + video numbers are in `curriculum.md` (`## Unidad N: <title>` and `<M>. <video title>`).
- If you find a match, cite as `Course: §N <Unidad title> · Video M: <video title>`.
- If no lecture clearly maps to the objective, write `Not in course curriculum.` Don't hedge with "maybe related to" - either it's covered or it's not.
- If a course lecture maps to an objective but the title is approximate, still cite it. If the match is genuinely ambiguous, cite the best candidate and add `(approximate match)`.
