#!/bin/bash
set -euo pipefail

# Download and source common functions
echo "Sourcing functions..."
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }
URL="https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles"
URL="$URL/main/extra/ISO/Install-Common.sh"
if command -v wget >/dev/null 2>&1; then
  wget -qO Install-Common.sh "$URL" || \
    die "Failed to download Install-Common.sh with wget"
elif command -v curl >/dev/null 2>&1; then
  curl -fsSL -o Install-Common.sh "$URL" || \
    die "Failed to download Install-Common.sh with curl"
else
  die "Neither wget nor curl is available"
fi
[ -f ./Install-Common.sh ] || die "Install-Common.sh not found."
source ./Install-Common.sh || die "Failed to source Install-Common.sh"

# Declare variables that will be set by sourced functions
declare init_system

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

# Prompt for init system
prompt_init_system

# Prompt for video card
prompt_video_card

# Partition the drive
partition_drive

# Determine correct partition suffix
partition_suffix

# Format the partitions
format_partitions

# Create BTRFS subvolumes
create_btrfs_subvolumes

# Mount the partitions
mount_partitions "gentoo"

# Store Script Directory (for Install-Common.sh copy to chroot)
SCRIPT_DIR="$(pwd)"

#====================== Gentoo Install - The Stage File =======================

# Move to Mounted Root Partition
cd /mnt/gentoo || \
  die "Failed to change directory to /mnt/gentoo."

# Grab the Latest Systemd Stage 3 Desktop Profile
GENTOO_MIRROR="https://distfiles.gentoo.org"
GENTOO_ARCH="amd64"
GENTOO_INIT="$init_system"
STAGE3_BASENAME="stage3-$GENTOO_ARCH-desktop-$GENTOO_INIT"
RELEASES_URL="$GENTOO_MIRROR/releases/$GENTOO_ARCH/autobuilds"
LATEST_TXT_URL="$RELEASES_URL/latest-$STAGE3_BASENAME.txt"

# Download the latest stage3 list
echo; echo "Downloading latest stage3 list..."
if command -v wget >/dev/null 2>&1; then
  wget -c -T 10 -t 10 -q --show-progress "$LATEST_TXT_URL" -O \
    latest-stage3.txt || \
    die "Failed to download $LATEST_TXT_URL with wget."
elif command -v curl >/dev/null 2>&1; then
  curl -fsSL -C - --retry 10 --connect-timeout 10 "$LATEST_TXT_URL" -o \
    latest-stage3.txt || \
    die "Failed to download $LATEST_TXT_URL with curl."
else
  die "Neither wget nor curl found."
fi

# Import Gentoo release key via WKD
echo; echo "Importing Gentoo release key..."
gpg --quiet --auto-key-locate=clear,nodefault,wkd \
  --locate-key releng@gentoo.org >/dev/null 2>&1 || \
    die "Failed to import Gentoo release key."

# Verify the PGP signature of the latest-stage3.txt file
echo "Verifying GPG signature of latest-stage3.txt..."
gpg --verify latest-stage3.txt 2>/dev/null || \
  die "GPG verification of latest-stage3.txt failed! Aborting..."

# Parse the stage3 tarball path from the verified file
STAGE3_TARBALL_PATH=$(awk '/^[^#].*\.tar\.xz/ { print $1; exit }' \
  latest-stage3.txt)
if [[ -z "$STAGE3_TARBALL_PATH" ]]; then
  die "Failed to parse the stage3 tarball path from latest-stage3.txt."
fi
STAGE3_TARBALL=$(basename "$STAGE3_TARBALL_PATH")

# Download tarball and verification files
echo; echo "Downloading stage3 tarball and verification files..."
for suffix in "" ".asc" ".DIGESTS" ".sha256"; do
  if command -v wget >/dev/null 2>&1; then
    wget -c -T 10 -t 10 -q --show-progress \
    "$RELEASES_URL/$STAGE3_TARBALL_PATH$suffix" || \
    die "Failed to download $RELEASES_URL/$STAGE3_TARBALL_PATH$suffix (wget)"
  elif command -v curl >/dev/null 2>&1; then
    curl -fsSL -C - --retry 10 --connect-timeout 10 \
    "$RELEASES_URL/$STAGE3_TARBALL_PATH$suffix" -o \
    "$(basename "$STAGE3_TARBALL_PATH$suffix")" || \
    die "Failed to download $RELEASES_URL/$STAGE3_TARBALL_PATH$suffix (curl)"
  else
    die "Neither wget nor curl found."
  fi
done

