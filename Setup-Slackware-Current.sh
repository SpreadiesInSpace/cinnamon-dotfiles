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

# Autologin Prompt
read -rp "Enable autologin for $username? [y/N]: " autologin_input
case "$autologin_input" in
    [yY][eE][sS]|[yY])
        enable_autologin=true
        ;;
    *)
        enable_autologin=false
        ;;
esac

# VM Prompt
read -rp "Is this a Virtual Machine? [y/N]: " response
case "$response" in
    [yY][eE][sS]|[yY])
        is_vm=true
        ;;
    *)
        is_vm=false
        ;;
esac

# Install sbopkg (for sbotools)
wget -c -T 10 -t 10 -q --show-progress https://github.com/sbopkg/sbopkg/releases/download/0.38.3/sbopkg-0.38.3-noarch-1_wsr.tgz
installpkg sbopkg-0.38.3-noarch-1_wsr.tgz
rm sbopkg-0.38.3-noarch-1_wsr.tgz
# Point sbopkg to current repo & sync
sed -i "s/REPO_BRANCH=\${REPO_BRANCH:-15.0}/REPO_BRANCH=\${REPO_BRANCH:-current}/g" /etc/sbopkg/sbopkg.conf
sed -i "s/REPO_NAME=\${REPO_NAME:-SBo}/REPO_NAME=\${REPO_NAME:-SBo-git}/g" /etc/sbopkg/sbopkg.conf
# Sync repo
sbopkg -r

# Install sbotools (for slpkg)
sbopkg -i sbotools
sboconfig -r https://github.com/Ponce/slackbuilds.git
# Sync repo
sbosnap fetch
# Update MAKEFLAGS in /etc/sbotools/sbotools.conf to match CPU cores
sboconfig -j $(nproc)

# For Virt-Manager & accessing samba shares (15.0 needs dnsmasq and samba)
cp /etc/samba/smb.conf-sample /etc/samba/smb.conf
sh /etc/rc.d/rc.samba start

# Install slpkg
packages=("python3-poetry-core" "python3-tomlkit" "python3-pythondialog" "slpkg")
for package in "${packages[@]}"; do
  # Install headlessly but fallback to prompt if any package fails
  if ! sboinstall -r "$package"; then
    echo "Install failed for $package, falling back to prompt..."
    sboinstall "$package"
  fi
done

# Replace slpkg and slackpkg configs
declare -A files=(
    ["https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles/main/etc/slpkg/repositories.toml"]="/etc/slpkg/repositories.toml"
    ["https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles/main/etc/slpkg/slpkg.toml"]="/etc/slpkg/slpkg.toml"
    ["https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles/main/etc/slpkg/blacklist.toml"]="/etc/slpkg/blacklist.toml"
    ["https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles/main/etc/slackpkg/blacklist"]="/etc/slackpkg/blacklist"
    ["https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles/main/etc/slackpkg/mirrors"]="/etc/slackpkg/mirrors"
)
for url in "${!files[@]}"; do
    local_path="${files[$url]}"
    # Backup the existing local file
    cp "$local_path" "${local_path}.old"    
    # Download the new file
    curl -o "$local_path" "$url"    
    # Verify the download was successful
    if [ $? -eq 0 ]; then
        echo "File $local_path updated successfully."
    else
        echo "Failed to update the file $local_path."
        mv "${local_path}.old" "$local_path"
    fi
done

# Update MAKEFLAGS in /etc/slpkg/slpkg.toml to match CPU cores
cores=$(nproc)
# Backup the current slpkg.toml file
cp /etc/slpkg/slpkg.toml /etc/slpkg/slpkg.toml.bak
# Edit slpkg.toml to set MAKEFLAGS
sed -i "s/^MAKEFLAGS = \"-j[0-9]*\"/MAKEFLAGS = \"-j$cores\"/" /etc/slpkg/slpkg.toml
echo "Updated MAKEFLAGS in /etc/slpkg/slpkg.toml to -j$cores based on the number of CPU cores."

# Sync slpkg 
slpkg -uy

# Update Slackware Packages
touch /var/log/slpkg/deps.log
slpkg -Uy -o "slack"
slpkg -Uy -o "slack_extra"

# Update Grub (in case Kernel Gets Updated)
grub-mkconfig -o /boot/grub/grub.cfg

