# Correct gedit embedded gnome-terminal path
if [[ $(ps -o comm= $PPID) == "gedit" ]]; then
  cd ~
fi

# Ignore History with Space
HISTCONTROL=ignoreboth

# Update and Cleanup
alias UC='updateAll;sudo bleachbit;exit'

# Bottom Gruvbox Color Scheme
alias btm='btm --theme gruvbox'

# Slackware Cleaning
alias cleanAll='sudo find /var/log -type f -name "*.log" -exec truncate -s 0 {} \;; sudo sboclean -d; sudo sboclean -w; sudo slpkg -T; flatpak uninstall --unused; sudo flatpak repair; rm -rf ~/.cache/*; sudo bleachbit -c --preset && bleachbit -c --preset'

# Slackware Update
alias updateNeovim='echo "Performing LazySync..."; nvim --headless "+Lazy! sync" +qa > /dev/null 2>&1; echo "LazySync complete!"'
alias updateApp='sudo sbocheck; sudo sboupgrade --all; sudo slpkg -u; sudo slpkg -U; sudo slpkg -U -o "slack"; sudo slpkg -U -o "slack_extra"; sudo slpkg -U -o "csb"; sudo slpkg -U -o "conraid"; sudo slpkg -U -o "alien"; sudo slpkg -U -o "gnome"; sudo slpkg -U -o "slint"; sudo grub-mkconfig -o /boot/grub/grub.cfg; flatpak update -y'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; sudo reboot'
alias updateShutdown='updateAll; sudo poweroff'

# Skip sourcing synth-shell-prompt if running in tty
if [[ $(tty) == /dev/tty[0-9]* ]]; then
    return
fi

