#!/bin/bash
set -e

### START: Check for root.
if [ "$EUID" -ne 0 ]
then echo "This script must run as root."
    exit
fi
### END: Check for root.

### START: Set subvolume name, UUIDs, User name, Download URLs, Download directory, Dependencies.
DATE=$(date +"%Y%m%d_%H%M")
SNAME="gentoo_$DATE"
ROOT_UUID="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
BOOT_UUID="XXXX-XXXX"
USERNAME="damiano"
LIVEUSB_URL="https://distfiles.gentoo.org/releases/amd64/autobuilds/current-livegui-amd64/livegui-amd64-20250315T023326Z.iso"
CHECKSUM_URL="https://distfiles.gentoo.org/releases/amd64/autobuilds/current-livegui-amd64/livegui-amd64-20250315T023326Z.iso.sha256"
DOWNLOAD_DIR="/tmp/gentoo_liveusb"
DEPS=("7z" "btrfs" "unsquashfs" "arch-chroot")
### END: Set subvolume name, UUIDs, User name, Download URLs, Download directory, Dependencies.

### START: Check for required dependencies.
echo "Checking for dependencies ..."
for DEP in "${DEPS[@]}"; do
    if ! command -v "$DEP" &>/dev/null; then
        echo "Error: Required package '$DEP' is not installed. Please install it first."
        exit 1
    fi
done
echo "Checking for dependencies: OK"
### END: Check for required dependencies.

### START: Check if unsquashfs supports XZ compression
echo "Checking that unsquashfs has xz support ..."
if ! unsquashfs -h 2>&1 | grep -q 'xz'; then
    echo "Error: unsquashfs does not support XZ compression. Ensure squashfs-tools is compiled with XZ support."
    echo "On gentoo you need USE=lzma when compiling"
    exit 1
fi
echo "Checking that unsquashfs has xz support: OK"
### END: Check if unsquashfs supports XZ compression.

### START: Download the LiveUSB and checksum and verify checksum.
echo "Downloading iso and sha256sum ..."
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"
wget --no-clobber --timeout=10 --tries=3 "$LIVEUSB_URL"
wget --no-clobber --timeout=10 --tries=3 "$CHECKSUM_URL"
echo "Downloading iso and sha256sum OK"
echo "Verifying sha256sum ..."
sha256sum -c *.sha256 || {
    echo "Checksum verification failed! Exiting."
    exit 1
}
echo "Verifying sha256sum: OK"
### END: Download the LiveUSB and checksum and verify checksum.

### START: Unmount everything and create mountpoints.
echo "Unmounting /mnt/boot and /mnt ..."
if mountpoint /mnt/boot
then
    umount -R /mnt/boot
fi
if mountpoint /mnt
then
    umount -R /mnt
fi
mkdir -p /mnt
echo "Unmounting /mnt/boot and /mnt: OK"
### END: Unmount everything and create mountpoints.

### START: Create subvolume for next generation.
echo "Creating subvolumes for next generation ..."
mount /dev/disk/by-uuid/"$ROOT_UUID" /mnt/
btrfs subvolume create /mnt/"$SNAME" 
umount /mnt/
mount /dev/disk/by-uuid/"$ROOT_UUID" -o subvol="$SNAME" /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-uuid/"$BOOT_UUID" /mnt/boot/
mount -o remount,rw /dev/disk/by-uuid/"$BOOT_UUID" /mnt/boot/
echo "Creating subvolumes for install: OK"
### END: Create subvolume for next generation.

###  START: Copy and extract live-image.
echo "Copying and extracting live-image ..."
7z x livegui-amd64-*.iso "image.squashfs"
unsquashfs image.squashfs
cp -a squashfs-root/* /mnt/
rm -r squashfs-root image.squashfs
echo "Copying and extracting live-image: OK"
###  END: Copy and extract live-image.

### START: Create fstab entries and boot entry.
echo "Create fstab entries and boot entry ..."
cat <<EOF > /mnt/etc/fstab
UUID="$ROOT_UUID" / btrfs rw,relatime,subvol=/$SNAME 0 1
UUID="$BOOT_UUID" /boot vfat defaults,fmask=0137,dmask=0027 0 2
EOF

# Store kernel name for boot entry
LINUX=$(ls /mnt/lib/modules)
cat <<EOF > /mnt/boot/loader/entries/$SNAME.conf
title   $SNAME
linux   /vmlinuz-$LINUX
initrd  /initramfs-$LINUX.img
options root=UUID=$ROOT_UUID rootflags=subvol=$SNAME rw rootfstype=btrfs i915.enable_psr=0
EOF
echo "Create fstab entries and boot entry: OK"
### END: Create fstab entries and boot entry.

### START: Configure system.
echo "Configure system ..."
# Setup profile and locale
ln -sf ../usr/share/zoneinfo/Europe/Stockholm /mnt/etc/localtime
sed -i -e "s/^#en_US.UTF.*/en_US.UTF-8 UTF-8/g" /mnt/etc/locale.gen 

# Personalize portage.
cat <<EOF >> /mnt/etc/portage/make.conf 
MAKEOPTS="-j4 -l5"
FEATURES="getbinpkg binpkg-request-signature"
ACCEPT_LICENSE="*"
EOF

# You can also set other USE-flags here, for example:
#cat <<EOF > /mnt/etc/portage/package.use/keepassxc 
## Browser integration
#app-admin/keepassxc browser
#EOF

sed -i -e "s/^priority = 1/priority = 9999/g" /mnt/etc/portage/binrepos.conf/gentoobinhost.conf

# Set hostname.
cat <<EOF > /mnt/etc/hostname
gentoo
EOF

# Set vconsole keymap.
cat <<EOF > /mnt/etc/vconsole.conf
KEYMAP=sv-latin1
EOF

# Change which user is automatically logged in.
sed -i -e "s/^User=gentoo/User=$USERNAME/" /mnt/etc/sddm.conf

# Make sudo require password.
sed -i -e "s/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/" /mnt/etc/sudoers
sed -i -e "s/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/" /mnt/etc/sudoers

# Create and setup user account.
# Password set to "password", change with passwd after install.
# You can also create a password here with 
# perl -e 'print crypt("YourPassword", "YourSalt"),"\n"'
arch-chroot /mnt env -i useradd -p "Heq5ZtRwPepeA" -m -G wheel,pipewire $USERNAME
echo "Configure system: OK"

echo "You can now use arch-chroot to install any missing packages, to remove packages, update the system, etc."
echo "Otherwise just reboot into your new system!"

### END: Configure system.

set +e
