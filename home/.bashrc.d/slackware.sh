#!/bin/bash
# ~/.bashrc.d/slackware.sh
# Slackware Current specific aliases and functions

# Minimum Error Handling
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; return 1; }

# Slackware Cleaning
cleanAll() {
	sudo find /var/log -type f -name "*.log" -exec truncate -s 0 {} \; || true
	sudo sboclean -d || true
	sudo sboclean -w || true
	yes | sudo slpkg clean-tmp || true
	flatpak uninstall --unused || true
	sudo flatpak repair || true
	rm -rf ~/.cache/* || true
	sudo bleachbit -c --preset || true
	bleachbit -c --preset || true
}

# Slackware Update
updateSlpkg() {
	sudo slpkg update || die "Failed to update slpkg repositories."
	sudo slpkg upgrade -P -B || die "Failed to upgrade sbo packages."

	local repos="slack slack_extra csb conraid alien gnome slint"
	for repo in $repos; do
		echo "Updating repository: $repo"
		sudo slpkg upgrade -P -B -o "$repo" || \
			die "Failed to upgrade $repo packages."
	done
}

updateNeovim() {
	echo "Performing LazySync..."
	nvim --headless "+Lazy! sync" +qa > /dev/null 2>&1 || true
	echo "LazySync complete!"
}

updateApp() {
	sudo sbocheck || true
	sudo sboupgrade --all || true
	updateSlpkg || true
	sudo grub-mkconfig -o /boot/grub/grub.cfg || true
	flatpak update -y || true
	updateNeovim || true
}

updateAll() {
	updateApp && cleanAll || true
}

updateRestart() {
	updateAll && reboot || true
}

updateShutdown() {
	updateAll && poweroff || true
}

# Update and Cleanup
UC() {
	updateAll || true
	sudo bleachbit || true
	exit
}