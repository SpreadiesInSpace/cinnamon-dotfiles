#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -eq 0 ]; then
  echo "This script must NOT be run as root. Please execute it as a regular user."
  exit
fi

# Get the current username
username=$(whoami)

# Install base-devel and git, then install yay from AUR
sudo pacman -S --needed --noconfirm base-devel git
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si --noconfirm
cd ..
rm -rf yay-bin

# Check if Color, ParallelDownloads, and ILoveCandy are already in yay config
# Define the options to be added
declare -A options=(["Color"]="Color" ["ParallelDownloads"]="ParallelDownloads = 5" ["ILoveCandy"]="ILoveCandy")
# Loop over the options
for key in "${!options[@]}"; do
    # Check if the option is already in the file
    if ! grep -q "^$key" /etc/pacman.conf; then
        # If not, add it under the # Misc options section
        sudo sed -i "/^# Misc options/a ${options[$key]}" /etc/pacman.conf
    fi
done

# Update MAKEFLAGS /etc/makepkg.conf to match CPU cores
sudo sed -i 's/^#*\s*MAKEFLAGS=.*/MAKEFLAGS="--jobs=$(nproc)"/' /etc/makepkg.conf

# All packages
packages=(
    # System utilities
    "bash-completion"
    "file-roller"
    "flatpak"
    "gparted"
    "grub-customizer"
    "ncdu"
    "neofetch"
    "timeshift"
    "unzip"
    "xorg-xkill"
    "xorg-xrandr"
    # Network utilities
    "filezilla"
    "gvfs"
    "gvfs-afc"
    "gvfs-gphoto2"
    "gvfs-mtp"
    "gvfs-nfs"
    "gvfs-smb"
    "kdeconnect"
    "samba"
    # Desktop environment and related packages
    "cinnamon"
    "eog"
    "evince"
    "ffmpegthumbnailer"
    "gedit"
    "gedit-plugins"
    "gnome-calculator"
    "gnome-keyring"
    "gnome-screenshot"
    "gnome-system-monitor"
    "gnome-terminal"
    "gthumb"
    "gufw"
    "haruna"
    "kvantum"
    "kvantum-qt5"
    "lightdm"
    "lightdm-settings"
    "lightdm-slick-greeter"
    "nemo-fileroller"
    "nemo-image-converter"
    "nemo-preview"
    "nemo-share"
    "qt5ct"
    "qt6ct"
    "rhythmbox"
    # Applications
    "bauh"
    "bleachbit"
    "brave-bin"
    "bottom"
    "gpaste"
    "libreoffice-fresh"
    "neovim"
    "qbittorrent"
    "reflector-simple"
    "spice-vdagent"
    "noto-fonts"
    "noto-fonts-emoji"
    "xclip"
    # For NvChad
    "gcc"
    "make"
    "ripgrep"
    # Virtualization tools
    "virt-manager"
    "qemu-desktop"
    "libvirt"
    "edk2-ovmf"
    "dnsmasq"
    "vde2"
    "bridge-utils"
    "iptables"
    "dmidecode"
    "guestfs-tools"
    "qemu-block-gluster"
    "qemu-block-iscsi"
)

# Update system and install packages
yay -Syu --needed --noconfirm "${packages[@]}"

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

# Enable and start services
sudo systemctl enable libvirtd.service
sudo systemctl enable NetworkManager
sudo systemctl enable lightdm

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
a==1 && /^#?greeter-session=/ {
    print "greeter-session=lightdm-slick-greeter"
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
# cd home/
# chmod +x Setup-Arch-Theme.sh
# ./Setup-Arch-Theme.sh
# cd ..

# Reboot for the changes to take effect
echo "Installation complete! Please reboot for the changes to take effect. Then run Setup-Arch-Theme.sh in cinnamon/home for theming."
