#!/bin/bash

# Minimal Error Handling function
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

# Prevents script from being run as root
if [ "$EUID" -eq 0 ]; then
  die "This script must NOT be run as root. Please run it as a regular user."
fi

# Clone grub-btrfs repo
git clone https://github.com/Antynea/grub-btrfs || \
  die "Failed to clone grub-btrfs repository."
cd grub-btrfs || die "Failed to change directory to grub-btrfs."

# Install grub-btrfs
sudo make install || die "Failed to install grub-btrfs."

# Clean Up
cd .. || die "Failed to change directory back."
sudo rm -rf grub-btrfs || die "Failed to remove grub-btrfs directory."

# Install Gruvbox GRUB theme
cd ../.. || die "Failed to change directory to project root."
sudo mkdir -p /boot/grub/themes || \
  die "Failed to create GRUB themes directory."
sudo cp -rf boot/grub/themes/gruvbox-dark/ /boot/grub/themes/ || \
  die "Failed to copy Gruvbox GRUB theme."

# Update /etc/default/grub to use the new theme
GRUB_THEME_LINE='GRUB_THEME="/boot/grub/themes/gruvbox-dark/theme.txt"'
sudo sed -i "/^GRUB_THEME=/s|^GRUB_THEME=.*|$GRUB_THEME_LINE|" \
  /etc/default/grub || \
  die "Failed to set GRUB_THEME line in /etc/default/grub."
sudo grep -qxF "$GRUB_THEME_LINE" /etc/default/grub || \
  echo -e "\n$GRUB_THEME_LINE" | sudo tee -a /etc/default/grub > /dev/null \
  || die "Failed to append GRUB_THEME line to /etc/default/grub."

# Uncomment GRUB_FONT line
sudo sed -i 's/^#GRUB_FONT=/GRUB_FONT=/' /etc/default/grub || \
  die "Failed to uncomment GRUB_FONT line in /etc/default/grub."

# Update grub.cfg
sudo grub-mkconfig -o /boot/grub/grub.cfg || \
  die "Failed to generate /boot/grub/grub.cfg."
