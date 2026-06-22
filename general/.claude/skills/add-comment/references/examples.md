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

- done. (×20)
- good catch, will fix. (×1)
- fixed. (×5)
- done (×1)
- fixed. same resolveUserAndRoleNames path on revoke. (×1)
- fixed. uses escapeQueryValue now. (×1)
- fixed. resolveUserAndRoleNames does an api lookup by RecordNo, no DisplayName dependency. (×1)
- deleted. (×2)
- moved to helpers.go. (×1)

### Replies — pushback

- i'd keep this one. nil just means the role doesn't exist (snowflake returns 200 empty), and the same missing role often shows up across lots of grant rows, so caching it saves a bunch of calls. callers already skip on nil anyway. (×1)
- `W` is writeup user, easy to mix up with ws. logindisabled is the ws-only flag per the [docs](https://developer.intacct.com/api/company-console/users/). (×1)
- checked. baton-http's actions.go doesn't unwrap ErrIgnoreError, so a 404 on update_user still fails. confirmed against the mock. (×1)
- enable/disable is not in the connector because the API doesn't expose it (×1)

### New line comments — feedback

- could batch this with a GetManyJSON over the distinct ids before the loop. the old code was already doing that. (×1)
- same on the writes. one SetManyJSON after the loop, like workersToStore. (×1)
- `null when not resolved` doesn't match the `pending column sync` case. the object exists and the type is populated, only the column is missing. should say null only when the object itself is missing (pending table/view replication, or not found). (×1)
- the echo rule lives only here in the deferred branch. step 4 builds the json for resolved and resolved_fallback without restating it, and the terminal block at line 91 says "copy verbatim" but doesn't cover the preset-vs-label split. same input ends up with different data_consumption_mode shapes across runs. would help to state it once near the top and apply everywhere. (×1)
- echo rule only lives here in the deferred branch. step 4 and the line 91 terminal block don't restate the preset-vs-label split, so other statuses come out inconsistent across runs. (×1)
- the read error here gets swallowed and returns nil. the SetManyJSON below then writes only this page's role for the folder, overwriting prior pages' cached roles, and folder.Grants later emits an incomplete grant set silently. propagate the read error up instead. (×1)
- this revoke returns Unimplemented but the entitlement isn't EntitlementImmutable. mark it immutable or implement revoke. same on role.go:259. (×1)

### Top-level PR/MR comments

- tested this locally. `role[]` isn't the cause, the empty `query=` is. `?role[]=admin` alone gives a real meta. add `&query=` and meta goes null. this pr still pulls in `zendesk.CommonOptions` which has no omitempty on Query, so `&query=` still goes out on every request and the cursor won't move at >100/role. (×1)
