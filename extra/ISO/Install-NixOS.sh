#!/bin/bash

# Download and source common functions
echo "Sourcing functions..."
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }
curl -fsSL -o Install-Common.sh https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles/main/extra/ISO/Install-Common.sh || die "Failed to download Install-Common.sh"
[ -f ./Install-Common.sh ] && source ./Install-Common.sh || die "Failed to source Install-Common.sh"

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
while true; do
    read -rp "Enable autologin for $username? [y/N]: " autologin_input
    if [[ "$autologin_input" =~ ^([yY][eE][sS]?|[yY])$ ]]; then
        enable_autologin=true
        break
    elif [[ "$autologin_input" =~ ^([nN][oO]?)$ ]]; then
        enable_autologin=false
        break
    else
        echo "Invalid input. Please answer y or n."
    fi
done

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
curl -fsSL -o configuration.nix https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles/refs/heads/main/home/theming/NixOS/configuration.nix || die "Failed to download custom configuration.nix" 

# Set Config File Variable
CONFIG="/mnt/etc/nixos/configuration.nix"

# Backs up old configuration.nix
timestamp=$(date +%s)
cp "$CONFIG" ""$CONFIG".old.${timestamp}" || die "Failed to back up configuration.nix"

# Copies my configuration.nix
cp configuration.nix "$CONFIG" || die "Failed to copy configuration.nix"

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
    sed -i '74s/^\( *enable *= *\)true;/\1false;/' "$CONFIG" || die "Failed to modify autologin setting."
fi

# Replace the placeholder with the actual username
sed -i "s/f16poom/$username/g" "$CONFIG" || die "Failed to replace username in configuration.nix"

# Prompt the user for hostname
sed -i "s/hostName = .*;/hostName = \"$hostname\";/g" "$CONFIG" || die "Failed to update hostname in configuration.nix"

# Set Timezone
sed -i "s|^\(\s*time\.timeZone\s*=\s*\).*|\\1\"$timezone\";|" "$CONFIG"|| die "Failed to set timezone."

# Comment out background line in configuration.nix
sed -i 's|^\(\s*background\s*=.*\)|# \1|' "$CONFIG"

# Add Nix Unstable and 23.05 Channels (for Neovim, icons and themes)
nix-channel --add https://nixos.org/channels/nixos-unstable nixos || die "Failed to add Nix unstable channel."
# nix-channel --add https://nixos.org/channels/nixos-23.05 nixos-23.05 || die "Failed to add Nix 23.05 channel."
nix-channel --update || die "Failed to update Nix channels."

# Install NixOS
nixos-install --no-root-passwd || die "Failed to install NixOS."

# Set Passwords
nixos-enter --root /mnt -c "echo 'root:$rootpasswd' | chpasswd" || die "Failed to set root password."
nixos-enter --root /mnt -c "echo '$username:$userpasswd' | chpasswd" || die "Failed to set user password."

# Enable Flathub remote for Flatpak
nixos-enter --root /mnt -c 'echo "Enabling Flathub..." && flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo' || die "Failed to enable Flathub remote."

# Place Login Wallpaper 
curl -fsSL -o Login_Wallpaper.jpg https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles/refs/heads/main/home/wallpapers/Login_Wallpaper.jpg || die "Failed to download wallpaper."
cp -nr Login_Wallpaper.jpg /mnt/boot/ || die "Failed to copy login wallpaper."

# Add back background line in configuration.nix & rebuild
sed -i 's|^\(\s*\)#\s*\(background\s*=.*\)|\1\2|' "$CONFIG"
nixos-enter --root /mnt -c "nixos-rebuild switch" || die "Rebuild Failed."

# Clone Repo as New User
nixos-enter --root /mnt -c "su - $username -c '
  cd \$HOME &&
  git clone https://github.com/SpreadiesInSpace/cinnamon-dotfiles ||
    { echo \"Failed to clone repo.\"; exit 1; }
  cd cinnamon-dotfiles ||
    { echo \"Failed to enter repo directory.\"; exit 1; }
  touch .nixos-unstable.done .nixos.done ||
    { echo \"Failed to create flags.\"; exit 1; }
  echo \"Reboot and run Setup.sh in cinnamon-dotfiles located in \$HOME/cinnamon-dotfiles.\"
'"
