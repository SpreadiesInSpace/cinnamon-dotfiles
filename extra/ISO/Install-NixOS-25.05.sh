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

# Check if script is run as root
check_if_root

# Detect if booted in UEFI or BIOS mode
detect_boot_mode

# Prompt for root password
prompt_root_password

# Prompt for new username
prompt_username

# Prompt for new user password
prompt_user_password

# Prompt for hostname
prompt_hostname

# Prompt for timezone
prompt_timezone "nixos"

# Prompt for drive to partition
prompt_drive

# Autologin Prompt
prompt_for_autologin

# Partition the drive
partition_drive

# Determine correct partition suffix
partition_suffix

# Format the partitions
format_partitions

# Create BTRFS subvolumes
create_btrfs_subvolumes

# Mount the partitions
mount_partitions "nixos"

# Generate NixOS config
nixos-generate-config --root /mnt || die "Failed to generate NixOS config."

# Download custom NixOS config
CONF="https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles"
CONF="$CONF/refs/heads/main/home/theming/NixOS/configuration.nix"
curl -fsSL -o configuration.nix "$CONF" || \
	die "Failed to download custom configuration.nix"

# Set Config File Variable
CONFIG="/mnt/etc/nixos/configuration.nix"

# Backs up old configuration.nix
timestamp=$(date +%s)
cp "$CONFIG" "$CONFIG.old.${timestamp}" || \
	die "Failed to back up configuration.nix"

# Copies my configuration.nix
cp configuration.nix "$CONFIG" || die "Failed to copy configuration.nix"

# Only run if BIOS
if [ ! -d /sys/firmware/efi ]; then
	# Comment out efiSupport inside grub block
	sudo sed -i '/^\s*grub = {/,/^\s*};/ {
		s/^\(\s*\)efiSupport = /\1# efiSupport = /
	}' "$CONFIG" || die "Failed to comment out efiSupport in grub block."

	# Comment out efi.canTouchEfiVariables
	sudo sed -i 's/^\(\s*\)efi\.canTouchEfiVariables = /\1# efi.canTouchEfiVariables = /' \
		"$CONFIG" || die "Failed to comment out efi.canTouchEfiVariables."

	# Replace boot.loader.grub.device with the selected drive
	sed -i "s|^\(\s*device\s*=\s*\).*|\\1\"$drive\";|" "$CONFIG" || \
		die "Failed to set GRUB bootloader device."
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
sed -i "s/hostName = .*;/hostName = \"$hostname\";/g" "$CONFIG" || \
	die "Failed to update hostname in configuration.nix"

# Set Timezone
sed -i "s|^\(\s*time\.timeZone\s*=\s*\).*|\\1\"$timezone\";|" "$CONFIG"|| \
	die "Failed to set timezone."

# Add Nix Unstable and 23.05 Channels (for Neovim, icons and themes)
# nix-channel --add https://nixos.org/channels/nixos-unstable nixos || \
# die "Failed to add Nix unstable channel."
# nix-channel --add https://nixos.org/channels/nixos-23.05 nixos-23.05 || \
# die "Failed to add Nix 23.05 channel."
# nix-channel --update || die "Failed to update Nix channels."

# Install NixOS
nixos-install --no-root-passwd || die "Failed to install NixOS."

# Ensure variables are exported before chroot
export username rootpasswd userpasswd || \
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
WALL="https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles"
WALL="$WALL/refs/heads/main/home/wallpapers/Login_Wallpaper.jpg"
curl -fsSL -o Login_Wallpaper.jpg "$WALL" \
	|| die "Failed to download wallpaper."
cp -nr Login_Wallpaper.jpg /mnt/boot/ || \
	die "Failed to copy login wallpaper."

# Enable background in configuration.nix
sed -i 's|^\(\s*\)#\s*\(background\s*=.*\)|\1\2|' "$CONFIG"

# Clone cinnamon-dotfiles repo as new user
clone_dotfiles "nixos"
