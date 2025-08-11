#!/bin/bash

# Minimal Error Handling function
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

# Check if script is run as root
if [ "$EUID" -eq 0 ]; then
	die "This script must NOT be run as root. Please run it as a regular user."
fi

# Disable Gnome Software Automatic Update Downloads
gsettings set org.gnome.software allow-updates false || \
	die "Failed to disable Gnome Software updates."
gsettings set org.gnome.software download-updates false || \
	die "Failed to disable Gnome Software auto-downloads."

# Set GRUB timeout to 0
sudo sed -i '/^#*GRUB_TIMEOUT=/s/^#*GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' \
	/etc/default/grub || die "Failed to update GRUB_TIMEOUT."
sudo grub2-mkconfig -o /boot/grub2/grub.cfg || \
	die "Failed to regenerate GRUB config."

# Remove Bloat
sudo dnf remove -y \
	baobab bulky celluloid drawing firefox gnome-calendar hexchat hp* hypnotix \
	mint-artwork mint-backgrounds* mintbackup mintstick mintupdate numix* \
	papirus-icon-theme pix pppoeconf redshift simple-scan thingy thunderbird \
	transmission-gtk warpinator webapp-manager xed xreader xviewer eom \
	google-noto-seriff* ibus* paper-icon-theme pidgin shotwell tecla \
	tracker-miners xawtv xfburn

