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

- done. (×117)
- good catch, will fix. (×1)
- fixed. (×12)
- done (×16)
- fixed. same `resolveOrderAndItemNames` path on refund. (×1)
- fixed. uses escapeQueryValue now. (×1)
- fixed. `resolveOrderAndItemNames` does an api lookup by `OrderID`, no `DisplayName` dependency. (×1)
- deleted. (×2)
- moved to helpers.go. (×1)
- fixed (×2)
- fixed. no longer seeded from public data. (×1)
- added `codes.AlreadyExists` (×1)
- yes, only when we can't read `ORDER_ITEMS`. dropped the skip so it just fails now. (×1)
- I cleaned those up (×1)
- yep, is a user held credential, so i chose `API_TOKEN`. (×1)
- added a comment (×1)
- done, moved the token calc inside `ListOrderItemsPage`. (×1)
- done. switched it to `logo.svg`, traced from the official mark (the apple-touch png) since <vendor> doesn't publish a square svg. (×1)
- done. stripped the xml decl, doctype and potrace metadata; square viewBox only now. (×1)
- you're right. done (×1)
- routed `resolveScheme` through the shared `IsNativeURL` instead of a TODO, so the three detectors agree and a native url resolves to `postgres` there now. (×1)
- done, folded `IsNativeURL` and `URLDatabase` into one `ParseNativeURL` pass. (×1)
- will narrow the title to postgres and link the mysql follow-up. (×1)
- done. mysql opt-in is the follow-up pr. (×1)
- done. placeholder values carrying `;`/`{`/`}`/`=` get rejected now so they can't inject keywords. a whole-url-in-one-var still works. (×1)
- yeah. when i rebase the follow-up i'll thread both `operation` and `idempotencyKey` through together so the prefix fix doesn't get dropped. (×1)
- fixed. the table and column operands use `|identifier` now, and the check queries drop `UPPER()` so they match the exact quoted names. same in `docs/mysql.md`. (×1)
- added a `|keyword` renderer (letters, digits, single spaces only), so `ORDER BY` renders intact and injection is rejected. example uses it now. (×1)
- fixed. the opt-in now needs at least one validation query, vars-checks them, and requires `no_transaction: true` on ddl engines. (×1)
- fixed. postgres stays default-on by engine (unchanged from the earlier pr), only mysql needs the opt-in now. (×1)
- ok (×1)
- documented it. (×1)
- good catch. it's bounded though: `authFatal` has a 5 min TTL (`authFatalTTL`), so even when `Cleanup` never runs the terminal cache self-expires and a since-fixed credential recovers on the next run. the TTL exists for exactly this case. (×1)
- done, switched to `store.Open` which reads the v3 format too. good catch. (×1)
- done, the zstd path is gone now, reads through the shared store. (×1)
- is true, the early catch ran before `wrapClientError` so it came back `codes.Unknown`. routed both 409 sites through the wrapper now so they carry `codes.AlreadyExists` (×1)
- done, switched both to `B`. (×1)
- now returns the error on 404 (×1)
- done. `pending_delete` shows as inactive, not deleted, since the order can still be restored in the grace period. the raw status goes in the details. (×1)
- on purpose, it's what cancel wrote before and what `CreateOrder` gives new orders. added a line. `ReadOnly` follow-up sounds good. (×1)
- agreed, leaving it for a follow-up. (×1)
- done. it double-prefixes now since `fetchReport` already adds `myapp:`, same as the json builders. (×1)
- added a note on the struct that it assumes one import per process. no map since nothing overlaps imports today. (×1)
- agreed, leaving it. (×1)
- thanks for checking it. (×1)
- dropped the cache config. (×1)
- dropped the bare `config_ref` and documented the explicit allowlist entry. (×1)
- done. tn70 !49 needs its override renamed from `integration-python311` to `integration-python311-el9`, otherwise the new rule skips it (×1)
- fixed it, the cache is keyed by job ID now and keeps the last 2. (×1)
- done, it skips the change call when nothing changed. two differences: the email compare is exact since <vendor> keeps case, so a case-only change is a real change. phone compares `phone_digits` instead of `formatted`, which carries the country code. kept the docs tip, the ui still re-runs the action until the value shows up on the next fetch. (×1)
- confirmed, `GET /users/{id}` returns deactivated users without a flag, only an unknown id 404s. so `Get` marks them inactive. added a deactivated case to `TestUsersGet` too. (×1)
- done, an empty job ID skips the cache now. the queue lib also fails a job with no ID (`ErrNoJobID` in the worker package), so it shouldn't happen. (×1)
- dropped them. the endpoint comes from the region now and `base-url` is a hidden cli-only override. (×1)
- opened <link> (×1)

