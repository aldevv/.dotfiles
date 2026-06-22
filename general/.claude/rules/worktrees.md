# Worktrees rules

## Worktrees
Worktrees live at `~/worktrees/<repo>/<branch>` for personal repos and `~/worktrees/work/<repo>/<branch>` for repos whose main checkout is under `$WORK` (managed by the `wt` helper at `$UTILITIES/stuff-git/wt`). The `~/worktrees/work/` parent carries `CLAUDE.md` and `.claude/lazy` symlinks pointing at `$WORK/`, so work worktrees inherit work-scope memory automatically.

- **Mirror the main checkout's `.envrc`.** Worktrees inherit `.git` but not working-tree files. When work starts in a worktree, copy `.envrc` from the main checkout and run `direnv allow` once. If the main repo has no `.envrc`, nothing to mirror.
- **Promote repeated dev-binary build sequences to `.envrc`.** If the same multi-step build runs more than a couple of times and the project has no Makefile / `bin/` target, define it as an alias or shell function in `.envrc`. Add it to **both** the main checkout and every active worktree's copy.
