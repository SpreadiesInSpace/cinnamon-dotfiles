#!/bin/bash
set -euo pipefail

# Download and source common functions
echo "Sourcing functions..."
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }
URL="https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles"
URL="$URL/main/extra/ISO/Install-Common.sh"
wget -qO Install-Common.sh "$URL" 2>/dev/null || \
  die "Failed to download Install-Common.sh"
[ -f ./Install-Common.sh ] || die "Install-Common.sh not found."
source ./Install-Common.sh || die "Failed to source Install-Common.sh"

# Check if script is run as root
check_if_root

# Detect if booted in UEFI or BIOS mode
detect_boot_mode

# Sync time and hardware clock
time_sync

# Auto-detect and mount installation media
SeTmedia || die "Failed to detect or mount installation media."
clear

# Install glibc-zoneinfo for timezone validation
installpkg /var/log/mount/slackware64/a/glibc-zoneinfo-*.t?z \
  >/dev/null 2>&1 || \
  die "Failed to install glibc-zoneinfo."

# Prompt for root password
prompt_root_password

# Prompt for new username
prompt_username

# Prompt for new user password
prompt_user_password

# Prompt for hostname
prompt_hostname

# Prompt for timezone
prompt_timezone

# Prompt for GRUB timeout
prompt_grub_timeout

# Prompt for drive to partition
prompt_drive

# Partition the drive
partition_drive

# Determine correct partition suffix
partition_suffix

# Format the partitions
format_partitions

# Create BTRFS subvolumes
create_btrfs_subvolumes

# Mount the partitions
mount_partitions

# Mount System Partitions
mount_system_partitions

# Re-mount ISO inside chroot
mkdir -p /mnt/var/log/mount || \
  die "Failed to mount installation media inside chroot."
mount --bind /var/log/mount /mnt/var/log/mount || \
  die "Failed to bind mount /var/log/mount to /mnt."

