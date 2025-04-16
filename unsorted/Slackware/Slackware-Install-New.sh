#!/bin/bash

# For SSH
# passwd
# dhcpcd
# /etc/rc.d/rc.dropbear start

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run the script as superuser"
  exit
fi

# Auto-detect and mount installation media
mount_install_media() {
  echo "Scanning for Slackware installation media..."
  # First check if already mounted
  if mountpoint -q /mnt/isofiles && [ -d "/mnt/isofiles/slackware64" ]; then
    echo "Installation media already mounted"
    return 0
  fi
  # Create mount point if needed
  mkdir -p /mnt/isofiles
  # Try to find and mount Slackware media
  local found=0
  # First try optical drive as it's the most common installation source
  echo "Trying optical drive..."
  if mount -o ro /dev/sr0 /mnt/isofiles 2>/dev/null; then
    if [ -d "/mnt/isofiles/slackware64" ]; then
      echo "Found Slackware media on optical drive"
      found=1
    else
      umount /mnt/isofiles
    fi
  fi
  # If not found on optical drive, try USB drives and other partitions
  if [ $found -eq 0 ]; then
    echo "Trying other media..."
    # Get list of potential partitions, skip already mounted system partitions
    for device in $(lsblk -lno NAME,TYPE,MOUNTPOINT | grep "part" | grep -v "/boot\|/home\|/\s" | cut -d' ' -f1); do
      echo "Trying device /dev/$device..."
      if mount -o ro /dev/$device /mnt/isofiles 2>/dev/null; then
        if [ -d "/mnt/isofiles/slackware64" ]; then
          echo "Found Slackware media on /dev/$device"
          found=1
          break
        else
          umount /mnt/isofiles
        fi
      fi
    done
  fi
  # If still not found, try ISO files
  if [ $found -eq 0 ]; then
    echo "Searching for Slackware ISO files..."
    mkdir -p /var/log/mntiso
    # Look for ISO files in common locations
    for iso in /root/*.iso /home/*/*.iso /mnt/*/*.iso /media/*/*.iso; do
      if [ -f "$iso" ]; then
        echo "Found ISO file: $iso, trying to mount..."
        if mount -o loop "$iso" /var/log/mntiso 2>/dev/null; then
          # Check if it's a Slackware ISO
          if [ -d "/var/log/mntiso/slackware64" ]; then
            # Use bind mount to make it available at our expected location
            if mount --bind /var/log/mntiso/slackware64 /mnt/isofiles; then
              echo "Successfully mounted Slackware ISO"
              found=1
              break
            else
              umount /var/log/mntiso
            fi
          else
            umount /var/log/mntiso
          fi
        fi
      fi
    done
  fi
  
  # Check if successful
  if [ $found -eq 0 ]; then
    echo "Failed to find and mount Slackware installation media"
    return 1
  fi
  
  return 0
}

# Ensure installation media is mounted before package installation
if ! mount_install_media; then echo "Cannot proceed without installation media"; exit 1; fi

# Required System Packages
required_sys_packages=(
  "a/glibc-zoneinfo" # for timezone validation
)

# Install Required System Packages
for pkg in "${required_sys_packages[@]}"; do
  installpkg "/mnt/isofiles/slackware64/$pkg"-*.t?z >/dev/null 2>&1
done

# Prompt for root password
while true; do
  read -sp "Enter new root password: " rootpasswd; echo
  read -sp "Confirm root password: " rootpasswd_confirm; echo
  if [ -z "$rootpasswd" ]; then echo "Root password cannot be empty."; continue; fi
  if [ "$rootpasswd" != "$rootpasswd_confirm" ]; then echo "Passwords do not match. Try again."; continue; fi
  break
done

# Prompt for new username
while true; do
  read -p "Enter new username: " username
  if [[ "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then break; fi
  echo "Invalid username. Use only lowercase letters, numbers, underscores or hyphens (cannot start with number or hyphen)"
done

# Prompt for new user password
while true; do
  read -sp "Enter password for $username: " userpasswd; echo
  read -sp "Confirm password for $username: " userpasswd_confirm; echo
  if [ -z "$userpasswd" ]; then echo "User password cannot be empty."; continue; fi
  if [ "$userpasswd" != "$userpasswd_confirm" ]; then echo "Passwords do not match. Try again."; continue; fi
  break
done

# Prompt for timezone
while true; do
  read -p "Enter your timezone (e.g., Asia/Bangkok): " timezone
  timezone="${timezone:-Asia/Bangkok}"  # default if empty
  if [ -f "/usr/share/zoneinfo/$timezone" ]; then echo "Timezone set to: $timezone"; break; fi
  echo "Invalid timezone: $timezone"
done

# Prompt for drive to partition
echo; lsblk; echo
while true; do
  read -p "Enter drive to use (e.g., /dev/sda, /dev/nvme0n1, /dev/mmcblk0): " drive
  # Check if the drive is valid (not a partition) and if it's a block device
  if [[ "$drive" =~ ^/dev/[a-zA-Z0-9]+$ ]] && [ -b "$drive" ] && ! [[ "$drive" =~ [0-9p]$ ]]; then
    # Confirm before proceeding
    read -rp "WARNING: This will erase all data on $drive. Are you sure you want to continue? [y/N]: " confirm
    case "$confirm" in
      [yY][eE][sS]|[yY]) break ;;
      *) echo "Aborting."; exit 1 ;;
    esac
  else
    echo "Invalid drive: $drive. Please enter a valid drive (e.g., /dev/sda, /dev/nvme0n1) without a partition number or 'p' suffix."
  fi
