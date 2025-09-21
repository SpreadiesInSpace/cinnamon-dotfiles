#!/bin/bash
# ~/.bashrc.d/lmde.sh
# LMDE specific aliases and functions

# Warning-based Error Handling
warn() { echo -e "\033[1;33mWarning:\033[0m $*" >&2; return 1; }

# Debian Cleaning
cleanKernel() {
  local packages
  mapfile -t packages < <(dpkg-query -W -f'${Package}\n' 'linux-*' | \
    sed -nr 's/.*-([0-9]+(\.[0-9]+){2}-[^-]+).*/\1 &/p' | \
    linux-version sort | \
    awk '($1==c){exit} {print $2}' c="$(uname -r | cut -f1,2 -d-)")

  if (( ${#packages[@]} > 0 )); then
    sudo apt-get purge "${packages[@]}" || \
      warn "Failed to remove old kernels."
  else
    echo "No old kernels to remove"
  fi
}

cleanAll() {
  flatpak remove --unused || \
    warn "Failed to remove unused flatpak packages."
  sudo flatpak repair || \
    warn "Failed to repair flatpak packages."
  sudo rm -rf /var/lib/systemd/coredump/* || \
    warn "Failed to clean systemd coredumps."
  sudo apt clean -y || \
    warn "Failed to clean apt cache."
  sudo apt autoclean -y || \
    warn "Failed to autoclean apt cache."
  sudo apt autoremove -y || \
    warn "Failed to autoremove packages."
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

# Debian Update
updateNeovim() {
  if [[ -x "${HOME}/update_neovim.sh" ]]; then
    "${HOME}"/update_neovim.sh || true
  fi
  echo "Performing LazySync..."
  nvim --headless "+Lazy! sync" +qa > /dev/null 2>&1 || \
    warn "LazySync failed."
  echo "LazySync complete!"
}

updateApp() {
  sudo apt update -y || warn "Failed to update package lists."
  sudo apt full-upgrade || warn "Failed to upgrade packages."
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

# LMDE Neofetch
neofetch() {
  if [[ -f "${HOME}/LMDEAscii.txt" ]]; then
    command neofetch --ascii "${HOME}/LMDEAscii.txt"
  else
    command neofetch
  fi
}