### GPT Partition Layout - (1GiB EFI + Remaining BTRFS)
```bash
parted -s /dev/vda mklabel gpt
parted -s /dev/vda mkpart primary fat32 1MiB 1050MiB
parted -s /dev/vda set 1 esp on
parted -s /dev/vda mkpart primary btrfs 1050MiB 100%
```

### MBR Partition Layout
```bash
parted -s /dev/vda mklabel msdos
parted -s /dev/vda mkpart primary btrfs 1MiB 100%
```

### BTRFS Subvolumes (for Timeshift)
```bash
mkfs.vfat /dev/vda1 # GPT Only
mkfs.btrfs -f /dev/vda2 # /dev/vda for MBR
mount /dev/vda2 /mnt # /dev/vda for MBR
btrfs su cr /mnt/@
btrfs su cr /mnt/@home
umount /mnt
```

### BTRFS Mounts (ssd autodetects since 2011, space_cache=v2 default since Kernel 5.15)
```bash
mount -o noatime,compress=zstd,discard=async,subvol=@ /dev/vda2 /mnt/ 
mkdir -p /mnt/home
mount -o noatime,compress=zstd,discard=async,subvol=@home /dev/vda2 /mnt/home 
mkdir -p /mnt/boot/efi # UEFI Only
mount /dev/vda1 /mnt/boot/efi # UEFI Only
```

### BTRFS Mounts - Gentoo
```bash
mkdir -p /mnt/gentoo
mount -o noatime,compress=zstd,discard=async,subvol=@ /dev/vda2 /mnt/gentoo 
mkdir -p /mnt/gentoo/home
mount -o noatime,compress=zstd,discard=async,subvol=@home /dev/vda2 /mnt/gentoo/home 
mkdir -p /mnt/gentoo/efi # UEFI Only
mount /dev/vda1 /mnt/gentoo/efi # UEFI Only
