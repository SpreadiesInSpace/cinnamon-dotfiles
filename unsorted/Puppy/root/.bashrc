# Terminal Title
PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'

# Bash Hostname
PS1="\[\033]0;\u@\h: \w\007\][\u@\h:\W]\$ "

# Ignore History with Space
HISTCONTROL=ignoreboth

# Bottom Gruvbox Color Scheme
alias btm='btm --color gruvbox'

# Rmlint Cleaning
alias cleanLint='bash rmlint.sh -d && rmlint'

# Puppy Cleaning
alias cleanAll='flatpak remove --unused;yes | apt clean && yes | apt autoclean && yes | apt autoremove && yes | rm -rf ~/.cache/* | rm -rf ~/.history | sudo journalctl --vacuum-size=50M | sudo journalctl --vacuum-time=4weeks | SystemMaxUse=50M | sudo bleachbit -c --preset && bleachbit -c --preset'

# Puppy Update
alias updateNeovim='nvim --headless "+Lazy! sync" +qa'
alias updateApp='yes | apt update && yes | apt full-upgrade; flatpak update -y; updateNeovim'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; reboot'
alias updateShutdown='updateAll; poweroff'
alias updateRam='save2flash'

# Update and Cleanup
alias UC='updateAll;run-as-spot bleachbit;exit'

# Remove History
rm -rf .history

##-----------------------------------------------------
## synth-shell-prompt.sh
if [ -f /root/.config/synth-shell/synth-shell-prompt.sh ] && [ -n "$( echo $- | grep i )" ]; then
	source /root/.config/synth-shell/synth-shell-prompt.sh
fi
