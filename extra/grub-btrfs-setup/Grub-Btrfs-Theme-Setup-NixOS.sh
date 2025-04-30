#!/bin/bash

# Install Gruvbox GRUB theme
cd ../..
sudo mkdir -p /boot/grub/themes
sudo cp -vnpr boot/grub/themes/gruvbox-dark/ /boot/grub/themes/

CONFIG_FILE="/etc/nixos/configuration.nix"

<<skip
# Comment out systemd-boot section
sudo sed -i '/^\(\s*\)systemd-boot\.enable = true;/s/^\(\s*\)/\1# /' "$CONFIG_FILE"

# Uncomment grub section, ensure closing bracket is handled
sudo sed -i '/^\(\s*\)#\s*grub = {/,/^\(\s*\)#};/ {
  s/^\(\s*\)#\s*grub = /\1grub = /
  s/^\(\s*\)#\s*enable = /\1enable = /
  s/^\(\s*\)#\s*efiSupport = /\1efiSupport = /
  s/^\(\s*\)#\s*device = /\1device = /
  s/^\(\s*\)#\s*theme = /\1theme = /
  s/^\(\s*\)#\s*splashImage = /\1splashImage = /
  s/^\(\s*\)#\s*gfxmodeEfi = /\1gfxmodeEfi = /
  s/^\(\s*\)#\s*};/\1};/
}' "$CONFIG_FILE"
skip

# Uncomment theme related lines in grub section
sudo sed -i '/^\s*grub = {/,/^\s*};/ {
  s/^\(\s*\)#\s*theme = /\1theme = /
  s/^\(\s*\)#\s*splashImage = /\1splashImage = /
}' "$CONFIG_FILE"

# Update grub.cfg and enable grub-btrfs daemon
sudo nixos-rebuild switch
