#!/bin/bash
set -euo pipefail

# Download and source common functions
echo "Sourcing functions..."
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }
curl -fsSL -o Install-Common.sh https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles/main/extra/ISO/Install-Common.sh || die "Failed to download Install-Common.sh"
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

#=================== Gentoo Install - The Stage File ===================

# Move to Mounted Root Partition
cd /mnt/gentoo || die "Failed to change directory to /mnt/gentoo."

# Sync Time
hwclock --systohc --utc

# Grab the Latest Systemd Stage 3 Desktop Profile
# wget https://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-desktop-systemd/stage3-amd64-desktop-systemd-*.tar.xz/

# Set Variables
GENTOO_MIRROR="https://distfiles.gentoo.org"
GENTOO_ARCH="amd64"
GENTOO_INIT="systemd"
STAGE3_BASENAME="stage3-$GENTOO_ARCH-desktop-$GENTOO_INIT"
RELEASES_URL="$GENTOO_MIRROR/releases/$GENTOO_ARCH/autobuilds"
LATEST_TXT_URL="$RELEASES_URL/latest-$STAGE3_BASENAME.txt"

# Download the latest stage3 list
echo; echo "Downloading latest stage3 list..."
wget -c -T 10 -t 10 -q --show-progress "$LATEST_TXT_URL" -O latest-stage3.txt || die "Failed to download $LATEST_TXT_URL."

# Import Gentoo release key via WKD
echo; echo "Importing Gentoo release key..."
gpg --quiet --auto-key-locate=clear,nodefault,wkd --locate-key releng@gentoo.org >/dev/null 2>&1 || die "Failed to import Gentoo release key."

# Verify the PGP signature of the latest-stage3.txt file
echo "Verifying GPG signature of latest-stage3.txt..."
gpg --verify latest-stage3.txt 2>/dev/null || die "GPG verification of latest-stage3.txt failed! Aborting..."

# Parse the stage3 tarball path from the verified file
STAGE3_TARBALL_PATH=$(awk '/^[^#].*\.tar\.xz/ { print $1; exit }' latest-stage3.txt)
if [[ -z "$STAGE3_TARBALL_PATH" ]]; then
   die "Failed to parse the stage3 tarball path from latest-stage3.txt."
fi
STAGE3_TARBALL=$(basename "$STAGE3_TARBALL_PATH")

# Download tarball and verification files
echo; echo "Downloading stage3 tarball and verification files..."
for suffix in "" ".asc" ".DIGESTS" ".sha256"; do
  wget -c -T 10 -t 10 -q --show-progress "$RELEASES_URL/$STAGE3_TARBALL_PATH$suffix" || die "Failed to download $RELEASES_URL/$STAGE3_TARBALL_PATH$suffix"
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
tar xpf "$STAGE3_TARBALL" --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo || die "Failed to extract tarball."

# Pull make.conf with use flags, jobs, licenses, mirrors, etc already set
url="https://raw.githubusercontent.com/spreadiesinspace/cinnamon-dotfiles/main/etc/portage/make.conf"
path="/mnt/gentoo/etc/portage/make.conf"

# Backup and exit on failure
cp "$path" "$path.stage3" || die "Failed to back up $path."
curl -fsSL "$url" -o "$path" || {
  echo "Failed to fetch $url, restoring original make.conf."
  mv "$path.stage3" "$path"
  die "Failed to fetch $url."
}
echo; echo "make.conf updated successfully"

# Set MAKEOPTS based on CPU cores (load limit = cores + 1)
cores=$(nproc)
makeopts_load_limit=$((cores + 1))
sed -i "s/^MAKEOPTS=.*/MAKEOPTS=\"-j$cores -l$makeopts_load_limit\"/" /mnt/gentoo/etc/portage/make.conf || die "Failed to update MAKEOPTS in make.conf."
echo; echo "Set MAKEOPTS to -j$cores -l$makeopts_load_limit"

# Set EMERGE_DEFAULT_OPTS based on CPU cores (load limit as 90% of cores)
load_limit=$(echo "$cores * 0.9" | bc -l | awk '{printf "%.1f", $0}')
sed -i "s/^EMERGE_DEFAULT_OPTS=.*/EMERGE_DEFAULT_OPTS=\"-j$cores -l$load_limit\"/" /mnt/gentoo/etc/portage/make.conf || die "Failed to update EMERGE_DEFAULT_OPTS in make.conf."
echo "Set EMERGE_DEFAULT_OPTS to -j$cores -l$load_limit"

# Set VIDEO_CARDS value in package.use
echo; set_video_card || die "Failed to set video card."

# Signal that make.conf was configured during install phase
touch /mnt/gentoo/etc/portage/.makeconf_configured || die "Failed to create .makeconf_configured flag."

# Review make.conf
# nano /mnt/gentoo/etc/portage/make.conf

#========= Gentoo Install - Installing the Gentoo Base System ==========

# Copy Network Info
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/ || die "Failed to copy resolv.conf to /mnt/gentoo/etc/"

