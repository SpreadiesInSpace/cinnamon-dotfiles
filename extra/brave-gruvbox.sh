#!/bin/bash

# Backup Existing Brave Profile
mv ~/.config/BraveSoftware/ ~/.config/BraveSoftware.bak/

# Clone Brave Gruvbox Example Profile
git clone https://github.com/spreadiesinspace/BraveSoftware ~/.config/BraveSoftware
rm -rf ~/.config/BraveSoftware/.git/
