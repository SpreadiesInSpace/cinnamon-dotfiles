#!/bin/bash

die() {
    # Handle exits on error
    printf "\033[1;31mError:\033[0m %s\n" "$*" >&2
    read -rp "Press Enter to exit..."
    exit 1
}

check_if_root() {
    # Check if the script is run as root
    if [ "$EUID" -ne 0 ]; then
        die "Please run the script as superuser."
    fi
}

detect_boot_mode() {
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
          die "System booted in UEFI mode but efivars is not available.
This indicates a broken UEFI environment. Cannot continue safely."
        else
          REMOVABLE_BOOT="1"
        fi
      fi
    fi
  else
    BOOTMODE="BIOS"
    echo; echo "WARNING: You are booted in BIOS mode."
    echo "If your system supports UEFI, it is recommended to boot the installer ISO"
    echo "in UEFI mode."
    read -rp "Continue with BIOS mode? [y/N]: " bios_continue
    case "$bios_continue" in
      [yY][eE][sS]|[yY]) ;;
      *) die "Aborting. Please reboot the ISO in UEFI mode if desired." ;;
    esac
  fi
}

prompt_root_password() {
  # Prompt for root password
  while true; do
    read -sp "Enter new root password: " rootpasswd; echo
    read -sp "Confirm root password: " rootpasswd_confirm; echo
    if [ -z "$rootpasswd" ]; then
      echo "Root password cannot be empty."
      continue
    fi
    if [ "$rootpasswd" != "$rootpasswd_confirm" ]; then
      echo "Passwords do not match. Try again."
      continue
    fi
    break
  done
}

