#!/bin/bash

# Get the current username
username=$(whoami)

# Copy my make.conf file to /etc/portage, preserving old one
sudo mv /etc/portage/make.conf /etc/portage/make.conf.old
sudo cp etc/portage/make.conf /etc/portage/make.conf

# Sync Repository
# sudo emaint -a sync

# Install CFG Update to process config file changes and eselect to handle overlays
sudo emerge -quN app-portage/cfg-update app-eselect/eselect-repository dev-vcs/git

# Select 23.0 gnome desktop systemd profile for Cinnamon
sudo eselect profile set default/linux/amd64/23.0/desktop/gnome/systemd
# Emerge changes and cleanup
sudo emerge -avDuN @world
#sudo cfg-update -u
#sudo emerge -avDuN @world
sudo emerge -ad

# Update system and install packages (split them to prevent slot conflicts)
# Desktop environment and related packages
desktop_environment=(
    "gnome-extra/cinnamon"
    "x11-misc/lightdm"
    "x11-misc/lightdm-gtk-greeter"
)
sudo emerge -aqDuN --with-bdeps=y "${desktop_environment[@]}"
sudo cfg-update -u
sudo emerge -aqDuN --with-bdeps=y "${desktop_environment[@]}"
<<com
# Desktop environment and related packages
desktop_environment_extra=(
    "media-video/celluloid"
    "media-gfx/eog"
    "app-text/evince"
    "app-editors/gedit"
    "gnome-extra/gnome-calculator"
    "media-gfx/gnome-screenshot"
    "gnome-extra/gnome-system-monitor"
    "x11-terms/gnome-terminal"
    "media-gfx/gthumb"
    "net-firewall/ufw"
    "gnome-extra/nemo"
    "gnome-extra/nemo-fileroller"
    "x11-misc/qt5ct"
    "gui-apps/qt6ct"
    "x11-base/xorg-server"
)
sudo emerge -aqDuN --with-bdeps=y "${desktop_environment_extra[@]}"
sudo cfg-update -u
sudo emerge -aqDuN --with-bdeps=y "${desktop_environment_extra[@]}"

# System utilities
system_utilities=(
    "app-arch/file-roller"
    "sys-apps/flatpak"
    "sys-block/gparted"
    "sys-fs/ncdu"
    "app-misc/neofetch"
    "app-arch/unzip"
    "x11-apps/xkill"
    "x11-apps/xrandr"
)
sudo emerge -aqDuN --with-bdeps=y "${system_utilities[@]}"
sudo cfg-update -u
sudo emerge -aqDuN --with-bdeps=y "${system_utilities[@]}"

# Network utilities
network_utilities=(
    "net-ftp/filezilla"
    "gnome-base/gvfs"
    "kde-misc/kdeconnect"
    "net-fs/samba"
)
sudo emerge -aqDuN --with-bdeps=y "${network_utilities[@]}"
sudo cfg-update -u
sudo emerge -aqDuN --with-bdeps=y "${network_utilities[@]}"

# Applications
applications=(
    "sys-apps/bleachbit"
    "sys-process/bottom"
    "app-office/libreoffice-bin"
    "app-editors/neovim"
    "net-p2p/qbittorrent"
    "app-emulation/spice-vdagent"
    "media-fonts/noto"
    "media-fonts/noto-emoji"
    "x11-misc/xclip"
)
sudo emerge -aqDuN --with-bdeps=y "${applications[@]}"
sudo cfg-update -u
sudo emerge -aqDuN --with-bdeps=y "${applications[@]}"

# For NvChad
nvchad=(
    "sys-devel/gcc"
    "dev-build/make"
    "sys-apps/ripgrep"
)
sudo emerge -aqDuN --with-bdeps=y "${nvchad[@]}"
sudo cfg-update -u
sudo emerge -aqDuN --with-bdeps=y "${nvchad[@]}"

# Virtualization tools
virtualization_tools=(
    "app-emulation/virt-manager"
    "app-emulation/qemu"
    "app-emulation/libvirt"
    "sys-firmware/edk2-ovmf-bin"
    "net-dns/dnsmasq"
    "net-misc/vde"
    "net-misc/bridge-utils"
    "net-firewall/iptables"
    "sys-apps/dmidecode"
    "app-emulation/libguestfs"
    "sys-cluster/glusterfs"
    "net-libs/libiscsi"
)
sudo emerge -aqDuN --with-bdeps=y "${virtualization_tools[@]}"
sudo cfg-update -u
sudo emerge -aqDuN --with-bdeps=y "${virtualization_tools[@]}"

# Install Brave
sudo eselect repository add brave-overlay git https://gitlab.com/jason.oliveira/brave-overlay.git
sudo emerge --sync brave-overlay
sudo emerge --ask www-client/brave-bin::brave-overlay

# Install rmlint
sudo emerge -quN scons dev-libs/glib
git clone https://github.com/sahib/rmlint.git
cd rmlint/
sudo scons --prefix=/usr install
cd ..
sudo rm -rf rmlint/

