# Terminal Title
PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'

# Bash Hostname
PS1="\[\033]0;\u@\h: \w\007\][\u@\h:\W]\$ "

# Ignore History with Space
HISTCONTROL=ignoreboth

# Bottom Gruvbox Color Scheme
alias btm='btm --color gruvbox'

# Puppy Cleaning
alias cleanLint='bash rmlint.sh -d;rm -rf ./rmlint.*'
alias cleanAll='yes | apt clean && yes | apt autoclean && yes | apt autoremove && yes | rm -rf ~/.cache/* | rm -rf ~/.history | sudo journalctl --vacuum-size=50M | sudo journalctl --vacuum-time=4weeks | SystemMaxUse=50M | rmlint | run-as-spot bleachbit -c --preset && bleachbit -c --preset && cleanLint'

# Puppy Update
alias updateApp='yes | apt update && yes | apt full-upgrade'
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
