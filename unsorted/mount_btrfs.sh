#!/bin/bash

# BTRFS Subvolumes (for Timeshift) - 512MB EFI + Remaining BTRFS
mkfs.vfat /dev/vda1
mkfs.btrfs -f /dev/vda2
mount /dev/vda2 /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@home
umount /mnt

# BTRFS Mounts (ssd autodetects since 2011, space_cache=v2 default since Kernel 5.15)
mount -o noatime,compress=zstd,discard=async,subvol=@ /dev/vda2 /mnt/ 
mkdir -p /mnt/home
mount -o noatime,compress=zstd,discard=async,subvol=@home /dev/vda2 /mnt/home 
mkdir -p /mnt/boot/efi
mount /dev/vda1 /mnt/boot/efi
