#!/bin/bash
# ~/.bashrc.d/Slackware.sh
# Slackware Current specific aliases and functions

# Warning-based Error Handling
warn() { echo -e "\033[1;33mWarning:\033[0m $*" >&2; return 1; }

# Slackware Cleaning
cleanAll() {
  sudo find /var/log -type f -name "*.log" -exec truncate -s 0 {} \; || \
    warn "Failed to truncate log files."
  sudo sboclean -d || \
    warn "Failed to clean SBo download files."
  sudo sboclean -w || \
    warn "Failed to clean SBo work files."
  yes | sudo slpkg clean-tmp || \
    warn "Failed to clean slpkg temporary files."
  flatpak uninstall --unused || \
    warn "Failed to remove unused flatpak packages."
  sudo flatpak repair || \
    warn "Failed to repair flatpak packages."
  rm -rf ~/.cache/* || \
    warn "Failed to clean user cache."
  sudo bleachbit -c --preset || \
    warn "Failed to run system bleachbit cleanup."
  bleachbit -c --preset || \
    warn "Failed to run user bleachbit cleanup."
}

# Slackware Update
updateSlpkg() {
  sudo slpkg update || warn "Failed to update slpkg repositories."
  sudo slpkg upgrade -P -B || warn "Failed to upgrade sbo packages."

  local repos="slack slack_extra csb conraid alien gnome slint"
  for repo in $repos; do
    echo "Updating repository: $repo"
    sudo slpkg upgrade -P -B -o "$repo" || \
      warn "Failed to upgrade $repo packages."
  done
}

updateNeovim() {
  echo "Performing LazySync..."
  nvim --headless "+Lazy! sync" +qa > /dev/null 2>&1 || \
    warn "LazySync failed."
  echo "LazySync complete!"
}

updateBootloader() {
  if [ -f /etc/lilo.conf ]; then
    echo "Detected LILO bootloader."
    sudo lilo || warn "Failed to update LILO configuration."
  elif [ -f /boot/efi/EFI/Slackware/elilo.conf ] || \
    [ -f /boot/efi/EFI/ELILO/elilo.conf ]; then
    echo "Detected ELILO bootloader."
    sudo eliloconfig || warn "Failed to update ELILO configuration."
  elif command -v sudo grub-mkconfig >/dev/null 2>&1; then
    echo "Detected GRUB bootloader."
    sudo grub-mkconfig -o /boot/grub/grub.cfg || \
      warn "Failed to generate GRUB config."
  else
    warn "No recognized bootloader found."
  fi
}

updateApp() {
  sudo sbocheck || warn "Failed to check SBo packages."
  sudo sboupgrade --all || warn "Failed to upgrade SBo packages."
  updateSlpkg || warn "Failed to update slpkg packages."
  updateBootloader || warn "Failed to update bootloader."
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