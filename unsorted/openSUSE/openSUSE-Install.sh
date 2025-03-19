#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run the script as superuser"
  exit
fi

# Zypper Enable Parallel Downloads
export ZYPP_CURL2=1
export ZYPP_PCK_PRELOAD=1

# Fix openSUSE's line break paste
echo "set enable-bracketed-paste" >> .inputrc

# Prompt for root password
read -sp "Enter new root password: " rootpasswd
echo

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
mkdir -p /mnt
mount -o noatime,compress=zstd,space_cache=v2,subvol=@ /dev/vda2 /mnt 
mkdir -p /mnt/home
mount -o noatime,compress=zstd,space_cache=v2,subvol=@home /dev/vda2 /mnt/home
mkdir -p /mnt/boot/efi
mount /dev/vda1 /mnt/boot/efi

# Mounting the Partitions
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

# Editing Fstab
genfstab -U / >> /etc/fstab

# Set Hostname
echo openSUSE > /etc/hostname

# Setting Timezone
ln -sf ../usr/share/zoneinfo/Asia/Bangkok /etc/localtime

# Installing grub
dracut -f --regenerate-all
grub2-install --efi-directory=/boot/efi
grub2-mkconfig -o /boot/grub2/grub.cfg

# Install Basic Desktop
zypper in -y btrfsprogs sudo bash-completion git
zypper in -y -t pattern basic_desktop
# Install Cinnamon Desktop Environment
zypper al mint-x-icon-theme mint-y-icon-theme
zypper rm -y busybox-which
zypper in -y cinnamon lightdm
# Install Recommended Packages (excluding Snapper & Firefox)
zypper al snapper*
zypper inr
zypper rm -y MozillaFirefox* *-lang *-doc
zypper al MozillaFirefox* *-lang *-doc
# Configure lightdm
systemctl set-default graphical
# update-alternatives --config default-displaymanager

# Set up Sudo
# Setup Sudo by uncommenting %wheel ALL=(ALL:ALL) with visudo
sed -i 's/^#\s*\(%wheel ALL=(ALL:ALL) ALL\)/\1/' /usr/etc/sudoers
# Create a new group named 'wheel' if it doesn't already exist
groupadd -f wheel

# Set password for root and user with responses from the start
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
# sudo bash Setup-OpenSUSE-Tumbleweed.sh
echo "Reboot and run Setup-OpenSUSE-Tumbleweed.sh in cinnamon-dotfiles located in $username's home folder."
EOUSR
EOF
