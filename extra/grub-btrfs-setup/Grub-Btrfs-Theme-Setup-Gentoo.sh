#!/bin/bash

# Minimal Error Handling function
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

# PWD Check
[[ -d "../../boot/grub/themes/gruvbox-dark" ]] || \
  die "Run from cinnamon-dotfiles/extra/grub-btrfs-setup/ directory"

# Prevents script from being run as root
if [ "$EUID" -eq 0 ]; then
  die "This script must NOT be run as root. Please run it as a regular user."
fi

# Detect Init System
if eselect profile show | grep -q systemd; then
  GENTOO_INIT="systemd"
else
  GENTOO_INIT="openrc"
fi

# Enable Guru Repository
sudo emerge -uvq app-eselect/eselect-repository || \
  die "Failed to install app-eselect/eselect-repository."
sudo eselect repository enable guru || \
  die "Failed to enable the guru repository."
sudo emaint sync -r guru || die "Failed to sync the guru repository."

# USE Systemd
echo "app-backup/grub-btrfs systemd" | \
  sudo tee /etc/portage/package.use/grub-btrfs > /dev/null || \
  die "Failed to set USE flag for grub-btrfs."

# Allow Unstable Package to be Merged
echo "app-backup/grub-btrfs ~amd64" | \
  sudo tee /etc/portage/package.accept_keywords/grub-btrfs > /dev/null || \
  die "Failed to add grub-btrfs to package.accept_keywords."

# Install grub-btrfs
sudo emerge -vq app-backup/grub-btrfs || die "Failed to install grub-btrfs."

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

# Update grub.cfg and enable grub-btrfs daemon
sudo grub-mkconfig -o /boot/grub/grub.cfg || \
  die "Failed to generate /boot/grub/grub.cfg."
if [ "$GENTOO_INIT" = "systemd" ]; then
  sudo systemctl enable --now grub-btrfsd.service || \
    die "Failed to enable and start grub-btrfsd.service."
fi