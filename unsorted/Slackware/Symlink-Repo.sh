#!/bin/bash

# Set up the shared Ponce repository directory
REPO_PATH="/var/lib/slpkg/repos/ponce"

# Clean up any existing directories or symlinks
sudo rm -rf /usr/sbo/repo
sudo rm -rf /var/lib/sbopkg/SBo-git
sudo rm -rf /var/lib/slpkg/repos/ponce

# Symlink sbotools directory to slpkg & clone ponce's repo
sudo sbosnap fetch
sudo mv /usr/sbo/repo/ $REPO_PATH
sudo ln -s $REPO_PATH /usr/sbo
sudo mv /usr/sbo/ponce /usr/sbo/repo

# Update slpkg to add metadata to the cloned ponce's repo
sudo slpkg update

# Create symlink for sbopkg
sudo ln -s $REPO_PATH /var/lib/sbopkg/SBo-git
# Configure sbopkg
sudo sed -i "s/REPO_BRANCH=\${REPO_BRANCH:-15.0}/REPO_BRANCH=\${REPO_BRANCH:-current}/g" \
  /etc/sbopkg/sbopkg.conf
sudo sed -i "s/REPO_NAME=\${REPO_NAME:-SBo}/REPO_NAME=\${REPO_NAME:-SBo-git}/g" \
  /etc/sbopkg/sbopkg.conf
# sync sbopkg (will delete metadata from others but still work)
# sudo sbopkg -r

