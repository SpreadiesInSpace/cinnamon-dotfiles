#!/bin/bash

# Minimal Error Handling function
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

# PWD Check
[[ -d "../../boot/grub/themes/gruvbox-dark" ]] || \
  die "Run from cinnamon-dotfiles/extra/grub-btrfs-setup/ directory."

# Prevents script from being run as root
if [ "$EUID" -eq 0 ]; then
  die "This script must NOT be run as root. Please run it as a regular user."
fi

# Clone grub-btrfs repo
git clone https://github.com/Antynea/grub-btrfs || \
  die "Failed to clone grub-btrfs repository."
cd grub-btrfs || die "Failed to change directory to grub-btrfs."

# Install dependencies
sudo apt update || die "Failed to update package list."
sudo apt install -y btrfs-progs bash gawk inotify-tools || \
  die "Failed to install required packages."

# Install grub-btrfs
sudo make install || die "Failed to install grub-btrfs."

# Clean Up
cd .. || die "Failed to change directory back."
sudo rm -rf grub-btrfs || die "Failed to remove grub-btrfs directory."

# Install Gruvbox GRUB theme
cd ../.. || die "Failed to change directory to project root."
sudo mkdir -p /boot/grub/themes || \
  die "Failed to create GRUB themes directory."
sudo mv /boot/grub/themes/linuxmint /boot/grub/themes/linuxmint.original || \
  die "Failed to rename original linuxmint theme."
sudo cp -rf boot/grub/themes/gruvbox-dark /boot/grub/themes/ || \
  die "Failed to copy Gruvbox GRUB theme."
sudo mv /boot/grub/themes/gruvbox-dark /boot/grub/themes/linuxmint || \
  die "Failed to rename Gruvbox theme to linuxmint."

# Update /etc/default/grub to use the new theme
GRUB_THEME_LINE='GRUB_THEME="/boot/grub/themes/gruvbox-dark/theme.txt"'
sudo sed -i "/^GRUB_THEME=/s|^GRUB_THEME=.*|$GRUB_THEME_LINE|" \
  /etc/default/grub || \
  die "Failed to set GRUB_THEME line in /etc/default/grub."
sudo grep -qxF "$GRUB_THEME_LINE" /etc/default/grub || \
  echo -e "\n$GRUB_THEME_LINE" | sudo tee -a /etc/default/grub > /dev/null \
  || die "Failed to append GRUB_THEME line to /etc/default/grub."

# Update grub.cfg and enable grub-btrfs daemon
sudo grub-mkconfig -o /boot/grub/grub.cfg || \
  die "Failed to generate /boot/grub/grub.cfg."
sudo systemctl enable --now grub-btrfsd.service || \
  die "Failed to enable and start grub-btrfsd.service."
