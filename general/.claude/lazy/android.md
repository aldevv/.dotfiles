# Android development

## Phone screen lock

- Prefer work that doesn't need the phone's screen: `adb install`, `adb shell run-as <pkg>`, tmux/CLI inside the app all work while it's locked. Only things that open UI (browser, permission dialogs, install prompts) need it unlocked.
- When the screen must stay on, save `adb shell settings get system screen_off_timeout`, raise it, and in the same step start a background watcher that polls for the thing being waited on and restores the saved value as soon as it's done, or after 5 minutes at most. Never leave the timeout raised while idly waiting for the user.
- Unlock over adb: `input keyevent KEYCODE_WAKEUP`, then `wm dismiss-keyguard` (opens the password prompt; swiping is unreliable), `input text <password>`, `input keyevent KEYCODE_ENTER`. Check with `dumpsys window | grep isKeyguardShowing`. Lock again with `input keyevent KEYCODE_SLEEP` as soon as the screen isn't needed. The password lives in the project's `CLAUDE.local.md`, never in shared files.
- Before any `screencap`, check the foreground app (`dumpsys activity activities | grep topResumedActivity`) and only capture when it's the app under test; never screenshot whatever else the user is doing. Prefer reading app state without the screen (`run-as`, tmux `capture-pane`).
- Never raise the screen timeout above a work-profile policy (`dumpsys device_policy | grep maximumTimeToUnlock`).

## Xiaomi / HyperOS quirks

- `input`, `pm grant` and similar need Developer options → "USB debugging (Security settings)" on, which only takes effect after a reboot (`getprop persist.security.adbinput` = 1 isn't enough on its own).
- adb installs show an "Install via USB" prompt that auto-denies after a few seconds; ticking "Remember my choice" once makes later installs silent.
- After a reboot, Wireless debugging is off and the fixed `adb tcpip 5555` port is gone: the user re-enables it and gives the new IP:port, then run `adb connect <ip>:<port> && adb tcpip 5555 && adb connect <ip>:5555`.

## Connecting the phone over Wi-Fi (Mac)

- Install adb with `brew install --cask android-platform-tools`, then `xattr -dr com.apple.quarantine /opt/homebrew/Caskroom/android-platform-tools/*/platform-tools`. Until the quarantine flag is gone, every `adb` call (even `adb version`) hangs silently.
- Pairing: the user opens Wireless debugging > "Pair device with pairing code". That pairing port only listens while that screen is open, and the port and code change every time it opens, so ask for fresh ones (check with `nc -z <ip> <port>` first). Then `adb pair <ip>:<pairport> <code>`, `adb connect <ip>:<port>`, `adb tcpip 5555`, `adb connect <ip>:5555`, and use `-s <ip>:5555` from then on.
- Wrap adb calls in a timeout (`perl -e 'alarm 20; exec @ARGV' adb ...`): a stuck pair/connect never returns.
- The work phone's unlock PIN is `PHONE_PIN` in `~/work/.envrc`. Never echo it.
- Okta Verify pushes: `~/.claude/skills/amazon-workspace-ops/scripts/phone-okta-approve.sh` unlocks the phone, taps "Yes, it's me", then "Use PIN" + PIN (Okta asks to re-verify; without it the push stays pending), keeps answering follow-up approval screens until none appears, and only then locks the phone.
- Keep wireless debugging authorized: `settings put global adb_allowed_connection_time 0` (no 7-day auth expiry; set 2026-11-06 on the moto g24). Wireless debugging itself turns off on reboot. Fixed with Automate (2026-11-06, verified: set to 0, back to 1 within 31s): `pm grant com.llamalab.automate android.permission.WRITE_SECURE_SETTINGS`, flow "Keep wireless debugging on" = Flow beginning -> System setting set (Global, `"adb_wifi_enabled"` as an expression, value 1) -> Delay 60s (inexact, no wake) -> back to the setting block, and Automate Settings > "Run on system startup" on (also `deviceidle whitelist +com.llamalab.automate`). After a reboot, port 5555 is gone, but the paired Mac sees the phone through mDNS (`adb devices` shows `adb-<serial>._adb-tls-connect._tcp`); `phone-okta-approve.sh` uses that to run `adb tcpip 5555` again on its own.
