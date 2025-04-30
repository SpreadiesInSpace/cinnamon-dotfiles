#!/bin/bash

# Source common functions
[ -f ./Setup-Common.sh ] && source ./Setup-Common.sh || { echo "Setup-Common.sh not found."; exit 1; }

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

# Display Status from Prompts
display_status "$enable_autologin" "$is_vm"

# Set Config File Variable
CONFIG="/etc/nixos/configuration.nix"

# Backs up old configuration.nix
timestamp=$(date +%s)
cp "$CONFIG" ""$CONFIG".old.${timestamp}" || die "Failed to back up configuration.nix"

# Copies my configuration.nix
cp ./home/theming/NixOS/configuration.nix "$CONFIG" || die "Failed to copy configuration.nix"

# Only run if BIOS
if [ ! -d /sys/firmware/efi ]; then
  # Comment out efiSupport inside grub block
  sudo sed -i '/^\s*grub = {/,/^\s*};/ {
    s/^\(\s*\)efiSupport = /\1# efiSupport = /
  }' "$CONFIG" || die "Failed to comment out efiSupport in grub block."
  # Comment out efi.canTouchEfiVariables
  sudo sed -i 's/^\(\s*\)efi\.canTouchEfiVariables = /\1# efi.canTouchEfiVariables = /' "$CONFIG" || die "Failed to comment out efi.canTouchEfiVariables."
fi

# If autologin is set to false, modify line 74 in /etc/nixos/configuration.nix
if [ "$enable_autologin" = false ]; then
    sed -i '74s/^\( *enable *= *\)true;/\1false;/' "$CONFIG" || die "Failed to modify autologin setting"
fi

# Replace the placeholder with the actual username
sed -i "s/f16poom/$username/g" "$CONFIG" || die "Failed to replace username in configuration.nix"

# Prompt the user for hostname
while ! read -p "Enter the hostname for your system: " hostname || [[ ! "$hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?$ ]]; do
    echo "Invalid hostname. Must be alphanumeric and may include hyphens (no leading/trailing hyphen)."
done
sed -i "s/hostName = .*;/hostName = \"$hostname\";/g" "$CONFIG" || die "Failed to update hostname in configuration.nix"

# Places Login Wallpaper
echo "Setting Login Wallpaper..."
cp -nr home/wallpapers/Login_Wallpaper.jpg /boot/ || die "Failed to copy login wallpaper"

# Add Nix Unstable and 23.05 Channels (for Neovim, icons and themes)
nix-channel --add https://nixos.org/channels/nixos-unstable nixos || die "Failed to add Nix unstable channel"
# nix-channel --add https://nixos.org/channels/nixos-23.05 nixos-23.05 || die "Failed to add Nix 23.05 channel"
nix-channel --update || die "Failed to update Nix channels"

# Reconfigures system
nixos-rebuild switch --upgrade || die "Failed to rebuild NixOS"

# Enable Flathub for Flatpak
enable_flathub

# Add flag for Setup-Theme.sh
add_setup_theme_flag "nixos"

# Display Reboot Message
print_reboot_message
