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

# Apply Fixes for openSUSE
sed -i '/#GRUB_BTRFS_GRUB_DIRNAME/a GRUB_BTRFS_GRUB_DIRNAME="/boot/grub2"' \
  config || die "Failed to update GRUB_BTRFS_GRUB_DIRNAME in config."
sed -i '/#GRUB_BTRFS_MKCONFIG=/a GRUB_BTRFS_MKCONFIG=/sbin/grub2-mkconfig' \
  config || die "Failed to update GRUB_BTRFS_MKCONFIG in config."
sed -i '/#GRUB_BTRFS_SCRIPT_CHECK=/a GRUB_BTRFS_SCRIPT_CHECK=grub2-script-check' \
  config || die "Failed to update GRUB_BTRFS_SCRIPT_CHECK in config."
sed -i '/#GRUB_BTRFS_MKCONFIG_LIB/a GRUB_BTRFS_MKCONFIG_LIB=/usr/share/grub2/grub-mkconfig_lib' \
  config || die "Failed to update GRUB_BTRFS_MKCONFIG_LIB in config."

# Install dependencies
sudo zypper install -y btrfs-progs bash gawk inotify-tools || \
  die "Failed to install dependencies with zypper."

# Install grub-btrfs
sudo make install || die "Failed to install grub-btrfs."

# Clean Up
cd .. || die "Failed to change directory back."
sudo rm -rf grub-btrfs || die "Failed to remove grub-btrfs directory."

# Install Gruvbox GRUB theme
cd ../.. || die "Failed to change directory to project root."
sudo mkdir -p /boot/grub2/themes || \
  die "Failed to create GRUB themes directory."
sudo cp -rf boot/grub/themes/gruvbox-dark/ /boot/grub2/themes/ || \
  die "Failed to copy Gruvbox GRUB theme."

# Update /etc/default/grub to use the new theme
GRUB_THEME_LINE='GRUB_THEME="/boot/grub2/themes/gruvbox-dark/theme.txt"'
sudo sed -i "/^GRUB_THEME=/s|^GRUB_THEME=.*|$GRUB_THEME_LINE|" \
  /etc/default/grub || \
  die "Failed to set GRUB_THEME line in /etc/default/grub."
sudo grep -qxF "$GRUB_THEME_LINE" /etc/default/grub || \
  echo -e "\n$GRUB_THEME_LINE" | sudo tee -a /etc/default/grub > /dev/null \
  || die "Failed to append GRUB_THEME line to /etc/default/grub."

# Check and comment out GRUB_TERMINAL_OUTPUT="console" if it exists
sudo sed -i 's/^GRUB_TERMINAL_OUTPUT="console"/#&/' /etc/default/grub || \
  die "Failed to comment out GRUB_TERMINAL_OUTPUT in /etc/default/grub."

# Update grub.cfg and enable grub-btrfs daemon
sudo grub2-mkconfig -o /boot/grub2/grub.cfg || \
  die "Failed to generate /boot/grub2/grub.cfg."
sudo systemctl enable --now grub-btrfsd.service || \
  die "Failed to enable and start grub-btrfsd.service."
