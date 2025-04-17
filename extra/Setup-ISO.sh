#!/bin/bash

# Links to run this file:
# bash <(curl -sL https://tinyurl.com/cinnamon-ISO)
# bash <(wget -qO- https://tinyurl.com/cinnamon-ISO)

# Shortened Links:
# https://tinyurl.com/cinnamon-ISO (this file)
# https://tinyurl.com/cinnamon-setup (Setup.sh)
# https://tinyurl.com/cinnamon-dotfiles (this repo)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Install script URLs and names
declare -A installs=(
  [1]="https://tinyurl.com/spready-arch"
  [2]="https://tinyurl.com/spready-gentoo"
  [3]="https://tinyurl.com/spready-opensuse-tumbleweed"
  [4]="https://tinyurl.com/spready-slackware-current"
  [5]="https://tinyurl.com/spready-void"
)

declare -A names=(
  [1]="Arch-Install.sh"
  [2]="Gentoo-Install.sh"
  [3]="OpenSUSE-TW-Install.sh"
  [4]="Slackware-Current-Install.sh"
  [5]="Void-Install.sh"
)

# Prompt menu
echo -e "${YELLOW}Which installer would you like to run?${NC}"
options=(
  "Arch Linux"
  "Gentoo"
  "openSUSE Tumbleweed"
  "Slackware Current"
  "Void Linux"
  "Exit"
)
PS3="Select a number: "

select opt in "${options[@]}"; do
  case $REPLY in
    [1-5])
      url="${installs[$REPLY]}"
      filename="${names[$REPLY]}"
      if [[ -z "$url" ]]; then
        echo -e "${RED}Invalid choice. Exiting.${NC}"
        exit 1
      fi

      echo -e "${YELLOW}Downloading $filename...${NC}"
      if command -v curl &>/dev/null; then
        curl -sL -C - --retry 10 --connect-timeout 10 "$url" -o "$filename"
      elif command -v wget &>/dev/null; then
        wget -q -c -T 10 -t 10 "$url" -O "$filename"
      else
        echo -e "${RED}Error: Neither curl nor wget found. Exiting.${NC}"
        exit 1
      fi

      chmod +x "$filename"
      echo -e "${GREEN}Running $filename...${NC}"

      if [[ "$REPLY" == "4" ]]; then
        ./"$filename"  # Slackware: run non-sudo
      else
        sudo ./"$filename"
      fi
      break
      ;;
    6)
      echo -e "${GREEN}Exiting.${NC}"
      exit 0
      ;;
    *)
      echo -e "${RED}Invalid choice. Try again.${NC}"
      ;;
  esac
done
