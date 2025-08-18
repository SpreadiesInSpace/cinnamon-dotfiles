#!/bin/bash

# All-in-one zRAM swap script with autostart setup

die() {
	printf "\033[1;31mError:\033[0m %s\n" "$*" >&2
	exit 1
}

uninstall_autostart() {
	local script_path="/usr/local/bin/zram-swap.sh"
	local username="$SUDO_USER"
	local user_home=$(getent passwd "$username" | cut -d: -f6)
	local desktop_file="$user_home/.config/autostart/zram-swap.desktop"

	echo "Removing zRAM autostart configuration..."

	# Stop any active zRAM swap
	local zram_dev
	zram_dev=$(grep zram /proc/swaps 2>/dev/null | cut -d' ' -f1 | head -n1)
	if [ -n "$zram_dev" ]; then
		echo "Disabling active zRAM swap..."
		swapoff "$zram_dev" 2>/dev/null || true
		if command -v zramctl >/dev/null 2>&1; then
			zramctl -r "$zram_dev" 2>/dev/null || true
		else
			echo 1 > "/sys/block/${zram_dev#/dev/}/reset" 2>/dev/null || true
		fi
	fi

	# Remove desktop autostart file
	if [ -f "$desktop_file" ]; then
		rm "$desktop_file" && echo "Removed autostart desktop file"
	fi

	# Remove sudoers entry
	if grep -q "$script_path" /etc/sudoers 2>/dev/null; then
		# Create temp sudoers without the zram line
		grep -v "$script_path" /etc/sudoers > /tmp/sudoers.tmp
		visudo -c -f /tmp/sudoers.tmp && mv /tmp/sudoers.tmp /etc/sudoers
		echo "Removed sudoers entry"
	fi

	# Remove installed script
	if [ -f "$script_path" ]; then
		rm "$script_path" && echo "Removed installed script"
	fi

	printf "\033[1;32mUninstall complete!\033[0m zRAM autostart removed.\n"
}

setup_autostart() {
	local script_path="/usr/local/bin/zram-swap.sh"
	local username="$SUDO_USER"
	local user_home=$(getent passwd "$username" | cut -d: -f6)
	local autostart_dir="$user_home/.config/autostart"
	local desktop_file="$autostart_dir/zram-swap.desktop"

	echo "Setting up autostart configuration..."

	# Copy this script to system location
	cp "$SCRIPT_FULL_PATH" "$script_path" || die "Failed to copy script"
	chmod +x "$script_path" || die "Failed to make script executable"

	# Setup passwordless sudo
	local sudoers_line="$username ALL=(ALL) NOPASSWD: $script_path"
	if ! grep -q "$script_path" /etc/sudoers 2>/dev/null; then
		echo "$sudoers_line" >> /etc/sudoers || die "Failed to add sudoers"
		echo "Added passwordless sudo entry"
	fi

	# Create autostart directory as user
	sudo -u "$username" mkdir -p "$autostart_dir" || \
		die "Failed to create autostart directory"

	# Create desktop autostart file
	cat > "$desktop_file" << EOF
[Desktop Entry]
Type=Application
Name=zRAM Swap Setup
Comment=Initialize zRAM compressed swap
Exec=sudo $script_path
Terminal=false
StartupNotify=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF

	# Set proper ownership
	chown "$username:$(id -gn "$username")" "$desktop_file"

	printf "\033[1;32mAutostart setup complete!\033[0m\n"
	echo "zRAM swap will now start automatically on login"
	echo "Script installed to: $script_path"
}

setup_zram() {
	echo "Setting up zRAM swap..."

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

	printf "\033[1;32mzRAM swap activated successfully!\033[0m\n"
	echo "Size: $((zram_size_kib / 1024)) MB"
}

# Get the full path to this script
SCRIPT_FULL_PATH="$(realpath "$0")"

# Main logic
if [[ $EUID -ne 0 ]]; then
	# Not running as root - check what operation to perform
	case "$1" in
		"--setup")
			echo "Installing and configuring zRAM autostart..."
			exec sudo /bin/bash "$SCRIPT_FULL_PATH" --setup
			;;
		"--uninstall")
			echo "Uninstalling zRAM autostart..."
			exec sudo /bin/bash "$SCRIPT_FULL_PATH" --uninstall
			;;
		*)
			echo "Usage: $0 [--setup|--uninstall]"
			echo "  --setup     Install zRAM autostart"
			echo "  --uninstall Remove zRAM autostart"
			exit 1
			;;
	esac
else
	# Running as root
	if [[ "$1" == "--setup" ]] && [[ -n "$SUDO_USER" ]]; then
		# Setup mode - configure autostart
		setup_autostart
		echo "Running initial zRAM setup..."
		setup_zram
	elif [[ "$1" == "--uninstall" ]] && [[ -n "$SUDO_USER" ]]; then
		# Uninstall mode - remove everything
		uninstall_autostart
	else
		# Normal mode - just setup zRAM
		setup_zram
	fi
fi