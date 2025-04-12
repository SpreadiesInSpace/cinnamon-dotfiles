#!/bin/bash

# For SSH
# passwd
# dhcpcd
# /etc/rc.d/rc.dropbear start

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run the script as superuser"
  exit
fi

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
echo "Timezone set to: $timezone"

# Prompt for drive to partition
echo; lsblk; echo
read -p "Enter drive to use (e.g., /dev/sda, /dev/nvme0n1, /dev/mmcblk0): " drive
if [ ! -b "$drive" ]; then echo "Invalid drive: $drive"; exit 1; fi

# Partition the drive
if ! /usr/sbin/parted -s "$drive" mklabel gpt; then echo "Failed to create partition table."; exit 1; fi
if ! /usr/sbin/parted -s "$drive" mkpart primary fat32 1MiB 513MiB; then echo "Failed to create boot partition."; exit 1; fi
if ! /usr/sbin/parted -s "$drive" set 1 esp on; then echo "Failed to set ESP flag."; exit 1; fi
if ! /usr/sbin/parted -s "$drive" mkpart primary btrfs 513MiB 100%; then echo "Failed to create root partition."; exit 1; fi

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
mount -o noatime,compress=zstd,discard=async,subvol=@ "$ROOT" /mnt
mkdir -p /mnt/{boot/efi,home}
mount -o noatime,compress=zstd,discard=async,subvol=@home "$ROOT" /mnt/home
mount "$BOOT" /mnt/boot/efi

# Setup
echo "Follow these steps during 'setup':
- Do not format partitions accidentally
- Do not install (E)LILO
- Enable rc.samba & rc.sshd
- Set hardware clock to UTC
- Select XFCE as DE
- Drop to Shell after installation"
setup

# Copy Network Info
cp --dereference /etc/resolv.conf /mnt/etc/

# Entering Chroot
cat << EOF | chroot /mnt /bin/bash

# New Chroot
source /etc/profile

# Set Timezone
if [ ! -f "/usr/share/zoneinfo/$timezone" ]; then
  echo "Invalid timezone: $timezone. Falling back to Asia/Bangkok."
  ln -sf /usr/share/zoneinfo/Asia/Bangkok /etc/localtime
else
  ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime
fi
hwclock --systohc

# Install Grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub

# Set GRUB timeout to 0
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub

# Generate Grub Config
grub-mkconfig -o /boot/grub/grub.cfg

# Download arch-install-scripts source and SlackBuild (for genfstab)
echo "Installing arch-install-scripts..."
wget -q https://gitlab.archlinux.org/archlinux/arch-install-scripts/-/archive/v29/arch-install-scripts-v29.tar.gz -O arch-install-scripts-v29.tar.gz
wget -q https://slackbuilds.org/slackbuilds/15.0/system/arch-install-scripts.tar.gz -O arch-install-scripts-slackbuild.tar.gz

# Extract SlackBuild and move the source into place
tar -xf arch-install-scripts-slackbuild.tar.gz >/dev/null 2>&1
mv arch-install-scripts-v29.tar.gz arch-install-scripts/

# Build, install and cleanup
cd arch-install-scripts || exit 1
./arch-install-scripts.SlackBuild >/dev/null 2>&1
installpkg /tmp/arch-install-scripts-29-noarch-1_SBo.tgz>/dev/null 2>&1
cd .. && rm -rf arch-install-scripts*

# Generate fstab
genfstab -U / > /etc/fstab
# Append Essential Mounts
echo "#/dev/cdrom    /mnt/cdrom     auto      noauto,owner,ro,comment=x-gvfs-show    0 0
#/dev/fd0      /mnt/floppy    auto      noauto,owner                           0 0
devpts         /dev/pts       devpts    gid=5,mode=620                         0 0
proc           /proc          proc      defaults                               0 0
tmpfs          /dev/shm       tmpfs     nosuid,nodev,noexec                    0 0" >> /etc/fstab

# Set Hostname
echo "$hostname" > /etc/HOSTNAME

# Prevent software from unsafely resolving localhost over the network
echo "# For loopbacking.
127.0.0.1               localhost
::1                     localhost" | tee /etc/hosts > /dev/null

# Allow Resolving the Local Hostname
echo "127.0.1.1               $hostname.localdomain $hostname" >> /etc/hosts

# Setup Sudo by uncommenting %wheel ALL=(ALL:ALL) with visudo
sed -i 's/^#\s*\(%wheel ALL=(ALL:ALL) ALL\)/\1/' /etc/sudoers

# Set Run Level to 4
sed -i 's/id:3:initdefault:/id:4:initdefault:/g' /etc/inittab

# Create User and Set Password
useradd -m -g users -G wheel,audio,video,plugdev,netdev,lp,scanner -s /bin/bash "$username"
echo "$username:$userpasswd" | chpasswd

# Set Default DE to XFCE System-Wide
ln -sf /etc/X11/xinit/xinitrc.xfce /etc/X11/xinit/xinitrc
ln -sf /etc/X11/xinit/xinitrc.xfce /etc/X11/xsession

# Enable Autologin
sed -i '/^\[Autologin\]/,/^\[/ {
  s/^User=[[:space:]]*$/User='$username'/;
  s/^Session=[[:space:]]*$/Session=xfce/;
  s/^User=.*$/User='$username'/;
  s/^Session=.*$/Session=xfce/;
}' /etc/sddm.conf

# Clone Repo as New User
cat << CLONE | su - $"$username"
cd; git clone https://github.com/SpreadiesInSpace/cinnamon-dotfiles
cd cinnamon-dotfiles
echo "Reboot and run Setup-Slackware.sh in cinnamon-dotfiles located in $username's home folder."
CLONE
EOF
