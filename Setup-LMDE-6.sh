#!/bin/bash

# Get the current username
username=$(whoami)

# Update system and install sudo, git and curl
sudo apt update && sudo apt upgrade -y
sudo apt install -y sudo git curl

# Install Bottom
VERSION="0.10.2"
FILE_VERSION="0.10.2-1"
# Define the source URL using the version and file version variables
URL="https://github.com/ClementTsang/bottom/releases/download/${VERSION}/bottom_${FILE_VERSION}_amd64.deb"
# Download the specified version using curl
curl -LO "$URL"
# Install the downloaded package
sudo dpkg -i bottom_${FILE_VERSION}_amd64.deb
# Remove the downloaded package file
sudo rm bottom_${FILE_VERSION}_amd64.deb

# Install Brave Browser
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
sudo apt update
sudo apt install -y brave-browser

# Install Neovim AppImage
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
chmod u+x nvim-linux-x86_64.appimage
./nvim-linux-x86_64.appimage --appimage-extract
./squashfs-root/AppRun --version
sudo rm -rf /squashfs-root/
sudo mv squashfs-root /
sudo rm -rf /usr/bin/nvim
sudo ln -s /squashfs-root/AppRun /usr/bin/nvim
rm nvim-linux-x86_64.appimage

# All packages
packages=(
    # System utilities
    "build-essential"
    "file-roller"
    "flatpak"
    "gparted"
    "grub-customizer"
    "ncdu"
    "neofetch"
    "timeshift"
    "unzip"
    "x11-xserver-utils"
    # Network utilities
    "filezilla"
    "gvfs"
    "gvfs-backends"
    "kdeconnect"
    "samba"
    # Desktop environment and related packages
    "cinnamon"
    "dconf-cli"
    "lightdm"
    "lightdm-settings"
    "slick-greeter"
    "eog"
    "evince"
    "gedit"
    "gedit-plugins"
    "gnome-calculator"
    "gnome-screenshot"
    "gnome-system-monitor"
    "gnome-terminal"
    "gthumb"
    "gufw"
    "haruna"
    "nemo"
    "nemo-fileroller"
    "qt5-style-kvantum"
    "qt5-style-kvantum-themes"
    "qt5ct"
    "qt6ct"
    "rhythmbox"
    # Applications
    "bleachbit"
    "gir1.2-gpaste-2"
    "gpaste-2"
    "libreoffice"
    "libreoffice-style-elementary"
    "qbittorrent"
    "spice-vdagent"
    "fonts-noto-core"
    "fonts-noto-color-emoji"
    "xclip"
    # For NvChad
    "gcc"
    "make"
    "ripgrep"
    # Virtualization tools
    "virt-manager"
    "qemu-system"
    "qemu-utils"
    "libvirt-clients"
    "libvirt-daemon-system"
    "libvirt-daemon"
    "bridge-utils"
    "virtinst"
    "iptables"
    "dmidecode"
    "guestfs-tools"
)

# Update system and install packages
sudo apt install -y "${packages[@]}"

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
sudo virsh net-start default
sudo virsh net-autostart default

# Add the current user to the necessary groups
groups=(libvirt libvirt-qemu kvm input disk video audio)
for group in "${groups[@]}"; do
    sudo usermod -aG "$group" "$username"
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

# Modify systemd configuration to change the default timeout for stopping services during shutdown via drop in file
sudo mkdir -p /etc/systemd/system.conf.d
echo "[Manager]" | sudo tee /etc/systemd/system.conf.d/override.conf
echo "DefaultTimeoutStopSec=15s" | sudo tee -a /etc/systemd/system.conf.d/override.conf

# Reload the systemd configuration
sudo systemctl daemon-reload

# Run the setup script
cd home/
chmod +x Setup-LMDE-Theme.sh
./Setup-LMDE-Theme.sh
cd ..

# Reboot for the changes to take effect
echo "Installation complete! Please reboot for the changes to take effect."
