# .bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '

# Correct gedit embedded gnome-terminal path
if [[ $(ps -o comm= $PPID) == "gedit" ]]; then
	cd ~
fi

# PS1 Prompt
export PS1="\[\e[38;5;9m\][\[\e[38;5;11m\]\u\[\e[38;5;2m\]@\[\e[38;5;12m\]\h \
\[\e[38;5;5m\]\w\[\e[38;5;9m\]]\[\e[0m\]\$ "

# Ignore History with Space
HISTCONTROL=ignoreboth

# Bottom Gruvbox Color Scheme
alias btm='btm --theme gruvbox'

# Elevated Power Actions
alias poweroff='loginctl poweroff'
alias reboot='loginctl reboot'

# Void Cleaning
alias cleanAll='flatpak remove --unused; sudo flatpak repair; \
sudo xbps-remove -yROo; sudo vkpurge rm all; rm -rf ~/.cache/*; \
sudo rm -rf /var/cache/xbps; \
sudo bleachbit -c --preset && bleachbit -c --preset'

# Void Update
alias updateXdeb='${HOME}/update_xdeb.sh'
alias updateNeovim='echo "Performing LazySync..."; \
nvim --headless "+Lazy! sync" +qa > /dev/null 2>&1; \
echo "LazySync complete!"'
alias updateApp='sudo xbps-install -Su xbps && sudo xbps-install -Suvy; \
updateXdeb; flatpak update -y; updateNeovim'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; reboot'
alias updateShutdown='updateAll; poweroff'

# Update and Cleanup
alias UC='updateAll;sudo bleachbit;exit'

# Skip Synth Shell prompt in virtual console or nvim's embedded terminal
if [[ $(tty) == /dev/tty[0-9]* ]] || \
	[[ $(ps -h -o comm -p $PPID) == "nvim" ]]; then
		return
fi
