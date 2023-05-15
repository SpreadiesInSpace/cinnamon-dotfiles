# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Aliases
alias dir='dir --color=auto'
alias egrep='grep -E --color=auto'
alias fgrep='grep -F --color=auto'
alias fixpacman="sudo rm /var/lib/pacman/db.lck"
alias grep='grep --color=auto'
alias grubup="sudo update-grub"
alias hw='hwinfo --short'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'
alias psmem='ps auxf | sort -nr -k 4'
alias rmpkg="sudo pacman -Rdd"
alias tarnow='tar -acf '
alias untar='tar -zxvf '
alias upd='/usr/bin/update'
alias vdir='vdir --color=auto'
alias wget='wget -c '

# Ignore History with Space
HISTCONTROL=ignoreboth

# Arch Cleaning
alias cleanLint='bash rmlint.sh -d'
alias cleanCache='sudo pacman -Rns $(pacman -Qtdq)'
alias cleanAll='yes | sudo pacman -Scc && yes | rm -rf ~/.cache/* | sudo journalctl --vacuum-size=50M | sudo journalctl --vacuum-time=4weeks | SystemMaxUse=50M | rmlint | sudo bleachbit -c --preset && bleachbit -c --preset && cleanLint && cleanCache'

# Arch Update
alias yay='paru'
alias updateApp='yay'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; systemctl reboot'
alias updateShutdown='updateAll; systemctl poweroff'

# Update and Cleanup
alias UC='updateAll;sudo bleachbit;exit'

# Bottom Gruvbox Color Scheme
alias btm='btm --color gruvbox'

##-----------------------------------------------------
## synth-shell-prompt.sh
if [ -f /home/f16poom/.config/synth-shell/synth-shell-prompt.sh ] && [ -n "$( echo $- | grep i )" ]; then
	source /home/f16poom/.config/synth-shell/synth-shell-prompt.sh
fi
