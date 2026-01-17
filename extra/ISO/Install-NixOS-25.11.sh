#!/bin/bash
set -euo pipefail

# Download and source common functions
echo "Sourcing functions..."
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }
URL="https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles"
URL="$URL/main/extra/ISO/Install-Common.sh"
curl -fsSL -o Install-Common.sh "$URL" || \
  die "Failed to download Install-Common.sh"
[ -f ./Install-Common.sh ] || die "Install-Common.sh not found."
source ./Install-Common.sh || die "Failed to source Install-Common.sh"

# Declare variables that will be set by sourced functions
declare username hostname timezone drive enable_autologin rootpasswd
declare userpasswd

# Check if script is run as root
check_if_root

# Detect if booted in UEFI or BIOS mode
detect_boot_mode

# Sync time and hardware clock
time_sync

# Prompt for root password
prompt_root_password

# Prompt for new username
prompt_username

# Prompt for new user password
prompt_user_password

# Prompt for hostname
prompt_hostname

# Prompt for timezone
prompt_timezone

# Prompt for GRUB timeout
prompt_grub_timeout

# Autologin Prompt
prompt_for_autologin

# VM Prompt
prompt_for_vm

# Prompt for drive to partition
prompt_drive

# Partition the drive
partition_drive "default"

# Determine correct partition suffix
partition_suffix "default"

# Format the partitions
format_partitions

# Create BTRFS subvolumes
create_btrfs_subvolumes

# Mount the partitions
mount_partitions "nixos"

# Generate NixOS config
nixos-generate-config --root /mnt || \
  die "Failed to generate NixOS config."

# Download custom NixOS config
CONF="https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles"
CONF="$CONF/refs/heads/main/etc/nixos/configuration.nix"
retry curl -fsSL -o configuration.nix "$CONF" || \
  die "Failed to download custom configuration.nix"

# Set Config File Variable
CONFIG="/mnt/etc/nixos/configuration.nix"

# Back up old configuration.nix
timestamp=$(date +%s)
cp "$CONFIG" "$CONFIG.old.${timestamp}" || \
  die "Failed to back up configuration.nix"

# Copy custom configuration.nix
cp configuration.nix "$CONFIG" || \
  die "Failed to copy configuration.nix"

# Configure all NixOS settings
configure_nixos_settings "$CONFIG" "$username" "$hostname" "$timezone" \
  "$enable_autologin" "$drive"

# Install NixOS
retry nixos-install --no-root-passwd || \
  die "Failed to install NixOS."

# Ensure variables are exported before chroot
export username rootpasswd userpasswd grub_timeout || \
  die "Failed to export required variables."

# Set Passwords
nixos-enter --root /mnt -c "echo 'root:$rootpasswd' | chpasswd" || \
  die "Failed to set root password."
nixos-enter --root /mnt -c "echo '$username:$userpasswd' | chpasswd" || \
  die "Failed to set user password."

# Enable Flathub remote for Flatpak
nixos-enter --root /mnt -c 'echo "Enabling Flathub..." && \
  flatpak remote-add --if-not-exists flathub \
  https://dl.flathub.org/repo/flathub.flatpakrepo' || \
  die "Failed to enable Flathub remote."

# Place Login Wallpaper
setup_login_wallpaper "$CONFIG" "/mnt"

# Set GRUB timeout
sed -i "s/^\\(\\s*\\)timeout\\s*=.*/\\1timeout = $grub_timeout;/" \
  "$CONFIG" || \
  die "Failed to set GRUB_TIMEOUT."

# Clone cinnamon-dotfiles repo as new user
clone_dotfiles "nixos"

# Setup GRUB theme
setup_grub_theme "NixOS"
