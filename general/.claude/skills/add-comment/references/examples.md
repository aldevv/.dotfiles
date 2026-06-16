# add-comment usage log

Real comments posted via this skill, deduplicated with use counts. The skill
reads this file before drafting so voice stays consistent and overused phrasings
are visible. After every successful post, the chosen text is recorded here via
`scripts/record_example.py` — same comment text in the same category just bumps
the `(×N)` counter rather than adding a duplicate line.

The seed entries below are the original voice training examples; live posts
increment from there.

## Answers

### Replies — agreeing or already done

- done. (×9)
- good catch, will fix. (×1)

### Replies — pushback

- i'd keep this one. nil just means the role doesn't exist (snowflake returns 200 empty), and the same missing role often shows up across lots of grant rows, so caching it saves a bunch of calls. callers already skip on nil anyway. (×1)

### New line comments — feedback

- could batch this with a GetManyJSON over the distinct ids before the loop. the old code was already doing that. (×1)
- same on the writes. one SetManyJSON after the loop, like workersToStore. (×1)
- `null when not resolved` doesn't match the `pending column sync` case. the object exists and the type is populated, only the column is missing. should say null only when the object itself is missing (pending table/view replication, or not found). (×1)
- the echo rule lives only here in the deferred branch. step 4 builds the json for resolved and resolved_fallback without restating it, and the terminal block at line 91 says "copy verbatim" but doesn't cover the preset-vs-label split. same input ends up with different data_consumption_mode shapes across runs. would help to state it once near the top and apply everywhere. (×1)
- echo rule only lives here in the deferred branch. step 4 and the line 91 terminal block don't restate the preset-vs-label split, so other statuses come out inconsistent across runs. (×1)
