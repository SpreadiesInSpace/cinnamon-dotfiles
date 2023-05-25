# Enable Bash Completion
[[ $PS1 && -f /usr/local/share/bash-completion/bash_completion.sh ]] && \
	source /usr/local/share/bash-completion/bash_completion.sh

# Terminal Title
PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'
 
# Bash Hostname
PS1="\[\033]0;\u@\h: \w\007\][\u@\h:\W]\$ "
 
# Ignore History with Space
HISTCONTROL=ignoreboth
 
# Bottom Gruvbox Color Scheme
alias btm='btm --color gruvbox'

# FreeBSD Cleaning
alias bleachRoot='cd /home/f16poom/.local/share/applications/bleachbit; sudo python3 bleachbit.py'
alias bleachbit='cd /home/f16poom/.local/share/applications/bleachbit; python3 bleachbit.py'
alias cleanLint='rmlint; bash rmlint.sh -d'
alias cleanAll='sudo pkg clean; sudo pkg clean -a; sudo pkg autoremove;cleanLint; rm -rf ~/.cache/* SystemMaxUse=50M | bleachRoot -c --preset; bleachbit -c --preset | bleachRoot;exit'
 
# FreeBSD Update
alias updateApp='cd ./linux-browser-installer/;sudo ./linux-browser-installer chroot upgrade;sudo ./linux-browser-installer clean;cd;sudo freebsd-update fetch; sudo freebsd-update install; sudo pkg upgrade'
alias updateAll='updateApp; cleanAll'
alias updateRestart='updateAll | sudo init 6'
alias updateShutdown='updateAll | sudo poweroff'

# Update and Cleanup
alias UC='updateAll;sudo bleachbit;exit'

function _update_ps1() {
    PS1=$(powerline-shell $?)
}

echo

if [[ $TERM != linux && ! $PROMPT_COMMAND =~ _update_ps1 ]]; then
   PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
fi
