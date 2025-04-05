#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run the script as root"
  exit 1
fi

# Refresh (for older ISOs)
xbps-install -Sy

# Install tools
xbps-install -y parted xtools

# Prompt for root password
read -sp "Enter new root password: " rootpasswd; echo

# Prompt for new user details
read -p "Enter new username: " username
read -sp "Enter password for $username: " userpasswd; echo

# Prompt for hostname
read -p "Enter hostname: " hostname

# Prompt for drive to partition
echo; lsblk; echo
read -p "Enter drive to use (e.g., /dev/sda, /dev/nvme0n1, /dev/mmcblk0): " drive

# Partition the drive
parted -s "$drive" mklabel gpt
parted -s "$drive" mkpart primary fat32 1MiB 513MiB
parted -s "$drive" set 1 esp on
parted -s "$drive" mkpart primary btrfs 513MiB 100%

# Format the partitions
if [[ "$drive" == *"nvme"* || "$drive" == *"mmcblk"* ]]; then
  mkfs.vfat "${drive}p1"
  mkfs.btrfs -f "${drive}p2"
  BOOT="${drive}p1"; ROOT="${drive}p2"
else
  mkfs.vfat "${drive}1"
  mkfs.btrfs -f "${drive}2"
  BOOT="${drive}1"; ROOT="${drive}2"
fi

# Create BTRFS subvolumes
mount "$ROOT" /mnt
btrfs su cr /mnt/@ && btrfs su cr /mnt/@home
umount /mnt

# Mount the partitions
mount -o noatime,compress=zstd,space_cache=v2,subvol=@ "$ROOT" /mnt
mkdir -p /mnt/{boot/efi,home}
mount -o noatime,compress=zstd,space_cache=v2,subvol=@home "$ROOT" /mnt/home
mount "$BOOT" /mnt/boot/efi

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

# Generate Chroot Script
cat > /mnt/chroot-setup.sh <<EOF
#!/bin/bash

# Bash Safety Mode - If any command fails, exit immediately
set -e

# New Chroot Environment
source /etc/profile
xbps-install -Sy
xbps-install -y git xtools xmirror nano sudo grub-x86_64-efi bash-completion

# Change shell to bash
chsh -s /bin/bash

# Set Hostname
echo "$hostname" > /etc/hostname

# Set Timezone
ln -sf /usr/share/zoneinfo/Asia/Bangkok /etc/localtime

# Locale Generation (uncomment en_US.UTF-8 UTF-8)
echo "en_US.UTF-8 UTF-8" > /etc/default/libc-locales
xbps-reconfigure -f glibc-locales

# Add User
useradd -m -G users,wheel,audio,video,plugdev -s /bin/bash "$username"

# Set Passwords
echo "root:$rootpasswd" | chpasswd
echo "$username:$userpasswd" | chpasswd

# Setup Sudo by uncommenting %wheel ALL=(ALL:ALL) with visudo
sed -i 's/^#\s*\(%wheel ALL=(ALL:ALL) ALL\)/\1/' /etc/sudoers

# Installing Grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id="Void"

# Set GRUB timeout to 0
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub

# Reconfigure System
xbps-reconfigure -fa

# Clone My Repo as the new user
su - "$username" -c 'git clone https://github.com/SpreadiesInSpace/cinnamon-dotfiles && echo "Reboot and run Setup-Void.sh from your home directory."'

# Delete Generated Script
rm -- "\$0"
EOF

# Make Script Executable
chmod +x /mnt/chroot-setup.sh

# Chroot and Run Script
xchroot /mnt /chroot-setup.sh
