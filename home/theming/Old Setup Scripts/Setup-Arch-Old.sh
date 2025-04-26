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

# Check if Color, ParallelDownloads, and ILoveCandy are already in /etc/pacman.conf
declare -A options=(["Color"]="Color" ["ParallelDownloads"]="ParallelDownloads = 5" ["ILoveCandy"]="ILoveCandy")
for key in "${!options[@]}"; do
    if ! grep -q "^$key" /etc/pacman.conf; then
        sed -i "/^# Misc options/a ${options[$key]}" /etc/pacman.conf
    fi
done

# Update MAKEFLAGS /etc/makepkg.conf to match CPU cores
sed -i 's/^#*\s*MAKEFLAGS=.*/MAKEFLAGS="--jobs=$(nproc)"/' /etc/makepkg.conf

# Install base-devel and git
pacman -S --needed --noconfirm base-devel git

# Remove passwordless sudo if script is interrupted
trap 'rm -f /etc/sudoers.d/99_${SUDO_USER}_nopasswd' EXIT

# Temporarily allow passwordless sudo for current user
echo "$SUDO_USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/99_${SUDO_USER}_nopasswd
chmod 0440 /etc/sudoers.d/99_${SUDO_USER}_nopasswd

# Install yay
cat << 'EOF' | su - "$SUDO_USER"
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si --noconfirm
cd ..
rm -rf yay-bin

# All packages
packages=(
    # System utilities
    "bash-completion"
    "file-roller"
    "flatpak"
    "gparted"
    "grub-customizer"
    "ncdu"
    "neofetch"
    "timeshift"
    "unzip"
    "xorg-xkill"
    "xorg-xrandr"
    # Network utilities
    "filezilla"
    "gvfs"
    "gvfs-afc"
    "gvfs-gphoto2"
    "gvfs-mtp"
    "gvfs-nfs"
    "gvfs-smb"
    "kdeconnect"
    "samba"
    # Desktop environment and related packages
    "cinnamon"
    "eog"
    "evince"
    "ffmpegthumbnailer"
    "gedit"
    "gedit-plugins"
    "gnome-calculator"
    "gnome-disk-utility"
    "gnome-keyring"
    "gnome-screenshot"
    "gnome-system-monitor"
    "gnome-terminal"
    "gthumb"
    "gufw"
    "haruna"
    "kvantum"
    "kvantum-qt5"
    "lightdm"
    "lightdm-settings"
    "lightdm-slick-greeter"
    "nemo-fileroller"
    "nemo-image-converter"
    "nemo-preview"
    "nemo-share"
    "qt5ct"
    "qt6ct"
    "rhythmbox"
    # Applications
    "bauh"
    "bleachbit"
    "brave-bin"
    "bottom"
    "gpaste"
    "libreoffice-fresh"
    "neovim"
    "qbittorrent"
    "reflector-simple"
    "spice-vdagent"
    "noto-fonts"
    "noto-fonts-emoji"
    "xclip"
    # For NvChad
    "gcc"
    "make"
    "ripgrep"
    # Virtualization tools
    "virt-manager"
    "qemu-desktop"
    "libvirt"
    "edk2-ovmf"
    "dnsmasq"
    "vde2"
    "bridge-utils"
    "iptables"
    "dmidecode"
    "guestfs-tools"
    "qemu-block-gluster"
    "qemu-block-iscsi"
)

# Install Packages
yay -Syu --needed --noconfirm "${packages[@]}"
EOF

# Remove temporary passwordless sudo access
rm -f /etc/sudoers.d/99_${SUDO_USER}_nopasswd

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

# Enable and start services
systemctl enable libvirtd lightdm NetworkManager

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
    # Enable libvirtd service (for Virtual Machine Manager)
    systemctl restart libvirtd
fi

# Add user to necessary groups
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
a==1 && /^#?greeter-session=/ {
    print "greeter-session=lightdm-slick-greeter"
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
su - "$SUDO_USER" -c "touch '$CURRENT_DIR/.arch.done'"

# Reboot for the changes to take effect
echo "Installation complete! Please reboot for the changes to take effect. Then run Theme.sh in cinnamon-dotfiles for theming."
