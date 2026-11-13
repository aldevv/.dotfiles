# Mac GUI input automation (Mac laptop)

- The Mac always uses a custom Colemak layout (`Colemak Latam`, `~/Library/Keyboard Layouts/Colemak Latam.keylayout`). It does not break automation: `cliclick t:<text>` types the right characters, and Return/keypad Enter (key codes 36/76) map like US QWERTY.
- `cliclick kp:return`/`kp:enter` work in normal apps, but some targets ignore them (e.g. the `coreautha` password dialog). Submit with `osascript -e 'tell application "System Events" to key code 36'` or click the button.
- System password dialogs (e.g. Okta Verify FastPass) are `coreautha` windows, not the requesting app's. Find one via JXA `ObjC.import("CoreGraphics")` + `CGWindowListCopyWindowInfo`, owner `coreautha`, window name = requesting app.
- For the Okta Verify password dialog, run `~/.local/bin/okta-verify-watch` (full path, it can be off PATH in the tool shell): it waits for the dialog, fills the Mac password from `~/.mac_password.gpg`, and clicks OK. If another `coreautha` "Okta Verify" window is still open after it exits, run it again.
