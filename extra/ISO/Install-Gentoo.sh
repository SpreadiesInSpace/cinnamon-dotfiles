#!/bin/bash

# Download and source common functions
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

#========================== Gentoo Install - The Stage File ==========================

# Move to Mounted Root Partition
cd /mnt/gentoo || die "Failed to change directory to /mnt/gentoo."

# Sync Time
hwclock --systohc --utc

# Grab the Latest Systemd Stage 3 Desktop Profile
# wget https://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-desktop-systemd/stage3-amd64-desktop-systemd-*.tar.xz/

# Set Variables
GENTOO_MIRROR="https://distfiles.gentoo.org"
GENTOO_ARCH="amd64"
STAGE3_BASENAME="stage3-amd64-desktop-systemd"
RELEASES_URL="$GENTOO_MIRROR/releases/$GENTOO_ARCH/autobuilds/current-$STAGE3_BASENAME/"

# Get the latest Stage 3 tarball
STAGE3_TARBALL=$(curl -s "$RELEASES_URL" | python3 -c 'import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read()))' | grep -o "\"${STAGE3_BASENAME}-[0-9A-Z]*.tar.xz\"" | sort -u | head -1 | sed 's/"//g')
if [ -z "$STAGE3_TARBALL" ]; then
  die "Failed to find the latest Stage 3 tarball."
fi

# Download tarball and verification files
echo; for suffix in "" ".asc" ".DIGESTS" ".sha256"; do
  wget -c -T 10 -t 10 -q --show-progress "$RELEASES_URL/$STAGE3_TARBALL$suffix" || die "Failed to download $RELEASES_URL/$STAGE3_TARBALL$suffix"
done

# Import Gentoo release key via WKD
echo; gpg --quiet --auto-key-locate=clear,nodefault,wkd --locate-key releng@gentoo.org || die "Failed to import Gentoo release key."

# Verify GPG signature files
echo "Verifying GPG signatures..."
for ext in asc DIGESTS sha256; do
  echo "- Checking $STAGE3_TARBALL.$ext..."
  if ! gpg --verify "$STAGE3_TARBALL.$ext" 2>/dev/null; then
    die "GPG verification of $STAGE3_TARBALL.$ext failed! Aborting..."
  fi
done

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
echo; set_video_card

# Signal that make.conf was configured during install phase
touch /mnt/gentoo/etc/portage/.makeconf_configured || die "Failed to create .makeconf_configured flag."

# Review make.conf
# nano /mnt/gentoo/etc/portage/make.conf

#================ Gentoo Install - Installing the Gentoo Base System =================

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

# Extra Mounts for Non-Gentoo Media
test -L /dev/shm && rm /dev/shm || die "Failed to remove symlink for /dev/shm"
mkdir /dev/shm || die "Failed to create /dev/shm"
mount --types tmpfs --options nosuid,nodev,noexec shm /dev/shm || die "Failed to mount /dev/shm"
chmod 1777 /dev/shm /run/shm || die "Failed to set permissions for /dev/shm"

# Entering Chroot
cat << EOF | chroot /mnt/gentoo /bin/bash

# New Chroot Environment - Installing the Gentoo Base System (Continued)
source /etc/profile
export PS1="(chroot) ${PS1}"

# Sync Snapshot
emerge-webrsync

# Set Binary Package Repo
echo "[binhost]
priority = 9999" > /etc/portage/binrepos.conf/gentoo.conf

# Set BINHOST sync URI based on CPU support for AVX2
if grep -q "avx2" /proc/cpuinfo; then
  echo "sync-uri = http://download.nus.edu.sg/mirror/gentoo/releases/amd64/binpackages/23.0/x86-64-v3/" >> /etc/portage/binrepos.conf/gentoo.conf
  echo "Use x86-64-v3 optimized binaries for AVX2-capable CPUs"
else
  echo "sync-uri = https://distfiles.gentoo.org/releases/amd64/binpackages/23.0/x86-64/" >> /etc/portage/binrepos.conf/gentoo.conf
  echo "Use baseline x86-64 binaries for broader compatibility"
fi

# Verify GPG
rm -rf /etc/portage/gnupg/ && echo && getuto

# Suppress unsafe directories warnings
# chmod 644 /etc/portage/gnupg/pubring.kbx
# chmod 644 /etc/portage/make.conf

# For Selecting Mirrors (mirrors already set in make.conf)
# emerge -1qv mirrorselect
# mirrorselect -i -o >> /etc/portage/make.conf

# Install Essentials 
emerge -vquN app-eselect/eselect-repository dev-vcs/git

# Switch from rsync to git for faster repository sync times
eselect repository disable gentoo
eselect repository enable gentoo
rm -rf /var/db/repos/gentoo

# Signal that repository sync is now using git during install phase
touch /var/db/repos/.synced-git-repo

# Sync Repository
emaint sync -r gentoo

# Update portage if there happens to be a new version
emerge -1uqv sys-apps/portage 

# Read the News
# eselect news list
# eselect news read

# Select 23.0 gnome desktop systemd profile for Cinnamon
eselect profile set default/linux/amd64/23.0/desktop/gnome/systemd

# Set CPU Flags (TO DO: make it work in chroot heredoc)
emerge -1uqv app-portage/cpuid2cpuflags
# echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags
cpuflags=$(cpuid2cpuflags)
if [[ -n "$cpuflags" ]]; then
  printf "*/* %s\n" "$cpuflags" > /etc/portage/package.use/00cpu-flags
else
  echo "Warning: cpuid2cpuflags returned nothing!"
fi

# Update World Set
emerge -vqDuN @world

# Remove Obselete Packages
emerge -q --depclean

# Set Timezone
ln -sf "../usr/share/zoneinfo/$timezone" /etc/localtime
hwclock --systohc

# Locale Generation (uncomment en_US.UTF-8 UTF-8 in /etc/locale.gen)
sed -i 's/^#\s*\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen

# Set Locale
eselect locale set en_US.utf8

# Reload Environment
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"

#=================== Gentoo Install - Configuring the Linux Kernel ===================

# Using GRUB & Initramfs
echo "sys-kernel/installkernel grub
sys-kernel/installkernel dracut" > /etc/portage/package.use/installkernel

# Install Kernel
emerge -qv sys-kernel/gentoo-kernel-bin

# Skip firmware installation for VMs
if ! systemd-detect-virt --vm &>/dev/null; then
  echo "Physical machine detected. Installing firmware..."
  emerge -qv sys-kernel/linux-firmware
  grep -q "GenuineIntel" /proc/cpuinfo && {
    echo "Intel CPU detected. Installing intel-microcode..."
    emerge -qv sys-firmware/intel-microcode
  } || echo "Non-Intel CPU detected. Skipping intel-microcode."
else
  echo "VM detected. Skipping firmware and microcode installation."
fi

#====================== Gentoo Install - Configuring the System ======================

# Generate fstab
emerge -qv sys-fs/genfstab
genfstab -U / >> /etc/fstab

# Set Hostname
echo "$hostname" > /etc/hostname

# Allow Resolving the Local Hostname
echo -e "127.0.1.1\t$hostname.localdomain\t$hostname" >> /etc/hosts

# Systemd Setup
systemd-machine-id-setup
# systemd-firstboot --prompt
systemctl preset-all --preset-mode=enable-only

# Networking
emerge -vq net-misc/networkmanager gnome-extra/nm-applet
systemctl disable systemd-networkd
systemctl disable systemd-resolved.service
systemctl enable NetworkManager

#===================== Gentoo Install - Installing System Tools ======================

# Install System Tools
emerge -vq sys-apps/mlocate app-shells/bash-completion sys-fs/xfsprogs sys-fs/e2fsprogs sys-fs/dosfstools sys-fs/btrfs-progs sys-fs/f2fs-tools sys-fs/ntfs3g sys-block/io-scheduler-udev-rules app-arch/unzip

# No sys-fs/zfs because it pulls in zfs-kmod which takes a while to compile
# emerge -qv sys-fs/zfs

# Enable Time Synchronization
systemctl enable systemd-timesyncd.service

# Gentoo Install - Configuring the Bootloader
grub-install --efi-directory=/efi

# Set GRUB timeout to 0
sed -i '/^#*GRUB_TIMEOUT=/s/^#*GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub

# Generate Grub Config
grub-mkconfig -o /boot/grub/grub.cfg

#============================ Gentoo Install - Finalizing ============================

# Install Sudo
emerge -qv app-admin/sudo

# Setup Sudo by uncommenting %wheel ALL=(ALL:ALL) with visudo
sed -i 's/^#\s*\(%wheel ALL=(ALL:ALL) ALL\)/\1/' /etc/sudoers

# Cleanup
rm /stage3-*.tar.*

# Create User and Set Passwords
useradd -m -G users,wheel,plugdev -s /bin/bash "$username"
echo "root:$rootpasswd" | chpasswd
echo "$username:$userpasswd" | chpasswd

# Clone Repo as New User
cat << 'CLONE' | su - "$username"
cd; git clone https://github.com/SpreadiesInSpace/cinnamon-dotfiles
cd cinnamon-dotfiles
touch .gentoo.done
echo "Reboot and run Setup.sh in cinnamon-dotfiles located in $username's home folder."
CLONE
EOF
