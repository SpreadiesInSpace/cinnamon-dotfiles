#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run the script as superuser"
  exit
fi

# Prompt for root password
read -sp "Enter new root password: " rootpasswd
echo

# Prompt for new user details
read -p "Enter new username: " username
read -sp "Enter password for $username: " userpasswd
echo

# BTRFS Subvolumes (for Timeshift) - Preparing the Disks
mkfs.vfat /dev/vda1
mkfs.btrfs -f /dev/vda2
mount /dev/vda2 /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@home
umount /mnt
mount -o noatime,compress=zstd,space_cache=v2,subvol=@ /dev/vda2 /mnt/ 
mkdir -p /mnt/home
mount -o noatime,compress=zstd,space_cache=v2,subvol=@home /dev/vda2 /mnt/home 
mkdir -p /mnt/boot/efi
mount /dev/vda1 /mnt/boot/efi

# Install Base System
# REPO=https://repo-fastly.voidlinux.org/current
REPO=https://mirror.vofr.net/voidlinux/current
ARCH=x86_64 
mkdir -p /mnt/var/db/xbps/keys
cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/
XBPS_ARCH=$ARCH xbps-install -Sy -r /mnt -R "$REPO" base-system

# Copy Network Info 
cp --dereference /etc/resolv.conf /mnt/etc/

# Entering Chroot
xbps-install -y xtools
cat << EOF | xchroot /mnt /bin/bash

# New Chroot Environment
xbps-install -Syu
xbps-install -y git xtools xmirror nano

# Change shell to bash
chsh -s /bin/bash

# Set Hostname
echo Void > /etc/hostname

# Set Timezone
ln -sf /usr/share/zoneinfo/Asia/Bangkok /etc/localtime

# Locale Generation (uncomment en_US.UTF-8 UTF-8)
echo "en_US.UTF-8 UTF-8" > /etc/default/libc-locales
xbps-reconfigure -f glibc-locales

# Set password for root and user with responses from the start
echo "root:$rootpasswd" | chpasswd
useradd -m -G users,wheel,audio,video,plugdev -s /bin/bash $username 
echo "$username:$userpasswd" | chpasswd

# Setting up Sudo
xbps-install -y sudo
# Setup Sudo by uncommenting %wheel ALL=(ALL:ALL) with visudo
sed -i 's/^#\s*\(%wheel ALL=(ALL:ALL) ALL\)/\1/' /etc/sudoers

# Generate fstab
cp /proc/mounts /etc/fstab
# delete dev cgroup and other termporary mounts and add
# tmpfs /tmp tmpfs defaults,nosuid,nodev 0 0
# change last column value to 1 (file system error corrected) for / and 2 (system should be rebooted) for others
nano /etc/fstab

# Installing Grub
xbps-install -y grub-x86_64-efi
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id="Void"

# Reconfigure System
xbps-reconfigure -fa

# Clone My Repo as the new user
xbps-install -y git bash-completion
cat << EOUSR | su - $username
cd
git clone https://github.com/SpreadiesInSpace/cinnamon-dotfiles
cd cinnamon-dotfiles
# sudo bash Setup-Void.sh
echo "Delete dangling entries (everything but your btrfs and vfat mounts) from /etc/fstab, reboot and run Setup-Void.sh in cinnamon-dotfiles located in $username's home folder."
EOUSR
EOF
