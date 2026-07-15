# Example review comments

Voice / length / phrasing reference for inline PR review comments. Don't copy verbatim; match the register.

Rules these all follow:
- 1-3 sentences
- lowercase start, no em-dashes, no emojis
- references other files as `file:line` when context spans
- states the issue then the fix, no preamble

This file grows automatically: the skill appends every posted comment under
its matching category at Step 8. Newer entries go to the top of each section
so the most recent voice samples are read first.

---

## Correctness

**parent-less child resource** (`users.go:33`)
> Foo is declared as a child of Bar (bar.go:419), but the constructor here doesn't set a parent. Either drop the child annotation or use a separate type for the top-level case.

**helper claim doesn't match implementation** (`service.go:54`)
> the docstring says "no API call needed", but the code path reads from the API on every miss. drop the docstring or short-circuit when the cached value is present.

**case-sensitive name match** (`helpers.go:46`)
> only matches lowercase "owner". if the upstream returns "Owner", the filter misses and the next step gets an opaque ID. lowercase before comparing, or match by stable ID.

## Data model / contracts

**expandable target doesn't exist** (`projects.go:160`)
> the target ID this expands to is never emitted by any builder, so the expansion silently does nothing. either emit the missing entitlement or drop the expansion.

**wrong type for principal** (`accounts.go:131`)
> service accounts are constructed with the user type. downstream UI treats user-type principals differently. switch to the app/machine type so the model stays consistent.

**over-emission across pagination** (`projects.go:158`)
> the implicit owner grant gets emitted on every page of phase 1, not just the first. gate it on the first-page predicate so a project with N pages of users doesn't get N duplicate owners.

## Error handling

**email embedded in returned error** (`company.go:192`)
> email is embedded in the returned error and the framework logs returned errors. drop the email from the message; log the user ID instead.

**warning + swallowed verify error** (`roles.go:115`)
> the verify error is logged at warn and then dropped. the caller never sees why verification failed. include verifyErr in the returned error.

**fragile substring match** (`helpers.go:35`)
> "500" matches any error message containing those three digits (counts, retry timings, IDs). a false-positive flips a real failure to "already exists". inspect the wrapped status via errors.As instead.

## API surface

**unbacked claim in customer-facing doc** (`docs/connector.mdx:9`)
> "cannot be changed via the API" isn't in the vendor's spec. soften to "is not currently supported in our testing" and add a date so we know when to recheck.

**no spec backing for the workaround** (`roles.go:91`)
> the vendor's spec only documents 200 here. add a TODO with the date the workaround was added so it can be removed when fixed upstream.

## Pagination / control flow

**unpaginated list call** (`accounts.go:67`)
> single list call with no cursor loop. confirmed the client is single-page today, but if that changes this silently drops items past page 1. drive it with a for-loop on the cursor for safety.

**duplicate emission across builders** (`users.go:33`)
> builder A emits type X for any user with the SA flag, but builder B also emits SAs. if the ID spaces ever overlap, you get duplicate resources with conflicting parents. dedupe, or assert disjoint prefixes.

## Tests / regression

**backwards-incompatible slug change** (`projects.go:108`)
> the slug switched from opaque ID to display-name. existing stores key grants by the old ID; after upgrade those grants orphan and Revoke fails. either keep the ID as the slug (use a separate label field for display) or add a migration annotation.

**no test for the new branch** (PR-level)
> the new error-recovery path has no coverage. at minimum add a fixture for the failing upstream response, so the branch is exercised once.

## Style nits

**stale comment after refactor** (`projects.go:140`)
> comment says "emitted from users.go" but the emission moved to this file. update or delete.

**trailing blank line** (`projects.go:409`)
> nit: stray blank line at EOF.

---

## Length / register reference

If a comment grows past three sentences, it's probably two findings stapled together. Split them and ask the user about each separately. The operator should be able to skim the preview in AskUserQuestion without scrolling.
