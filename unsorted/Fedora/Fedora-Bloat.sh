#!/bin/bash

# Check if script is run as root
if [ "$EUID" -eq 0 ]; then
  echo "This script must NOT be run as root. Please run it as a regular user."
  exit
fi

# Disable Gnome Software Automatic Update Downloads
gsettings set org.gnome.software allow-updates false
gsettings set org.gnome.software download-updates false

# Set GRUB timeout to 0
sudo sed -i '/^#*GRUB_TIMEOUT=/s/^#*GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

# Remove Bloat
sudo dnf remove -y baobab bulky celluloid drawing firefox gnome-calendar hexchat hp* hypnotix mint-artwork mint-backgrounds* mintbackup mintstick mintupdate numix* papirus-icon-theme pix pppoeconf redshift simple-scan thingy thunderbird transmission-gtk warpinator webapp-manager xed xreader xviewer eom google-noto-seriff* ibus* paper-icon-theme pidgin shotwell tecla tracker-miners xawtv xfburn
