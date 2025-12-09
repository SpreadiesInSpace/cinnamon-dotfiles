#!/bin/bash

# Source common functions
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }
if [ ! -f ./Master-Common.sh ]; then
  URL="https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles"
  URL="$URL/main/extra/ISO/Master-Common.sh"

  # Try curl first, fallback to wget if curl is not available
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL -o Master-Common.sh "$URL" || \
      die "Failed to download Master-Common.sh"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO Master-Common.sh "$URL" || \
      die "Failed to download Master-Common.sh"
  else
    die "Neither curl nor wget is available for downloading Master-Common.sh"
  fi
fi
source ./Master-Common.sh || \
  die "Failed to source Master-Common.sh"

detect_boot_mode() {
  # Detect if booted in UEFI or BIOS mode
  if [ -d /sys/firmware/efi ]; then
    BOOTMODE="UEFI"
    REMOVABLE_BOOT="0"
    # Check if efivarfs is mounted
    if ! grep -q 'efivarfs' /proc/mounts; then
      echo "efivars not mounted. Attempting to mount efivarfs..."
      if ! mount -t efivarfs efivarfs /sys/firmware/efi/efivars \
        2>/dev/null; then
        echo "Failed to mount efivarfs. Attempting to remount as read-write..."
        if ! mount -o remount,rw,nosuid,nodev,noexec --types \
          efivarfs efivarfs /sys/firmware/efi/efivars 2>/dev/null; then
          # At this point, efivars exists but is not writable/mountable
          if [ ! -w /sys/firmware/efi/efivars ]; then
            # Writable access blocked — may be removable boot
            REMOVABLE_BOOT="1"
          fi
          die "UEFI detected but efivarfs is not accessible.
This is likely a permissions or kernel setting issue."
        fi
      fi
    fi
    # If efivarfs is mounted but not writable, mark as removable boot
    if [ ! -w /sys/firmware/efi/efivars ]; then
      REMOVABLE_BOOT="1"
    fi
  else
    BOOTMODE="BIOS"
    echo "WARNING: You are booted in BIOS mode."
    echo "Continuing in BIOS mode."
  fi
  export REMOVABLE_BOOT
}

time_sync() {
  # Sync time and hardware clock
  echo "Synchronizing system time..."
  NTP_POOL="${NTP_POOL:-pool.ntp.org}"
  local success=false

  # Try commands in order: timedatectl, chronyc, chronyd, ntpd & ntpdate
  if [ "$success" = false ] && command -v timedatectl >/dev/null 2>&1; then
    { timedatectl set-ntp true 2>/dev/null || \
      systemctl restart systemd-timesyncd 2>/dev/null || \
      systemctl start systemd-timesyncd 2>/dev/null; } && success=true
  fi
  if [ "$success" = false ] && command -v chronyc >/dev/null 2>&1 && \
     pgrep chronyd >/dev/null 2>&1; then
    { chronyc -a "burst 4/4" && chronyc -a makestep; } >/dev/null 2>&1 && \
      success=true
  elif [ "$success" = false ] && command -v chronyd >/dev/null 2>&1; then
    chronyd -q "server $NTP_POOL iburst" >/dev/null 2>&1 && success=true
  fi
  if [ "$success" = false ] && command -v ntpd >/dev/null 2>&1; then
    pkill ntpd 2>/dev/null || true
    { ntpd -gq -p "$NTP_POOL" 2>/dev/null || \
      ntpdate -s "$NTP_POOL" 2>/dev/null; } && success=true
  elif [ "$success" = false ] && command -v ntpdate >/dev/null 2>&1; then
    ntpdate -s "$NTP_POOL" 2>/dev/null && success=true
  fi

  # Sync hardware clock if any method succeeds
  if [ "$success" = true ] && command -v hwclock >/dev/null 2>&1; then
    hwclock --systohc --utc 2>/dev/null || \
      echo "Warning: Could not sync hardware clock"
  fi
  [ "$success" = true ]
}

