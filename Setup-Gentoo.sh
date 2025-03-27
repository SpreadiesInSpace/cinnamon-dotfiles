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

# Copy my make.conf file to /etc/portage, preserving old one
mv /etc/portage/make.conf /etc/portage/make.conf.old
cp etc/portage/make.conf /etc/portage/make.conf

# Update MAKEFLAGS & EMERGE_DEFAULT_OPS in /etc/portage/make.conf to match CPU cores
cores=$(nproc)
# Calculate the load average limit (e.g., cores + 1)
load_limit=$((cores + 1))
# Edit make.conf to set MAKEOPTS
sed -i "s/^MAKEOPTS=.*/MAKEOPTS=\"-j$cores -l$load_limit\"/" /etc/portage/make.conf
# Edit make.conf to set EMERGE_DEFAULT_OPTS
sed -i "s/^EMERGE_DEFAULT_OPTS=.*/EMERGE_DEFAULT_OPTS=\"-j$cores -l$load_limit\"/" /etc/portage/make.conf
echo "Updated MAKEOPTS and EMERGE_DEFAULT_OPTS in /etc/portage/make.conf to -j$cores -l$load_limit based on the number of CPU cores."

# Set VIDEO_CARDS value in make.conf
set_video_card() {
  while true; do
    echo "Valid values are:"
    echo "1) amdgpu radeonsi"
    echo "2) nvidia"
    echo "3) intel"
    echo "4) nouveau (open source)"
    echo "5) virgl (QEMU/KVM)"
    echo "6) vc4 (Raspberry Pi)"
    echo "7) d3d12 (WSL)"
    echo "8) other"
    read -p "Enter the video card type number: " video_card_number

    case $video_card_number in
      1) video_card="amdgpu radeonsi"; break ;;
      2) video_card="nvidia"; break ;;
      3) video_card="intel"; break ;;
      4) video_card="nouveau"; break ;;
      5) video_card="virgl"; break ;;
      6) video_card="vc4"; break ;;
      7) video_card="d3d12"; break ;;
      8) 
        read -p "Enter the video card type: " video_card; break ;;
      *) echo "Invalid selection, please try again." ;;
    esac
  done
  # Edit make.conf to set VIDEO_CARDS
  sed -i "s/^VIDEO_CARDS=.*/VIDEO_CARDS=\"$video_card\"/" /etc/portage/make.conf
  echo "Updated VIDEO_CARDS in /etc/portage/make.conf to $video_card based on provided input."
}
# Call the function
set_video_card

# Review make.conf file
# nano /etc/portage/make.conf

# Install Essentials 
emerge -vquN app-eselect/eselect-repository app-editors/nano dev-vcs/git

# Switch from rsync to git
eselect repository disable gentoo
eselect repository enable gentoo
rm -rf /var/db/repos/gentoo

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

# lwt dependency fails to compile because ppxlib is pulled in as a binary
# emerge -vq --keep-going app-emulation/guestfs-tools 
# re-emerge dev/ppxlib from source
# FEATURES="-getbinpkg" emerge -1Dvq dev-ml/ppxlib
# lwt will now compile properly, allowing guestfs-tools to finish compiling
# emerge -vq --keep-going app-emulation/guestfs-tools 

# Enable Flathub
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Preserve old libvirtd configuration (for Virtual Machine Manager)
cp /etc/libvirt/libvirtd.conf /etc/libvirt/libvirtd.conf.old

# Check for 'unix_sock_group' entry
if ! grep -q "^unix_sock_group = \"libvirt\"$" /etc/libvirt/libvirtd.conf; then
    echo 'unix_sock_group = "libvirt"' | tee -a /etc/libvirt/libvirtd.conf
else
    sed -i '/^#*unix_sock_group = "libvirt"/s/^#*//' /etc/libvirt/libvirtd.conf
fi

# Check for 'unix_sock_ro_perms' entry
if ! grep -q "^unix_sock_ro_perms = \"0777\"$" /etc/libvirt/libvirtd.conf; then
    echo 'unix_sock_ro_perms = "0777"' | tee -a /etc/libvirt/libvirtd.conf
else
    sed -i '/^#*unix_sock_ro_perms = "0777"/s/^#*//' /etc/libvirt/libvirtd.conf
fi

# Check for 'unix_sock_rw_perms' entry
if ! grep -q "^unix_sock_rw_perms = \"0770\"$" /etc/libvirt/libvirtd.conf; then
    echo 'unix_sock_rw_perms = "0770"' | tee -a /etc/libvirt/libvirtd.conf
else
    sed -i '/^#*unix_sock_rw_perms = "0770"/s/^#*//' /etc/libvirt/libvirtd.conf
fi

# Preserve old QEMU configuration (for Virtual Machine Manager)
cp /etc/libvirt/qemu.conf /etc/libvirt/qemu.conf.old

# Check for 'user' entry
if ! grep -q "^user = \"$username\"$" /etc/libvirt/qemu.conf; then
    echo "user = \"$username\"" | tee -a /etc/libvirt/qemu.conf
fi

# Check for 'group' entry
if ! grep -q "^group = \"$username\"$" /etc/libvirt/qemu.conf; then
    echo "group = \"$username\"" | tee -a /etc/libvirt/qemu.conf
fi

# Check for 'swtpm_user' entry
if ! grep -q "^swtpm_user = \"$username\"$" /etc/libvirt/qemu.conf; then
    echo "swtpm_user = \"$username\"" | tee -a /etc/libvirt/qemu.conf
fi

# Check for 'swtpm_group' entry
if ! grep -q "^swtpm_group = \"$username\"$" /etc/libvirt/qemu.conf; then
    echo "swtpm_group = \"$username\"" | tee -a /etc/libvirt/qemu.conf
fi

# Enable and start services
systemctl enable libvirtd.service
systemctl enable lightdm.service
systemctl enable NetworkManager.service
systemctl --global enable pipewire-pulse.socket 
systemctl --global enable wireplumber.service
systemctl --global enable pipewire.service

# Start and autostart the default network
virsh net-start default
virsh net-autostart default

# Add the current user to the necessary groups
groups=(libvirt libvirt-qemu kvm input disk video pipewire)
for group in "${groups[@]}"; do
    usermod -aG "$group" "$username"
done

# Backs up old lightdm.conf
cp /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.old

# Replace specific lines in lightdm.conf
awk -i inplace '
/^\[Seat:\*\]/ {a=1}
a==1 && /^#?greeter-hide-users=/ {
    print "greeter-hide-users=false"
    next
}
a==1 && /^#?display-setup-script=/ {
    print "#display-setup-script=xrandr --output Virtual-1 --mode 1920x1080 --rate 60"
    next
}
a==1 && /^#?autologin-user=/ {
    print "#autologin-user='"$username"'"
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

# Create a new group named 'autologin' if it doesn't already exist
groupadd -f autologin
# Add the current user to the 'autologin' group
gpasswd -a $username autologin

# Modify systemd configuration to change the default timeout for stopping services during shutdown via drop in file
sudo mkdir -p /etc/systemd/system.conf.d
echo "[Manager]" | sudo tee /etc/systemd/system.conf.d/override.conf
echo "DefaultTimeoutStopSec=15s" | sudo tee -a /etc/systemd/system.conf.d/override.conf

# Reload the systemd configuration
systemctl daemon-reload

# Run the setup script
# cd home/
# chmod +x Setup-Gentoo-Theme.sh
# ./Setup-Gentoo-Theme.sh
# cd ..

# Reboot for the changes to take effect
echo "Installation complete! Please reboot for the changes to take effect. Then run Setup-Gentoo-Theme.sh in cinnamon/home for theming."
