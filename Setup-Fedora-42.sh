#!/bin/bash

# Source common functions
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }
[ -f ./Setup-Common.sh ] || die "Setup-Common.sh not found."
source ./Setup-Common.sh || die "Failed to source Setup-Common.sh"

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
echo "Configuring DNF..."
if ! grep -q "^max_parallel_downloads=10$" /etc/dnf/dnf.conf; then
	echo 'max_parallel_downloads=10' | tee -a /etc/dnf/dnf.conf >/dev/null 2>&1 \
		|| die "Failed to enable parallel downloads in /etc/dnf/dnf.conf"
else
	sed -i '/^#*max_parallel_downloads=10/s/^#*//' /etc/dnf/dnf.conf || \
		die "Failed to modify parallel downloads setting in /etc/dnf/dnf.conf"
fi

# Remove PackageKit cache
rm -rf /var/cache/PackageKit || die "Failed to remove PackageKit cache."

# Redownload metadata cache without auto updates
echo "Refreshing Metadata Cache..."
pkcon refresh force -c -1 >/dev/null 2>&1 || \
	die "Failed to refresh metadata cache."

# Update system and install git
dnf -y update || die "System update failed."
dnf -y install git || die "Git installation failed."

# Add RPM Fusion
FEDORA_VER="$(rpm -E %fedora)"
BASE_URL="https://mirrors.rpmfusion.org"
dnf -y install \
	"$BASE_URL/free/fedora/rpmfusion-free-release-$FEDORA_VER.noarch.rpm" \
	"$BASE_URL/nonfree/fedora/rpmfusion-nonfree-release-$FEDORA_VER.noarch.rpm" \
	|| die "Failed to add RPM Fusion repositories."

# Install Media Codecs
dnf4 -y group upgrade multimedia || die "Multimedia group upgrade failed."
dnf -y swap 'ffmpeg-free' 'ffmpeg' --allowerasing || \
	die "Failed to swap ffmpeg-free with ffmpeg."
dnf -y upgrade @multimedia --setopt="install_weak_deps=False" \
	--exclude=PackageKit-gstreamer-plugin || \
	die "Failed to upgrade multimedia group."
dnf group install -y sound-and-video || \
	die "Failed to install sound-and-video group."

# Install Brave
curl -fsS https://dl.brave.com/install.sh | sh || \
	die "Failed to install Brave Browser."

# Install Bottom
dnf -y copr enable atim/bottom || die "Failed to enable COPR repo for Bottom."
dnf -y install bottom || die "Failed to install Bottom."

# Install Neofetch
URL="https://archives.fedoraproject.org/pub/archive/fedora/linux/releases/40"
dnf -y install \
	"$URL/Everything/x86_64/os/Packages/n/neofetch-7.1.0-12.fc40.noarch.rpm" \
	|| die "Failed to install Neofetch."

# Install VSCodium
VSC="https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg"
rpmkeys --import "$VSC" \
	|| die "Failed to import VSCodium GPG key."
# Add VSCodium repository
GPG="https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg"
printf "%s\n" \
	"[gitlab.com_paulcarroty_vscodium_repo]" \
	"name=download.vscodium.com" \
	"baseurl=https://download.vscodium.com/rpms/" \
	"enabled=1" \
	"gpgcheck=1" \
	"repo_gpgcheck=1" \
	"gpgkey=$GPG" \
	"metadata_expire=1h" | \
	tee -a /etc/yum.repos.d/vscodium.repo || \
	die "Failed to add VSCodium repository."
dnf install -y codium || die "Failed to install VSCodium."

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
dnf -y install "${packages[@]}" || die "Failed to install packages."

# Disable Problem Reporting
systemctl disable abrtd.service >/dev/null 2>&1 || \
	die "Failed to disable Problem Reporting service."

# Uninstall SystemD Core Dump Generator (tracker-miners)
dnf remove -y tracker-miners || die "Failed to remove tracker-miners."

# Replace FirewallD with UFW and allow KDE Connect through
dnf -y remove firewalld || die "Failed to remove firewalld."
systemctl daemon-reload || die "Failed to reload systemd daemon."
ufw enable || die "Failed to enable UFW."
ufw allow "KDE Connect" || die "Failed to allow KDE Connect in UFW."

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
