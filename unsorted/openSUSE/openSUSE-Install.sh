#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run the script as superuser"
  exit
fi

# Enable Parallel Downloads
export ZYPP_CURL2=1
export ZYPP_PCK_PRELOAD=1

# Fix openSUSE's line break paste issue
echo "set enable-bracketed-paste" >> ~/.inputrc

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
zypper ref

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

# Mount System Partitions
mkdir -p /mnt/{proc,sys,dev,run}
mount --types proc /proc /mnt/proc
mount --rbind /sys /mnt/sys
mount --make-rslave /mnt/sys
mount --rbind /dev /mnt/dev
mount --make-rslave /mnt/dev
mount --bind /run /mnt/run
mount --make-slave /mnt/run

# Installing the Base System
zypper --root /mnt ar --no-gpgcheck --refresh https://download.opensuse.org/tumbleweed/repo/oss/ oss
zypper --root /mnt in -y kernel-default grub2-x86_64-efi shim zypper bash man shadow util-linux nano arch-install-scripts

# Copy Repos
cp /etc/zypp/repos.d/* /mnt/etc/zypp/repos.d/

# Copy Network Info
cp --dereference /etc/resolv.conf /mnt/etc/

# Chrooting
cat << EOF | chroot /mnt /bin/bash

# New Chroot
source /etc/profile
export PS1="(chroot) ${PS1}"

# Sync Repos
zypper ref

# Remove Dangling Repo (at this point, all proper repos have been generated)
zypper rr oss

# Generate fstab
genfstab -U / >> /etc/fstab

# Set Hostname
echo "$hostname" > /etc/hostname

# Allow Resolving the Local Hostname
echo -e "127.0.1.1\t$hostname.localdomain\t$hostname" >> /etc/hosts

# Setting Timezone
ln -sf "../usr/share/zoneinfo/$timezone" /etc/localtime
hwclock --systohc

# Set Locale
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo 'RC_LANG="en_US.UTF-8"' > /etc/sysconfig/language

# Set Keymap
echo "KEYMAP=us" > /etc/vconsole.conf

# Installing grub
dracut -f --regenerate-all
grub2-install --efi-directory=/boot/efi

# Set GRUB timeout to 0
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub

# Generate Grub Config
grub2-mkconfig -o /boot/grub2/grub.cfg

# Install Basic Desktop
zypper in -y -t pattern basic_desktop

# Install Cinnamon Desktop Environment
zypper al mint-x-icon-theme mint-y-icon-theme
zypper rm -y busybox-which
zypper in -y cinnamon lightdm-slick-greeter btrfsprogs sudo bash-completion git

# Install Recommended Packages (excluding Snapper & Firefox)
zypper al snapper*
zypper inr
zypper rm -y MozillaFirefox* *-lang *-doc lightdm-gtk-greeter
zypper al MozillaFirefox* *-lang *-doc

# Configure lightdm
systemctl set-default graphical

# Setup Sudo by uncommenting %wheel ALL=(ALL:ALL) with visudo
sed -i 's/^#\s*\(%wheel ALL=(ALL:ALL) ALL\)/\1/' /usr/etc/sudoers

# Add wheel group for sudo
groupadd -f wheel

# Create User and Set Passwords
useradd -m -G wheel,audio,video,users -s /bin/bash "$username"
echo "root:$rootpasswd" | chpasswd
echo "$username:$userpasswd" | chpasswd

# Enabling System Services
systemctl enable NetworkManager

# Clone Repo as New User
cat << CLONE | su - "$username"
cd; git clone https://github.com/SpreadiesInSpace/cinnamon-dotfiles
cd cinnamon-dotfiles
echo "Reboot and run Setup-OpenSUSE-Tumbleweed.sh in cinnamon-dotfiles located in $username's home folder."
CLONE
EOF
