#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run the script using sudo."
  exit
fi

# Old slpkg version needed this
touch /var/log/slpkg/deps.log || die "Failed to create deps.log"

# Replace Slackware Current's appstream-glib with gfs for file-roller (GFS 46.x)
# -O avoids pulling in dependencies like the entire Gnome DE
slpkg install -y gnome-terminal -o gnome -O  || die "Failed to install gnome-terminal."

# Install Self-Compiled qemu from SBo
git clone https://github.com/spreadiesinspace/qemu || die "Failed to download QEMU."
cd qemu/
./install.sh || die "Failed to install QEMU."
cd ..
rm -rf qemu/

# Workaround for gedit-plugins to compile (GFS 46, broken)
slpkg install -y libpeas gedit-plugins || die "Failed to install libpeas gedit-plugins."
slpkg install -y libpeas -o gnome || die "Failed to install libpeas for gnome."