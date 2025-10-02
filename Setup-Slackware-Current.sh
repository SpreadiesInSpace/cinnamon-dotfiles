#!/bin/bash

# Source common functions
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }
[ -f ./Setup-Common.sh ] || die "Setup-Common.sh not found."
source ./Setup-Common.sh || die "Failed to source Setup-Common.sh"

# Declare variables that will be set by sourced functions
declare enable_autologin is_vm

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
SBO="https://github.com/sbopkg/sbopkg/releases/download/0.38.3"
SBO="$SBO/sbopkg-0.38.3-noarch-1_wsr.tgz"
wget -c -T 10 -t 10 -q --show-progress "$SBO" || \
  die "Failed to download sbopkg package."
installpkg sbopkg-0.38.3-noarch-1_wsr.tgz || \
  die "Failed to install sbopkg package."
rm sbopkg-0.38.3-noarch-1_wsr.tgz || \
  die "Failed to remove sbopkg package file."

# Point sbopkg to current repo & sync
SBO_CONF="/etc/sbopkg/sbopkg.conf"
sed -i "s/REPO_BRANCH=\${REPO_BRANCH:-15.0}/REPO_BRANCH=\${REPO_BRANCH:-current}/g" \
  "$SBO_CONF" || \
  die "Failed to update REPO_BRANCH."
sed -i "s/REPO_NAME=\${REPO_NAME:-SBo}/REPO_NAME=\${REPO_NAME:-SBo-git}/g" \
  "$SBO_CONF" || \
  die "Failed to update REPO_NAME."
retry sbopkg -r || \
  die "Failed to sync sbopkg repository."

# Install sbotools (for slpkg)
retry sbopkg -B -i sbotools || \
  die "Failed to install sbotools."
sboconfig -r https://github.com/Ponce/slackbuilds.git || \
  die "Failed to configure sbotools repository."
retry sbosnap fetch || \
  die "Failed to fetch sbosnap."

# Update MAKEFLAGS in /etc/sbotools/sbotools.conf to match CPU cores
cores=$(nproc)
sboconfig -j "$cores" || \
  die "Failed to update sbotools configuration with CPU cores."

# For Virt-Manager & accessing samba shares (15.0 needs dnsmasq and samba)
cp /etc/samba/smb.conf-sample /etc/samba/smb.conf || \
  die "Failed to copy Samba config."
sh /etc/rc.d/rc.samba start || \
  die "Failed to start Samba service."

# Install slpkg
packages=(
  "python3-poetry-core"
  "python3-tomlkit"
  "python3-pythondialog"
  "slpkg"
)
for package in "${packages[@]}"; do
  # Install headlessly but fallback to prompt if any package fails
  if ! retry sboinstall -r "$package"; then
    echo "Install failed for $package, falling back to prompt..."
    retry sboinstall "$package" || \
      die "Failed to install $package."
  fi
done

# Declare Config Files
CONFIG="https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles"
declare -A files=(
  ["$CONFIG/main/etc/slpkg/repositories.toml"]="/etc/slpkg/repositories.toml"
  ["$CONFIG/main/etc/slpkg/slpkg.toml"]="/etc/slpkg/slpkg.toml"
  ["$CONFIG/main/etc/slpkg/blacklist.toml"]="/etc/slpkg/blacklist.toml"
  ["$CONFIG/main/etc/slackpkg/blacklist"]="/etc/slackpkg/blacklist"
  ["$CONFIG/main/etc/slackpkg/mirrors"]="/etc/slackpkg/mirrors"
)

# Replace slpkg and slackpkg configs
timestamp=$(date +%s)
for url in "${!files[@]}"; do
  local_path="${files[$url]}"

  if [ -f "$local_path" ]; then
    cp "$local_path" "${local_path}.old.${timestamp}" || \
      die "Failed to backup $local_path."
  fi
  if retry curl -fsSL -o "$local_path" "$url"; then
    echo "File $local_path updated successfully."
  else
    echo "Failed to download $url."
    [ -f "${local_path}.old.${timestamp}" ] && \
      mv "${local_path}.old.${timestamp}" "$local_path"
    exit 1
  fi
done

# Update MAKEFLAGS in /etc/slpkg/slpkg.toml to match CPU cores
cores=$(nproc)
# Backup the current slpkg.toml file
timestamp=$(date +%s)
cp /etc/slpkg/slpkg.toml /etc/slpkg/slpkg.toml.old."${timestamp}" || \
  die "Failed to backup /etc/slpkg/slpkg.toml."
# Edit slpkg.toml to set MAKEFLAGS
sed -i "s/^MAKEFLAGS = \"-j[0-9]*\"/MAKEFLAGS = \"-j$cores\"/" \
  /etc/slpkg/slpkg.toml || \
    die "Failed to update MAKEFLAGS in /etc/slpkg/slpkg.toml."
