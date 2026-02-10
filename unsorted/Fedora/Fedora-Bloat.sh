#!/bin/bash

# Minimal Error Handling function
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  die "Please run the script as superuser."
fi

# Run if not installed via cinnamon-ISO
if [[ ! -f ".fedora-43.done" ]]; then
  # Set GRUB timeout to 0
  sed -i '/^#*GRUB_TIMEOUT=/s/^#*GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' \
    /etc/default/grub || die "Failed to update GRUB_TIMEOUT."
  grub2-mkconfig -o /boot/grub2/grub.cfg || \
    die "Failed to regenerate GRUB config."
  # Disable Gnome Software Automatic Updates
  sudo -u "$SUDO_USER" \
    env XDG_RUNTIME_DIR="/run/user/$(id -u "$SUDO_USER")" \
    gsettings set org.gnome.software allow-updates false || \
    die "Failed to disable Gnome Software updates."
  sudo -u "$SUDO_USER" \
    env XDG_RUNTIME_DIR="/run/user/$(id -u "$SUDO_USER")" \
    gsettings set org.gnome.software download-updates false || \
    die "Failed to disable Gnome Software auto-downloads."
fi

# Disable Problem Reporting
systemctl disable --now abrtd.service >/dev/null 2>&1 || true

# Remove Bloat
dnf remove -y \
  baobab bulky celluloid drawing eom exaile firefox \
  gnome-calendar google-noto-seriff* hexchat hp* hypnotix \
  ibus* mediawriter mint-artwork mint-backgrounds* \
  mintbackup mintstick mintupdate numix* paper-icon-theme \
  papirus-icon-theme pidgin pix pppoeconf redshift \
  shotwell simple-scan tecla thingy thunderbird tracker-miners \
  transmission-gtk warpinator webapp-manager xawtv xed \
  xfburn xreader xviewer

# Replace FirewallD with UFW and allow KDE Connect through
dnf --setopt=max_parallel_downloads=10 install -y gnome-software \
  kde-connect ufw || die "Failed to install ufw."
systemctl daemon-reload || die "Failed to reload systemd daemon."
# ufw enable || die "Failed to enable UFW."
# ufw allow "KDE Connect" || die "Failed to allow KDE Connect in UFW."
dnf remove -y firewalld

# Remove PackageKit cache
rm -rf /var/cache/PackageKit || \
  die "Failed to remove PackageKit cache."

# Redownload metadata cache without auto updates (for gnome-software)
echo "Refreshing Metadata Cache..."
pkcon refresh force -c -1 >/dev/null 2>&1 || \
  die "Failed to refresh metadata cache."
