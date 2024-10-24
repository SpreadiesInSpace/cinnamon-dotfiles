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
# Review make.conf file
nano /etc/portage/make.conf

# Sync Repository
emaint -a sync

# Install Essentials 
emerge -quN app-eselect/eselect-repository app-editors/nano dev-vcs/git

# Select 23.0 gnome desktop systemd profile for Cinnamon
eselect profile set default/linux/amd64/23.0/desktop/gnome/systemd
# Emerge changes and cleanup
emerge -qDuN @world
emerge --depclean

# Update system and install packages (split them to prevent slot conflicts)
# Desktop environment and display manager
desktop_environment=(
    "x11-base/xorg-server"
    "gnome-extra/cinnamon"
    "x11-misc/lightdm"
    "x11-misc/lightdm-gtk-greeter"
)
emerge -qDuN --with-bdeps=y "${desktop_environment[@]}"

# Install Brave
eselect repository enable gentoo-zh
emaint sync -r gentoo-zh
emerge -qDuN www-client/brave-bin

# Enable Guru Overlay
eselect repository enable guru
emaint sync -r guru

# Install rmlint
emerge -quN dev-build/scons dev-libs/glib
git clone https://github.com/sahib/rmlint.git
cd rmlint/
scons --prefix=/usr install
cd ..
rm -rf rmlint/

# Enable sunny-overlay for GPaste
eselect repository add sunny-overlay git https://github.com/dguglielmi/sunny-overlay.git
emaint sync -r sunny-overlay

# Allow select unstable packages to be merged
# echo "x11-misc/copyq ~amd64" | tee /etc/portage/package.accept_keywords/copyq
echo "x11-misc/gpaste ~amd64" | tee /etc/portage/package.accept_keywords/gpaste
echo "app-admin/grub-customizer ~amd64" | tee /etc/portage/package.accept_keywords/grub-customizer
echo "x11-apps/lightdm-gtk-greeter-settings ~amd64" | tee /etc/portage/package.accept_keywords/lightdm-gtk-greeter-settings
echo "x11-themes/kvantum ~amd64" | tee /etc/portage/package.accept_keywords/kvantum
echo "app-backup/timeshift ~amd64" | tee /etc/portage/package.accept_keywords/timeshift

# Unstable Packages
unstable_packages=(
    #"x11-misc/copyq"
    "x11-misc/gpaste"
    "app-admin/grub-customizer"
    "x11-apps/lightdm-gtk-greeter-settings"
    "x11-themes/kvantum"
    "app-backup/timeshift"
)
touch /etc/portage/package.accept_keywords/zzz_autounmask
emerge -qDuN --with-bdeps=y "${unstable_packages[@]}" --autounmask-write --autounmask
dispatch-conf
emerge -qDuN --with-bdeps=y "${unstable_packages[@]}"

# Desktop environment related packages
desktop_environment_extra=(
    "media-gfx/eog"
    "app-text/evince"
    "app-editors/gedit"
    "gnome-extra/gnome-calculator"
    "media-gfx/gnome-screenshot"
    "gnome-extra/gnome-system-monitor"
    "x11-terms/gnome-terminal"
    "media-gfx/gthumb"
    "media-video/mpv"
    "gnome-extra/nemo"
    "gnome-extra/nemo-fileroller"
    "x11-misc/qt5ct"
    "gui-apps/qt6ct"
    "media-sound/rhythmbox"
)
emerge -qDuN --with-bdeps=y "${desktop_environment_extra[@]}"

# System utilities
system_utilities=(
    "app-admin/eclean-kernel"
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
)
emerge -qDuN --with-bdeps=y "${system_utilities[@]}"

# Applications
applications=(
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
)
emerge -qDuN --with-bdeps=y "${applications[@]}"

# Virtualization tools
virtualization_tools=(
    "app-emulation/virt-manager"
    "app-emulation/qemu"
    "app-emulation/libvirt"
    "sys-firmware/edk2-bin"
    "net-dns/dnsmasq"
    "net-misc/vde"
    "net-misc/bridge-utils"
    "net-firewall/iptables"
    "sys-apps/dmidecode"
    "app-emulation/libguestfs"
    "sys-cluster/glusterfs"
    "net-libs/libiscsi"
)
touch /etc/portage/package.accept_keywords/zzz_autounmask
emerge -qDuN --with-bdeps=y "${virtualization_tools[@]}" --autounmask-write --autounmask
dispatch-conf
emerge -qDuN --with-bdeps=y "${virtualization_tools[@]}"

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

# Enable and start services service
systemctl enable libvirtd.service
systemctl enable lightdm.service
systemctl enable NetworkManager.service
systemctl --global enable pulseaudio.service pulseaudio.socket

# Start and autostart the default network
virsh net-start default
virsh net-autostart default

# Add the current user to the necessary groups
groups=(libvirt libvirt-qemu kvm input disk video audio)
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

# Modify systemd configuration to change the default timeout for stopping services during shutdown, preserving old one
cp /etc/systemd/system.conf /etc/systemd/system.conf.old
sed -i 's/^#DefaultTimeoutStopSec=.*/DefaultTimeoutStopSec=15s/' /etc/systemd/system.conf

# Reload the systemd configuration
systemctl daemon-reload

# Run the setup script
# cd home/
# chmod +x Setup-Gentoo-Theme.sh
# ./Setup-Gentoo-Theme.sh
# cd ..

# Reboot for the changes to take effect
echo "Installation complete! Please reboot for the changes to take effect. Then run Setup-Gentoo-Theme.sh in cinnamon/home for theming."
