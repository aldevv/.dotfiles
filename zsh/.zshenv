ZDOTDIR="$HOME/.config/zsh"
. "$ZDOTDIR/.zshenv"

if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then . $HOME/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer

if [ -e /home/kanon/.nix-profile/etc/profile.d/nix.sh ]; then . /home/kanon/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer
