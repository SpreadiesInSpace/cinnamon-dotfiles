#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run the script as superuser"
  exit
fi

# Prompt for root password
while true; do
  read -sp "Enter new root password: " rootpasswd; echo
  read -sp "Confirm root password: " rootpasswd_confirm; echo
  if [ -z "$rootpasswd" ]; then echo "Root password cannot be empty."; continue; fi
  if [ "$rootpasswd" != "$rootpasswd_confirm" ]; then echo "Passwords do not match. Try again."; continue; fi
  break
done

# Prompt for new username
while true; do
  read -p "Enter new username: " username
  if [[ "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then break; fi
  echo "Invalid username. Use only lowercase letters, numbers, underscores or hyphens (cannot start with number or hyphen)"
done

# Prompt for new user password
while true; do
  read -sp "Enter password for $username: " userpasswd; echo
  read -sp "Confirm password for $username: " userpasswd_confirm; echo
  if [ -z "$userpasswd" ]; then echo "User password cannot be empty."; continue; fi
  if [ "$userpasswd" != "$userpasswd_confirm" ]; then echo "Passwords do not match. Try again."; continue; fi
  break
done

# Prompt for hostname
while true; do
  read -p "Enter hostname: " hostname
  if [[ "$hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?$ ]] && ! [[ "$hostname" =~ \  ]]; then break; fi
  echo "Invalid hostname. Must be alphanumeric, may include hyphens, and cannot contain spaces or start/end with a hyphen."
done

# Prompt for timezone
while true; do
  read -p "Enter your timezone (e.g., Asia/Bangkok): " timezone
  timezone="${timezone:-Asia/Bangkok}"  # default if empty
  if [ -f "/usr/share/zoneinfo/$timezone" ]; then echo "Timezone set to: $timezone"; break; fi
  echo "Invalid timezone: $timezone"
done

# Prompt for drive to partition
echo; lsblk; echo
while true; do
  read -p "Enter drive to use (e.g., /dev/sda, /dev/nvme0n1, /dev/mmcblk0): " drive
  # Check if the drive is valid (not a partition) and if it's a block device
  if [[ "$drive" =~ ^/dev/[a-zA-Z0-9]+$ ]] && [ -b "$drive" ] && ! [[ "$drive" =~ [0-9p]$ ]]; then
    # Confirm before proceeding
    read -rp "WARNING: This will erase all data on $drive. Are you sure you want to continue? [y/N]: " confirm
    case "$confirm" in
      [yY][eE][sS]|[yY]) break ;;
      *) echo "Aborting."; exit 1 ;;
    esac
  else
    echo "Invalid drive: $drive. Please enter a valid drive (e.g., /dev/sda, /dev/nvme0n1) without a partition number or 'p' suffix."
  fi
done

# Partition the drive
if ! parted -s "$drive" mklabel gpt; then echo "Failed to create partition table."; exit 1; fi
if ! parted -s "$drive" mkpart primary fat32 1MiB 513MiB; then echo "Failed to create boot partition."; exit 1; fi
if ! parted -s "$drive" set 1 esp on; then echo "Failed to set ESP flag."; exit 1; fi
if ! parted -s "$drive" mkpart primary btrfs 513MiB 100%; then echo "Failed to create root partition."; exit 1; fi

# Determine correct partition suffix
if [[ "$drive" == *"nvme"* || "$drive" == *"mmcblk"* ]]; then
  BOOT="${drive}p1"; ROOT="${drive}p2"
else
  BOOT="${drive}1"; ROOT="${drive}2"
fi

# Format the partitions
if ! mkfs.vfat "$BOOT"; then echo "Failed to format EFI partition."; exit 1; fi
if ! mkfs.btrfs -f "$ROOT"; then echo "Failed to format root partition."; exit 1; fi

# Create BTRFS subvolumes
mount "$ROOT" /mnt || { echo "Failed to mount root partition."; exit 1; }
btrfs su cr /mnt/@ || { echo "Failed to create subvolume @."; exit 1; }
btrfs su cr /mnt/@home || { echo "Failed to create subvolume @home."; exit 1; }
umount /mnt

# Mount the partitions
mkdir -p /mnt/gentoo
mount -o noatime,compress=zstd,discard=async,subvol=@ "$ROOT" /mnt/gentoo
mkdir -p /mnt/gentoo/{efi,home}
mount -o noatime,compress=zstd,discard=async,subvol=@home "$ROOT" /mnt/gentoo/home
mount "$BOOT" /mnt/gentoo/efi

#========================== Gentoo Install - The Stage File ==========================

# Move to Mounted Root Partition
cd /mnt/gentoo

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

# Download tarball and verification files
echo; for suffix in "" ".asc" ".DIGESTS" ".sha256"; do
  wget -c -T 10 -t 10 -q --show-progress "$RELEASES_URL/$STAGE3_TARBALL$suffix"
done

# Import Gentoo release key via WKD
echo; gpg --quiet --auto-key-locate=clear,nodefault,wkd --locate-key releng@gentoo.org

# Verify GPG signature files
echo "Verifying GPG signatures..."
for ext in asc DIGESTS sha256; do
  echo "- Checking $STAGE3_TARBALL.$ext..."
  if ! gpg --verify "$STAGE3_TARBALL.$ext" 2>/dev/null; then
    echo "GPG verification of $STAGE3_TARBALL.$ext failed! Aborting..."
    exit 1
  fi
done

# If all verifications passed, extract the tarball
echo; echo "All verifications passed. Extracting tarball..."
tar xpf "$STAGE3_TARBALL" --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo

# Pull make.conf with use flags, jobs, licenses, mirrors, etc already set
url="https://raw.githubusercontent.com/spreadiesinspace/cinnamon-dotfiles/main/etc/portage/make.conf"
path="/mnt/gentoo/etc/portage/make.conf"

# Backup and exit on failure
cp "$path" "$path.stage3"
curl -fsSL "$url" -o "$path" || {
  echo "Failed to fetch $url, restoring original make.conf."
  mv "$path.stage3" "$path"
  exit 1
}
echo; echo "make.conf updated successfully"

# Set MAKEOPTS based on CPU cores (load limit = cores + 1)
cores=$(nproc)
makeopts_load_limit=$((cores + 1))
sed -i "s/^MAKEOPTS=.*/MAKEOPTS=\"-j$cores -l$makeopts_load_limit\"/" /mnt/gentoo/etc/portage/make.conf
echo; echo "Updated MAKEOPTS to -j$cores -l$makeopts_load_limit"

# Set EMERGE_DEFAULT_OPTS based on CPU cores (load limit as 90% of cores)
load_limit=$(echo "$cores * 0.9" | bc -l | awk '{printf "%.1f", $0}')
sed -i "s/^EMERGE_DEFAULT_OPTS=.*/EMERGE_DEFAULT_OPTS=\"-j$cores -l$load_limit\"/" /mnt/gentoo/etc/portage/make.conf
echo "Updated EMERGE_DEFAULT_OPTS to -j$cores -l$load_limit"

# Set VIDEO_CARDS value in package.use
set_video_card() {
  while true; do
    echo "Select your video card type:"
    echo
    echo "1) amdgpu radeonsi"
    echo "2) nvidia"
    echo "3) intel"
    echo "4) nouveau (open source)"
    echo "5) virgl (QEMU/KVM)"
    echo "6) vc4 (Raspberry Pi)"
    echo "7) d3d12 (WSL)"
    echo "8) other"
    echo
    read -p "Enter the number corresponding to your video card: " video_card_number

    case $video_card_number in
      1) video_card="amdgpu radeonsi"; break ;;
      2) video_card="nvidia"; break ;;
      3) video_card="intel"; break ;;
      4) video_card="nouveau"; break ;;
      5) video_card="virgl"; break ;;
      6) video_card="vc4"; break ;;
      7) video_card="d3d12"; break ;;
      8) 
        read -p "Enter the video card type: " video_card; break ;;
      *) echo "Invalid selection, please try again." ;;
    esac
  done

  # Create or update the /etc/portage/package.use/00video-cards file
  echo "*/* VIDEO_CARDS: $video_card" | tee /mnt/gentoo/etc/portage/package.use/00video-cards >/dev/null
  echo; echo "Updated VIDEO_CARDS in /etc/portage/package.use/00video-cards to $video_card based on provided input."; echo
}

# Call the function
echo; set_video_card

# Signal that make.conf was configured during install phase
touch /mnt/gentoo/etc/portage/.makeconf_configured

# Review make.conf
# nano /mnt/gentoo/etc/portage/make.conf

#================ Gentoo Install - Installing the Gentoo Base System =================

# Copy Network Info 
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/

# Mount Filesystems
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run

# Extra Mounts for Non-Gentoo Media
test -L /dev/shm && rm /dev/shm && mkdir /dev/shm
mount --types tmpfs --options nosuid,nodev,noexec shm /dev/shm   
chmod 1777 /dev/shm /run/shm

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
cat << CLONE | su - "$username"
cd; git clone https://github.com/SpreadiesInSpace/cinnamon-dotfiles
cd cinnamon-dotfiles
echo "Reboot and run Setup-Gentoo.sh in cinnamon-dotfiles located in $username's home folder."
CLONE
EOF
