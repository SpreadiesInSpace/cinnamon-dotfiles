#!/bin/bash

# Minimal Error Handling function
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  die "Please run the script as superuser."
fi

# Set GRUB timeout to 0
if [[ ! -f ".lmde-7.done" ]]; then
  sed -i '/^#*GRUB_TIMEOUT=/s/^#*GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' \
    /etc/default/grub || die "Failed to update GRUB timeout."
  grub-mkconfig -o /boot/grub/grub.cfg || \
    die "Failed to regenerate GRUB config."
fi

# Remove Bloat
apt remove -y \
  baobab bulky celluloid drawing firefox gnome-calendar hexchat hypnotix \
  ibus* mint-artwork mint-backgrounds* mint-cursor-themes mint-L* mint-x* \
  mint-y* mintbackup mintstick mintwelcome numix* papirus-icon-theme pix \
  pppoeconf redshift simple-scan thingy thunderbird transmission-gtk \
  warpinator webapp-manager xed xreader xviewer yelp

# Remove specific icon themes
rm -rf \
  /usr/share/icons/Bibata-* \
  /usr/share/icons/GoogleDot-* \
  /usr/share/icons/XCursor-Pro-* \
  /usr/share/icons/DMZ-* \
  /usr/share/icons/ubuntu-mono-* || die "Failed to remove icon themes."
