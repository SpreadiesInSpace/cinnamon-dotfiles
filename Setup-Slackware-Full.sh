#!/bin/bash

# Get the current username
username=$(whoami)

# Grab Slackware Setup Scripts by gosh-its-arch-linux
git clone https://gitlab.com/gosh-its-arch-linux/slackware-scripts.git
cd slackware-scripts
# Can do either Current or Slackware 15.0
cd Current
# cd Slackware15
chmod +x *.sh
# Set up Slackware User, init level 4, xwmconfig to KDE
sudo ./setup_script
# Set Slackpkg US Mirrors and update cache
sudo ./update_mirror_and_pkgs
# Run Full Update
sudo ./update_slackware
# Install and configure sbopkg and sbotools
sudo ./install_sbopkg_and_sbotools

# Install Bottom


# Install Neovim AppImage
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
chmod u+x nvim.appimage
./nvim.appimage --appimage-extract
./squashfs-root/AppRun --version
sudo mv squashfs-root /
sudo ln -s /squashfs-root/AppRun /usr/bin/nvim
rm nvim.appimage

# Install rmlint
git clone https://github.com/sahib/rmlint.git
cd rmlint/
sudo scons --prefix=/usr install
cd ..
sudo rm -rf rmlint/

# Install Xed
git clone https://github.com/linuxmint/xed
cd xed/

# All packages
packages=(
    # System utilities
    "file-roller"
    "flatpak"
    "gparted"
    "ncdu"
    #"neofetch""
    "timeshift"
    # "unzip" 
    # "xkill" 
    # "xrandr"
    # Network utilities
    "filezilla"
    #"gvfs"
    #"kdeconnect"
    "samba"
    # Desktop environment and related packages
    # "cinnamon"
    "celluloid"
    "eog"
    "evince"
    "gnome-calculator"
    "gnome-screenshot"
    "gnome-system-monitor"
    "gnome-terminal"
    "gui-ufw"
    "kvantum-qt5"
    "qt5ct"
    "qt6ct"
    # Applications
    "bleachbit"
    "brave-browser"
    "bottom" #no rust16
    #"gpaste"
    "libreoffice"
    #"neovim" 
    "qbittorrent"
    "rmlint" #no sphinx
    "spice-vdagent"
    #"noto-fonts"
    #"noto-fonts-emoji" (doesn't exist)
    "xclip"
    # For NvChad
    #"gcc"
    #"make"
    "ripgrep"
    # Virtualization tools
    "virt-manager"
    "qemu"
    "libvirt"
    "edk2-ovmf"
    #"dnsmasq"
    "vde2"
    #"bridge-utils"
    #"iptables"
    #"dmidecode"
)

# Update system and install packages
sudo sboinstall "${packages[@]}"

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

# Enable and start the libvirtd and spice-vdagent service
sudo sh /etc/rc.d/rc.spice-vdagent start
sudo sh /etc/rc.d/rc.libvirt start

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
# sudo cp /etc/systemd/system.conf /etc/systemd/system.conf.old
# sudo sed -i 's/^#DefaultTimeoutStopSec=.*/DefaultTimeoutStopSec=15s/' /etc/systemd/system.conf

# Reload the systemd configuration
# sudo systemctl daemon-reload

# Run the setup script
cd home/
chmod +x Setup-Slackware.sh
./Setup-Slackware.sh
cd ..

# Reboot for the changes to take effect
echo "Installation complete! Please reboot for the changes to take effect."