prompt_root_password() {
  # Prompt for root password
  while true; do
    read -rsp "Enter new root password: " rootpasswd; echo
    read -rsp "Confirm root password: " rootpasswd_confirm; echo
    if [ -z "$rootpasswd" ]; then
      echo "Root password cannot be empty."
      continue
    fi
    if [ "$rootpasswd" != "$rootpasswd_confirm" ]; then
      echo "Passwords do not match. Try again."
      continue
    fi
    break
  done
}

prompt_username() {
  # Prompt for new username
  while true; do
    read -rp "Enter new username: " username
    if [[ -z "$username" ]]; then
      echo "Username cannot be empty."
    elif [[ "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
      break
    else
      echo "Invalid username. Use only lowercase letters, numbers, \
underscores or hyphens."
      echo "(cannot start with number or hyphen)"
    fi
  done
}

prompt_user_password() {
  # Prompt for new user password
  while true; do
    read -rsp "Enter password for $username: " userpasswd; echo
    read -rsp "Confirm password for $username: " userpasswd_confirm; echo
    if [ -z "$userpasswd" ]; then
      echo "User password cannot be empty."
      continue
    fi
    if [ "$userpasswd" != "$userpasswd_confirm" ]; then
      echo "Passwords do not match. Try again."
      continue
    fi
    break
  done
}

prompt_grub_timeout() {
  # Prompt for GRUB timeout
  while true; do
    read -rp "Enter GRUB timeout in seconds (default: 3): " grub_timeout
    grub_timeout="${grub_timeout:-3}"  # default if empty

    # Validate input is numeric and within range
    if [[ "$grub_timeout" =~ ^[0-9]+$ ]] &&
       [ "$grub_timeout" -ge 0 ] && [ "$grub_timeout" -le 10 ]; then
      echo "GRUB timeout set to: $grub_timeout seconds"
      break
    else
      echo "Invalid timeout. Please enter a number between 0 and 10."
    fi
  done
  export grub_timeout
}

prompt_drive() {
  # Prompt for drive to partition
  echo; lsblk -dpo NAME,SIZE,MODEL; echo

  # Check if the drive is a valid block device and not a partition
  local regex='^/dev/(sd[a-z]+|nvme[0-9]+n[0-9]+|mmcblk[0-9]+|vd[a-z]+)$'

  while true; do
    echo "Enter drive to use (e.g., /dev/sda, /dev/nvme0n1, /dev/mmcblk0):"
    read -r drive

    if [[ "$drive" =~ $regex ]] && [ -b "$drive" ]; then
      if mount | grep -q "^$drive"; then
        die "Drive $drive has mounted partitions. Aborting."
      fi

      echo "WARNING: This will erase all data on $drive"
      while true; do
        read -rp "Are you sure you want to continue? [y/N]: " confirm
        case "$confirm" in
          [yY][eE][sS]|[yY]) break 2 ;;  # exit both loops
          [nN][oO]|[nN]|'') die "Aborting." ;;
          *) echo "Invalid input. Please answer y or n." ;;
        esac
      done
    else
      echo "Invalid drive: $drive"
      echo "Enter a valid drive without a partition number"
    fi
  done
}

# Only NixOS uses this
prompt_for_autologin() {
  # Autologin Prompt
  while true; do
    read -rp "Enable autologin for $username? [y/N]: " autologin_input
    if [[ "$autologin_input" =~ ^([yY]|[yY][eE][sS])$ ]]; then
      enable_autologin=true
      break
    elif [[ "$autologin_input" =~ ^([nN]|[nN][oO])$ || \
        -z "$autologin_input" ]]; then
      enable_autologin=false
      break
    else
      echo "Invalid input. Please answer y or n."
    fi
  done
  export enable_autologin
}

# Only NixOS uses this
prompt_for_vm() {
  # VM Prompt
  while true; do
    read -rp "Is this a Virtual Machine? [y/N]: " response
    if [[ "$response" =~ ^([yY]|[yY][eE][sS])$ ]]; then
      is_vm=true
      break
    elif [[ "$response" =~ ^([nN]|[nN][oO])$ || -z "$response" ]]; then
      is_vm=false
      break
    else
      echo "Invalid input. Please answer y or n."
    fi
  done
}

