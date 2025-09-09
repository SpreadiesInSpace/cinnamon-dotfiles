#!/bin/bash

# Partition the drive # partition_drive
parted "$drive" --script \
  mklabel gpt \
  mkpart SYS fat32 1MiB 601MiB \
  mkpart BOOT ext4 601MiB 1625MiB \
  mkpart ROOT ext4 1625MiB 100% \
  set 1 esp on

# Determine correct partition suffix
partition_suffix() {
  # Determine correct partition suffix
  local suffix=""
  [[ "$drive" == *"nvme"* || "$drive" == *"mmcblk"* ]] && suffix="p"
  if [ "$BOOTMODE" = "UEFI" ]; then
    SYS="${drive}${suffix}1"
    BOOT="${drive}${suffix}2"
    ROOT="${drive}${suffix}3"
  else
    BOOT="${drive}${suffix}1"
    ROOT="${drive}${suffix}2"
  fi
}
partition_suffix

# Format the partitions
mkfs.fat -F 32 -n SYS "$SYS" # EFI Only
mkfs.ext4 -F -L BOOT "$BOOT"
mkfs.btrfs -f -L ROOT "$ROOT"

# Create BTRFS subvolumes (Timeshift and Snapper compatable)
mount "$ROOT" /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@home
btrfs su cr /mnt/@cache
btrfs su cr /mnt/@images
btrfs su cr /mnt/@log
btrfs su cr /mnt/@.snapshots
umount /mnt

# Mount the partitions
mount -o noatime,compress=zstd,discard=async,subvol=@ \
  "$ROOT" /mnt
mkdir -p /mnt/{boot,home,.snapshots,var/{log,cache,lib/libvirt/images}}
mount -o noatime,compress=zstd,discard=async,subvol=@home \
  "$ROOT" /mnt/home
mount -o noatime,compress=zstd,discard=async,subvol=@images \
  "$ROOT" /mnt/var/lib/libvirt/images
mount -o noatime,compress=zstd,discard=async,subvol=@log \
  "$ROOT" /mnt/var/log
mount -o noatime,compress=zstd,discard=async,subvol=@cache \
  "$ROOT" /mnt/var/cache
mount -o noatime,compress=zstd,discard=async,subvol=@.snapshots \
  "$ROOT" /mnt/.snapshots
mount "$BOOT" /mnt/boot
mkdir /mnt/boot/efi # EFI Only
mount "$SYS" /mnt/boot/efi # EFI Only

# Mount System Partitions (old)
udevadm trigger
mkdir -p /mnt/{proc,sys,dev/pts}
mount -t proc proc /mnt/proc
mount -t sysfs sys /mnt/sys
mount -B /dev /mnt/dev
mount -t devpts pts /mnt/dev/pts