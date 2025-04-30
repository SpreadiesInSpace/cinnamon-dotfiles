#!/bin/bash

# Install Gruvbox GRUB theme
cd ../..
sudo mkdir -p /boot/grub/themes
sudo cp -vnpr boot/grub/themes/gruvbox-dark/ /boot/grub/themes/

CONFIG_FILE="/etc/nixos/configuration.nix"

# Uncomment theme related lines in grub section
sudo sed -i '/^\s*grub = {/,/^\s*};/ {
  s/^\(\s*\)#\s*theme = /\1theme = /
  s/^\(\s*\)#\s*splashImage = /\1splashImage = /
}' "$CONFIG_FILE"

# Update grub.cfg and enable grub-btrfs daemon
sudo nixos-rebuild switch
