#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run the script using sudo."
  exit
fi

# Check if the script is run from the root account
if [ "$SUDO_USER" = "" ]; then
  echo "Please do not run this script from the root account. Use sudo instead."
  exit
fi

# Get the current username
username=$SUDO_USER

# Autologin Prompt
read -rp "Enable autologin for $username? [y/N]: " autologin_input
case "$autologin_input" in
    [yY][eE][sS]|[yY])
        enable_autologin=true
        ;;
    *)
        enable_autologin=false
        ;;
esac

# VM Prompt
read -rp "Is this a Virtual Machine? [y/N]: " response
case "$response" in
    [yY][eE][sS]|[yY])
        is_vm=true
        ;;
    *)
        is_vm=false
        ;;
esac

# Check if custom make.conf and VIDEO_CARDS have already been set previously
MAKECONF_FLAG="/etc/portage/.makeconf_configured"

if [ -f "$MAKECONF_FLAG" ]; then
  echo "make.conf already configured during install. Skipping..."
else
  echo "Configuring /etc/portage/make.conf..."

  # Backup current make.conf & replace with custom one
  cp /etc/portage/make.conf /etc/portage/make.conf.old
  cp etc/portage/make.conf /etc/portage/make.conf

  # Set MAKEOPTS based on CPU cores (load limit = cores + 1)
  cores=$(nproc)
  makeopts_load_limit=$((cores + 1))
  sed -i "s/^MAKEOPTS=.*/MAKEOPTS=\"-j$cores -l$makeopts_load_limit\"/" /etc/portage/make.conf
  echo "Updated MAKEOPTS to -j$cores -l$makeopts_load_limit"

  # Set EMERGE_DEFAULT_OPTS based on CPU cores (load limit as 90% of cores)
  load_limit=$(echo "$cores * 0.9" | bc -l | awk '{printf "%.1f", $0}')
  sed -i "s/^EMERGE_DEFAULT_OPTS=.*/EMERGE_DEFAULT_OPTS=\"-j$cores -l$load_limit\"/" /etc/portage/make.conf
  echo "Updated EMERGE_DEFAULT_OPTS to -j$cores -l$load_limit"

  # Set VIDEO_CARDS value in package.use
  set_video_card() {
    while true; do
      echo "Select your video card type:"
      echo "1) amdgpu radeonsi"
      echo "2) nvidia"
      echo "3) intel"
      echo "4) nouveau (open source)"
      echo "5) virgl (QEMU/KVM)"
      echo "6) vc4 (Raspberry Pi)"
      echo "7) d3d12 (WSL)"
      echo "8) other"
      read -p "Enter the number corresponding to your video card: " video_card_number

      case $video_card_number in
        1) video_card="amdgpu radeonsi"; break ;;
        2) video_card="nvidia"; break ;;
        3) video_card="intel"; break ;;
        4) video_card="nouveau"; break ;;
        5) video_card="virgl"; break ;;
        6) video_card="vc4"; break ;;
        7) video_card="d3d12"; break ;;
        8)
          read -p "Enter your video card string: " video_card
          break ;;
        *) echo "Invalid selection, please try again." ;;
      esac
    done
    
    # Create or update the /etc/portage/package.use/00video-cards file
    echo "*/* VIDEO_CARDS: $video_card" | tee /etc/portage/package.use/00video-cards
    echo "Updated VIDEO_CARDS in /etc/portage/package.use/00video-cards to $video_card based on provided input."
  }
  
  # Call the function
  set_video_card

  # Drop flag so this doesn't run again
  touch "$MAKECONF_FLAG"
fi

# Review make.conf file
# nano /etc/portage/make.conf

# Install Essentials 
emerge -vquN app-eselect/eselect-repository app-editors/nano dev-vcs/git

# Switch from rsync to git for faster repository sync times
FLAG="/var/db/repos/.synced-git-repo"

# Skip this if run previously
if [[ ! -f "$FLAG" ]]; then
  eselect repository disable gentoo
  eselect repository enable gentoo
  rm -rf /var/db/repos/gentoo
  touch "$FLAG"
  echo "Switched to git for repository sync."