# Enable Guru Overlay
sudo eselect repository enable guru
sudo emaint sync -r guru

# Allow select unstable packages to be merged
echo "x11-misc/copyq ~amd64" | sudo tee /etc/portage/package.accept_keywords/copyq
echo "app-admin/grub-customizer ~amd64" | sudo tee /etc/portage/package.accept_keywords/grub-customizer
echo "x11-themes/kvantum ~amd64" | sudo tee /etc/portage/package.accept_keywords/kvantum
echo "app-backup/timeshift ~amd64" | sudo tee /etc/portage/package.accept_keywords/timeshift

# Unstable Packages
unstable_packages=(
    "x11-misc/copyq"
    "app-admin/grub-customizer"
    "x11-themes/kvantum"
    "app-backup/timeshift"
)
sudo emerge -aqDuN --with-bdeps=y "${unstable_packages[@]}"
sudo cfg-update -u
sudo emerge -aqDuN --with-bdeps=y "${unstable_packages[@]}"

# Enable Flathub
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Preserve old libvirtd configuration (for Virtual Machine Manager)
sudo cp /etc/libvirt/libvirtd.conf /etc/libvirt/libvirtd.conf.old

# Check for 'unix_sock_group' entry
if ! grep -q "^unix_sock_group = \"libvirt\"$" /etc/libvirt/libvirtd.conf; then
    echo 'unix_sock_group = "libvirt"' | sudo tee -a /etc/libvirt/libvirtd.conf
else
    sudo sed -i '/^#*unix_sock_group = "libvirt"/s/^#*//' /etc/libvirt/libvirtd.conf
fi

# Check for 'unix_sock_ro_perms' entry
if ! grep -q "^unix_sock_ro_perms = \"0777\"$" /etc/libvirt/libvirtd.conf; then
    echo 'unix_sock_ro_perms = "0777"' | sudo tee -a /etc/libvirt/libvirtd.conf
else
    sudo sed -i '/^#*unix_sock_ro_perms = "0777"/s/^#*//' /etc/libvirt/libvirtd.conf
fi

# Check for 'unix_sock_rw_perms' entry
if ! grep -q "^unix_sock_rw_perms = \"0770\"$" /etc/libvirt/libvirtd.conf; then
    echo 'unix_sock_rw_perms = "0770"' | sudo tee -a /etc/libvirt/libvirtd.conf
else
    sudo sed -i '/^#*unix_sock_rw_perms = "0770"/s/^#*//' /etc/libvirt/libvirtd.conf
fi

# Preserve old QEMU configuration (for Virtual Machine Manager)
sudo cp /etc/libvirt/qemu.conf /etc/libvirt/qemu.conf.old

# Check for 'user' entry
if ! grep -q "^user = \"$username\"$" /etc/libvirt/qemu.conf; then
    echo "user = \"$username\"" | sudo tee -a /etc/libvirt/qemu.conf
fi

# Check for 'group' entry
if ! grep -q "^group = \"$username\"$" /etc/libvirt/qemu.conf; then
    echo "group = \"$username\"" | sudo tee -a /etc/libvirt/qemu.conf
fi

# Check for 'swtpm_user' entry
if ! grep -q "^swtpm_user = \"$username\"$" /etc/libvirt/qemu.conf; then
    echo "swtpm_user = \"$username\"" | sudo tee -a /etc/libvirt/qemu.conf
fi

# Check for 'swtpm_group' entry
if ! grep -q "^swtpm_group = \"$username\"$" /etc/libvirt/qemu.conf; then
    echo "swtpm_group = \"$username\"" | sudo tee -a /etc/libvirt/qemu.conf
fi

# Enable and start the libvirtd service
sudo systemctl enable --now libvirtd.service

# Start and autostart the default network
# sudo virsh net-start default
# sudo virsh net-autostart default

# Add the current user to the necessary groups
groups=(libvirt libvirt-qemu kvm input disk video audio)
for group in "${groups[@]}"; do
    sudo usermod -aG "$group" "$USER"
done

# Backs up old lightdm.conf
sudo cp /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.old

# Replace specific lines in lightdm.conf
sudo awk -i inplace '
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
sudo groupadd -f autologin
# Add the current user to the 'autologin' group
sudo gpasswd -a $username autologin

# Modify systemd configuration to change the default timeout for stopping services during shutdown, preserving old one
sudo cp /etc/systemd/system.conf /etc/systemd/system.conf.old
sudo sed -i 's/^#DefaultTimeoutStopSec=.*/DefaultTimeoutStopSec=15s/' /etc/systemd/system.conf

# Reload the systemd configuration
sudo systemctl daemon-reload

# Run the setup script
# cd home/
# chmod +x Setup-Gentoo.sh
# ./Setup-Gentoo.sh
# cd ..

# Reboot for the changes to take effect
echo "Installation complete! Please reboot for the changes to take effect. Then run Setup-Gentoo.sh in cinnamon/home for theming."
