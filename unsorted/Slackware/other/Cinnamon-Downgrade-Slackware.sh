#!/bin/bash

# Downgrade Cinnamon and dependencies to version 6.2.9
git clone https://github.com/SpreadiesInSpace/csb-629
cd csb-629
sudo installpkg *.txz
cd ..
rm -rf csb-629

# Disable csb repo
sudo sed -i '98s/ENABLE = true/ENABLE = false/' /etc/slpkg/repositories.toml

# Refresh cache
sudo slpkg -uy

# Switch back to Cinnamon 6.2.9 compatible applets
cd ../..
mkdir -p ~/.local/share/cinnamon/applets
mkdir -p ~/.local/share/cinnamon/applets.og
mv ~/.local/share/cinnamon/applets/* ~/.local/share/cinnamon/applets.og
cp -vnpr home/.local/share/cinnamon/applets/* ~/.local/share/cinnamon/applets/
cd unsorted/Slackware/ || exit