### Replies — pushback

- i'd keep this one. nil just means the item doesn't exist (the api returns 200 empty), and the same missing item often shows up across lots of order rows, so caching it saves a bunch of calls. callers already skip on nil anyway. (×1)
- `W` is the web user, easy to mix up with `S`. `loginDisabled` is the `S`-only flag per the [docs](<link>). (×1)
- checked. the http client's retry.go doesn't unwrap `ErrIgnored`, so a 404 on update_order still fails. confirmed against the mock. (×1)
- pause/resume is not in the client because the API doesn't expose it (×1)
- Couldn't find a 400 in the OpenAPI, so I kept 409 and just expanded the message to cover self / last admin / bulk. (×1)
- new success_condition catches it. so it works as is (×1)
- not a blocker, the runtime has no web crypto. (×1)
- keeping math.random. the runtime has no web crypto. (×1)
- i think is ok to keep it, <vendor> caps the endpoint at 50 calls/min account-wide, and the response headers only warn us after we've already queued more requests. <link> (×1)
- looked closer at this and you're right, deleting it. the client's retry loop already retries `codes.Unavailable` with unlimited attempts by default and backs off using the real `*RateLimitInfo` (reset time, remaining count) instead of guessing, so the client-side pacer wasn't buying us anything for correctness. removed `WithRateLimiter` and the `options`/`WithRateLimit` plumbing around it. (×1)
- won't work here. `FieldsMutuallyExclusive` needs fields that aren't required, and it only checks the current group. it'd miss leftover oauth creds under api-key mode. (×1)
- I don't think it works in worker mode, the order in `Process`/`Retry` is rebuilt from just its `ResourceId` there, so a `regionId` on the payload is empty. `Id.Resource` is the only field we still get on that path, and encoding the region there re-keys every existing order. (×1)
- i added it. `DISTINCT` + `WITHIN GROUP` doesn't compile against `STRING_AGG`, but i dropped `DISTINCT` and it works. (×1)
- keeping `Warn` for visibility. (×1)
- intentional, postgres is the only engine i've verified this on. filed the mysql follow-up as <TICKET>. (×1)
- kept the behavior, added a comment that it leans on the postgres `check_queries` contract and shouldn't be generalized. (×1)
- intended postgres case, keeping it. the test name and the new code comment spell out the trade-off. (×1)
- added `limit`/`offset`. loud-failing the bare-array branch would change behavior. (×1)
- false positive i think. the generator only uses `dirname(entry)` to find `specs/`, it never opens the entry file. `specs/` is at the repo root in a standalone repo so the dir has to be `$PWD`. adding `src/` points it at `$PWD/src/specs/source` which doesn't exist. (×1)
- done, but kept `a.line_id`. `line.source_id` is the adjustment id, so it'd just repeat `adjustment_id`. (×1)
- the `adjustment.source_id` isnt the line id, `line.source_id` holds the `adj_id`, so I think we need the line table to get `line_id` (×1)
- didn't add an `account_type` check, but a 403 from the billing api now says the account isn't owned by the org (trial accounts never are) or the key is missing billing access. a 404 still comes back as is. (×1)
- yeah, known gap. without the org key, `Delete` and the pause/resume actions fail right away with an error naming `org-id` and `api-token`, so it's not silent. leaving the flags static for now. (×1)
- dropped the state check, it sets the value directly now. the user walk has to stay because every write command takes a username and the api can't look a user up by id. <link> (×1)
- workers can't read the space profile yet, so keeping `DescribeSpace` until the client supports it. (×1)
- same client gap as the spaces thread, workers can't read the profile yet. (×1)
- can't assert it from the probe. it runs through the cli and the local runner drops the response (`_, err = r.client.Update(...)` in `runner.go:194`). `Update` itself returns `Replaced` with the old item's id for own and inherited items, same id the import emits, and nothing for an untrusted item or no item. can add a go test that calls `Update` directly if you want it in ci. (×1)
- same client gap as the spaces thread. workers only get the id, type, name and parent (`types.d.ts` in the client), so the owner from `ListSpaces` can't reach them. keeping `DescribeSpace` until the client passes it through. (×1)
- task errors don't reach the caller as a gRPC code, the queue passes them back as a plain string. so i'd keep `fmt.Errorf` here. (×1)
- named regions come back even when disabled, so `requireDefaultRegion` already rejects them. <link> (×1)
- a `Failed` job can't be used and only delete + recreate fixes it, so linking it would report a job the user can't open. (×1)