# Install Bash Completion for csb
slpkg -iy bash-completion -o "slack_extra"

# Alien packages
alien_packages=(
    "libreoffice"
    "openjdk17" # for libreoffice
)

# Install packages from Alien over SBo to reduce compile times
slpkg -iy "${alien_packages[@]}" -o alien -O

# All packages
packages=(
    # System utilities
    #"gparted"
    #"neofetch"
    #"unzip"
    #"xkill"
    #"xrandr"
    # Network utilities
    "filezilla"
    "libfilezilla" # for filezilla
    "libmspack" # for filezilla
    "pugixml" # for filezilla
    "wxwidgets" # for filezilla
    #"gvfs"
    #"kdeconnect"
    #"samba"
    # Desktop environment and related packages
    #"cinnamon"
    "qt5ct"
    # Applications
    "bleachbit"
    #"noto-fonts"
    #"noto-emoji"
    "qbittorrent"
    "libtorrent-rasterbar"
    "ufw"
    "xclip"
    # For NvChad
    #"gcc"
    #"make"
    "neovim"
    "luv" # for neovim
    "lua-lpeg" # for neovim
    "unibilium" # for neovim
    # Virtualization tools
    "libslirp"
    "libcacard"
    "spice"
    "usbredir"
    "virglrenderer"
    "libnfs"
    "snappy"
    "device-tree-compiler"
    "vde2"
    "spice-gtk"
    "gtk-vnc"
    "libosinfo"
    "edk2-ovmf-bin"
    #"dnsmasq"
    #"bridge-utils"
    #"iptables"
    #"dmidecode"
    "spice-vdagent"
    "libvirt"
    "libvirt-glib"
    "libvirt-python"
    "audit"
    "virtiofsd"    
    "yajl"
    "virt-manager"
)

# Install packages from Conraid over SBo to reduce compile times
slpkg -iy "${packages[@]}" -o conraid

# GFS packages
gnome_packages=(
    "eog"
    "evince"
    "flatpak"
    "malcontent" # for flatpak
    "gedit"
    "libgedit-amtk" # for gedit
    "libgedit-gtksourceview" # for gedit
    "libpeas" # for gedit
    "gnome-disk-utility"
    "gpaste"
    # "libportal" # for file-roller
    #"rhythmbox" # using Elisa instead
    #"totem-pl-parser" # for rhythmbox
)

# Install packages from GFS over SBo to reduce compile times
slpkg -iy "${gnome_packages[@]}" -o gnome
# Replace Slackware Current's appstream-glib with gfs for file-roller
# -O avoids pulling in dependencies like the entire Gnome DE
slpkg -iy appstream-glib gnome-terminal -o gnome -O

# Add LightDM group
groupadd -g 380 lightdm
useradd -d /var/lib/lightdm -s /bin/false -u 380 -g 380 lightdm

# SBo packages
sbo_packages=(
    "file-roller"
    "gnome-calculator"
    "gnome-screenshot"
    "gnome-system-monitor"
    "kvantum-qt5"
    "haruna"
    "lightdm"
    "lightdm-settings"
    "lightdm-slick-greeter"
    "ncdu"
    "qt6ct"
    "tepl" # for gedit
    "timeshift"
    #"libuchardet" # for rhythmbox
    "brave-browser"
    "ripgrep"
    #"qemu" # TARGETS=x86_64-softmmu
    "libiscsi"
    "glusterfs"
)

# Install Packages
slpkg -iy "${sbo_packages[@]}"
slpkg -iy bottom # prevent download timeout

# Install Self-Compiled qemu from SBo
git clone https://github.com/spreadiesinspace/qemu
cd qemu/
./install.sh
cd ..
rm -rf qemu/

# Slint packages
slint_packages=(
    "kvantum-qt6" # for qBittorrent
    "kwindowsystem6" # for kvantum-qt6
    "md4c" # for kvantum-qt6
)

# Install packages from Slint over SBo to reduce compile times
slpkg -iy "${slint_packages[@]}" -o slint -O

# Workaround for gedit-plugins to compile (broken)
# slpkg -iy libpeas gedit-plugins
# slpkg -iy libpeas -o gnome

