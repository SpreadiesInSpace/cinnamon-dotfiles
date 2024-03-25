# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
	for rc in ~/.bashrc.d/*; do
		if [ -f "$rc" ]; then
			. "$rc"
		fi
	done
fi

unset rc

# Ignore History with Space
HISTCONTROL=ignoreboth

# Bottom Gruvbox Color Scheme
alias btm='btm --color gruvbox'

# Rmlint Cleaning
alias cleanLint='bash rmlint.sh -d && rmlint'

# Fedora Cleaning
alias cleanGuestFS='sudo rm -rf /var/tmp/.guestfs-1000/*'
alias cleanAll='flatpak remove --unused;yes | sudo dnf clean all | cleanGuestFS | rm -rf ~/.cache/* | sudo journalctl --vacuum-size=50M | sudo journalctl --vacuum-time=4weeks | SystemMaxUse=50M | sudo bleachbit -c --preset && bleachbit -c --preset'
alias cleanKernel='sudo dnf remove $(dnf repoquery --installonly --latest-limit=-1 -q)'
 
# Fedora Update
alias updateApp='yes | sudo dnf upgrade && yes | sudo dnf autoremove; flatpak update -y'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; systemctl reboot'
alias updateShutdown='updateAll; systemctl poweroff'

# Update and Cleanup
alias UC='updateAll;sudo bleachbit;exit'

