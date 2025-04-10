#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run the script as superuser"
  exit
fi

# Prompt for root password
read -sp "Enter new root password: " rootpasswd; echo
if [ -z "$rootpasswd" ]; then echo "Root password cannot be empty."; exit 1; fi

# Prompt for new user details
read -p "Enter new username: " username
if ! [[ "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then echo "Invalid username. Use only lowercase letters, numbers, underscores or hyphens (cannot start with number or hyphen)"; exit 1; fi
read -sp "Enter password for $username: " userpasswd; echo
if [ -z "$userpasswd" ]; then echo "User password cannot be empty."; exit 1; fi

# Prompt for hostname
read -p "Enter hostname: " hostname
if [[ ! "$hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?$ ]]; then echo "Invalid hostname. Must be alphanumeric and may include hyphens (no leading/trailing hyphen)."; exit 1; fi

# Prompt for timezone
read -p "Enter your timezone (e.g., Asia/Bangkok): " timezone
timezone="${timezone:-Asia/Bangkok}"  # default if empty
if [ ! -f "/usr/share/zoneinfo/$timezone" ]; then echo "Invalid timezone: $timezone"; exit 1; fi
echo "Timezone set to: $timezone"

# Prompt for drive to partition
echo; lsblk; echo
read -p "Enter drive to use (e.g., /dev/sda, /dev/nvme0n1, /dev/mmcblk0): " drive
if [ ! -b "$drive" ]; then echo "Invalid drive: $drive"; exit 1; fi

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

# Gentoo Install - The Stage File
cd /mnt/gentoo
# Sync Time
hwclock --systohc --utc
# Grab the Latest Systemd Stage 3 Desktop Profile
# https://www.gentoo.org/downloads/#other-arches
GENTOO_MIRROR="https://distfiles.gentoo.org" GENTOO_ARCH="amd64" STAGE3_BASENAME="stage3-amd64-desktop-systemd" STAGE3_RELEASES="$GENTOO_MIRROR/releases/$GENTOO_ARCH/autobuilds/current-$STAGE3_BASENAME/" CURRENT_STAGE3=$(curl -s "$STAGE3_RELEASES" | python3 -c 'import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read()))' | grep -o "\"${STAGE3_BASENAME}-[0-9A-Z]*.tar.xz\"" | sort -u | head -1 | sed 's/"//g') && wget --no-clobber --timeout=10 --tries=10 "$STAGE3_RELEASES/$CURRENT_STAGE3"
# Check if Tarball is There
if [ -z "$CURRENT_STAGE3" ]; then echo "Failed to get the latest Stage 3 tarball name."; exit 1; fi
# Extract Stage 3 tarball
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo
# Pull make.conf with use flags, jobs, licenses, mirrors, etc already set
# https://github.com/SpreadiesInSpace/cinnamon-dotfiles/blob/main/etc/portage/make.conf
declare -A files=(["https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles/main/etc/portage/make.conf"]="/mnt/gentoo/etc/portage/make.conf"); for url in "${!files[@]}"; do local_path="${files[$url]}"; cp "$local_path" "${local_path}.old"; curl -o "$local_path" "$url"; if [ $? -eq 0 ]; then echo "File $local_path updated successfully."; else echo "Failed to update the file $local_path."; mv "${local_path}.old" "$local_path"; fi; done
# Update MAKEFLAGS & EMERGE_DEFAULT_OPS in /etc/portage/make.conf to match CPU cores
cores=$(nproc) && load_limit=$((cores + 1)) && sed -i.bak "s/^MAKEOPTS=.*/MAKEOPTS=\"-j$cores -l$load_limit\"/; s/^EMERGE_DEFAULT_OPTS=.*/EMERGE_DEFAULT_OPTS=\"-j$cores -l$load_limit\"/" /mnt/gentoo/etc/portage/make.conf && echo "Updated MAKEOPTS and EMERGE_DEFAULT_OPTS in /etc/portage/make.conf to -j$cores -l$load_limit based on the number of CPU cores."
# Set VIDEO_CARDS value in make.conf
set_video_card() {
  while true; do
    echo "Valid values are:"
    echo "1) amdgpu radeonsi"
    echo "2) nvidia"
    echo "3) intel"
    echo "4) nouveau (open source)"
    echo "5) virgl (QEMU/KVM)"
    echo "6) vc4 (Raspberry Pi)"
    echo "7) d3d12 (WSL)"
    echo "8) other"
    read -p "Enter the video card type number: " video_card_number

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
  # Edit make.conf to set VIDEO_CARDS
  sed -i "s/^VIDEO_CARDS=.*/VIDEO_CARDS=\"$video_card\"/" /mnt/gentoo/etc/portage/make.conf
  echo "Updated VIDEO_CARDS in /mnt/gentoo/etc/portage/make.conf to $video_card based on provided input."
}
# Call the function
set_video_card
# nano /mnt/gentoo/etc/portage/make.conf

# Gentoo Install - Installing the Gentoo Base System
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
# Setting Binary Packages
echo "[binhost]
priority = 9999
sync-uri = http://download.nus.edu.sg/mirror/gentoo/releases/amd64/binpackages/23.0/x86-64-v3/
#sync-uri = https://distfiles.gentoo.org/releases/amd64/binpackages/23.0/x86-64-v3/
" > /etc/portage/binrepos.conf/gentoo.conf
# Verify GPG
rm -rf /etc/portage/gnupg/ && getuto
# Suppress unsafe directories warnings
chmod 644 /etc/portage/gnupg/pubring.kbx
chmod 644 /etc/portage/make.conf
# emerge -qv mirrorselect # mirrors already set in make.conf
# Install Essentials 
emerge -vquN app-eselect/eselect-repository dev-vcs/git
# Switch from rsync to git for faster repository sync times
eselect repository disable gentoo
eselect repository enable gentoo
rm -rf /var/db/repos/gentoo
# Sync Repository
emaint sync -r gentoo
emerge -qv --oneshot sys-apps/portage
# eselect news list
# eselect news read
# Select 23.0 gnome desktop systemd profile for Cinnamon
eselect profile set default/linux/amd64/23.0/desktop/gnome/systemd
# CPU Flags
emerge -qv --oneshot app-portage/cpuid2cpuflags
echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags
# Update World Set
emerge -vqDuN @world
# Remove Obselete Packages
emerge -q --depclean
# Setting Timezone
ln -sf "../usr/share/zoneinfo/$timezone" /etc/localtime
hwclock --systohc
# Locale Generation (uncomment en_US.UTF-8 UTF-8 in /etc/locale.gen)
sed -i 's/^#\s*\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen
# Set Locale
eselect locale set en_US.utf8
# Reload Environment
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"

# Gentoo Install - Configuring the Linux Kernel
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

# Gentoo Install - Configuring the System
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

# Gentoo Install - Installing System Tools
emerge -vq sys-apps/mlocate app-shells/bash-completion sys-fs/xfsprogs sys-fs/e2fsprogs sys-fs/dosfstools sys-fs/btrfs-progs sys-fs/f2fs-tools sys-fs/ntfs3g sys-block/io-scheduler-udev-rules
# Enable Time Synchronization
systemctl enable systemd-timesyncd.service
# pulls in zfs-kmod which takes a while to compile
# emerge -qv sys-fs/zfs

# Gentoo Install - Configuring the Bootloader
grub-install --efi-directory=/efi
# Set GRUB timeout to 0
sed -i '/^#*GRUB_TIMEOUT=/s/^#*GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
# Generate Grub Config
grub-mkconfig -o /boot/grub/grub.cfg

# Gentoo Install - Finalizing
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
