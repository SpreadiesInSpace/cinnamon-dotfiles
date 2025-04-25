#!/bin/bash

# Links to run this file:
# bash <(curl -sL https://tinyurl.com/spready-opensuse-tumbleweed)
# bash <(wget -qO- https://tinyurl.com/spready-opensuse-tumbleweed)

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run the script as superuser"
  exit
fi

# Enable Parallel Downloads
# export ZYPP_CURL2=1
export ZYPP_PCK_PRELOAD=1

# Fix openSUSE's line break paste issue
echo "set enable-bracketed-paste" >> ~/.inputrc

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

# Prompt for hostname
while true; do
  read -p "Enter hostname: " hostname
  if [[ "$hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?$ ]] && ! [[ "$hostname" =~ \  ]]; then break; fi
  echo "Invalid hostname. Must be alphanumeric, may include hyphens, and cannot contain spaces or start/end with a hyphen."
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
  # Check if the drive is a valid block device and not a partition
  if [[ "$drive" =~ ^/dev/(sd[a-z]|nvme[0-9]+n[0-9]+|mmcblk[0-9]+|vd[a-z])$ ]] && [ -b "$drive" ]; then
    # Confirm before proceeding
    read -rp "WARNING: This will erase all data on $drive. Are you sure you want to continue? [y/N]: " confirm
    case "$confirm" in
      [yY][eE][sS]|[yY]) break ;;
      *) echo "Aborting."; exit 1 ;;
    esac
  else
    echo "Invalid drive: $drive. Please enter a valid drive (e.g., /dev/sda, /dev/nvme0n1, /dev/mmcblk0) without a partition number or 'p' suffix."
  fi
done

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
zypper --root /mnt in -y --download-in-advance dracut kernel-default grub2-x86_64-efi shim zypper bash man shadow util-linux nano arch-install-scripts

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
zypper in -y cinnamon lightdm-gtk-greeter-settings btrfsprogs sudo bash-completion git unzip

# Install Recommended Packages (excluding Snapper & Firefox)
zypper al snapper*
zypper inr
zypper rm -y MozillaFirefox* *-lang *-doc
zypper al MozillaFirefox* *-lang *-doc

# Configure lightdm
systemctl set-default graphical

# Set Timezone
ln -sf "../usr/share/zoneinfo/$timezone" /etc/localtime
hwclock --systohc

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
cat << 'CLONE' | su - "$username"
cd; git clone https://github.com/SpreadiesInSpace/cinnamon-dotfiles
cd cinnamon-dotfiles
touch .opensuse-tumbleweed.done
echo "Reboot and run Setup.sh in cinnamon-dotfiles located in $username's home folder."
CLONE
EOF
