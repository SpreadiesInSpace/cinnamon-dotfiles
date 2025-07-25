#!/bin/bash
set -euo pipefail

# Download and source common functions
echo "Sourcing functions..."
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }
wget -qO Install-Common.sh https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles/main/extra/ISO/Install-Common.sh 2>/dev/null || die "Failed to download Install-Common.sh"
[ -f ./Install-Common.sh ] && source ./Install-Common.sh || die "Failed to source Install-Common.sh"

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

# Refresh repository and install tools
xbps-install -Sy parted xtools || die "Failed to install parted and xtools."

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

# Install Base System and Packages
REPO=https://repo-fi.voidlinux.org/current
# REPO=https://mirror.vofr.net/voidlinux/current
# REPO=https://repo-fastly.voidlinux.org/current
ARCH=x86_64 
mkdir -p /mnt/var/db/xbps/keys || die "Failed to create /mnt/var/db/xbps/keys."
cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/ || die "Failed to copy XBPS keys."
XBPS_ARCH=$ARCH xbps-install -Syu -r /mnt -R "$REPO" base-system cinnamon dejavu-fonts-ttf lightdm lightdm-gtk-greeter-settings lightdm-gtk3-greeter gnome-terminal spice-vdagent xorg-minimal xorg-input-drivers xorg-video-drivers NetworkManager alsa-pipewire libspa-bluetooth pipewire wireplumber git xtools xmirror nano sudo grub grub-x86_64-efi bash-completion unzip || die "Failed to install base packages."

# Enable Services
for service in dbus lightdm NetworkManager polkitd spice-vdagentd; do
  chroot /mnt ln -sfv /etc/sv/$service /etc/runit/runsvdir/default || die "Failed to enable service $service."
done

# Copy Network Info 
cp --dereference /etc/resolv.conf /mnt/etc/ || die "Failed to copy resolv.conf."

# Generate fstab
xgenfstab -U /mnt > /mnt/etc/fstab || die "Failed to generate fstab."

# Ensure variables are exported before chroot
export drive hostname timezone username rootpasswd userpasswd BOOTMODE REMOVABLE_BOOT || die "Failed to export required variables."

# Entering Chroot
cat << EOF | xchroot /mnt /bin/bash || die "Failed to enter chroot."

# Minimal Error Handling function
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

# New Chroot Environment
source /etc/profile || die "Failed to source /etc/profile."

# Change shell to bash
chsh -s /bin/bash || die "Failed to change shell to bash."

# Set Hostname
echo "$hostname" > /etc/hostname || die "Failed to set hostname"

# Allow Resolving the Local Hostname
echo -e "127.0.1.1\t$hostname.localdomain\t$hostname" >> /etc/hosts || die "Failed to write to /etc/hosts."

# Set Timezone
ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime || die "Failed to set timezone."
hwclock --systohc || die "Failed to sync hardware clock"

# Locale Generation (uncomment en_US.UTF-8 UTF-8) in /etc/default/libc-locales
sed -i 's/^#\s*\(en_US.UTF-8 UTF-8\)/\1/' /etc/default/libc-locales || die "Failed to uncomment locale."
xbps-reconfigure -f glibc-locales || die "Failed to generate locale"

# Create User
useradd -m -G users,wheel,audio,video,plugdev -s /bin/bash "$username"  || die "Failed to create user."

# Set Root Password
passwd root << PASSWORD || die "Failed to set root password."
$rootpasswd
$rootpasswd
PASSWORD

# Set User Password
passwd "$username" << PASSWORD || die "Failed to set user password."
$userpasswd
$userpasswd
PASSWORD

# Setup Sudo by uncommenting %wheel ALL=(ALL:ALL) with visudo
sed -i 's/^#\s*\(%wheel ALL=(ALL:ALL) ALL\)/\1/' /etc/sudoers || die "Failed to enable sudo for wheel group."

# Configure GRUB Bootloader
if [ "$BOOTMODE" = "UEFI" ]; then
  if [ "$REMOVABLE_BOOT" = "1" ]; then
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --removable || die "Failed to install GRUB (UEFI removable)."
  else
    grub-install --target=x86_64-efi --efi-directory=/boot/efi || die "Failed to install GRUB (UEFI)."
  fi
else
  grub-install --target=i386-pc --boot-directory=/boot "$drive" || die "Failed to install GRUB (BIOS)."
fi

# Set GRUB timeout to 0
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub || die "Failed to set GRUB_TIMEOUT."

# Generate Grub Config (xbps-reconfigure -fa takes care of this)
# grub-mkconfig -o /boot/grub/grub.cfg  || die "Failed to generate GRUB config"

# Reconfigure System
xbps-reconfigure -fa || die "Failed to reconfigure system."

# Clone Repo as New User
cat << 'CLONE' | su - "$username"
cd && git clone https://github.com/SpreadiesInSpace/cinnamon-dotfiles || { echo "Failed to clone repo."; exit 1; }
cd cinnamon-dotfiles || { echo "Failed to enter repo directory."; exit 1; }
touch .void.done || { echo "Failed to create flag."; exit 1; }
echo "Reboot and run Setup.sh in cinnamon-dotfiles located in \$HOME/cinnamon-dotfiles."
CLONE
EOF
