# Correct gedit embedded gnome-terminal path
if [[ $(ps -o comm= $PPID) == "gedit" ]]; then
  cd ~
fi

# PS1 Prompt
PS1="\[\e]0;\u@\h: \w\a\]$PS1"

# Ignore History with Space
HISTCONTROL=ignoreboth

# Bottom Gruvbox Color Scheme
alias btm='btm --theme gruvbox'

# Puppy Cleaning
alias cleanAll='flatpak remove --unused; sudo flatpak repair; yes | apt clean && yes | apt autoclean && yes | apt autoremove && yes | rm -rf ~/.cache/* | rm -rf ~/.history | sudo journalctl --vacuum-size=50M | sudo journalctl --vacuum-time=4weeks | SystemMaxUse=50M | sudo bleachbit -c --preset && bleachbit -c --preset'

# Puppy Update
alias updateNeovim='${HOME}/update_neovim.sh;nvim --headless "+Lazy! sync" +qa'
alias updateApp='yes | apt update && yes | apt full-upgrade; flatpak update -y; updateNeovim'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; reboot'
alias updateShutdown='updateAll; poweroff'
alias updateRam='save2flash'

# Update and Cleanup
alias UC='updateAll;run-as-spot bleachbit;exit'

# Remove History
rm -rf .history

# Skip sourcing synth-shell-prompt if running in tty
if [[ $(tty) == /dev/tty[0-9]* ]]; then
    return
fi
