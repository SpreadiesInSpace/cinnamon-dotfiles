#!/bin/bash

# Minimal Error Handling
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

# Install zram-generator
apt update || die "APT Update Failed."
apt install -y systemd-zram-generator || \
  die "Failed to install zram-generator."

# Source Install-Common.sh and configure zRAM
sudo bash -c 'source ../../extra/ISO/Install-Common.sh && configure_zram' || \
  die "Failed to configure zRAM."

# Update GRUB Config
sudo update-grub || die "Failed to regenate GRUB config."

# Reload systemd
sudo systemctl daemon-reload || die "Failed to reload systemd."

# Clean Up
sudo rm -f Master-Common.sh

# Show zRAM
zramctl