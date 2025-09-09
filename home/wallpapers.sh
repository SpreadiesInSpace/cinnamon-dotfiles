#!/bin/bash

# Source common functions
source ./Theme-Common.sh

# Ensure tmp is removed if script fails
trap 'rm -rf wallpapers/' EXIT

# Clone wallpapers
echo "Downloading wallpapers..."
git clone https://github.com/SpreadiesInSpace/wallpapers >/dev/null 2>&1 || \
  die "Failed to download wallpapers."

# Clean Up
trap - EXIT
rm -rf wallpapers/.git