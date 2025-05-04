#!/bin/bash

# Handle exits on error
die() {
    printf "\033[1;31mError:\033[0m %s\n" "$*" >&2
    read -rp "Press Enter to exit..."
    exit 1
}

# Check if the script is run as root
[[ $EUID -ne 0 ]] && die "Please run the script as superuser."

# Detect distro and init system
[ -f /etc/os-release ] || die "/etc/os-release not found"
. /etc/os-release
distro="$ID"
init_sys=$(ps -p 1 -o comm=)

# Determine memory size
ram_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo) || die "Failed to read memory"
ram_mb=$((ram_kb / 1024))
zram_size_kb=0

prompt_for_hibernation() {
    while true; do
        read -rp "Will this system support hibernation? [y/N]: " hibernate_input
        if [[ "$hibernate_input" =~ ^([yY][eE][sS]?|[yY])$ ]]; then
            hibernation=true
            break
        elif [[ "$hibernate_input" =~ ^([nN][oO]?)$ ]]; then
            hibernation=false
            break
        else
            echo "Invalid input. Please answer y or n."
        fi
    done
}


prompt_for_hibernation

# Calculate ZRAM size based on Gentoo Wiki guidance
if [ "$ram_mb" -le 2048 ]; then
    if \$hibernation; then
        zram_size_kb=$((ram_kb * 3))
    else
        zram_size_kb=$((ram_kb * 2))
    fi
elif [ "$ram_mb" -le 8192 ]; then
    if \$hibernation; then
        zram_size_kb=$((ram_kb * 2))
    else
        zram_size_kb=$((ram_kb))
    fi
elif [ "$ram_mb" -le 65536 ]; then
    if \$hibernation; then
        zram_size_kb=$((ram_kb * 3 / 2))
    else
        zram_size_kb=$((8 * 1024 * 1024))  # 8 GB in KB
    fi
else
    if \$hibernation; then
        echo "Warning: Hibernation is not recommended for RAM > 64GB"
        zram_size_kb=$((8 * 1024 * 1024))
    else
        zram_size_kb=$((8 * 1024 * 1024))
    fi
fi

#===================== Init-based setup functions ======================

setup_systemd() {
    echo "[zram0]
zram-size = ${zram_size_kb}K
compression-algorithm = zstd
swap-priority = 100" > /etc/systemd/zram-generator.conf || die "Failed to write config"

    systemctl daemon-reexec || die "Failed to reexec systemd"
    systemctl restart systemd-zram-setup@zram0 || die "Failed to restart zram"
    echo "ZRAM configured using systemd-zram-generator"
}

setup_openrc() {
    cat << 'EOF' > /etc/init.d/zram || die "Failed to write OpenRC init script"
#!/sbin/openrc-run
description="ZRAM compressed swap device"
depend() { need localmount; }
start() {
  modprobe zram
  echo 1 > /sys/block/zram0/max_comp_streams
  echo $(( $(awk '/MemTotal/ {print $2}' /proc/meminfo) * 512 )) > /sys/block/zram0/disksize
  mkswap /dev/zram0
  swapon -p 100 /dev/zram0
}
stop() {
  swapoff /dev/zram0
  modprobe -r zram
}
EOF
    chmod +x /etc/init.d/zram || die "Failed to chmod"
    rc-update add zram default || die "Failed to add service"
    /etc/init.d/zram start || die "Failed to start zram"
    echo "ZRAM configured via OpenRC service"
}

setup_runit() {
    mkdir -p /etc/sv/zram || die "Failed to create runit dir"
    cat << EOF > /etc/sv/zram/run || die "Failed to write runit service"
#!/bin/sh
modprobe zram
echo 1 > /sys/block/zram0/max_comp_streams
echo $(( $zram_size_kb )) > /sys/block/zram0/disksize
mkswap /dev/zram0
swapon -p 100 /dev/zram0
exec sleep infinity
EOF
    chmod +x /etc/sv/zram/run || die "Failed to chmod"
    ln -sf /etc/sv/zram /var/service/ || die "Failed to link runit service"
    echo "ZRAM configured via runit service"
}

setup_sysv() {
    rc_local="/etc/rc.d/rc.local"
    grep -q zram "$rc_local" 2>/dev/null || cat << EOF >> "$rc_local" || die "Failed to write rc.local"
modprobe zram
echo 1 > /sys/block/zram0/max_comp_streams
echo $(( $zram_size_kb )) > /sys/block/zram0/disksize
mkswap /dev/zram0
swapon -p 100 /dev/zram0
EOF
    chmod +x "$rc_local" || die "Failed to chmod rc.local"
    echo "ZRAM setup appended to rc.local"
}

setup_nixos() {
    echo "ZRAM must be declared in Nix config:
boot.initrd.zram.enable = true;
Then run: nixos-rebuild switch"
}

#======================== Package Installation #========================

install_zram_generator() {
    if [ "$distro" = "arch" ]; then
        pacman -Sy --noconfirm systemd-zram-generator || die "Failed to install zram generator"
    elif [ "$distro" = "fedora" ]; then
        dnf install -y systemd-zram-generator || die "Failed to install zram generator"
    elif [ "$distro" = "gentoo" ]; then
        emerge -av sys-apps/systemd-zram-generator || die "Failed to emerge zram generator"
    elif [ "$distro" = "void" ]; then
        xbps-install -Sy systemd-zram-generator || die "Failed to install zram generator"
    elif [ "$distro" = "opensuse" ]; then
        zypper install -y systemd-zram-generator || die "Failed to install zram generator"
    elif [ "$distro" = "debian" ] || [ "$distro" = "ubuntu" ] || [ "$distro" = "linuxmint" ] || [ "$distro" = "lmde" ]; then
        apt update && apt install -y systemd-zram-generator || die "Failed to install zram generator"
    else
        die "Unsupported distro: $distro. Manual install required."
    fi
}

#=================== Execution based on Init System ====================

if [ "$distro" = "nixos" ]; then
    setup_nixos
elif [ "$distro" = "void" ] && [ "$init_sys" = "runit" ]; then
    setup_runit
elif [ "$distro" = "gentoo" ] && [ "$init_sys" = "openrc" ]; then
    setup_openrc
elif [ "$distro" = "slackware" ]; then
    setup_sysv
else
    install_zram_generator
    setup_systemd
fi
