#!/bin/bash
# ~/.bashrc.d/void.sh
# Void Linux specific aliases and functions

# Minimum Error Handling
bdie() { echo -e "\033[1;31mError:\033[0m $*" >&2; return 1; }

# Void Cleaning
cleanAll () {
  flatpak remove --unused || true
  sudo flatpak repair || bdie "Failed to repair flatpak packages."
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
  nvim --headless "+Lazy! sync" +qa > /dev/null 2>&1 || \
    bdie "LazySync failed."
  echo "LazySync complete!"
}

updateApp() {
  sudo xbps-install -Su xbps || bdie "Failed to update xbps."
  sudo xbps-install -Suv || bdie "Failed to update packages."
  updateXdeb || true
  flatpak update -y || bdie "Failed to update flatpak packages."
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