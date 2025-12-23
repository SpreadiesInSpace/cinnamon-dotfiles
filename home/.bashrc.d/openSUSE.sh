#!/bin/bash
# ~/.bashrc.d/openSUSE.sh
# openSUSE Tumbleweed specific aliases and functions

# Warning-based Error Handling
warn() { echo -e "\033[1;33mWarning:\033[0m $*" >&2; return 1; }

# openSUSE Cleaning
cleanKernel() {
  sudo zypper purge-kernels || \
    warn "Failed to purge old kernels."
}

cleanExtra() {
  sudo zypper rm --no-confirm '*-lang' '*-doc' || \
    warn "Failed to remove language and documentation packages."
  sudo rm -rf /usr/share/themes/Mint-* || \
    warn "Failed to remove Mint themes."
}

cleanAll() {
  cleanKernel
  cleanExtra
  flatpak remove --unused || \
    warn "Failed to remove unused flatpak packages."
  sudo flatpak repair || \
    warn "Failed to repair flatpak packages."
  sudo rm -rf /var/lib/systemd/coredump/* || \
    warn "Failed to clean systemd coredumps."
  sudo zypper clean -a || \
    warn "Failed to clean zypper cache."
  if command -v snapper >/dev/null 2>&1; then
    sudo snapper delete 1-100 || \
      warn "Failed to delete snapper snapshots."
  fi
  rm -rf ~/.cache/* || \
    warn "Failed to clean user cache."
  sudo rm -rf /tmp/* || \
    warn "Failed to clean /tmp"
  sudo journalctl --vacuum-size=50M || \
    warn "Failed to vacuum journalctl by size."
  sudo journalctl --vacuum-time=4weeks || \
    warn "Failed to vacuum journalctl by time."
  sudo bleachbit -c --preset || \
    warn "Failed to run system bleachbit cleanup."
  bleachbit -c --preset || \
    warn "Failed to run user bleachbit cleanup."
}

# openSUSE Update
updateNeovim() {
  echo "Performing LazySync..."
  nvim --headless "+Lazy! sync" +qa > /dev/null 2>&1 || \
    warn "LazySync failed."
  echo "LazySync complete!"
}

updateApp() {
  sudo zypper ref || warn "Failed to refresh repositories."
  sudo zypper dup || warn "Failed to perform distribution upgrade."
  flatpak update -y || warn "Failed to update flatpak packages."
  updateNeovim || warn "Failed to update Neovim."
}

updateAll() {
  if updateApp; then
    cleanAll
  fi
}

updateRestart() {
  updateAll
  reboot
}

updateShutdown() {
  updateAll
  poweroff
}

# Update and Cleanup
UC() {
  updateAll || warn "Failed to complete update."
  sudo -E bleachbit || warn "Final bleachbit cleanup failed."
  exit
}