done

# Partition the drive
if ! /usr/sbin/parted -s "$drive" mklabel gpt; then echo "Failed to create partition table."; exit 1; fi
if ! /usr/sbin/parted -s "$drive" mkpart primary fat32 1MiB 513MiB; then echo "Failed to create boot partition."; exit 1; fi
if ! /usr/sbin/parted -s "$drive" set 1 esp on; then echo "Failed to set ESP flag."; exit 1; fi
if ! /usr/sbin/parted -s "$drive" mkpart primary btrfs 513MiB 100%; then echo "Failed to create root partition."; exit 1; fi

# Determine correct partition suffix
if [[ "$drive" == *"nvme"* || "$drive" == *"mmcblk"* ]]; then
  BOOT="${drive}p1"; ROOT="${drive}p2"
else
  BOOT="${drive}1"; ROOT="${drive}2"
fi

# Format the partitions
if ! mkfs.vfat "$BOOT"; then echo "Failed to format EFI partition."; exit 1; fi
if ! mkfs.btrfs -f "$ROOT"; then echo "Failed to format root partition."; exit 1; fi

# Create BTRFS subvolumes
mount "$ROOT" /mnt || { echo "Failed to mount root partition."; exit 1; }
btrfs su cr /mnt/@ || { echo "Failed to create subvolume @."; exit 1; }
btrfs su cr /mnt/@home || { echo "Failed to create subvolume @home."; exit 1; }
umount /mnt

# Mount the partitions
mount -o noatime,compress=zstd,discard=async,subvol=@ "$ROOT" /mnt
mkdir -p /mnt/{boot/efi,home}
mount -o noatime,compress=zstd,discard=async,subvol=@home "$ROOT" /mnt/home
mount "$BOOT" /mnt/boot/efi

# Mount System Partitions
mkdir -p /mnt/{proc,sys,dev,run}
mount --types proc /proc /mnt/proc
mount --rbind /sys /mnt/sys
mount --make-rslave /mnt/sys
mount --rbind /dev /mnt/dev
mount --make-rslave /mnt/dev
mount --bind /run /mnt/run
mount --make-slave /mnt/run

# Verify installation media is mounted and remount if needed
ensure_media_mounted() {
  # Check if already mounted and has the expected content
  if mountpoint -q /mnt/isofiles && [ -d "/mnt/isofiles/slackware64" ]; then
    echo "Installation media already mounted"; return 0
  fi
  # If mounted but without slackware64 directory, unmount it
  if mountpoint -q /mnt/isofiles; then
    echo "Mount point exists but doesn't contain Slackware - remounting"; umount /mnt/isofiles
  fi
  # Remount using mounting function
  mount_install_media; return $?
}

# Ensure installation media is mounted before package installation
echo "Verifying installation media is mounted..."
if ! ensure_media_mounted; then echo "Cannot proceed with package installation without media"; exit 1; fi

# Get list of package set directories
pkg_dirs=( /mnt/isofiles/slackware64/* )
package_sets=()
for dir in "${pkg_dirs[@]}"; do
  [ -d "$dir" ] && package_sets+=("$(basename "$dir")")
done

# Prepare for full installation
echo "Starting full Slackware installation..."

# Get list of package sets (sorted alphabetically)
package_sets=(); for dir in /mnt/isofiles/slackware64/*; do [ -d "$dir" ] && package_sets+=("$(basename "$dir")"); done
IFS=$'\n' package_sets=($(sort <<<"${package_sets[*]}")); unset IFS

# Install all sets with overall progress
total_sets=${#package_sets[@]}; set_count=1; echo
for pkg_set in "${package_sets[@]}"; do
  pkg_set_cap="${pkg_set^^}"  # Capitalize package set name
  echo "[$set_count/$total_sets] Installing package set: $pkg_set_cap"
  pkg_files=( /mnt/isofiles/slackware64/"$pkg_set"/*.t?z )
  total_pkgs=${#pkg_files[@]}; pkg_count=1
  for pkg in "${pkg_files[@]}"; do
    pkg_name=$(basename "$pkg")
    printf "\r    [%s/%s] Installing: %-60s" "$pkg_count" "$total_pkgs" "$pkg_name"
    installpkg --root /mnt "$pkg" >/dev/null 2>&1; ((pkg_count++))
  done
  echo; ((set_count++))
done; echo

# Run post-installation configuration
echo "Running ldconfig..."
[ -x /mnt/sbin/ldconfig ] && /mnt/sbin/ldconfig -r /mnt

# Run netconfig interactively before chroot
chroot /mnt netconfig

# Extract hostname without domain
hostname=$(cat /mnt/etc/HOSTNAME)
hostname=${hostname%%.*}

# Copy Network Info
cp --dereference /etc/resolv.conf /mnt/etc/

# Entering Chroot
cat << EOF | chroot /mnt /bin/bash

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

# Install Grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub

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
cat << CLONE | su - $"$username"
cd; git clone https://github.com/SpreadiesInSpace/cinnamon-dotfiles
cd cinnamon-dotfiles
echo "Reboot and run Setup-Slackware.sh in cinnamon-dotfiles located in $username's home folder."
CLONE
EOF
