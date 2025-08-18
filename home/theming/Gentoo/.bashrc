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

# PS1 Prompt
export PS1="\[\e[38;5;9m\][\[\e[38;5;11m\]\u\[\e[38;5;2m\]@\[\e[38;5;12m\]\h \[\e[38;5;5m\]\w\[\e[38;5;9m\]]\[\e[0m\]\$ "

# Ignore History with Space
HISTCONTROL=ignoreboth

# Update and Cleanup
alias UC='updateAll;sudo bleachbit;exit'

# Bottom Gruvbox Color Scheme
alias btm='btm --theme gruvbox'

# Gentoo Cleaning
alias cleanAll='sudo emerge -aq --depclean; flatpak remove --unused; sudo flatpak repair; sudo rm -rf /var/lib/systemd/coredump/*; yes | rm -rf ~/.cache/* | sudo rm -rf /var/tmp/portage/ | sudo rm -rf /var/cache/distfiles/ | sudo rm -rf /var/cache/binpkgs/ | sudo eclean-dist --destructive | sudo eclean-pkg | sudo journalctl --vacuum-size=50M | sudo journalctl --vacuum-time=4weeks | SystemMaxUse=50M | sudo bleachbit -c --preset && bleachbit -c --preset'
alias cleanKernel='sudo eclean-kernel -a'
 
# Gentoo Update
alias updateSync='sudo emaint -a sync'
alias updatePortage='sudo emerge --oneshot sys-apps/portage'
alias updateNeovim='echo "Performing LazySync..."; nvim --headless "+Lazy! sync" +qa > /dev/null 2>&1; echo "LazySync complete!"'
alias updateApp='updateSync; sudo emerge -avqDuN --with-bdeps=y @world; flatpak update -y; updateNeovim; sudo grub-mkconfig -o /boot/grub/grub.cfg'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; systemctl reboot'
alias updateShutdown='updateAll; systemctl poweroff'

# Skip Synth Shell prompt in virtual console or nvim's embedded terminal
if [[ $(tty) == /dev/tty[0-9]* ]] || [[ $(ps -h -o comm -p $PPID) == "nvim" ]]; then
    return
fi
