#!/bin/bash

# Links to run this file:
# bash <(curl -sL https://tinyurl.com/spready-arch)
# bash <(wget -qO- https://tinyurl.com/spready-arch)

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run the script as superuser"
  exit
fi

# Detect if booted in UEFI or BIOS mode
if [ -d /sys/firmware/efi ]; then
  BOOTMODE="UEFI"
  REMOVABLE_BOOT="0"  # assume normal boot unless proven otherwise
  # Check if efivars is mounted
  if ! mount | grep -q efivars; then
    echo "efivars not mounted. Attempting to mount efivars..."
    if ! mount -t efivarfs efivars /sys/firmware/efi/efivars; then
      echo "Failed to mount efivars. Attempting to remount as read-write..."
      if ! mount -o remount,rw,nosuid,nodev,noexec --types efivarfs efivarfs /sys/firmware/efi/efivars; then
        echo "ERROR: System booted in UEFI mode but efivars is not available."
        echo "This indicates a broken UEFI environment. Cannot continue safely."
        exit 1
      else
        REMOVABLE_BOOT="1"
      fi
    fi
  fi
else
  BOOTMODE="BIOS"
  echo; echo "WARNING: You are booted in BIOS mode."
  echo "If your system supports UEFI, it is recommended to boot the installer ISO in UEFI mode."
  read -rp "Continue with BIOS mode? [y/N]: " bios_continue
  case "$bios_continue" in
    [yY][eE][sS]|[yY]) ;;
    *) echo "Aborting. Please reboot the ISO in UEFI mode if desired."; exit 1 ;;
  esac
fi

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
  if [[ "$drive" =~ ^/dev/(sd[a-z]|nvme[0-9]+n[0-9]+|mmcblk[0-9]+|vd[a-z])$ ]] && [ -b "$drive" ]; then
    read -rp "WARNING: This will erase all data on $drive. Are you sure you want to continue? [y/N]: " confirm
    case "$confirm" in
      [yY][eE][sS]|[yY]) break ;;
      *) echo "Aborting."; exit 1 ;;
    esac
  else
    echo "Invalid drive: $drive. Please enter a valid drive (e.g., /dev/sda, /dev/nvme0n1, /dev/mmcblk0) without a partition number or 'p' suffix."
  fi
done

# Update keyring (for older ISOs)
echo "Updating keyring..."
pacman -Syu --needed --noconfirm archlinux-keyring || { echo "Failed to update keyring."; exit 1; }

# Partition the drive
if [ "$BOOTMODE" = "UEFI" ]; then
  # Create GPT partition table
  parted -s "$drive" mklabel gpt || { echo "Failed to create GPT partition table."; exit 1; }
  # Create ESP (EFI System Partition) for UEFI
  parted -s "$drive" mkpart primary fat32 1MiB 513MiB || { echo "Failed to create boot partition."; exit 1; }
  parted -s "$drive" set 1 esp on || { echo "Failed to set ESP flag."; exit 1; }
  # Create root partition
  parted -s "$drive" mkpart primary btrfs 513MiB 100% || { echo "Failed to create root partition."; exit 1; }
else
  # Create MBR partition table for BIOS
  parted -s "$drive" mklabel msdos || { echo "Failed to create MBR partition table."; exit 1; }
  # Create single root partition
  parted -s "$drive" mkpart primary btrfs 1MiB 100% || { echo "Failed to create root partition."; exit 1; }
fi

# Determine correct partition suffix
if [[ "$drive" == *"nvme"* || "$drive" == *"mmcblk"* ]]; then
  if [ "$BOOTMODE" = "UEFI" ]; then
    BOOT="${drive}p1"; ROOT="${drive}p2"
  else
    ROOT="${drive}p1"
  fi
else
  if [ "$BOOTMODE" = "UEFI" ]; then
    BOOT="${drive}1"; ROOT="${drive}2"
  else
    ROOT="${drive}1"
  fi
fi

# Format the partitions
if [ "$BOOTMODE" = "UEFI" ]; then
  mkfs.fat -F32 "$BOOT" || { echo "Failed to format EFI partition."; exit 1; }
fi
mkfs.btrfs -f "$ROOT" || { echo "Failed to format root partition."; exit 1; }

# Create BTRFS subvolumes
mount "$ROOT" /mnt || { echo "Failed to mount root partition."; exit 1; }
btrfs su cr /mnt/@ || { echo "Failed to create subvolume @."; exit 1; }
btrfs su cr /mnt/@home || { echo "Failed to create subvolume @home."; exit 1; }
umount /mnt || { echo "Failed to unmount root partition."; exit 1; }

# Mount the partitions
mount -o noatime,compress=zstd,discard=async,subvol=@ "$ROOT" /mnt || { echo "Failed to mount root subvolume."; exit 1; }
mkdir -p /mnt/home || { echo "Failed to create /mnt/home."; exit 1; }
mount -o noatime,compress=zstd,discard=async,subvol=@home "$ROOT" /mnt/home || { echo "Failed to mount home subvolume."; exit 1; }
if [ "$BOOTMODE" = "UEFI" ]; then
  mkdir -p /mnt/boot/efi || { echo "Failed to create /mnt/boot/efi."; exit 1; }
  mount "$BOOT" /mnt/boot/efi || { echo "Failed to mount EFI partition."; exit 1; }
fi

# Install Essential packages
pacstrap -K /mnt base linux linux-firmware sudo bash-completion grub efibootmgr git networkmanager nano unzip || { echo "Pacstrap failed"; exit 1; }

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab || { echo "Failed to generate fstab"; exit 1; }

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

# Setup Sudo by uncommenting %wheel ALL=(ALL:ALL) with visudo
sed -i 's/^#\s*\(%wheel ALL=(ALL:ALL) ALL\)/\1/' /etc/sudoers

# Create User and Set Passwords
useradd -m -G users,wheel,audio,video -s /bin/bash "$username"
echo "root:$rootpasswd" | chpasswd
echo "$username:$userpasswd" | chpasswd

# Clone Repo as New User
cat << 'CLONE' | su - "$username"
cd; git clone https://github.com/SpreadiesInSpace/cinnamon-dotfiles
cd cinnamon-dotfiles
touch .arch.done
echo "Reboot and run Setup.sh in cinnamon-dotfiles located in $username's home folder."
CLONE
EOF
