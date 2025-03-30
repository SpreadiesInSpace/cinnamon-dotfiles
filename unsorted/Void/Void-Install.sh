#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run the script as superuser"
  exit
fi

# Refresh (for older ISOs)
xbps-install -Sy

# Install tools
xbps-install -y parted xtools

# Prompt for root password
read -sp "Enter new root password: " rootpasswd
echo

# Prompt for new user details
read -p "Enter new username: " username
read -sp "Enter password for $username: " userpasswd
echo

# Prompt for hostname
read -p "Enter hostname: " hostname

# Prompt for drive to partition
echo
lsblk
echo
read -p "Enter drive to use (e.g., /dev/sda, /dev/vda, /dev/nvme0n1, /dev/mmcblk0): " drive

# Partition the drive
echo "Partitioning $drive..."
parted -s "$drive" mklabel gpt
parted -s "$drive" mkpart primary fat32 1MiB 513MiB
parted -s "$drive" set 1 esp on
parted -s "$drive" mkpart primary btrfs 513MiB 100%

# Format the partitions
if [[ "$drive" == *"nvme"* ]] || [[ "$drive" == *"mmcblk"* ]]; then
  mkfs.vfat "${drive}p1"
  mkfs.btrfs -f "${drive}p2"
else
  mkfs.vfat "${drive}1"
  mkfs.btrfs -f "${drive}2"
fi

# Mount the partitions and create BTRFS subvolumes
if [[ "$drive" == *"nvme"* ]] || [[ "$drive" == *"mmcblk"* ]]; then
  mount "${drive}p2" /mnt
else
  mount "${drive}2" /mnt
fi

btrfs su cr /mnt/@
btrfs su cr /mnt/@home
umount /mnt

if [[ "$drive" == *"nvme"* ]] || [[ "$drive" == *"mmcblk"* ]]; then
  mount -o noatime,compress=zstd,space_cache=v2,subvol=@ "${drive}p2" /mnt
  mkdir -p /mnt/home
  mount -o noatime,compress=zstd,space_cache=v2,subvol=@home "${drive}p2" /mnt/home
  mkdir -p /mnt/boot/efi
  mount "${drive}p1" /mnt/boot/efi
else
  mount -o noatime,compress=zstd,space_cache=v2,subvol=@ "${drive}2" /mnt
  mkdir -p /mnt/home
  mount -o noatime,compress=zstd,space_cache=v2,subvol=@home "${drive}2" /mnt/home
  mkdir -p /mnt/boot/efi
  mount "${drive}1" /mnt/boot/efi
fi

# Install Base System
# REPO=https://repo-fastly.voidlinux.org/current
REPO=https://mirror.vofr.net/voidlinux/current
ARCH=x86_64 
mkdir -p /mnt/var/db/xbps/keys
cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/
XBPS_ARCH=$ARCH xbps-install -Sy -r /mnt -R "$REPO" base-system

# Copy Network Info 
cp --dereference /etc/resolv.conf /mnt/etc/

# Generate fstab
xgenfstab -U /mnt > /mnt/etc/fstab

# Entering Chroot
cat << EOF | xchroot /mnt /bin/bash

# New Chroot Environment
source /etc/profile
xbps-install -Syu
xbps-install -y git xtools xmirror nano NetworkManager

# Change shell to bash
chsh -s /bin/bash

# Set Hostname
echo "$hostname" > /etc/hostname

# Enable Networking
ln -s /etc/sv/NetworkManager /var/service

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

# Installing Grub
xbps-install -y grub-x86_64-efi
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id="Void"

# Set GRUB timeout to 0
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
# grub-mkconfig -o /boot/grub/grub.cfg

# Reconfigure System
xbps-reconfigure -fa

# Clone My Repo as the new user
xbps-install -y git bash-completion
cat << EOUSR | su - $username
cd
git clone https://github.com/SpreadiesInSpace/cinnamon-dotfiles
cd cinnamon-dotfiles
echo "Reboot and run Setup-Void.sh in cinnamon-dotfiles located in $username's home folder."
EOUSR
EOF

