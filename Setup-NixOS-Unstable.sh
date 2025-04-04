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

# Backs up old configuration.nix
cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.old

# Appends configuration.nix with needed options
cp ./home/theming/NixOS/configuration.nix /etc/nixos/configuration.nix

# Replace the placeholder with the actual username
sed -i "s/f16poom/$username/g" /etc/nixos/configuration.nix

# Prompt the user for hostname
read -p "Enter the hostname for your system: " hostname
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

# Run the setup script
# cd home/
# chmod +x Setup-NixOS-Theme.sh
# sh Setup-NixOS-Theme.sh
# cd ..

# Reboot for the changes to take effect
echo "Installation complete! Please reboot for the changes to take effect. Then run Setup-NixOS-Theme.sh in cinnamon/home for theming."
