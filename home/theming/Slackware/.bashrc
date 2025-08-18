# Correct gedit embedded gnome-terminal path
if [[ $(ps -o comm= $PPID) == "gedit" ]]; then
	cd ~
fi

# PS1 Prompt
export PS1="\[\e[38;5;9m\][\[\e[38;5;11m\]\u\[\e[38;5;2m\]@\[\e[38;5;12m\]\h \
\[\e[38;5;5m\]\w\[\e[38;5;9m\]]\[\e[0m\]\$ "

# Ignore History with Space
HISTCONTROL=ignoreboth

# Update and Cleanup
alias UC='updateAll;sudo bleachbit;exit'

# Bottom Gruvbox Color Scheme
alias btm='btm --theme gruvbox'

# Slackware Cleaning
alias cleanAll='sudo find /var/log -type f -name "*.log" -exec truncate -s 0 \
{} \;; sudo sboclean -d; sudo sboclean -w; sudo slpkg -T; \
flatpak uninstall --unused; sudo flatpak repair; rm -rf ~/.cache/*; \
sudo bleachbit -c --preset && bleachbit -c --preset'

# Slackware Update
updateSlpkg() {
	sudo slpkg update
	sudo slpkg upgrade -P -B
	for repo in slack slack_extra csb conraid alien gnome slint; do
		sudo slpkg upgrade -P -B -o "$repo"
	done
}
alias updateNeovim='echo "Performing LazySync..."; \
nvim --headless "+Lazy! sync" +qa > /dev/null 2>&1; \
echo "LazySync complete!"'
alias updateApp='sudo sbocheck; sudo sboupgrade --all; updateSlpkg; \
sudo grub-mkconfig -o /boot/grub/grub.cfg; flatpak update -y; updateNeovim'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; sudo reboot'
alias updateShutdown='updateAll; sudo poweroff'

# Skip Synth Shell prompt in virtual console or nvim's embedded terminal
if [[ $(tty) == /dev/tty[0-9]* ]] || \
	[[ $(ps -h -o comm -p $PPID) == "nvim" ]]; then
		return
fi
