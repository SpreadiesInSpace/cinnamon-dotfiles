#!/bin/bash

# Minimal Error Handling function
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

# PWD Check
[[ -d "../../boot/grub/themes/gruvbox-dark" ]] || \
  die "Run from cinnamon-dotfiles/extra/grub-theme-setup/ directory."

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  die "Please run the script as superuser."
fi

# Install Gruvbox GRUB theme
cd ../.. || die "Failed to change directory to project root."
mkdir -p /boot/grub/themes || \
  die "Failed to create GRUB themes directory."
mv /boot/grub/themes/linuxmint /boot/grub/themes/linuxmint.original || \
  die "Failed to rename original linuxmint theme."
cp -rf boot/grub/themes/gruvbox-dark /boot/grub/themes/ || \
  die "Failed to copy Gruvbox GRUB theme."
mv /boot/grub/themes/gruvbox-dark /boot/grub/themes/linuxmint || \
  die "Failed to rename Gruvbox theme to linuxmint."

# Update /etc/default/grub to use the new theme
GRUB_THEME_LINE='GRUB_THEME="/boot/grub/themes/gruvbox-dark/theme.txt"'
sed -i "/^GRUB_THEME=/s|^GRUB_THEME=.*|$GRUB_THEME_LINE|" \
  /etc/default/grub || \
  die "Failed to set GRUB_THEME line in /etc/default/grub."
grep -qxF "$GRUB_THEME_LINE" /etc/default/grub || \
  echo -e "\n$GRUB_THEME_LINE" | tee -a /etc/default/grub > /dev/null \
  || die "Failed to append GRUB_THEME line to /etc/default/grub."

# Update grub.cfg
grub-mkconfig -o /boot/grub/grub.cfg || \
  die "Failed to generate /boot/grub/grub.cfg."
