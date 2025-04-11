#!/bin/bash

# Shortened Links:
# https://tinyurl.com/cinnamon-ISO (this file)
# https://tinyurl.com/cinnamon-setup (Setup.sh)
# https://tinyurl.com/cinnamon-dotfiles (this repo)

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run the script using sudo."
  exit
fi

# Populate Installer Links
declare -A installs=(
  [1]="https://tinyurl.com/spready-arch"
  [2]="https://tinyurl.com/spready-gentoo"
  [3]="https://tinyurl.com/spready-opensuse-tumbleweed"
  [4]="https://tinyurl.com/spready-slackware-current"
  [5]="https://tinyurl.com/spready-void"
)

# Populate Names
declare -A names=(
  [1]="Arch-Install.sh"
  [2]="Gentoo-Install.sh"
  [3]="OpenSUSE-TW-Install.sh"
  [4]="Slackware-Current-Install.sh"
  [5]="Void-Install.sh"
)

# Download Function
download_file() {
  url=$1
  filename=$2
  if command -v curl &> /dev/null; then
    echo "Using curl to download $filename..."
    curl -sL "$url" -o "$filename"
  elif command -v wget &> /dev/null; then
    echo "Using wget to download $filename..."
    wget -q "$url" -O "$filename"
  else
    echo "Error: Neither curl nor wget found. Exiting."
    exit 1
  fi
}

# Installer Prompt
echo "Which installer would you like to run?"
echo "1) Arch Linux"
echo "2) Gentoo"
echo "3) openSUSE Tumbleweed"
echo "4) Slackware Current"
echo "5) Void Linux"
read -rp "Enter a number [1-5]: " choice

# Set Variables
url=${installs[$choice]}
filename=${names[$choice]}

# Safety Check
if [[ -z "$url" ]]; then
  echo "Invalid choice. Exiting."
  exit 1
fi

# Download Installer
echo "Downloading $filename..."
download_file "$url" "$filename"

# Make Installer executable and Run
chmod +x "$filename"
echo "Running $filename..."
./"$filename"
