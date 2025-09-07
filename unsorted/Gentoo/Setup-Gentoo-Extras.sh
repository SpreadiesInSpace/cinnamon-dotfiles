#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
	echo "Please run the script using sudo."
	exit
fi

# Set LINGUAS for Cinnamon Localization
echo "*/* LINGUAS: en" | tee /etc/portage/package.use/00localization || \
die "Failed to set LINGUAS to EN"

# Use Cinnamon from djs_overlay
eselect repository enable djs_overlay || \
	die "Failed to enable djs_overlay repository."
echo "app-editors/nemo::djs_overlay" | \
	tee /etc/portage/package.mask/nemo || \
	die "Failed to mask nemo package."
echo "app-editors/neovim::djs_overlay" | \
	tee /etc/portage/package.mask/neovim || \
	die "Failed to mask neovim package."
echo "www-client/brave-bin::djs_overlay" | \
	tee /etc/portage/package.mask/brave || \
	die "Failed to mask brave-bin package."

# Update system and install Cinnamon (split them to prevent slot conflicts)
desktop_environment=(
	"x11-base/xorg-server"
	"gnome-extra/cinnamon"
	"x11-misc/lightdm"
	"x11-misc/lightdm-gtk-greeter"
	"www-client/brave-bin" # for verifying gentoo-zh > djs_brave override
)
emerge -vqDuN --with-bdeps=y "${desktop_environment[@]}" || \
	die "Failed to install Cinnamon/Brave package group."

# Temporary Python Versions Fix
echo "x11-apps/lightdm-gtk-greeter-settings PYTHON_SINGLE_TARGET: python3_12" | \
tee /etc/portage/package.use/python || \
die "Failed to set USE flags for python."

# lwt fix for guestfs-tools
emerge -vq --keep-going app-emulation/guestfs-tools
# re-emerge dev/ppxlib from source
FEATURES="-getbinpkg" emerge -1Dvq dev-ml/ppxlib
# lwt will now compile properly, allowing guestfs-tools to finish compiling
emerge -vq --keep-going app-emulation/guestfs-tools
