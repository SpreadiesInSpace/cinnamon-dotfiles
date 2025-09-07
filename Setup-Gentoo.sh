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

# Detect Init System
if eselect profile show | grep -q systemd; then
	GENTOO_INIT="systemd"
else
	GENTOO_INIT="openrc"
fi
echo "Detected init system: $GENTOO_INIT"

# Check if custom make.conf and VIDEO_CARDS have already been set previously
if is_makeconf_configured; then
	echo "make.conf already configured during install. Skipping..."
else
	echo "Configuring make.conf..."

	# Backup current make.conf & replace with custom one
	configure_make_conf "/etc/portage/make.conf" "old.$(date +%s)" "false"

	# Set VIDEO_CARDS value in package.use
	set_video_card || \
		die "Failed to set video card."

	# Drop flag so this doesn't run again
	mark_makeconf_configured
fi

# Install Essentials
emerge -vquN app-eselect/eselect-repository app-editors/nano dev-vcs/git || \
	die "Failed to install essential packages."

# Switch from rsync to git for faster repository sync times
FLAG="/var/db/repos/.synced-git-repo"

# Skip this if run previously
if [[ ! -f "$FLAG" ]]; then
	eselect repository remove -f gentoo || \
		die "Failed to remove rsync-based Gentoo repository."
	eselect repository add gentoo git \
		https://github.com/gentoo-mirror/gentoo.git || \
		die "Failed to enable Git-based Gentoo repository."
	touch "$FLAG" || \
		die "Failed to create git sync flag."
	rm -rf /var/db/repos/gentoo || \
		die "Failed to remove existing gentoo repository."
	echo "Switched to git for repository sync."
else
	echo "Repository already configured for git. Skipping."
fi

# Enable Additional Overlays
eselect repository add sunny-overlay git \
	https://github.com/dguglielmi/sunny-overlay.git || \
	die "Failed to add sunny-overlay repository."
eselect repository enable guru || \
	die "Failed to enable guru repository."
eselect repository enable gentoo-zh || \
	die "Failed to enable gentoo-zh repository."

# Allow select unstable packages to be merged
echo "x11-misc/gpaste ~amd64" | \
	tee /etc/portage/package.accept_keywords/gpaste || \
	die "Failed to add gpaste to package.accept_keywords."
echo "app-admin/grub-customizer ~amd64" | \
	tee /etc/portage/package.accept_keywords/grub-customizer || \
	die "Failed to add grub-customizer to package.accept_keywords."
echo "media-video/haruna ~amd64" | \
	tee /etc/portage/package.accept_keywords/haruna || \
	die "Failed to add haruna to package.accept_keywords."
echo "x11-apps/lightdm-gtk-greeter-settings ~amd64" | \
	tee /etc/portage/package.accept_keywords/lightdm-gtk-greeter-settings || \
	die "Failed to add lightdm-gtk-greeter-settings to package.accept_keywords."
echo "x11-themes/kvantum ~amd64" | \
	tee /etc/portage/package.accept_keywords/kvantum || \
	die "Failed to add kvantum to package.accept_keywords."
echo "app-backup/timeshift ~amd64" | \
	tee /etc/portage/package.accept_keywords/timeshift || \
	die "Failed to add timeshift to package.accept_keywords."

# Enable Extra Use Flags
echo "app-editors/gedit-plugins charmap git terminal" | \
	tee /etc/portage/package.use/gedit-plugins || \
	die "Failed to set USE flags for gedit-plugins."
echo "media-video/ffmpegthumbnailer gnome" | \
	tee /etc/portage/package.use/ffmpegthumbnailer || \
	die "Failed to set USE flags for ffmpegthumbnailer."
echo "gnome-extra/nemo tracker" | \
	tee /etc/portage/package.use/nemo || \
	die "Failed to set USE flags for nemo."
echo "app-emulation/qemu glusterfs iscsi opengl pipewire spice usbredir vde virgl virtfs zstd" | \
	tee /etc/portage/package.use/qemu || \
	die "Failed to set USE flags for qemu."

# Temporary Python Versions Fix
# echo "x11-apps/lightdm-gtk-greeter-settings PYTHON_SINGLE_TARGET: python3_12" | \
#	tee /etc/portage/package.use/python || \
#	die "Failed to set USE flags for python."

# Sync Repository + All Overlays
emaint sync -a || \
	die "Failed to sync repositories and overlays."

# Select appropriate Gentoo profile based on init system
if [ "$GENTOO_INIT" = "systemd" ]; then
	eselect profile set default/linux/amd64/23.0/desktop/gnome/systemd || \
		die "Failed to set systemd system profile."
else
	eselect profile set default/linux/amd64/23.0/desktop || \
		die "Failed to set OpenRC system profile."
fi

# Enable Sound (Pipewire)
echo "media-video/pipewire sound-server" | \
	tee /etc/portage/package.use/pipewire || \
	die "Failed to set USE flags for pipewire."
echo "media-sound/pulseaudio -daemon" | \
	tee /etc/portage/package.use/pulseaudio || \
	die "Failed to set USE flags for pulseaudio."

# Emerge changes and cleanup
emerge -vqDuN @world || \
	die "Failed to emerge world update."
emerge -q --depclean || \
	die "Failed to clean up unused dependencies."

