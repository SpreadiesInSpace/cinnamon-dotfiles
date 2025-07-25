#!/bin/bash

# Source common functions
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }
[ -f ./Setup-Common.sh ] && source ./Setup-Common.sh || die "Setup-Common.sh not found."

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
export ZYPP_PCK_PRELOAD=1 || die "Failed to enable parallel downloads."

# Enable Parallel Downloads Persistently 
if ! grep -q "^ZYPP_PCK_PRELOAD=1" /etc/environment; then
    echo 'ZYPP_PCK_PRELOAD=1' | tee -a /etc/environment || die "Failed to enable faster repo syncing."
fi

# Fix openSUSE's line break paste
echo "set enable-bracketed-paste" >> /home/$username/.inputrc || die "Failed to update .inputrc for $username."
echo "set enable-bracketed-paste" >> /root/.inputrc || die "Failed to update /root/.inputrc"

# Update system and install packages
zypper ref || die "Failed to refresh repositories."
zypper dup -y || die "Failed to perform system update."

# Install git
zypper in -y git || die "Failed to install git."

# Install Media Codecs
zypper ar -cfp 90 --no-gpgcheck 'https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/Essentials/' packman-essentials || die "Failed to add Packman repository."
zypper ref || die "Failed to refresh repositories"
zypper dup --from packman-essentials -y --allow-vendor-change || die "Failed to update from Packman repository."
zypper in --from packman-essentials -y ffmpeg gstreamer-plugins-{good,bad,ugly,libav} libavcodec || die "Failed to install media codecs."

# Install Brave
zypper in -y curl || die "Failed to install curl"
rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc || die "Failed to import Brave browser GPG key."
zypper ar https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo || die "Failed to add Brave browser repository."
zypper in -y brave-browser || die "Failed to install Brave browser."

# Install VSCodium
rpmkeys --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg || die "Failed to import VSCodium GPG key."
printf "[gitlab.com_paulcarroty_vscodium_repo]\nname=gitlab.com_paulcarroty_vscodium_repo\nbaseurl=https://download.vscodium.com/rpms/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg\nmetadata_expire=1h\n" | tee -a /etc/zypp/repos.d/vscodium.repo || die "Failed to add VSCodium repository."
zypper in -y codium || die "Failed to install VSCodium."

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
    zypper in -y "${packages[@]}" || die "Failed to install packages."
else
    zypper in "${packages[@]}" || die "Failed to install packages."
fi

# Remove devhelp
zypper rm -y devhelp* || die "Failed to remove devhelp."
zypper al devhelp* || die "Failed to add devhelp to avoid reinstallation."

# Install neofetch
zypper ar --no-gpgcheck https://download.opensuse.org/repositories/utilities/openSUSE_Factory/utilities.repo || die "Failed to add neofetch repository."
zypper ref || die "Failed to refresh repositories."
zypper in -y neofetch || die "Failed to install neofetch."

# Protect neofetch from being replaced by neowofetch
zypper al neofetch || die "Failed to add neofetch to the blacklist."

# Install Additional Tools for Virt Manager
zypper in -y -t pattern kvm_server kvm_tools || die "Failed to install Virt Manager tools."

# Set polkit permissions for wheel group users
set_polkit_perms

# Enable Flathub for Flatpak
enable_flathub

# Preserve old configurations (for Virtual Machine Manager)
preserve_old_libvirt_configs

# Set proper permissions in libvirtd.conf
set_libvirtd_permissions

# Set proper permissions in qemu.conf
set_qemu_permissions

# Enable libvirtd service (for Virtual Machine Manager)
echo "Enabling services..."
systemctl enable libvirtd --now >/dev/null 2>&1

# Only enable net-autostart if in physical machine
manage_virsh_network

# Add user to necessary groups
add_user_to_groups libvirt kvm input disk video audio

# Backup original LightDM config
backup_lightdm_config

# Copies example lightdm.conf
cp /usr/share/doc/packages/lightdm/lightdm.conf.example /etc/lightdm/lightdm.conf || die "Failed to copy LightDM configuration file."

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
