#!/bin/bash
# ~/.bashrc.d/lmde.sh
# LMDE specific aliases and functions

# Minimum Error Handling
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; return 1; }

# Debian Cleaning
cleanKernel() {
	local packages
	mapfile -t packages < <(dpkg-query -W -f'${Package}\n' 'linux-*' | \
		sed -nr 's/.*-([0-9]+(\.[0-9]+){2}-[^-]+).*/\1 &/p' | \
		linux-version sort | \
		awk '($1==c){exit} {print $2}' c="$(uname -r | cut -f1,2 -d-)")

	if (( ${#packages[@]} > 0 )); then
		sudo apt-get purge "${packages[@]}" || true
	else
		echo "No old kernels to remove"
	fi
}

cleanAll() {
	flatpak remove --unused || true
	sudo flatpak repair || die "Failed to repair flatpak packages."
	sudo rm -rf /var/lib/systemd/coredump/* || true
	sudo apt clean -y || true
	sudo apt autoclean -y || true
	sudo apt autoremove -y || true
	rm -rf ~/.cache/* || true
	sudo journalctl --vacuum-size=50M || true
	sudo journalctl --vacuum-time=4weeks || true
	sudo bleachbit -c --preset || true
	bleachbit -c --preset || true
}

# Debian Update
updateNeovim() {
	if [[ -x "${HOME}/update_neovim.sh" ]]; then
		"${HOME}"/update_neovim.sh || true
	fi
	echo "Performing LazySync..."
	nvim --headless "+Lazy! sync" +qa > /dev/null 2>&1 || \
		die "LazySync failed."
	echo "LazySync complete!"
}

updateApp() {
	sudo apt update -y || die "Failed to update package lists."
	sudo apt full-upgrade || die "Failed to upgrade packages."
	flatpak update -y || die "Failed to update flatpak packages."
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

# LMDE Neofetch
neofetch() {
	if [[ -f "${HOME}/LMDEAscii.txt" ]]; then
		command neofetch --ascii "${HOME}/LMDEAscii.txt"
	else
		command neofetch
	fi
}