partition_drive() {
  local distro="${1:-}"
  # Find parted binary
  if command -v parted >/dev/null 2>&1; then
    PARTED="parted"
  elif [ -x /usr/sbin/parted ]; then
    PARTED="/usr/sbin/parted"
  else
    die "parted not found. Cannot partition the drive."
  fi

  # Determine if we need separate /boot (Fedora requirement)
  local need_boot_partition=false
  [ "$distro" = "fedora" ] && need_boot_partition=true

  if [ "$BOOTMODE" = "UEFI" ]; then
    # Create GPT partition table
    "$PARTED" -s "$drive" mklabel gpt || \
      die "Failed to create GPT partition table."

    if [ "$need_boot_partition" = true ]; then
      # Fedora: ESP + /boot + root
      "$PARTED" -s "$drive" mkpart primary fat32 1MiB 601MiB || \
        die "Failed to create EFI partition."
      "$PARTED" -s "$drive" set 1 esp on || \
        die "Failed to set ESP flag."
      "$PARTED" -s "$drive" mkpart primary ext4 601MiB 1625MiB || \
        die "Failed to create boot partition."
      "$PARTED" -s "$drive" mkpart primary btrfs 1625MiB 100% || \
        die "Failed to create root partition."
    else
      # Other distros: ESP + root
      "$PARTED" -s "$drive" mkpart primary fat32 1MiB 1050MiB || \
        die "Failed to create EFI partition."
      "$PARTED" -s "$drive" set 1 esp on || \
        die "Failed to set ESP flag."
      "$PARTED" -s "$drive" mkpart primary btrfs 1050MiB 100% || \
        die "Failed to create root partition."
    fi
  else
    # Create MBR partition table for BIOS
    "$PARTED" -s "$drive" mklabel msdos || \
      die "Failed to create MBR partition table."

    if [ "$need_boot_partition" = true ]; then
      # Fedora BIOS: /boot + root
      "$PARTED" -s "$drive" mkpart primary ext4 1MiB 1025MiB || \
        die "Failed to create boot partition."
      "$PARTED" -s "$drive" set 1 boot on || \
        die "Failed to set boot flag."
      "$PARTED" -s "$drive" mkpart primary btrfs 1025MiB 100% || \
        die "Failed to create root partition."
    else
      # Other distros BIOS: root only
      "$PARTED" -s "$drive" mkpart primary btrfs 1MiB 100% || \
        die "Failed to create root partition."
      "$PARTED" -s "$drive" set 1 boot on || \
        die "Failed to set boot flag."
    fi
  fi
}

partition_suffix() {
  local distro="${1:-}"
  # Determine correct partition suffix
  local suffix=""
  [[ "$drive" == *"nvme"* || "$drive" == *"mmcblk"* ]] && suffix="p"

  # Determine if we need separate /boot (Fedora requirement)
  local need_boot_partition=false
  [ "$distro" = "fedora" ] && need_boot_partition=true

  if [ "$BOOTMODE" = "UEFI" ]; then
    if [ "$need_boot_partition" = true ]; then
      # Fedora: ESP + /boot + root
      EFI="${drive}${suffix}1"
      BOOT="${drive}${suffix}2"
      ROOT="${drive}${suffix}3"
    else
      # Other distros: ESP + root
      EFI="${drive}${suffix}1"
      ROOT="${drive}${suffix}2"
      BOOT=""  # No separate boot partition
    fi
  else
    if [ "$need_boot_partition" = true ]; then
      # Fedora BIOS: /boot + root
      BOOT="${drive}${suffix}1"
      ROOT="${drive}${suffix}2"
      EFI=""  # No EFI partition
    else
      # Other distros BIOS: root only
      ROOT="${drive}${suffix}1"
      BOOT=""  # No separate boot partition
      EFI=""   # No EFI partition
    fi
  fi
}

format_partitions() {
  # Format the partitions
  if [ "$BOOTMODE" = "UEFI" ] && [ -n "$EFI" ]; then
    mkfs.fat -F32 "$EFI" || \
    die "Failed to format EFI partition."
  fi
  if [ -n "$BOOT" ]; then
    mkfs.ext4 -F "$BOOT" || \
    die "Failed to format boot partition."
  fi
  mkfs.btrfs -f "$ROOT" || \
    die "Failed to format root partition."
}

