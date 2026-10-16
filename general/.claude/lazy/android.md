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
