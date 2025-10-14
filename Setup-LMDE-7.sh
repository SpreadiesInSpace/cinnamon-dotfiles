#!/bin/bash

# Source common functions
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }
[ -f ./Setup-Common.sh ] || die "Setup-Common.sh not found."
source ./Setup-Common.sh || die "Failed to source Setup-Common.sh"

# Declare variables that will be set by sourced functions
declare enable_autologin is_vm

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
retry apt update || \
  die "Failed to update system."
retry apt upgrade -y || \
  die "Failed to upgrade system."
retry apt install -y git curl || \
  die "Failed to install git and curl."

# Install Brave Browser
retry curl -fsS https://dl.brave.com/install.sh | sh || \
  die "Failed to install Brave Browser."

# Install Neovim AppImage
NVIM="https://github.com/neovim/neovim/releases/latest/download"
NVIM="$NVIM/nvim-linux-x86_64.appimage"
retry curl -LO "$NVIM" || \
  die "Failed to download Neovim AppImage."
chmod u+x nvim-linux-x86_64.appimage || \
  die "Failed to make Neovim AppImage executable."
./nvim-linux-x86_64.appimage --appimage-extract || \
  die "Failed to extract Neovim AppImage."
./squashfs-root/AppRun --version || \
  die "Failed to check Neovim version."
rm -rf /squashfs-root/ || \
  die "Failed to remove extracted Neovim AppImage files."
mv squashfs-root / || die "Failed to move extracted Neovim files."
rm -rf /usr/bin/nvim || die "Failed to remove existing Neovim binary."
ln -s /squashfs-root/AppRun /usr/bin/nvim || \
  die "Failed to create symlink for Neovim."
rm nvim-linux-x86_64.appimage || die "Failed to remove Neovim AppImage file."

# Install VSCodium
VSC="https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg"
retry wget -qO - "$VSC" \
  | gpg --dearmor \
  | dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg || \
  die "Failed to import VSCodium GPG key."
keyring="/usr/share/keyrings/vscodium-archive-keyring.gpg"
repo_url="https://download.vscodium.com/debs"
echo "deb [arch=amd64,arm64 signed-by=$keyring] $repo_url vscodium main" \
  | tee /etc/apt/sources.list.d/vscodium.list \
  > /dev/null || \
  die "Failed to add VSCodium repository."
retry apt update || \
  die "APT update failed."
retry apt install -y codium || \
  die "Failed to install VSCodium."

# Install Neofetch
echo "deb http://deb.debian.org/debian bookworm main" > \
  /etc/apt/sources.list.d/bookworm-neofetch.list || \
  die "Failed to add bookworm repo."
apt update || die "APT update failed."
apt install -y neofetch -t bookworm || die "Failed to install neofetch."

# Pin the package to prevent changes
echo "Package: neofetch
Pin: version *
Pin-Priority: 1001" > /etc/apt/preferences.d/pin-neofetch || \
  die "Failed to pin neofetch."

# Remove the source
rm /etc/apt/sources.list.d/bookworm-neofetch.list || \
  die "Failed to remove bookworm repo."
apt update || die "APT update failed."

# All packages
packages=(
  # System utilities
  "build-essential"
  "file-roller"
  "flatpak"
  "gparted"
  "grub-customizer"
  "ncdu"
  #"neofetch"
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
  #"mint-meta-codecs"
  "nemo"
  "nemo-fileroller"
  "qt5-style-kvantum"
  "qt5-style-kvantum-themes"
  "qt5ct"
  "qt6ct"
  "qt6-style-kvantum"
  "qt-style-kvantum-themes"
  "rhythmbox"
  # Applications
  "bleachbit"
  "btm"
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
retry apt install -y "${packages[@]}" || \
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
