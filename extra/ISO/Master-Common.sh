#!/bin/bash

check_bash_requirement() {
  if [ -z "$BASH_VERSION" ]; then
    echo "Error: This script requires Bash for proper functionality" >&2

    # Check if sourced
    if [[ "${BASH_SOURCE[0]}" != "${0}" ]] 2>/dev/null; then
      return 1
    else
      echo "Please run with: bash $0" >&2
      exit 1
    fi
  fi
}

# Only proceed if Bash check passes
check_bash_requirement || return 1 2>/dev/null || exit 1

die() {
  # Handle exits on error
  printf "\033[1;31mError:\033[0m %s\n" "$*" >&2
  exit 1
}

check_if_root() {
  # Check if the script is run as root
  if [ "$EUID" -ne 0 ]; then
    die "Please run the script as superuser."
  fi
}

check_if_not_root_account() {
  # Check if the script is run from the root account
  if [ "$SUDO_USER" = "" ]; then
    die "Please do not run this script as root. Use sudo instead."
  fi
}

check_not_root() {
  # Prevents script from being run as root
  if [ "$EUID" -eq 0 ]; then
    die "This script must NOT be run as root. Please run it as a regular user."
  fi
}

retry() {
  local max_attempts=5
  local attempt=1
  local delay=1

  while [ $attempt -le $max_attempts ]; do
    if "$@"; then
      return 0
    fi

    if [ $attempt -eq $max_attempts ]; then
      return 1
    fi

    echo "Retrying in ${delay}s..."
    sleep $delay
    delay=$((delay + 2))
    attempt=$((attempt + 1))
  done
}

# TODO: Use this for Install and Setup(?) scripts
get_distro() {
  local distro=""
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
      arch) distro="arch" ;;
      fedora) distro="fedora" ;;
      gentoo) distro="gentoo" ;;
      linuxmint) distro="lmde" ;;
      nixos) distro="nixos" ;;
      opensuse*) distro="opensuse" ;;
      slackware) distro="slackware" ;;
      void) distro="void" ;;
    esac
  fi
  echo "Detected OS: $distro"
}

prompt_hostname() {
  # Prompt for hostname
  while true; do
    read -rp "Enter hostname: " hostname
    # Trim leading and trailing whitespace
    hostname="${hostname#"${hostname%%[![:space:]]*}"}"  # leading
    hostname="${hostname%"${hostname##*[![:space:]]}"}"  # trailing
    if [[ -z "$hostname" ]]; then
      echo "Hostname cannot be empty."
    elif [[ "$hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$ ]]; then
      break
    else
      echo "Invalid hostname. Must start/end with a letter or number and may \
include"
      echo "internal hyphens."
    fi
  done
}

prompt_timezone() {
  # Prompt for timezone
  local zoneinfo_dir="/usr/share/zoneinfo"
  local tz_wiki="https://en.wikipedia.org/wiki/List_of_tz_database_time_zones"

  if [ ! -d "$zoneinfo_dir" ]; then
    if [ -d "/etc/zoneinfo" ]; then
      zoneinfo_dir="/etc/zoneinfo"
    else
      echo "No timezone database found. Skipping timezone prompt."
      return
    fi
  fi

  while true; do
    echo; echo "For a complete list of valid timezone identifiers, see:"
    echo "$tz_wiki"; echo
    read -rp "Enter your timezone (e.g., Asia/Bangkok): " timezone
    timezone="${timezone:-Asia/Bangkok}"  # default if empty
    if [ -f "$zoneinfo_dir/$timezone" ]; then
      echo "Timezone set to: $timezone"; echo
      break
    fi
    echo "Invalid timezone: $timezone"
  done
}

# Only Install-Gentoo.sh uses this
prompt_video_card() {
  local link="https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation"
  link="$link/Base#VIDEO_CARDS"
  # Detect hardware info
  if command -v lspci &> /dev/null; then
    gpu_info=$(lspci | grep -i VGA)
  fi

  # Prompt for video card
  while true; do
    # Show detected hardware info if available
    if [[ -n "$gpu_info" ]]; then
      echo "Detected graphics hardware:"
      echo "$gpu_info"
      echo
    fi
    echo "Select your video card:"
    echo
    echo "1) Intel (intel) - Intel graphics (integrated and Arc GPUs)"
    echo "2) AMD (amdgpu radeonsi) - AMD since Sea Islands"
    echo "3) NVIDIA (nvidia) - NVIDIA cards with proprietary drivers"
    echo "4) Nouveau (nouveau) - NVIDIA cards with open source drivers"
    echo "5) VirtIO-GPU (virgl) - Virtual machines (QEMU/KVM)"
    echo "6) VideoCore IV (vc4) - Raspberry Pi (legacy)"
    echo "7) D3D12 (d3d12) - Windows Subsystem for Linux"
    echo "8) Other/Manual entry"
    echo
    echo "See $link"
    echo "for more details."
    echo
    read -rp "Enter the number corresponding to your video card: " \
      video_card_number

    case $video_card_number in
      1) video_card="intel"; break ;;
      2) video_card="amdgpu radeonsi"; break ;;
      3) video_card="nvidia"; break ;;
      4) video_card="nouveau"; break ;;
      5) video_card="virgl"; break ;;
      6) video_card="vc4"; break ;;
      7) video_card="d3d12"; break ;;
      8) read -rp "Enter the video card type: " video_card; break ;;
      *) echo; echo "Invalid selection, please try again." ;;
    esac
  done
  echo "Video card selection: $video_card"
}

