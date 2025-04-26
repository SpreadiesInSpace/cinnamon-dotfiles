#!/bin/bash

# Source common functions
source ./Setup-Common.sh

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

# Backs up old configuration.nix
timestamp=$(date +%s)
cp /etc/nixos/configuration.nix "/etc/nixos/configuration.nix.old.${timestamp}"

# Copies my configuration.nix
cp ./home/theming/NixOS/configuration.nix /etc/nixos/configuration.nix

# If autologin is set to false, modify line 73 in /etc/nixos/configuration.nix
if [ "$enable_autologin" = false ]; then
    sed -i '73s/^\( *enable *= *\)true;/\1false;/' /etc/nixos/configuration.nix
fi

# Replace the placeholder with the actual username
sed -i "s/f16poom/$username/g" /etc/nixos/configuration.nix

# Prompt the user for hostname
read -p "Enter the hostname for your system: " hostname
if [[ ! "$hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?$ ]]; then echo "Invalid hostname. Must be alphanumeric and may include hyphens (no leading/trailing hyphen)."; exit 1; fi
sed -i "s/hostName = .*;/hostName = \"$hostname\";/g" /etc/nixos/configuration.nix

# Places Login Wallpaper
cp -vnr home/wallpapers/Login_Wallpaper.jpg /boot/

# Add Nix Unstable and 23.05 Channels (for Neovim, icons and themes)
nix-channel --add https://nixos.org/channels/nixos-unstable nixos
# nix-channel --add https://nixos.org/channels/nixos-23.05 nixos-23.05
nix-channel --update

# Reconfigures system
nixos-rebuild switch --upgrade

# Enable Flathub for Flatpak
enable_flathub

# Add flag for Setup-Theme.sh
add_setup_theme_flag "nixos"

# Display Reboot Message
print_reboot_message
