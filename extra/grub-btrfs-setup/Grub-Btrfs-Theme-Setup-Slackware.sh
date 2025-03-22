#!/bin/bash

# Clone grub-btrfs repo
git clone https://github.com/Antynea/grub-btrfs
cd grub-btrfs

# Install dependencies (Slackware Current has them all installed by default)
# sudo slpkg -iy btrfs-progs grub bash gawk inotify-tools

# Install grub-btrfs
sudo make install

# Clean Up
cd ..
sudo rm -rf grub-btrfs

# Install Gruvbox GRUB theme
cd ../..
sudo mkdir -p /boot/grub/themes
sudo cp -vnpr boot/grub/themes/gruvbox-dark/ /boot/grub/themes/

# Update /etc/default/grub to use the new theme
GRUB_THEME_LINE='GRUB_THEME="/boot/grub/themes/gruvbox-dark/theme.txt"'
sudo sed -i "/^GRUB_THEME=/s|^GRUB_THEME=.*|$GRUB_THEME_LINE|" /etc/default/grub
sudo grep -qxF "$GRUB_THEME_LINE" /etc/default/grub || echo -e "\n$GRUB_THEME_LINE" | sudo tee -a /etc/default/grub

# Uncomment GRUB_FONT line
sudo sed -i 's/^#GRUB_FONT=/GRUB_FONT=/' /etc/default/grub

# Update grub.cfg
sudo grub-mkconfig -o /boot/grub/grub.cfg
