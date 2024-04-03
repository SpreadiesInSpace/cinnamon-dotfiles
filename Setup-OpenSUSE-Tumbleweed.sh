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

# Update system and install packages
zypper refresh
zypper dist-upgrade -y

# Install and run mirrorsorcerer for faster mirrors
zypper install -y mirrorsorcerer
mirrorsorcerer -x
systemctl enable mirrorsorcerer

# Install git
zypper install -y git

# Install Media Codecs
zypper ar -cfp 90 --no-gpgcheck 'https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/Essentials/' packman-essentials
zypper refresh
zypper dup --from packman-essentials --allow-vendor-change -y
zypper install --from packman-essentials -y ffmpeg gstreamer-plugins-{good,bad,ugly,libav} libavcodec-full vlc-codecs

# Install Brave
zypper install -y curl
rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
zypper addrepo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
zypper install -y brave-browser

# Install rmlint
zypper addrepo --no-gpgcheck https://download.opensuse.org/repositories/home:darix:apps/openSUSE_Tumbleweed/home:darix:apps.repo
zypper refresh
zypper install -y rmlint

# All packages
packages=(
    # System utilities
    "file-roller"
    "flatpak"
    "gparted"
    "ncdu"
    "neofetch"
    "timeshift"
    "unzip"
    "xkill"
    "xrandr"
    # Network utilities
    "filezilla"
    "gvfs"
    "gvfs-backends"
    "kdeconnect-kde"
    "samba"
    # Desktop environment and related packages
    "cinnamon"
    "celluloid"
    "eog"
    "evince"
    #"gedit"
    "gnome-calculator"
    "gnome-screenshot"
    "gnome-system-monitor"
    "gnome-terminal"
    "gthumb"
    "kvantum-manager"
    "kvantum-qt5"
    "kvantum-qt6"
    "lightdm"
    "lightdm-slick-greeter"
    "nemo"
    "nemo-extension-fileroller"
    "nemo-extension-image-converter"
    "nemo-extension-preview"
    "nemo-extension-share"
    "qt5ct"
    "qt6ct"
    "rhythmbox"
    # Applications
    "bleachbit"
    "bottom"
    "gpaste"
    "typelib-1_0-GPaste-2"
    "libreoffice"
    "libreoffice-gtk3"
    "neovim"
    "opi"
    "qbittorrent"
    "spice-vdagent"
    "google-noto-coloremoji-fonts"
    "google-noto-sans-fonts"
    "xclip"
    "xed"
    # For NvChad
    "gcc"
    "make"
    "ripgrep"
    # Virtualization tools
    "yast2-vm"
    "libvirt"
)

# Install packages
for package in "${packages[@]}"; do
    zypper install -y $package
done

# Install Cinnamon Control Center (needs to be seperate according to openSUSE wiki)
zypper install cinnamon-control-center

# Install Additional Tools for Virt Manager
zypper install -y -t pattern kvm_server kvm_tools

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
# virsh net-start default
# virsh net-autostart default

# Add the current user to the necessary groups
groups=(libvirt libvirt-qemu kvm input disk video audio)
for group in "${groups[@]}"; do
    usermod -aG "$group" "$username"
done

# Backs up old lightdm.conf
cp /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.old

# Copies example lightdm.conf
cp /usr/share/doc/packages/lightdm/lightdm.conf.example /etc/lightdm/lightdm.conf

# Replace specific lines in lightdm.conf
awk -i inplace '
/^\[Seat:\*\]/ {a=1}
a==1 && /^#?greeter-hide-users=/ {
    print "greeter-hide-users=false"
    next
}
a==1 && /^#?greeter-session=/ {
    print "greeter-session=slick-greeter"
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

# Modify systemd configuration to change the default timeout for stopping services during shutdown, preserving old one
cp /etc/systemd/system.conf.d/timeout.conf /etc/systemd/system.conf.d/timeout.conf.old
mkdir -p /etc/systemd/system.conf.d/
echo -e "[Manager]\nDefaultTimeoutStopSec=15s" | tee /etc/systemd/system.conf.d/timeout.conf

# Reload the systemd configuration
systemctl daemon-reload

# Run the setup script
# cd home/
# chmod +x Setup-openSUSE-Theme.sh
# ./Setup-openSUSE-Theme.sh
# cd ..

# Reboot for the changes to take effect
echo "Installation complete! Please reboot for the changes to take effect. Then run Setup-openSUSE-Theme.sh in cinnamon/home for theming."
