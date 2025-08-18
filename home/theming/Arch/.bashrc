#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# PS1 Prompt
export PS1="\[\e[38;5;9m\][\[\e[38;5;11m\]\u\[\e[38;5;2m\]@\[\e[38;5;12m\]\h \
\[\e[38;5;5m\]\w\[\e[38;5;9m\]]\[\e[0m\]\$ "

# Ignore History with Space
HISTCONTROL=ignoreboth

# Bottom Gruvbox Color Scheme
alias btm='btm --theme gruvbox'

# Arch Cleaning
alias cleanCache='sudo pacman -Rns $(pacman -Qtdq)'
alias cleanAll='flatpak remove --unused; sudo flatpak repair; \
sudo rm -rf /var/lib/systemd/coredump/*; yes | sudo pacman -Scc && \
yes | rm -rf ~/.cache/* | sudo journalctl --vacuum-size=50M | \
sudo journalctl --vacuum-time=4weeks | SystemMaxUse=50M | \
sudo bleachbit -c --preset && bleachbit -c --preset && cleanCache'

# Arch Update
alias updateNeovim='echo "Performing LazySync..."; \
nvim --headless "+Lazy! sync" +qa > /dev/null 2>&1; \
echo "LazySync complete!"'
alias updateApp='yay; flatpak update -y; updateNeovim'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; systemctl reboot'
alias updateShutdown='updateAll; systemctl poweroff'

# Update and Cleanup
alias UC='updateAll;sudo bleachbit;exit'

# Skip Synth Shell prompt in virtual console or nvim's embedded terminal
if [[ $(tty) == /dev/tty[0-9]* ]] || \
	[[ $(ps -h -o comm -p $PPID) == "nvim" ]]; then
		return
fi