# Mount Filesystems
mount --types proc /proc /mnt/gentoo/proc || die "Failed to mount /proc"
mount --rbind /sys /mnt/gentoo/sys || die "Failed to mount /sys"
mount --make-rslave /mnt/gentoo/sys || die "Failed to set /mnt/gentoo/sys as slave"
mount --rbind /dev /mnt/gentoo/dev || die "Failed to mount /dev"
mount --make-rslave /mnt/gentoo/dev || die "Failed to set /mnt/gentoo/dev as slave"
mount --bind /run /mnt/gentoo/run || die "Failed to mount /run"
mount --make-slave /mnt/gentoo/run || die "Failed to set /mnt/gentoo/run as slave"

# Fix /dev/shm if it's a broken symlink (common on non-Gentoo ISOs)
if test -L /dev/shm; then
  echo "Fixing /dev/shm symlink..."
  rm /dev/shm || die "Failed to remove /dev/shm symlink."
  mkdir /dev/shm || die "Failed to create /dev/shm directory."
  mount -t tmpfs -o nosuid,nodev,noexec shm /dev/shm || die "Failed to mount tmpfs on /dev/shm."
  chmod 1777 /dev/shm /run/shm || die "Failed to set permissions on /dev/shm or /run/shm."
fi

# Copy common functions to chroot environment
cp "$SCRIPT_DIR/Install-Common.sh" /mnt/gentoo/ || die "Failed to copy Install-Common.sh to chroot."

# Ensure variables are exported before chroot
: "${cpuflags:=}"
export cpuflags drive hostname timezone username rootpasswd userpasswd BOOTMODE REMOVABLE_BOOT || die "Failed to export required variables."

# Entering Chroot
cat << EOF | chroot /mnt/gentoo /bin/bash || die "Failed to enter chroot."

# Source common functions inside chroot
source Install-Common.sh || { echo "Failed to source Install-Common.sh in chroot."; exit 1; }

# New Chroot Environment - Installing the Gentoo Base System (Continued)
source /etc/profile || die "Failed to source /etc/profile."

# Sync Snapshot
emerge-webrsync || die "Failed to run emerge-webrsync."

# Set Binary Package Repo.
echo "[binhost]
priority = 9999" > /etc/portage/binrepos.conf/gentoo.conf || die "Failed to write binhost config."

# Set BINHOST sync URI based on CPU support for AVX2.
if grep -q "avx2" /proc/cpuinfo; then
  echo "sync-uri = http://download.nus.edu.sg/mirror/gentoo/releases/amd64/binpackages/23.0/x86-64-v3/" >> /etc/portage/binrepos.conf/gentoo.conf || die "Failed to write AVX2 binhost URI."
  echo "Use x86-64-v3 optimized binaries for AVX2-capable CPUs."
else
  echo "sync-uri = https://distfiles.gentoo.org/releases/amd64/binpackages/23.0/x86-64/" >> /etc/portage/binrepos.conf/gentoo.conf || die "Failed to write baseline binhost URI."
  echo "Use baseline x86-64 binaries for broader compatibility."
fi

# Only remove if there are known issues
if [ -d /etc/portage/gnupg ] && [ ! -w /etc/portage/gnupg ]; then
    echo "Fixing GPG directory permissions..."
    rm -rf /etc/portage/gnupg/ || die "Failed to remove problematic GPG directory."
fi

# Verify GPG.
echo && getuto || die "Failed to verify GPG keys with getuto."

# Select Mirrors (mirrors already set in make.conf)
# emerge -1qv mirrorselect || die "Failed to install mirrorselect."
# mirrorselect -i -o >> /etc/portage/make.conf || die "Failed to run mirrorselect."

# Install Essentials
emerge -vquN app-eselect/eselect-repository dev-vcs/git || die "Failed to install eselect-repository and git."

# Switch from rsync to git for faster repository sync times
eselect repository remove -f gentoo || die "Failed to remove rsync-based Gentoo repository."
eselect repository add gentoo git https://github.com/gentoo-mirror/gentoo.git || die "Failed to enable Git-based Gentoo repository."
rm -rf /var/db/repos/gentoo || die "Failed to remove existing gentoo repository."

# Signal that repository sync is now using git during install phase
touch /var/db/repos/.synced-git-repo || die "Failed to create .synced-git-repo flag file."

# Sync Repository
emaint sync -r gentoo || die "Failed to sync the Gentoo repository using Git."

# Update portage if there happens to be a new version
emerge -1uqv sys-apps/portage || die "Failed to update Portage."

# Read the News
# eselect news list
# eselect news read

# Select 23.0 gnome desktop systemd profile for Cinnamon
eselect profile set default/linux/amd64/23.0/desktop/gnome/systemd || die "Failed to set the system profile."

# Set CPU Flags (TO DO: make it work in chroot heredoc)
# emerge -1uqv app-portage/cpuid2cpuflags
# echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags
# cpuflags=$(cpuid2cpuflags)
# if [[ -n "$cpuflags" ]]; then
#   printf "*/* %s\n" "$cpuflags" > /etc/portage/package.use/00cpu-flags
# else
#   echo "Warning: cpuid2cpuflags returned nothing!"
# fi

# Update World Set
emerge -vqDuN @world || die "Failed to update the world set."

