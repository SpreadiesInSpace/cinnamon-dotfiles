#!/bin/bash

# Download noto-fonts-cjk
wget --content-disposition https://archlinux.org/packages/extra/any/noto-fonts-cjk/download/

# Unpack
zstd -d *.pkg.tar.zst
tar -xf *.pkg.tar

# Install 
cp -vnpr usr/share/fonts/noto-cjk/ /usr/share/fonts/

# Symlink
mkdir -p ~/.fonts
sudo ln -s /usr/share/fonts/noto-cjk ~/.fonts

# Clean Up
rm -rf usr/
rm -rf noto-fonts-cjk-*
rm -rf .BUILDINFO
rm -rf .PKGINFO
rm -rf .MTREE
