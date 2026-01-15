#!/bin/bash

# Minimal Error Handling function
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

# Download noto-fonts
URL="https://archlinux.org/packages/extra/any/noto-fonts/download/"
wget -c -T 10 -t 10 -q --show-progress --content-disposition "$URL" || \
  die "Failed to download noto-fonts."

# Unpack
zstd -d ./*.pkg.tar.zst || die "Decompression failed."
tar -xf ./*.pkg.tar || die "Extraction failed."

# Install
echo "Installing noto-fonts."
sudo cp -npr usr/share/fonts/noto/ /usr/share/fonts/ || \
  die "Failed to copy noto-fonts to /usr/share/fonts"

# Symlink
mkdir -p ~/.fonts || die "Failed to make .fonts folder."
sudo ln -sf /usr/share/fonts/noto ~/.fonts || \
  die "Failed to symlink fonts."

# Clean Up
rm -rf usr/ || die "Failed to remove usr/"
rm -rf noto-fonts-* || die "Failed to remove noto-fonts-*"
rm -rf .BUILDINFO || die "Failed to remove .BUILDINFO"
rm -rf .PKGINFO || die "Failed to remove .PKGINFO"
rm -rf .MTREE || die "Failed to remove .MTREE"
