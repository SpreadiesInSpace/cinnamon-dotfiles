#!/usr/bin/env bash

# All-in-one zRAM swap script with autostart setup
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

# Check if running on NixOS
is_nixos() {
	[ -f /etc/os-release ] && grep -q "^ID=nixos" /etc/os-release
}

# Check for unsupported distributions
check_unsupported_distros() {
	if [ -f /etc/os-release ]; then
		if grep -q "^ID.*slackware" /etc/os-release || \
			 grep -q "^ID=fedora" /etc/os-release || \
			 grep -q "^ID.*suse" /etc/os-release; then
			local distro_name
			distro_name=$(grep "^PRETTY_NAME=" /etc/os-release | \
										cut -d'"' -f2)
			die "Unsupported distribution: $distro_name"
		fi
	fi
}

uninstall_autostart() {
	local script_path="/usr/local/bin/zram-swap.sh"
	local username="$SUDO_USER"
	local user_home
	user_home=$(getent passwd "$username" | cut -d: -f6)
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
	local sudoers_file="/etc/sudoers.d/zram-swap"
	if [ -f "$sudoers_file" ]; then
		rm "$sudoers_file" && echo "Removed sudoers entry"
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
	local user_home
	user_home=$(getent passwd "$username" | cut -d: -f6)
	local autostart_dir="$user_home/.config/autostart"
	local desktop_file="$autostart_dir/zram-swap.desktop"

	echo "Setting up autostart configuration..."

	# Copy this script to system location
	cp "$SCRIPT_FULL_PATH" "$script_path" || die "Failed to copy script"
	chmod +x "$script_path" || die "Failed to make script executable"

	# Setup passwordless sudo using sudoers.d
	local sudoers_dir="/etc/sudoers.d"
	local sudoers_file="$sudoers_dir/zram-swap"
	local sudoers_line="$username ALL=(ALL) NOPASSWD: $script_path"

	# Create sudoers.d directory if it doesn't exist
	if [ ! -d "$sudoers_dir" ]; then
		mkdir -p "$sudoers_dir" || die "Failed to create $sudoers_dir directory"
		chmod 755 "$sudoers_dir" || die "Failed to set sudoers.d permissions"
	fi

	if [ ! -f "$sudoers_file" ]; then
		echo "$sudoers_line" > "$sudoers_file" || \
			die "Failed to create sudoers file"
		chmod 440 "$sudoers_file" || \
			die "Failed to set sudoers file permissions"
		visudo -c -f "$sudoers_file" || \
			die "Invalid sudoers configuration"
		echo "Added passwordless sudo entry in $sudoers_file"
	fi

	# Create autostart directory
	mkdir -p "$autostart_dir" || die "Failed to create autostart directory"

	# Get user's UID and GID
	local user_uid
	user_uid=$(id -u "$username")
	local user_gid
	user_gid=$(id -g "$username")

	# Fix ownership of .config and autostart directories
	chown "$user_uid:$user_gid" "$user_home/.config" 2>/dev/null || true
	chown "$user_uid:$user_gid" "$autostart_dir" || \
		die "Failed to set autostart directory ownership"

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
	chown "$user_uid:$user_gid" "$desktop_file"

	printf "\033[1;32mAutostart setup complete!\033[0m\n"
	echo "zRAM swap will now start automatically on login"
	echo "Script installed to: $script_path"
}

setup_zram() {
	# Check if zram swap is already active
	if grep -q zram /proc/swaps 2>/dev/null; then
		echo "zRAM swap is already active:"
		grep zram /proc/swaps
		return 0
	fi

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
		# Find an available zram device or create one
		zram_dev=$(zramctl --find 2>/dev/null) || {
			# If --find fails, try to reset existing devices
			for dev in /dev/zram*; do
				[ -e "$dev" ] || continue
				echo "Attempting to reset busy device $dev..."
				zramctl -r "$dev" 2>/dev/null && {
					zram_dev="$dev"
					break
				}
			done
			# If still no device, try --find again
			[ -z "$zram_dev" ] && zram_dev=$(zramctl --find 2>/dev/null)
		}

		[ -z "$zram_dev" ] && die "No zRAM device available"

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

# Check for unsupported distributions first
check_unsupported_distros

# Main logic
if [[ $EUID -ne 0 ]]; then
	# Not running as root - re-exec with sudo
	case "$1" in
		"--install")
			if is_nixos; then
				die "Autostart installation not supported on NixOS. Use --test instead."
			fi
			echo "Installing and configuring zRAM autostart..."
			exec sudo bash "$SCRIPT_FULL_PATH" --install
			;;
		"--remove")
			echo "Uninstalling zRAM autostart..."
			exec sudo bash "$SCRIPT_FULL_PATH" --remove
			;;
		"--test")
			echo "Testing zRAM swap setup..."
			exec sudo bash "$SCRIPT_FULL_PATH" --test
			;;
		"")
			if is_nixos; then
				echo "NixOS detected - running zRAM setup directly..."
				exec sudo bash "$SCRIPT_FULL_PATH" --test
			else
				echo "Usage: $0 [--install|--remove|--test]"
				echo "  --install     Install zRAM autostart"
				echo "  --remove      Remove zRAM autostart"
				echo "  --test        Test zRAM swap setup (no autostart)"
				exit 1
			fi
			;;
		*)
			echo "Usage: $0 [--install|--remove|--test]"
			echo "  --install     Install zRAM autostart"
			echo "  --remove      Remove zRAM autostart"
			echo "  --test        Test zRAM swap setup (no autostart)"
			exit 1
			;;
	esac
else
	# Running as root
	case "$1" in
		"--install")
			[[ -z "$SUDO_USER" ]] && die "Must be run via sudo for --install"
			setup_autostart
			echo "Running initial zRAM setup..."
			setup_zram
			;;
		"--remove")
			[[ -z "$SUDO_USER" ]] && die "Must be run via sudo for --remove"
			uninstall_autostart
			;;
		*)
			# Default case: just setup zRAM (covers --test, NixOS, and no args)
			setup_zram
			;;
	esac
fi