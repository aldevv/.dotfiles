#!/usr/bin/env bash
# check-domain-neutral.sh
# Enforce that the generic auto-new-day engine carries NO work/domain-specific
# terminology. Everything domain-specific belongs in a domain pack (e.g.
# auto-new-day-work), never here. Scans the engine tree for a denylist of
# unambiguous work identifiers and exits non-zero on any hit.
#
# Run manually, from a git pre-commit hook, or in CI over the dotfiles repo:
#   scripts/check-domain-neutral.sh [<dir>]   # dir defaults to the engine root
#
# A line may opt out with a trailing `domain-neutral-ignore` marker (use only
# for a genuinely generic mention, e.g. naming "a connector pack" as an example
# of a domain pack).

set -u
ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"

# Unambiguous work/domain identifiers. Deliberately NOT the bare word
# "connector" (too generic); only terms that could not appear in a
# domain-neutral engine.
PATTERN='baton-|baton_|ConductorOne|al-conductorone|ductone|\bCX[HPO]-[0-9]|squire|Connector Horizon|btipling|johnallers|ggreer|axiomatic|baton-admin|validate-connector|my-connector-review'

hits=$(grep -rInE "$PATTERN" \
  --include='*.sh' --include='*.md' --include='*.json' \
  "$ROOT" 2>/dev/null \
  | grep -v '/.git/' \
  | grep -v 'domain-neutral-ignore' \
  | grep -v "scripts/check-domain-neutral.sh:")

if [ -n "$hits" ]; then
  echo "domain-neutral check FAILED: work/domain terms found in the generic engine" >&2
  echo "$hits" | sed "s|^$ROOT/||" >&2
  echo "" >&2
  echo "Move the offending content into a domain pack, genericize it, or (for a" >&2
  echo "truly generic mention) append a 'domain-neutral-ignore' marker comment." >&2
  exit 1
fi
echo "domain-neutral check passed: no work/domain terms in $ROOT"