### New line comments — feedback

- could batch this with a GetManyJSON over the distinct ids before the loop. the old code was already doing that. (×1)
- same on the writes. one SetManyJSON after the loop, like ordersToStore. (×1)
- `null when not resolved` doesn't match the `pending column backfill` case. the object exists and the type is populated, only the column is missing. should say null only when the object itself is missing (pending table/view replication, or not found). (×1)
- the echo rule lives only here in the deferred branch. step 4 builds the json for resolved and resolved_fallback without restating it, and the terminal block at line 91 says "copy verbatim" but doesn't cover the preset-vs-label split. same input ends up with different output_mode shapes across runs. would help to state it once near the top and apply everywhere. (×1)
- echo rule only lives here in the deferred branch. step 4 and the line 91 terminal block don't restate the preset-vs-label split, so other statuses come out inconsistent across runs. (×1)
- the read error here gets swallowed and returns nil. the SetManyJSON below then writes only this page's tag for the folder, overwriting prior pages' cached tags, and `folder.Items` later emits an incomplete set silently. propagate the read error up instead. (×1)
- this `Delete` returns Unimplemented but the item isn't marked `ReadOnly`. mark it read-only or implement delete. same on tag.go:259. (×1)
- dropping the annotation here. empty today so nothing breaks, but rate-limit hints would get silently lost if they ever land. could pass it through `ListResult.Annotations`. (×1)
- checkout needs to run before setup-go, otherwise `go-version-file: go.mod` errors out once `if: false` flips. (×1)
- the lib caps batches at 50 per bucket id (`maxItemsPerBatch` in `batch/batcher.go:255`). the key is per-envType, so every label in one environment shares one bucket. <vendor> allows unlimited custom labels, so >50 in any env will fail the import. worth a code comment here calling out the cap as a known limitation. (×1)
- <vendor>'s Role enum is `[Admin, Billing, Developer, Editor, Viewer, Auditor]`. `Owner` isn't valid and three real values are missing. Fix the list. (<link>) (×1)
- if the caller passes `items: []`, `updateOrderHandler` still appends "items" to `updated`, so the guard passes but the PATCH goes out with an empty body and the api 400s per RFC 6902. Guard `len(ops)==0` here before `newPatchRequest`. (×1)
- `FEATURE_DELETE` and `FEATURE_ACTIONS` ship unconditionally, but Delete and the three actions all require the admin api. On oauth-only setups the UI shows buttons that 500 at invoke. Gate the flags on `AdminConfigured()` in `client.go`, or return `codes.Unimplemented` (×1)
- `POST /v1/transferContent` requires the `account.content.transfer` scope per <vendor>'s docs, separate from `account.read`. Since Delete calls it, existing users who only enabled `account.read` will 403 at Delete time. Add it here. (spec: <link>) (×1)
- delete idempotency never fires. the real not-found message is `could not find the target or you are unauthorized.` and none of the substrings match. add that string or key off `Extensions["errorClass"]`. (spec: <link>) (×1)
- this drains every page to find one email AND returns the wrong ID (v1 aggregator, not the v2 id the mutations need). one filtered v2 query fixes both. (spec: <link>) (×1)
- updating also needs the **domain manager** role. worth calling out near the warning at line 23. (spec: <link>) (×1)
- this drains every org's projects paginated to find one owner. fix is having `parentID` and return InvalidArgument otherwise. (×1)
- drop `none` here. createorder rejects it; it's still fine for the update action. (×1)
- `ListOrganizations` doesn't paginate. <vendor> supports it (max perPage=9000). cli delete fallback misses orgs past page 1 (<link>) (×1)
- same, `ListTeams` doesn't paginate. default page = 50, orgs with more teams lose them. <link> (×1)
- these all surface to the caller as codes.Unknown, and every other vendorsdk error in the client has the same problem. worth adding a MapAPIError helper next to IsAlreadyExistsError that unwraps *vendorsdk.APIError and returns the matching gRPC code (429 and 5xx as Unavailable, 403 as PermissionDenied, 400 as InvalidArgument, etc), then wrapping every vendorsdk call site with status.Error(MapAPIError(err), ...). (×1)
- these all surface to the caller as `codes.Unknown`, and every other `vendorsdk` error in the client has the same problem. worth adding a `MapAPIError` helper next to `IsAlreadyExistsError` that unwraps `*vendorsdk.APIError` and returns the matching gRPC code (`429` and `5xx` as `codes.Unavailable`, `403` as `codes.PermissionDenied`, `400` as `codes.InvalidArgument`, etc), then wrapping every `vendorsdk` call site with `status.Error(MapAPIError(err), ...)`. (×1)
- `parent_item` works in `tmpl:` but isn't a declared cel variable in the config loader, so `organization_id` here (and the static label at :177) fails `Validate` with `undeclared reference to 'parent_item'` and the import returns 0 rows. i built the branch and ran an import against the mock to confirm. `go build`/`go vet` won't catch this, only a run does. needs a cel-reachable org id, or derive `organization_id` another way. (×1)
- both `user` and `userAccount` register as handlers, so the lib's `getAuthDetails` picks the auth option nondeterministically (`options` flips between `NO_PASSWORD` and `RANDOM_PASSWORD`). (×1)
- `hostname` skips `quoteValue` here. `url.Parse` keeps `;` in the host, so `pg://...@host;SSLMODE=off:.../db` injects `SSLMODE=off` as a connection keyword. wrap it like the other fields. (×1)
- not sure this will work for a user in more than one org. `GET /api/1/users` looks account-wide, so the same user would dedupe to one row and only keep the last org's items. docs: <link> (×1)
- should `userName` allow more than 8-16 alphanumerics? the docs say it needs to match the email address, so it could contain any character an email can. <link> (×1)
- right now it lists every workspace again for each membership and key, with no caching, so a run makes a lot of extra api calls on bigger orgs. better to switch to the v2 loader and keep the workspace ids in a shared cache: save them in `workspaceLoader.List` and read them in `Items`. (×2)
- `CreateOrder` only sends `email`/`firstName`/`lastName`/`memberType`, but the form schema also offers `userKind` and `sendInvite`. `userKind` is a real create field, so setting it to `guest`/`embed` gets silently dropped, and `sendInvite` isn't a create param at all. could we wire `userKind` (and `isGuest`) in, or drop those two from the schema so it's not offering inputs that do nothing? <link> (×1)
- `*assigned.LastUpdated` is deref'd with no nil check (same at :509). <link> (×1)
- `README.md:44` still says `Full control` for quarantine, can you flip it to `Read/Write` there too? otherwise it disagrees with this line. (×1)
- `wrapError` drops the response body, so a CSRF-enabled setup now gets `403 Forbidden` instead of `CSRF nonce validation failed`, the string the README tells people to look for. could we carry `messages[].title` into the error? (×1)
- until `extend_data_disk_linux` exists in `/commands` this returns `undefined`, so linux machines quietly get no command. we'll need to create it in dev and prod before this ships. (×1)
- empty `os` falls back to windows here, but the backend's `OSType` falls back to the persona. a linux box with no `instance.osType` would get the windows plan and fail. could skip the command when `os` is empty instead? (×1)
- this should send a chat alert, it's a failure someone needs to see. same for the other early returns here (command not found, `CommandRun` failed). and i'd drop the success messages, alerts should only fire when something goes wrong. (×1)
- <db> doesn't raise <error code> when revoking a role. a multi-account revoke where only some accounts hold the role succeeds and removes that edge, and revoking from an account that doesn't hold it is silent too. so the old single revoke already handled the partial case. could we drop `revokePerVariant`, `isNoSuchGrantErr` and `splitAccount`? per-variant also means a failure halfway leaves some accounts revoked and others not. (×1)
- I think this shipped in 0.1.1, not 0.1.0. The 0.1.0 tag and image still have the old config fields (the split is a later commit). Same in README lines 27 and 29. (×1)

