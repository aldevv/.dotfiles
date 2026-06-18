#!/usr/bin/env bash
# Ensure ~/.ssh/config has a Host personal alias pointing at github.com with
# the personal key pinned (IdentitiesOnly yes, so a future work key in the
# agent can never be offered for personal traffic).
#
# Idempotent: exits 0 silently if the alias already resolves. Refuses to
# overwrite an existing Host personal block even if broken; the user may have
# pointed it somewhere intentionally.
set -euo pipefail

config="$HOME/.ssh/config"
key="$HOME/.ssh/id_ed25519"

resolved=$(ssh -G personal 2>/dev/null | awk '/^hostname /{print $2; exit}')
if [ -n "$resolved" ] && [ "$resolved" != "personal" ]; then
  exit 0
fi

if [ ! -f "$key" ]; then
  echo "ensure-personal-alias: $key not found, cannot configure Host personal" >&2
  exit 1
fi

if [ -f "$config" ] && grep -qiE '^[[:space:]]*Host[[:space:]]+([^[:space:]]+[[:space:]]+)*personal([[:space:]]|$)' "$config"; then
  echo "ensure-personal-alias: Host personal already present in $config but does not resolve. Manual review needed." >&2
  exit 1
fi

mkdir -p "$HOME/.ssh"
touch "$config"
chmod 600 "$config"

cat >> "$config" <<EOF

Host personal
    HostName github.com
    User git
    IdentityFile $key
    IdentitiesOnly yes
EOF

echo "ensure-personal-alias: appended Host personal block to $config"

resolved=$(ssh -G personal 2>/dev/null | awk '/^hostname /{print $2; exit}')
if [ "$resolved" = "github.com" ]; then
  exit 0
fi
echo "ensure-personal-alias: appended block but personal still does not resolve to github.com" >&2
exit 1