# Only Install-Gentoo.sh uses this
write_video_card() {
  # Set VIDEO_CARDS value in package.use
  local prefix="${1:-}"
  local base_path="/etc/portage/package.use/00-video-cards"
  local target_path

  # "mnt" for Install-Gentoo.sh, empty for Setup-Gentoo.sh
  if [ "$prefix" = "mnt" ]; then
    target_path="/mnt$base_path"
  else
    target_path="$base_path"
  fi

  # Ensure video_card variable is set
  if [ -z "$video_card" ]; then
    die "Video card not selected. Call prompt_video_card() first."
  fi

  # Create directory if it doesn't exist
  mkdir -p "$(dirname "$target_path")" || \
    die "Failed to create directory for $target_path."

  echo "*/* VIDEO_CARDS: $video_card" > "$target_path" || \
    die "Failed to update VIDEO_CARDS in $target_path."
  echo "Updated VIDEO_CARDS in $target_path to $video_card"
}

# Only Setup-Gentoo.sh uses this
set_video_card() {
  # Set VIDEO_CARDS value in package.use
  prompt_video_card
  write_video_card "default"
}

# Only Gentoo uses this
configure_make_conf() {
  # Pull make.conf with use flags, jobs, licenses, mirrors, etc already set
  local target_path="$1"
  local backup_suffix="${2:-stage3}"
  local fetch_remote="${3:-true}"

  # Validate target path
  [ -z "$target_path" ] && \
    die "Target path not specified for make.conf configuration."
  [ ! -f "$target_path" ] && die "make.conf not found at $target_path."

  # Backup original if it doesn't already exist
  if [ ! -f "$target_path.$backup_suffix" ]; then
    cp "$target_path" "$target_path.$backup_suffix" || \
      die "Failed to back up $target_path."
  fi

  # Download custom make.conf if requested (Install phase)
  if [ "$fetch_remote" = "true" ]; then
    local url="https://raw.githubusercontent.com/spreadiesinspace"
    url="$url/cinnamon-dotfiles/main/etc/portage/make.conf"

    curl -fsSL "$url" -o "$target_path" || {
      echo "Failed to fetch remote make.conf, restoring backup."
      cp "$target_path.$backup_suffix" "$target_path"
      die "Failed to fetch $url."
    }
    echo "make.conf updated successfully from remote source."
  elif [ -f "etc/portage/make.conf" ]; then
    # Use local copy (Setup phase)
    cp "etc/portage/make.conf" "$target_path" || \
      die "Failed to copy local make.conf to $target_path."
    echo "make.conf updated successfully from local source."
  fi

  # Configure CPU-specific settings
  local cores
  cores=$(nproc) || die "Failed to retrieve number of CPU cores."

  # Set MAKEOPTS (load limit = cores + 1)
  local makeopts_limit=$((cores + 1))
  sed -i "s/^MAKEOPTS=.*/MAKEOPTS=\"-j$cores -l$makeopts_limit\"/" \
    "$target_path" || die "Failed to update MAKEOPTS in make.conf."
  echo "Set MAKEOPTS to -j$cores -l$makeopts_limit"

  # Set EMERGE_DEFAULT_OPTS (load limit as 90% of cores)
  local limit
  limit=$(awk "BEGIN {printf \"%.1f\", $cores * 0.9}") || \
    die "Failed to calculate emerge load limit."
  sed -i \
    "s/^EMERGE_DEFAULT_OPTS=.*/EMERGE_DEFAULT_OPTS=\"-j$cores -l$limit\"/" \
    "$target_path" || die "Failed to update EMERGE_DEFAULT_OPTS in make.conf."
  echo "Set EMERGE_DEFAULT_OPTS to -j$cores -l$limit"

  # Check available RAM and disable parallel emerges if insufficient
  local ram_gb
  ram_gb=$(free -g | awk '/^Mem:/ {print $2}') || \
    die "Failed to check available RAM."

  if [ "$ram_gb" -lt 16 ]; then
    sed -i 's/^EMERGE_DEFAULT_OPTS=/#EMERGE_DEFAULT_OPTS=/' "$target_path" || \
      die "Failed to comment out EMERGE_DEFAULT_OPTS."
    echo "RAM Available: $ram_gb GB"
    echo "RAM < 16 GB, Disabling parallel emerges..."
    echo "To enable parallel emerges later, uncomment the \
EMERGE_DEFAULT_OPTS line in make.conf"
  fi
}

