#!/bin/bash

<<skip
# For SSH
passwd
dhcpcd
/etc/rc.d/rc.dropbear start
skip

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run the script as superuser"
  exit
fi

# Prompt for root password
# read -sp "Enter new root password: " rootpasswd
# echo

# Prompt for new user details
read -p "Enter new username: " username
read -sp "Enter password for $username: " userpasswd
echo

# BTRFS Subvolumes (for Timeshift) - Preparing the Disks
mkfs.vfat /dev/vda1
mkfs.btrfs -f /dev/vda2
mount /dev/vda2 /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@home
umount /mnt
mount -o noatime,compress=zstd,space_cache=v2,subvol=@ /dev/vda2 /mnt/ 
mkdir -p /mnt/home
mount -o noatime,compress=zstd,space_cache=v2,subvol=@home /dev/vda2 /mnt/home 
mkdir -p /mnt/boot/efi
mount /dev/vda1 /mnt/boot/efi

# Setup
# Don't accidentally format partition
# Don't install (E)LILO
# Enable rc.samba
# Hardware Clock to UTC
# Select XFCE as DE
# Drop to Shell
setup

# Copy Network Info 
cp --dereference /etc/resolv.conf /mnt/etc/

# Entering Chroot
cat << EOF | chroot /mnt /bin/bash

# New Chroot
source /etc/profile

# Install Grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub
grub-mkconfig -o /boot/grub/grub.cfg

# Edit fstab for Timeshift
# noatime,compress=zstd,space_cache=v2,subvol=@ for /
# noatime,compress=zstd,space_cache=v2,subvol=@home for /home
# nano /etc/fstab

# Install arch-install-scripts for fstab 
wget https://gitlab.archlinux.org/archlinux/arch-install-scripts/-/archive/v29/arch-install-scripts-v29.tar.gz
wget https://slackbuilds.org/slackbuilds/15.0/system/arch-install-scripts.tar.gz
tar xvf arch-install-scripts.tar.gz
mv arch-install-scripts-v29.tar.gz arch-install-scripts/
cd arch-install-scripts/
./arch-install-scripts.SlackBuild
installpkg /tmp/arch-install-scripts-29-noarch-1_SBo.tgz
cd ..
rm -rf arch-install-scripts*

# Generate Fstab
genfstab -U / > /etc/fstab

# Add User - Set password for root and user with responses from the start
# echo "root:$rootpasswd" | chpasswd
useradd -m -g users -G wheel,audio,video,plugdev,netdev,lp,scanner -s /bin/bash $username
echo "$username:$userpasswd" | chpasswd

# Setup Sudo by uncommenting %wheel ALL=(ALL:ALL) with visudo
sed -i 's/^#\s*\(%wheel ALL=(ALL:ALL) ALL\)/\1/' /etc/sudoers

# Set Run Level to 4
if [ -f "/etc/inittab" ]; then
  sed -i 's/id:3:initdefault:/id:4:initdefault:/g' /etc/inittab
  echo "Default run level changed to 4 in /etc/inittab"
else
  echo "/etc/inittab file not found. Skipping the run level change."
fi

# Clone My Repo as the new user
cat << EOUSR | su - $username
cd
git clone https://github.com/SpreadiesInSpace/cinnamon-dotfiles
cd cinnamon-dotfiles
# sudo bash Setup-Slackware.sh
echo "Reboot and run Setup-Slackware.sh in cinnamon-dotfiles located in $username's home folder."
EOUSR
EOF
