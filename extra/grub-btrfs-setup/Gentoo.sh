#!/bin/bash

# Minimal Error Handling function
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  die "Please run the script as superuser."
fi

# Detect Init System
if eselect profile show | grep -q systemd; then
  GENTOO_INIT="systemd"
else
  GENTOO_INIT="openrc"
fi

# Enable Guru Repository
emerge -uvq app-eselect/eselect-repository || \
  die "Failed to install app-eselect/eselect-repository."
eselect repository enable guru || \
  die "Failed to enable the guru repository."
emaint sync -r guru || die "Failed to sync the guru repository."

# Use systemd for grub-btrfs
if [ "$GENTOO_INIT" = "openrc" ]; then
echo "app-backup/grub-btrfs systemd" | \
  tee /etc/portage/package.use/grub-btrfs > /dev/null || \
  die "Failed to set USE flag for grub-btrfs."
fi

# Allow Unstable Package to be Merged
echo "app-backup/grub-btrfs ~amd64" | \
  tee /etc/portage/package.accept_keywords/grub-btrfs > /dev/null || \
  die "Failed to add grub-btrfs to package.accept_keywords."

# Install grub-btrfs
emerge -vq app-backup/grub-btrfs || die "Failed to install grub-btrfs."

# Update grub.cfg and enable grub-btrfs daemon
grub-mkconfig -o /boot/grub/grub.cfg || \
  die "Failed to generate /boot/grub/grub.cfg."
if [ "$GENTOO_INIT" = "systemd" ]; then
  systemctl enable --now grub-btrfsd.service || \
    die "Failed to enable and start grub-btrfsd.service."
fi