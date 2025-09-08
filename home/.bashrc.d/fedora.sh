#!/bin/bash
# ~/.bashrc.d/fedora.sh
# Fedora Linux specific aliases and functions

# Minimum Error Handling
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; return 1; }

# Fedora Cleaning
cleanExtra() {
	sudo rpm -e --nodeps cinnamon-themes mint-x-icons \
		mint-y-icons mint-y-theme mint-themes \
		mint-themes-gtk3 mint-themes-gtk4 || true
	sudo rm -rf /var/lib/systemd/coredump/* || true
	sudo rm -rf /var/tmp/.guestfs-1000/* || true
	sudo rm -rf /var/cache/PackageKit/ || true
}

cleanAll() {
	flatpak remove --unused || true
	sudo flatpak repair || true
	cleanExtra || true
	sudo dnf clean all || true
	rm -rf ~/.cache/* || true
	sudo journalctl --vacuum-size=50M || true
	sudo journalctl --vacuum-time=4weeks || true
	sudo bleachbit -c --preset || true
	bleachbit -c --preset || true
}

cleanKernel() {
	if old_kernels=$(dnf repoquery --installonly \
		--latest-limit=-1 -q 2>/dev/null); then
		sudo dnf remove "$old_kernels" || true
	fi
}

# Fedora Update
updateNeovim() {
	echo "Performing LazySync..."
	nvim --headless "+Lazy! sync" +qa > /dev/null 2>&1 || true
	echo "LazySync complete!"
}

updateApp() {
	sudo dnf upgrade -y || die "Failed to update packages."
	sudo dnf autoremove -y || true
	flatpak update || true
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