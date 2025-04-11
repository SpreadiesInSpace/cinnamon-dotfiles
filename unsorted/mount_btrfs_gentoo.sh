#!/bin/bash

# BTRFS Subvolumes (for Timeshift) - 512MB EFI + Remaining BTRFS
mkfs.vfat /dev/vda1
mkfs.btrfs -f /dev/vda2
mount /dev/vda2 /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@home
umount /mnt

# BTRFS Mounts - Gentoo
mkdir -p /mnt/gentoo
mount -o noatime,compress=zstd,discard=async,subvol=@ /dev/vda2 /mnt/gentoo 
mkdir -p /mnt/gentoo/home
mount -o noatime,compress=zstd,discard=async,subvol=@home /dev/vda2 /mnt/gentoo/home 
mkdir -p /mnt/gentoo/efi
mount /dev/vda1 /mnt/gentoo/efi
