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

# Check if Color, ParallelDownloads, and ILoveCandy are in /etc/pacman.conf
echo "Configuring pacman..."
declare -A options=(
  ["Color"]="Color"
  ["ParallelDownloads"]="ParallelDownloads = 5"
  ["ILoveCandy"]="ILoveCandy"
)
for key in "${!options[@]}"; do
  if ! grep -q "^$key" /etc/pacman.conf; then
    sed -i "/^# Misc options/a ${options[$key]}" /etc/pacman.conf || \
    die "Failed to configure pacman option: $key."
  fi
done

# Update MAKEFLAGS /etc/makepkg.conf to match CPU cores
cores=$(nproc)
echo "Set MAKEFLAGS to --jobs=$cores"
sed -i "s/^#*\\s*MAKEFLAGS=.*/MAKEFLAGS=\"--jobs=$cores\"/" \
  /etc/makepkg.conf || \
  die "Failed to update MAKEFLAGS in /etc/makepkg.conf."

# Install base-devel and git
pacman -S --needed --noconfirm base-devel git || \
  die "Failed to install git."

# Remove passwordless sudo if script is interrupted
trap 'rm -f /etc/sudoers.d/99_${SUDO_USER}_nopasswd' ERR INT TERM

# Temporarily allow passwordless sudo for current user
echo "$SUDO_USER ALL=(ALL) NOPASSWD: ALL" > \
  /etc/sudoers.d/99_"${SUDO_USER}"_nopasswd || \
    die "Failed to modify sudoers file for $SUDO_USER."
chmod 0440 /etc/sudoers.d/99_"${SUDO_USER}"_nopasswd || \
  die "Failed to set proper permissions for sudoers file."

# Install yay
cat << 'EOF' | su - "$SUDO_USER"
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }
trap 'rm -rf yay-bin' ERR INT TERM
echo "Configuring yay..."
git clone https://aur.archlinux.org/yay-bin.git >/dev/null 2>&1 || \
  die "Failed to download yay."
cd yay-bin || die "Failed to enter yay-bin directory."
makepkg -si --noconfirm >/dev/null 2>&1 || die "Failed to install yay."
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
  "wget"
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
  "vscodium-bin"
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
yay -Syu --needed --noconfirm "${packages[@]}" || \
  die "Failed to install packages."
EOF

# Remove temporary passwordless sudo access
rm -f /etc/sudoers.d/99_"${SUDO_USER}"_nopasswd

# Enable Flathub for Flatpak
enable_flathub

# Preserve old configurations (for Virtual Machine Manager)
preserve_old_libvirt_configs

# Set proper permissions in libvirtd.conf
set_libvirtd_permissions

# Set proper permissions in qemu.conf
set_qemu_permissions

# Enable and start services
echo "Enabling services..."
systemctl enable libvirtd >/dev/null 2>&1 || \
  die "Failed to enable libvirtd service."
systemctl enable lightdm >/dev/null 2>&1 || \
  die "Failed to enable lightdm service."
systemctl enable NetworkManager >/dev/null 2>&1 || \
  die "Failed to enable NetworkManager service."

# Only enable net-autostart if in physical machine
manage_virsh_network

# Add user to necessary groups
add_user_to_groups libvirt libvirt-qemu kvm input disk video audio

# Backup original LightDM config
backup_lightdm_config

# Modify lightdm.conf in-place
modify_lightdm_conf "arch"

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

# Display Reboot Message
print_reboot_message
