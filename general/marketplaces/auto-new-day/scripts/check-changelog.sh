#!/usr/bin/env bash
# check-changelog.sh <plugin-root>
# Pre-commit check: when staged changes touch a plugin's files, require that
# the staged plugin.json version differs from HEAD and that the staged
# CHANGELOG.md has a `## <version>` entry. Silent exit 0 when the plugin has
# no staged changes.
set -u
root=$(cd "${1:?usage: check-changelog.sh <plugin-root>}" && pwd -P)
top=$(git -C "$root" rev-parse --show-toplevel) || exit 0
top=$(cd "$top" && pwd -P)
prefix=${root#"$top"}; prefix=${prefix#/}; [ -n "$prefix" ] && prefix="$prefix/"
changed=$(git -C "$top" diff --cached --name-only -- "${prefix:-.}" | grep -v "^${prefix}CHANGELOG.md$")
[ -n "$changed" ] || exit 0
manifest="${prefix}.claude-plugin/plugin.json"
new=$(git -C "$top" show ":$manifest" 2>/dev/null | jq -r '.version // empty')
old=$(git -C "$top" show "HEAD:$manifest" 2>/dev/null | jq -r '.version // empty')
fail() { echo "check-changelog: ${prefix:-./}: $*" >&2; exit 1; }
[ -n "$new" ] || fail "no version in staged $manifest"
[ "$new" != "$old" ] || fail "plugin files changed but version is still $new; bump $manifest"
git -C "$top" show ":${prefix}CHANGELOG.md" 2>/dev/null | grep -q "^## $new\b" \
  || fail "stage a '## $new' entry in ${prefix}CHANGELOG.md describing the change"
exit 0
