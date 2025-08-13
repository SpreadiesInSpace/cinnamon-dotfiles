#!/usr/bin/env bash

# Links to run this file:
# bash <(curl -sL https://tinyurl.com/cinnamon-theme)
# bash <(wget -qO- https://tinyurl.com/cinnamon-theme)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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
		cd home/ || { echo -e "${RED}Directory not found. Exiting.${NC}"; exit 1; }
		chmod +x "$script"
		bash "$script"
		exit 0
	fi
done

# No flags found — show prompt
echo -e "${YELLOW}No theme flag found. Choose a theme script to run:${NC}"
# Move to Theme Setup Scripts Directory
cd home/ || { echo -e "${RED}Directory not found. Exiting.${NC}"; exit 1; }
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
		bash "$script"
		break
	else
		echo -e "${RED}Invalid choice. Try again.${NC}"
	fi
done

