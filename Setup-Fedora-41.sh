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

# Check for max_parellel_downloads and fastestmirrors entries and adds them to dnf.conf
if ! grep -q "^max_parallel_downloads=10$" /etc/dnf/dnf.conf; then
    echo 'max_parallel_downloads=10' | tee -a /etc/dnf/dnf.conf
else
    sed -i '/^#*max_parallel_downloads=10/s/^#*//' /etc/dnf/dnf.conf
fi

# Update system and install git
dnf -y update
dnf -y install git

# Add RPM Fusion
dnf -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
dnf -y install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
dnf -y upgrade --refresh
# dnf -y groupupdate core

# Install Media Codecs
dnf -y swap 'ffmpeg-free' 'ffmpeg' --allowerasing
dnf -y update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin 
dnf -y update @sound-and-video
dnf -y install gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel # ffmpeg gstreamer-ffmpeg
dnf -y install lame\* --exclude=lame-devel

# Install Brave
dnf -y install dnf-plugins-core
dnf config-manager addrepo --id=brave-browser --set=name='Brave Browser' --set=baseurl='https://brave-browser-rpm-release.s3.brave.com/$basearch'
rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
dnf -y install brave-browser

# Install Bottom
dnf -y copr enable atim/bottom
dnf -y install bottom

# Install Neofetch
dnf -y install https://dl.fedoraproject.org/pub/fedora/linux/releases/40/Everything/x86_64/os/Packages/n/neofetch-7.1.0-12.fc40.noarch.rpm

# Rename Totem Thumbnailer to make ffmpegthumbnailer work
mv /usr/share/thumbnailers/totem.thumbnailer /usr/share/thumbnailers/totem.thumbnailer.bak

# All packages
packages=(
    # System utilities
    "file-roller"
    "flatpak"
    "gparted"
    "grub-customizer"
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

# Update install packages
dnf -y install "${packages[@]}"

# Disable Problem Reporting
systemctl disable abrtd.service

# Uninstall SystemD Core Dump Generator (tracker-miners)
dnf remove -y tracker-miners

# Replace FirewallD with UFW and allow KDE Connect through
dnf -y remove firewalld
systemctl daemon-reload
ufw enable
ufw allow "KDE Connect"

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

# Enable and start the libvirtd service
systemctl enable --now libvirtd.service

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
{print}
' /etc/lightdm/lightdm.conf

# Create a new group named 'autologin' if it doesn't already exist
groupadd -f autologin
# Add the current user to the 'autologin' group
gpasswd -a $username autologin

# Modify systemd configuration to change the default timeout for stopping services during shutdown via drop in file
mkdir -p /etc/systemd/system.conf.d
echo "[Manager]" | tee /etc/systemd/system.conf.d/override.conf
echo "DefaultTimeoutStopSec=15s" | tee -a /etc/systemd/system.conf.d/override.conf

# Reload the systemd configuration
systemctl daemon-reload

# Run the setup script
# cd home/
# chmod +x Setup-Fedora-Theme.sh
# ./Setup-Fedora-Theme.sh
# cd ..

# Reboot for the changes to take effect
echo "Installation complete! Please reboot for the changes to take effect. Then run Setup-Fedora-Theme.sh in cinnamon/home for theming."
