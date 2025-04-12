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

# Update keyring (for older ISOs)
echo "Updating keyring..."
pacman -Sy --noconfirm archlinux-keyring

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

# Install Essential packages
pacstrap -K /mnt base linux linux-firmware sudo bash-completion grub efibootmgr git networkmanager nano unzip

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Entering Chroot
cat << EOF | arch-chroot /mnt

# Set Timezone
ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime
hwclock --systohc

# Locale Generation (uncomment en_US.UTF-8 UTF-8 in /etc/locale.gen)
sed -i 's/^#\s*\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen

# Set Locale
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Set Keymap
echo "KEYMAP=us" > /etc/vconsole.conf

# Set Hostname
echo "$hostname" > /etc/hostname

# Allow Resolving the Local Hostname
echo -e "127.0.1.1\t$hostname.localdomain\t$hostname" >> /etc/hosts

# Enable Networking
systemctl enable NetworkManager

# Configure GRUB Bootloader
grub-install --target=x86_64-efi --efi-directory=/boot/efi

# Set GRUB timeout to 0
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub

# Generate Grub Config
grub-mkconfig -o /boot/grub/grub.cfg

# Setup Sudo by uncommenting %wheel ALL=(ALL:ALL) with visudo
sed -i 's/^#\s*\(%wheel ALL=(ALL:ALL) ALL\)/\1/' /etc/sudoers

# Create User and Set Passwords
useradd -m -G users,wheel,audio,video -s /bin/bash "$username"
echo "root:$rootpasswd" | chpasswd
echo "$username:$userpasswd" | chpasswd

# Clone Repo as New User
cat << CLONE | su - "$username"
cd; git clone https://github.com/SpreadiesInSpace/cinnamon-dotfiles
cd cinnamon-dotfiles
echo "Reboot and run Setup-Arch.sh in cinnamon-dotfiles located in $username's home folder."
CLONE
EOF
