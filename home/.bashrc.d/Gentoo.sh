#!/bin/bash
# ~/.bashrc.d/gentoo.sh
# Gentoo Linux specific aliases and functions

# Minimum Error Handling
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; return 1; }

# Gentoo Cleaning
cleanAll() {
	sudo emerge -aq --depclean || true
	flatpak remove --unused || true
	sudo flatpak repair || die "Failed to repair flatpak packages."
	if [ "$(ps -p 1 -o comm=)" = "systemd" ] 2>/dev/null; then
		sudo rm -rf /var/lib/systemd/coredump/* || true
		sudo journalctl --vacuum-size=50M || true
		sudo journalctl --vacuum-time=4weeks || true
	fi
	rm -rf ~/.cache/* || true
	sudo rm -rf /var/tmp/portage/* || true
	sudo rm -rf /var/cache/distfiles/* || true
	sudo rm -rf /var/cache/binpkgs/* || true
	sudo eclean-dist -d || true
	sudo eclean-pkg -d || true
	sudo bleachbit -c --preset || true
	bleachbit -c --preset || true
}

cleanKernel() {
	sudo eclean-kernel -a || true
}

# Gentoo Update
updateSync() {
	sudo emaint -a sync || die "Failed to sync repositories."
}

updatePortage() {
	sudo emerge --oneshot sys-apps/portage || \
		die "Failed to update Portage."
}

updateNeovim() {
	echo "Performing LazySync..."
	nvim --headless "+Lazy! sync" +qa > /dev/null 2>&1 || \
		die "LazySync failed."
	echo "LazySync complete!"
}

updateApp() {
	updateSync || die "Failed to sync repos."
	sudo emerge -avqDuN --with-bdeps=y @world || \
		die "Failed to update packages."
	flatpak update -y || die "Failed to update flatpak packages."
	updateNeovim || true
	sudo grub-mkconfig -o /boot/grub/grub.cfg || true
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