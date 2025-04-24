#!/bin/bash

# Source common functions
source ./Setup-Common.sh

# Check if the script is run as root
check_if_root

# Check if the script is run from the root account
check_if_not_root_account

# Get the current username
get_current_username

# Autologin Prompt
prompt_for_autologin

# VM Prompt
prompt_for_vm

# Display Status from Prompts
display_status "$enable_autologin" "$is_vm"

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

# Enable Flathub for Flatpak
enable_flathub

# Preserve old configurations (for Virtual Machine Manager)
preserve_old_libvirt_configs

# Set proper permissions in libvirtd.conf
set_libvirtd_permissions

# Set proper permissions in qemu.conf
set_qemu_permissions

# Enable and start services
systemctl enable libvirtd
systemctl enable lightdm
systemctl enable NetworkManager

# Only enable net-autostart if in physical machine
manage_virsh_network # has void/slackware cases

# Add user to necessary groups
add_user_to_groups libvirt libvirt-qemu kvm input disk video audio

# Backup original LightDM config
backup_lightdm_config

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
ensure_autologin_group

# If running in a VM, set display-setup-script in lightdm.conf
set_lightdm_display_for_vm

# Set timeout for stopping services during shutdown via drop in file
set_systemd_timeout_stop

# Reload the systemd configuration
reload_systemd_daemon

# Add flag for Setup-Theme.sh
add_setup_theme_flag "arch"

# Reboot for the changes to take effect
echo "Installation complete! Please reboot for the changes to take effect. Then run Theme.sh in cinnamon-dotfiles for theming."