# Only Gentoo uses this
is_makeconf_configured() {
  # Check if custom make.conf and VIDEO_CARDS have already been set previously
  local flag_file="/etc/portage/.makeconf_configured"
  [ -f "$flag_file" ]
}

# Only Gentoo uses this
mark_makeconf_configured() {
  # Signal that make.conf was configured during install phase
  local prefix="${1:-}"
  local flag_file="/etc/portage/.makeconf_configured"

  # Handle "mnt" prefix for Install-Gentoo.sh
  [ "$prefix" = "mnt" ] && flag_file="/mnt$flag_file"

  touch "$flag_file" || die "Failed to create $flag_file flag."
}

# Only Gentoo uses this
enable_pipewire() {
  # Enable Pipewire
  echo "media-video/pipewire echo-cancel flatpak sound-server" | \
    tee /etc/portage/package.use/pipewire || \
    die "Failed to set USE flags for pipewire."
  echo "media-sound/pulseaudio -daemon" | \
    tee /etc/portage/package.use/pulseaudio || \
    die "Failed to set USE flags for pulseaudio."
}

# Only NixOS uses this
setup_nixos_config() {
  local config_path="$1"
  local source_type="$2"  # "remote" or "local"
  local source_path="$3"  # URL or local path

  # Validate parameters
  [ -z "$config_path" ] && die "Config path not specified."
  [ -z "$source_type" ] && die "Source type not specified."
  [ -z "$source_path" ] && die "Source path not specified."

  # Backup existing configuration
  local timestamp
  timestamp=$(date +%s)
  cp "$config_path" "$config_path.old.${timestamp}" || \
    die "Failed to back up configuration.nix"

  # Get the new configuration
  if [ "$source_type" = "remote" ]; then
    curl -fsSL -o configuration.nix "$source_path" || \
      die "Failed to download custom configuration.nix"
    cp configuration.nix "$config_path" || \
      die "Failed to copy configuration.nix"
  elif [ "$source_type" = "local" ]; then
    cp "$source_path" "$config_path" || \
      die "Failed to copy configuration.nix"
  else
    die "Invalid source type: $source_type"
  fi
}

