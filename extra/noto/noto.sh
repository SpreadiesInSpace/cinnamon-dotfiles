#!/bin/bash

# Install Noto Fonts
sudo rm -rf /usr/share/fonts/noto/
sudo git clone --depth=1 https://github.com/SpreadiesInSpace/noto /usr/share/fonts/noto
sudo rm -rf /usr/share/fonts/noto/.git
