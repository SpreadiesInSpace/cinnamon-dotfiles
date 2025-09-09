#!/usr/bin/env bash

# Minimal Error Handling function
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

# Prevents script from being run as root
if [ "$EUID" -eq 0 ]; then
  die "This script must NOT be run as root. Please run it as a regular user."
fi

# Install Gruvbox GRUB theme
cd ../.. || die "Failed to change directory to project root."
sudo mkdir -p /boot/grub/themes || \
  die "Failed to create GRUB themes directory."
sudo cp -rf boot/grub/themes/gruvbox-dark/ /boot/grub/themes/ || \
  die "Failed to copy Gruvbox GRUB theme."

CONFIG_FILE="/etc/nixos/configuration.nix"

# Uncomment theme-related lines in grub section
sudo sed -i '/^\s*grub = {/,/^\s*};/ {
  s/^\(\s*\)#\s*theme = /\1theme = /
  s/^\(\s*\)#\s*splashImage = /\1splashImage = /
}' "$CONFIG_FILE" || \
  die "Failed to uncomment grub theme lines in $CONFIG_FILE."

# Update grub.cfg and enable grub-btrfs daemon
sudo nixos-rebuild switch || die "Failed to rebuild NixOS configuration."
