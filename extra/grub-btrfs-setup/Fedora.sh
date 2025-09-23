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

# Apply Fixes for Fedora
sed -i '/#GRUB_BTRFS_SNAPSHOT_KERNEL/a GRUB_BTRFS_SNAPSHOT_KERNEL_PARAMETERS="systemd.volatile=state"' \
  config || die "Failed to update GRUB_BTRFS_SNAPSHOT_KERNEL_PARAMETERS."
sed -i '/#GRUB_BTRFS_GRUB_DIRNAME/a GRUB_BTRFS_GRUB_DIRNAME="/boot/grub2"' \
  config || die "Failed to update GRUB_BTRFS_GRUB_DIRNAME."
sed -i '/#GRUB_BTRFS_MKCONFIG=/a GRUB_BTRFS_MKCONFIG=/sbin/grub2-mkconfig' \
  config || die "Failed to update GRUB_BTRFS_MKCONFIG."
sed -i '/#GRUB_BTRFS_SCRIPT_CHECK=/a GRUB_BTRFS_SCRIPT_CHECK=grub2-script-check' \
  config || die "Failed to update GRUB_BTRFS_SCRIPT_CHECK."

# Install dependencies
dnf install -y btrfs-progs grub2 bash gawk inotify-tools || \
  die "Failed to install required packages with dnf."

# Install grub-btrfs
make install || die "Failed to install grub-btrfs."

# Clean Up
cd .. || die "Failed to change directory back."
rm -rf grub-btrfs || die "Failed to remove grub-btrfs directory."

# Check and comment out GRUB_TERMINAL_OUTPUT="console" if it exists
sed -i 's/^GRUB_TERMINAL_OUTPUT="console"/#&/' \
  /etc/default/grub || \
  die "Failed to comment out GRUB_TERMINAL_OUTPUT in /etc/default/grub."

# Update grub.cfg and enable grub-btrfs daemon
grub2-mkconfig -o /boot/grub2/grub.cfg || \
  die "Failed to generate /boot/grub2/grub.cfg."
systemctl enable --now grub-btrfsd.service || \
  die "Failed to enable and start grub-btrfsd.service."