# Correct gedit embedded gnome-terminal path
if [[ $(ps -o comm= $PPID) == "gedit" ]]; then
  cd ~
fi

# Terminal Title
PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'

# Bash Hostname
PS1="\[\033]0;\u@\h: \w\007\][\u@\h:\W]\$ "

# Ignore History with Space
HISTCONTROL=ignoreboth

# Update and Cleanup
alias UC='updateAll;sudo bleachbit;exit'

# Bottom Gruvbox Color Scheme
alias btm='btm --theme gruvbox'

# Rmlint Cleaning
# alias cleanLint='bash rmlint.sh -d && rmlint'

# Slackware Cleaning
alias cleanAll='sudo find /var/log -type f -name "*.log" -exec truncate -s 0 {} \;; sudo sboclean -d; sudo sboclean -w; sudo slpkg -T; flatpak uninstall --unused; sudo flatpak repair; rm -rf ~/.cache/*; sudo bleachbit -c --preset && bleachbit -c --preset'

# Slackware Update
# alias updateNeovim='${HOME}/update_neovim.sh;nvim --headless "+Lazy! sync" +qa'
alias updateApp='sudo sbocheck; sudo sboupgrade --all; sudo slpkg -u; sudo slpkg -U; sudo slpkg -U -o "slack"; sudo slpkg -U -o "slack_extra"; sudo slpkg -U -o "csb"; sudo slpkg -U -o "conraid"; sudo slpkg -U -o "alien"; sudo slpkg -U -o "restricted"; sudo slpkg -U -o "gnome"; sudo grub-mkconfig -o /boot/grub/grub.cfg; flatpak update -y'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; sudo reboot'
alias updateShutdown='updateAll; sudo poweroff'

# Skip sourcing .bashrc if running in tty
if [[ $(tty) == /dev/tty[0-9]* ]]; then
  return
fi
