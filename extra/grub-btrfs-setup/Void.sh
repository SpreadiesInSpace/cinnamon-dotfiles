#!/bin/bash

# Minimal Error Handling function
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  die "Please run the script as superuser."
fi

# Install grub-btrfs
xbps-install -Syu btrfs-progs grub bash gawk inotify-tools grub-btrfs \
  grub-btrfs-runit || \
  die "Failed to install required packages with xbps-install."

# Update grub.cfg and enable grub-btrfs daemon
grub-mkconfig -o /boot/grub/grub.cfg || \
  die "Failed to generate /boot/grub/grub.cfg."
ln -s /etc/sv/grub-btrfs /var/service || \
  die "Failed to create symlink for grub-btrfs service."
