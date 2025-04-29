#!/bin/bash

# Download and source common functions
echo "Sourcing functions..."
wget -qO Install-Common.sh https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles/main/extra/ISO/Install-Common.sh 2>/dev/null || { echo "Failed to download Install-Common.sh"; exit 1; }
[ -f ./Install-Common.sh ] && source ./Install-Common.sh || { echo "Failed to source Install-Common.sh."; exit 1; }

# Check if script is run as root
check_if_root

# Detect if booted in UEFI or BIOS mode
detect_boot_mode

# Auto-detect and mount installation media
SeTmedia || die "Failed to detect or mount installation media."
clear

# Install glibc-zoneinfo for timezone validation
installpkg /var/log/mount/slackware64/a/glibc-zoneinfo-*.t?z >/dev/null 2>&1 || die "Failed to install glibc-zoneinfo."

# Prompt for root password
prompt_root_password

# Prompt for new username
prompt_username

# Prompt for new user password
prompt_user_password

# Prompt for hostname (netconfig takes care of this)
# prompt_hostname 

# Prompt for timezone
prompt_timezone

# Prompt for drive to partition
prompt_drive

# Partition the drive
partition_drive "slackware"

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
mkdir -p /mnt/var/log/mount || die "Failed to mount installation media inside chroot."
mount --bind /var/log/mount /mnt/var/log/mount || die "Failed to bind mount /var/log/mount to /mnt."

