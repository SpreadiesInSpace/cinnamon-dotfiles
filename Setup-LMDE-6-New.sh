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

# Enable Flathub for Flatpak
enable_flathub

# Preserve old configurations (for Virtual Machine Manager)
preserve_old_libvirt_configs

# Set proper permissions in libvirtd.conf
set_libvirtd_permissions

# Set proper permissions in qemu.conf
set_qemu_permissions

# Enable libvirtd service (for Virtual Machine Manager)
systemctl enable --now libvirtd

# Only enable net-autostart if in physical machine
manage_virsh_network

# Add user to necessary groups
add_user_to_groups libvirt libvirt-qemu kvm input disk video audio

# Backup original LightDM config
backup_lightdm_config

# Modify lightdm.conf in-place
modify_lightdm_conf

# Ensure autologin group exists and add user
ensure_autologin_group

# If running in a VM, set display-setup-script in lightdm.conf
set_lightdm_display_for_vm

# Set timeout for stopping services during shutdown via drop in file
set_systemd_timeout_stop

# Reload the systemd configuration
reload_systemd_daemon

# Add flag for Setup-Theme.sh
add_setup_theme_flag "lmde"

# Display Reboot Message
print_reboot_message
