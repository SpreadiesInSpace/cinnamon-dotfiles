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

# Install base-devel, git, and other dependencies
xbps-install -Syu git xtools

# Install xmirror utility
xbps-install -Sy xmirror

# Use xmirror to select the fastest mirrors
# xmirror -s https://repo-fastly.voidlinux.org/
xmirror -s https://mirror.vofr.net/voidlinux/

# Install multilib and nonfree repos
xbps-install -Sy void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree
xbps-install -Syu

# All packages (adapt package names as needed for Void Linux)
packages=(
    # Void Builds Cinnamon packages
    "dialog"
    "cryptsetup"
    "lvm2"
    "mdadm"
    "libxcrypt-compat"
    "xorg-minimal"
    "xorg-input-drivers"
    "xorg-video-drivers"
    #"intel-ucode"
    "setxkbmap"
    "xauth"
    "font-misc-misc"
    "alsa-plugins-pulseaudio"
    "gptfdisk"
    "gettext"
    "elogind"
    "dbus-elogind"
    "dbus-elogind-x11"
    "exfat-utils"
    "fuse-exfat"
    "wget"
    "xdg-utils"
    "xdg-desktop-portal"
    "xdg-desktop-portal-gtk"
    "xdg-desktop-portal-kde"
    "xdg-user-dirs"
    "xdg-user-dirs-gtk"
    "AppStream"
    "libvdpau-va-gl"
    "vdpauinfo"
    "pipewire"
    "wireplumber"
    "gstreamer1-pipewire"
    "upower"
    "dtrx"
    "unzip"
    "p7zip"
    "bash-completion"
    "colord"
    "alsa-utils"
    "pavucontrol"
    "udisks2"
    "ntfs-3g"
    "gnome-keyring"
    "network-manager-applet"
    "adwaita-icon-theme"
    "rsync"
    "psmisc"
    "dkms"
    # System utilities
    "file-roller"
    "flatpak"
    "gparted"
    "grub-customizer"
    "ncdu"
    "neofetch"
    "timeshift"
    "xkill"
    "xrandr"
    # Network utilities
    "filezilla"
    "gvfs"
    "gvfs-afc"
    "gvfs-gphoto2"
    "gvfs-mtp"
    "gvfs-smb"
    "kdeconnect"
    "kf6-sonnet"
    "samba"
    # Desktop environment and related packages
    "cinnamon"
    "celluloid"
    "eog"
    "evince"
    "ffmpegthumbnailer"
    "gedit"
    "gedit-plugins"
    "gnome-calculator"
    "gnome-disk-utility"
    "gnome-screenshot"
    "gnome-system-monitor"
    "gnome-terminal"
    "gthumb"
    "gufw"
    "kvantum"
    "lightdm"
    "lightdm-gtk-greeter-settings"
    "lightdm-gtk3-greeter"
    "nemo-fileroller"
    "nemo-image-converter"
    "nemo-preview"
    #"nemo-share"
    "qt5ct"
    "qt6ct"
    "rhythmbox"
    # Applications
    "bleachbit"
    "bottom"
    "GPaste"
    "libreoffice"
    "nano"
    "neovim"
    "octoxbps"
    "qbittorrent"
    "spice-vdagent"
    "noto-fonts-ttf"
    "noto-fonts-emoji"
    "xclip"
    # For NvChad
    "gcc"
    "make"
    "ripgrep"
    # Virtualization tools
    "virt-manager"
    "qemu"
    "libvirt"
    "edk2-ovmf"
    "dnsmasq"
    "vde2"
    "bridge-utils"
    "iptables"
    "dmidecode"
    "libguestfs"
)

# Install Packages
xbps-install -Sy "${packages[@]}"

# Protect neofetch from being removed
xbps-pkgdb -m hold neofetch

# Install Brave
cd home/theming/Void
chmod +x update_brave.sh
./update_brave.sh
cd ..

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
for service in dbus lightdm NetworkManager polkitd spice-vdagentd libvirtd virtlockd virtlogd; do
  ln -sf /etc/sv/$service /etc/runit/runsvdir/default
done

# Let services start
sleep 5

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
    sv restart libvirtd
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

# Add flag for Setup-Theme.sh
CURRENT_DIR=$(pwd)
su - "$SUDO_USER" -c "touch '$CURRENT_DIR/.void.done'"

# Reboot for the changes to take effect
echo "Installation complete! Please reboot for the changes to take effect. Then run Theme.sh in cinnamon-dotfiles for theming."