# Get list of package set directories
pkg_dirs=( /var/log/mount/slackware64/* )
[ ! -d "/var/log/mount/slackware64" ] && die "Slackware package directory not found at /var/log/mount/slackware64."
package_sets=()
for dir in "${pkg_dirs[@]}"; do
  [ -d "$dir" ] && package_sets+=("$(basename "$dir")")
done

# Prepare for full installation
echo "Starting full Slackware installation..."

# Get list of package sets (sorted alphabetically)
package_sets=(); for dir in /var/log/mount/slackware64/*; do [ -d "$dir" ] && package_sets+=("$(basename "$dir")"); done
IFS=$'\n' package_sets=($(sort <<<"${package_sets[*]}")); unset IFS

# Install all sets with overall progress
total_sets=${#package_sets[@]}; set_count=1; echo
for pkg_set in "${package_sets[@]}"; do
  pkg_set_cap="${pkg_set^^}"  # Capitalize package set name
  echo "[$set_count/$total_sets] Installing package set: $pkg_set_cap"
  pkg_files=( /var/log/mount/slackware64/"$pkg_set"/*.t?z )
  total_pkgs=${#pkg_files[@]}; pkg_count=1
  for pkg in "${pkg_files[@]}"; do
    pkg_name=$(basename "$pkg")
    printf "\r    [%s/%s] Installing: %-60s" "$pkg_count" "$total_pkgs" "$pkg_name"
    installpkg --root /mnt "$pkg" >/dev/null 2>&1 || die "Failed to install package $pkg_name."
    ((pkg_count++))
  done
  echo; ((set_count++))
done; echo

# Run post-installation configuration
echo "Running ldconfig..."
[ -x /mnt/sbin/ldconfig ] && /mnt/sbin/ldconfig -r /mnt || die "Failed to run ldconfig."

# Run netconfig interactively before chroot
chroot /mnt netconfig; clear || die "Failed to run netconfig in chroot."

# Extract hostname without domain
hostname=$(cat /mnt/etc/HOSTNAME)
hostname=${hostname%%.*}

# Copy Network Info
[ ! -e /etc/resolv.conf ] && die "Source resolv.conf does not exist."
cp --dereference /etc/resolv.conf /mnt/etc/ || die "Failed to copy resolv.conf."

# Entering Chroot
cat << EOF | chroot /mnt /bin/bash || die "Failed to enter chroot."

# New Chroot
source /etc/profile

# Post Install Scripts
/var/log/setup/setup.*.mkinitrd
/var/log/setup/setup.*.mkfontdir
/var/log/setup/setup.*.fontconfig
/var/log/setup/setup.*.update-desktop-database
/var/log/setup/setup.*.update-mime-database
/var/log/setup/setup.*.gtk-update-icon-cache
/var/log/setup/setup.*.cacerts
/var/log/setup/setup.cups-genppdupdate
/var/log/setup/setup.htmlview

# Set Timezone
ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime
hwclock --systohc

# Configure GRUB Bootloader
if [ "$BOOTMODE" = "UEFI" ]; then
  if [ "$REMOVABLE_BOOT" = "1" ]; then
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --removable
  else
    grub-install --target=x86_64-efi --efi-directory=/boot/efi
  fi
else
  grub-install --target=i386-pc --boot-directory=/boot "$drive"
fi

# Set GRUB timeout to 0
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub

# Generate Grub Config
grub-mkconfig -o /boot/grub/grub.cfg

# List Default Enabled Services from Setup Menu
services=(
  # atalk
  atd
  avahidaemon
  avahidnsconfd
  # bind
  crond
  # cups
  # dnsmasq
  # dovecot
  fuse
  # httpd
  # inetd
  # ip_forward
  messagebus
  networkmanager
  # mysqld
  # nfsd
  # ntpd
  # openldap
  # openvpn
  # pcmcia
  # pcscd
  # postfix
  # rpc
  samba # default is off
  # saslauthd
  # smartd
  # snmpd
  syslog
  sshd
)

# Enable Selected Services (chmod only, no start)
for svc in "${services[@]}"; do
  # Skip commented-out entries
  [[ "$svc" == \#* || -z "$svc" ]] && continue
  svc_path="/etc/rc.d/rc.$svc"
  if [ -f "$svc_path" ]; then
    chmod +x "$svc_path"  # Just chmod, don't start
  else
    echo "Service script not found: $svc_path"
  fi
done

# Download arch-install-scripts source and SlackBuild (for genfstab)
echo "Installing arch-install-scripts..."
wget -q https://gitlab.archlinux.org/archlinux/arch-install-scripts/-/archive/v29/arch-install-scripts-v29.tar.gz -O arch-install-scripts-v29.tar.gz
wget -q https://slackbuilds.org/slackbuilds/15.0/system/arch-install-scripts.tar.gz -O arch-install-scripts-slackbuild.tar.gz

# Extract SlackBuild and move the source into place
tar -xf arch-install-scripts-slackbuild.tar.gz >/dev/null 2>&1
mv arch-install-scripts-v29.tar.gz arch-install-scripts/

# Build, install and cleanup
cd arch-install-scripts || exit 1
./arch-install-scripts.SlackBuild >/dev/null 2>&1
installpkg /tmp/arch-install-scripts-29-noarch-1_SBo.tgz>/dev/null 2>&1
cd .. && rm -rf arch-install-scripts*

# Generate fstab
genfstab -U / > /etc/fstab
# Append Essential Mounts
echo "#/dev/cdrom    /mnt/cdrom     auto      noauto,owner,ro,comment=x-gvfs-show    0 0
#/dev/fd0      /mnt/floppy    auto      noauto,owner                           0 0
devpts         /dev/pts       devpts    gid=5,mode=620                         0 0
proc           /proc          proc      defaults                               0 0
tmpfs          /dev/shm       tmpfs     nosuid,nodev,noexec                    0 0" >> /etc/fstab

# Set Hostname
echo "$hostname" > /etc/HOSTNAME

# Prevent software from unsafely resolving localhost over the network
echo "# For loopbacking.
127.0.0.1               localhost
::1                     localhost" | tee /etc/hosts > /dev/null

# Allow Resolving the Local Hostname
echo "127.0.1.1               $hostname.localdomain $hostname" >> /etc/hosts

# Setup Sudo by uncommenting %wheel ALL=(ALL:ALL) with visudo
sed -i 's/^#\s*\(%wheel ALL=(ALL:ALL) ALL\)/\1/' /etc/sudoers

# Set Run Level to 4
sed -i 's/id:3:initdefault:/id:4:initdefault:/g' /etc/inittab

# Create User and Set Passwords
useradd -m -g users -G wheel,audio,video,plugdev,netdev,lp,scanner -s /bin/bash "$username"
echo "root:$rootpasswd" | chpasswd
echo "$username:$userpasswd" | chpasswd

# Set Default DE to XFCE System-Wide
ln -sf /etc/X11/xinit/xinitrc.xfce /etc/X11/xinit/xinitrc
ln -sf /etc/X11/xinit/xinitrc.xfce /etc/X11/xsession
cp /etc/X11/xinit/xinitrc.xfce /root/.xinitrc
cp /etc/X11/xinit/xinitrc.xfce /root/.xsession
chmod -x /root/.xinitrc
chmod -x /root/.xsession

# Enable Autologin
sed -i '/^\[Autologin\]/,/^\[/ {
  s/^User=[[:space:]]*$/User='$username'/;
  s/^Session=[[:space:]]*$/Session=xfce/;
  s/^User=.*$/User='$username'/;
  s/^Session=.*$/Session=xfce/;
}' /etc/sddm.conf

# Clone Repo as New User
cat << 'CLONE' | su - "$username"
cd; git clone https://github.com/SpreadiesInSpace/cinnamon-dotfiles
cd cinnamon-dotfiles
touch .slackware-current.done
echo "Reboot and run Setup.sh in cinnamon-dotfiles located in $username's home folder."
CLONE
EOF