# Verify GPG signatures
echo; echo "Verifying GPG signatures..."
for ext in asc DIGESTS sha256; do
  echo "- Checking $STAGE3_TARBALL.$ext..."
  if ! gpg --verify "$STAGE3_TARBALL.$ext" 2>/dev/null; then
    die "GPG verification of $STAGE3_TARBALL.$ext failed! Aborting..."
  fi
done

# Verify SHA256 hash
echo; echo "Verifying SHA256 checksum..."
if ! sha256sum --check "$STAGE3_TARBALL.sha256" 2>/dev/null; then
  die "SHA256 verification failed! Aborting..."
fi

# If all verifications passed, extract the tarball
echo; echo "All verifications passed. Extracting tarball..."
tar xpf "$STAGE3_TARBALL" --xattrs-include='*.*' --numeric-owner \
  -C /mnt/gentoo || \
  die "Failed to extract tarball."

# Pull make.conf with use flags, jobs, licenses, mirrors, etc already set
configure_make_conf "/mnt/gentoo/etc/portage/make.conf" "stage3" "true"

# Set VIDEO_CARDS value in package.use
echo; write_video_card "mnt" || \
  die "Failed to set video card."

# Signal that make.conf was configured during install phase
mark_makeconf_configured "mnt"

#============= Gentoo Install - Installing the Gentoo Base System =============

# Copy Network Info
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/ || \
  die "Failed to copy resolv.conf to /mnt/gentoo/etc/"

# Mount Filesystems
mount_system_partitions "gentoo"

# Fix /dev/shm if it's a broken symlink (common on non-Gentoo ISOs)
if test -L /dev/shm; then
  echo "Fixing /dev/shm symlink..."
  rm /dev/shm || die "Failed to remove /dev/shm symlink."
  mkdir /dev/shm || die "Failed to create /dev/shm directory."
  mount -t tmpfs -o nosuid,nodev,noexec shm /dev/shm || \
    die "Failed to mount tmpfs on /dev/shm."
  chmod 1777 /dev/shm /run/shm || \
    die "Failed to set permissions on /dev/shm or /run/shm."
fi

# Copy common functions to chroot environment
cp "$SCRIPT_DIR/Install-Common.sh" "$SCRIPT_DIR/Master-Common.sh" \
  /mnt/gentoo/ || \
  die "Failed to copy Install-Common.sh to chroot."

#============================== Chroot Variables ==============================

# Binary Repos
SYNC_URI_V3="http://download.nus.edu.sg/mirror/gentoo/releases/amd64"
SYNC_URI_V3="$SYNC_URI_V3/binpackages/23.0/x86-64-v3/"
SYNC_URI="https://distfiles.gentoo.org/releases/amd64/binpackages/23.0/x86-64/"

# Package Lists (accounts for Init System and CPU)
GIT_PKGS="app-eselect/eselect-repository dev-vcs/git"
SYSTEM_PKGS="sys-kernel/gentoo-kernel-bin sys-fs/genfstab \
  net-misc/networkmanager gnome-extra/nm-applet app-shells/bash-completion \
  sys-fs/xfsprogs sys-fs/e2fsprogs sys-fs/dosfstools sys-fs/btrfs-progs \
  sys-fs/f2fs-tools sys-fs/ntfs3g sys-block/io-scheduler-udev-rules \
  app-arch/unzip app-admin/sudo"
PHYSICAL_PKGS="net-wireless/blueman sys-kernel/linux-firmware"

# OpenRC Packages
if [ "$GENTOO_INIT" = "openrc" ]; then
  GIT_PKGS="$GIT_PKGS app-emulation/virt-what"
  OPENRC_PKGS="app-admin/sysklogd sys-process/cronie net-misc/chrony"
  SYSTEM_PKGS="$SYSTEM_PKGS $OPENRC_PKGS"
else
  # systemd Packages
  SYSTEMD_PKGS="sys-apps/zram-generator"
  SYSTEM_PKGS="$SYSTEM_PKGS $SYSTEMD_PKGS"
fi

# CPU Check
IS_INTEL="false"
[ -f /proc/cpuinfo ] && grep -q "GenuineIntel" /proc/cpuinfo && IS_INTEL="true"

# Ensure variables are exported before chroot
export drive hostname timezone username rootpasswd userpasswd BOOTMODE \
  REMOVABLE_BOOT GENTOO_INIT SYNC_URI_V3 SYNC_URI GIT_PKGS SYSTEM_PKGS \
  PHYSICAL_PKGS IS_INTEL grub_timeout || \
  die "Failed to export required variables."

