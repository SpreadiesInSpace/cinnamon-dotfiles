#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run the script as superuser"
  exit
fi

# Prompt for root password
read -sp "Enter new root password: " rootpasswd; echo
if [ -z "$rootpasswd" ]; then echo "Root password cannot be empty."; exit 1; fi

# Prompt for new user details
read -p "Enter new username: " username
if ! [[ "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then echo "Invalid username. Use only lowercase letters, numbers, underscores or hyphens (cannot start with number or hyphen)"; exit 1; fi
read -sp "Enter password for $username: " userpasswd; echo
if [ -z "$userpasswd" ]; then echo "User password cannot be empty."; exit 1; fi

# Prompt for hostname
read -p "Enter hostname: " hostname
if [[ ! "$hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?$ ]]; then echo "Invalid hostname. Must be alphanumeric and may include hyphens (no leading/trailing hyphen)."; exit 1; fi

# Prompt for timezone
read -p "Enter your timezone (e.g., Asia/Bangkok): " timezone
timezone="${timezone:-Asia/Bangkok}"  # default if empty
if [ ! -f "/usr/share/zoneinfo/$timezone" ]; then echo "Invalid timezone: $timezone"; exit 1; fi
echo "Timezone set to: $timezone"

# Prompt for drive to partition
echo; lsblk; echo
read -p "Enter drive to use (e.g., /dev/sda, /dev/nvme0n1, /dev/mmcblk0): " drive
if [ ! -b "$drive" ]; then echo "Invalid drive: $drive"; exit 1; fi

# Refresh (for older ISOs)
xbps-install -Sy

# Install tools
xbps-install -y parted xtools

# Partition the drive
if ! parted -s "$drive" mklabel gpt; then echo "Failed to create partition table."; exit 1; fi
if ! parted -s "$drive" mkpart primary fat32 1MiB 513MiB; then echo "Failed to create boot partition."; exit 1; fi
if ! parted -s "$drive" set 1 esp on; then echo "Failed to set ESP flag."; exit 1; fi
if ! parted -s "$drive" mkpart primary btrfs 513MiB 100%; then echo "Failed to create root partition."; exit 1; fi

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

# Install Base System
# REPO=https://repo-fastly.voidlinux.org/current
REPO=https://mirror.vofr.net/voidlinux/current
ARCH=x86_64 
mkdir -p /mnt/var/db/xbps/keys
cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/
XBPS_ARCH=$ARCH xbps-install -Sy -r /mnt -R "$REPO" base-system

# Install Packages
xbps-install -Sy -r /mnt -R "$REPO" NetworkManager git xtools xmirror nano sudo grub-x86_64-efi bash-completion

# Enable Networking
for service in dbus NetworkManager polkitd; do
  chroot /mnt ln -sfv /etc/sv/$service /etc/runit/runsvdir/default
done

# Copy Network Info 
cp --dereference /etc/resolv.conf /mnt/etc/

# Generate fstab
xgenfstab -U /mnt > /mnt/etc/fstab

# Entering Chroot
cat << EOF | xchroot /mnt /bin/bash

# New Chroot Environment
source /etc/profile

# Change shell to bash
chsh -s /bin/bash

# Set Hostname
echo "$hostname" > /etc/hostname

# Allow Resolving the Local Hostname
echo -e "127.0.1.1\t$hostname.localdomain\t$hostname" >> /etc/hosts

# Set Timezone
ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime
hwclock --systohc

# Locale Generation (uncomment en_US.UTF-8 UTF-8) in /etc/default/libc-locales
sed -i 's/^#\s*\(en_US.UTF-8 UTF-8\)/\1/' /etc/default/libc-locales
xbps-reconfigure -f glibc-locales

# Create User
useradd -m -G users,wheel,audio,video,plugdev -s /bin/bash "$username"

# Set Root Password
passwd root << PASSWORD
$rootpasswd
$rootpasswd
PASSWORD

# Set User Password
passwd "$username" << PASSWORD
$userpasswd
$userpasswd
PASSWORD

# Setup Sudo by uncommenting %wheel ALL=(ALL:ALL) with visudo
sed -i 's/^#\s*\(%wheel ALL=(ALL:ALL) ALL\)/\1/' /etc/sudoers

# Installing Grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id="Void"

# Set GRUB timeout to 0
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub

# Generate Grub Config (xbps-reconfigure -fa takes care of this)
# grub-mkconfig -o /boot/grub/grub.cfg

# Reconfigure System
xbps-reconfigure -fa

# Clone Repo as New User
cat << CLONE | su - "$username"
cd; git clone https://github.com/SpreadiesInSpace/cinnamon-dotfiles
cd cinnamon-dotfiles
echo "Reboot and run Setup-Void.sh in cinnamon-dotfiles located in $username's home folder."
CLONE
EOF
