#!/usr/bin/env bash
# ~/.bashrc.d/NixOS.sh
# NixOS specific aliases and functions

# Warning-based Error Handling
warn() { echo -e "\033[1;33mWarning:\033[0m $*" >&2; return 1; }

# NixOS Cleaning
cleanAll() {
  flatpak remove --unused || \
    warn "Failed to remove unused flatpak packages."
  sudo flatpak repair || \
    warn "Failed to repair flatpak packages."
  sudo rm -rf /var/lib/systemd/coredump/* || \
    warn "Failed to clean systemd coredumps."
  rm -rf ~/.cache/* || \
    warn "Failed to clean user cache"
  sudo rm /nix/var/nix/gcroots/auto/* || \
    warn "Failed to remove auto gcroots."
  sudo nix-collect-garbage -d || \
    warn "Failed to collect garbage as root."
  nix-collect-garbage -d || \
    warn "Failed to collect garbage as user."
  sudo nix-store --optimise || \
    warn "Failed to optimize nix store as root."
  nix-store --optimise || \
    warn "Failed to optimize nix store as user."
  sudo nix-env -p /nix/var/nix/profiles/system --delete-generations old || \
    warn "Failed to delete old system generations."
  sudo nix-env --delete-generations old || \
    warn "Failed to delete old root generations."
  nix-env --delete-generations old || \
    warn "Failed to delete old user generations."
  sudo journalctl --flush --rotate || \
    warn "Failed to flush and rotate journalctl."
  sudo journalctl --vacuum-time=1s || \
    warn "Failed to vacuum journalctl."
  sudo bleachbit -c --preset || \
    warn "Failed to run system bleachbit cleanup."
  bleachbit -c --preset || \
    warn "Failed to run user bleachbit cleanup."
}

# NixOS Update
updateNeovim() {
  echo "Performing LazySync..."
  nvim --headless "+Lazy! sync" +qa > /dev/null 2>&1 || \
    warn "LazySync failed."
  echo "LazySync complete!"
}

updateApp() {
  sudo nixos-rebuild switch --upgrade || warn "Failed to update packages."
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

# NixOS Neofetch
neofetch() {
  if [[ -f "${HOME}/NixAscii.txt" ]]; then
    command neofetch --ascii "${HOME}/NixAscii.txt"
  else
    command neofetch
  fi
}