#=========================== Chroot Variables - END ===========================

# Entering Chroot
cat << EOF | chroot /mnt/gentoo /bin/bash || die "Failed to enter chroot."

# Source common functions inside chroot
source Install-Common.sh || \
  { echo "Failed to source Install-Common.sh in chroot."; exit 1; }

# New Chroot Environment - Installing the Gentoo Base System (Continued)
source /etc/profile || die "Failed to source /etc/profile."

# Sync Snapshot
retry emerge-webrsync || die "Failed to run emerge-webrsync."

# Set Binary Package Repo.
echo "[binhost]
priority = 9999" > /etc/portage/binrepos.conf/gentoo.conf || \
  die "Failed to write binhost config."

# Set BINHOST sync URI based on CPU support for AVX2.
if grep -q "avx2" /proc/cpuinfo; then
  echo "sync-uri = $SYNC_URI_V3" \
    >> /etc/portage/binrepos.conf/gentoo.conf || \
    die "Failed to write AVX2 binhost URI."
  echo "Use x86-64-v3 optimized binaries for AVX2-capable CPUs."
else
  echo "sync-uri = $SYNC_URI" \
    >> /etc/portage/binrepos.conf/gentoo.conf || \
    die "Failed to write baseline binhost URI."
  echo "Use baseline x86-64 binaries for broader compatibility."
fi

# Only remove GPG directory if there are permission issues
if [ -d /etc/portage/gnupg ] && [ ! -w /etc/portage/gnupg ]; then
  echo "Fixing GPG directory permissions..."
  rm -rf /etc/portage/gnupg/ || \
    die "Failed to remove problematic GPG directory."
fi

# Verify GPG.
echo; getuto || die "Failed to verify GPG keys with getuto."

# Install packages for Gentoo git sync
retry emerge -vquN $GIT_PKGS || die "Failed to install packages for git sync."

# Switch from rsync to git for faster repository sync times
eselect repository remove -f gentoo || \
  die "Failed to remove rsync-based Gentoo repository."
eselect repository add gentoo git \
  https://github.com/gentoo-mirror/gentoo.git || \
  die "Failed to enable Git-based Gentoo repository."
rm -rf /var/db/repos/gentoo || \
  die "Failed to remove existing gentoo repository."

# Signal that repository sync is now using git during install phase
touch /var/db/repos/.synced-git-repo || \
  die "Failed to create .synced-git-repo flag file."

# Sync Repository
retry emaint sync -r gentoo || \
  die "Failed to sync the Gentoo repository using Git."

# Update portage if there happens to be a new version
retry emerge -1uqv sys-apps/portage || die "Failed to update Portage."

# Select appropriate Gentoo profile based on init system
if [ "$GENTOO_INIT" = "systemd" ]; then
  eselect profile set default/linux/amd64/23.0/desktop/gnome/systemd || \
    die "Failed to set systemd system profile."
else
  eselect profile set default/linux/amd64/23.0/desktop || \
    die "Failed to set OpenRC system profile."
fi

# Set CPU Flags (TO DO: make it work in chroot heredoc)
# retry emerge -1uqv app-portage/cpuid2cpuflags
# echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00-cpu-flags

# Update World Set
retry emerge -vqDuN @world || die "Failed to update the world set."

# Remove Obsolete Packages
emerge -q --depclean || die "Failed to remove obsolete packages."

# Set Timezone
ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime || \
  die "Failed to set timezone."
hwclock --systohc || die "Failed to set hardware clock."

# Locale Generation (uncomment en_US.UTF-8 UTF-8 in /etc/locale.gen)
sed -i 's/^#\s*\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen || \
  die "Failed to uncomment locale in /etc/locale.gen."
locale-gen || die "Failed to generate locales."

# Set Locale
eselect locale set en_US.utf8 || die "Failed to set locale to en_US.utf8."

# Reload Environment
env-update || die "Failed to update environment."
source /etc/profile || die "Failed to reload environment."

#=============== Gentoo Install - Configuring the Linux Kernel ================

# Using GRUB & Initramfs
echo "sys-kernel/installkernel grub dracut" > \
  /etc/portage/package.use/installkernel || \
  die "Failed to update /etc/portage/package.use/installkernel."

# Install System Packages
if { [ "$GENTOO_INIT" = "systemd" ] && systemd-detect-virt --vm; } || \
   virt-what | grep -q .; then
    # VM - just the system packages (including OpenRC if selected)
    retry emerge -vq $SYSTEM_PKGS || die "Failed to install system packages."
