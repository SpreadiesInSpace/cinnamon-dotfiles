# Sample .bashrc for SUSE Linux
# Copyright (c) SUSE Software Solutions Germany GmbH

# There are 3 different types of shells in bash: the login shell, normal shell
# and interactive shell. Login shells read ~/.profile and interactive shells
# read ~/.bashrc; in our setup, /etc/profile sources ~/.bashrc - thus all
# settings made here will also take effect in a login shell.
#
# NOTE: It is recommended to make language settings in ~/.profile rather than
# here, since multilingual X sessions would not work properly if LANG is over-
# ridden in every subshell.

test -s ~/.alias && . ~/.alias || true

# Ignore History with Space
HISTCONTROL=ignoreboth

# Bottom Gruvbox Color Scheme
alias btm='btm --theme gruvbox'

# Rmlint Cleaning
# alias cleanLint='bash rmlint.sh -d && rmlint'

# openSUSE Cleaning
alias cleanAll='sudo zypper rm *-lang *-doc; flatpak remove --unused; sudo flatpak repair; sudo zypper clean -a;sudo zypper purge-kernels; sudo snapper delete 1-100; rm -rf ~/.cache/*; sudo rm /tmp/* -rf; sudo journalctl --vacuum-size=50M; sudo journalctl --vacuum-time=4weeks; SystemMaxUse=50M; sudo bleachbit -c --preset && bleachbit -c --preset; sudo -E bleachbit; exit'

# openSUSE Update
alias updateNeovim='nvim --headless "+Lazy! sync" +qa'
alias updateApp='sudo zypper ref; sudo zypper dup; flatpak update -y; updateNeovim'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; systemctl reboot'
alias updateShutdown='updateAll; systemctl poweroff'

# Update and Cleanup
alias UC='updateAll;sudo bleachbit;exit'

# Skip sourcing .bashrc if running in tty
if [[ $(tty) == /dev/tty[0-9]* ]]; then
  return
fi