#!/bin/bash
# ~/.bashrc.d/void.sh
# Void Linux specific aliases and functions

# Warning-based Error Handling
warn() { echo -e "\033[1;33mWarning:\033[0m $*" >&2; return 1; }

# Void Cleaning
cleanAll() {
  flatpak remove --unused || \
    warn "Failed to remove unused flatpak packages."
  sudo flatpak repair || \
    warn "Failed to repair flatpak packages."
  sudo xbps-remove -yROo || \
    warn "No orphaned packages to remove."
  sudo vkpurge rm all || \
    warn "Failed to remove old kernels."
  rm -rf ~/.cache/* || \
    warn "Failed to clean user cache."
  sudo rm -rf /var/cache/xbps || \
    warn "Failed to clean xbps cache."
  sudo bleachbit -c --preset || \
    warn "Failed to run system bleachbit cleanup."
  bleachbit -c --preset || \
    warn "Failed to run user bleachbit cleanup."
}

# Void Update
updateXdeb() {
  if [[ -x "${HOME}/update_xdeb.sh" ]]; then
    "${HOME}"/update_xdeb.sh || \
      warn "Failed to update xdeb/Brave/VSCodium."
  fi
}

updateNeovim() {
  echo "Performing LazySync..."
  nvim --headless "+Lazy! sync" +qa > /dev/null 2>&1 || \
    warn "LazySync failed."
  echo "LazySync complete!"
}

updateApp() {
  sudo xbps-install -Su xbps || warn "Failed to update xbps."
  sudo xbps-install -Suv || warn "Failed to update packages."
  updateXdeb || warn "Failed to update xdeb packages."
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