#!/bin/bash

# Change to bash shell
chsh -s /bin/bash

# Get the current username
username=$(whoami)

# Update system and install git and curl
apt update && apt upgrade -y
apt install -y git curl nano

# Install Bottom
VERSION="0.10.2"
FILE_VERSION="0.10.2-1"
# Define the source URL using the version and file version variables
URL="https://github.com/ClementTsang/bottom/releases/download/${VERSION}/bottom_${FILE_VERSION}_amd64.deb"
# Download the specified version using curl
curl -LO "$URL"
# Install the downloaded package
dpkg -i bottom_${FILE_VERSION}_amd64.deb
# Remove the downloaded package file
rm bottom_${FILE_VERSION}_amd64.deb

# Install Brave Browser
curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"|tee /etc/apt/sources.list.d/brave-browser-release.list
apt update
apt install -y brave-browser

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
  #"grub-customizer"
  "ncdu"
  "neofetch"
  #"timeshift"
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
  "dconf-editor"
  #"lightdm"
  #"lightdm-settings"
  #"slick-greeter"
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
  "gvfs*"
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
  "libreoffice-gtk3"
  "libreoffice-style-elementary"
  "qbittorrent"
  # "rmlint"
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
apt install -y "${packages[@]}"

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

# Place modified .xinitrc (for Cinnamon), preserving old one
mv ~/.xinitrc ~/.xinitrc.old
mv home/theming/Puppy/.xinitrc ~/
# Sets Windowmanager to cinnamon
echo "startcinnamon" > /etc/windowmanager

<<lightdm
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
lightdm

<<systemd
# Modify systemd configuration to change the default timeout for stopping services during shutdown, preserving old one
cp /etc/systemd/system.conf /etc/systemd/system.conf.old
sed -i 's/^#DefaultTimeoutStopSec=.*/DefaultTimeoutStopSec=15s/' /etc/systemd/system.conf

# Reload the systemd configuration
systemctl daemon-reload
systemd

# Improve Font Rendering
# Write the XML content to /etc/fonts/local.conf
cat <<EOL > /etc/fonts/local.conf
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <match target="font">
    <edit name="antialias" mode="assign">
      <bool>true</bool>
    </edit>
    <edit name="hinting" mode="assign">
      <bool>true</bool>
    </edit>
    <edit mode="assign" name="rgba">
      <const>rgb</const>
    </edit>
    <edit mode="assign" name="hintstyle">
      <const>hintslight</const>
    </edit>
    <edit mode="assign" name="lcdfilter">
      <const>lcddefault</const>
    </edit>
  </match>
</fontconfig>
EOL
# Append Xft settings to ~/.Xresources, preserving old one
cp ~/.Xresources ~/.Xresources.bak
cat <<EOL >> ~/.Xresources
Xft.antialias: 1
Xft.hinting: 1
Xft.rgba: rgb
Xft.hintstyle: hintslight
Xft.lcdfilter: lcddefault
EOL
# Merge changes to ~/.Xresources
xrdb -merge ~/.Xresources
# Symlink available presets to /etc/fonts/conf.d/
ln -s /usr/share/fontconfig/conf.avail/10-sub-pixel-rgb.conf /etc/fonts/conf.d/
ln -s /usr/share/fontconfig/conf.avail/10-hinting-slight.conf /etc/fonts/conf.d/
ln -s /usr/share/fontconfig/conf.avail/11-lcdfilter-default.conf /etc/fonts/conf.d/

# Run the setup script
# cd home/
# chmod +x Setup-LMDE-Theme.sh
# ./Setup-LMDE-Theme.sh
# cd ..

# Reboot for the changes to take effect
echo "Installation complete! Please reboot for the changes to take effect. Then run Setup-Puppy-Theme.sh in cinnamon/home for theming."
