#!/bin/bash
# ~/.bashrc.d/arch.sh
# Arch Linux specific aliases and functions

# Minimum Error Handling
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; return 1; }

# Arch Cleaning
cleanCache() {
  if orphans=$(pacman -Qtdq 2>/dev/null); then
    sudo pacman -Rns "$orphans" || true
  fi
}

cleanAll() {
  flatpak remove --unused || true
  sudo flatpak repair || die "Failed to repair flatpak packages."
  sudo rm -rf /var/lib/systemd/coredump/* || true
  sudo pacman -Scc --noconfirm || true
  rm -rf ~/.cache/* || true
  sudo journalctl --vacuum-size=50M || true
  sudo journalctl --vacuum-time=4weeks || true
  sudo bleachbit -c --preset || true
  bleachbit -c --preset || true
  cleanCache || true
}

# Arch Update
updateNeovim() {
  echo "Performing LazySync..."
  nvim --headless "+Lazy! sync" +qa > /dev/null 2>&1 || \
    die "LazySync failed."
  echo "LazySync complete!"
}

updateApp() {
  yay || die "Failed to update packages."
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