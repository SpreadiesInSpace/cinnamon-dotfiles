#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run the script as superuser"
  exit
fi

# Enable Parallel Downloads
export ZYPP_CURL2=1
export ZYPP_PCK_PRELOAD=1

# Refresh (for older ISOs)
zypper ref

# Fix openSUSE's line break paste issue
echo "set enable-bracketed-paste" >> ~/.inputrc

# Prompt for root password
read -sp "Enter new root password: " rootpasswd
echo

# Prompt for new user details
read -p "Enter new username: " username
read -sp "Enter password for $username: " userpasswd
echo

# Prompt for hostname
read -p "Enter hostname: " hostname

# Prompt for drive to partition
echo
lsblk
echo
read -p "Enter drive to use (e.g., /dev/sda, /dev/nvme0n1, /dev/mmcblk0): " drive

# Partition the drive
echo "Partitioning $drive..."
parted -s "$drive" mklabel gpt
parted -s "$drive" mkpart primary fat32 1MiB 513MiB
parted -s "$drive" set 1 esp on
parted -s "$drive" mkpart primary btrfs 513MiB 100%

# Format the partitions
if [[ "$drive" == *"nvme"* ]] || [[ "$drive" == *"mmcblk"* ]]; then
  mkfs.vfat "${drive}p1"
  mkfs.btrfs -f "${drive}p2"
else
  mkfs.vfat "${drive}1"
  mkfs.btrfs -f "${drive}2"
fi

# Mount the partitions and create BTRFS subvolumes
if [[ "$drive" == *"nvme"* ]] || [[ "$drive" == *"mmcblk"* ]]; then
  mount "${drive}p2" /mnt
else
  mount "${drive}2" /mnt
fi

btrfs su cr /mnt/@
btrfs su cr /mnt/@home
umount /mnt

if [[ "$drive" == *"nvme"* ]] || [[ "$drive" == *"mmcblk"* ]]; then
  mount -o noatime,compress=zstd,space_cache=v2,subvol=@ "${drive}p2" /mnt
  mkdir -p /mnt/home
  mount -o noatime,compress=zstd,space_cache=v2,subvol=@home "${drive}p2" /mnt/home
  mkdir -p /mnt/boot/efi
  mount "${drive}p1" /mnt/boot/efi
else
  mount -o noatime,compress=zstd,space_cache=v2,subvol=@ "${drive}2" /mnt
  mkdir -p /mnt/home
  mount -o noatime,compress=zstd,space_cache=v2,subvol=@home "${drive}2" /mnt/home
  mkdir -p /mnt/boot/efi
  mount "${drive}1" /mnt/boot/efi
fi

# Mount System Partitions
mkdir /mnt/{proc,sys,dev,run}
mount --types proc /proc /mnt/proc
mount --rbind /sys /mnt/sys
mount --make-rslave /mnt/sys
mount --rbind /dev /mnt/dev
mount --make-rslave /mnt/dev
mount --bind /run /mnt/run
mount --make-slave /mnt/run

# Installing the Base System
zypper --root /mnt ar --no-gpgcheck --refresh https://download.opensuse.org/tumbleweed/repo/oss/ oss
zypper --root /mnt in -y kernel-default grub2-x86_64-efi shim zypper bash man shadow util-linux nano arch-install-scripts

# Copy Repos
cp /etc/zypp/repos.d/* /mnt/etc/zypp/repos.d/

# Copy Network Info
cp --dereference /etc/resolv.conf /mnt/etc/

# Chrooting
cat << EOF | chroot /mnt /bin/bash

# New Chroot
source /etc/profile
export PS1="(chroot) ${PS1}"

# Sync Repos
zypper ref

# Remove Dangling Repo
zypper rr oss

# Editing Fstab
genfstab -U / >> /etc/fstab

# Set Hostname
echo "$hostname" > /etc/hostname

# Setting Timezone
ln -sf ../usr/share/zoneinfo/Asia/Bangkok /etc/localtime

# Installing grub
dracut -f --regenerate-all
grub2-install --efi-directory=/boot/efi

# Set GRUB timeout to 0
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

# Install Basic Desktop
zypper in -y -t pattern basic_desktop
# Install Cinnamon Desktop Environment
zypper al mint-x-icon-theme mint-y-icon-theme
zypper rm -y busybox-which
zypper in -y cinnamon lightdm-slick-greeter btrfsprogs sudo bash-completion git
# Install Recommended Packages (excluding Snapper & Firefox)
zypper al snapper*
zypper inr
zypper rm -y MozillaFirefox* *-lang *-doc lightdm-gtk-greeter
zypper al MozillaFirefox* *-lang *-doc

# Configure lightdm
systemctl set-default graphical

# Setup Sudo
sed -i 's/^#\s*\(%wheel ALL=(ALL:ALL) ALL\)/\1/' /usr/etc/sudoers
# Add wheel group
groupadd -f wheel

# Set password for root and user
echo "root:$rootpasswd" | chpasswd
useradd -m -G wheel,audio,video,users -s /bin/bash $username 
echo "$username:$userpasswd" | chpasswd

# Enabling System Services
systemctl enable NetworkManager

# Clone My Repo as the new user
cat << EOUSR | su - $username
cd
git clone https://github.com/SpreadiesInSpace/cinnamon-dotfiles
cd cinnamon-dotfiles
echo "Reboot and run Setup-OpenSUSE-Tumbleweed.sh in cinnamon-dotfiles located in $username's home folder."
EOUSR
EOF
