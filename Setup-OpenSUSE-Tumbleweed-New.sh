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

# Copies example lightdm.conf
cp /usr/share/doc/packages/lightdm/lightdm.conf.example /etc/lightdm/lightdm.conf

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
add_setup_theme_flag "opensuse"

# Display Reboot Message
print_reboot_message
