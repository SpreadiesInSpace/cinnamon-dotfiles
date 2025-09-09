#!/bin/bash

# Minimal Error Handling function
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  die "Please run the script as superuser."
fi

# Temporary downgrade glib2 and blacklist from updating
glib2="https://slackware.uk/cumulative/slackware64-current/slackware64"
glib2="$glib2/l/glib2-2.84.4-x86_64-1.txz"
wget -c -T 10 -t 10 -q --show-progress "$glib2" || \
  die "Failed to download glib2 package."
installpkg glib2-2.84.4-x86_64-1.txz || \
  die "Failed to install glib2 package."
rm glib2-2.84.4-x86_64-1.txz || \
  die "Failed to remove glib2 package file."
sed -i 's/^\(PACKAGES *= *\["mint"\)\]/\1, "glib2"]/' \
  /etc/slpkg/blacklist.toml || \
  die "Failed to blacklist glib2."