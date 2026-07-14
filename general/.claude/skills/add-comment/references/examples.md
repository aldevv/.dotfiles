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

- done. (×28)
- good catch, will fix. (×1)
- fixed. (×6)
- done (×1)
- fixed. same resolveUserAndRoleNames path on revoke. (×1)
- fixed. uses escapeQueryValue now. (×1)
- fixed. resolveUserAndRoleNames does an api lookup by RecordNo, no DisplayName dependency. (×1)
- deleted. (×2)
- moved to helpers.go. (×1)
- fixed (×2)
- fixed. no longer seeded from public data. (×1)
- added `codes.AlreadyExists` (×1)

### Replies — pushback

- i'd keep this one. nil just means the role doesn't exist (snowflake returns 200 empty), and the same missing role often shows up across lots of grant rows, so caching it saves a bunch of calls. callers already skip on nil anyway. (×1)
- `W` is writeup user, easy to mix up with ws. logindisabled is the ws-only flag per the [docs](https://developer.intacct.com/api/company-console/users/). (×1)
- checked. baton-http's actions.go doesn't unwrap ErrIgnoreError, so a 404 on update_user still fails. confirmed against the mock. (×1)
- enable/disable is not in the connector because the API doesn't expose it (×1)
- Couldn't find a 400 in the OpenAPI, so I kept 409 and just expanded the message to cover self / last owner / SCIM. (×1)
- new success_condition catches it. so it works as is (×1)
- not a blocker, goja has no web crypto. (×1)
- keeping math.random. goja has no web crypto. (×1)

### New line comments — feedback

- could batch this with a GetManyJSON over the distinct ids before the loop. the old code was already doing that. (×1)
- same on the writes. one SetManyJSON after the loop, like workersToStore. (×1)
- `null when not resolved` doesn't match the `pending column sync` case. the object exists and the type is populated, only the column is missing. should say null only when the object itself is missing (pending table/view replication, or not found). (×1)
- the echo rule lives only here in the deferred branch. step 4 builds the json for resolved and resolved_fallback without restating it, and the terminal block at line 91 says "copy verbatim" but doesn't cover the preset-vs-label split. same input ends up with different data_consumption_mode shapes across runs. would help to state it once near the top and apply everywhere. (×1)
- echo rule only lives here in the deferred branch. step 4 and the line 91 terminal block don't restate the preset-vs-label split, so other statuses come out inconsistent across runs. (×1)
- the read error here gets swallowed and returns nil. the SetManyJSON below then writes only this page's role for the folder, overwriting prior pages' cached roles, and folder.Grants later emits an incomplete grant set silently. propagate the read error up instead. (×1)
- this revoke returns Unimplemented but the entitlement isn't EntitlementImmutable. mark it immutable or implement revoke. same on role.go:259. (×1)
- dropping the annotation here. empty today so nothing breaks, but rate-limit hints would get silently lost if they ever land. could pass it through SyncOpResults.Annotations. (×1)
- checkout needs to run before setup-go, otherwise `go-version-file: go.mod` errors out once `if: false` flips. (×1)
- sdk caps exclusion groups at 50 per group id (`maxEntitlementsPerExclusionGroup` in baton-sdk sync/syncer.go:255). the key is per-envType, so every env-role in one environment shares one bucket. workato allows unlimited custom env-roles, so >50 in any env will fail sync. worth a code comment here calling out the cap as a known limitation. (×1)
- Lucid's SCIM Role enum is `[AccountAdmin, BillingAdmin, Developer, DocumentAdmin, EnterpriseShieldAdmin, TemplateAdmin]`. `TeamAdmin` isn't valid and three real values are missing. Fix the list. (https://lucid.readme.io/reference/modifyuserpatch) (×1)
- if the caller passes `roles: []`, `updateUserHandler` still appends "roles" to `updated`, so the guard passes but the PATCH goes out with `Operations: null` and Lucid 400s per RFC 7644 §3.5.2. Guard `len(ops)==0` here before `newScimRequest`. (×1)
- `CAPABILITY_RESOURCE_DELETE` and `CAPABILITY_ACTIONS` ship unconditionally, but Delete and the three actions all require SCIM. On OAuth2-only tenants the UI shows buttons that 500 at invoke. Gate the capabilities on `ScimConfigured()` in `connector.go`, or return `codes.Unimplemented` (×1)
- `POST /v1/transferUserContent` requires the `account.user.transfercontent` scope per Lucid's docs, separate from `account.user`. Since Delete calls it, existing customers who only granted `account.user` will 403 at Delete time. Add it here. (spec: https://developer.lucid.co/reference/transferusercontent) (×1)
- delete idempotency never fires. the real not-found message is `could not find the target or you are unauthorized.` and none of the substrings match. add that string or key off `Extensions["errorClass"]`. (spec: https://github.com/newrelic/newrelic-client-go/blob/main/pkg/usermanagement/users_integration_test.go) (×1)
- this drains every page to find one email AND returns the wrong ID (v1 aggregator, not the v2 identity id the mutations need). one filtered v2 query fixes both. (spec: https://docs.newrelic.com/docs/apis/nerdgraph/examples/nerdgraph-manage-users/) (×1)
- provisioning also needs the **authentication domain manager** role. worth calling out near the warning at line 23. (spec: https://docs.newrelic.com/docs/apis/nerdgraph/examples/nerdgraph-manage-users/) (×1)
- this drains every org's networks paginated to find one auth user. fix is having parentResourceID and return InvalidArgument otherwise. (×1)
- drop `none` here. createaccount rejects it; it's still fine for the update action. (×1)
- ListOrganizations doesn't paginate. meraki supports it (max perPage=9000). cli-delete fallback misses orgs past page 1 (https://developer.cisco.com/meraki/api-v1/get-organizations/) (×1)
- same, ListSMRoles doesn't paginate. default page = 50, orgs with more sm roles lose them. https://developer.cisco.com/meraki/api-v1/get-organization-sm-admins-roles/ (×1)
- these all surface to c1 as codes.Unknown, and every other gocloak error in the connector has the same problem. worth adding a MapAPIError helper next to IsAlreadyExistsError that unwraps *gocloak.APIError and returns the matching gRPC code (429 and 5xx as Unavailable, 403 as PermissionDenied, 400 as InvalidArgument, etc), then wrapping every gocloak call site with status.Error(MapAPIError(err), ...). (×1)
- these all surface to c1 as `codes.Unknown`, and every other gocloak error in the connector has the same problem. worth adding a `MapAPIError` helper next to `IsAlreadyExistsError` that unwraps `*gocloak.APIError` and returns the matching gRPC code (`429` and `5xx` as `codes.Unavailable`, `403` as `codes.PermissionDenied`, `400` as `codes.InvalidArgument`, etc), then wrapping every gocloak call site with `status.Error(MapAPIError(err), ...)`. (×1)

### Top-level PR/MR comments

- tested this locally. `role[]` isn't the cause, the empty `query=` is. `?role[]=admin` alone gives a real meta. add `&query=` and meta goes null. this pr still pulls in `zendesk.CommonOptions` which has no omitempty on Query, so `&query=` still goes out on every request and the cursor won't move at >100/role. (×1)
- docs/connector.mdx table is stale, doesn't reflect the new provision / delete / actions surface. same in readme. worth a pass before merge. (×1)
- that meraki api key in the deleted .claude/settings.json from dc05c3e is still in git history. rotate it on the draftkings tenant before merge. (×1)
- I don't think this is a blocker, and this would add pagination to the delete/provisioning operations, which would have side effects. I think we should keep it as is. (×1)
- closing as won't fix. the owner grant already fails cleanly with a 400, not worth a breaking change. moving owner to `base_role_owner` changes its id and forces a one-time remove+add on every tenant. (×1)

### New line comments — nit

- expand-columns is a string slice, same as skip-database above. could show comma-separated here: `"mydb.mytable,otherdb.othertable"`. (×1)
- `optionalStringField` at line 501-504 already does `strings.TrimSpace(raw)`, so the outer `strings.TrimSpace(...)` here is redundant. can drop it: `if mapped := optionalStringField(profileMap, "email"); mapped != "" {`. (×1)

## Anti-patterns — what NOT to post

Calibration set. Each entry is something we drafted, the user rejected, and what should have shipped instead. Read this whenever a draft starts to sprawl.

### Restating the whole fix when "done" is enough

- Original comment from reviewer: `should we ship role grants from users? or what's the way to improve it? i think it is going to list all members for each role`
- Don't post: `moved the base_role emit to user.grants with `item_path: "$"` + cross-resource grant_mapping in c29c960, so /members paginates once and the per-user /members/{id} reuses cache from the teams + customRoles entries. pattern's from baton-http examples/fivetran.yaml:158-170 + rapid7.yaml:62-74.`
- Post instead: `done.`
- Why: reviewer raised a concern, we already discussed the fix in chat with the operator, and the commit is linked on the PR. The reply only needs to close the thread. Saving the long-form rationale for the commit message or the PR description is correct; reposting it as a comment is noise.