# Install Cinnamon and Set Default DE System-Wide
slpkg -iy "*" -o csb
ln -sf /etc/X11/xinit/xinitrc.cinnamon-session /etc/X11/xinit/xinitrc
ln -sf /etc/X11/xinit/xinitrc.cinnamon-session /etc/X11/xsession
cp /etc/X11/xinit/xinitrc.cinnamon-session /root/.xinitrc
cp /etc/X11/xinit/xinitrc.cinnamon-session /root/.xsession
chmod -x /root/.xinitrc
chmod -x /root/.xsession

# Enable Flathub
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Start spice-vdagent service (it already autostarts by default)
/etc/rc.d/rc.spice-vdagent start

# Check if the block for libvirt already exists
if ! grep -q '# Start libvirt' /etc/rc.d/rc.local; then
  # Add libvirt startup to rc.local if not already present
  echo '' >> /etc/rc.d/rc.local
  echo '# Start libvirt' >> /etc/rc.d/rc.local
  echo 'if [ -x /etc/rc.d/rc.libvirt ]; then' >> /etc/rc.d/rc.local
  echo '  /etc/rc.d/rc.libvirt start' >> /etc/rc.d/rc.local
  echo 'fi' >> /etc/rc.d/rc.local
fi
# Make sure rc.libvirt is executable
chmod +x /etc/rc.d/rc.libvirt
# Start libvirtd service
/etc/rc.d/rc.libvirt start

# Only enable net-autostart if in physical machine
if [ "$is_vm" = false ]; then
    virsh net-autostart default
    virsh net-start default
else
    # Disable autostart and destroy the network if running
    virsh net-autostart default --disable
    rm -f /etc/libvirt/qemu/networks/autostart/default.xml
    if virsh net-info default | grep -q "Active:.*yes"; then
        virsh net-destroy default
    fi
    # Restart libvirtd to ensure clean state
    /etc/rc.d/rc.libvirt restart
fi

# Add the current user to the necessary groups
groups=(kvm input disk video audio users)
for group in "${groups[@]}"; do
    usermod -aG "$group" "$username"
done

# Backup original rc.4
cp /etc/rc.d/rc.4 /etc/rc.d/rc.4.old

# Run LightDM on Boot
if ! grep -q 'exec /usr/bin/lightdm' /etc/rc.d/rc.4; then
  sed -i '/# Try to use GNOME'\''s gdm session manager/i\
# Try to use LightDM session manager:\nif [ -x /usr/bin/lightdm ]; then\n  exec /usr/bin/lightdm\nfi\n' /etc/rc.d/rc.4
fi

# Backup original LightDM config
cp /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.old

# Modify lightdm.conf in-place
awk -v user="$username" -v autologin="$enable_autologin" -i inplace '
/^\[Seat:\*\]/ {a=1}
a==1 && /^#?greeter-hide-users=/ {
    print "greeter-hide-users=false"
    next
}
a==1 && /^#?greeter-session=/ {
    print "greeter-session=lightdm-slick-greeter"
    next
}
a==1 && /^#?autologin-user=/ {
    if (autologin == "true") {
        print "autologin-user=" user
    } else {
        print "#autologin-user=" user
    }
    next
}
a==1 && /^#?autologin-session=/ {
    print "autologin-session=cinnamon"
    next
}
{print}
' /etc/lightdm/lightdm.conf

# Ensure autologin group exists and add user
groupadd -f autologin
gpasswd -a "$username" autologin

# If running in a VM, set display-setup-script in lightdm.conf
if [ "$is_vm" = true ]; then
    # Detect connected output using sysfs (avoids X dependency)
    output_path=$(grep -l connected /sys/class/drm/*/status | head -n1)
    output=$(basename "$(dirname "$output_path")")
    output="${output#*-}"  # Strip 'cardX-' prefix
    if [[ -n "$output" ]]; then
        sed -i "/^\[Seat:\*\]/,/^\[.*\]/ {
            s|^#*display-setup-script=.*|display-setup-script=xrandr --output $output --mode 1920x1080 --rate 60|
        }" /etc/lightdm/lightdm.conf
    fi
fi

# Add flag for Setup-Theme.sh
CURRENT_DIR=$(pwd)
su - "$SUDO_USER" -c "touch '$CURRENT_DIR/.slackware.done'"

# Reboot for the changes to take effect
echo "Installation complete! Please reboot for the changes to take effect. Then run Theme.sh in cinnamon-dotfiles for theming."