echo "Updated MAKEFLAGS in /etc/slpkg/slpkg.toml to -j$cores based on the \
number of CPU cores."

# Sync slpkg
retry slpkg update || \
  die "Failed to sync slpkg."

# Update Slackware Packages
touch /var/log/slpkg/deps.log || true
retry slpkg upgrade -y -o "slack" || \
  die "Failed to update slack packages."
retry slpkg upgrade -y -o "slack_extra" || \
  die "Failed to update slack_extra packages."

# Update Bootloader Entries (in case Kernel Gets Updated)
if [ -f /etc/lilo.conf ]; then
  echo "Detected LILO bootloader."
  lilo || die "Failed to update LILO configuration."
elif [ -f /boot/efi/EFI/Slackware/elilo.conf ] || \
  [ -f /boot/efi/EFI/ELILO/elilo.conf ]; then
  echo "Detected ELILO bootloader."
  eliloconfig || die "Failed to update ELILO configuration."
elif command -v grub-mkconfig >/dev/null 2>&1; then
  echo "Detected GRUB bootloader."
  grub-mkconfig -o /boot/grub/grub.cfg || \
    die "Failed to generate GRUB config."
else
  die "No recognized bootloader found."
fi

# Install Bash Completion for csb
retry slpkg install -y -P -B bash-completion -o "slack_extra" || \
  die "Failed to install bash-completion."

# Alien packages
alien_packages=(
  "libreoffice"
  "openjdk17" # for libreoffice
)

# Install packages from Alien over SBo to reduce compile times
retry slpkg install -y -P -B "${alien_packages[@]}" -o alien -O || \
  die "Failed to install alienbob packages."

# All packages
packages=(
  # System utilities
  #"gparted"
  #"neofetch"
  #"unzip"
  #"xkill"
  #"xrandr"
  # For Filezilla
  "libfilezilla"
  "libmspack"
  "pugixml"
  "wxwidgets"
  "filezilla"
  # Network utilities
  #"gvfs"
  #"kdeconnect"
  #"samba"
  # Applications
  "bleachbit"
  #"noto-fonts"
  #"noto-emoji"
  "qbittorrent"
  "libtorrent-rasterbar" # for qBittorrent
  "qt5ct"
  "ufw"
  "vscodium-bin"
  # For NvChad
  #"gcc"
  #"make"
  "xclip"
  # For Neovim
  "luv"
  "lua-lpeg"
  "unibilium"
  "neovim"
  # For Virt-Manager
  "libosinfo"
  "osinfo-db"
  "osinfo-db-tools"
  "yajl"
  "numactl"
  "libvirt"
  "libvirt-glib"
  "libvirt-python"
  "gtk-vnc"
  "spice"
  "spice-gtk"
  "spice-protocol"
  "spice-vdagent"
  "audit"
  "device-tree-compiler"
  #"bridge-utils"
  #"dmidecode"
  #"dnsmasq"
  #"iptables"
  "libcacard"
  "libslirp"
  "libnfs"
  "snappy"
  "usbredir"
  "vde2"
  "virglrenderer"
  "qemu" # TARGETS=x86_64-softmmu
  "libbpf" # for conraid's qemu
  "jack" # for conraid's qemu
  "virtiofsd"
  "edk2-ovmf-bin"
  "virt-manager"
)

# Install packages from Conraid over SBo to reduce compile times
retry slpkg install -y -P -B "${packages[@]}" -o conraid || \
  die "Failed to install conraid packages."

# GFS packages
gnome_packages=(
  "eog"
  "evince"
  "libgxps" # for evince
  "file-roller"
  "libportal" # for file-roller
  # For flatpak
  "libstemmer"
  "libxmlb"
  "malcontent"
  "flatpak"
  # For gedit
  "libgedit-amtk"
  "libgedit-gtksourceview"
  "libgedit-tepl"
  "libpeas"
  "gedit"
  "gedit-plugins"
  "gnome-calculator"
  "gnome-system-monitor"
  "gnome-disk-utility"
  "gpaste"
  # "rhythmbox" # using Elisa instead
)

# Install packages from GFS over SBo to reduce compile times
retry slpkg install -y -P -B "${gnome_packages[@]}" -o gnome || \
  die "Failed to install gnome packages."

# Add LightDM group
groupadd -g 380 lightdm || \
  die "Failed to create group 'lightdm'."
useradd -d /var/lib/lightdm -s /bin/false -u 380 -g 380 lightdm || \
  die "Failed to create user 'lightdm'."

