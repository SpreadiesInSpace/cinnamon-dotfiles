#!/bin/bash
# ~/.bashrc.d/opensuse.sh
# openSUSE Tumbleweed specific aliases and functions

# Minimum Error Handling
bdie() { echo -e "\033[1;31mError:\033[0m $*" >&2; return 1; }

# openSUSE Cleaning
cleanAll() {
  sudo zypper rm --no-confirm '*-lang' '*-doc' || true
  sudo rm -rf /usr/share/themes/Mint-* || true
  flatpak remove --unused || true
  sudo flatpak repair || bdie "Failed to repair flatpak packages."
  sudo rm -rf /var/lib/systemd/coredump/* || true
  sudo zypper clean -a || true
  sudo zypper purge-kernels || true
  if command -v snapper >/dev/null 2>&1; then
    sudo snapper delete 1-100 || true
  fi
  rm -rf ~/.cache/* || true
  sudo rm -rf /tmp/* || true
  sudo journalctl --vacuum-size=50M || true
  sudo journalctl --vacuum-time=4weeks || true
  sudo bleachbit -c --preset || true
  bleachbit -c --preset || true
}

# openSUSE Update
updateNeovim() {
  echo "Performing LazySync..."
  nvim --headless "+Lazy! sync" +qa > /dev/null 2>&1 || \
    bdie "LazySync failed."
  echo "LazySync complete!"
}

updateApp() {
  sudo zypper ref || bdie "Failed to refresh repositories."
  sudo zypper dup || bdie "Failed to perform distribution upgrade."
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
  sudo -E bleachbit || true
  exit
}