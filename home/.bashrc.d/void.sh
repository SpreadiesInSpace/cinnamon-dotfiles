#!/bin/bash
# ~/.bashrc.d/void.sh
# Void Linux specific aliases and functions

# Minimum Error Handling
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; return 1; }

# Void Cleaning
cleanAll () {
	flatpak remove --unused || true
	sudo flatpak repair || true
	sudo xbps-remove -yROo || true
	sudo vkpurge rm all || true
	rm -rf ~/.cache/* || true
	sudo rm -rf /var/cache/xbps || true
	sudo bleachbit -c --preset || true
	bleachbit -c --preset || true
}

# Void Update
updateXdeb() {
	if [[ -x "${HOME}/update_xdeb.sh" ]]; then
		"${HOME}"/update_xdeb.sh || true
	fi
}

updateNeovim() {
	echo "Performing LazySync..."
	nvim --headless "+Lazy! sync" +qa > /dev/null 2>&1 || true
	echo "LazySync complete!"
}

updateApp() {
	sudo xbps-install -Su xbps || die "Failed to update xbps."
	sudo xbps-install -Suvy || die "Failed to update packages."
	updateXdeb || true
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