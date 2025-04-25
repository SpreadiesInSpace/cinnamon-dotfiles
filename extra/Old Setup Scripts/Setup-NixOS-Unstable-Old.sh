#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run the script using sudo."
  exit
fi

# Check if the script is run from the root account
if [ "$SUDO_USER" = "" ]; then
  echo "Please do not run this script from the root account. Use sudo instead."
  exit
fi

# Get the current username
username=$SUDO_USER

# Autologin Prompt
read -rp "Enable autologin for $username? [y/N]: " autologin_input
case "$autologin_input" in
    [yY][eE][sS]|[yY])
        enable_autologin=true
        ;;
    *)
        enable_autologin=false
        ;;
esac

# Backs up old configuration.nix
cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.old

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

# Enable Flathub
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Add flag for Setup-Theme.sh
CURRENT_DIR=$(pwd)
su - "$SUDO_USER" -c "touch '$CURRENT_DIR/.nixos.done'"

# Reboot for the changes to take effect
echo "Installation complete! Please reboot for the changes to take effect. Then run Theme.sh in cinnamon-dotfiles for theming."