else
  echo "Repository already configured for git. Skipping."
fi

# Enable Additional Overlays
eselect repository add sunny-overlay git https://github.com/dguglielmi/sunny-overlay.git # for GPaste
eselect repository enable guru # for unstable packages
eselect repository enable gentoo-zh # for Brave
eselect repository enable djs_overlay # for Cinnamon 6.4

# Mask select djs_overlay packages
echo "app-editors/neovim::djs_overlay" | tee /etc/portage/package.mask/neovim
echo "www-client/brave-bin::djs_overlay" | tee /etc/portage/package.mask/brave

# Allow select unstable packages to be merged
echo "x11-misc/gpaste ~amd64" | tee /etc/portage/package.accept_keywords/gpaste
echo "app-admin/grub-customizer ~amd64" | tee /etc/portage/package.accept_keywords/grub-customizer
echo "media-video/haruna ~amd64" | tee /etc/portage/package.accept_keywords/haruna
echo "x11-apps/lightdm-gtk-greeter-settings ~amd64" | tee /etc/portage/package.accept_keywords/lightdm-gtk-greeter-settings
echo "x11-themes/kvantum ~amd64" | tee /etc/portage/package.accept_keywords/kvantum
echo "app-backup/timeshift ~amd64" | tee /etc/portage/package.accept_keywords/timeshift

# Enable Extra Use Flags
echo "app-editors/gedit-plugins charmap git terminal" | tee /etc/portage/package.use/gedit-plugins
echo "media-video/ffmpegthumbnailer gnome" | tee /etc/portage/package.use/ffmpegthumbnailer
echo "gnome-extra/nemo tracker" | tee /etc/portage/package.use/nemo
echo "app-emulation/qemu glusterfs iscsi opengl pipewire spice usbredir vde virgl virtfs zstd" | tee /etc/portage/package.use/qemu

# Sync Repository + All Overlays
emaint sync -a

# Select 23.0 gnome desktop systemd profile for Cinnamon
eselect profile set default/linux/amd64/23.0/desktop/gnome/systemd

# Enable Sound (Pipewire)
echo "media-video/pipewire sound-server" | tee /etc/portage/package.use/pipewire
echo "media-sound/pulseaudio -daemon" | tee /etc/portage/package.use/pulseaudio

# Set LINGUAS for Cinnamon Localization
# echo "*/* LINGUAS: en" | tee /etc/portage/package.use/00localization

# Emerge changes and cleanup
emerge -vqDuN @world
emerge -q --depclean

# Update system and install Cinnamon (split them to prevent slot conflicts)
desktop_environment=(
    "x11-base/xorg-server"
    "gnome-extra/cinnamon"
    "x11-misc/lightdm"
    "x11-misc/lightdm-gtk-greeter"
    "www-client/brave-bin" # for verifying gentoo-zh > djs_brave override
)
emerge -vqDuN --with-bdeps=y "${desktop_environment[@]}"

