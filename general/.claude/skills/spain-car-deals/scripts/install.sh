#!/usr/bin/env bash
set -euo pipefail

SKILL="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
UNITS="$HOME/.config/systemd/user"

mkdir -p "$UNITS" "$HOME/.cache/spain-car-deals"
cp "$SKILL"/references/systemd/spain-car-deals.* "$UNITS/"
systemctl --user daemon-reload
systemctl --user enable --now spain-car-deals.timer
loginctl enable-linger "$USER" 2>/dev/null || echo "could not enable linger: the timer only runs while you are logged in" >&2
systemctl --user list-timers spain-car-deals.timer --no-pager
[ -d "$HOME/.cache/ms-playwright/personal-gmail" ] || echo "Gmail profile missing: sign in once with the personal-manage skill (gmail.js login) so the report can be emailed" >&2
