#!/bin/bash

# Update Neovim to the latest version
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
chmod u+x nvim.appimage
./nvim.appimage --appimage-extract
./squashfs-root/AppRun --version
sudo rm -rf /squashfs-root/
sudo mv squashfs-root /
sudo rm -rf /usr/bin/nvim
sudo ln -s /squashfs-root/AppRun /usr/bin/nvim
rm nvim.appimage