create_btrfs_subvolumes() {
  # Create BTRFS subvolumes
  mount -t btrfs "$ROOT" /mnt || \
    die "Failed to mount root partition."
  btrfs su cr /mnt/@ || \
    die "Failed to create subvolume @."
  btrfs su cr /mnt/@home || \
    die "Failed to create subvolume @home."
  btrfs su cr /mnt/@.snapshots || \
    die "Failed to create subvolume @.snapshots."
  umount /mnt || die "Failed to unmount root partition."
}

mount_partitions() {
  # Mount the partitions
  local distro="${1:-}"
  local MNT="/mnt"
  [ "$distro" = "gentoo" ] && MNT="/mnt/gentoo"

  mkdir -p "$MNT" || \
    die "Failed to create $MNT."
  mount -t btrfs -o noatime,compress=zstd,discard=async,subvol=@ \
    "$ROOT" "$MNT" || \
    die "Failed to mount root subvolume."

  # Create and mount home
  mkdir -p "$MNT/home" || \
    die "Failed to create $MNT/home."
  mount -t btrfs -o noatime,compress=zstd,discard=async,subvol=@home \
    "$ROOT" "$MNT/home" || \
    die "Failed to mount home subvolume."

  # Mount snapshots subvolume (universal)
  mkdir -p "$MNT/.snapshots" || \
    die "Failed to create $MNT/.snapshots."
  mount -t btrfs -o noatime,compress=zstd,discard=async,subvol=@.snapshots \
    "$ROOT" "$MNT/.snapshots" || \
    die "Failed to mount snapshots subvolume."

  # Handle boot partition mounting
  if [ -n "$BOOT" ]; then
    # Separate /boot partition (Fedora)
    mkdir -p "$MNT/boot" || \
      die "Failed to create $MNT/boot."
    mount "$BOOT" "$MNT/boot" || \
      die "Failed to mount boot partition."

    # Mount EFI inside /boot for Fedora
    if [ "$BOOTMODE" = "UEFI" ] && [ -n "$EFI" ]; then
      mkdir -p "$MNT/boot/efi" || \
        die "Failed to create $MNT/boot/efi."
      mount "$EFI" "$MNT/boot/efi" || \
        die "Failed to mount EFI partition."
    fi
  elif [ "$BOOTMODE" = "UEFI" ] && [ -n "$EFI" ]; then
    # Direct EFI mounting for other distros
    if [ "$distro" = "nixos" ]; then
      mkdir -p "$MNT/boot" || \
        die "Failed to create $MNT/boot."
      mount "$EFI" "$MNT/boot" || \
        die "Failed to mount EFI partition to /boot."
    else
      mkdir -p "$MNT/boot/efi" || \
        die "Failed to create $MNT/boot/efi."
      mount "$EFI" "$MNT/boot/efi" || \
        die "Failed to mount EFI partition to /boot/efi."
    fi
  fi
}

# Only Fedora/Gentoo/openSUSE/Slackware uses this
mount_system_partitions() {
  local distro="${1:-}"
  # Mount System Partitions
  local MNT="/mnt"
  [ "$distro" = "gentoo" ] && MNT="/mnt/gentoo"

  mkdir -p "$MNT"/{proc,sys,dev,run} || \
    die "Failed to create system mount points."
  mount --types proc /proc "$MNT/proc" || \
    die "Failed to mount /proc."
  mount --rbind /sys "$MNT/sys" || \
    die "Failed to bind-mount /sys."
  mount --make-rslave "$MNT/sys" || \
    die "Failed to make /sys rslave."
  mount --rbind /dev "$MNT/dev" || \
    die "Failed to bind-mount /dev."
  mount --make-rslave "$MNT/dev" || \
    die "Failed to make /dev rslave."
  mount --bind /run "$MNT/run" || \
    die "Failed to bind-mount /run."
  mount --make-slave "$MNT/run" || \
    die "Failed to make /run slave."
}

