#!/bin/bash
# ~/.bashrc.d/gentoo.sh
# Gentoo Linux specific aliases and functions

# Warning-based Error Handling
warn() { echo -e "\033[1;33mWarning:\033[0m $*" >&2; return 1; }

# Gentoo Cleaning
cleanAll() {
  sudo emerge -aq --depclean || \
    warn "Failed to clean dependencies."
  flatpak remove --unused || \
    warn "Failed to remove unused flatpak packages."
  sudo flatpak repair || \
    warn "Failed to repair flatpak packages."
  if [ "$(ps -p 1 -o comm=)" = "systemd" ] 2>/dev/null; then
    sudo rm -rf /var/lib/systemd/coredump/* || \
      warn "Failed to clean systemd coredumps."
    sudo journalctl --vacuum-size=50M || \
      warn "Failed to vacuum journalctl by size."
    sudo journalctl --vacuum-time=4weeks || \
      warn "Failed to vacuum journalctl by time."
  fi
  rm -rf ~/.cache/* || \
    warn "Failed to clean user cache."
  sudo rm -rf /var/tmp/portage/* || \
    warn "Failed to clean portage temporary files."
  sudo rm -rf /var/cache/distfiles/* || \
    warn "Failed to clean distfiles cache."
  sudo rm -rf /var/cache/binpkgs/* || \
    warn "Failed to clean binary packages cache."
  sudo eclean-dist -d || \
    warn "Failed to run eclean-dist."
  sudo eclean-pkg -d || \
    warn "Failed to run eclean-pkg."
  sudo bleachbit -c --preset || \
    warn "Failed to run system bleachbit cleanup."
  bleachbit -c --preset || \
    warn "Failed to run user bleachbit cleanup."
}

cleanKernel() {
  sudo eclean-kernel -a || warn "Failed to clean old kernels."
}

# Gentoo Update
updateSync() {
  sudo emaint -a sync || warn "Failed to sync repositories."
}

updatePortage() {
  sudo emerge --oneshot sys-apps/portage || \
    warn "Failed to update Portage."
}

updateNeovim() {
  echo "Performing LazySync..."
  nvim --headless "+Lazy! sync" +qa > /dev/null 2>&1 || \
    warn "LazySync failed."
  echo "LazySync complete!"
}

updateApp() {
  updateSync || warn "Failed to sync repos."
  sudo emerge -avqDuN --with-bdeps=y @world || \
    warn "Failed to update packages."
  flatpak update -y || warn "Failed to update flatpak packages."
  updateNeovim || warn "Failed to update Neovim."
  sudo grub-mkconfig -o /boot/grub/grub.cfg || \
    warn "Failed to update GRUB configuration."
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