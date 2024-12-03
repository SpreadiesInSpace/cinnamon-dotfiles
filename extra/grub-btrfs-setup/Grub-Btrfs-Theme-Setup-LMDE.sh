#!/bin/bash

# Clone grub-btrfs repo
git clone https://github.com/Antynea/grub-btrfs
cd grub-btrfs

# Install dependencies
sudo apt update
sudo apt install -y btrfs-progs bash gawk inotify-tools

# Install grub-btrfs
sudo make install

# Clean Up
cd ..
sudo rm -rf grub-btrfs

# Install Gruvbox GRUB theme
cd ../..
sudo mkdir -p /boot/grub/themes
sudo mv /boot/grub/themes/linuxmint /boot/grub/themes/linuxmint.original
sudo cp -vnpr boot/grub/themes/gruvbox-dark /boot/grub/themes/
sudo mv /boot/grub/themes/gruvbox-dark /boot/grub/themes/linuxmint

# Update /etc/default/grub to use the new theme
GRUB_THEME_LINE='GRUB_THEME="/boot/grub/themes/gruvbox-dark/theme.txt"'
sudo sed -i "/^GRUB_THEME=/s|^GRUB_THEME=.*|$GRUB_THEME_LINE|" /etc/default/grub
sudo grep -qxF "$GRUB_THEME_LINE" /etc/default/grub || echo -e "\n$GRUB_THEME_LINE" | sudo tee -a /etc/default/grub

# Update grub.cfg and enable grub-btrfs daemon
sudo grub-mkconfig -o /boot/grub/grub.cfg
sudo systemctl enable --now grub-btrfsd.service