# Only Gentoo uses this
prompt_init_system() {
  # Prompt for init system
  while true; do
    echo "Select your init system:"
    echo
    echo "1) OpenRC"
    echo "2) systemd"
    echo
    read -rp "Enter the number corresponding to your init system: " \
      init_system_number

    case $init_system_number in
      1) init_system="openrc"; break ;;
      2) init_system="systemd"; break ;;
      *) echo "Invalid selection, please try again." ;;
    esac
  done
  export init_system
}

# NixOS doesn't use this
configure_zram() {
  local distro="${1:-}"

  # Determine sysctl destination
  if [ "$distro" = "void" ]; then
    SYSCTL_FILE="/etc/sysctl.conf"
  else
    SYSCTL_FILE="/etc/sysctl.d/99-zram.conf"
    # Create the directory if it doesn't exist
    if [ ! -d "$(dirname "$SYSCTL_FILE")" ]; then
      mkdir -p "$(dirname "$SYSCTL_FILE")" || \
        die "Failed to create $(dirname "$SYSCTL_FILE") directory."
    fi
  fi

  # Apply sysctl tuning
  {
    cat << 'SYSCTL'
# zRAM optimization
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
vm.swappiness = 180
SYSCTL
  } > "$SYSCTL_FILE" || die "Failed to write sysctl tuning."

  if [ "$distro" = "slackware" ]; then
    # Backup existing zram config
    if [ -f /etc/default/zram ]; then
      cp /etc/default/zram "/etc/default/zram.orig" || \
        die "Failed to backup zram config."
    fi

    # Slackware zram config
    {
      cat << 'ZRAM'
ZRAM_ENABLE=1
MEM_TOTAL_MB=$(awk '/^MemTotal:/ { printf "%.0f", $2/1024 }' /proc/meminfo)
ZRAM_HALF_MB=$(( MEM_TOTAL_MB / 2 ))
[ $ZRAM_HALF_MB -gt 8192 ] && ZRAM_HALF_MB=8192
MEMTOTAL=$(( ZRAM_HALF_MB * 1024 ))
ZRAMSIZE=$MEMTOTAL
ZRAMNUMBER=1
ZRAMCOMPRESSION=zstd
ZRAMPRIORITY=100
ZRAM
    } > /etc/default/zram || die "Failed to write zram config."

  elif [ "$distro" = "void" ]; then
    # Calculate static values for Void zramen
    MEM_TOTAL_MB=$(awk '/^MemTotal:/ { printf "%.0f", $2/1024 }' \
      /proc/meminfo)
    ZRAM_HALF_MB=$(( MEM_TOTAL_MB / 2 ))
    [ $ZRAM_HALF_MB -gt 8192 ] && ZRAM_HALF_MB=8192

    # Backup existing zramen config
    if [ -f /etc/sv/zramen/conf ]; then
      cp /etc/sv/zramen/conf "/etc/sv/zramen/conf.orig" || \
        die "Failed to backup zramen config."
    fi

    # Void zramen config (zramen doesn't support dynamic calculation)
    {
      cat << ZRAMEN
export ZRAM_COMP_ALGORITHM=zstd
export ZRAM_PRIORITY=100
export ZRAM_SIZE=$ZRAM_HALF_MB
export ZRAM_MAX_SIZE=$ZRAM_HALF_MB
export ZRAM_STREAMS=1
export ZRAMEN_QUIET=1
ZRAMEN
    } > /etc/sv/zramen/conf || die "Failed to write zramen config."

  # Gentoo OpenRC configs
  elif [ "$distro" = "gentoo" ]; then
    # Create /etc/local.d/zram.start
    {
      cat << 'ZRAMSTART'
#!/bin/bash
modprobe zram
MEM_TOTAL_MB=$(awk '/^MemTotal:/ { printf "%.0f", $2/1024 }' /proc/meminfo)
ZRAM_HALF_MB=$(( MEM_TOTAL_MB / 2 ))
[ $ZRAM_HALF_MB -gt 8192 ] && ZRAM_HALF_MB=8192
echo ${ZRAM_HALF_MB}M > /sys/block/zram0/disksize
mkswap /dev/zram0
swapon /dev/zram0 -p 100
ZRAMSTART
    } > /etc/local.d/zram.start || die "Failed to write zram start script."

    # Create /etc/local.d/zram.stop
    {
      cat << 'ZRAMSTOP'
#!/bin/bash
swapoff /dev/zram0
echo 1 > /sys/block/zram0/reset
modprobe -r zram
ZRAMSTOP
    } > /etc/local.d/zram.stop || die "Failed to write zram stop script."

    # Make scripts executable
    chmod +x /etc/local.d/zram.start /etc/local.d/zram.stop || \
      die "Failed to make zram scripts executable."

  else
    # systemd zram-generator config
    {
      cat << 'ZRAM'
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = zstd
ZRAM
    } > /etc/systemd/zram-generator.conf || \
      die "Failed to write zram-generator config."

    # Ensure zswap.enabled=0 in GRUB_CMDLINE_LINUX
    GRUB_FILE="/etc/default/grub"
    PARAM="zswap.enabled=0"

    # Check if GRUB_CMDLINE_LINUX exists (commented or uncommented)
    if grep -q '^\s*#*\s*GRUB_CMDLINE_LINUX=' "$GRUB_FILE" 2>/dev/null; then
      # Remove any existing zswap.enabled parameter
      sed -i -E \
        's/^(\s*#*\s*GRUB_CMDLINE_LINUX="[^"]*)\s*zswap\.enabled=[^" ]*\s*([^"]*)"/\1 \2"/' \
        "$GRUB_FILE" || \
        die "Failed to remove existing zswap.enabled from GRUB."

      # Uncomment the line if it's commented
      sed -i 's/^\s*#\s*\(GRUB_CMDLINE_LINUX=\)/\1/' "$GRUB_FILE" || \
        die "Failed to uncomment GRUB_CMDLINE_LINUX."

      # Add the new parameter
      sed -i -E "s/^(GRUB_CMDLINE_LINUX=\"[^\"]*)\"/\1 $PARAM\"/" \
        "$GRUB_FILE" || \
        die "Failed to add zswap.enabled=0 to GRUB."
    else
      # No GRUB_CMDLINE_LINUX line exists, create it
      echo "GRUB_CMDLINE_LINUX=\"$PARAM\"" >> "$GRUB_FILE" || \
        die "Failed to write GRUB_CMDLINE_LINUX."
    fi
  fi
}

