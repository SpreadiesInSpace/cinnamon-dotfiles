#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -eq 0 ]; then
  echo "This script must NOT be run as root. Please execute it as a regular user."
  exit
fi

declare -A setups=(
  [1]="Arch"
  [2]="Fedora-41"
  [3]="Gentoo"
  [4]="LMDE-6"
  [5]="NixOS-Unstable"
  [6]="OpenSUSE-Tumbleweed"
  [7]="Slackware-Current"
  [8]="Void"
)

echo "Which setup script would you like to run?"
for i in "${!setups[@]}"; do
  echo "$i) Setup-${setups[$i]}.sh"
done

read -rp "Enter a number [1-8]: " choice
distro="${setups[$choice]}"

if [[ -z "$distro" ]]; then
  echo "Invalid choice. Exiting."
  exit 1
fi

script="Setup-${distro}.sh"

if [[ ! -f "$script" ]]; then
  echo "Script $script not found. Exiting."
  exit 1
fi

# Move to main directory
cd ..

if [[ ! -x "$script" ]]; then
  echo "Making $script executable..."
  chmod +x "$script"
fi

echo "Running $script..."
if [[ "$distro" == "Arch" ]]; then
  ./"$script"
else
  sudo ./"$script"
fi
