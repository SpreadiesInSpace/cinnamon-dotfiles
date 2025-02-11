#!/bin/bash

# Get the current username
username=$(whoami)

# Backs up old configuration.nix
sudo cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.old

# Appends configuration.nix with needed options
sudo cp ./home/theming/NixOS/configuration.nix /etc/nixos/configuration.nix

# Replace the placeholder with the actual username
sudo sed -i "s/f16poom/$username/g" /etc/nixos/configuration.nix

# Places Login Wallpaper
sudo cp -vnr home/wallpapers/Login_Wallpaper.jpg /boot/

# Add Nix Unstable and 23.05 Channels (for Neovim, icons and themes)
# sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos-unstable
# sudo nix-channel --add https://nixos.org/channels/nixos-23.05 nixos-23.05
# sudo nix-channel --update

# Add Nix Unstable and 23.05 Channels (for Neovim, icons and themes)
sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos
sudo nix-channel --add https://nixos.org/channels/nixos-23.05 nixos-23.05
sudo nix-channel --upgrade

# Reconfigures system
# sudo nixos-rebuild switch

# Enable Flathub
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Run the setup script
cd home/
chmod +x Setup-NixOS-Theme.sh
sh Setup-NixOS-Theme.sh
cd ..

# Logout and log back in for the changes to take effect
echo "Installation complete! Please log out and log back in for the changes to take effect."

