# Phone (Android, proot Debian)

This session runs on my Android phone: proot Debian inside the `dev.aldevv.claudecode` app. Ignore the stale `/etc/hostname`. `~/.machine_metadata` has `id=phone`.

- No `pm`/`am`/Docker. Reach Android with `adb connect 127.0.0.1:5555` (already authorized), then `export ANDROID_SERIAL=127.0.0.1:5555`.
- Install apps with `adb install --user 0 --no-incremental`; MIUI may pop an install prompt I must accept on screen.
- `/sdcard` is mounted. `GOROOT` is exported as `/usr/local/go`; override it when using a Go installed elsewhere.
- adb's tcpip mode on 5555 is lost on reboot. Wireless debugging instead listens on the Wi-Fi IP (not 127.0.0.1) on a random port, and our key is already authorized: find the IP with a UDP-socket `getsockname()`, port-scan it, `adb connect <ip>:<port>`. Use `run-as com.easycancha.scheduler <cmd>` per command; `run-as pkg sh -c '...; ...'` splits on `;` outside run-as.
- Android build tools (arm64, all under `~/.local/share/`): Go `~/.local/go` (set `GOROOT`), NDK cross-compiler wrapper `android-ndk-r26d-sysroot/cc` (use as `CC` with `CGO_ENABLED=1 GOOS=android GOARCH=arm64`), Gradle `gradle-dist/gradle-8.7/bin/gradle`, SDK `android-sdk` (`ANDROID_HOME`), static aapt2 `android-sdk-tools-arm64/build-tools/aapt2` (pass `-Pandroid.aapt2FromMavenOverride=<path>`). Gradle's debug key lives in `~/.config/.android/debug.keystore`.
- No SSH key: use `gh`/HTTPS remotes. The dotfiles `epic`/`personal`/`wiki` submodules are intentionally not cloned here; `sync-dotfiles` syncs the parent only.