# SBo packages
sbo_packages=(
  #"bottom"
  "brave-browser"
  "gnome-screenshot"
  "kvantum-qt5"
  "haruna"
  "lightdm"
  "lightdm-settings"
  "lightdm-slick-greeter"
  "ncdu"
  "qt6ct"
  "timeshift"
  "ripgrep" # for neovim
  "libiscsi" # for Virt-Manager
  "glusterfs" # for Virt-Manager
)

# Install Packages
retry slpkg install -y -P -B "${sbo_packages[@]}" || \
  die "Failed to install SBo packages."

# Install bottom seperately to prevent download fails.
retry slpkg install -y -P -B bottom || \
  die "Failed to install bottom."

# Slint packages
slint_packages=(
  "kvantum-qt6" # for qBittorrent
  "kwindowsystem6" # for kvantum-qt6
  "md4c" # for kvantum-qt6
)

# Install packages from Slint over SBo to reduce compile times
retry slpkg install -y -P -B "${slint_packages[@]}" -o slint -O || \
  die "Failed to install slint packages."

# Install Cinnamon, LightDM and set Default DE System-Wide
retry slpkg install -y -P -B '*' -o csb || die "Failed to install Cinnamon"
ln -sf /etc/X11/xinit/xinitrc.cinnamon-session /etc/X11/xinit/xinitrc || \
  die "Failed to create symlink for xinitrc."
ln -sf /etc/X11/xinit/xinitrc.cinnamon-session /etc/X11/xsession || \
  die "Failed to create symlink for xsession."
cp /etc/X11/xinit/xinitrc.cinnamon-session /root/.xinitrc || \
  die "Failed to copy xinitrc to /root."
cp /etc/X11/xinit/xinitrc.cinnamon-session /root/.xsession || \
  die "Failed to copy xsession to /root."
chmod -x /root/.xinitrc || \
  die "Failed to modify permissions for /root/.xinitrc."
chmod -x /root/.xsession || \
  die "Failed to modify permissions for /root/.xsession."

# Set polkit permissions for wheel group users
set_polkit_perms

# Temporary mozjs128 fix for Cinnamon
bash unsorted/Slackware/mozjs128.sh

# Enable Flathub for Flatpak
enable_flathub

# Start spice-vdagent service (it already autostarts by default)
/etc/rc.d/rc.spice-vdagent start || \
  die "Failed to start spice-vdagent service."

# Check if the block for libvirt already exists
if ! grep -q '# Start libvirt' /etc/rc.d/rc.local; then
  # Add libvirt startup to rc.local if not already present
  echo '' >> /etc/rc.d/rc.local || \
    die "Failed to append to /etc/rc.d/rc.local"
  echo '# Start libvirt' >> /etc/rc.d/rc.local || \
    die "Failed to add '# Start libvirt' to /etc/rc.d/rc.local"
  echo 'if [ -x /etc/rc.d/rc.libvirt ]; then' >> /etc/rc.d/rc.local || \
    die "Failed to add check for rc.libvirt to /etc/rc.d/rc.local"
  echo '  /etc/rc.d/rc.libvirt start' >> /etc/rc.d/rc.local || die \
    "Failed to add libvirt start command to /etc/rc.d/rc.local"
  echo 'fi' >> /etc/rc.d/rc.local || \
    die "Failed to close if condition in /etc/rc.d/rc.local"
fi

# Make sure rc.libvirt is executable
chmod +x /etc/rc.d/rc.libvirt || \
  die "Failed to make /etc/rc.d/rc.libvirt executable."

# Start libvirtd service
echo "Enabling services..."
/etc/rc.d/rc.libvirt start >/dev/null 2>&1 || \
  die "Failed to start libvirtd service."

# Only enable net-autostart if in physical machine
manage_virsh_network "slackware"

# Add the current user to the necessary groups
add_user_to_groups kvm input disk video audio users

# Backup original rc.4
timestamp=$(date +%s)
cp /etc/rc.d/rc.4 "/etc/rc.d/rc.4.old.${timestamp}" || \
  die "Failed to backup /etc/rc.d/rc.4"

# Run LightDM on Boot
if ! grep -q 'exec /usr/bin/lightdm' /etc/rc.d/rc.4; then
  {
    echo "# Try to use LightDM session manager:"
    echo "if [ -x /usr/bin/lightdm ]; then"
    echo "  exec /usr/bin/lightdm"
    echo "fi"
    echo ""
  } > /tmp/lightdm_block
  sed -i '/# Try to use GNOME'\''s gdm session manager/r /tmp/lightdm_block' \
    /etc/rc.d/rc.4 || \
    die "Failed to modify /etc/rc.d/rc.4 to include LightDM."
  rm -f /tmp/lightdm_block
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
