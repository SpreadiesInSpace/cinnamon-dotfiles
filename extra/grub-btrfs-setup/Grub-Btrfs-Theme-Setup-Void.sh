#!/bin/bash

# Install grub-btrfs
sudo xbps-install -Syu btrfs-progs grub bash gawk inotify-tools grub-btrfs

# Install Gruvbox GRUB theme
cd ../..
sudo mkdir -p /boot/grub/themes
sudo cp -vnpr boot/grub/themes/gruvbox-dark/ /boot/grub/themes/

# Update /etc/default/grub to use the new theme
GRUB_THEME_LINE='GRUB_THEME="/boot/grub/themes/gruvbox-dark/theme.txt"'
sudo sed -i "/^GRUB_THEME=/s|^GRUB_THEME=.*|$GRUB_THEME_LINE|" /etc/default/grub
sudo grep -qxF "$GRUB_THEME_LINE" /etc/default/grub || echo -e "\n$GRUB_THEME_LINE" | sudo tee -a /etc/default/grub

# Update grub.cfg
sudo grub-mkconfig -o /boot/grub/grub.cfg
# sudo ln -s /etc/sv/grub-btrfsd /var/service
