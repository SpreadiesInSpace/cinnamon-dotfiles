#!/bin/bash
# ~/.bashrc.d/Fedora.sh
# Fedora Linux specific aliases and functions

# Warning-based Error Handling
warn() { echo -e "\033[1;33mWarning:\033[0m $*" >&2; return 1; }

# Fedora Cleaning
cleanKernel() {
  local old_kernels
  old_kernels=$(dnf repoquery --installonly --latest-limit=-1 -q)
  if [ -n "$old_kernels" ]; then
    sudo dnf remove "$old_kernels" || \
      warn "Failed to remove old kernels."
  else
    echo "No old kernels to remove"
  fi
}

cleanExtra() {
  sudo rpm -e --nodeps cinnamon-themes mint-x-icons \
    mint-y-icons mint-y-theme mint-themes \
    mint-themes-gtk3 mint-themes-gtk4 || \
    warn "Failed to remove mint themes."
  sudo rm -rf /var/cache/PackageKit/ || \
    warn "Failed to clean PackageKit cache."
}

cleanAll() {
  cleanKernel
  cleanExtra
  sudo dnf autoremove -y || \
    warn "Failed to autoremove packages."
  flatpak remove --unused || \
    warn "Failed to remove unused flatpak packages."
  sudo flatpak repair || \
    warn "Failed to repair flatpak packages."
  sudo rm -rf /var/lib/systemd/coredump/* || \
    warn "Failed to clean systemd coredumps."
  sudo rm -rf /var/tmp/.guestfs-1000/* || \
    warn "Failed to clean guestfs temporary files."
  sudo dnf clean all || \
    warn "Failed to clean dnf cache."
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
}

# Fedora Update
updateNeovim() {
  echo "Performing LazySync..."
  nvim --headless "+Lazy! sync" +qa > /dev/null 2>&1 || \
    warn "LazySync failed."
  echo "LazySync complete!"
}

updateApp() {
  sudo dnf upgrade || warn "Failed to update packages."
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
  sudo bleachbit || warn "Final bleachbit cleanup failed."
  exit
}