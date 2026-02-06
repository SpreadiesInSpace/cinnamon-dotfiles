#!/usr/bin/env bash

# Minimal Error Handling function
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

# Backup Existing Brave Profile
if [ -d ~/.config/BraveSoftware/ ]; then
  timestamp=$(date +%s)
  mv ~/.config/BraveSoftware/ ~/.config/BraveSoftware.old."$timestamp"/ || \
    die "Failed to backup old Brave Profile."
fi

# Download and extract Brave profile
ZIP_URL="https://github.com/spreadiesinspace/BraveSoftware"
ZIP_URL="$ZIP_URL/archive/refs/heads/main.zip"
ZIP_NAME="brave-profile.zip"
EXTRACT_DIR="BraveSoftware-main"

echo "Downloading Brave profile archive..."
if command -v curl &>/dev/null; then
  curl -sL -C - --retry 10 --connect-timeout 10 "$ZIP_URL" -o "$ZIP_NAME" || \
    die "Failed to download profile archive."
elif command -v wget &>/dev/null; then
  wget -q -c -T 10 -t 10 "$ZIP_URL" -O "$ZIP_NAME" || \
    die "Failed to download profile archive."
else
  die "Neither curl nor wget is available."
fi

echo "Extracting archive..."
unzip -n "$ZIP_NAME" &>/dev/null || die "Failed to extract archive."
rm "$ZIP_NAME"

# Move extracted contents to final location
mv "$EXTRACT_DIR" ~/.config/BraveSoftware || \
  die "Failed to move profile to destination."

# Clean Up
rm -rf ~/.config/BraveSoftware/push.sh || die "Failed to clean up."
echo "Brave profile setup complete!"