# Remove Obsolete Packages
emerge -q --depclean || die "Failed to remove obsolete packages."

# Set Timezone
ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime || die "Failed to set timezone."
hwclock --systohc || die "Failed to set hardware clock."

# Locale Generation (uncomment en_US.UTF-8 UTF-8 in /etc/locale.gen)
sed -i 's/^#\s*\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen || die "Failed to uncomment locale in /etc/locale.gen."
locale-gen || die "Failed to generate locales."

# Set Locale
eselect locale set en_US.utf8 || die "Failed to set locale to en_US.utf8."

# Reload Environment
env-update && source /etc/profile || die "Failed to reload environment."

#============ Gentoo Install - Configuring the Linux Kernel ============

# Using GRUB & Initramfs
echo "sys-kernel/installkernel grub dracut" > /etc/portage/package.use/installkernel || die "Failed to update /etc/portage/package.use/installkernel."

# Install System Packages
emerge -qv sys-kernel/gentoo-kernel-bin sys-fs/genfstab net-misc/networkmanager gnome-extra/nm-applet app-shells/bash-completion sys-fs/xfsprogs sys-fs/e2fsprogs sys-fs/dosfstools sys-fs/btrfs-progs sys-fs/f2fs-tools sys-fs/ntfs3g sys-block/io-scheduler-udev-rules app-arch/unzip app-admin/sudo || die "Failed to install system packages."

# Skip firmware installation for VMs
if ! systemd-detect-virt --vm &>/dev/null; then
  echo "Physical machine detected. Installing firmware..."
  emerge -vq sys-kernel/linux-firmware || die "Failed to install sys-kernel/linux-firmware."
  grep -q "GenuineIntel" /proc/cpuinfo && {
    echo "Intel CPU detected. Installing intel-microcode..."
    emerge -vq sys-firmware/intel-microcode || die "Failed to install sys-firmware/intel-microcode."
  } || echo "Non-Intel CPU detected. Skipping intel-microcode."
else
  echo "VM detected. Skipping firmware and microcode installation."
fi

#=============== Gentoo Install - Configuring the System ===============

# Generate fstab
# emerge -vq sys-fs/genfstab || die "Failed to install sys-fs/genfstab."
genfstab -U / >> /etc/fstab || die "Failed to generate fstab."

# Set Hostname
echo "$hostname" > /etc/hostname || die "Failed to set hostname."

# Allow Resolving the Local Hostname
echo -e "127.0.1.1\t$hostname.localdomain\t$hostname" >> /etc/hosts || die "Failed to update /etc/hosts."

# Systemd Setup
systemd-machine-id-setup || die "Failed to run systemd-machine-id-setup."
# systemd-firstboot --prompt
systemctl preset-all --preset-mode=enable-only || die "Failed to preset systemd services."

# Networking
# emerge -vq net-misc/networkmanager gnome-extra/nm-applet || die "Failed to install network-manager and nm-applet."
systemctl disable systemd-networkd || die "Failed to disable systemd-networkd."
systemctl disable systemd-resolved.service || die "Failed to disable systemd-resolved service."
systemctl enable NetworkManager || die "Failed to enable NetworkManager."

#============== Gentoo Install - Installing System Tools ===============

# Install System Tools
# emerge -vq sys-apps/mlocate app-shells/bash-completion sys-fs/xfsprogs sys-fs/e2fsprogs sys-fs/dosfstools sys-fs/btrfs-progs sys-fs/f2fs-tools sys-fs/ntfs3g sys-block/io-scheduler-udev-rules app-arch/unzip || die "Failed to install essential system tools."

# No sys-fs/zfs because it pulls in zfs-kmod which takes a while to compile
# emerge -vq sys-fs/zfs

# Enable Time Synchronization
systemctl enable systemd-timesyncd.service || die "Failed to enable systemd-timesyncd service."

#============= Gentoo Install - Configuring the Bootloader =============

# Configure GRUB Bootloader
install_grub

# Set GRUB timeout to 0
sed -i '/^#*GRUB_TIMEOUT=/s/^#*GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub || die "Failed to set GRUB_TIMEOUT."

# Generate Grub Config
grub-mkconfig -o /boot/grub/grub.cfg || die "Failed to generate GRUB config."

#===================== Gentoo Install - Finalizing =====================

# Install Sudo
# emerge -vq app-admin/sudo || die "Failed to install sudo."

# Setup Sudo by uncommenting %wheel ALL=(ALL:ALL) with visudo
sed -i 's/^#\s*\(%wheel ALL=(ALL:ALL) ALL\)/\1/' /etc/sudoers || die "Failed to enable sudo for wheel group."

# Create User and Set Passwords
useradd -m -G users,wheel,plugdev -s /bin/bash "$username" || die "Failed to create user."
echo "root:$rootpasswd" | chpasswd || die "Failed to set root password."
echo "$username:$userpasswd" | chpasswd || die "Failed to set user password."

# Cleanup
rm /stage3-*.tar.* Install-Common.sh latest-stage3.txt || die "Failed to remove Stage 3 tarball."

# Clone cinnamon-dotfiles repo as new user
clone_dotfiles "gentoo"
EOF
