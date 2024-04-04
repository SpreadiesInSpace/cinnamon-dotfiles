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

# Review Hostname
nano /etc/HOSTNAME
nano /etc/hosts

# Grab Slackware Setup Scripts by gosh-its-arch-linux
git clone https://gitlab.com/gosh-its-arch-linux/slackware-scripts.git
cd slackware-scripts
cd Slackware15
chmod +x *.sh
# Set up Slackware User, init level 4
# ./setup_script
# Set Slackpkg Mirrors to US and update cache
./update_mirror_and_pkgs.sh
# Run Full Update & update grub
./update_slackware.sh
grub-mkconfig -o /boot/grub/grub.cfg
# Install and configure sbopkg and sbotools
./install_sbopkg_and_sbotools.sh
cd ../..
rm -rf slackware-scripts/

# Blacklist Ponce's repo & SBo packages
if ! grep -q "^\[0-9\]+_SBo$" /etc/slackpkg/blacklist; then
    echo '[0-9]+_SBo' | tee -a /etc/slackpkg/blacklist
fi
if ! grep -q "^\[0-9\]+ponce$" /etc/slackpkg/blacklist; then
    echo '[0-9]+ponce' | tee -a /etc/slackpkg/blacklist
fi
if ! grep -q "^\[0-9\]+_csb$" /etc/slackpkg/blacklist; then
    echo '[0-9]+_csb' | tee -a /etc/slackpkg/blacklist
fi

# Point sbopkg to current repo
sed -i "s/REPO_BRANCH=\${REPO_BRANCH:-15.0}/REPO_BRANCH=\${REPO_BRANCH:-current}/g" /etc/sbopkg/sbopkg.conf
sed -i "s/REPO_NAME=\${REPO_NAME:-SBo}/REPO_NAME=\${REPO_NAME:-SBo-git}/g" /etc/sbopkg/sbopkg.conf

# Install slackpkg+ & configure
url="https://sourceforge.net/projects/slackpkgplus/files/slackpkg%2B-1.8.0-noarch-7mt.txz/download"
wget -O slackpkg+.txz "$url"
installpkg slackpkg+.txz
sed -i 's/TAG_PRIORITY=off/TAG_PRIORITY=on/g' /etc/slackpkg/slackpkgplus.conf
slackpkg update gpg
slackpkg install-new
rm slackpkg+.txz

# Install Bottom
cargo install bottom --locked

# Install Neovim AppImage
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
chmod u+x nvim.appimage
./nvim.appimage --appimage-extract
./squashfs-root/AppRun --version
mv squashfs-root /
ln -s /squashfs-root/AppRun /usr/bin/nvim
rm nvim.appimage

# Install rmlint
git clone https://github.com/sahib/rmlint.git
cd rmlint/
scons --prefix=/usr install
cd ..
rm -rf rmlint/
<<com
# Install Cinnamon
git clone https://github.com/CinnamonSlackBuilds/csb
cd csb/
# Check if the Mint entries exist in the build-cinnamon.sh file
if grep -q "mint-y-icons\|mint-l-icons\|mint-themes\|mint-cursor-themes" build-cinnamon.sh; then
    # Remove the Mint entries
    sed -i '/mint-y-icons\|mint-l-icons\|mint-themes\|mint-cursor-themes/d' build-cinnamon.sh
fi
./build-cinnamon.sh
cd ..
rm -rf csb/
xwmconfig
com
# Update sbo just to be sure
sbocheck
sboupgrade --all

# For pcsc-lite dependency that gets called in
groupadd -g 257 pcscd
useradd -u 257 -g pcscd -d /var/run/pcscd -s /bin/false pcscd

# All packages
packages=(
    # System utilities
    "file-roller"
    "flatpak"
    "gparted"
    "ncdu"
    #"neofetch"
    "timeshift"
    #"unzip" 
    #"xkill" 
    #"xrandr"
    # Network utilities
    "filezilla"
    #"gvfs"
    #"kdeconnect"
    #"samba"
    # Desktop environment and related packages
    #"cinnamon"
    #"eog" #using Geeqie instead
    #"evince" #using okular instead
    "gdm"
    #"gnome-calculator" #using kcalc instead
    "gnome-screenshot"
    "gnome-system-monitor"
    "gnome-terminal"
    "gui-ufw"
    "kvantum-qt5"
    "mpv"
    "qt5ct"
    "qt6ct"
    "rhythmbox"
    # Applications
    "bleachbit"
    "brave-browser"
    "clipit"
    "libreoffice"
    "qbittorrent"
    #"noto-fonts"
    "noto-emoji"
    "xclip"
    # For NvChad
    #"gcc"
    #"make"
    "ripgrep"
    # Virtualization tools
    "libslirp"
    "libiscsi"
    "libcacard"
    "spice"
    "spice-vdagent"
    "usbredir"
    "virglrenderer"
    "libnfs"
    "snappy"
    "device-tree-compiler"
    "glusterfs"
    "vde2"
    "qemu"
    "spice-gtk"
    "gtk-vnc"
    "libvirt"
    "libvirt-glib"
    "libvirt-python"
    "libosinfo"
    "edk2-ovmf"
    "virt-manager"
    #"dnsmasq" # This package and below is already there
    #"bridge-utils"
    #"iptables"
    #"dmidecode"
)

# Update system and install packages
sboinstall "${packages[@]}"

# Enable Flathub
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
<<com
# Preserve old libvirtd configuration (for Virtual Machine Manager)
cp /etc/libvirt/libvirtd.conf /etc/libvirt/libvirtd.conf.old

# Check for 'unix_sock_group' entry
if ! grep -q "^unix_sock_group = \"users\"$" /etc/libvirt/libvirtd.conf; then
    echo 'unix_sock_group = "users"' | tee -a /etc/libvirt/libvirtd.conf
else
    sed -i '/^#*unix_sock_group = "users"/s/^#*//' /etc/libvirt/libvirtd.conf
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
com
# Enable and start the libvirtd and spice-vdagent service *
sh /etc/rc.d/rc.spice-vdagent start
sh /etc/rc.d/rc.libvirt start

# Start and autostart the default network
# virsh net-start default
# virsh net-autostart default

# Add the current user to the necessary groups
groups=(libvirt libvirt-qemu kvm input disk video audio users)
for group in "${groups[@]}"; do
    usermod -aG "$group" "$username"
done

# Modify systemd configuration to change the default timeout for stopping services during shutdown, preserving old one
# cp /etc/systemd/system.conf /etc/systemd/system.conf.old
# sed -i 's/^#DefaultTimeoutStopSec=.*/DefaultTimeoutStopSec=15s/' /etc/systemd/system.conf

# Reload the systemd configuration
# systemctl daemon-reload

# Run the setup script
# cd home/
# chmod +x Setup-Slackware-Theme.sh
# ./Setup-Slackware-Theme.sh
# cd ..

# Reboot for the changes to take effect
echo "Installation complete! Please reboot for the changes to take effect. Then run Setup-Slackware-Theme.sh in cinnamon/home for theming."
