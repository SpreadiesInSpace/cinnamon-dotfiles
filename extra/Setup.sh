#!/bin/bash

# Shortened Links:
# https://tinyurl.com/cinnamon-dotfiles-setup (this file)
# https://tinyurl.com/cinnamon-dotfiles-setup-ISO (Setup-ISO.sh)
# https://tinyurl.com/cinnamon-dotfiles (this repo)
# https://tinyurl.com/spready-arch (Arch-Install.sh)
# https://tinyurl.com/spready-gentoo (Gentoo-Install.sh)
# https://tinyurl.com/spready-opensuse-tumbleweed (openSUSE-Install.sh)
# https://tinyurl.com/spready-slackware-current (Slackware-Install.sh)
# https://tinyurl.com/spready-void (Void-Install.sh)

# Check if the script is run as root
if [ "$EUID" -eq 0 ]; then
  echo "This script must NOT be run as root. Please execute it as a regular user."
  exit
fi

# Download zip archive of repo 
REPO_URL="https://github.com/SpreadiesInSpace/cinnamon-dotfiles"
ZIP_URL="$REPO_URL/archive/refs/heads/main.zip"
ZIP_NAME="dotfiles.zip"
echo "Downloading dotfiles archive..."
if command -v curl &>/dev/null; then
  curl -L "$ZIP_URL" -o "$ZIP_NAME"
elif command -v wget &>/dev/null; then
  wget "$ZIP_URL" -O "$ZIP_NAME"
else
  echo "Error: Neither curl nor wget is available."
  exit 1
fi

# Unzip and move to cinnamon-dotfiles-main
echo "Unzipping..."
unzip -o "$ZIP_NAME" || { echo "Unzip failed. Exiting."; exit 1; }
cd cinnamon-dotfiles-main || { echo "Directory not found. Exiting."; exit 1; }

# Populate Names
setup_names=(
  "Arch"
  "Fedora-41"
  "Gentoo"
  "LMDE-6"
  "NixOS-Unstable"
  "OpenSUSE-Tumbleweed"
  "Slackware-Current"
  "Void"
)

# Installer Prompt
echo "Which setup script would you like to run?"
for i in "${!setup_names[@]}"; do
  index=$((i + 1))
  echo "$index) Setup-${setup_names[$i]}.sh"
done
read -rp "Enter a number [1-${#setup_names[@]}]: " choice

# Adjust index (user inputs 1-based index)
choice=$((choice - 1))

# Safety Check
if [[ -z "${setup_names[$choice]}" ]]; then
  echo "Invalid choice. Exiting."
  exit 1
fi

# Set Variables
distro="${setup_names[$choice]}"
script="Setup-${distro}.sh"

# Abort if script isn't there
if [[ ! -f "$script" ]]; then
  echo "Script $script not found. Exiting."
  exit 1
fi

# Make Script Executable
if [[ ! -x "$script" ]]; then
  echo "Making $script executable..."
  chmod +x "$script"
else
  echo "$script is already executable."
fi

# Run Script
echo "Running $script..."
if [[ "$distro" == "Arch" ]]; then
  ./"$script"
else
  sudo ./"$script"
fi
