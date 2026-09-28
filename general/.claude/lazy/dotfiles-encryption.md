# Dotfiles secrets (git-secret / `.scr`)

Secrets in the personal dotfiles are managed with [git-secret](https://git-secret.io). Plaintext stays gitignored; a GPG-encrypted `<path>.scr` copy is what gets committed.

- Repo: `~/.dotfiles/personal` (git-secret root; `~/.gitsecret` symlinks to `~/.dotfiles/personal/.gitsecret`).
- Encrypted extension is `.scr` (not git-secret's default `.secret`), set by `export SECRETS_EXTENSION=".scr"` in `~/.config/zsh/.zprofile`. This must be in the shell env for `git secret` to read/write the right filenames.
- `.gitignore` ignores the plaintext (`.config/rclone/rclone.conf`, `*.conf`) and force-tracks the ciphertext (`!*.scr`).
- Recipient: your own key, `jbernal@unal.edu.co` (GPG `rsa3072/F2BC4837D3501299`, encryption subkey `7EE16B661B84352D`). `git secret whoknows` lists recipients.
- Registered secrets: `git secret list` (includes `.config/rclone/rclone.conf` and `.local/share/.pass/*.gpg`).

## Refresh a changed secret and push

The plaintext lives at its normal path (e.g. `~/.config/rclone/rclone.conf`, which stow points into this repo). After editing it:

```
cd ~/.dotfiles/personal
git secret hide -m            # re-encrypt only files whose hash changed
git add .config/rclone/rclone.conf.scr .gitsecret/paths/mapping.cfg
git commit -m "rclone: refresh encrypted config"
git push
```

`dotpassfile <plaintext-path>` is a wrapper that does add + hide + stage in one shot.

### Gotcha: `hide -m` catches sibling drift

`git secret hide -m` re-encrypts EVERY secret whose current plaintext hash differs from `mapping.cfg`, not just the one you touched (e.g. a stale `gh_token`). GPG output is also nondeterministic, so any re-hidden file shows a diff even when its content is unchanged. To keep a commit scoped to one secret:

```
# capture the new hash line for your file from mapping.cfg first, then:
git checkout -- <other-secret>.scr .gitsecret/paths/mapping.cfg   # revert siblings + mapping to HEAD
# re-apply only your file's new hash into the reverted mapping.cfg (awk/sed on its path line)
```

Flag unrelated drift (like a stale token) to the user instead of silently committing it.

## Never commit plaintext

`*.conf` and the exact plaintext paths are gitignored, but ad-hoc copies like `rclone.conf.bak.YYYYMMDD` are NOT matched by those patterns and will show as untracked. Delete them before any `git add -A`.

## Restore on a new machine

`git secret reveal` decrypts all `.scr` back to plaintext (needs the GPG private key imported).
