# Phone (Android, proot Debian)

This session runs on my Android phone: proot Debian inside the `dev.aldevv.claudecode` app. Ignore the stale `/etc/hostname`. `~/.machine_metadata` has `id=phone`.

- No `pm`/`am`/Docker. Reach Android with `adb connect 127.0.0.1:5555` (already authorized), then `export ANDROID_SERIAL=127.0.0.1:5555`.
- Install apps with `adb install --user 0 --no-incremental`; MIUI may pop an install prompt I must accept on screen.
- `/sdcard` is mounted. `GOROOT` is exported as `/usr/local/go`; override it when using a Go installed elsewhere.
- No SSH key: use `gh`/HTTPS remotes. The dotfiles `epic`/`personal`/`wiki` submodules are intentionally not cloned here; `sync-dotfiles` syncs the parent only.
