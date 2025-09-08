#!/bin/bash
# ~/.bashrc.d/lmde.sh
# LMDE specific aliases and functions

# Minimum Error Handling
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; return 1; }

# Debian Cleaning
cleanKernel() {
	sudo apt-get purge $(dpkg-query -W -f'${Package}\n' 'linux-*' | \
		sed -nr 's/.*-([0-9]+(\.[0-9]+){2}-[^-]+).*/\1 &/p' | \
		linux-version sort | \
		awk '($1==c){exit} {print $2}' c="$(uname -r | cut -f1,2 -d-)") || \
		true
}

cleanAll() {
	flatpak remove --unused || true
	sudo flatpak repair || true
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
	nvim --headless "+Lazy! sync" +qa > /dev/null 2>&1 || true
	echo "LazySync complete!"
}

updateApp() {
	sudo apt update -y || die "Failed to update package lists."
	sudo apt full-upgrade -y || die "Failed to upgrade packages."
	flatpak update -y || true
	updateNeovim || true
}

updateAll() {
	updateApp && cleanAll || true
}

updateRestart() {
	updateAll && sudo systemctl reboot || true
}

updateShutdown() {
	updateAll && sudo systemctl poweroff || true
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