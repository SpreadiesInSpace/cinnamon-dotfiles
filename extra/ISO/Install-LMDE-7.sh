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

# Update APT cache and install debootstrap
retry apt update || \
  die "Failed to refresh APT repositories."
retry apt install -y debootstrap arch-install-scripts || \
  die "Failed to install debootstrap."

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

# Install the Base System
if [ "$BOOTMODE" = "UEFI" ]; then
  GRUB_PKG="grub-efi-amd64"
else
  GRUB_PKG="grub-pc"
fi
retry debootstrap \
  --include linux-image-amd64,"$GRUB_PKG",locales,ca-certificates \
  --arch amd64 trixie /mnt || \
   die "Failed to install base packages."

# Copy sources from ISO to installed system
mkdir -p /mnt/etc/apt/{sources.list.d,preferences.d} || \
  die "Failed to create apt directories."
cp /etc/apt/sources.list /mnt/etc/apt/sources.list || \
  die "Failed to copy sources.list."
cp /etc/apt/sources.list.d/official-package-repositories.list \
  /mnt/etc/apt/sources.list.d/official-package-repositories.list || \
  die "Failed to copy official-package-repositories.list."
cp -r /etc/apt/{preferences.d,trusted.gpg.d} /mnt/etc/apt/ || \
  die "Failed to copy APT preferences."

# Locale Generation (uncomment en_US.UTF-8 UTF-8 in /etc/locale.gen)
arch-chroot /mnt sed -i 's/^#\s*\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen || \
  die "Failed to uncomment locale."
arch-chroot /mnt locale-gen || die "Failed to generate locale."

# Set Locale
arch-chroot /mnt echo "LANG=en_US.UTF-8" > /etc/locale.conf || \
  die "Failed to set locale."

# Install System Packages
retry arch-chroot /mnt bash -c \
  'DEBIAN_FRONTEND=noninteractive apt install -y \
  amd64-microcode arch-install-scripts bash-completion \
  blueman bluez-firmware btrfs-progs cinnamon dbus \
  dbus-user-session dbus-x11 dialog firmware-atheros \
  firmware-bnx2 firmware-bnx2x firmware-brcm80211 \
  firmware-intel-graphics firmware-intel-misc \
  firmware-intel-sound firmware-iwlwifi firmware-linux \
  firmware-linux-nonfree firmware-misc-nonfree \
  firmware-realtek firmware-sof-signed \
  ffmpegthumbnailer git gnome-terminal grub2-theme-mint \
  intel-microcode intel-media-va-driver libnotify-bin \
  lightdm linuxmint-keyring mesa-va-drivers \
  mesa-vulkan-drivers mint-common mint-info-cinnamon \
  mintinstall mintreport mint-meta-cinnamon mintsources \
  mintupdate mintsystem nano network-manager pipewire \
  pipewire-alsa pipewire-pulse pulseaudio-utils \
  python3-dbus slick-greeter spice-vdagent sudo \
  systemd-zram-generator unzip util-linux-extra vainfo \
  wget wireplumber xorg xserver-xorg-core \
  xserver-xorg-input-libinput xserver-xorg-video-all' \
  || die "Failed to install packages."

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab || \
  die "Failed to generate fstab."

# Copy common functions to chroot environment
cp Install-Common.sh Master-Common.sh /mnt/ || \
  die "Failed to copy Install-Common.sh to chroot."

# Ensure variables are exported before chroot
export drive hostname timezone username rootpasswd userpasswd BOOTMODE \
  REMOVABLE_BOOT grub_timeout || \
  die "Failed to export required variables."

# Entering Chroot
cat << EOF | arch-chroot /mnt /bin/bash || die "Failed to enter chroot."

# Source common functions inside chroot
source Install-Common.sh || \
  { echo "Failed to source Install-Common.sh in chroot."; exit 1; }

# New Chroot
source /etc/profile || die "Failed to source /etc/profile."

# Set Timezone
ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime || \
  die "Failed to set timezone."
hwclock --systohc || die "Failed to set hardware clock."

# Set Hostname
echo "$hostname" > /etc/hostname || die "Failed to set hostname."

# Allow Resolving the Local Hostname
echo -e "127.0.1.1\t$hostname.localdomain\t$hostname" >> /etc/hosts || \
  die "Failed to write to /etc/hosts."

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

# Setup Sudo by uncommenting %wheel ALL=(ALL:ALL) with visudo (not applicable)
# sed -i 's/^#\s*\(%wheel ALL=(ALL:ALL) ALL\)/\1/' /etc/sudoers || \
#  die "Failed to enable sudo for wheel group."

# Create User and Set Passwords
useradd -m -G users,sudo,audio,video -s /bin/bash "$username" || \
  die "Failed to create user."
echo "root:$rootpasswd" | chpasswd || \
  die "Failed to set root password."
echo "$username:$userpasswd" | chpasswd || \
  die "Failed to set user password."

# Enabling System Services
systemctl enable dbus NetworkManager bluetooth || \
  die "Failed to enable services."

# Clean up
rm -rf Install-Common.sh Master-Common.sh

# Clone cinnamon-dotfiles repo as new user
clone_dotfiles "lmde-7"

# Setup GRUB theme
setup_grub_theme "LMDE"
EOF
