#!/bin/bash
# ~/.bashrc.d/slackware.sh
# Slackware Current specific aliases and functions

# Minimum Error Handling
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; return 1; }

# Slackware Cleaning
cleanAll() {
  sudo find /var/log -type f -name "*.log" -exec truncate -s 0 {} \; || true
  sudo sboclean -d || true
  sudo sboclean -w || true
  yes | sudo slpkg clean-tmp || true
  flatpak uninstall --unused || true
  sudo flatpak repair || die "Failed to repair flatpak packages."
  rm -rf ~/.cache/* || true
  sudo bleachbit -c --preset || true
  bleachbit -c --preset || true
}

# Slackware Update
updateSlpkg() {
  sudo slpkg update || die "Failed to update slpkg repositories."
  sudo slpkg upgrade -P -B || die "Failed to upgrade sbo packages."

  local repos="slack slack_extra csb conraid alien gnome slint"
  for repo in $repos; do
    echo "Updating repository: $repo"
    sudo slpkg upgrade -P -B -o "$repo" || \
      die "Failed to upgrade $repo packages."
  done
}

updateNeovim() {
  echo "Performing LazySync..."
  nvim --headless "+Lazy! sync" +qa > /dev/null 2>&1 || \
    die "LazySync failed."
  echo "LazySync complete!"
}

updateBootloader() {
  if command -v grub-mkconfig >/dev/null 2>&1; then
    echo "Detected GRUB bootloader."
    grub-mkconfig -o /boot/grub/grub.cfg || \
      die "Failed to generate GRUB config."
  elif [ -f /boot/efi/EFI/Slackware/elilo.conf ] || \
    [ -f /boot/efi/EFI/ELILO/elilo.conf ]; then
    echo "Detected ELILO bootloader."
    eliloconfig || \
      die "Failed to update ELILO configuration."
  elif [ -f /etc/lilo.conf ]; then
    echo "Detected LILO bootloader."
    lilo || \
      die "Failed to update LILO configuration."
  else
    echo "No recognized bootloader found."
    die "Bootloader configuration not updated."
  fi
}

updateApp() {
  sudo sbocheck || true
  sudo sboupgrade --all || true
  updateSlpkg || true
  updateBootloader || true
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