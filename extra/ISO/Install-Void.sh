#!/bin/bash
set -euo pipefail

# Download and source common functions
echo "Sourcing functions..."
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }
URL="https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles"
URL="$URL/main/extra/ISO/Install-Common.sh"
wget -qO Install-Common.sh "$URL" 2>/dev/null || \
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

# Confirm before proceeding
prompt_confirm

# Refresh repository and install tools
retry xbps-install -Sy parted xtools || \
  die "Failed to install parted and xtools."

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

# Install Base System and Packages
REPO=https://repo-fi.voidlinux.org/current
# REPO=https://repo-de.voidlinux.org/current
# REPO=https://mirror.vofr.net/voidlinux/current
# REPO=https://repo-fastly.voidlinux.org/current
ARCH=x86_64
mkdir -p /mnt/var/db/xbps/keys || \
  die "Failed to create /mnt/var/db/xbps/keys."
cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/ || \
  die "Failed to copy XBPS keys."
XBPS_ARCH=$ARCH retry xbps-install -Syu -r /mnt -R "$REPO" base-system \
  dejavu-fonts-ttf lightdm lightdm-gtk-greeter-settings lightdm-gtk3-greeter \
  cinnamon gnome-terminal spice-vdagent xorg-minimal xorg-input-drivers \
  xorg-video-drivers NetworkManager alsa-pipewire libspa-bluetooth pipewire \
  wireplumber git xtools xmirror nano sudo grub grub-x86_64-efi \
  bash-completion unzip zramen blueman || \
  die "Failed to install base packages."

# Enable Services
services="bluetoothd dbus lightdm NetworkManager polkitd spice-vdagentd zramen"
for service in $services; do
  chroot /mnt ln -sfv "/etc/sv/$service" /etc/runit/runsvdir/default || \
    die "Failed to enable service $service."
done

# Copy Network Info
cp --dereference /etc/resolv.conf /mnt/etc/ || \
  die "Failed to copy resolv.conf."

# Generate fstab
xgenfstab -U /mnt > /mnt/etc/fstab || \
  die "Failed to generate fstab."

# Copy common functions to chroot environment
cp Install-Common.sh Master-Common.sh /mnt/ || \
  die "Failed to copy Install-Common.sh to chroot."

# Ensure variables are exported before chroot
export drive hostname timezone username rootpasswd userpasswd BOOTMODE \
  REMOVABLE_BOOT grub_timeout || \
  die "Failed to export required variables."

# Entering Chroot
cat << EOF | xchroot /mnt /bin/bash || die "Failed to enter chroot."

# Source common functions inside chroot
source Install-Common.sh || \
  { echo "Failed to source Install-Common.sh in chroot."; exit 1; }

# New Chroot Environment
source /etc/profile || die "Failed to source /etc/profile."

# Change shell to bash
chsh -s /bin/bash || die "Failed to change shell to bash."

# Set Hostname
echo "$hostname" > /etc/hostname || die "Failed to set hostname"

# Allow Resolving the Local Hostname
echo -e "127.0.1.1\t$hostname.localdomain\t$hostname" >> /etc/hosts || \
  die "Failed to write to /etc/hosts."

# Set Timezone
ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime || \
  die "Failed to set timezone."
hwclock --systohc || die "Failed to set hardware clock."

# Locale Generation (uncomment en_US.UTF-8 UTF-8) in
# /etc/default/libc-locales
sed -i 's/^#\s*\(en_US.UTF-8 UTF-8\)/\1/' /etc/default/libc-locales || \
  die "Failed to uncomment locale."
xbps-reconfigure -f glibc-locales || die "Failed to generate locale"

# Create User
useradd -m -G users,wheel,audio,video,plugdev -s /bin/bash "$username"  || \
  die "Failed to create user."

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
sed -i 's/^#\s*\(%wheel ALL=(ALL:ALL) ALL\)/\1/' /etc/sudoers || \
  die "Failed to enable sudo for wheel group."

# Configure GRUB Bootloader
install_grub

# Set GRUB_GFXMODE
set_grub_gfxmode

# Set GRUB timeout
sed -i "/^#*GRUB_TIMEOUT=/s/^#*GRUB_TIMEOUT=.*/GRUB_TIMEOUT=$grub_timeout/" \
  /etc/default/grub || \
  die "Failed to set GRUB_TIMEOUT."

# Configure zRAM
configure_zram "void"

# Generate Grub Config (xbps-reconfigure -fa takes care of this)
# grub-mkconfig -o /boot/grub/grub.cfg  || \
  die "Failed to generate GRUB config"

# Reconfigure System
xbps-reconfigure -fa || die "Failed to reconfigure system."

# Clean up
rm -rf Install-Common.sh Master-Common.sh

# Clone cinnamon-dotfiles repo as new user
clone_dotfiles "void"

# Setup GRUB theme
setup_grub_theme "Void"

# Create first-boot script to set monospace font (for gnome-terminal)
set_monospace_font
EOF
