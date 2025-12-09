#!/bin/bash

# Source common functions
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }
[ -f ./Setup-Common.sh ] || die "Setup-Common.sh not found."
source ./Setup-Common.sh || die "Failed to source Setup-Common.sh"

# Declare variables that will be set by sourced functions
declare username enable_autologin is_vm

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
  echo 'max_parallel_downloads=10' | tee -a /etc/dnf/dnf.conf \
  >/dev/null 2>&1 || \
  die "Failed to enable parallel downloads in /etc/dnf/dnf.conf"
else
  sed -i '/^#*max_parallel_downloads=10/s/^#*//' \
  /etc/dnf/dnf.conf || \
  die "Failed to modify parallel downloads setting in /etc/dnf/dnf.conf"
fi

# Update system and install git
retry dnf -y update || \
  die "System update failed."
retry dnf -y install git || \
  die "Git installation failed."

# Add RPM Fusion
fedora_ver="$(rpm -E %fedora)"
free="https://mirrors.rpmfusion.org/free/fedora"
free="$free/rpmfusion-free-release-$fedora_ver.noarch.rpm"
nonfree="https://mirrors.rpmfusion.org/nonfree/fedora"
nonfree="$nonfree/rpmfusion-nonfree-release-$fedora_ver.noarch.rpm"
retry dnf -y install "$free" "$nonfree" || \
  die "Failed to add RPM Fusion repositories."

# Fix RPM Fusion mirrors
fix_rpmfusion_mirrors

# Install Media Codecs
retry dnf install -y libavcodec-freeworld || \
  die "Failed to install libavcodec-freeworld."
retry dnf -y group install multimedia || \
  die "Failed to install multimedia group."
retry dnf -y swap 'ffmpeg-free' 'ffmpeg' --allowerasing || \
  die "Failed to switch to full ffmpeg."
retry dnf -y upgrade @multimedia --setopt="install_weak_deps=False" \
  --exclude=PackageKit-gstreamer-plugin || \
  die "Failed to install gstreamer compenents."
retry dnf -y group install sound-and-video || \
  die "Failed to install sound-and-video group."

# Debloat if installed via cinnamon-ISO
if [[ -f ".fedora-43.done" ]]; then
  bash unsorted/Fedora/Fedora-Bloat.sh || \
    die "Failed to remove bloat."
  sudo -u "$username" touch home/.fedora.gnome
fi

# Install Brave
retry curl -fsS https://dl.brave.com/install.sh | sh || \
  die "Failed to install Brave Browser."

# Install Bottom
VERSION="0.11.4"
FILE_VERSION="0.11.4-1"
# Define the source URL using the version and file version variables
BTM="https://github.com/ClementTsang/bottom/releases"
BTM="$BTM/download/${VERSION}/bottom-${FILE_VERSION}.x86_64.rpm"
# Download the specified version using curl
retry curl -LO "$BTM" || \
  die "Failed to download Bottom package."
# Install the downloaded package
rpm -i bottom-${FILE_VERSION}.x86_64.rpm || \
  die "Failed to install Bottom package."
# Remove the downloaded package file
rm bottom-${FILE_VERSION}.x86_64.rpm || \
  die "Failed to remove downloaded Bottom package file."

# Install Neofetch
neofetch_url="https://archives.fedoraproject.org/pub/archive/fedora"
neofetch_url="$neofetch_url/linux/releases/40/Everything/x86_64/os"
neofetch_url="$neofetch_url/Packages/n/neofetch-7.1.0-12.fc40.noarch.rpm"
retry dnf -y install "$neofetch_url" || \
  die "Failed to install Neofetch."

# Install VSCodium
VSC="https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg"
rpmkeys --import "$VSC" || die "Failed to import VSCodium GPG key."
{
  cat << EOF
[gitlab.com_paulcarroty_vscodium_repo]
name=download.vscodium.com
baseurl=https://download.vscodium.com/rpms/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=$VSC
metadata_expire=1h
EOF
} > /etc/yum.repos.d/vscodium.repo || \
  die "Failed to add VSCodium repository."
retry dnf install -y codium || \
  die "Failed to install VSCodium."

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
  #"ufw"
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
  "google-noto-sans-math-fonts"
  # For NvChad
  "gcc"
  "make"
  "ripgrep"
  # Virtualization tools
  "guestfs-tools"
  "@virtualization"
)

# Install Packages
retry dnf -y install "${packages[@]}" || \
  die "Failed to install packages."

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
