#!/bin/bash

# Swap to modified pacman.conf with Arch Archive (26/11/24) as source
sudo mv /etc/pacman.conf /etc/pacman.conf.og
sudo cp pacman.conf /etc/pacman.conf

# Downgrade Cinnamon and dependencies to version 6.2.9
yay -Syyu cinnamon cinnamon-control-center cinnamon-desktop cinnamon-menus \
	cinnamon-screensaver cinnamon-session cinnamon-settings-daemon cjs muffin \
	nemo nemo-fileroller nemo-image-converter nemo-preview nemo-share xapp \
	xdg-desktop-portal-xapp

# Resore old pacman.conf
sudo mv /etc/pacman.conf.og /etc/pacman.conf

# Prevent Cinnamon and dependencies from upgrading
declare -A options=(["IgnorePkg"]="IgnorePkg = cinnamon cinnamon-control-center cinnamon-desktop cinnamon-menus cinnamon-screensaver cinnamon-session cinnamon-settings-daemon cjs muffin nemo nemo-fileroller nemo-image-converter nemo-preview nemo-share xapp xdg-desktop-portal-xapp")
# Loop over the options
for key in "${!options[@]}"; do
	# Check if the option is already in the file
	if ! grep -q "^$key" /etc/pacman.conf; then
		# If not, add it under the # Misc options section
		sudo sed -i "/^# Misc options/a ${options[$key]}" /etc/pacman.conf
	fi
done

# Refresh cache
yay -Syu

# Switch back to Cinnamon 6.2.9 compatible applets
cd ../..
mkdir -p ~/.local/share/cinnamon/applets
mkdir -p ~/.local/share/cinnamon/applets.og
mv ~/.local/share/cinnamon/applets/* ~/.local/share/cinnamon/applets.og
cp -vnpr home/.local/share/cinnamon/applets/* ~/.local/share/cinnamon/applets/
cd unsorted/Arch/ || exit
