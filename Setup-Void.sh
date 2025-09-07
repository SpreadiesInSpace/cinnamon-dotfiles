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

# Install tools
xbps-install -Sy xbps git xtools xmirror || \
	die "Failed to install git and xtools."

# Use xmirror to select a mirror
REPO="https://repo-fi.voidlinux.org/"
# REPO="https://repo-de.voidlinux.org/"
# REPO="https://mirror.vofr.net/voidlinux/"
# REPO="https://repo-fastly.voidlinux.org/"
xmirror -s "$REPO" || \
	die "Failed to set the mirror with xmirror."

# Install multilib and nonfree repos
xbps-install -Sy void-repo-nonfree void-repo-multilib \
	void-repo-multilib-nonfree || \
		die "Failed to install multilib and nonfree repositories."
xbps-install -Syu || \
	die "Failed to update system after adding repositories."

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
	"gstreamer1-pipewire"
	"upower"
	"dtrx"
	"unzip"
	"7zip"
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
	# PipeWire
	"alsa-pipewire"
	"libspa-bluetooth"
	"pipewire"
	"wireplumber"
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
xbps-install -Sy "${packages[@]}" || \
	die "Failed to install packages."

# Protect neofetch from being removed
xbps-pkgdb -m hold neofetch || \
	die "Failed to hold neofetch package."

# Install Brave and VSCodium
cd home/theming/Void || \
	die "Failed to move to theming/Void folder."
./update_xdeb.sh || \
	die "Failed to install Brave/VSCodium."
cd ..

# Configure PipeWire
configure_pipewire

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
for service in dbus lightdm NetworkManager polkitd spice-vdagentd \
		libvirtd virtlockd virtlogd; do
	ln -sf /etc/sv/$service /etc/runit/runsvdir/default || \
		die "Failed to enable $service."
done

# Let services start
sleep 5

# Only enable net-autostart if in physical machine
manage_virsh_network "void"

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

# Add flag for Setup-Theme.sh
add_setup_theme_flag "void"

# Display Reboot Message
print_reboot_message
