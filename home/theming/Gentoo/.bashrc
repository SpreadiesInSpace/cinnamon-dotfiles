# /etc/skel/.bashrc
#
# This file is sourced by all *interactive* bash shells on startup,
# including some apparently interactive shells such as scp and rcp
# that can't tolerate any output.  So make sure this doesn't display
# anything or bad things will happen !


# Test for an interactive shell.  There is no need to set anything
# past this point for scp and rcp, and it's important to refrain from
# outputting anything in those cases.
if [[ $- != *i* ]] ; then
	# Shell is non-interactive.  Be done now!
	return
fi

# Put your fun stuff here.

# Terminal Title
PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'

# Bash Hostname
PS1="\[\033]0;\u@\h: \w\007\][\u@\h:\W]\$ "

# Ignore History with Space
HISTCONTROL=ignoreboth

# virsh net-autostart default --disable
alias netFix='sudo nmcli networking off & sudo nmcli networking on'

# Update and Cleanup
alias UC='updateAll;sudo bleachbit;exit'

# Bottom Gruvbox Color Scheme
alias btm='btm --theme gruvbox'

# Rmlint Cleaning
# alias cleanLint='bash rmlint.sh -d && rmlint'

# Gentoo Cleaning
alias cleanAll='sudo emerge -aq --depclean; flatpak remove --unused; sudo flatpak repair; sudo rm -rf /var/lib/systemd/coredump/*; yes | rm -rf ~/.cache/* | sudo rm -rf /var/tmp/portage/ | sudo rm -rf /var/cache/distfiles/ | sudo rm -rf /var/cache/binpkgs/ | sudo eclean-dist --destructive | sudo eclean-pkg | sudo journalctl --vacuum-size=50M | sudo journalctl --vacuum-time=4weeks | SystemMaxUse=50M | sudo bleachbit -c --preset && bleachbit -c --preset'
alias cleanKernel='sudo eclean-kernel -a'
 
# Gentoo Update
alias updateSync='sudo emaint -a sync'
alias updatePortage='sudo emerge --oneshot sys-apps/portage'
alias updateNeovim='nvim --headless "+Lazy! sync" +qa'
alias updateApp='updateSync; sudo emerge -avqDuN --with-bdeps=y @world; flatpak update -y; updateNeovim; sudo grub-mkconfig -o /boot/grub/grub.cfg'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; systemctl reboot'
alias updateShutdown='updateAll; systemctl poweroff'

# Skip sourcing synth-shell-prompt if running in tty
if [[ $(tty) == /dev/tty[0-9]* ]]; then
    return
fi
