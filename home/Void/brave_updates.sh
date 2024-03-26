#!/bin/bash

# Set the directory where you want to download and convert packages
WORKDIR="$HOME/brave_updates"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# Function to install and update xdeb
setup_xdeb() {
  # Install dependencies
  sudo xbps-install -Sy binutils tar curl xbps xz

  # Download the latest xdeb release
  curl -LO $(curl -s https://api.github.com/repos/xdeb-org/xdeb/releases/latest | grep -oP '"browser_download_url": "\K(.*xdeb)(?=")')

  # Set the executable bit for xdeb
  chmod 0744 xdeb
}

# Function to check and download the latest Brave version
check_and_download_brave() {
  # Get the latest release info from GitHub
  LATEST_RELEASE=$(curl -s https://api.github.com/repos/brave/brave-browser/releases/latest)

  # Extract the version number and download URL for the .deb package
  VERSION=$(echo "$LATEST_RELEASE" | grep -oP '"tag_name": "\K(.*)(?=")')
  DEB_URL=$(echo "$LATEST_RELEASE" | grep -oP '"browser_download_url": "\K(.*amd64.deb)(?=")')

  # Download the .deb package
  curl -LO "$DEB_URL"
}

# Function to convert and install the Brave package
convert_and_install_brave() {
  # Convert the .deb package to .xbps
  ./xdeb -Sedf brave-browser*.deb

  # Install the package
  sudo xbps-install -y -R ./binpkgs brave-browser
}

# Main process
setup_xdeb
check_and_download_brave
convert_and_install_brave
