#!/bin/bash
set -euo pipefail

# Turn SELinux back on if script is interrupted
trap 'fixfiles -F onboot' ERR INT TERM

# Download and source common functions
echo "Sourcing functions..."
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }
URL="https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles"
URL="$URL/main/extra/ISO/Install-Common.sh"
curl -fsSL -o Install-Common.sh "$URL" || \
	die "Failed to download Install-Common.sh"
[ -f ./Install-Common.sh ] || die "Install-Common.sh not found."
source ./Install-Common.sh || die "Failed to source Install-Common.sh"

# Temporarily disable SELinux
setenforce 0 || \
	die "Failed to disable SELinux"

# Disable Problem Reporting
systemctl disable --now abrtd.service >/dev/null 2>&1 || true

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

# Prompt for drive to partition
prompt_drive

# Partition the drive
partition_drive "fedora"

# Determine correct partition suffix
partition_suffix "fedora"

# Format the partitions
format_partitions

# Create BTRFS subvolumes
create_btrfs_subvolumes

# Mount the partitions
mount_partitions

# Mount System Partitions
mount_system_partitions

# Declare Version
source /etc/os-release || \
	die "Failed to source /etc/os-release."
export VERSION_ID="$VERSION_ID" || \
	die "Failed to extract Fedora version."

# Install Core Fedora Packages
dnf --installroot=/mnt --releasever="$VERSION_ID" \
	--setopt=max_parallel_downloads=10 \
	--use-host-config group install -y core cinnamon-desktop || \
	die "Failed to install core packages."

# Install System Packages
dnf --installroot=/mnt --setopt=max_parallel_downloads=10 \
	install -y glibc-langpack-en btrfs-progs efi-filesystem efibootmgr fwupd \
	grub2-common grub2-efi-x64 grub2-pc grub2-pc-modules grub2-tools \
	grub2-tools-efi grub2-tools-extra grub2-tools-minimal grubby kernel \
	mokutil shim-x64 arch-install-scripts git unzip spice-vdagent iwlwifi-* \
	microcode_ctl || \
	die "Failed to install system packages."

# Copy Network Info
mv /mnt/etc/resolv.conf /mnt/etc/resolv.conf.orig || \
	die "Failed to move original /etc/resolv.conf"
[ ! -e /etc/resolv.conf ] && die "Source resolv.conf does not exist."
cp --dereference /etc/resolv.conf /mnt/etc/ || \
	die "Failed to copy resolv.conf."

# Copy common functions to chroot environment
cp Install-Common.sh /mnt/ || \
	die "Failed to copy Install-Common.sh to chroot."

# Ensure variables are exported before chroot
export drive hostname timezone username rootpasswd userpasswd BOOTMODE \
	REMOVABLE_BOOT || \
	die "Failed to export required variables."

# Chrooting
cat << EOF | chroot /mnt /bin/bash || die "Failed to enter chroot."

# Source common functions inside chroot
source Install-Common.sh || \
	{ echo "Failed to source Install-Common.sh in chroot."; exit 1; }

# New Chroot
source /etc/profile || die "Failed to source /etc/profile."

# Configure lightdm
systemctl set-default graphical || \
	die "Failed to set default target to graphical."

# Disable Problem Reporting
systemctl disable abrtd.service >/dev/null 2>&1 || true

# Generate fstab
genfstab -U / > /etc/fstab || die "Failed to generate fstab."

# Remove zram swap entries from fstab
sed -i '/zram.*LABEL=zram/d' /etc/fstab || \
	die "Failed to remove zram entries from fstab."
sed -i '/none.*swap.*defaults,pri=/d' /etc/fstab || \
	die "Failed to remove zram entries from fstab."

# Generate /etc/default/grub
cat >> /etc/default/grub << 'ETC' || die "Failed to create /etc/default/grub"
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="rhgb quiet"
GRUB_DISABLE_RECOVERY="true"
GRUB_ENABLE_BLSCFG=true
ETC

# Backup original /etc/default/grub
cp /etc/default/grub /etc/default/grub.orig || \
	die "Failed to backup original /etc/default/grub."

# Remove boot splash
sed -i 's/rhgb quiet/quiet/' /etc/default/grub || \
	die "Failed to remove boot splash."

# Configure GRUB Bootloader
if [ "$BOOTMODE" = "UEFI" ]; then
	# Reinstall these to regenerate grub.cfg
	rm -rf /boot/efi/EFI/fedora/grub.cfg /boot/grub2/grub2.cfg
	dnf reinstall -y shim-* grub2-efi-* grub2-common
	# Add signed Fedora Boot SHIM (for UEFI Secure Boot)
	efibootmgr -c -d "$drive" -p 1 -L "Fedora (Custom)" \
		-l \\EFI\FEDORA\\SHIMX64.EFI || \
		die "Failed to add signed Fedora Boot SHIM."
else
	install_grub "fedora"
fi

# Set GRUB timeout to 0
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub || \
	die "Failed to set GRUB_TIMEOUT."

# Configure zRAM
configure_zram

# Regenerate Grub Config
grub2-mkconfig -o /boot/grub2/grub.cfg || \
	die "Failed to generate GRUB config."

# Set Timezone
ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime || \
	die "Failed to set timezone."
hwclock --systohc || die "Failed to set hardware clock."

# Set Locale
echo "LANG=en_US.UTF-8" > /etc/locale.conf || \
	die "Failed to set /etc/locale.conf."
echo 'RC_LANG="en_US.UTF-8"' > /etc/sysconfig/language || \
	die "Failed to set /etc/sysconfig/language."

# Set Keymap
echo "KEYMAP=us" > /etc/vconsole.conf || die "Failed to set keymap."

# Set Hostname
echo "$hostname" > /etc/hostname || die "Failed to set hostname."

# Allow Resolving the Local Hostname
echo -e "127.0.1.1\t$hostname.localdomain\t$hostname" >> /etc/hosts || \
	die "Failed to write to /etc/hosts."

# Create User
useradd -m -G users,wheel,audio,video -s /bin/bash "$username" || \
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

# Turn SELinux back on
fixfiles -F onboot || die "Failed to turn SELinux back on."

# Clean up
rm -rf Install-Common.sh

# Clone cinnamon-dotfiles repo as new user
clone_dotfiles "fedora-42"
EOF