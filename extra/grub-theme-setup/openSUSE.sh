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
mkdir -p /boot/grub2/themes || \
  die "Failed to create GRUB themes directory."
cp -rf boot/grub/themes/gruvbox-dark/ /boot/grub2/themes/ || \
  die "Failed to copy Gruvbox GRUB theme."

# Update /etc/default/grub to use the new theme
GRUB_THEME_LINE='GRUB_THEME="/boot/grub2/themes/gruvbox-dark/theme.txt"'
sed -i "/^GRUB_THEME=/s|^GRUB_THEME=.*|$GRUB_THEME_LINE|" \
  /etc/default/grub || \
  die "Failed to set GRUB_THEME line in /etc/default/grub."
grep -qxF "$GRUB_THEME_LINE" /etc/default/grub || \
  echo -e "\n$GRUB_THEME_LINE" | tee -a /etc/default/grub > /dev/null \
  || die "Failed to append GRUB_THEME line to /etc/default/grub."

# Check and comment out GRUB_TERMINAL_OUTPUT="console" if it exists
sed -i 's/^GRUB_TERMINAL_OUTPUT="console"/#&/' /etc/default/grub || \
  die "Failed to comment out GRUB_TERMINAL_OUTPUT in /etc/default/grub."

# Update grub.cfg
grub2-mkconfig -o /boot/grub2/grub.cfg || \
  die "Failed to generate /boot/grub2/grub.cfg."
