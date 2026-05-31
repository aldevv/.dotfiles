# Comments

**Load this when:** writing or reviewing any code comment, considering whether to add one, or planning code you suspect will need a comment to be readable.

## Rule

Adding any comment is a rule violation by default. Before writing any comment, state in chat first: `comment justified: <complex flow / hidden invariant / non-obvious WHY / workaround>`. No comment goes into a tool call without that chat utterance preceding it. If you can't articulate the justification in advance, don't write the comment. The check is pre-write, not post-write.

When touching existing code: if a comment restates the line that follows it, delete the comment.

Exception: tests. A one-line function-header comment naming a non-obvious scenario is OK. Per-line narration inside the test body is not.

The "Forbidden patterns" and "Justified comments" sections below show what these rules look like in practice.

## Forbidden patterns

### 1. Restating the next line

```python
# Increment the counter
counter += 1
```

Delete the comment. The code already says it.

### 2. Function-purpose summary that the name already conveys

```go
// GetUserByID fetches a user by their ID
func GetUserByID(id string) (*User, error) { ... }
```

Delete the comment. Name plus signature already say it.

### 3. "Used by X" / cross-cutting consistency notes

```ts
// Called by the checkout flow when the customer applies a promo code
function applyDiscount(order) { ... }
```

Delete. Caller context belongs in the PR description, not the code. Readers can grep callers.

### 4. Multi-line docstring on trivial code

```python
def add(a, b):
    """
    Adds two numbers and returns the result.

    Args:
        a: First operand.
        b: Second operand.
    Returns:
        The sum.
    """
    return a + b
```

Delete the docstring. Signature already tells you everything.

### 5. Paragraph-length comment on trivial code

```python
# This function takes a list of User objects and filters them down to only the
# users who have a non-empty email field. This is necessary because in our system,
# users may exist without emails (legacy accounts predating the email-required
# policy, or imports from external systems where email wasn't mandatory).
#
# The implementation uses a list comprehension and checks the `email` attribute
# is truthy (catches both None and empty string). The function returns a new
# list and does not modify the input.
def users_with_email(users):
    return [u for u in users if u.email]
```

