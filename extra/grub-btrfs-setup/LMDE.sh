#!/bin/bash

# Minimal Error Handling function
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  die "Please run the script as superuser."
fi

# Clone grub-btrfs repo
git clone https://github.com/Antynea/grub-btrfs || \
  die "Failed to clone grub-btrfs repository."
cd grub-btrfs || die "Failed to change directory to grub-btrfs."

# Install dependencies
apt update || die "Failed to update package list."
apt install -y btrfs-progs bash gawk inotify-tools || \
  die "Failed to install required packages."

# Install grub-btrfs
make install || die "Failed to install grub-btrfs."

# Clean Up
cd .. || die "Failed to change directory back."
rm -rf grub-btrfs || die "Failed to remove grub-btrfs directory."

# Update grub.cfg and enable grub-btrfs daemon
grub-mkconfig -o /boot/grub/grub.cfg || \
  die "Failed to generate /boot/grub/grub.cfg."
systemctl enable --now grub-btrfsd.service || \
  die "Failed to enable and start grub-btrfsd.service."
