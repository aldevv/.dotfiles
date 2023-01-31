if [ -d "$HOME/.local/Programs/rust/cargo/env" ]; then
    source "$HOME/.local/Programs/rust/cargo/env"
fi

if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then . $HOME/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer

