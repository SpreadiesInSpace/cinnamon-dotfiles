#!/bin/bash

# Minimal Error Handling function
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
	die "Please run the script as superuser."
fi

# Set GRUB timeout to 0
sed -i '/^#*GRUB_TIMEOUT=/s/^#*GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' \
	/etc/default/grub || die "Failed to update GRUB_TIMEOUT."
grub2-mkconfig -o /boot/grub2/grub.cfg || \
	die "Failed to regenerate GRUB config."

# Disable Problem Reporting
systemctl disable --now abrtd.service >/dev/null 2>&1 || true

# Remove Bloat
dnf remove -y \
	baobab bulky celluloid drawing firefox gnome-calendar hexchat hp* \
	hypnotix mint-artwork mint-backgrounds* mintbackup mintstick mintupdate \
	numix* papirus-icon-theme pix pppoeconf redshift simple-scan thingy \
	thunderbird transmission-gtk warpinator webapp-manager xed xreader xviewer \
	eom google-noto-seriff* ibus* paper-icon-theme pidgin shotwell tecla \
	tracker-miners xawtv xfburn

# Replace FirewallD with UFW and allow KDE Connect through
dnf --setopt=max_parallel_downloads=10 install -y gnome-software \
	kde-connect ufw || die "Failed to install ufw."
systemctl daemon-reload || die "Failed to reload systemd daemon."
ufw enable || die "Failed to enable UFW."
ufw allow "KDE Connect" || die "Failed to allow KDE Connect in UFW."
dnf remove -y firewalld

# Remove PackageKit cache
rm -rf /var/cache/PackageKit || \
	die "Failed to remove PackageKit cache."

# Redownload metadata cache without auto updates (for gnome-software)
echo "Refreshing Metadata Cache..."
pkcon refresh force -c -1 >/dev/null 2>&1 || \
	die "Failed to refresh metadata cache."
