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
cp "$CONFIG" "$CONFIG.old.${timestamp}" || \
	die "Failed to back up configuration.nix"

# Copies my configuration.nix
cp ./home/theming/NixOS/configuration.nix "$CONFIG" || \
	die "Failed to copy configuration.nix"

# Only run if BIOS
if [ ! -d /sys/firmware/efi ]; then
	# Comment out efiSupport inside grub block
	sudo sed -i '/^\s*grub = {/,/^\s*};/ {
		s/^\(\s*\)efiSupport = /\1# efiSupport = /
	}' "$CONFIG" || die "Failed to comment out efiSupport in grub block."
	# Comment out efi.canTouchEfiVariables
	sudo sed -i 's/^\(\s*\)efi\.canTouchEfiVariables = /\1# efi.canTouchEfiVariables = /' \
		"$CONFIG" || die "Failed to comment out efi.canTouchEfiVariables."
fi

# If autologin is set to false, modify line 74 in /etc/nixos/configuration.nix
if [ "$enable_autologin" = false ]; then
	sed -i '74s/^\( *enable *= *\)true;/\1false;/' "$CONFIG" || \
		die "Failed to modify autologin setting."
fi

# Replace the placeholder with the actual username
sed -i "s/f16poom/$username/g" "$CONFIG" || \
	die "Failed to replace username in configuration.nix"

# Prompt the user for hostname
while true; do
	read -rp "Enter hostname: " hostname
	# Trim leading and trailing whitespace
	hostname="${hostname#"${hostname%%[![:space:]]*}"}"  # leading
	hostname="${hostname%"${hostname##*[![:space:]]}"}"  # trailing
	if [[ -z "$hostname" ]]; then
		echo "Hostname cannot be empty."
	elif [[ "$hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$ ]]; then
		break
	else
		echo "Invalid hostname. Must start/end with a letter or number and may \
include internal hyphens."
	fi
done
sed -i "s/hostName = .*;/hostName = \"$hostname\";/g" "$CONFIG" || \
	die "Failed to update hostname in configuration.nix"

# Set Timezone
while true; do
	read -rp "Enter your timezone (e.g., Asia/Bangkok): " timezone
	timezone="${timezone:-Asia/Bangkok}"  # default if empty
	if [ -f "/etc/zoneinfo/$timezone" ]; then
		echo "Timezone set to: $timezone"
		# Use sed to update the time.timeZone value in the config
		sed -i "s|^\(\s*time\.timeZone\s*=\s*\).*|\\1\"$timezone\";|" "$CONFIG"
		break
	fi
	echo "Invalid timezone: $timezone"
done

# Place Login Wallpaper
echo "Setting Login Wallpaper..."
cp -nr home/wallpapers/Login_Wallpaper.jpg /boot/ || \
	die "Failed to copy login wallpaper."

# Enable background in configuration.nix
sed -i 's|^\(\s*\)#\s*\(background\s*=.*\)|\1\2|' "$CONFIG"

# Add Nix Unstable and 23.05 Channels (for Neovim, icons and themes)
# nix-channel --add https://nixos.org/channels/nixos-unstable nixos || \
# die "Failed to add Nix unstable channel."
# nix-channel --add https://nixos.org/channels/nixos-23.05 nixos-23.05 || \
# die "Failed to add Nix 23.05 channel."
# nix-channel --update || die "Failed to update Nix channels."

# Reconfigures system
nixos-rebuild switch --upgrade || die "Failed to rebuild NixOS."

# Enable Flathub for Flatpak
enable_flathub

# Add flag for Setup-Theme.sh
add_setup_theme_flag "nixos"

# Display Reboot Message
print_reboot_message
