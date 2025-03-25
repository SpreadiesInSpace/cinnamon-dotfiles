#!/bin/bash

# Get the current username
username=$(whoami)

# Install base-devel, git, and other dependencies
sudo xbps-install -Syu git xtools

# Install xmirror utility
sudo xbps-install -Sy xmirror

# Use xmirror to select the fastest mirrors
# sudo xmirror -s https://repo-fastly.voidlinux.org/
sudo xmirror -s https://mirror.vofr.net/voidlinux/

# Install multilib and nonfree repos
sudo xbps-install -Sy void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree
sudo xbps-install -Syu

# All packages (adapt package names as needed for Void Linux)
packages=(
    # Void Builds Cinnamon packages
    "dialog"
    "cryptsetup"
    "lvm2"
    "mdadm"
    "libxcrypt-compat"
    "xorg-minimal"
    "xorg-input-drivers"
    "xorg-video-drivers"
    #"intel-ucode"
    "setxkbmap"
    "xauth"
    "font-misc-misc"
    "alsa-plugins-pulseaudio"
    "gptfdisk"
    "gettext"
    "elogind"
    "dbus-elogind"
    "dbus-elogind-x11"
    "exfat-utils"
    "fuse-exfat"
    "wget"
    "xdg-utils"
    "xdg-desktop-portal"
    "xdg-desktop-portal-gtk"
    "xdg-desktop-portal-kde"
    "xdg-user-dirs"
    "xdg-user-dirs-gtk"
    "AppStream"
    "libvdpau-va-gl"
    "vdpauinfo"
    "pipewire"
    "wireplumber"
    "gstreamer1-pipewire"
    "upower"
    "dtrx"
    "unzip"
    "p7zip"
    "bash-completion"
    "colord"
    "alsa-utils"
    "pavucontrol"
    "udisks2"
    "ntfs-3g"
    "gnome-keyring"
    "network-manager-applet"
    "adwaita-icon-theme"
    "rsync"
    "psmisc"
    "dkms"
    # System utilities
    "file-roller"
    "flatpak"
    "gparted"
    "grub-customizer"
    "ncdu"
    "neofetch"
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
    "gvfs-smb"
    "kdeconnect"
    "kf6-sonnet"
    "samba"
    # Desktop environment and related packages
    "cinnamon"
    "celluloid"
    "eog"
    "evince"
    "ffmpegthumbnailer"
    "gedit"
    "gedit-plugins"
    "gnome-calculator"
    "gnome-screenshot"
    "gnome-system-monitor"
    "gnome-terminal"
    "gthumb"
    "gufw"
    "kvantum"
    "lightdm"
    "lightdm-gtk-greeter-settings"
    "lightdm-gtk3-greeter"
    "nemo-fileroller"
    "nemo-image-converter"
    "nemo-preview"
    #"nemo-share"
    "qt5ct"
    "qt6ct"
    "rhythmbox"
    # Applications
    "bleachbit"
    "bottom"
    "GPaste"
    "libreoffice"
    "nano"
    "neovim"
    "octoxbps"
    "qbittorrent"
    # "rmlint"
    "spice-vdagent"
    "noto-fonts-ttf"
    "noto-fonts-emoji"
    "xclip"
    # For NvChad
    "gcc"
    "make"
    "ripgrep"
    # Virtualization tools
    "virt-manager"
    "qemu"
    "libvirt"
    "edk2-ovmf"
    "dnsmasq"
    "vde2"
    "bridge-utils"
    "iptables"
    "dmidecode"
    "libguestfs"
)

# Update system and install packages
sudo xbps-install -Syu "${packages[@]}"

# Protect neofetch from being removed
xbps-pkgdb -m hold neofetch

<<LANCZOS
# Apply ANTIALIAS to LANCZOS patch for cinnamon-settings backgrounds
# List of files to update
files=(
    "/usr/share/cinnamon/cinnamon-settings-users/cinnamon-settings-users.py"
    "/usr/share/cinnamon/cinnamon-settings/bin/imtools.py"
    "/usr/share/cinnamon/cinnamon-settings/modules/cs_backgrounds.py"
    "/usr/share/cinnamon/cinnamon-settings/modules/cs_user.py"
)
# Iterate over each file and replace 'ANTIALIAS' with 'LANCZOS'
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        sudo sed -i 's/ANTIALIAS/LANCZOS/g' "$file"
        echo "Updated $file"
    else
        echo "File $file not found"
    fi
done
echo "cinnamon-settings backgrounds LANCZOS patch complete!"
LANCZOS

# Install Brave
cd home/theming/Void
chmod +x update_brave.sh
./update_brave.sh
cd ..

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

# Enable and start services for Virt Manager
sudo ln -s /etc/sv/spice-vdagentd /var/service
sudo ln -s /etc/sv/libvirtd /var/service
sudo ln -s /etc/sv/virtlockd /var/service
sudo ln -s /etc/sv/virtlogd /var/service

# Enable and start services for LightDM & Cinnamon
sudo ln -s /etc/sv/dbus /var/service
sudo ln -s /etc/sv/lightdm /var/service
sudo ln -s /etc/sv/NetworkManager /var/service
sudo rm /var/service/dhcpcd

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

# Run the setup script
# cd home/
# chmod +x Setup-Void-Theme.sh
# ./Setup-Void-Theme.sh
# cd ..

# Reboot for the changes to take effect
echo "Installation complete! Please reboot for the changes to take effect. Then run Setup-Void-Theme.sh in cinnamon/home for theming."
