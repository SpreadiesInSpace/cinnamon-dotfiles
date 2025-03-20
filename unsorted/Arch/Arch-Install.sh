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

# Prompt for hostname
read -p "Enter hostname: " hostname

# Prompt for drive to partition
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

# Install Essential packages
pacstrap -K /mnt base linux linux-firmware sudo bash-completion grub efibootmgr git networkmanager nano

# Generate Fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Entering Chroot
cat << EOF | arch-chroot /mnt

# Set Timezone
ln -sf /usr/share/zoneinfo/Asia/Bangkok /etc/localtime
hwclock --systohc

# Locale Generation
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen

# Set Locale
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf

# Set Hostname
echo "$hostname" > /etc/hostname

# Enable Networking
systemctl enable NetworkManager

# Configure GRUB Bootloader
grub-install --target=x86_64-efi --efi-directory=/boot/efi
# Set GRUB timeout to 0
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Setup Sudo
sed -i 's/^#\s*\(%wheel ALL=(ALL:ALL) ALL\)/\1/' /etc/sudoers

# Set passwords and add user
echo "root:$rootpasswd" | chpasswd
useradd -m -G users,wheel,audio,video -s /bin/bash $username
echo "$username:$userpasswd" | chpasswd

# Clone repo as the new user
cat << EOUSR | su - $username
cd
git clone https://github.com/SpreadiesInSpace/cinnamon-dotfiles
cd cinnamon-dotfiles
echo "Reboot and run Setup-Arch.sh in cinnamon-dotfiles located in $username's home folder."
EOUSR
EOF
