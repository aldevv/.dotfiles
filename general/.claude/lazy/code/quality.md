# Code quality

**Load this when** any of:
- `Write` or `Edit` tool calls on source files (`.go`, `.py`, `.ts`, `.js`, `.lua`, `.sh`, etc.)
- User phrases: "refactor", "clean up", "review this", "extract", "rename"

Covers readability principles, naming, function extraction, hardcoded strings, and magic separators.

## Refactoring

Refactoring style follows Martin Fowler's book Refactoring.

When refactoring existing code: write a passing test first, make the change, confirm the test still passes. Never refactor and fix a bug in the same commit.


## Readability is priority #1

Apply clean-code practices only when they make the code easier to read, not as ends in themselves.

- **Prefer guard clauses and early returns over if-else nesting.** Check the failure/edge case first, return immediately, then write the happy path without indentation. `if err != nil { return err }` at the top beats an `else` block that pushes the main logic rightward. Apply this whenever the condition is a pre-check, validation, or error — not when both branches are equally weighted logic.
- **Complex `if` conditions get extracted to a named predicate — when the condition is genuinely hard to read inline.** `if isEligibleForRefund(order) { ... }` beats five chained boolean clauses. Apply to switch/case guards and nested ternaries too. Short conditions used once stay inline (see "Don't extract short expressions" below).
- **Prefer many small named functions over one long function with inline comments.** A well-named function call is self-documenting; a comment above an inline block isn't.
- **No hardcoded strings for values defined elsewhere.** If a constant, config field, env var, or enum already names a value, reference it instead of retyping the literal. `conf.GetString("base-url")` becomes `conf.BaseURL`. Same rule for raw `os.Getenv("FOO")` calls when the config layer already wraps them. Magic separators (`"@"`, `":"`, `"/"`) referenced more than once become a named `const` next to their point of use.
- **Don't refactor for purity alone.** DRY, SRP, Hexagonal, dependency injection are fine when they make a specific reader's life easier here. If a refactor adds indirection a future reader has to chase without paying for itself in clarity, skip it. Three similar lines is better than a premature abstraction.
- **When in conflict, readability wins.** If a "clean" pattern obscures what the code does, the pattern is wrong for this spot.

## Don't extract short expressions into named helpers

Keep it inline unless one of these holds: the expression is genuinely complex, it's used in three or more places, or the name carries domain information the inline form doesn't.

When naming an inline local, describe what the value *is*, not how it was produced. A SQL predicate built with `AND` clauses is a `match_clause`, not `on`.

## Name booleans with an `is_` / `has_` / `should_` prefix

Bool variables, parameters, and bool-returning functions get a prefix that makes the truth question explicit: `is_X`, `has_X`, `should_X`. Use the language's casing convention (`isX` in Go/JS/Java, `is_x` in Python/Ruby).

`valid` → `is_valid`, `empty` → `is_empty`, `keys` → `has_keys`.

In Go, bare names (`found`, `ok`, `valid`) are idiomatic for unexported fields and short-scope locals; the prefix applies to exported identifiers and method names.

Doesn't apply to truthiness checks on non-bool values — `if missing_meta:` is fine when `missing_meta` is a list.

## Function signature quality: more than 3 parameters

4+ parameters is a signal to reconsider the signature — callers lose track of argument order, and same-type swaps compile silently. Use whatever the language's named-parameter idiom is (struct, dataclass, options object, record, builder).

Prefer grouping when: multiple params share a type, the set is likely to grow, or callers source most args from a single place. Keep positional params for short utilities (`min(a, b)`), library-mandated signatures, or functions called in very few places with clearly distinct types.

When all fields are required, a plain named object works. When callers selectively override defaults, use the language's options/builder pattern.

Go example (plain struct vs functional options):

```go
func Fetch(cfg FetchConfig) (*Response, error)          // all required

func NewServer(addr string, opts ...Option) *Server     // selective overrides
func WithPort(p int) Option { return func(o *ServerOptions) { o.Port = p } }
```

## Prefer plain words in names

- Use simple, common words in identifiers; avoid jargon or fancy vocabulary a reader might not know. If a name needs a dictionary, it's the wrong word.
- Examples: `provenance` → `source`, `instantiate` → `create`, `obfuscate` → `hide`, `ephemeral` → `temporary`.

## Shell scripts

- Format shell scripts (`.sh` / `.bash`) with `shfmt`; treat it as the canonical formatter. Run it before considering a script done.
- Document every function argument: positional params (`$1`, `$2`) carry no meaning on their own. Name them with `local`s at the top (`local key=$1 value=$2`), or add a one-line `# $1=…, $2=…` comment above the function.
- Comment for readability (shell is dense, so this overrides the usual minimal-comment default): put a one-line comment above each multi-line block saying what it does, and above any `sed` / `grep` / `find` / `awk` line that interpolates variables.
