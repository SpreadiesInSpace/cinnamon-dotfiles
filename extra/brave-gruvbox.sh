#!/bin/bash

# Minimal Error Handling function
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

# Backup Existing Brave Profile
if [ -d ~/.config/BraveSoftware/ ]; then
  timestamp=$(date +%s)
  mv ~/.config/BraveSoftware/ ~/.config/BraveSoftware.old."$timestamp"/ || \
    die "Failed to backup old Brave Profile."
fi

# Clone Brave Gruvbox Example Profile
git clone https://github.com/spreadiesinspace/BraveSoftware \
  ~/.config/BraveSoftware || die "Failed to download new Brave profile."
rm -rf ~/.config/BraveSoftware/.git/ || die "Failed to remove .git"
rm -rf ~/.config/BraveSoftware/update_brave_settings.sh || \
  die "Failed to remove .git"
