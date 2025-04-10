#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -eq 0 ]; then
  echo "This script must NOT be run as root. Please execute it as a regular user."
  exit
fi

# Set GRUB timeout to 0
sed -i '/^#*GRUB_TIMEOUT=/s/^#*GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

# Remove Bloat
dnf remove -y baobab bulky celluloid drawing firefox gnome-calendar hexchat hypnotix mint-artwork mint-backgrounds* mintbackup mintstick mintupdate numix* papirus-icon-theme pix pppoeconf redshift simple-scan thingy thunderbird transmission-gtk warpinator webapp-manager xed xreader xviewer eom google-noto-seriff* ibus paper-icon-theme pidgin shotwell tracker-miners xawtv xfburn
