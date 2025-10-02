#!/bin/bash

# Minimal Error Handling function
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

# Install mozjs128
URL="https://slackware.uk/cumulative/slackware64-current"
URL="$URL/slackware64/l/mozjs128-128.14.0esr-x86_64-1.txz"
wget -c -T 10 -t 10 -q --show-progress "$URL" || \
  die "Failed to download ca-certificates package."
sudo installpkg mozjs128-128.14.0esr-x86_64-1.txz || \
  die "Failed to install ca-certificates package."
rm mozjs128-128.14.0esr-x86_64-1.txz || \
  die "Failed to remove ca-certificates package file."

# Blacklist mozjs128 from being deleted (slpkg)
sudo sed -i 's/^\(PACKAGES *= *\["mint"\)\]/\1, "mozjs128"]/' \
  /etc/slpkg/blacklist.toml

# Blacklist mozjs128 for slackpkg
if ! grep -q "^mozjs128$" /etc/slackpkg/blacklist 2>/dev/null; then
  echo "mozjs128" | sudo tee -a /etc/slackpkg/blacklist > /dev/null || \
    die "Failed to add mozjs128 to slackpkg blacklist."
fi
