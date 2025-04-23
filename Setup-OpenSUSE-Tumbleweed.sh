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

# Get the current username
username=$SUDO_USER

# Autologin Prompt
read -rp "Enable autologin for $username? [y/N]: " autologin_input
case "$autologin_input" in
    [yY][eE][sS]|[yY])
        enable_autologin=true
        ;;
    *)
        enable_autologin=false
        ;;
esac

# VM Prompt
read -rp "Is this a Virtual Machine? [y/N]: " response
case "$response" in
    [yY][eE][sS]|[yY])
        is_vm=true
        ;;
    *)
        is_vm=false
        ;;
esac

# Enable Parallel Downloads during Setup
# export ZYPP_CURL2=1
export ZYPP_PCK_PRELOAD=1

# Enable Parallel Downloads and Faster Repo Syncing Persistantly 
if ! grep -q "^ZYPP_CURL2=1" /etc/environment; then
    echo 'ZYPP_CURL2=1' | tee -a /etc/environment
fi
if ! grep -q "^ZYPP_PCK_PRELOAD=1" /etc/environment; then
    echo 'ZYPP_PCK_PRELOAD=1' | tee -a /etc/environment
fi

# Fix openSUSE's line break paste
echo "set enable-bracketed-paste" >> /home/$username/.inputrc
echo "set enable-bracketed-paste" >> /root/.inputrc

# Update system and install packages
zypper ref
zypper dup -y

# Install git
zypper in -y git

# Install Media Codecs
zypper ar -cfp 90 --no-gpgcheck 'https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/Essentials/' packman-essentials
zypper ref
zypper dup --from packman-essentials -y --allow-vendor-change
zypper in --from packman-essentials -y ffmpeg gstreamer-plugins-{good,bad,ugly,libav} libavcodec

# Install Brave
zypper in -y curl
rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
zypper ar https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
zypper in -y brave-browser

# For Cinnamon and Opi
zypper rm -y busybox-which busybox-diffutils

# All packages
packages=(
    # System utilities
    "file-roller"
    "flatpak"
    "gparted"
    "ncdu"
    # "neofetch"
    "timeshift"
    "unzip"
    "xkill"
    "xrandr"
    # Network utilities
    "filezilla"
    "gvfs"
    "gvfs-backends"
    "kdeconnect-kde"
    "samba"
    # Desktop environment and related packages
    "cinnamon"
    "dconf"
    "gsettings-backend-dconf"
    "eog"
    "evince"
    "ffmpegthumbnailer"
    "gedit"
    "gedit-plugins"
    "gedit-plugin-*"
    "gnome-calculator"
    "gnome-disk-utility"
    "gnome-screenshot"
    "gnome-system-monitor"
    "gnome-terminal"
    "gthumb"
    "haruna"
    "kvantum-manager"
    "kvantum-qt5"
    "kvantum-qt6"
    "lightdm"
    "lightdm-gtk-greeter"
    "lightdm-gtk-greeter-settings"
    "nemo"
    "nemo-extension-fileroller"
    "nemo-extension-image-converter"
    "nemo-extension-preview"
    "nemo-extension-share"
    "qt5ct"
    "qt6ct"
    "rhythmbox"
    # Applications
    "bleachbit"
    "bottom"
    "gpaste"
    "typelib-1_0-GPaste-2"
    "libreoffice"
    "libreoffice-gtk3"
    "neovim"
    "opi"
    "qbittorrent"
    "spice-vdagent"
    "google-noto-coloremoji-fonts"
    "google-noto-sans-fonts"
    "xclip"
    # For NvChad
    "gcc"
    "make"
    "ripgrep"
    # Virtualization tools
    "yast2-vm"
    "libvirt"
)

# Install packages headlessly if installed via openSUSE-Install.sh
if [[ -f .opensuse-tumbleweed.done ]]; then
    zypper in -y "${packages[@]}"
else
    zypper in "${packages[@]}"
fi

# Remove devhelp
zypper rm -y devhelp*
zypper al devhelp*

# Install neofetch
zypper ar --no-gpgcheck https://download.opensuse.org/repositories/utilities/openSUSE_Factory/utilities.repo
zypper ref
zypper in -y neofetch

# Protect neofetch from being replaced by neowofetch
zypper al neofetch

