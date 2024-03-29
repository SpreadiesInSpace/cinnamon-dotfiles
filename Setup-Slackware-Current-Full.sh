#!/bin/bash

# Get the current username
username=$(whoami)

# Review Hostname
sudo nano /etc/HOSTNAME
sudo nano /etc/hosts

# Grab Slackware Setup Scripts by gosh-its-arch-linux
git clone https://gitlab.com/gosh-its-arch-linux/slackware-scripts.git
cd slackware-scripts
# Can do either Current or Slackware 15.0
# cd Slackware15
cd Current
chmod +x *.sh
# Set up Slackware User, init level 4
# sudo ./setup_script
# Set Slackpkg Mirrors and update cache
# Switch from US to China Mirror *
# sed -i 's|TARGET_MIRROR="http://mirrors.us.kernel.org/slackware/slackware64-current"|#TARGET_MIRROR="http://mirrors.us.kernel.org/slackware/slackware64-current"|g' update_mirror_and_pkgs.sh
# awk '/TARGET_MIRROR="http:\/\/mirrors.us.kernel.org\/slackware\/slackware64-current"/{print;print "TARGET_MIRROR=\"http:\/\/mirrors.ustc.edu.cn\/slackware\/slackware64-current\"";next}1' update_mirror_and_pkgs.sh > temp && mv temp update_mirror_and_pkgs.sh
# nano update_mirror_and_pkgs.sh
sudo ./update_mirror_and_pkgs.sh
# Run Full Update & update grub
sudo ./update_slackware.sh
sudo grub-mkconfig -o /boot/grub/grub.cfg
# Install and configure sbopkg and sbotools
sudo ./install_sbopkg_and_sbotools.sh
cd ../..
rm -rf slackware-scripts/

# Blacklist Ponce's repo
if ! grep -q "^\[0-9\]+ponce$" /etc/slackpkg/blacklist; then
    echo '[0-9]+ponce' | sudo tee -a /etc/slackpkg/blacklist
fi

# Install slackpkg+ & configure
url="https://sourceforge.net/projects/slackpkgplus/files/slackpkg%2B-1.8.0-noarch-7mt.txz/download"
wget -O slackpkg+.txz "$url"
sudo installpkg slackpkg+.txz
sudo sed -i 's/TAG_PRIORITY=off/TAG_PRIORITY=on/g' /etc/slackpkg/slackpkgplus.conf
sudo slackpkg update gpg
sudo slackpkg install-new
<<com
# Install Cinnamon
git clone https://github.com/CinnamonSlackBuilds/csb
cd csb/
# Check if the Mint entries exist in the build-cinnamon.sh file
if grep -q "mint-y-icons\|mint-l-icons\|mint-themes\|mint-cursor-themes" build-cinnamon.sh; then
    # Remove the Mint entries
    sed -i '/mint-y-icons\|mint-l-icons\|mint-themes\|mint-cursor-themes/d' build-cinnamon.sh
fi
sudo ./build-cinnamon.sh
cd ..
sudo rm -rf csb/
xwmconfig

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

# All packages
packages=(
    # System utilities
    "file-roller"
    "flatpak"
    "gparted"
    "ncdu"
    #"neofetch""
    "timeshift"
    #"unzip" 
    #"xkill" 
    #"xrandr"
    # Network utilities
    "filezilla"
    #"gvfs"
    #"kdeconnect"
    "samba"
    # Desktop environment and related packages
    #"cinnamon"
    "celluloid"
    #"eog" #using Geeqie instead
    #"evince" #using okular instead
    "gdm"
    #"gnome-calculator" #using kcalc instead
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
    "clipit"
    "libreoffice"
    "qbittorrent"
    "spice-vdagent"
    #"noto-fonts"
    "noto-emoji"
    "xclip"
    # For NvChad
    #"gcc"
    #"make"
    "ripgrep"
    # Virtualization tools
    #"virt-manager" # Currently not working
    #"qemu"
    #"libvirt"
    #"edk2-ovmf"
    #"vde2"
    #"dnsmasq" # This package and below is already there
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

# Enable and start the libvirtd and spice-vdagent service *
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

# Set up theming for gdm
flatpak install -y io.github.realmazharhussain.GdmSettings
flatpak run io.github.realmazharhussain.GdmSettings
flatpak remove -y io.github.realmazharhussain.GdmSettings
flatpak remove -y --unused
<< #autologin
sudo cp -f home/Slackware/monitors.xml ~gdm/.config/monitors.xml
sudo chown $(id -u gdm):$(id -g gdm) ~gdm/.config/monitors.xml
sudo restorecon ~gdm/.config/monitors.xml
# Backs up old gdm custom.conf
sudo cp /etc/gdm/custom.conf /etc/gdm/custom.conf.old
# Use awk to add the configuration under the [daemon] section
sudo awk -i inplace '
BEGIN { RS=""; FS="\n" }
/^\[daemon\]/ {
    a=1
    print
    next
}
a==1 && /^#?AutomaticLoginEnable=/ {
    print "AutomaticLoginEnable=True"
    a=0
    next
}
a==1 && /^#?AutomaticLogin=/ {
    print "AutomaticLogin='"$username"'"
    a=0
    next
}
a==1 {
    print "AutomaticLoginEnable=True"
    print "AutomaticLogin='"$username"'"
    a=0
    next
}
{print}
' "/etc/gdm/custom.conf"

# Check if the entries were added, if not, append them
if ! grep -q "AutomaticLoginEnable=True" "/etc/gdm/custom.conf"; then
    echo "AutomaticLoginEnable=True" | sudo tee -a "/etc/gdm/custom.conf"
fi
if ! grep -q "AutomaticLogin='"$username"'" "/etc/gdm/custom.conf"; then
    echo "AutomaticLogin='"$username"'" | sudo tee -a "/etc/gdm/custom.conf"
fi
#autologin
# Modify systemd configuration to change the default timeout for stopping services during shutdown, preserving old one
# sudo cp /etc/systemd/system.conf /etc/systemd/system.conf.old
# sudo sed -i 's/^#DefaultTimeoutStopSec=.*/DefaultTimeoutStopSec=15s/' /etc/systemd/system.conf

# Reload the systemd configuration
# sudo systemctl daemon-reload

# Run the setup script
# cd home/
# chmod +x Setup-Slackware.sh
# ./Setup-Slackware.sh
# cd ..

# Reboot for the changes to take effect
echo "Installation complete! Please reboot for the changes to take effect. Then run Setup-Slackware.sh in cinnamon/home for theming."