### Top-level PR/MR comments

- tested this locally. `role[]` isn't the cause, the empty `query=` is. `?role[]=admin` alone gives a real meta. add `&query=` and meta goes null. this pr still pulls in `vendor.CommonOptions` which has no omitempty on Query, so `&query=` still goes out on every request and the cursor won't move at >100/role. (×1)
- docs/api.mdx table is stale, doesn't reflect the new create / delete / actions surface. same in readme. worth a pass before merge. (×1)
- that api key in the deleted .claude/settings.json from dc05c3e is still in git history. rotate it before merge. (×1)
- I don't think this is a blocker, and this would add pagination to the delete/update operations, which would have side effects. I think we should keep it as is. (×1)
- closing as won't fix. the owner update already fails cleanly with a 400, not worth a breaking change. moving owner to `base_owner` changes its id and forces a one-time remove+add on every account. (×1)
- @alice @bob done with the feedback, mind taking another look? (×1)

### New line comments — nit

- expand-columns is a string slice, same as skip-database above. could show comma-separated here: `"mydb.mytable,otherdb.othertable"`. (×1)
- `optionalStringField` at line 501-504 already does `strings.TrimSpace(raw)`, so the outer `strings.TrimSpace(...)` here is redundant. can drop it: `if mapped := optionalStringField(profileMap, "email"); mapped != "" {`. (×1)
- let's not log `user_id`, it's user data. `role` is enough here. and this can be `Debug` instead of `Warn`. (×1)
- needs a prettier pass, this line and the new test. (×1)

