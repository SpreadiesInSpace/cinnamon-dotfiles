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
  sudo dnf autoremove -y || true
  flatpak remove --unused || true
  sudo flatpak repair || die "Failed to repair flatpak packages."
  cleanExtra || true
  sudo dnf clean all || true
  rm -rf ~/.cache/* || true
  sudo journalctl --vacuum-size=50M || true
  sudo journalctl --vacuum-time=4weeks || true
  sudo bleachbit -c --preset || true
  bleachbit -c --preset || true
}

cleanKernel() {
  local old_kernels=$(dnf repoquery --installonly --latest-limit=-1 -q)
  if [ -n "$old_kernels" ]; then
    sudo dnf remove $old_kernels
  else
    echo "No old kernels to remove"
  fi
}

# Fedora Update
updateNeovim() {
  echo "Performing LazySync..."
  nvim --headless "+Lazy! sync" +qa > /dev/null 2>&1 || \
    die "LazySync failed."
  echo "LazySync complete!"
}

updateApp() {
  sudo dnf upgrade || die "Failed to update packages."
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