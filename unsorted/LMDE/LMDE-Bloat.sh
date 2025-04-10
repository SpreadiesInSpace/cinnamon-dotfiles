#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -eq 0 ]; then
  echo "This script must NOT be run as root. Please execute it as a regular user."
  exit
fi

# Set GRUB timeout to 0
sed -i '/^#*GRUB_TIMEOUT=/s/^#*GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Remove Bloat
apt remove -y baobab bulky celluloid drawing firefox gnome-calendar hexchat hypnotix mint-artwork mint-backgrounds* mintbackup mintstick numix* papirus-icon-theme pix pppoeconf redshift simple-scan thingy thunderbird transmission-gtk warpinator webapp-manager xed xreader xviewer mint-L* mint-x* mint-y*

rm -rf /usr/share/icons/Bibata-* /usr/share/icons/GoogleDot-* /usr/share/icons/XCursor-Pro-* /usr/share/icons/DMZ-* /usr/share/icons/ubuntu-mono-*
