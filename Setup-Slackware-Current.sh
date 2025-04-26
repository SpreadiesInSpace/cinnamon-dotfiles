#!/bin/bash

# Source common functions
source ./Setup-Common.sh

# Check if the script is run as root
check_if_root

# Check if the script is run from the root account
check_if_not_root_account

# Get the current username
get_current_username

# Autologin Prompt
prompt_for_autologin

# VM Prompt
prompt_for_vm

# Display Status from Prompts
display_status "$enable_autologin" "$is_vm"

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

# Declare Config Files
declare -A files=(
    ["https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles/main/etc/slpkg/repositories.toml"]="/etc/slpkg/repositories.toml"
    ["https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles/main/etc/slpkg/slpkg.toml"]="/etc/slpkg/slpkg.toml"
    ["https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles/main/etc/slpkg/blacklist.toml"]="/etc/slpkg/blacklist.toml"
    ["https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles/main/etc/slackpkg/blacklist"]="/etc/slackpkg/blacklist"
    ["https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles/main/etc/slackpkg/mirrors"]="/etc/slackpkg/mirrors"
)

# Replace slpkg and slackpkg configs
timestamp=$(date +%s)
for url in "${!files[@]}"; do
    local_path="${files[$url]}"

    if [ -f "$local_path" ]; then
        cp "$local_path" "${local_path}.old.${timestamp}" || { echo "Failed to backup $local_path"; exit 1; }
    fi
    if curl -fsSL -o "$local_path" "$url"; then
        echo "File $local_path updated successfully."
    else
        echo "Failed to download $url"
        [ -f "${local_path}.old.${timestamp}" ] && mv "${local_path}.old.${timestamp}" "$local_path"
        exit 1
    fi
done

# Update MAKEFLAGS in /etc/slpkg/slpkg.toml to match CPU cores
cores=$(nproc)
# Backup the current slpkg.toml file
timestamp=$(date +%s)
cp /etc/slpkg/slpkg.toml /etc/slpkg/slpkg.toml.old.${timestamp}
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

# Enable Flathub for Flatpak
enable_flathub

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
manage_virsh_network "slackware"

# Add the current user to the necessary groups
add_user_to_groups kvm input disk video audio users

# Backup original rc.4
timestamp=$(date +%s)
cp /etc/rc.d/rc.4 "/etc/rc.d/rc.4.old.${timestamp}"

# Run LightDM on Boot
if ! grep -q 'exec /usr/bin/lightdm' /etc/rc.d/rc.4; then
  sed -i '/# Try to use GNOME'\''s gdm session manager/i\
# Try to use LightDM session manager:\nif [ -x /usr/bin/lightdm ]; then\n  exec /usr/bin/lightdm\nfi\n' /etc/rc.d/rc.4
fi

# Backup original LightDM config
backup_lightdm_config

# Modify lightdm.conf in-place
modify_lightdm_conf "slackware"

# Ensure autologin group exists and add user
ensure_autologin_group

# If running in a VM, set display-setup-script in lightdm.conf
set_lightdm_display_for_vm

# Add flag for Setup-Theme.sh
add_setup_theme_flag "slackware"

# Display Reboot Message
print_reboot_message
