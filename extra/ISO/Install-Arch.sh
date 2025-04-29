#!/bin/bash

# Download and source common functions
echo "Sourcing functions..."
curl -fsSL -o Install-Common.sh https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles/main/extra/ISO/Install-Common.sh || { echo "Failed to download Install-Common.sh"; exit 1; }
[ -f ./Install-Common.sh ] && source ./Install-Common.sh || { echo "Failed to source Install-Common.sh."; exit 1; }

# Check if script is run as root
check_if_root

# Detect if booted in UEFI or BIOS mode
detect_boot_mode

# Prompt for root password
prompt_root_password

# Prompt for new username
prompt_username

# Prompt for new user password
prompt_user_password

# Prompt for hostname
prompt_hostname

# Prompt for timezone
prompt_timezone

# Prompt for drive to partition
prompt_drive

# Update keyring (for older ISOs)
echo "Updating keyring..."
pacman -Sy --needed --noconfirm archlinux-keyring || die "Failed to update keyring."

# Partition the drive
partition_drive

# Determine correct partition suffix
partition_suffix

# Format the partitions
format_partitions

# Create BTRFS subvolumes
create_btrfs_subvolumes

# Mount the partitions
mount_partitions

# Install Essential packages
pacstrap -K /mnt base linux linux-firmware sudo bash-completion grub efibootmgr git networkmanager nano unzip || die "Failed to install base packages."

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab || die "Failed to generate fstab."

# Entering Chroot
cat << EOF | arch-chroot /mnt || die "Failed to enter chroot."

# Set Timezone
ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime
hwclock --systohc

# Locale Generation (uncomment en_US.UTF-8 UTF-8 in /etc/locale.gen)
sed -i 's/^#\s*\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen

# Set Locale
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Set Keymap
echo "KEYMAP=us" > /etc/vconsole.conf

# Set Hostname
echo "$hostname" > /etc/hostname

# Allow Resolving the Local Hostname
echo -e "127.0.1.1\t$hostname.localdomain\t$hostname" >> /etc/hosts

# Enable Networking
systemctl enable NetworkManager

# Configure GRUB Bootloader
if [ "$BOOTMODE" = "UEFI" ]; then
  if [ "$REMOVABLE_BOOT" = "1" ]; then
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --removable
  else
    grub-install --target=x86_64-efi --efi-directory=/boot/efi
  fi
else
  grub-install --target=i386-pc --boot-directory=/boot "$drive"
fi

# Set GRUB timeout to 0
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub

# Generate Grub Config
grub-mkconfig -o /boot/grub/grub.cfg

# Setup Sudo by uncommenting %wheel ALL=(ALL:ALL) with visudo
sed -i 's/^#\s*\(%wheel ALL=(ALL:ALL) ALL\)/\1/' /etc/sudoers

# Create User and Set Passwords
useradd -m -G users,wheel,audio,video -s /bin/bash "$username"
echo "root:$rootpasswd" | chpasswd
echo "$username:$userpasswd" | chpasswd

# Clone Repo as New User
cat << 'CLONE' | su - "$username"
cd; git clone https://github.com/SpreadiesInSpace/cinnamon-dotfiles
cd cinnamon-dotfiles
touch .arch.done
echo "Reboot and run Setup.sh in cinnamon-dotfiles located in $username's home folder."
CLONE
EOF
