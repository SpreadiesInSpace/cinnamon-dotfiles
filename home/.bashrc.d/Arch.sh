#!/bin/bash
# ~/.bashrc.d/Arch.sh
# Arch Linux specific aliases and functions

# Warning-based Error Handling
warn() { echo -e "\033[1;33mWarning:\033[0m $*" >&2; return 1; }

# Arch Cleaning
cleanAll() {
  flatpak remove --unused || \
    warn "Failed to remove unused flatpak packages."
  sudo flatpak repair || \
    warn "Failed to repair flatpak packages."
  sudo rm -rf /var/lib/systemd/coredump/* || \
    warn "Failed to clean systemd coredumps."
  sudo rm -rf /var/cache/pacman/pkg/* || \
    warn "Failed to clean pacman pkg directory."
  yes | sudo pacman -Scc || \
    warn "Failed to clean pacman cache."
  rm -rf ~/.cache/* || \
    warn "Failed to clean user cache."
  sudo journalctl --vacuum-size=50M || \
    warn "Failed to vacuum journalctl by size."
  sudo journalctl --vacuum-time=4weeks || \
    warn "Failed to vacuum journalctl by time."
  sudo bleachbit -c --preset || \
    warn "Failed to run system bleachbit cleanup."
  bleachbit -c --preset || \
    warn "Failed to run user bleachbit cleanup."
  sudo pacman -Rns "$(pacman -Qtdq)" 2>/dev/null || \
    warn "No orphaned packages to remove."
}

# Arch Update
updateNeovim() {
  echo "Performing LazySync..."
  nvim --headless "+Lazy! sync" +qa > /dev/null 2>&1 || \
    warn "LazySync failed"
  echo "LazySync complete!"
}

updateApp() {
  yay || warn "Failed to update packages."
  flatpak update -y || warn "Failed to update flatpak packages."
  updateNeovim || warn "Failed to update Neovim."
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
  updateAll || warn "Failed to complete update."
  sudo bleachbit || warn "Final bleachbit cleanup failed."
  exit
}