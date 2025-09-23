#!/usr/bin/env bash

# Minimal Error Handling function
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

# PWD Check
[[ -d "../../boot/grub/themes/gruvbox-dark" ]] || \
  die "Run from cinnamon-dotfiles/extra/grub-theme-setup/ directory."

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  die "Please run the script as superuser."
fi

# Install Gruvbox GRUB theme
cd ../.. || die "Failed to change directory to project root."
mkdir -p /boot/grub/themes || \
  die "Failed to create GRUB themes directory."
cp -rf boot/grub/themes/gruvbox-dark/ /boot/grub/themes/ || \
  die "Failed to copy Gruvbox GRUB theme."

CONFIG_FILE="/etc/nixos/configuration.nix"

# Uncomment theme-related lines in grub section
sed -i '/^\s*grub = {/,/^\s*};/ {
  s/^\(\s*\)#\s*theme = /\1theme = /
  s/^\(\s*\)#\s*splashImage = /\1splashImage = /
}' "$CONFIG_FILE" || \
  die "Failed to uncomment grub theme lines in $CONFIG_FILE."

# Update grub.cfg
nixos-rebuild switch || \
  die "Failed to rebuild NixOS configuration."
