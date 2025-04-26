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

# Enable Parallel Downloads
if ! grep -q "^max_parallel_downloads=10$" /etc/dnf/dnf.conf; then
    echo 'max_parallel_downloads=10' | tee -a /etc/dnf/dnf.conf
else
    sed -i '/^#*max_parallel_downloads=10/s/^#*//' /etc/dnf/dnf.conf
fi

# Remove PackageKit cache
rm -rf /var/cache/PackageKit

# Redownload metadata cache without auto updates
pkcon refresh force -c -1

# Disable Gnome Software Automatic Update Downloads
su - "$SUDO_USER" -c "dconf write /org/gnome/software/allow-updates false"
su - "$SUDO_USER" -c "dconf write /org/gnome/software/download-updates false"

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
add_user_to_groups libvirt kvm input disk video audio

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
add_setup_theme_flag "fedora"

# Display Reboot Message
print_reboot_message
