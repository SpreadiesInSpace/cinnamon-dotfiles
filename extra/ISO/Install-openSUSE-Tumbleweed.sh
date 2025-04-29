#!/bin/bash

# Source common functions
[ -f ./Install-Common.sh ] && source ./Install-Common.sh || { echo "Install-Common.sh not found."; exit 1; }

# Check if script is run as root
check_if_root

# Detect if booted in UEFI or BIOS mode
detect_boot_mode

# Enable Parallel Downloads
export ZYPP_PCK_PRELOAD=1 || die "Failed to enable parallel downloads."

# Fix openSUSE's line break paste issue
echo "set enable-bracketed-paste" >> ~/.inputrc || die "Failed to enable line break paste."

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

# Refresh (for older ISOs)
zypper ref

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

# Mount System Partitions
mount_system_partitions

# Installing the Base System
zypper --root /mnt ar --no-gpgcheck --refresh https://download.opensuse.org/tumbleweed/repo/oss/ oss || die "Failed to add openSUSE repo."
zypper --root /mnt in -y --download-in-advance dracut kernel-default grub2-x86_64-efi shim zypper bash man shadow util-linux nano arch-install-scripts || die "Failed to install base packages."

# Copy Repos
cp /etc/zypp/repos.d/* /mnt/etc/zypp/repos.d/ || die "Failed to copy repo files."

# Copy Network Info
[ ! -e /etc/resolv.conf ] && die "Source resolv.conf does not exist."
cp --dereference /etc/resolv.conf /mnt/etc/ || die "Failed to copy resolv.conf."

# Chrooting
cat << EOF | chroot /mnt /bin/bash || die "Failed to enter chroot."

# New Chroot
source /etc/profile
export PS1="(chroot) ${PS1}"

# Sync Repos
zypper ref

# Remove Dangling Repo (at this point, all proper repos have been generated)
zypper rr oss

# Generate fstab
genfstab -U / >> /etc/fstab

# Set Hostname
echo "$hostname" > /etc/hostname

# Allow Resolving the Local Hostname
echo -e "127.0.1.1\t$hostname.localdomain\t$hostname" >> /etc/hosts

# Set Locale
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo 'RC_LANG="en_US.UTF-8"' > /etc/sysconfig/language

# Set Keymap
echo "KEYMAP=us" > /etc/vconsole.conf

# Installing grub
dracut -f --regenerate-all
grub2-install --efi-directory=/boot/efi

# Set GRUB timeout to 0
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub

# Generate Grub Config
grub2-mkconfig -o /boot/grub2/grub.cfg

# Install Basic Desktop
zypper in -y -t pattern basic_desktop

# Install Cinnamon Desktop Environment
zypper al mint-x-icon-theme mint-y-icon-theme
zypper rm -y busybox-which
zypper in -y cinnamon lightdm-gtk-greeter-settings btrfsprogs sudo bash-completion git unzip

# Install Recommended Packages (excluding Snapper & Firefox)
zypper al snapper*
zypper inr
zypper rm -y MozillaFirefox* *-lang *-doc
zypper al MozillaFirefox* *-lang *-doc

# Configure lightdm
systemctl set-default graphical

# Set Timezone
ln -sf "../usr/share/zoneinfo/$timezone" /etc/localtime
hwclock --systohc

# Setup Sudo by uncommenting %wheel ALL=(ALL:ALL) with visudo
sed -i 's/^#\s*\(%wheel ALL=(ALL:ALL) ALL\)/\1/' /usr/etc/sudoers

# Add wheel group for sudo
groupadd -f wheel

# Create User and Set Passwords
useradd -m -G wheel,audio,video,users -s /bin/bash "$username"
echo "root:$rootpasswd" | chpasswd
echo "$username:$userpasswd" | chpasswd

# Enabling System Services
systemctl enable NetworkManager

# Clone Repo as New User
cat << 'CLONE' | su - "$username"
cd; git clone https://github.com/SpreadiesInSpace/cinnamon-dotfiles
cd cinnamon-dotfiles
touch .opensuse-tumbleweed.done
echo "Reboot and run Setup.sh in cinnamon-dotfiles located in $username's home folder."
CLONE
EOF
