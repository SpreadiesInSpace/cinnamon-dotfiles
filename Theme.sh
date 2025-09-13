#!/usr/bin/env bash

# Links to run this file:
# bash <(curl -sL https://tinyurl.com/cinnamon-theme)
# bash <(wget -qO- https://tinyurl.com/cinnamon-theme)

# PWD Check
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }
[[ "$(basename "$PWD")" == "cinnamon-dotfiles" ]] || \
  die "Run from cinnamon-dotfiles directory."

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

# Theme script list
scripts=(
  "Setup-Arch-Theme.sh"
  "Setup-Fedora-Theme.sh"
  "Setup-Gentoo-Theme.sh"
  "Setup-LMDE-Theme.sh"
  "Setup-NixOS-Theme.sh"
  "Setup-OpenSUSE-Theme.sh"
  "Setup-Slackware-Current-Theme.sh"
  "Setup-Void-Theme.sh"
)

# Flag check
for script in "${scripts[@]}"; do
  base="${script,,}" # lowercase
  flag="${base//setup-/}" # remove prefix
  flag=".${flag%%-theme.sh}.done" # trim suffix and prepend dot
  if [[ -f "$(dirname "$0")/$flag" ]]; then
    pretty_name="$(tr '[:lower:]' '[:upper:]' <<< "${flag:1:1}")${flag:2:-5}"
    echo -e "${GREEN}Detected flag: $pretty_name. Running $script...${NC}"
    # Move to Theme Setup Scripts Directory
    cd home/ || die "Directory 'home/' not found."
    [[ -f "$script" ]] || die "Script '$script' not found in home/ directory."
    chmod +x "$script" || die "Failed to make '$script' executable."
    timed bash "$script"
    exit 0
  fi
done

# No flags found — show prompt
echo -e "${YELLOW}No theme flag found. Choose a theme script to run:${NC}"
# Move to Theme Setup Scripts Directory
cd home/ || die "Directory 'home/' not found."
PS3="Select a number: "
select script in "${scripts[@]}" "Exit"; do
  if [[ "$script" == "Exit" ]]; then
    echo -e "${GREEN}Exiting.${NC}"
    exit 0
  elif [[ -n "$script" ]]; then
    [[ -f "$script" ]] || die "Script '$script' not found in home/ directory."
    echo -e "${GREEN}Running $script...${NC}"
    chmod +x "$script" || die "Failed to make '$script' executable."
    timed bash "$script"
    break
  else
    echo -e "${RED}Invalid choice. Try again.${NC}"
  fi
done