### Answers

- This was a misconfiguration on our side. Remote desktop was flagged as disabled on your workstation, so the dashboard stopped offering it. That's fixed. Refresh the dashboard and it should be back in the connect options. (×1)
- hi, good! no, i didn't turn anything on at the account level. it was a dev account from the developer program and the only thing i did was add the reports scope to the API client. with the scope it returned all 22 reports. (×1)

### Replies — clarifying / asking back

- deployment names are unique per cloud account, so no collision risk. also pre-existing, not new in this PR. (×1)
- if a workspace's in both lists, exclude wins. (×1)
- i split it in two. oauth now errors on a failed account check instead of just warning, so it won't silently drop data. for token mode i kept the warn but added what you asked for: a config help-text note that it skips account-level data (use oauth for that), plus the docs warning. (×1)
- the already absent case returns `204`, not a 404, so `RemoveItemFromList` is already idempotent. (×1)
- yeah, this branch is what introduced `autherror.go` (the `name` param for multi-db), and the other pr adds the postgres detection on top. didn't want to duplicate `pg.IsAuthError` here and ship a conflicting change, so whoever lands second rebases `autherror.go` onto the other. final file ends up with both the db-name context and the postgres branch. (×1)
- yeah, still there. low priority like you said. the combo is still rejected, just after a wasted connect and discovery run. (×1)
- the `..._MySQL` full-path create/delete tests are already on the branch, so mysql gets end-to-end coverage too. the extra queries opt in and use `|keyword` now. (×1)
- intentional, not a missed classification. a code-less 404 here cannot be told apart from a routing or directory failure, so we fail loud rather than report a delete that never happened as already-deleted. (×1)
- confirmed: a null or missing `Data` yields an empty set, not an error. (×1)
- audited all seven against the openapi. only `listOrders` uses the container, and only when `limit` is sent. the rest are bare arrays, `Invoices` included. no sibling shares it. (×1)
- outdated, the test expects the partial result now. (×1)
- i removed the line to follow the mental model that we talked about (×2)
- flipped this back, a 404 on delete is success again per the thread on `Delete`. (×1)
- this is the order we just created. `AlreadyExists` comes from the pre-check before `batchInsert` so is not the same (×1)
- on purpose, the user still holds the Basic plan so success would be wrong. hiding it with `ReadOnly` is a follow-up. (×1)
- `Name` is exact (case-insensitive), partial names come back empty. the response has no name to compare, so i updated the doc comment instead. <link> (×1)
- agree. the client can't build `baseUrl` from the region yet, `httpclient.v2` only takes one config field. ok to leave it until a computed `baseUrl` lands in the client? (×1)
- agreed, that's a platform question. reworded the comment so it doesn't assume one job per process, it just says overlapping jobs evict each other and refetch. (×1)
- it merges, the other `UserSettings` stay as they were. (×1)
- apps part is in the dev guide, linked it in the doc. couldn't find the spaces part documented, but the delete fails with `ResourceInUse` while a space is still attached, so the doc just names that error now. (×1)
- kept it in its own commit, added the h2 test. (×1)
- LRU now and failed loads don't take a slot. a third overlapping job can still evict the oldest one. (×1)
- workers can't read the resource profile yet. the follow-up pr adds that, i'll drop the extra describes once it lands. <link> (×1)

