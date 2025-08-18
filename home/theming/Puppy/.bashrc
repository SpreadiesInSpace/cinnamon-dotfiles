# Correct gedit embedded gnome-terminal path
if [[ $(ps -o comm= $PPID) == "gedit" ]]; then
  cd ~
fi

# PS1 Prompt
export PS1="\[\e[38;5;9m\][\[\e[38;5;11m\]\u\[\e[38;5;2m\]@\[\e[38;5;12m\]\h \[\e[38;5;5m\]\w\[\e[38;5;9m\]]\[\e[0m\]\$ "

# Ignore History with Space
HISTCONTROL=ignoreboth

# Bottom Gruvbox Color Scheme
alias btm='btm --theme gruvbox'

# Puppy Cleaning
alias cleanAll='flatpak remove --unused; sudo flatpak repair; yes | apt clean && yes | apt autoclean && yes | apt autoremove && yes | rm -rf ~/.cache/* | rm -rf ~/.history | sudo journalctl --vacuum-size=50M | sudo journalctl --vacuum-time=4weeks | SystemMaxUse=50M | sudo bleachbit -c --preset && bleachbit -c --preset'

# Puppy Update
alias updateNeovim='${HOME}/update_neovim.sh; echo "Performing LazySync..."; nvim --headless "+Lazy! sync" +qa > /dev/null 2>&1; echo "LazySync complete!"'
alias updateApp='yes | apt update && yes | apt full-upgrade; flatpak update -y; updateNeovim'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; reboot'
alias updateShutdown='updateAll; poweroff'
alias updateRam='save2flash'

# Update and Cleanup
alias UC='updateAll;run-as-spot bleachbit;exit'

# Remove History
rm -rf .history

# Skip Synth Shell prompt in virtual console or nvim's embedded terminal
if [[ $(tty) == /dev/tty[0-9]* ]] || [[ $(ps -h -o comm -p $PPID) == "nvim" ]]; then
    return
fi
