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

# Enable Parallel Downloads
if ! grep -q "^max_parallel_downloads=10$" /etc/dnf/dnf.conf; then
    echo 'max_parallel_downloads=10' | tee -a /etc/dnf/dnf.conf
else
    sed -i '/^#*max_parallel_downloads=10/s/^#*//' /etc/dnf/dnf.conf
fi

# Update system and install git
dnf -y update
dnf -y install git

# Add RPM Fusion
dnf -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Install Media Codecs
dnf4 -y group upgrade multimedia
dnf -y swap 'ffmpeg-free' 'ffmpeg' --allowerasing
dnf -y upgrade @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
dnf group install -y sound-and-video

# Install Brave
dnf -y install dnf-plugins-core
dnf config-manager addrepo --id=brave-browser --set=name='Brave Browser' --set=baseurl='https://brave-browser-rpm-release.s3.brave.com/$basearch'
rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
dnf -y install brave-browser

# Install Bottom
dnf -y copr enable atim/bottom
dnf -y install bottom

# Install Neofetch
dnf -y install https://dl.fedoraproject.org/pub/fedora/linux/releases/40/Everything/x86_64/os/Packages/n/neofetch-7.1.0-12.fc40.noarch.rpm

# All packages
packages=(
    # System utilities
    "file-roller"
    "flatpak"
    "gparted"
    #"grub-customizer"
    "ncdu"
    #"neofetch"
    "timeshift"
    "unzip"
    "xkill"
    "xrandr"
    # Network utilities
    "filezilla"
    "gvfs"
    "gvfs-afc"
    "gvfs-gphoto2"
    "gvfs-mtp"
    "gvfs-nfs"
    "gvfs-smb"
    "kde-connect"
    "kf6-qqc2-desktop-style"
    "samba"
    # Desktop environment and related packages
    "cinnamon"
    # "dnfdragora"
    "eog"
    "evince"
    "ffmpegthumbnailer"
    "gedit"
    "gedit-plugins"
    "gnome-calculator"
    "gnome-disk-utility"
    "gnome-screenshot"
    "gnome-software"
    "gnome-system-monitor"
    "gnome-terminal"
    "gthumb"
    "haruna"
    "ufw"
    "kvantum"
    "kvantum-qt6"
    "lightdm"
    "lightdm-settings"
    "slick-greeter"
    "nemo"
    "nemo-extensions"
    "qt5ct"
    "qt6ct"
    "rhythmbox"
    # Applications
    "bleachbit"
    "gpaste"
    "libreoffice"
    "neovim"
    "qbittorrent"
    "spice-vdagent"
    "google-noto-fonts-common"
    "google-noto-emoji-fonts"
    # For NvChad
    "gcc"
    "make"
    "ripgrep"
    # Virtualization tools
    "guestfs-tools"
    "@virtualization"
)

# Install Packages
dnf -y install "${packages[@]}"

# Disable Problem Reporting
systemctl disable abrtd.service

# Uninstall SystemD Core Dump Generator (tracker-miners)
dnf remove -y tracker-miners

# Replace FirewallD with UFW and allow KDE Connect through
dnf -y remove firewalld
systemctl daemon-reload
ufw enable
ufw allow "KDE Connect"

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
su - "$SUDO_USER" -c "touch '$CURRENT_DIR/.fedora.done'"

# Reboot for the changes to take effect
echo "Installation complete! Please reboot for the changes to take effect. Then run Theme.sh in cinnamon-dotfiles for theming."