# Get list of package set directories
pkg_dirs=( /var/log/mount/slackware64/* )
[ ! -d "/var/log/mount/slackware64" ] && \
  die "Slackware package directory not found at /var/log/mount/slackware64."
package_sets=()
dir=""
for dir in "${pkg_dirs[@]}"; do
  [ -d "$dir" ] && package_sets+=("$(basename "$dir")")
done

# Prepare for full installation
echo "Starting full Slackware installation..."

# Get list of package sets (sorted alphabetically)
package_sets=()
for dir in /var/log/mount/slackware64/*; do
  [ -d "$dir" ] && package_sets+=("$(basename "$dir")")
done

# Sort using mapfile
mapfile -t package_sets < <(printf '%s\n' "${package_sets[@]}" | sort)

# Install all sets with overall progress
total_sets=${#package_sets[@]}; set_count=1; echo
for pkg_set in "${package_sets[@]}"; do
  pkg_set_cap="${pkg_set^^}"  # Capitalize package set name
  echo "[$set_count/$total_sets] Installing package set: $pkg_set_cap"
  pkg_files=( /var/log/mount/slackware64/"$pkg_set"/*.t?z )
  total_pkgs=${#pkg_files[@]}; pkg_count=1
  for pkg in "${pkg_files[@]}"; do
    pkg_name=$(basename "$pkg")
    printf "\r    [%s/%s] Installing: %-60s" \
      "$pkg_count" "$total_pkgs" "$pkg_name"
    retry installpkg --root /mnt "$pkg" >/dev/null 2>&1 || \
      die "Failed to install package $pkg_name."
    ((pkg_count++))
  done
  echo; ((set_count++))
done; echo

# Run post-installation configuration
echo "Running ldconfig..."
[ -x /mnt/sbin/ldconfig ] || \
  die "ldconfig not found or not executable at /mnt/sbin/ldconfig"
/mnt/sbin/ldconfig -r /mnt || \
  die "Failed to run ldconfig."

# Copy Network Info
[ ! -e /etc/resolv.conf ] && die "Source resolv.conf does not exist."
cp --dereference /etc/resolv.conf /mnt/etc/ || \
  die "Failed to copy resolv.conf."

# Copy common functions to chroot environment
cp Install-Common.sh Master-Common.sh /mnt/ || \
  die "Failed to copy Install-Common.sh to chroot."

# Define arch-install-scripts source and SlackBuild (for genfstab)
AIS="https://gitlab.archlinux.org/archlinux/arch-install-scripts"
AIS="$AIS/-/archive/v29/arch-install-scripts-v29.tar.gz"
AIS_SLACKBUILD="https://slackbuilds.org/slackbuilds/15.0"
AIS_SLACKBUILD="$AIS_SLACKBUILD/system/arch-install-scripts.tar.gz"

# Ensure variables are exported before chroot
export drive hostname timezone username rootpasswd userpasswd BOOTMODE \
  REMOVABLE_BOOT AIS AIS_SLACKBUILD grub_timeout || \
  die "Failed to export required variables."

# Entering Chroot
cat << EOF | chroot /mnt /bin/bash || die "Failed to enter chroot."

# Source common functions inside chroot
source Install-Common.sh || \
  { echo "Failed to source Install-Common.sh in chroot."; exit 1; }

# New Chroot
source /etc/profile || die "Failed to source /etc/profile."

# Run Post Install Scripts
/var/log/setup/setup.*.mkfontdir || die "Failed to run mkfontdir."
/var/log/setup/setup.*.fontconfig || die "Failed to run fontconfig."
/var/log/setup/setup.*.update-desktop-database || \
  die "Failed to run update-desktop-database."
/var/log/setup/setup.*.update-mime-database || \
  die "Failed to run update-mime-database."
/var/log/setup/setup.*.gtk-update-icon-cache || \
  die "Failed to run gtk-update-icon-cache."
/var/log/setup/setup.*.cacerts || die "Failed to run cacerts."
/var/log/setup/setup.cups-genppdupdate || \
  die "Failed to run cups-genppdupdate."
/var/log/setup/setup.htmlview || die "Failed to run htmlview."

# Set Timezone
ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime || \
  die "Failed to set timezone."
hwclock --systohc || die "Failed to set hardware clock."

# Configure GRUB Bootloader
install_grub

# Set GRUB timeout
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=$grub_timeout/' \
  /etc/default/grub || \
  die "Failed to set GRUB_TIMEOUT."

# Configure zRAM
configure_zram "slackware"

# Generate Grub Config
/var/log/setup/setup.*.mkinitrd || \
  die "Failed to make initrd and generate GRUB config."

# Disabled Services: atalk bind cups dnsmasq dovecot httpd inetd ip_forward
# mysqld nfsd ntpd openldap openvpn pcmcia pcscd postfix rpc saslauthd smartd
# snmpd

# List Default Services from Setup Menu
services=(
  atd
  avahidaemon
  avahidnsconfd
  crond
  fuse
  messagebus
  networkmanager
  samba
  syslog
  sshd
)

# Enable Selected Services (escape loop variables to evaluate inside chroot)
for svc in "\${services[@]}"; do
  svc_path="/etc/rc.d/rc.\$svc"
  if [ -f "\$svc_path" ]; then
    chmod +x "\$svc_path" || die "Failed to chmod +x \$svc_path."
  else
    die "Service script not found: \$svc_path."
  fi
done

# Download arch-install-scripts source and SlackBuild (for genfstab)
echo "Installing arch-install-scripts..."
retry wget -q "$AIS" \
  -O arch-install-scripts-v29.tar.gz || \
  die "Failed to download arch-install-scripts source."
retry wget -q "$AIS_SLACKBUILD" \
  -O arch-install-scripts-slackbuild.tar.gz || \
  die "Failed to download SlackBuild."

# Extract SlackBuild and move the source into place
tar -xf arch-install-scripts-slackbuild.tar.gz >/dev/null 2>&1 \
  || die "Failed to extract SlackBuild."
mv arch-install-scripts-v29.tar.gz arch-install-scripts/ \
  || die "Failed to move source tarball."

# Build, install and cleanup
cd arch-install-scripts || die "Missing arch-install-scripts directory"
./arch-install-scripts.SlackBuild >/dev/null 2>&1 || die "SlackBuild failed."
installpkg /tmp/arch-install-scripts-29-noarch-1_SBo.tgz >/dev/null 2>&1 || \
  die "installpkg failed"
cd .. && rm -rf arch-install-scripts* || \
  die "Cleanup for arch-install-scripts failed."

# Generate fstab
genfstab -U / > /etc/fstab || die "Failed to generate fstab."

# Remove zram swap entries from fstab
sed -i '/^# \/dev\/zram/d' /etc/fstab || \
  die "Failed to remove zram comment from fstab."
sed -i '/^\/dev\/zram.*swap/d' /etc/fstab || \
  die "Failed to remove zram entry from fstab."

# Append Essential Mounts
cat >> /etc/fstab << 'TAB' || die "Failed to append essential mounts to fstab."
#/dev/cdrom  /mnt/cdrom   auto    noauto,owner,ro,comment=x-gvfs-show  0 0
#/dev/fd0    /mnt/floppy  auto    noauto,owner                         0 0
devpts       /dev/pts     devpts  gid=5,mode=620                       0 0
proc         /proc        proc    defaults                             0 0
tmpfs        /dev/shm     tmpfs   nosuid,nodev,noexec                  0 0
TAB

# Set Hostname
echo "$hostname" > /etc/HOSTNAME || die "Failed to set hostname."

# Prevent software from unsafely resolving localhost over the network
echo "# For loopbacking.
127.0.0.1               localhost
::1                     localhost" | tee /etc/hosts > /dev/null || \
  die "Failed to write to /etc/hosts."

# Allow Resolving the Local Hostname
echo "127.0.1.1               $hostname.localdomain $hostname" >> /etc/hosts \
  || die "Failed to write to /etc/hosts."

# Setup Sudo by uncommenting %wheel ALL=(ALL:ALL) with visudo
sed -i 's/^#\s*\(%wheel ALL=(ALL:ALL) ALL\)/\1/' /etc/sudoers || \
  die "Failed to enable sudo for wheel group."

# Set Run Level to 4
sed -i 's/id:3:initdefault:/id:4:initdefault:/g' /etc/inittab || \
  die "Failed to set run level to 4."

# Create User and Set Passwords
useradd -m -g users -G wheel,audio,video,plugdev,netdev,lp,scanner \
  -s /bin/bash "$username" || die "Failed to create user."
echo "root:$rootpasswd" | chpasswd || \
  die "Failed to set root password."
echo "$username:$userpasswd" | chpasswd || \
  die "Failed to set user password."

# Set Default DE to XFCE System-Wide
ln -sf /etc/X11/xinit/xinitrc.xfce /etc/X11/xinit/xinitrc \
  || die "Failed to link xinitrc."
ln -sf /etc/X11/xinit/xinitrc.xfce /etc/X11/xsession || \
  die "Failed to link xsession."
cp /etc/X11/xinit/xinitrc.xfce /root/.xinitrc || \
  die "Failed to copy .xinitrc to /root."
cp /etc/X11/xinit/xinitrc.xfce /root/.xsession || \
  die "Failed to copy .xsession to /root."
chmod -x /root/.xinitrc || die "Failed to chmod .xinitrc."
chmod -x /root/.xsession || die "Failed to chmod .xsession."

# Enable Autologin
sed -i '/^\[Autologin\]/,/^\[/ {
  s/^User=[[:space:]]*$/User='"$username"'/;
  s/^Session=[[:space:]]*$/Session=xfce/;
  s/^User=.*$/User='"$username"'/;
  s/^Session=.*$/Session=xfce/;
}' /etc/sddm.conf || die "Failed to configure autologin in sddm.conf."

# Clean up
rm -rf Install-Common.sh Master-Common.sh

# Clone cinnamon-dotfiles repo as new user
clone_dotfiles "slackware-current"

# Setup GRUB theme
setup_grub_theme "Slackware"
EOF
