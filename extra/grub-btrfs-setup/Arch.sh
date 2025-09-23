#!/bin/bash

# Minimal Error Handling function
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  die "Please run the script as superuser."
fi

# Install grub-btrfs
pacman -Syu --needed --noconfirm btrfs-progs grub bash gawk inotify-tools \
  grub-btrfs || die "Failed to install required packages."

# Update grub.cfg and enable grub-btrfs daemon
grub-mkconfig -o /boot/grub/grub.cfg || \
  die "Failed to generate /boot/grub/grub.cfg."
systemctl enable --now grub-btrfsd.service || \
  die "Failed to enable and start grub-btrfsd.service."