# Install Additional Tools for Virt Manager
zypper in -y -t pattern kvm_server kvm_tools

# Enable Flathub
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Preserve old configurations (for Virtual Machine Manager)
cp /etc/libvirt/libvirtd.conf /etc/libvirt/libvirtd.conf.old
cp /etc/libvirt/qemu.conf /etc/libvirt/qemu.conf.old

# Set proper permissions in libvirtd.conf
for line in \
  'unix_sock_group = "libvirt"' \
  'unix_sock_ro_perms = "0777"' \
  'unix_sock_rw_perms = "0770"'; do
  key=${line%% *}
  # Only add the line if it's completely missing (including commented-out lines)
  if ! grep -q -E "^$key\s*=" /etc/libvirt/libvirtd.conf; then
    # Append the line if it doesn't exist in any form
    echo "$line" | tee -a /etc/libvirt/libvirtd.conf > /dev/null
  fi
done

# Set proper permissions in qemu.conf
for key in user group swtpm_user swtpm_group; do
  if ! grep -q "^$key = \"$username\"$" /etc/libvirt/qemu.conf; then
    echo "$key = \"$username\"" | tee -a /etc/libvirt/qemu.conf > /dev/null
  fi
done

# Enable libvirtd service (for Virtual Machine Manager)
systemctl enable --now libvirtd

# Only enable net-autostart if in physical machine
if [ "$is_vm" = false ]; then
    virsh net-autostart default
    virsh net-start default
else
    # Disable autostart and destroy the network if running
    virsh net-autostart default --disable
    rm -f /etc/libvirt/qemu/networks/autostart/default.xml
    if virsh net-info default | grep -q "Active:.*yes"; then
        virsh net-destroy default
    fi
    # Restart libvirtd to ensure clean state
    systemctl restart libvirtd
fi

# Add the current user to the necessary groups
groups=(libvirt kvm input disk video audio)
for group in "${groups[@]}"; do
    usermod -aG "$group" "$username"
done

# Backup original LightDM config
cp /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.old

# Copies example lightdm.conf
cp /usr/share/doc/packages/lightdm/lightdm.conf.example /etc/lightdm/lightdm.conf

# Modify lightdm.conf in-place
awk -v user="$username" -v autologin="$enable_autologin" -i inplace '
/^\[Seat:\*\]/ {a=1}
a==1 && /^#?greeter-hide-users=/ {
    print "greeter-hide-users=false"
    next
}
a==1 && /^#?autologin-user=/ {
    if (autologin == "true") {
        print "autologin-user=" user
    } else {
        print "#autologin-user=" user
    }
    next
}
a==1 && /^#?autologin-session=/ {
    print "autologin-session=cinnamon"
    next
}
{print}
' /etc/lightdm/lightdm.conf

# Ensure autologin group exists and add user
groupadd -f autologin
gpasswd -a "$username" autologin

# If running in a VM, set display-setup-script in lightdm.conf
if [ "$is_vm" = true ]; then
    # Detect connected output using sysfs (avoids X dependency)
    output_path=$(grep -l connected /sys/class/drm/*/status | head -n1)
    output=$(basename "$(dirname "$output_path")")
    output="${output#*-}"  # Strip 'cardX-' prefix
    if [[ -n "$output" ]]; then
        sed -i "/^\[Seat:\*\]/,/^\[.*\]/ {
            s|^#*display-setup-script=.*|display-setup-script=xrandr --output $output --mode 1920x1080 --rate 60|
        }" /etc/lightdm/lightdm.conf
    fi
fi

# Set timeout for stopping services during shutdown via drop in file
mkdir -p /etc/systemd/system.conf.d
echo "[Manager]" | tee /etc/systemd/system.conf.d/override.conf
echo "DefaultTimeoutStopSec=15s" | tee -a /etc/systemd/system.conf.d/override.conf

# Reload the systemd configuration
systemctl daemon-reload

# Add flag for Setup-Theme.sh
CURRENT_DIR=$(pwd)
su - "$SUDO_USER" -c "touch '$CURRENT_DIR/.opensuse.done'"

# Reboot for the changes to take effect
echo "Installation complete! Please reboot for the changes to take effect. Then run Theme.sh in cinnamon-dotfiles for theming."
