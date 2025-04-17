#!/bin/bash

# Links to run this file:
# bash <(curl -sL https://tinyurl.com/cinnamon-setup)
# bash <(wget -qO- https://tinyurl.com/cinnamon-setup)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Root check
if [ "$EUID" -eq 0 ]; then
  echo -e "${RED}This script must NOT be run as root. Please execute it as a regular user.${NC}"
  exit 1
fi

# Repo details
REPO_URL="https://github.com/SpreadiesInSpace/cinnamon-dotfiles"
ZIP_URL="$REPO_URL/archive/refs/heads/main.zip"
ZIP_NAME="dotfiles.zip"

echo -e "${YELLOW}Downloading cinnamon-dotfiles archive...${NC}"
if command -v curl &>/dev/null; then
  curl -sL -C - --retry 10 --connect-timeout 10 "$ZIP_URL" -o "$ZIP_NAME"
elif command -v wget &>/dev/null; then
  wget -q -c -T 10 -t 10 "$ZIP_URL" -O "$ZIP_NAME"
else
  echo -e "${RED}Error: Neither curl nor wget is available.${NC}"
  exit 1
fi

echo -e "${YELLOW}Unzipping archive...${NC}"
unzip -o "$ZIP_NAME" &>/dev/null || { echo -e "${RED}Unzip failed. Exiting.${NC}"; exit 1; }
rm "$ZIP_NAME"
mv cinnamon-dotfiles-main cinnamon-dotfiles
cd cinnamon-dotfiles || { echo -e "${RED}Directory not found. Exiting.${NC}"; exit 1; }

# Setup script list
setup_names=(
  "Arch"
  "Fedora-42"
  "Gentoo"
  "LMDE-6"
  "NixOS-Unstable"
  "OpenSUSE-Tumbleweed"
  "Slackware-Current"
  "Void"
)

echo -e "${YELLOW}Which setup script would you like to run?${NC}"
PS3="Select a number: "

select distro in "${setup_names[@]}" "Exit"; do
  if [[ "$distro" == "Exit" ]]; then
    echo -e "${GREEN}Exiting.${NC}"
    exit 0
  elif [[ -n "$distro" ]]; then
    script="Setup-${distro}.sh"
    if [[ ! -f "$script" ]]; then
      echo -e "${RED}Script $script not found. Exiting.${NC}"
      exit 1
    fi

    chmod +x "$script"
    echo -e "${GREEN}Running $script...${NC}"
    if [[ "$distro" == "NixOS-Unstable" ]]; then
      nix-shell -p unzip --run "sudo bash $script"
    else
      sudo bash "$script"
    fi
    break
  else
    echo -e "${RED}Invalid choice. Try again.${NC}"
  fi
done

