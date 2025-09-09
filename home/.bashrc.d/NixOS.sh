#!/usr/bin/env bash
# ~/.bashrc.d/nixos.sh
# NixOS specific aliases and functions

# NixOS Cleaning
cleanAll() {
  flatpak remove --unused || true
  sudo flatpak repair || die "Failed to repair flatpak packages."
  sudo rm -rf /var/lib/systemd/coredump/* || true
  rm -rf ~/.cache/* || true
  sudo rm /nix/var/nix/gcroots/auto/* || true
  sudo nix-collect-garbage -d || true
  nix-collect-garbage -d || true
  sudo nix-store --optimise || true
  nix-store --optimise || true
  sudo nix-env -p /nix/var/nix/profiles/system --delete-generations old || true
  sudo nix-env --delete-generations old || true
  nix-env --delete-generations old || true
  sudo journalctl --flush --rotate || true
  sudo journalctl --vacuum-time=1s || true
  sudo bleachbit -c --preset || true
  bleachbit -c --preset || true
}

# NixOS Update
updateNeovim() {
  echo "Performing LazySync..."
  nvim --headless "+Lazy! sync" +qa > /dev/null 2>&1 || \
    die "LazySync failed."
  echo "LazySync complete!"
}

updateApp() {
  sudo nixos-rebuild switch --upgrade || die "Failed to update packages."
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

# NixOS Neofetch
neofetch() {
  if [[ -f "${HOME}/NixAscii.txt" ]]; then
    command neofetch --ascii "${HOME}/NixAscii.txt"
  else
    command neofetch
  fi
}