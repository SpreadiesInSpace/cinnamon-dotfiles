#!/bin/bash

# Links to run this file:
# bash <(curl -sL https://tinyurl.com/cinnamon-ISO)
# bash <(wget -qO- https://tinyurl.com/cinnamon-ISO)

# Other Shortened Links:
# https://tinyurl.com/cinnamon-ISO (this file)
# https://tinyurl.com/cinnamon-setup (Setup.sh)
# https://tinyurl.com/cinnamon-dotfiles (this repo)

# Minimal Error Handling function
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Time any command and show elapsed duration
# Usage: timed <command>
timed() {
  local start_time
  local end_time
  local elapsed

  start_time=$(date +%s)
  "$@"
  end_time=$(date +%s)
  elapsed=$((end_time - start_time))
  echo -e "${GREEN}Time Elapsed: $((elapsed/60))m $((elapsed%60))s${NC}"
}

# Install script URLs and names
URL="https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles"
URL="$URL/main/extra/ISO"
declare -A installs=(
  [1]="$URL/Install-Arch.sh"
  [2]="$URL/Install-Fedora-42.sh"
  [3]="$URL/Install-Gentoo.sh"
  [4]="$URL/Install-NixOS-25.05.sh"
  [5]="$URL/Install-openSUSE-Tumbleweed.sh"
  [6]="$URL/Install-Slackware-Current.sh"
  [7]="$URL/Install-Void.sh"
)

declare -A names=(
  [1]="Install-Arch.sh"
  [2]="Install-Fedora-42.sh"
  [3]="Install-Gentoo.sh"
  [4]="Install-NixOS-25.05.sh"
  [5]="Install-openSUSE-Tumbleweed.sh"
  [6]="Install-Slackware-Current.sh"
  [7]="Install-Void.sh"
)

# Prompt menu
echo -e "${YELLOW}Which installer would you like to run?${NC}"
options=(
  "Arch Linux"
  "Fedora 42"
  "Gentoo"
  "NixOS 25.05"
  "openSUSE Tumbleweed"
  "Slackware Current"
  "Void Linux"
  "Exit"
)
PS3="Select a number: "

select _ in "${options[@]}"; do
  case $REPLY in
    [1-7])
      url="${installs[$REPLY]}"
      filename="${names[$REPLY]}"
      [[ -n "$url" ]] || die "Invalid choice. Exiting."

      echo -e "${YELLOW}Downloading $filename...${NC}"
      if command -v curl &>/dev/null; then
        curl -sL -C - --retry 10 --connect-timeout 10 "$url" -o "$filename"
      elif command -v wget &>/dev/null; then
        wget -q -c -T 10 -t 10 "$url" -O "$filename"
      else
        die "Neither curl nor wget found."
      fi

      chmod +x "$filename"
      echo -e "${GREEN}Running $filename...${NC}"

      if [[ "$REPLY" == "6" ]]; then
        # Slackware ISO doesn't have sudo
        bash "$filename"
      else
        timed sudo bash "$filename"
      fi
      break
      ;;
    8)
      echo -e "${GREEN}Exiting.${NC}"
      exit 0
      ;;
    *)
      echo -e "${RED}Invalid choice. Try again.${NC}"
      ;;
  esac
done