# Only NixOS uses this
configure_nixos_settings() {
  local config_path="$1"
  local username="$2"
  local hostname="$3"
  local timezone="$4"
  local enable_autologin="$5"
  local drive="${6:-}"  # Optional, only for BIOS installs

  # Replace username placeholder
  sed -i "s/f16poom/$username/g" "$config_path" || \
    die "Failed to replace username in configuration.nix"

  # Set hostname
  sed -i "s/hostName = .*;/hostName = \"$hostname\";/g" "$config_path" || \
    die "Failed to update hostname in configuration.nix"

  # Set timezone
  sed -i "s|^\(\s*time\.timeZone\s*=\s*\).*|\\1\"$timezone\";|" \
    "$config_path" || die "Failed to set timezone."

  # Configure autologin
  if [ "$enable_autologin" = false ]; then
    sed -i '/autoLogin.*{/,/}/ {
      s/enable *= *true/enable = false/
    }' "$config_path" || die "Failed to modify autologin setting."
  fi

  # Handle BIOS mode configuration
  if [ ! -d /sys/firmware/efi ]; then
    # Comment out efiSupport inside grub block
    sed -i '/^\s*grub = {/,/^\s*};/ {
      s/^\(\s*\)efiSupport = /\1# efiSupport = /
    }' "$config_path" || \
      die "Failed to comment out efiSupport in grub block."

    # Comment out efi.canTouchEfiVariables
    sed -i \
      's/^\(\s*\)efi\.canTouchEfiVariables = /\1# efi.canTouchEfiVariables = /' \
      "$config_path" || \
      die "Failed to comment out efi.canTouchEfiVariables."

    # Set GRUB device for BIOS (install phase only)
    if [ -n "$drive" ]; then
      sed -i "s|^\(\s*device\s*=\s*\).*|\\1\"$drive\";|" "$config_path" || \
        die "Failed to set GRUB bootloader device."
    fi
  fi
}

# Only NixOS uses this
setup_login_wallpaper() {
  # Setup login wallpaper for NixOS
  local config_path="$1"
  local mount_prefix="${2:-}"  # "/mnt" for install, "" for setup

  local wallpaper_url="https://raw.githubusercontent.com/SpreadiesInSpace"
  wallpaper_url="$wallpaper_url/wallpapers/main/Login_Wallpaper.jpg"

  local boot_path="${mount_prefix}/boot"
  local wallpaper_file="Login_Wallpaper.jpg"

  echo "Setting up login wallpaper..."

  # Download wallpaper
  curl -fsSL -o "$wallpaper_file" "$wallpaper_url" || \
    die "Failed to download wallpaper."

  # Copy to boot directory
  cp -nr "$wallpaper_file" "$boot_path/" || \
    die "Failed to copy login wallpaper to $boot_path."

  # Enable background in configuration.nix
  sed -i 's|^\(\s*\)#\s*\(background\s*=.*\)|\1\2|' "$config_path" || \
    die "Failed to enable background in configuration."

  echo "Login wallpaper configured successfully."
}

# Only openSUSE uses this
cinnamon_env_fix() {
  # Comment out Cinnamon desktop environment setting (temp fix)
  local file="/usr/share/cinnamon/js/ui/main.js"

  [ -f "$file" ] || die "$file not found."

  if ! sed -n '315p' "$file" | grep -q "^[[:space:]]*//"; then
    sudo sed -i '315s/^/\/\/ /' "$file" || \
      die "Failed to comment out Cinnamon desktop env setting."
  fi
}