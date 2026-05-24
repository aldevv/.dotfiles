# Debugging & iteration tooling

## Principles

- **Prefer TDD**. create a failing test, then make it pass

- **Reproduce first.** Write the smallest reliable reproducer before touching anything. If you can capture it as a unit test, do that — it becomes the regression guard automatically. A bug you can't trigger consistently is one you can't verify you fixed.

- **Before closing a fix, ask:** what would have made this faster to find? Add the missing observability. Not optional.

- If you find yourself mentally reconstructing the state of a data structure from raw dumps, add a `String()` (Go), `__repr__` (Python), or `Display` (Rust) method — or a free `FooString(x Foo) string` function — to make it visible in one step.

- If you write the same print statement in three or more places, extract it into a gated helper: a function guarded by a `DEBUG=1` env check or verbosity flag. See "What gated means" below.

- After two rounds of printf haven't narrowed the bug, switch to a debugger (GDB, Delve, or pdb) instead of adding more print statements.

- **Log boundaries, not interiors.** Log on entry with args and on exit with return value. That tells you whether the contract held or broke. Print statements inside a loop body rarely do.

- **Add a regression test before closing.** Lock in what you learned so the same bug can't silently return.

- **Document dead ends.** For multi-session bugs, keep a running log of what was ruled out and why at `.claude/debugging/<bug-name>/README.md`. When the bug is resolved, rename the folder to `.claude/debugging/<bug-name>_done`. If a `HANDOFF.md` exists, reference it there.

- **Keep debug code out of production paths.** Gated helpers are fine to commit. Unconditional print statements and dumps are not — remove them before merging.

## Instrument before you hunt

Before spending iterations on a hard-to-reproduce bug in any system with non-trivial internal state, ask: "Is there a cheap way to print the whole state at this point?" If yes, add it before anything else. A small helper that makes a data structure visible can outweigh a week of printf hunting.

This is not polish — treat it with the same priority as the first passing test.

## What gated means

A helper is gated when output only fires if a condition is explicitly set: a `DEBUG=1` env var, a `--verbose` flag, or a build tag. Zero overhead when off. Always guard debug output this way before committing.

## Concrete examples

**Compiler / transpiler (niche but instructive):** adding `ExprString`, `PatternString`, `TypeString`, `DumpModule`, and a two-level `H2GO_DEBUG` logger to a Haskell-to-Go transpiler took one session and made every subsequent debugging session faster. Test output now shows the full AST at each pipeline stage instead of requiring mental reconstruction from raw Go struct dumps.

**Generic state machine or middleware chain:** if a request or event passes through several handlers and exits wrong, add a small `debugChain(label string, state any)` helper (gated by `DEBUG=1`) that prints label plus a JSON or pretty-printed snapshot of state. Call it at the entry and exit of each handler. You'll see exactly which hop corrupted the value without sprinkling ad-hoc prints everywhere.

## The checklist

- Every non-trivial internal type gets a `String()` / `__repr__` / `Display` method or a free `FooString(x Foo) string` function. Nil-safe. Called from tests and print statements alike.
- A gated debug logger (env var, flag, or build tag) emits pipeline milestones at level 1 and per-item detail at level 2. Zero overhead when off.
- Key pipeline stages (parse, desugar, type-check, codegen) each emit at least one log line naming the stage, the module, and the item count.

## What to add and where

**String helpers** go in a dedicated `debug.go` (or `_string.go`) file next to the types. Free functions (`ExprString(e Expr) string`) are safer than interface methods when the interface is already defined without `String()` — no need to touch every implementor. Make them nil-safe.

**Gated logger** goes in its own small package (`internal/dbg` or similar):
- `Log(msg, kv...)` fires at level 1 (pipeline milestones)
- `Log2(msg, kv...)` fires at level 2 (per-item detail)
- `Enabled() bool` lets call sites skip expensive string building

**Where to instrument:**
- Parser entry point: log after lex (token count) and after parse (decl count)
- Each pipeline pass entry point: log module name + item count on entry and exit
- Codegen per-item: log which function/type is being emitted (level 2 only)

## Instrumenting a new pipeline stage

A small permanent gated addition can make a stage fully transparent for all future sessions. Pick by stage shape:

- **Lexer:** hook the single emit point — one `Log2` call covers the whole stage, shows every token in order at level 2.
- **Recursive descent parser (Thorsten Ball trace):** add a depth counter to the parser state; create `trace.go` with two gated methods (`ptrace`/`puntrace`); add `defer p.puntrace(p.ptrace("parseFoo"))` at the top of each parse function. Produces an indented call tree at level 2 — which rule fired, in what order, what token it saw. Example:
  ```
  > parseDecl  tok=VarID text=foo
    > parseExpr  tok=VarID text=x
    < parseExpr
  < parseDecl
  ```
- **Linear pass (desugar, rename, codegen):** one `Log` on entry and one on exit with stage name and item count. Spots "pass never ran" or "saw 0 items" at level 1.

| Level | Output |
|---|---|
| 1 | pipeline stages with item counts |
| 2 | level 1 + token stream + parser call tree |

## GDB when observability runs dry (use a real debugger)

If the above tools (String helpers, debug logger, dump functions) don't surface the problem,
and the binary or runtime supports it, reach for GDB before adding more print statements.

**Try GDB when:**
- A crash or panic has no readable stack trace
- A value looks correct at the logging call site but wrong downstream (silent mutation)
- A loop or recursive walk runs forever or terminates too early with no visible signal
- The program is a compiled binary (C, C++, Go with `CGO`, Rust) or a language with a GDB extension (Python `gdb`, Go `dlv` when GDB isn't available)

**Quick start for a compiled binary:**
```bash
# build with debug symbols (no optimization)
go build -gcflags="all=-N -l" -o mybin .   # Go
gcc -g -O0 -o mybin main.c                  # C

gdb ./mybin
(gdb) break main.go:42        # or function name: break parseModule
(gdb) run --flag arg
(gdb) bt                      # backtrace on crash
(gdb) p someVar               # print variable
(gdb) watch someVar           # break on write
(gdb) info locals             # all locals in current frame
```

**For Go specifically**, prefer `dlv` (Delve) over GDB — it understands goroutines and Go types natively:
```bash
dlv debug ./cmd/myapp -- --flag arg
(dlv) break internal/parser/parser.go:42
(dlv) continue
(dlv) print mod.Decls         # prints Go slice/struct directly
(dlv) goroutines              # list all goroutines
```

Use GDB/dlv as a last resort after observability helpers fail, not as the first move. A good `DumpModule()` call in a test often beats a 20-minute GDB session.

## When this fires

Ask before writing any debugging code: "Will I be back here guessing what the data looks like?" If yes, invest in a `String()` or `Dump*` helper first. The time to add it is before the second confused debugging session, not after the fifth.
