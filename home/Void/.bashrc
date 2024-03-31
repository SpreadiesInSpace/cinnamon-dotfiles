# .bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '

# Terminal Title
PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'

# Ignore History with Space
HISTCONTROL=ignoreboth

# Bottom Gruvbox Color Scheme
alias btm='btm --color gruvbox'

# Rmlint Cleaning
alias cleanLint='bash rmlint.sh -d && rmlint'

# Void Cleaning
alias cleanAll='flatpak remove --unused; sudo xbps-remove -yROo; sudo vkpurge rm all; rm -rf ~/.cache/*; sudo rm -rf /var/cache/xbps; sudo bleachbit -c --preset && bleachbit -c --preset'
 
# Void Update
alias updateBrave='${HOME}/brave_updates.sh'
alias updateApp='sudo xbps-install -Su xbps && sudo xbps-install -Suvy; updateBrave; flatpak update -y'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; sudo reboot'
alias updateShutdown='updateAll; sudo poweroff'

# Update and Cleanup
alias UC='updateAll;sudo bleachbit;exit'