else
  # Physical machine - add firmware
  if [ "$IS_INTEL" = "true" ]; then
    retry emerge -vq $SYSTEM_PKGS $PHYSICAL_PKGS sys-firmware/intel-microcode \
      || die "Failed to install system packages."
  else
    retry emerge -vq $SYSTEM_PKGS $PHYSICAL_PKGS || \
      die "Failed to install system packages."
  fi
fi

#================== Gentoo Install - Configuring the System ===================

# Generate fstab
genfstab -U / >> /etc/fstab || die "Failed to generate fstab."

# Remove zram swap entries from fstab (if using Fedora ISO)
sed -i '/zram.*LABEL=zram/d' /etc/fstab || \
  die "Failed to remove zram entries from fstab."
sed -i '/none.*swap.*defaults,pri=/d' /etc/fstab || \
  die "Failed to remove zram entries from fstab."

# Set Hostname
echo "$hostname" > /etc/hostname || die "Failed to set hostname."
if [ "$GENTOO_INIT" = "openrc" ]; then
  echo "hostname=$hostname" > /etc/conf.d/hostname
fi

# Allow Resolving the Local Hostname
echo -e "127.0.1.1\t$hostname.localdomain\t$hostname" >> /etc/hosts || \
  die "Failed to update /etc/hosts."

# Init System Setup
if [ "$GENTOO_INIT" = "systemd" ]; then
  systemd-machine-id-setup || die "Failed to run systemd-machine-id-setup."
  # systemd-firstboot --prompt
  systemctl preset-all --preset-mode=enable-only || \
    die "Failed to preset systemd services."
  # Enable Services
  systemctl enable bluetooth || \
    die "Failed to enable services."
else
  rc-update add sysklogd default || die "Failed to enable sysklogd service."
  rc-update add cronie default || die "Failed to enable cronie service."
  rc-update add bluetooth default || die "Failed to enable bluetooth service."
fi

# Configure networking based on init system
if [ "$GENTOO_INIT" = "systemd" ]; then
  # Disable conflicting systemd services and enable NetworkManager
  systemctl disable systemd-networkd || \
    die "Failed to disable systemd-networkd."
  systemctl disable systemd-resolved.service || \
    die "Failed to disable systemd-resolved service."
  systemctl enable NetworkManager || die "Failed to enable NetworkManager."
else
  # Enable NetworkManager for OpenRC
  rc-update add NetworkManager default || \
    die "Failed to enable NetworkManager."
fi

#================== Gentoo Install - Installing System Tools ==================

# Enable Time Synchronization
if [ "$GENTOO_INIT" = "systemd" ]; then
  systemctl enable systemd-timesyncd.service || \
    die "Failed to enable systemd-timesyncd service."
else
  rc-update add chronyd default || die "Failed to enable chronyd service."
fi

#================ Gentoo Install - Configuring the Bootloader =================

# Configure GRUB Bootloader
install_grub

# Set GRUB_GFXMODE
set_grub_gfxmode

# Set GRUB timeout
sed -i "/^#*GRUB_TIMEOUT=/s/^#*GRUB_TIMEOUT=.*/GRUB_TIMEOUT=$grub_timeout/" \
  /etc/default/grub || \
  die "Failed to set GRUB_TIMEOUT."

# Configure zRAM
if [ "$GENTOO_INIT" = "systemd" ]; then
  configure_zram
else
  configure_zram "gentoo"
fi

# Generate Grub Config
grub-mkconfig -o /boot/grub/grub.cfg || die "Failed to generate GRUB config."

#======================== Gentoo Install - Finalizing =========================

# Setup Sudo by uncommenting %wheel ALL=(ALL:ALL) with visudo
sed -i 's/^#\s*\(%wheel ALL=(ALL:ALL) ALL\)/\1/' /etc/sudoers || \
  die "Failed to enable sudo for wheel group."

# Create User and Set Passwords
useradd -m -G users,wheel,plugdev -s /bin/bash "$username" || \
  die "Failed to create user."
echo "root:$rootpasswd" | chpasswd || die "Failed to set root password."
echo "$username:$userpasswd" | chpasswd || die "Failed to set user password."

# Cleanup
rm /stage3-*.tar.* Install-Common.sh Master-Common.sh latest-stage3.txt || \
  die "Failed to remove Stage 3 tarball."

# Clone cinnamon-dotfiles repo as new user
clone_dotfiles "gentoo"

# Setup GRUB theme
setup_grub_theme "Gentoo"
EOF