### Ticket status updates

- PR is up: <link>. It's only been tested against a mock <vendor> server, since we don't have a real <vendor> account. Could the customer from the support ticket run a first import with OAuth 2.0 client credentials once this ships? That would be our live check. Existing token setups don't need any changes. (×1)
- Can't test this in staging yet. The tables are deployed and refreshing but empty. Blocked on two things: <vendor> can't create disputes on migrated transactions. `getAllTransHistory` returns 503 for migrated accounts. Migrated adjustments aren't linked to their line, `source_table`/`source_id` are empty. The migration team needs to backfill them. Parsing works on a sample transaction id. (×1)

### Ticket comments

- <vendor>'s docs say not to use the query API for bulk export, and a nightly import is a bulk export: > Use the query API within the defined limits. Don't use it for bulk data import or export, or mass operations that can indirectly trigger many requests. [<vendor> API fundamentals](<link>) (needs a developer login) (×1)

### Ticket closing

- Fixed by <TICKET>, out since v0.1.10. Fields that already load by default, like `user_id` and `title`, now get skipped when they're listed in additional report fields, so the import doesn't fail. CSV reports get the same fix in <TICKET>. (×1)

## Anti-patterns — what NOT to post

Calibration set. Each entry is something we drafted, the user rejected, and what should have shipped instead. Read this whenever a draft starts to sprawl.

### Restating the whole fix when "done" is enough

- Original comment from reviewer: `should we fetch tags per order? or what's the way to improve it? i think it is going to list all items for each tag`
- Don't post: `moved the tag emit to order.items with `item_path: "$"` + cross-resource mapping in c29c960, so /items paginates once and the per-order /items/{id} reuses cache from the teams + customTags entries. pattern's from examples/a.yaml:158-170 + b.yaml:62-74.`
- Post instead: `done.`
- Why: reviewer raised a concern, we already discussed the fix in chat with the operator, and the commit is linked on the PR. The reply only needs to close the thread. Saving the long-form rationale for the commit message or the PR description is correct; reposting it as a comment is noise.

### AI-slop vocab (never use these words)

Words that instantly read as machine-written. Banned in comment bodies; say what the code actually does in plain words instead.

- `no-op` / `noop` → say "does nothing now" / "the pop is dead now" / "never runs". Example: don't post `the pop is a no-op now`; post `the pop does nothing now, providerId isn't in the body anymore`.
- Also banned (mirrors the global writing-style rule): `leverage`, `robust`, `seamless(ly)`, `streamline`, `delve`, `harness` (as verb), `utilize`, `intricate`.
- Test: would a tired engineer type this word in slack? `no-op` in casual speech, rarely. If it smells like a status-page word, replace it with the concrete thing the code does.
