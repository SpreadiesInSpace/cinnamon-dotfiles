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

# PS1 Prompt
export PS1="\[\e[38;5;9m\][\[\e[38;5;11m\]\u\[\e[38;5;2m\]@\[\e[38;5;12m\]\h \[\e[38;5;5m\]\w\[\e[38;5;9m\]]\[\e[0m\]\$ "

# Ignore History with Space
HISTCONTROL=ignoreboth

# Bottom Gruvbox Color Scheme
alias btm='btm --color gruvbox'

# Fedora Cleaning
alias cleanExtra='sudo rpm -e --nodeps cinnamon-themes mint-x-icons mint-y-icons mint-y-theme mint-themes mint-themes-gtk3 mint-themes-gtk4; sudo rm -rf /var/lib/systemd/coredump/*; sudo rm -rf /var/tmp/.guestfs-1000/*; sudo rm -rf /var/cache/PackageKit/'
alias cleanAll='flatpak remove --unused; sudo flatpak repair; cleanExtra; yes | sudo dnf clean all | rm -rf ~/.cache/* | sudo journalctl --vacuum-size=50M | sudo journalctl --vacuum-time=4weeks | SystemMaxUse=50M | sudo bleachbit -c --preset && bleachbit -c --preset'
alias cleanKernel='sudo dnf remove $(dnf repoquery --installonly --latest-limit=-1 -q)'
 
# Fedora Update
alias updateNeovim='echo "Performing LazySync..."; nvim --headless "+Lazy! sync" +qa > /dev/null 2>&1; echo "LazySync complete!"'
alias updateApp='yes | sudo dnf upgrade && yes | sudo dnf autoremove; flatpak update -y; updateNeovim'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; systemctl reboot'
alias updateShutdown='updateAll; systemctl poweroff'

# Update and Cleanup
alias UC='updateAll;sudo bleachbit;exit'

# Skip Synth Shell prompt in virtual console or nvim's embedded terminal
if [[ $(tty) == /dev/tty[0-9]* ]] || [[ $(ps -h -o comm -p $PPID) == "nvim" ]]; then
    return
fi
