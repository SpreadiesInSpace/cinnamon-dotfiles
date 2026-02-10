#!/bin/bash

# Minimal Error Handling function
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

# Install Self-Compiled qemu from SBo
git clone https://github.com/spreadiesinspace/qemu || \
  die "Failed to download QEMU."
cd qemu/ || die "Moving to qemu directory failed."
sudo ./install.sh >/dev/null 2>&1 || die "Failed to install QEMU."
cd ..
rm -rf qemu/
