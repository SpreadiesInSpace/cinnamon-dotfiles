#!/bin/bash

# Handle exits on error
die() {
	printf "\033[1;31mError:\033[0m %s\n" "$*" >&2
	exit 1
}

# Check if the script is run as root
[[ $EUID -ne 0 ]] && die "Please run the script as superuser."

# Abort if zram swap is already active
grep -q zram /proc/swaps && die "zram swap is already active."

# Load zram module
modprobe zram || die "zram module not available"

# Calculate zram size per Gentoo Wiki
ram_kib=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
ram_gib=$((ram_kib / 1024 / 1024))

if [ "$ram_gib" -lt 8 ]; then
	zram_size_kib=$((ram_kib * 3 / 2))  # 1.5x RAM
elif [ "$ram_gib" -lt 16 ]; then
	zram_size_kib=$((ram_kib))         # 1.0x RAM
else
	zram_size_kib=$((ram_kib / 2))     # 0.5x RAM
fi

# Use zramctl if available, else fallback to sysfs
if command -v zramctl >/dev/null 2>&1; then
	zram_dev=$(zramctl --find)
	zramctl --algorithm zstd --size "${zram_size_kib}K" "$zram_dev" || \
		die "zramctl setup failed"
else
	zram_dev=/dev/zram0
	[ -e "$zram_dev" ] || echo 0 > /sys/class/zram-control/hot_add
	echo zstd > /sys/block/zram0/comp_algorithm 2>/dev/null || true
	echo "${zram_size_kib}K" > /sys/block/zram0/disksize || \
		die "Failed to set zram size"
fi

# Format and enable swap
mkswap "$zram_dev" || die "mkswap failed"
swapon "$zram_dev" || die "swapon failed"
