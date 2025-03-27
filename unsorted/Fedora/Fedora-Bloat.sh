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

# Set GRUB timeout to 0
sed -i '/^#*GRUB_TIMEOUT=/s/^#*GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

# Remove Bloat
dnf remove -y baobab bulky celluloid drawing firefox gnome-calendar hexchat hypnotix mint-artwork mint-backgrounds* mintbackup mintstick mintupdate numix* papirus-icon-theme pix pppoeconf redshift simple-scan thingy thunderbird transmission-gtk warpinator webapp-manager xed xreader xviewer eom google-noto-seriff* ibus paper-icon-theme pidgin shotwell tracker-miners xawtv xfburn