Delete the entire comment. The function name + one-line body already say it. Long comments are justified only when the underlying logic is genuinely complex (see Justified #5). Long-on-trivial inverts the trade: it adds maintenance debt and reading friction without adding signal. If the legacy-users context actually matters at the call site, it belongs in the PR description, not above a one-line filter.

### 6. Per-line narration inside a test body

```ts
test('user has correct name', () => {
  // Set up the user
  const user = makeUser('alice')
  // Call the method
  const result = user.getName()
  // Assert the result is correct
  expect(result).toBe('alice')
})
```

Delete every comment in the body. Tests get at most a one-line header (see "Justified" #4).

### 7. Stale cross-cutting note that no longer matches the code

```go
// Authentication is handled by the gateway middleware, not the handler.
func (h *Handler) Authenticate(w http.ResponseWriter, r *http.Request) {
    // empty: gateway middleware fills the auth context upstream
}
```

Delete. Two failures at once: it's a cross-cutting "the work lives elsewhere" pointer (rule #3), AND the moment someone moves auth back into the handler (or replaces the gateway) the note silently lies. Cross-cutting notes age badly because nobody updates them when refactoring the thing they describe.

### 8. Doc-comment on a small helper function

```go
// refToUser builds a user resource from a list-endpoint ref.
func refToUser(ref Ref) (*User, error) {
    return &User{ID: ref.ID, Login: ref.ID}, nil
}
```

Delete. The function name plus its three-line body says everything. Same for any single-purpose conversion function (`formatHeader`, `parseFoo`, `toPrincipal`). Default for small helpers: zero comments. (Exception: if the name isn't clear at a glance and a clearer name would hurt call sites, a one-line comment is justified, see Justified #9.)

### 9. File-level header comment that inventories what the file contains

```go
// Package client provides the REST client, OAuth helpers, and response model
// types for talking to the Foo API. It exposes the Client struct and a set
// of construction options (WithBaseURL, WithAccessToken, ...).
package client
```

Delete. The package name plus the types declared at the top of the file already tell the reader. Same rule for `/* This file contains ... */` preambles in any language. **A header IS justified when it orients the reader to a complex flow they can't infer from the types**, see Justified #8 below.

### 10. Type or struct comment that restates the type name

```go
// Order represents an order placed by a customer.
type Order struct {
    ID       int
    Customer string
    Total    float64
}
```

Delete. The type name plus its fields says it. A comment is only justified if it documents an invariant the fields cannot express (e.g., "Total includes shipping but excludes tax").

## Justified comments

### 1. Hidden invariant the reader can't infer

```python
# Workday API returns ref-only entries for archived users; treat a missing name as deleted.
if not user.name:
    return DELETED_USER
```

The behavior of the upstream API is invisible from the call site.

### 2. Platform workaround

```sh
# macOS sed needs an empty '' after -i; GNU sed does not. The .bak dance below is portable.
sed -i.bak 's/foo/bar/' "$file" && rm "$file.bak"
```

The workaround makes no sense without the explanation.

### 3. Surprising ordering with a real consequence

```js
// Cache the token BEFORE retrying. The retry path reads from cache, not the response, because
// some upstreams scrub the token from the second response.
cache.set('token', token);
authClient.retry();
```

The order is load-bearing and a reader could "fix" it the wrong way without the note.

### 4. Test header that names a non-obvious scenario

```ts
// Workday quirk: ref ID without name should still count as a valid user.
test('user with ref ID and no name', () => { ... })
```

The test name alone wouldn't tell a future reader why this case exists.

### 5. Multi-paragraph: load-bearing ordering across a system boundary

When the surrounding logic looks redundant but is actually load-bearing because of a system boundary (replication lag, eventual consistency, protocol handshake, retry-window quirks), a multi-paragraph comment is justified. Cut every sentence that doesn't add information, but write as much as the reader actually needs.

```python
# Two-phase publish. DO NOT collapse this back to a single index.publish() call.
#
# The search index and the audit log are eventually consistent via separate Kafka
# topics, and audit consumers can observe a PUBLISHED event before the index has
# accepted the document. Three incidents in 2025 came from this race: support sent
# customers links to docs that 404'd, oncall lost ~30 min each time before realizing
# the document was about to land in the index.
#
# Sequence:
#   1. Reserve the doc ID with a "pending" tombstone. Idempotent. The UI hides it.
#   2. Write the audit log. Audit consumers are allowed to see pending tombstones.
#   3. Hydrate the doc body. Once this returns, GETs serve the real content.
#
# If the process crashes between (2) and (3), audit-recon.py picks up tombstones
# older than 5 minutes and either retries (3) or rolls back the audit event. The
# reconciler depends on the tombstone existing; the audit consumers depend on the
# audit event being visible before the index is. Both invariants are load-bearing
# and can't be inferred from any of the three calls in isolation.
reserve_tombstone(doc_id)
audit_log.append(PublishEvent(doc_id))
index.hydrate(doc_id, body)
```

A future maintainer reading this without the comment would "clean it up" into a single call and re-introduce all three incidents. The comment earns every line, because it documents a constraint that lives across three different services and one cron job. Length follows necessity, not aesthetics.

### 6. Vendor API quirk that a reader could not infer

```go
// GET /items rejects query-string filters (returns 400 INVALID_FILTER); use /search.
pathSearch = "/v1/search"
```

Switching back to the rejected form would silently break in production. The vendor error code is the identifier a future reader would search the docs for.

### 7. Correctness invariant disguised as a cosmetic field

```go
// Requesting `owner` is load-bearing: without it the API returns rows the caller
// can't read, widening the result set past the access-control boundary.
fields := []string{"id", "name", "owner"}
```

`owner` looks like a harmless extra field a future "cleanup" might trim. The comment warns that removing it widens the result set past the access-control boundary, which is a correctness regression and not a test failure.

### 8. File-level header that orients the reader to a complex flow

```go
// Package payments orchestrates the two-phase capture flow:
//
//   Authorize → optional Hold (7-day window) → Capture | Void.
//
// State is held in the database, NOT the gateway, so the flow survives
// gateway downtime. Retry logic in retry.go assumes any state past
// "Authorized" can be safely retried; "PreAuth" cannot.
package payments
```

The two-phase flow, the state location (db vs gateway), and the retry-safety boundary are all load-bearing facts a reader cannot infer from the type signatures. Without this header, the reader has to reconstruct the flow from `authorize.go`, `capture.go`, `retry.go`, and the schema before any of the individual files make sense. Counter-example to Forbidden #9: this header is not an inventory of contents, it is a map of the flow.

Before (forbidden, the comment is a crutch):

```python
# Eligible if active, not banned, has verified email, and is in a supported region.
if user.active and not user.banned and user.email_verified and user.region in SUPPORTED_REGIONS:
    grant_access(user)
```

After (no comment needed; the predicate is its own name):

```python
if is_eligible_for_access(user):
    grant_access(user)


def is_eligible_for_access(user):
    return (
        user.active
        and not user.banned
        and user.email_verified
        and user.region in SUPPORTED_REGIONS
    )
```

This is the highest-leverage move: if a comment is needed to explain a complex boolean, switch/case guard, or loop condition, the predicate wants a name, not a comment.

### 9. Small-helper name that isn't clear at a glance

A function or identifier must be clear at a glance. When its purpose isn't obvious from the name alone, fix it one of two ways, in this order:

- **Prefer a clearer name.** `emit` → `set_output`, `proc` → `parse_published_version`.
- **Add a one-line comment only when a better short name would hurt the call sites** — e.g. a terse, established idiom read inline many times. The classic case is `die` in `... || die "msg"`: renaming to `print_error_and_exit` clutters every call site, so keep the name and document it once.

This is the deliberate exception to Forbidden #8: a glance-unclear small-helper name justifies a one-line comment.

```sh
# print message to stderr and exit non-zero
die() { echo "$1" >&2; exit 1; }
```

## Length guidance

When a comment IS justified: as short as it can be while staying understandable; as long as it needs to be. Understanding is the priority, brevity is second. Three-clause sentences with semicolons are usually a smell; split them.

## Shell scripts are an exception

Shell is dense and hard to read, so it gets more comments than the minimal default above. In `.sh` / `.bash`: put a one-line comment above each multi-line block saying what it does, above any `sed` / `grep` / `find` / `awk` line that interpolates variables, and document each function's positional args. See the `## Shell scripts` section in `quality.md`.
