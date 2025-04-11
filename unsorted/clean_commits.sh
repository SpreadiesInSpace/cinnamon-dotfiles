#!/bin/bash

# Go to cinnamon-dotfiles/ and remove git history
cd ..
rm -rf .git

# Initialize
git init
git remote add origin https://github.com/SpreadiesInSpace/cinnamon-dotfiles
git add .
git commit -m 'Clean Up'

# Set branch name from master to main then force push
git branch -m main
git push -f -u origin main
