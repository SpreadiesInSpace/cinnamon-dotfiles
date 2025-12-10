#!/bin/bash
set -euo pipefail

# Download and source common functions
echo "Sourcing functions..."
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }
URL="https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles"
URL="$URL/main/extra/ISO/Install-Common.sh"
curl -fsSL -o Install-Common.sh "$URL" || \
  die "Failed to download Install-Common.sh"
[ -f ./Install-Common.sh ] || die "Install-Common.sh not found."
source ./Install-Common.sh || die "Failed to source Install-Common.sh"

# Check if script is run as root
check_if_root

# Detect if booted in UEFI or BIOS mode
detect_boot_mode

# Sync time and hardware clock
time_sync

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

# Prompt for GRUB timeout
prompt_grub_timeout

# Prompt for drive to partition
prompt_drive

# Update keyring (for older ISOs)
echo "Initializing and populating Pacman keyring..."
pacman-key --init || \
  die "Failed to initialize Pacman keyring."
pacman-key --populate archlinux || \
  die "Failed to populate Arch Linux keys"
retry pacman -Sy --needed --noconfirm archlinux-keyring || \
  die "Failed to update archlinux-keyring."

# Partition the drive
partition_drive "default"

# Determine correct partition suffix
partition_suffix "default"

# Format the partitions
format_partitions

# Create BTRFS subvolumes
create_btrfs_subvolumes

# Mount the partitions
mount_partitions "default"

# Install Essential packages
retry pacstrap -K /mnt base blueman linux linux-firmware cinnamon lightdm \
  lightdm-slick-greeter gnome-terminal spice-vdagent sudo bash-completion \
    grub efibootmgr git networkmanager nano unzip wget zram-generator || \
    die "Failed to install base packages."

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab || \
  die "Failed to generate fstab."

# Enable Services
systemctl --root=/mnt enable lightdm NetworkManager bluetooth || \
  die "Failed to enable services."

# Copy common functions to chroot environment
cp Install-Common.sh Master-Common.sh /mnt/ || \
  die "Failed to copy Install-Common.sh to chroot."

# Ensure variables are exported before chroot
export drive hostname timezone username rootpasswd userpasswd BOOTMODE \
  REMOVABLE_BOOT grub_timeout || \
  die "Failed to export required variables."

# Entering Chroot
cat << EOF | arch-chroot /mnt || die "Failed to enter chroot."

# Source common functions inside chroot
source Install-Common.sh || \
  { echo "Failed to source Install-Common.sh in chroot."; exit 1; }

# Set Timezone
ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime || \
  die "Failed to set timezone."
hwclock --systohc || die "Failed to set hardware clock."

# Locale Generation (uncomment en_US.UTF-8 UTF-8 in /etc/locale.gen)
sed -i 's/^#\s*\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen || \
  die "Failed to uncomment locale."
locale-gen || die "Failed to generate locale."

# Set Locale
echo "LANG=en_US.UTF-8" > /etc/locale.conf || \
  die "Failed to set locale."

# Set Keymap
echo "KEYMAP=us" > /etc/vconsole.conf || die "Failed to set keymap."

# Set Hostname
echo "$hostname" > /etc/hostname || die "Failed to set hostname."

# Allow Resolving the Local Hostname
echo -e "127.0.1.1\t$hostname.localdomain\t$hostname" >> /etc/hosts || \
  die "Failed to write to /etc/hosts."

# Set LightDM as Display Manager
awk -i inplace '
/^\[Seat:\*\]/ {a=1}
a==1 && /^#?greeter-session=/ {
  print "greeter-session=lightdm-slick-greeter"
  next
}
{print}
' /etc/lightdm/lightdm.conf || \
  die "Failed to set greeter-session for LightDM."

# Configure GRUB Bootloader
install_grub

# Set GRUB_GFXMODE
set_grub_gfxmode

# Set GRUB timeout
sed -i "/^#*GRUB_TIMEOUT=/s/^#*GRUB_TIMEOUT=.*/GRUB_TIMEOUT=$grub_timeout/" \
  /etc/default/grub || \
  die "Failed to set GRUB_TIMEOUT."

# Configure zRAM
configure_zram

# Generate Grub Config
grub-mkconfig -o /boot/grub/grub.cfg || \
  die "Failed to generate GRUB config."

# Setup Sudo by uncommenting %wheel ALL=(ALL:ALL) with visudo
sed -i 's/^#\s*\(%wheel ALL=(ALL:ALL) ALL\)/\1/' /etc/sudoers || \
  die "Failed to enable sudo for wheel group."

# Create User and Set Passwords
useradd -m -G users,wheel,audio,video -s /bin/bash "$username" || \
  die "Failed to create user."
echo "root:$rootpasswd" | chpasswd || \
  die "Failed to set root password."
echo "$username:$userpasswd" | chpasswd || \
  die "Failed to set user password."

# Clean up
rm -rf Install-Common.sh Master-Common.sh

# Clone cinnamon-dotfiles repo as new user
clone_dotfiles "arch"

# Setup GRUB theme
setup_grub_theme "Arch"
EOF