# Fedora/NixOS doesn't use this
install_grub() {
  # Configure GRUB Bootloader
  local distro="${1:-}"
  local cmd="grub-install"
  # Use grub2-install for openSUSE and Fedora
  [ "$distro" = "opensuse" ] && cmd="grub2-install"
  [ "$distro" = "fedora" ] && cmd="grub2-install"
  if [ "$BOOTMODE" = "UEFI" ]; then
    # Install GRUB for UEFI
    if [ "$REMOVABLE_BOOT" = "1" ]; then
      "$cmd" --target=x86_64-efi --efi-directory=/boot/efi \
        --bootloader-id="$distro" --removable || \
        die "Failed to install GRUB (UEFI removable)."
    else
      "$cmd" --target=x86_64-efi --efi-directory=/boot/efi \
        --bootloader-id="$distro" || \
        die "Failed to install GRUB (UEFI)."
    fi
  else
    # Install GRUB for BIOS
    "$cmd" --target=i386-pc --boot-directory=/boot "$drive" || \
      die "Failed to install GRUB (BIOS)."
  fi
}

# NixOS doesn't use this
set_grub_gfxmode() {
  local gfx="1920x1200,1920x1080,auto"
  # Set GRUB_GFXMODE
  if grep -q "^GRUB_GFXMODE=$gfx" /etc/default/grub; then
    # Already set correctly - skip
    :
  elif grep -q '^GRUB_GFXMODE=' /etc/default/grub; then
    # Uncommented line exists - comment it out and add new one below
    sed -i "/^GRUB_GFXMODE=/{ s/^/# /; a\\GRUB_GFXMODE=$gfx
  }" /etc/default/grub || die "Failed to set GRUB_GFXMODE."
  elif grep -q "^#GRUB_GFXMODE=$gfx" /etc/default/grub; then
    # Commented line with correct value exists - uncomment it
    sed -i "s/^#GRUB_GFXMODE=$gfx/GRUB_GFXMODE=$gfx/" \
      /etc/default/grub
  elif grep -q '^#GRUB_GFXMODE=' /etc/default/grub; then
    # Commented line exists - add new line below
    sed -i "/^#GRUB_GFXMODE=/a\\GRUB_GFXMODE=$gfx" \
      /etc/default/grub || die "Failed to set GRUB_GFXMODE."
  else
    # No line exists - add it
    echo "GRUB_GFXMODE=$gfx" >> /etc/default/grub || \
      die "Failed to add GRUB_GFXMODE."
  fi
}

