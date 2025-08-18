#!/bin/bash

# Install Neofetch
echo "deb http://deb.debian.org/debian bookworm main" > \
	/etc/apt/sources.list.d/bookworm-neofetch.list || \
	die "Failed to add bookworm repo."
apt update || die "APT update failed."
apt install -y neofetch -t bookworm || die "Failed to install neofetch."

# Pin the package to prevent changes
echo "Package: neofetch
Pin: version *
Pin-Priority: 1001" > /etc/apt/preferences.d/pin-neofetch || \
	die "Failed to pin neofetch."

# Remove the source
rm /etc/apt/sources.list.d/bookworm-neofetch.list || \
	die "Failed to remove bookworm repo."
apt update || die "APT update failed."

# All packages
packages=(
	#"neofetch"
	"qt6-style-kvantum"
	"qt-style-kvantum-themes"
	"btm"
)

# Install Packages
apt install -y "${packages[@]}" || die "Failed to install packages."