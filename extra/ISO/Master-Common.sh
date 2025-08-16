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
	local distro="${1:-}"
	local zoneinfo_dir="/usr/share/zoneinfo"

	# If NixOS, use /etc/zoneinfo instead
	[ "$distro" = "nixos" ] && zoneinfo_dir="/etc/zoneinfo"

	while true; do
		read -rp "Enter your timezone (e.g., Asia/Bangkok): " timezone
		timezone="${timezone:-Asia/Bangkok}"  # default if empty
		if [ -f "$zoneinfo_dir/$timezone" ]; then
			echo "Timezone set to: $timezone"
			break
		fi
		echo "Invalid timezone: $timezone"
	done
}

# Only Gentoo uses this
set_video_card() {
	local target_path="${1:-/etc/portage/package.use/00video-cards}"

	while true; do
		echo "Select your video card type:"
		echo
		echo "1) amdgpu radeonsi"
		echo "2) nvidia"
		echo "3) intel"
		echo "4) nouveau (open source)"
		echo "5) virgl (QEMU/KVM)"
		echo "6) vc4 (Raspberry Pi)"
		echo "7) d3d12 (WSL)"
		echo "8) other"
		echo
		read -rp "Enter the number corresponding to your video card: " \
			video_card_number

		case $video_card_number in
			1) video_card="amdgpu radeonsi"; break ;;
			2) video_card="nvidia"; break ;;
			3) video_card="intel"; break ;;
			4) video_card="nouveau"; break ;;
			5) video_card="virgl"; break ;;
			6) video_card="vc4"; break ;;
			7) video_card="d3d12"; break ;;
			8) read -rp "Enter the video card type: " video_card; break ;;
			*) echo "Invalid selection, please try again." ;;
		esac
	done

	echo "*/* VIDEO_CARDS: $video_card" > "$target_path" || \
			die "Failed to update VIDEO_CARDS in $target_path."
	echo; echo "Updated VIDEO_CARDS in $target_path to $video_card"; echo
}