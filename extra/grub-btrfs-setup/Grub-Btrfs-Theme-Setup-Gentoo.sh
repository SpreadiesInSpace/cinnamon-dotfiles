#!/bin/bash

# Enable Guru Repository
sudo emerge -vq app-eselect/eselect-repository 
sudo eselect repository enable guru 
sudo emaint sync -r guru

# USE Systemd
echo "app-backup/grub-btrfs systemd" | sudo tee /etc/portage/package.use/grub-btrfs

# Allow Unstable Package to be Merged
echo "app-backup/grub-btrfs ~amd64" | sudo tee /etc/portage/package.accept_keywords/grub-btrfs

# Install grub-btrfs
sudo emerge -vq app-backup/grub-btrfs

# Install Gruvbox GRUB theme
cd ../..
sudo mkdir -p /boot/grub/themes
sudo cp -vnpr boot/grub/themes/gruvbox-dark/ /boot/grub/themes/

# Update /etc/default/grub to use the new theme
GRUB_THEME_LINE='GRUB_THEME="/boot/grub/themes/gruvbox-dark/theme.txt"'
sudo sed -i "/^GRUB_THEME=/s|^GRUB_THEME=.*|$GRUB_THEME_LINE|" /etc/default/grub
sudo grep -qxF "$GRUB_THEME_LINE" /etc/default/grub || echo -e "\n$GRUB_THEME_LINE" | sudo tee -a /etc/default/grub

# Update grub.cfg and enable grub-btrfs daemon
sudo grub-mkconfig -o /boot/grub/grub.cfg
sudo systemctl enable --now grub-btrfsd.service
