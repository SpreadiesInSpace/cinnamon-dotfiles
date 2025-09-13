#!/bin/bash
# ~/.bashrc.d/slackware.sh
# Slackware Current specific aliases and functions

# Minimum Error Handling
bdie() { echo -e "\033[1;31mError:\033[0m $*" >&2; return 1; }

# Slackware Cleaning
cleanAll() {
  sudo find /var/log -type f -name "*.log" -exec truncate -s 0 {} \; || true
  sudo sboclean -d || true
  sudo sboclean -w || true
  yes | sudo slpkg clean-tmp || true
  flatpak uninstall --unused || true
  sudo flatpak repair || bdie "Failed to repair flatpak packages."
  rm -rf ~/.cache/* || true
  sudo bleachbit -c --preset || true
  bleachbit -c --preset || true
}

# Slackware Update
updateSlpkg() {
  sudo slpkg update || bdie "Failed to update slpkg repositories."
  sudo slpkg upgrade -P -B || bdie "Failed to upgrade sbo packages."

  local repos="slack slack_extra csb conraid alien gnome slint"
  for repo in $repos; do
    echo "Updating repository: $repo"
    sudo slpkg upgrade -P -B -o "$repo" || \
      bdie "Failed to upgrade $repo packages."
  done
}

updateNeovim() {
  echo "Performing LazySync..."
  nvim --headless "+Lazy! sync" +qa > /dev/null 2>&1 || \
    bdie "LazySync failed."
  echo "LazySync complete!"
}

updateBootloader() {
  if command -v sudo grub-mkconfig >/dev/null 2>&1; then
    echo "Detected GRUB bootloader."
    sudo grub-mkconfig -o /boot/grub/grub.cfg || \
      bdie "Failed to generate GRUB config."
  elif [ -f /boot/efi/EFI/Slackware/elilo.conf ] || \
    [ -f /boot/efi/EFI/ELILO/elilo.conf ]; then
    echo "Detected ELILO bootloader."
    sudo eliloconfig || \
      bdie "Failed to update ELILO configuration."
  elif [ -f /etc/lilo.conf ]; then
    echo "Detected LILO bootloader."
    sudo lilo || \
      bdie "Failed to update LILO configuration."
  else
    echo "No recognized bootloader found."
    bdie "Bootloader configuration not updated."
  fi
}

updateApp() {
  sudo sbocheck || true
  sudo sboupgrade --all || true
  updateSlpkg || true
  updateBootloader || true
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