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

# Update system and install git and curl
apt update && apt upgrade -y
apt install -y git curl

# Install Bottom
VERSION="0.10.2"
FILE_VERSION="0.10.2-1"
# Define the source URL using the version and file version variables
URL="https://github.com/ClementTsang/bottom/releases/download/${VERSION}/bottom_${FILE_VERSION}_amd64.deb"
# Download the specified version using curl
curl -LO "$URL"
# Install the downloaded package
dpkg -i bottom_${FILE_VERSION}_amd64.deb
# Remove the downloaded package file
rm bottom_${FILE_VERSION}_amd64.deb

# Install Brave Browser
curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"|tee /etc/apt/sources.list.d/brave-browser-release.list
apt update
apt install -y brave-browser

# Install Neovim AppImage
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
chmod u+x nvim-linux-x86_64.appimage
./nvim-linux-x86_64.appimage --appimage-extract
./squashfs-root/AppRun --version
rm -rf /squashfs-root/
mv squashfs-root /
rm -rf /usr/bin/nvim
ln -s /squashfs-root/AppRun /usr/bin/nvim
rm nvim-linux-x86_64.appimage

# All packages
packages=(
    # System utilities
    "build-essential"
    "file-roller"
    "flatpak"
    "gparted"
    "grub-customizer"
    "ncdu"
    "neofetch"
    "timeshift"
    "unzip"
    "x11-xserver-utils"
    # Network utilities
    "filezilla"
    "gvfs"
    "gvfs-backends"
    "kdeconnect"
    "samba"
    # Desktop environment and related packages
    "cinnamon"
    "dconf-cli"
    "lightdm"
    "lightdm-settings"
    "slick-greeter"
    "eog"
    "evince"
    "gedit"
    "gedit-plugins"
    "gnome-calculator"
    "gnome-disk-utility"
    "gnome-screenshot"
    "gnome-system-monitor"
    "gnome-terminal"
    "gthumb"
    "gufw"
    "haruna"
    "nemo"
    "nemo-fileroller"
    "qt5-style-kvantum"
    "qt5-style-kvantum-themes"
    "qt5ct"
    "qt6ct"
    "rhythmbox"
    # Applications
    "bleachbit"
    "gir1.2-gpaste-2"
    "gpaste-2"
    "libreoffice"
    "libreoffice-style-elementary"
    "qbittorrent"
    "spice-vdagent"
    "fonts-noto-core"
    "fonts-noto-color-emoji"
    "xclip"
    # For NvChad
    "gcc"
    "make"
    "ripgrep"
    # Virtualization tools
    "virt-manager"
    "qemu-system"
    "qemu-utils"
    "libvirt-clients"
    "libvirt-daemon-system"
    "libvirt-daemon"
    "bridge-utils"
    "virtinst"
    "iptables"
    "dmidecode"
    "guestfs-tools"
)

# Install Packages
apt install -y "${packages[@]}"

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
groups=(libvirt libvirt-qemu kvm input disk video audio)
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
su - "$SUDO_USER" -c "touch '$CURRENT_DIR/.lmde.done'"

# Reboot for the changes to take effect
echo "Installation complete! Please reboot for the changes to take effect. Then run Theme.sh in cinnamon-dotfiles for theming."
