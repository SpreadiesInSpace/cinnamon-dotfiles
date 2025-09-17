#!/usr/bin/env bash

# Exit early if NixOS is installed via cinnamon-ISO
if [ -f ".nixos-25.05.done" ]; then
  echo "This NixOS install was done via Install-NixOS.sh."
  echo "Now run Theme.sh with the following command:"
  echo "./Theme.sh"
  exit 0
fi

# Source common functions
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }
[ -f ./Setup-Common.sh ] || die "Setup-Common.sh not found."
source ./Setup-Common.sh || die "Failed to source Setup-Common.sh"

# Declare variables that will be set by sourced functions
declare username hostname timezone enable_autologin is_vm

# Check if the script is run as root
check_if_root

# Check if the script is run from the root account
check_if_not_root_account

# Get the current username
get_current_username

# Autologin Prompt
prompt_for_autologin

# VM Prompt
prompt_for_vm

# Prompt for hostname and timezone
prompt_hostname
prompt_timezone "nixos"

# Display Status from Prompts
display_status "$enable_autologin" "$is_vm"

# Declare config file
CONFIG="/etc/nixos/configuration.nix"

# Back up old configuration.nix
timestamp=$(date +%s)
cp "$CONFIG" "$CONFIG.old.${timestamp}" || \
  die "Failed to back up configuration.nix"

# Copy custom configuration.nix
cp ./etc/nixos/configuration.nix "$CONFIG" || \
  die "Failed to copy configuration.nix"

# Configure all NixOS settings
configure_nixos_settings "$CONFIG" "$username" "$hostname" "$timezone" \
  "$enable_autologin"

# Place Login Wallpaper
setup_login_wallpaper "$CONFIG"

# Reconfigures system
retry nixos-rebuild switch --upgrade || \
  die "Failed to rebuild NixOS."

# Enable Flathub for Flatpak
enable_flathub

# Add flag for Setup-Theme.sh
add_setup_theme_flag "nixos"

# Display Reboot Message
print_reboot_message
