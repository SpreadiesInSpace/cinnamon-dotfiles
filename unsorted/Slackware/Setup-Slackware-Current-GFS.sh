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
cd Current
chmod +x *.sh
# Set up Slackware User, init level 4
# ./setup_script
# Set Slackpkg Mirrors to US and update cache
#./update_mirror_and_pkgs.sh
# Run Full Update & update grub
nano /etc/slackpkg/mirrors
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
if ! grep -q "^\[0-9\]+_wsr$" /etc/slackpkg/blacklist; then
    echo '[0-9]+_wsr' | tee -a /etc/slackpkg/blacklist
fi
if ! grep -q "^\[0-9\]+ponce$" /etc/slackpkg/blacklist; then
    echo '[0-9]+ponce' | tee -a /etc/slackpkg/blacklist
fi
if ! grep -q "^\[0-9\]+_lngn$" /etc/slackpkg/blacklist; then
     echo '[0-9]+_lngn' | tee -a /etc/slackpkg/blacklist
fi

# Point sbopkg to current repo
sed -i "s/REPO_BRANCH=\${REPO_BRANCH:-15.0}/REPO_BRANCH=\${REPO_BRANCH:-current}/g" /etc/sbopkg/sbopkg.conf
sed -i "s/REPO_NAME=\${REPO_NAME:-SBo}/REPO_NAME=\${REPO_NAME:-SBo-git}/g" /etc/sbopkg/sbopkg.conf

# Install slackpkg+ & configure
#url="https://sourceforge.net/projects/slackpkgplus/files/slackpkg%2B-1.8.0-noarch-7mt.txz/download"
#wget -O slackpkg+.txz "$url"
#installpkg slackpkg+.txz
#sed -i 's/TAG_PRIORITY=off/TAG_PRIORITY=on/g' /etc/slackpkg/slackpkgplus.conf
#MIRRORPLUS['csb']https://slackware.uk/csb/current/x86_64/
nano /etc/slackpkg/slackpkgplus.conf
slackpkg update gpg
slackpkg install-new
#rm slackpkg+.txz

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
<<csb
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
csb
# Update sbo just to be sure
sbocheck
sboupgrade --all

# For libdaemon dependency that gets called in
# groupadd -g 214 avahi
# useradd -u 214 -g 214 -c Avahi -d /dev/null -s /bin/false avahi

# For pcsc-lite dependency that gets called in
groupadd -g 257 pcscd
useradd -u 257 -g pcscd -d /var/run/pcscd -s /bin/false pcscd

# For Virt-Manager & accessing samba shares
# slackpkg install dnsmasq samba
cp /etc/samba/smb.conf-sample /etc/samba/smb.conf
sh /etc/rc.d/rc.samba start

# All Slackpkg packages
packages= (
    gdm-settings
    gtk-vnc
    gpaste
)

# Install Slackpkg packages
slackpkg install "${sbopackages[@]}"

# All Slackbuild packages
sbopackages=(
    # System utilities
    #"file-roller" #GFS
    #"flatpak" #GFS borked, dev haven't recompiled
    #"gparted"
    "ncdu"
    #"neofetch"
    "timeshift"
    #"unzip" #In GFS but symlinked
    #"xkill" 
    #"xrandr"
    # Network utilities
    #"filezilla" flatpak this, it takes long to compile
    #"gvfs"
    #"kdeconnect" #Not installed in GFS
    #"samba"
    # Desktop environment and related packages
    #"cinnamon"
    #"eog" #GFS
    #"evince" #GFS
    #"gdm" #GFS
    #"gdm-settings" #Not installed in GFS 
    #"gnome-calculator" #GFS
    #"gnome-screenshot" #GFS
    #"gnome-system-monitor" #GFS
    #"gnome-terminal" #GFS
    "ufw"
    #"kvantum-qt5" #use snuk
    "mpv"
    "qt5ct"
    "qt6ct"
    "rhythmbox"
    # Applications
    "bleachbit"
    "bottom"
    "brave-browser"
    #"gpaste" #Not installed in GFS
    "libreoffice"
    #"qbittorrent" flatpak this, it takes long to compile
    #"noto-fonts"
    #"fonts-noto-emoji" #GFS
    #"rmlint" compiling via SBo fails on Slackware Current
    "xclip"
    # For NvChad
    #"gcc"
    #"make"
    "ripgrep"
    # Virtualization tools
    #"libslirp" #GFS
    "libiscsi"
    #"libcacard" #GFS
    #"spice" #GFS
    "spice-vdagent"
    #"usbredir" #GFS
    #"virglrenderer" #GFS
    #"libnfs" #GFS
    #"snappy" #GFS
    #"device-tree-compiler" #GFS
    "glusterfs"
    #"vde2" #GFS
    #"qemu" #GFS
    "spice-gtk"
    #"gtk-vnc" #Not installed in GFS
    #"libvirt" #GFS
    #"libvirt-glib" #GFS
    #"libvirt-python" #GFS
    #"libosinfo" #GFS
    "edk2-ovmf"
    "virt-manager" 
    #"dnsmasq"
    #"bridge-utils"
    #"iptables"
    #"dmidecode"
)

# Install SBo packages
sboinstall "${sbopackages[@]}"

# Enable Flathub
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Install additional apps via Flathub
flatpak install -y org.filezillaproject.Filezilla
flatpak install -y org.qbittorrent.qBittorrent
flatpak install -y runtime/org.kde.KStyle.Kvantum/x86_64/5.15-23.08

# Enable and start the libvirtd and spice-vdagent service *
sh /etc/rc.d/rc.spice-vdagent start
sh /etc/rc.d/rc.libvirt start

# Start and autostart the default network
virsh net-start default
virsh net-autostart default

# Add the current user to the necessary groups
groups=(libvirt libvirt-qemu kvm input disk video audio users)
for group in "${groups[@]}"; do
    usermod -aG "$group" "$username"
done

# Replace specific liness in sddm.conf
# sed -i "/\[Autologin\]/,/User=/ s/User=.*/User=$username/" /etc/sddm.conf
# sed -i "/\[Autologin\]/,/Session=/ s/Session=.*/Session=cinnamon/" /etc/sddm.conf

# Run the setup script
# cd home/
# chmod +x Setup-Slackware-Current-Theme.sh
# ./Setup-Slackware-Current-Theme.sh
# cd ..

# Reboot for the changes to take effect
echo "Installation complete! Please reboot for the changes to take effect. Then run Setup-Slackware-Current-Theme.sh in cinnamon/home for theming."
