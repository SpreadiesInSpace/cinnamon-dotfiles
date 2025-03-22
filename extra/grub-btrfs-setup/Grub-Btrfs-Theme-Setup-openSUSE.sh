#!/bin/bash

# Clone grub-btrfs repo
git clone https://github.com/Antynea/grub-btrfs
cd grub-btrfs

# Apply Fixes for openSUSE
sed -i '/#GRUB_BTRFS_GRUB_DIRNAME/a GRUB_BTRFS_GRUB_DIRNAME="/boot/grub2"' config
sed -i '/#GRUB_BTRFS_MKCONFIG=/a GRUB_BTRFS_MKCONFIG=/sbin/grub2-mkconfig' config
sed -i '/#GRUB_BTRFS_SCRIPT_CHECK=/a GRUB_BTRFS_SCRIPT_CHECK=grub2-script-check' config
sed -i '/#GRUB_BTRFS_MKCONFIG_LIB=/a GRUB_BTRFS_MKCONFIG_LIB=/usr/share/grub2/grub-mkconfig_lib' config

# Install dependencies
sudo zypper install -y btrfs-progs bash gawk inotify-tools

# Install grub-btrfs
sudo make install

# Clean Up
cd ..
sudo rm -rf grub-btrfs

# Install Gruvbox GRUB theme
cd ../..
sudo mkdir -p /boot/grub2/themes
sudo cp -vnpr boot/grub/themes/gruvbox-dark/ /boot/grub2/themes/

# Update /etc/default/grub to use the new theme
GRUB_THEME_LINE='GRUB_THEME="/boot/grub2/themes/gruvbox-dark/theme.txt"'
sudo sed -i "/^GRUB_THEME=/s|^GRUB_THEME=.*|$GRUB_THEME_LINE|" /etc/default/grub
sudo grep -qxF "$GRUB_THEME_LINE" /etc/default/grub || echo -e "\n$GRUB_THEME_LINE" | sudo tee -a /etc/default/grub

# Check and comment out GRUB_TERMINAL_OUTPUT="console" if it exists
sudo sed -i 's/^GRUB_TERMINAL_OUTPUT="console"/#&/' /etc/default/grub

# Update grub.cfg and enable grub-btrfs daemon
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
sudo systemctl enable --now grub-btrfsd.service
