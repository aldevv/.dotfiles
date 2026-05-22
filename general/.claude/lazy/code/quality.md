# Code quality

**Load this when:** writing, reviewing, modifying, refactoring, or deleting any code. Line-level decisions: naming, function extraction, hardcoded strings, magic separators. Precedents are captured from real feedback; treat each as a precedent for the next time the same shape comes up.

## Don't extract a one-line SQL fragment into a named helper

A short SQL fragment that's only built in one or two places stays inline. A `def foo_sql(...)` whose body is one `" AND ".join(...)` is indirection: the reader has to jump to a different scope to see what `foo_sql` returns, when reading the original line in place would have been the same length and self-contained.

**Don't:**

```python
def on_clause_sql(keys, qvo_target_to_source):
    return " AND ".join(
        f"EQUAL_NULL(t.{k}, s.{qvo_target_to_source[k]})" for k in keys
    )

class ViewDataReplicator:
    def _build_merge_sql(self):
        on = on_clause_sql(self.keys, self.qvo_target_to_source)
        ...
        return f"... ON {on} ..."

    def _build_delete_sql(self):
        on = on_clause_sql(self.keys, self.qvo_target_to_source)
        ...
```

**Do:**

```python
class ViewDataReplicator:
    def _build_merge_sql(self):
        match_clause = " AND ".join(
            f"EQUAL_NULL(t.{k}, s.{self.qvo_target_to_source[k]})"
            for k in self.keys
        )
        ...
        return f"... ON {match_clause} ..."

    def _build_delete_sql(self):
        match_clause = " AND ".join(
            f"EQUAL_NULL(t.{k}, s.{self.qvo_target_to_source[k]})"
            for k in self.keys
        )
        ...
```

The duplication is two lines. Splitting them into a helper costs three lines (def + return + blank) and forces a context switch. Keep them inline.

**Naming the local variable:** the value holds the boolean predicate that goes after `ON`. The SQL term for that is the *match clause* (or *match condition*). Don't name it `on` — that's the SQL keyword, not what the variable contains. `match_clause` reads naturally with the surrounding f-string (`ON {match_clause}`) and tells the reader what the value is.

**When extraction IS warranted:**
- The fragment is genuinely complex (multi-line, conditional branches, comments needed).
- It's used in three or more places.
- The name carries information the inline form doesn't (e.g. domain-specific operation name a reader would search for).

If none of those apply, inline.

## Name booleans with an `is_` / `has_` / `should_` prefix

Boolean values (variables, function returns, parameters) read better with a prefix that makes the truth question obvious. The prefix is the verb the value answers: `is_X` answers "is it X?", `has_X` answers "does it have X?", `should_X` answers "should it X?". Without the prefix, the reader has to infer the type from context, and code like `if active:` looks like it could mean "the active record" rather than "is the record active?".

**Don't:**

```python
def replicator(session, source, target, key_columns):
    valid = check_object_ref(session, source, "view") == "VALID"
    empty = not key_columns
    if not valid or empty:
        return "ERROR"
```

**Do:**

```python
def replicator(session, source, target, key_columns):
    is_source_valid = check_object_ref(session, source, "view") == "VALID"
    has_keys = bool(key_columns)
    if not is_source_valid or not has_keys:
        return "ERROR"
```

The first reads as a list of nouns; the second reads as a list of yes/no questions, which is what the `if` is actually asking.

**Applies to:**
- Local variables that hold a `bool`.
- Function/method names that return `bool` (`is_timestamp(col)`, not `timestamp(col)`).
- Method arguments that are `bool` (`force=True`, `skip_validation=False`, `is_dry_run=True`).
- Class attributes that are `bool`.

**Doesn't apply to:**
- Truthiness checks on non-bool values (a list, a string, an `Optional[X]`). Those use the value's natural noun: `if missing_meta:` is fine because `missing_meta` is a list.
- Functions returning `Optional[str]` or other non-bool unions; pick a name that reflects the value (`classify_timestamp` returns `'ntz'`/`'tz'`/`None`).

**Python style note:** the convention is `is_something` / `has_something` (snake_case), not `isSomething` (camelCase). Match the language.

## Don't retype config field names as string literals

If the config struct exposes a typed field, use it. The string-key form duplicates the canonical declaration and silently survives renames.

**Don't:**

```go
if v := conf.GetString("base-url"); v != "" { ... }
```

**Do:**

```go
if conf.BaseURL != "" { ... }
```

Same rule for raw `os.Getenv("FOO")` reads when the config layer already wraps them.

## Extract repeated magic separators to named constants

A single literal at its point of use is fine. A literal that joins two other values inside an expression is a smell.

**Don't:**

```go
params := url.Values{"username": []string{userID + "@" + companyID}}
```

**Do:**

```go
const (
    usernameKey       = "username"
    usernameSeparator = "@"
)
params := url.Values{usernameKey: []string{userID + usernameSeparator + companyID}}
```

The constants document the API contract at the usage site instead of leaving the reader to grep for `"@"`.