clone_dotfiles() {
  # Clone cinnamon-dotfiles repo as new user
  local distro="${1:-}"

  if [ "$distro" = "nixos" ]; then
    # NixOS uses nixos-enter and creates multiple flag files
    nixos-enter --root /mnt -c "su - $username -c '
      cd \$HOME &&
      git clone https://github.com/SpreadiesInSpace/cinnamon-dotfiles ||
        { echo \"Failed to clone repo.\"; exit 1; }
      cd cinnamon-dotfiles ||
        { echo \"Failed to enter repo directory.\"; exit 1; }
      touch .nixos-25.11.done .$distro.done home/.rebuild ||
        { echo \"Failed to create flags.\"; exit 1; }
      if [ \"$is_vm\" = true ]; then
        touch home/.vm || { echo \"Failed to create VM flag.\"; exit 1; }
      fi
      echo \"Reboot and run Theme.sh in cinnamon-dotfiles located in \
\$HOME/cinnamon-dotfiles.\"'"
  else
    cat << CLONE | su - "$username"
cd && git clone https://github.com/SpreadiesInSpace/cinnamon-dotfiles || \
  die "Failed to clone repo."
cd cinnamon-dotfiles || die "Failed to enter repo directory."
touch .$distro.done || die "Failed to create flag."
echo "Reboot and run Setup.sh in cinnamon-dotfiles located in \
\$HOME/cinnamon-dotfiles."
CLONE
  fi
}

setup_grub_theme() {
  # Setup GRUB theme
  local distro="${1:-}"
  local dir="/mnt/home/$username/cinnamon-dotfiles"
  dir="$dir/boot/grub/themes/gruvbox-dark/"
  if [ "$distro" = "NixOS" ]; then
    if [ ! -d "$dir" ]; then
      die "GRUB theme source not found in cinnamon-dotfiles"
    fi

    mkdir -p /mnt/boot/grub/themes || \
      die "Failed to create GRUB themes directory."
    cp -rf "$dir" \
      /mnt/boot/grub/themes/ || \
      die "Failed to copy Gruvbox GRUB theme."

    # Modify the NixOS configuration to enable the theme
    local config_file="/mnt/etc/nixos/configuration.nix"
    sed -i '/^\s*grub = {/,/^\s*};/ {
      s/^\(\s*\)#\s*theme = /\1theme = /
      s/^\(\s*\)#\s*splashImage = /\1splashImage = /
    }' "$config_file" || \
      die "Failed to uncomment grub theme lines in configuration.nix"

  else
    cd "/home/$username/cinnamon-dotfiles/extra/grub-theme-setup/" ||
      die "Failed to enter GRUB theme directory."
    bash "$distro.sh" >/dev/null 2>&1 || die "Failed to setup GRUB theme."
  fi
}

# Only Void uses this
set_monospace_font() {
  # Create first-boot script to set monospace font for gnome-terminal
  su - "$username" -c "
  mkdir -p ~/.config/autostart
  cat > ~/.config/autostart/set-font.desktop << 'MONOSPACE'
[Desktop Entry]
Type=Application
Name=Set Monospace Font
Exec=sh -c 'gsettings set org.gnome.desktop.interface monospace-font-name \"DejaVu Sans Mono 11\" && rm ~/.config/autostart/set-font.desktop'
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
MONOSPACE
  " || die "Failed to create font setup script."
}