# All Packages
packages=(
	# Unstable Packages
	"x11-misc/gpaste"
	"app-admin/grub-customizer"
	#"x11-apps/lightdm-gtk-greeter-settings" # clashes with gobject-introspection
	"x11-themes/kvantum"
	"app-backup/timeshift" # triggers use flag change
	# Desktop environment related packages
	"x11-base/xorg-server"
	"gnome-extra/cinnamon"
	"x11-misc/lightdm"
	"x11-misc/lightdm-gtk-greeter"
	"www-client/brave-bin"
	"media-gfx/eog"
	"app-text/evince"
	"media-video/ffmpegthumbnailer"
	"app-editors/gedit"
	"app-editors/gedit-plugins"
	"gnome-extra/gnome-calculator"
	"sys-apps/gnome-disk-utility"
	"media-gfx/gnome-screenshot"
	"gnome-extra/gnome-system-monitor"
	"x11-terms/gnome-terminal"
	"media-gfx/gthumb"
	"media-video/haruna"
	"gnome-extra/nemo"
	"gnome-extra/nemo-fileroller"
	"x11-misc/qt5ct"
	"gui-apps/qt6ct"
	"media-sound/rhythmbox"
	"app-editors/vscodium"
	# System utilities
	"app-admin/eclean-kernel"
	"dev-python/zstandard" # for eclean-kernel
	"app-arch/file-roller"
	"sys-apps/flatpak"
	"sys-apps/xdg-desktop-portal-gtk"
	"app-portage/gentoolkit"
	"sys-block/gparted"
	"app-portage/mirrorselect"
	"sys-fs/ncdu"
	"app-misc/neofetch"
	"net-firewall/ufw"
	"app-arch/unzip"
	"x11-apps/xkill"
	"x11-apps/xrandr"
	# Network utilities
	"net-ftp/filezilla"
	"gnome-base/gvfs"
	"kde-misc/kdeconnect"
	"net-fs/samba"
	# Applications
	"sys-apps/bleachbit"
	"sys-process/bottom"
	"app-office/libreoffice-bin"
	"app-editors/neovim"
	"net-p2p/qbittorrent"
	"app-emulation/spice-vdagent"
	"media-fonts/noto"
	"media-fonts/noto-emoji"
	"x11-misc/xclip"
	# For NvChad
	"sys-devel/gcc"
	"dev-build/make"
	"sys-apps/ripgrep"
	# Virtualization Tools
	"app-emulation/virt-manager" # triggers use flag change
	"app-emulation/qemu"
	"app-emulation/libvirt" # triggers use flag change
	"sys-firmware/edk2-bin"
	"net-dns/dnsmasq"
	"net-misc/vde"
	"net-misc/bridge-utils"
	"net-firewall/iptables"
	"sys-apps/dmidecode"
	"sys-cluster/glusterfs"
	"net-libs/libiscsi"
	"app-emulation/guestfs-tools"
)

# Create autounmask file
touch /etc/portage/package.use/zzz_autounmask || \
	die "Failed to create autounmask file."

# Temporary libguestfs sandbox violation fix
bash unsorted/Gentoo/libguestfs-sandbox-fix.sh

# Install Packages
if [ "$GENTOO_INIT" = "systemd" ]; then
	emerge -vqDuN --with-bdeps=y --keep-going --autounmask-write \
		--autounmask-continue=y "${packages[@]}"
else
	emerge -vqDuN --with-bdeps=y --keep-going --autounmask-write \
		--autounmask-continue=y "${packages[@]}" \
		gui-libs/display-manager-init
	# Enable LightDM for OpenRC via display-manager
	sed -i 's|^DISPLAYMANAGER=.*|DISPLAYMANAGER="lightdm"|' \
		/etc/conf.d/display-manager
fi

# Capture Exit Code
emerge_exit_code=$?

# Stop script if emerge fails desipte using --keep-going flag
if [ $emerge_exit_code -ne 0 ]; then
	die "Emerge failed with exit code: $emerge_exit_code"
fi

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

# Enable and start services
echo "Enabling services..."
if [ "$GENTOO_INIT" = "systemd" ]; then
	for svc in libvirtd lightdm NetworkManager; do
		systemctl enable "$svc" >/dev/null 2>&1 || \
			die "Failed to enable $svc service."
	done
	for user_svc in pipewire.service pipewire-pulse.socket \
			wireplumber.service; do
		systemctl --global enable "$user_svc" >/dev/null 2>&1 || \
			die "Failed to enable $user_svc globally."
	done
else
	for svc in libvirtd display-manager NetworkManager spice-vdagent dbus \
			openrc-settingsd elogind; do
		rc-update add "$svc" default || die "Failed to enable $svc service."
	done
fi

# Only enable net-autostart if in physical machine
manage_virsh_network

# Add the current user to the necessary groups
add_user_to_groups libvirt kvm input disk video pipewire

# Backup original LightDM config
backup_lightdm_config

# Modify lightdm.conf in-place
modify_lightdm_conf "gentoo"

# Ensure autologin group exists and add user
ensure_autologin_group

# If running in a VM, set display-setup-script in lightdm.conf
set_lightdm_display_for_vm

# Set timeout for stopping services during shutdown via drop in file
if [ "$GENTOO_INIT" = "systemd" ]; then
	set_systemd_timeout_stop
	# Reload the systemd configuration
	reload_systemd_daemon
fi

# Add flag for Setup-Theme.sh
add_setup_theme_flag "gentoo"

# Display Reboot Message
print_reboot_message
