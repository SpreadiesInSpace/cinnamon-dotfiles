# Terminal Title
PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'

# Bash Hostname
PS1="\[\033]0;\u@\h: \w\007\][\u@\h:\W]\$ "

# Ignore History with Space
HISTCONTROL=ignoreboth

# Update and Cleanup
alias UC='updateAll;sudo bleachbit;exit'

# Bottom Gruvbox Color Scheme
alias btm='${HOME}/.cargo/bin/btm --color gruvbox'

# Rmlint Cleaning
alias cleanLint='bash rmlint.sh -d && rmlint'

# Slackware Cleaning
alias cleanAll='sudo find /var/log -type f -name "*.log" -exec truncate -s 0 {} \; ; sudo sboclean -d ; sudo sboclean -w ; flatpak uninstall --unused ; rm -rf ~/.cache/*; sudo bleachbit -c --preset && bleachbit -c --preset'

# Slackware Update
alias updateApp='sudo slackpkg update; sudo slackpkg install-new; sudo slackpkg upgrade-all; sudo sbocheck; sudo sboupgrade --all; sudo grub-mkconfig -o /boot/grub/grub.cfg;flatpak update -y'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; sudo reboot'
alias updateShutdown='updateAll; sudo poweroff'
echo

##-----------------------------------------------------
## synth-shell-prompt.sh
if [ -f /home/f16poom/.config/synth-shell/synth-shell-prompt.sh ] && [ -n "$( echo $- | grep i )" ]; then
	source /home/f16poom/.config/synth-shell/synth-shell-prompt.sh
fi
