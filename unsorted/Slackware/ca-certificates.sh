#!/bin/bash

# Minimal Error Handling function
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

# Remove installed ca-certificates
sudo slpkg -Ry ca-certificates || \
	die "Failed to remove current ca-certificates."

# Install older ca-certificates
URL="https://slackware.uk/cumulative/slackware-current/slackware"
URL="$URL/n/ca-certificates-20250131-noarch-1.txz"
wget -c -T 10 -t 10 -q --show-progress "$URL" || \
	die "Failed to download ca-certificates package."
sudo installpkg ca-certificates-20250131-noarch-1.txz || \
	die "Failed to install ca-certificates package."
rm ca-certificates-20250131-noarch-1.txz || \
	die "Failed to remove ca-certificates package file."

# Blacklist ca-certificates
sudo sed -i 's/^\(PACKAGES *= *\["mint"\)\]/\1, "ca-certificates"]/' \
	/etc/slpkg/blacklist.toml