prompt_username() {
  # Prompt for new username
  while true; do
    read -p "Enter new username: " username
    if [[ "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
      break
    fi
    echo "Invalid username. Use only lowercase letters, numbers, underscores or hyphens (cannot start with number or hyphen)"
  done
}

prompt_user_password() {
  # Prompt for new user password
  while true; do
    read -sp "Enter password for $username: " userpasswd; echo
    read -sp "Confirm password for $username: " userpasswd_confirm; echo
    if [ -z "$userpasswd" ]; then
      echo "User password cannot be empty."
      continue
    fi
    if [ "$userpasswd" != "$userpasswd_confirm" ]; then
      echo "Passwords do not match. Try again."
      continue
    fi
    break
  done
}

# Slackware doesn't use this
prompt_hostname() {
  # Prompt for hostname
  while true; do
    read -p "Enter hostname: " hostname
    if [[ "$hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?$ ]] && ! [[ "$hostname" =~ \  ]]; then
      break
    fi
    echo "Invalid hostname. Must be alphanumeric, may include hyphens, and cannot contain spaces or start/end with a hyphen."
  done
}

prompt_timezone() {
  # Prompt for timezone
  while true; do
    read -p "Enter your timezone (e.g., Asia/Bangkok): " timezone
    timezone="${timezone:-Asia/Bangkok}"  # default if empty
    if [ -f "/usr/share/zoneinfo/$timezone" ]; then
      echo "Timezone set to: $timezone"
      break
    fi
    echo "Invalid timezone: $timezone"
  done
}

prompt_drive() {
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
        *) die "Aborting." ;;
      esac
    else
      echo "Invalid drive: $drive. Please enter a valid drive (e.g., /dev/sda, /dev/nvme0n1, /dev/mmcblk0) without a partition number or 'p' suffix."
    fi
  done
}

partition_drive() {
  # Partition the drive
  local distro=$1
  # Set parted path for Slackware
  local PARTED="parted"
  if [ "$distro" = "slackware" ]; then
    PARTED="/usr/sbin/parted"
  fi
  if [ "$BOOTMODE" = "UEFI" ]; then
    # Create GPT partition table
    "$PARTED" -s "$drive" mklabel gpt || die "Failed to create GPT partition table."
    # Create ESP (EFI System Partition) for UEFI
    "$PARTED" -s "$drive" mkpart primary fat32 1MiB 513MiB || die "Failed to create boot partition."
    "$PARTED" -s "$drive" set 1 esp on || die "Failed to set ESP flag."
    # Create root partition
    "$PARTED" -s "$drive" mkpart primary btrfs 513MiB 100% || die "Failed to create root partition."
  else
    # Create MBR partition table for BIOS
    "$PARTED" -s "$drive" mklabel msdos || die "Failed to create MBR partition table."
    # Create single root partition
    "$PARTED" -s "$drive" mkpart primary btrfs 1MiB 100% || die "Failed to create root partition."
  fi
}

partition_suffix() {
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
}

format_partitions() {
  # Format the partitions
  if [ "$BOOTMODE" = "UEFI" ]; then
    mkfs.fat -F32 "$BOOT" || die "Failed to format EFI partition."
  fi
  mkfs.btrfs -f "$ROOT" || die "Failed to format root partition."
}

create_btrfs_subvolumes() {
  # Create BTRFS subvolumes
  mount "$ROOT" /mnt || die "Failed to mount root partition."
  btrfs su cr /mnt/@ || die "Failed to create subvolume @."
  btrfs su cr /mnt/@home || die "Failed to create subvolume @home."
  umount /mnt || die "Failed to unmount root partition."
}

mount_partitions() {
  # Mount the partitions
  local distro="$1"
  # Handle Gentoo Mounts
  local MNT="/mnt"
  if [ "$distro" = "gentoo" ]; then
    MNT="/mnt/gentoo"
  fi
  mkdir -p "$MNT" || die "Failed to create $MNT."
  mount -o noatime,compress=zstd,discard=async,subvol=@ "$ROOT" "$MNT" || die "Failed to mount root subvolume."
  mkdir -p "$MNT/home" || die "Failed to create $MNT/home."
  mount -o noatime,compress=zstd,discard=async,subvol=@home "$ROOT" "$MNT/home" || die "Failed to mount home subvolume."  
  if [ "$BOOTMODE" = "UEFI" ]; then
    mkdir -p "$MNT/efi" || die "Failed to create $MNT/efi."
    mount "$BOOT" "$MNT/efi" || die "Failed to mount EFI partition."
  fi
}

# Only openSUSE/Slackware uses this
mount_system_partitions() {
  # Mount System Partitions
  mkdir -p /mnt/{proc,sys,dev,run} || die "Failed to create system mount points."
  mount --types proc /proc /mnt/proc || die "Failed to mount /proc."
  mount --rbind /sys /mnt/sys || die "Failed to bind-mount /sys."
  mount --make-rslave /mnt/sys || die "Failed to make /sys rslave."
  mount --rbind /dev /mnt/dev || die "Failed to bind-mount /dev."
  mount --make-rslave /mnt/dev || die "Failed to make /dev rslave."
  mount --bind /run /mnt/run || die "Failed to bind-mount /run."
  mount --make-slave /mnt/run || die "Failed to make /run slave."
}

# Only Gentoo uses this
set_video_card() {
# Set VIDEO_CARDS value in package.use
  while true; do
    echo "Select your video card type:"
    echo
    echo "1) amdgpu radeonsi"
    echo "2) nvidia"
    echo "3) intel"
    echo "4) nouveau (open source)"
    echo "5) virgl (QEMU/KVM)"
    echo "6) vc4 (Raspberry Pi)"
    echo "7) d3d12 (WSL)"
    echo "8) other"
    echo
    read -p "Enter the number corresponding to your video card: " video_card_number

    case $video_card_number in
      1) video_card="amdgpu radeonsi"; break ;;
      2) video_card="nvidia"; break ;;
      3) video_card="intel"; break ;;
      4) video_card="nouveau"; break ;;
      5) video_card="virgl"; break ;;
      6) video_card="vc4"; break ;;
      7) video_card="d3d12"; break ;;
      8) 
        read -p "Enter the video card type: " video_card; break ;;
      *) echo "Invalid selection, please try again." ;;
    esac
  done

  # Create or update the /etc/portage/package.use/00video-cards file
  echo "*/* VIDEO_CARDS: $video_card" > /mnt/gentoo/etc/portage/package.use/00video-cards || die "Failed to update VIDEO_CARDS in /etc/portage/package.use/00video-cards."
  echo; echo "Updated VIDEO_CARDS in /etc/portage/package.use/00video-cards to $video_card based on provided input."; echo
}
