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

# Set Keyboard Layout
loadkeys us
# Sync Time
timedatectl

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

# Install Essential packages
pacstrap -K /mnt base linux linux-firmware sudo bash-completion grub efibootmgr git networkmanager nano #intel-ucode
# Generate Fstab
genfstab -U /mnt >> /mnt/etc/fstab
# Entering Chroot
cat << EOF | arch-chroot /mnt

# Set Timezone
ln -sf /usr/share/zoneinfo/Asia/Bangkok /etc/localtime
# Sync to Hardware Clock
hwclock --systohc
# Locale Generation (uncomment en_US.UTF-8 UTF-8 in /etc/locale.gen)
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
# Set Locale
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "KEYMAP="us"" >> /etc/vconsole.conf
# Hostname
echo Arch > /etc/hostname
# Enable Networking
systemctl enable NetworkManager
# Configuring the Bootloader
grub-install --target=x86_64-efi --efi-directory=/boot/efi
grub-mkconfig -o /boot/grub/grub.cfg
# Setup Sudo by uncommenting %wheel ALL=(ALL:ALL) with visudo
sed -i 's/^#\s*\(%wheel ALL=(ALL:ALL) ALL\)/\1/' /etc/sudoers

# Set password for root and user with responses from the start
echo "root:$rootpasswd" | chpasswd
useradd -m -G users,wheel,audio,video -s /bin/bash $username 
echo "$username:$userpasswd" | chpasswd

# Clone My Repo as the new user
cat << EOUSR | su - $username
cd
git clone https://github.com/SpreadiesInSpace/cinnamon-dotfiles
cd cinnamon-dotfiles
# sudo bash Setup-Arch.sh
echo "Reboot and run Setup-Arch.sh in cinnamon-dotfiles located in $username's home folder."
EOUSR
EOF