# All Packages
packages=(
    "x11-misc/gpaste"
    "app-admin/grub-customizer"
    "x11-apps/lightdm-gtk-greeter-settings"
    "x11-themes/kvantum"
    "app-backup/timeshift" # triggers use flag change
    # Desktop environment related packages
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
    "app-office/libreoffice"
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
# Automatically accept USE changes and update config files
touch /etc/portage/package.use/zzz_autounmask
# Emerge with autounmask-write and continue
emerge -vqDuN --with-bdeps=y "${packages[@]}" --autounmask-write --autounmask-continue=y
# Update configurations automatically, writing to zzz_autounmask
dispatch-conf <<< $(echo -e 'y')
# Resume emerge
emerge -vqDuN --with-bdeps=y --keep-going "${packages[@]}"

# Enable Flathub
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Preserve old configurations (for Virtual Machine Manager)
cp /etc/libvirt/libvirtd.conf /etc/libvirt/libvirtd.conf.old
cp /etc/libvirt/qemu.conf /etc/libvirt/qemu.conf.old

# Set proper permissions in libvirtd.conf
for line in \
  'unix_sock_group = "libvirt"' \
  'unix_sock_ro_perms = "0777"' \
  'unix_sock_rw_perms = "0770"'; do
  key=${line%% *}
  # Only add the line if it's completely missing (including commented-out lines)
  if ! grep -q -E "^$key\s*=" /etc/libvirt/libvirtd.conf; then
    # Append the line if it doesn't exist in any form
    echo "$line" | tee -a /etc/libvirt/libvirtd.conf > /dev/null
  fi
done

# Set proper permissions in qemu.conf
for key in user group swtpm_user swtpm_group; do
  if ! grep -q "^$key = \"$username\"$" /etc/libvirt/qemu.conf; then
    echo "$key = \"$username\"" | tee -a /etc/libvirt/qemu.conf > /dev/null
  fi
done

# Enable and start services
systemctl enable libvirtd lightdm NetworkManager
systemctl --global enable pipewire.service pipewire-pulse.socket wireplumber.service

# Only enable net-autostart if in physical machine
if [ "$is_vm" = false ]; then
    virsh net-autostart default
    virsh net-start default
else
    # Disable autostart and destroy the network if running
    virsh net-autostart default --disable
    rm -f /etc/libvirt/qemu/networks/autostart/default.xml
    if virsh net-info default | grep -q "Active:.*yes"; then
        virsh net-destroy default
    fi
    # Restart libvirtd to ensure clean state
    systemctl restart libvirtd
fi

# Add the current user to the necessary groups
groups=(libvirt kvm input disk video pipewire)
for group in "${groups[@]}"; do
    usermod -aG "$group" "$username"
done

# Backup original LightDM config
cp /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.old

# Modify lightdm.conf in-place
awk -v user="$username" -v autologin="$enable_autologin" -i inplace '
/^\[Seat:\*\]/ {a=1}
a==1 && /^#?greeter-hide-users=/ {
    print "greeter-hide-users=false"
    next
}
a==1 && /^#?autologin-user=/ {
    if (autologin == "true") {
        print "autologin-user=" user
    } else {
        print "#autologin-user=" user
    }
    next
}
a==1 && /^#?autologin-session=/ {
    print "autologin-session=cinnamon"
    next
}
a==1 && /^#?user-session=/ {
    print "user-session=cinnamon"
    next
}
{print}
' /etc/lightdm/lightdm.conf

# Ensure autologin group exists and add user
groupadd -f autologin
gpasswd -a "$username" autologin

# If running in a VM, set display-setup-script in lightdm.conf
if [ "$is_vm" = true ]; then
    # Detect connected output using sysfs (avoids X dependency)
    output_path=$(grep -l connected /sys/class/drm/*/status | head -n1)
    output=$(basename "$(dirname "$output_path")")
    output="${output#*-}"  # Strip 'cardX-' prefix
    if [[ -n "$output" ]]; then
        sed -i "/^\[Seat:\*\]/,/^\[.*\]/ {
            s|^#*display-setup-script=.*|display-setup-script=xrandr --output $output --mode 1920x1080 --rate 60|
        }" /etc/lightdm/lightdm.conf
    fi
fi

# Set timeout for stopping services during shutdown via drop in file
mkdir -p /etc/systemd/system.conf.d
echo "[Manager]" | tee /etc/systemd/system.conf.d/override.conf
echo "DefaultTimeoutStopSec=15s" | tee -a /etc/systemd/system.conf.d/override.conf

# Reload the systemd configuration
systemctl daemon-reload

# Add flag for Setup-Theme.sh
CURRENT_DIR=$(pwd)
su - "$SUDO_USER" -c "touch '$CURRENT_DIR/.gentoo.done'"

# Reboot for the changes to take effect
echo "Installation complete! Please reboot for the changes to take effect. Then run Theme.sh in cinnamon-dotfiles for theming."
