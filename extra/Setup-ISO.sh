#!/bin/bash

# Links to run this file:
# bash <(curl -sL https://tinyurl.com/cinnamon-ISO)
# bash <(wget -qO- https://tinyurl.com/cinnamon-ISO)

# Other Shortened Links:
# https://tinyurl.com/cinnamon-ISO (this file)
# https://tinyurl.com/cinnamon-setup (Setup.sh)
# https://tinyurl.com/cinnamon-dotfiles (this repo)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Install script URLs and names
URL="https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles"
declare -A installs=(
	[1]="$URL/refs/heads/main/extra/ISO/Install-Arch.sh"
	[2]="$URL/refs/heads/main/extra/ISO/Install-Gentoo.sh"
	[3]="$URL/refs/heads/main/extra/ISO/Install-NixOS-25.05.sh"
	[4]="$URL/refs/heads/main/extra/ISO/Install-openSUSE-Tumbleweed.sh"
	[5]="$URL/refs/heads/main/extra/ISO/Install-Slackware-Current.sh"
	[6]="$URL/refs/heads/main/extra/ISO/Install-Void.sh"
)

declare -A names=(
	[1]="Install-Arch.sh"
	[2]="Install-Gentoo"
	[3]="Install-NixOS-25.05.sh"
	[4]="Install-openSUSE-Tumbleweed.sh"
	[5]="Install-Slackware-Current.sh"
	[6]="Install-Void.sh"
)

# Prompt menu
echo -e "${YELLOW}Which installer would you like to run?${NC}"
options=(
	"Arch Linux"
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
		[1-6])
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

			if [[ "$REPLY" == "5" ]]; then
				bash "$filename"  # Slackware: run non-sudo
			else
				sudo bash "$filename"
			fi
			break
			;;
		7)
			echo -e "${GREEN}Exiting.${NC}"
			exit 0
			;;
		*)
			echo -e "${RED}Invalid choice. Try again.${NC}"
			;;
	esac
done
