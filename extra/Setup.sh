#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -eq 0 ]; then
  echo "This script must NOT be run as root. Please execute it as a regular user."
  exit
fi

# Move to main directory
cd ..

# Ordered list
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

echo "Which setup script would you like to run?"
for i in "${!setup_names[@]}"; do
  index=$((i + 1))
  echo "$index) Setup-${setup_names[$i]}.sh"
done

read -rp "Enter a number [1-${#setup_names[@]}]: " choice

# Adjust index (user inputs 1-based index)
choice=$((choice - 1))

# Safety check
if [[ -z "${setup_names[$choice]}" ]]; then
  echo "Invalid choice. Exiting."
  exit 1
fi

distro="${setup_names[$choice]}"
script="Setup-${distro}.sh"

if [[ ! -f "$script" ]]; then
  echo "Script $script not found. Exiting."
  exit 1
fi

if [[ ! -x "$script" ]]; then
  echo "Making $script executable..."
  chmod +x "$script"
else
  echo "$script is already executable."
fi

echo "Running $script..."
if [[ "$distro" == "Arch" ]]; then
  ./"$script"
else
  sudo ./"$script"
fi

