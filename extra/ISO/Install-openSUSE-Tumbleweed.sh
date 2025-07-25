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
zypper --root /mnt in -y --download-in-advance dracut kernel-default grub2 grub2-i386-pc grub2-x86_64-efi shim zypper bash man shadow util-linux nano arch-install-scripts || die "Failed to install base packages."

# Copy Repos
cp /etc/zypp/repos.d/* /mnt/etc/zypp/repos.d/ || die "Failed to copy repo files."

# Copy Network Info
[ ! -e /etc/resolv.conf ] && die "Source resolv.conf does not exist."
cp --dereference /etc/resolv.conf /mnt/etc/ || die "Failed to copy resolv.conf."

# Ensure variables are exported before chroot
export drive hostname timezone username rootpasswd userpasswd BOOTMODE REMOVABLE_BOOT || die "Failed to export required variables."

# Chrooting
cat << EOF | chroot /mnt /bin/bash || die "Failed to enter chroot."

# Minimal Error Handling function
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

# New Chroot
source /etc/profile || die "Failed to source /etc/profile."

# Sync Repos
zypper --gpg-auto-import-keys ref || die "Failed to refresh zypper repositories."

# Remove Dangling Repo (at this point, all proper repos have been generated)
zypper rr oss || die "Failed to remove oss repo."

# Generate fstab
genfstab -U / >> /etc/fstab || die "Failed to generate fstab."

# Set Hostname
echo "$hostname" > /etc/hostname || die "Failed to set hostname."

# Allow Resolving the Local Hostname
echo -e "127.0.1.1\t$hostname.localdomain\t$hostname" >> /etc/hosts || die "Failed to write to /etc/hosts."

# Set Locale
echo "LANG=en_US.UTF-8" > /etc/locale.conf || die "Failed to set /etc/locale.conf."
echo 'RC_LANG="en_US.UTF-8"' > /etc/sysconfig/language || die "Failed to set /etc/sysconfig/language."

# Set Keymap
echo "KEYMAP=us" > /etc/vconsole.conf || die "Failed to set keymap."

# Configure GRUB Bootloader
dracut -f --regenerate-all || die "Failed to regenerate initramfs with dracut."
if [ "$BOOTMODE" = "UEFI" ]; then
  if [ "$REMOVABLE_BOOT" = "1" ]; then
    grub2-install --target=x86_64-efi --efi-directory=/boot/efi --removable || die "Failed to install GRUB (UEFI removable)."
  else
    grub2-install --target=x86_64-efi --efi-directory=/boot/efi || die "Failed to install GRUB (UEFI)."
  fi
else
  grub2-install --target=i386-pc --boot-directory=/boot "$drive" || die "Failed to install GRUB (BIOS)."
fi

# Set GRUB timeout to 0
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub || die "Failed to set GRUB_TIMEOUT."

# Generate Grub Config
grub2-mkconfig -o /boot/grub2/grub.cfg || die "Failed to generate GRUB config."

# Install Basic Desktop
zypper in -y -t pattern basic_desktop || die "Failed to install basic desktop pattern."

# Install Cinnamon Desktop Environment
zypper al mint-x-icon-theme mint-y-icon-theme || die "Failed to lock Mint icon themes."
zypper rm -y busybox-which || die "Failed to remove busybox-which."
zypper in -y cinnamon gnome-terminal spice-vdagent lightdm-gtk-greeter-settings btrfsprogs sudo bash-completion git unzip || die "Failed to install Cinnamon and base packages."

# Install Recommended Packages (excluding Snapper & Firefox)
zypper al snapper* || die "Failed to lock snapper packages."
zypper -n inr || die "Failed to install recommended packages."
zypper rm -y MozillaFirefox* *-lang *-doc || die "Failed to remove Firefox, language packs, and docs."
zypper al MozillaFirefox* *-lang *-doc || die "Failed to lock Firefox, language packs, and docs."

# Configure lightdm
systemctl set-default graphical || die "Failed to set default target to graphical."

# Set Timezone
ln -sf "../usr/share/zoneinfo/$timezone" /etc/localtime || die "Failed to set timezone."
hwclock --systohc || die "Failed to sync hardware clock."

# Setup Sudo by uncommenting %wheel ALL=(ALL:ALL) with visudo
sed -i 's/^#\s*\(%wheel ALL=(ALL:ALL) ALL\)/\1/' /usr/etc/sudoers || die "Failed to enable sudo for wheel group."

# Add wheel group for sudo
groupadd -f wheel || die "Failed to add wheel group."

# Create User and Set Passwords
useradd -m -G wheel,audio,video,users -s /bin/bash "$username" || die "Failed to create user."
echo "root:$rootpasswd" | chpasswd || die "Failed to set root password."
echo "$username:$userpasswd" | chpasswd || die "Failed to set user password."

# Enabling System Services
systemctl enable NetworkManager || die "Failed to enable NetworkManager."

# Clone Repo as New User
cat << 'CLONE' | su - "$username"
cd && git clone https://github.com/SpreadiesInSpace/cinnamon-dotfiles || { echo "Failed to clone repo."; exit 1; }
cd cinnamon-dotfiles || { echo "Failed to enter repo directory."; exit 1; }
touch .opensuse-tumbleweed.done || { echo "Failed to create flag."; exit 1; }
echo "Reboot and run Setup.sh in cinnamon-dotfiles located in \$HOME/cinnamon-dotfiles."
CLONE
EOF
