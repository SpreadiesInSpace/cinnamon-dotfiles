# .bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '

# Correct gedit embedded gnome-terminal path
if [[ $(ps -o comm= $PPID) == "gedit" ]]; then
  cd ~
fi

# Ignore History with Space
HISTCONTROL=ignoreboth

# Bottom Gruvbox Color Scheme
alias btm='btm --theme gruvbox'

# Void Cleaning
alias cleanAll='flatpak remove --unused; sudo flatpak repair; sudo xbps-remove -yROo; sudo vkpurge rm all; rm -rf ~/.cache/*; sudo rm -rf /var/cache/xbps; sudo bleachbit -c --preset && bleachbit -c --preset'
 
# Void Update
alias updateXdeb='${HOME}/update_xdeb.sh'
alias updateNeovim='nvim --headless "+Lazy! sync" +qa'
alias updateApp='sudo xbps-install -Su xbps && sudo xbps-install -Suvy; updateXdeb; flatpak update -y; updateNeovim'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; sudo reboot'
alias updateShutdown='updateAll; sudo poweroff'

# Update and Cleanup
alias UC='updateAll;sudo bleachbit;exit'

# Skip sourcing synth-shell-prompt if running in tty
if [[ $(tty) == /dev/tty[0-9]* ]]; then
    return
fi
