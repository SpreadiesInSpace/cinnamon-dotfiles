#!/bin/bash

# Source common functions
source ./Theme-Common.sh

# Ensure tmp is removed if script fails
trap 'rm -rf tmp' EXIT

# Clone icons and fonts
mkdir tmp
echo "Downloading Icons and Fonts..."
git clone https://github.com/SpreadiesInSpace/cinnamon-extras tmp >/dev/null \
	2>&1 || die "Failed to Download Icons and Fonts."

# Clean Up
rm -rf tmp/.git
cp -npr tmp/.* .
rm -rf tmp/
