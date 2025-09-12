#!/usr/bin/env bash

# Links to run this file:
# bash <(curl -sL https://tinyurl.com/cinnamon-setup)
# bash <(wget -qO- https://tinyurl.com/cinnamon-setup)

# Other Shortened Links:
# https://tinyurl.com/cinnamon-setup (this file)
# https://tinyurl.com/cinnamon-ISO (Setup-ISO.sh)
# https://tinyurl.com/cinnamon-dotfiles (this repo)

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
    echo -e "${GREEN}Time elapsed: $((elapsed/60))m $((elapsed%60))s${NC}"
}

# Root check
if [ "$EUID" -eq 0 ]; then
  echo -e "${RED}This script must NOT be run as root. Please execute it as a \
regular user.${NC}"
  exit 1
fi

# Repo details
REPO_URL="https://github.com/SpreadiesInSpace/cinnamon-dotfiles"
ZIP_URL="$REPO_URL/archive/refs/heads/main.zip"
ZIP_NAME="dotfiles.zip"
EXTRACT_DIR="cinnamon-dotfiles-main"

# Resolve real path of script
if [[ "$0" =~ ^/dev/fd/ ]]; then
  SCRIPT_DIR="$PWD"
else
  SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null)")" \
    2>/dev/null && pwd || echo "$PWD")"
fi
TOP_DIR="$(dirname "$SCRIPT_DIR")"

# Skip cinnamon-dotfiles download if it already exists
if [[ "$(basename "$TOP_DIR")" == "cinnamon-dotfiles" ]]; then
  echo -e "${GREEN}Already inside cinnamon-dotfiles. Skipping download and \
extraction.${NC}"
  cd "$TOP_DIR" || \
    { echo -e "${RED}Failed to enter directory. Exiting.${NC}"; exit 1; }
else
  if [[ ! -d "cinnamon-dotfiles" ]]; then
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
    if grep -qi nixos /etc/os-release; then
      nix-shell -p unzip --run "unzip -n '$ZIP_NAME'" &>/dev/null || \
        { echo -e "${RED}Unzip failed (NixOS). Exiting.${NC}"; exit 1; }
    else
      unzip -n "$ZIP_NAME" &>/dev/null || \
        { echo -e "${RED}Unzip failed. Exiting.${NC}"; exit 1; }
    fi
    rm "$ZIP_NAME"

    mv "$EXTRACT_DIR" cinnamon-dotfiles
  else
    echo -e "${GREEN}cinnamon-dotfiles already exists. \
Skipping download and extraction.${NC}"
  fi

  cd cinnamon-dotfiles || \
    { echo -e "${RED}Directory not found. Exiting.${NC}"; exit 1; }
fi

# Setup script list
scripts=(
  "Setup-Arch.sh"
  "Setup-Fedora-42.sh"
  "Setup-Gentoo.sh"
  "Setup-LMDE-6.sh"
  "Setup-NixOS-25.05.sh"
  "Setup-OpenSUSE-Tumbleweed.sh"
  "Setup-Slackware-Current.sh"
  "Setup-Void.sh"
)

# Flag check
for script in "${scripts[@]}"; do
  base="${script,,}" # Lowercase script name
  flag="${base//setup-/}" # Remove 'setup-' prefix
  flag=".${flag%%.sh}.done" # Trim extension and prepend dot
    if [[ -f "./$flag" ]]; then
    pretty_name="$(tr '[:lower:]' '[:upper:]' <<< "${flag:1:1}")${flag:2:-5}"
    echo -e "${GREEN}Detected flag: $pretty_name. Running $script...${NC}"
    chmod +x "$script"
    if [[ "$script" == "Setup-NixOS-25.05.sh" ]]; then
      timed nix-shell -p unzip --run "sudo bash $script"
    else
      timed sudo bash "$script"
    fi
    exit 0
  fi
done

# No flags found — show prompt
echo -e "${YELLOW}No setup flag found. Choose a setup script to run:${NC}"
PS3="Select a number: "
select script in "${scripts[@]}" "Exit"; do
  if [[ "$script" == "Exit" ]]; then
    echo -e "${GREEN}Exiting.${NC}"
    exit 0
  elif [[ -n "$script" ]]; then
    if [[ ! -f "$script" ]]; then
      echo -e "${RED}Script $script not found. Exiting.${NC}"
      exit 1
    fi
    echo -e "${GREEN}Running $script...${NC}"
    chmod +x "$script"
    if [[ "$script" == "Setup-NixOS-25.05.sh" ]]; then
      timed nix-shell -p unzip --run "sudo bash $script"
    else
      timed sudo bash "$script"
    fi
    break
  else
    echo -e "${RED}Invalid choice. Try again.${NC}"
  fi
done

