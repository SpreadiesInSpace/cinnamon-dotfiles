#!/bin/bash

<<skip
# For SSH
passwd
dhcpcd
/etc/rc.d/rc.dropbear start
# For KVM/QEMU
sudo su # passwd: live
/etc/rc.d/rc.spice-vdagent start
skip

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run the script as superuser"
  exit
fi

# Prompt for root password
read -sp "Enter new root password: " rootpasswd
echo

# Prompt for user details
read -p "Enter new username: " username
read -sp "Enter password for $username: " userpasswd
echo

# Prompt for hostname
read -p "Enter hostname: " hostname

# Prompt for drive to partition
echo
lsblk
echo
read -p "Enter drive to use (e.g., /dev/sda, /dev/vda, /dev/nvme0n1, /dev/mmcblk0): " drive

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
  mkdir -p /setup2hd
  mount -o noatime,compress=zstd,space_cache=v2,subvol=@ "${drive}p2" /setup2hd
  mkdir -p /setup2hd/home
  mount -o noatime,compress=zstd,space_cache=v2,subvol=@home "${drive}p2" /setup2hd/home
  mkdir -p /setup2hd/boot/efi
  mount "${drive}p1" /setup2hd/boot/efi
else
  mount -o noatime,compress=zstd,space_cache=v2,subvol=@ "${drive}2" /setup2hd
  mkdir -p /setup2hd/home
  mount -o noatime,compress=zstd,space_cache=v2,subvol=@home "${drive}2" /setup2hd/home
  # setup2hd mounts /setup2hd/boot/efi by itself 
  # mkdir -p /setup2hd/boot/efi
  # mount "${drive}1" /setup2hd/boot/efi
fi

# Setup
echo "Follow these steps during 'setup':
- Do not format partitions accidentally
- Do not install (E)LILO
- Enable rc.samba
- Set hardware clock to UTC
- Drop to Shell after installation"
setup2hd

# Copy Network Info
cp --dereference /etc/resolv.conf /setup2hd/etc/

# Entering Chroot
cat << EOF | chroot /setup2hd /bin/bash

# New Chroot
source /etc/profile

# Set Timezone
ln -sf /usr/share/zoneinfo/Asia/Bangkok /etc/localtime
hwclock --systohc

# Install Grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub
# Set GRUB timeout to 0
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Function to install arch-install-scripts
install_arch_install_scripts() {
  echo "Installing arch-install-scripts..."

  # Download necessary files
  wget -q https://gitlab.archlinux.org/archlinux/arch-install-scripts/-/archive/v29/arch-install-scripts-v29.tar.gz -O arch-install-scripts-v29.tar.gz
  wget -q https://slackbuilds.org/slackbuilds/15.0/system/arch-install-scripts.tar.gz -O arch-install-scripts-slackbuild.tar.gz

  # Extract files
  tar -xf arch-install-scripts-slackbuild.tar.gz
  mv arch-install-scripts-v29.tar.gz arch-install-scripts/
  cd arch-install-scripts || exit

  # Build and install the package
  ./arch-install-scripts.SlackBuild
  installpkg /tmp/arch-install-scripts-29-noarch-1_SBo.tgz

  # Clean up
  cd ..
  rm -rf arch-install-scripts*
}

# Call the function
install_arch_install_scripts

# Edit /etc/fstab for Timeshift
# noatime,compress=zstd,space_cache=v2,subvol=@ for /
# noatime,compress=zstd,space_cache=v2,subvol=@home for /home
genfstab -U / > /etc/fstab
echo "proc              /proc           proc    defaults         0 0
devpts            /dev/pts        devpts  gid=5,mode=620   0 0
tmpfs             /dev/shm        tmpfs   defaults         0 0" >> /etc/fstab

# Set Hostname
echo "$hostname" > /etc/HOSTNAME
echo "# For loopbacking.
127.0.0.1               localhost
::1                     localhost" | tee /etc/hosts > /dev/null

# Setup Sudo
sed -i 's/^#\s*\(%wheel ALL=(ALL:ALL) ALL\)/\1/' /etc/sudoers

# Set password for root and user
echo "root:$rootpasswd" | chpasswd
useradd -m -g users -G wheel,audio,video,plugdev,netdev,lp,scanner -s /bin/bash
echo "$username:$userpasswd" | chpasswd

# Clone My Repo as the new user
cat << EOUSR | su - $username
cd
git clone https://github.com/SpreadiesInSpace/cinnamon-dotfiles
cd cinnamon-dotfiles
echo "Reboot and run Setup-Slackware.sh in cinnamon-dotfiles located in $username's home folder."
EOUSR
EOF

<<notes
mkfs.vfat /dev/vda1
mkfs.btrfs -f /dev/vda2
mount /dev/vda2 /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@home
umount /mnt
mkdir -p /setup2hd
mount -o noatime,compress=zstd,space_cache=v2,subvol=@ /dev/vda2 /setup2hd/ 
mkdir -p /setup2hd/home
mount -o noatime,compress=zstd,space_cache=v2,subvol=@home /dev/vda2 /setup2hd/home
# setup2hd mounts /setup2hd/boot/efi by itself 
# mkdir -p /setup2hd/boot/efi
# mount /dev/vda1 /setup2hd/boot/efi

# GFS 48 Repo
https://reddoglinux.ddns.net/linux/gnome/48.x/x86_64/
https://slackware.lngn.net/pub/x86_64/slackware64-current/gfs48/

# has:
flatpak

# doesn't have:
gparted
kdeconnect-kde

