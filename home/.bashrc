# Terminal Title
PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'

# Bash Hostname
PS1="\[\033]0;\u@\h: \w\007\][\u@\h:\W]\$ "

# Ignore History with Space
HISTCONTROL=ignoreboth

# Update and Cleanup
alias UC='updateAll;sudo bleachbit;exit'

# Bottom Gruvbox Color Scheme
alias btm='btm --color gruvbox'

# Arch Cleaning
alias cleanLint='bash rmlint.sh -d'
alias cleanCache='sudo pacman -Rns $(pacman -Qtdq)'
alias cleanAll='yes | sudo pacman -Scc && yes | rm -rf ~/.cache/* | sudo journalctl --vacuum-size=50M | sudo journalctl --vacuum-time=4weeks | SystemMaxUse=50M | rmlint | sudo bleachbit -c --preset && bleachbit -c --preset && cleanLint && cleanCache'

# Arch Update
alias updateApp='yay'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; systemctl reboot'
alias updateShutdown='updateAll; systemctl poweroff'

# Debian Cleaning
alias cleanLint='bash rmlint.sh -d;rm -rf ./rmlint.*'
alias cleanAll='yes | sudo apt clean && yes | sudo apt autoclean && yes | sudo apt autoremove && yes | rm -rf ~/.cache/* | sudo journalctl --vacuum-size=50M | sudo journalctl --vacuum-time=4weeks | SystemMaxUse=50M | rmlint | sudo bleachbit -c --preset && bleachbit -c --preset && cleanLint'

# Debian Update (Tien)
alias updateApp='yes | sudo apt update && yes | sudo apt full-upgrade'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; systemctl reboot'
alias updateShutdown='updateAll; systemctl poweroff'

# Fedora Cleaning
alias cleanLint='bash rmlint.sh -d'
alias cleanAll='yes | sudo dnf clean all | rm -rf ~/.cache/* | sudo journalctl --vacuum-size=50M | sudo journalctl --vacuum-time=4weeks | SystemMaxUse=50M | rmlint | sudo bleachbit -c --preset && bleachbit -c --preset && cleanLint'
alias cleanKernel='sudo dnf remove $(dnf repoquery --installonly --latest-limit=-1 -q)'
 
# Fedora Update
alias updateApp='yes | sudo dnf upgrade && yes | sudo dnf autoremove'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; systemctl reboot'
alias updateShutdown='updateAll; systemctl poweroff'

# FreeBSD Cleaning
alias bleachRoot='cd /home/f16poom/.local/share/applications/bleachbit; sudo python3 bleachbit.py'
alias bleachbit='cd /home/f16poom/.local/share/applications/bleachbit; python3 bleachbit.py'
alias cleanLint='rmlint; bash rmlint.sh -d'
alias cleanAll='sudo pkg clean; sudo pkg clean -a; sudo pkg autoremove; sudo portsnap auto;cleanLint; rm -rf ~/.cache/* SystemMaxUse=50M | bleachRoot -c --preset; bleachbit -c --preset | bleachRoot;exit'
 
# FreeBSD Update
alias updateApp='cd ./linux-browser-installer/;sudo ./linux-browser-installer chroot upgrade;sudo ./linux-browser-installer clean;cd;sudo freebsd-update fetch; sudo freebsd-update install; sudo pkg upgrade'
alias updateAll='updateApp; cleanAll'
alias updateRestart='updateAll | sudo init 6'
alias updateShutdown='updateAll | sudo poweroff'

# Gentoo Cleaning
alias cleanLint='bash rmlint.sh -d'
alias cleanAll='sudo emerge -a --depclean; flatpak remove --unused; yes | rm -rf ~/.cache/* | sudo rm -rf /var/tmp/portage/ | sudo rm -rf /var/cache/distfiles/ | sudo rm -rf /var/cache/binpkgs/ | sudo eclean-dist --destructive | sudo eclean-pkg | sudo journalctl --vacuum-size=50M | sudo journalctl --vacuum-time=4weeks | SystemMaxUse=50M | rmlint | sudo bleachbit -c --preset && bleachbit -c --preset && cleanLint'
alias cleanKernel='sudo eclean-kernel -a'
 
# Gentoo Update
alias updateSync='sudo emaint -a sync;'
alias updatePortage='sudo emerge --oneshot sys-apps/portage'
alias updateApp='sudo emerge -avDuN --with-bdeps=y @world; flatpak update -y'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; systemctl reboot'
alias updateShutdown='updateAll; systemctl poweroff'

# Manjaro Cleaning
alias cleanLint='bash rmlint.sh -d'
alias cleanCache='sudo pacman -Rns $(pacman -Qtdq)'
alias cleanAll='yes | sudo pamac clean && yes | sudo pacman -Scc && yes | rm -rf ~/.cache/* | sudo journalctl --vacuum-size=50M | sudo journalctl --vacuum-time=4weeks | SystemMaxUse=50M | rmlint | sudo bleachbit -c --preset && bleachbit -c --preset && cleanLint && cleanCache'
 
# Manjaro Update
alias updateApp='sudo pamac checkupdates; sudo pamac update'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; systemctl reboot'
alias updateShutdown='updateAll; systemctl poweroff'

# NixOS Cleaning
alias cleanLint='bash rmlint.sh -d'
alias cleanAll='flatpak remove --unused;rm -rf ~/.cache/*; sudo rm /nix/var/nix/gcroots/auto/*; sudo nix-collect-garbage -d; nix-collect-garbage -d; sudo nix-store --optimise; nix-store --optimise; sudo nix-env -p /nix/var/nix/profiles/system --delete-generations old; sudo nix-env --delete-generations old; nix-env --delete-generations old; sudo journalctl --flush --rotate;sudo journalctl --vacuum-time=1s; rmlint; sudo bleachbit -c --preset && bleachbit -c --preset && cleanLint'

# NixOS Update
alias updateApp='sudo nixos-rebuild switch --upgrade; flatpak update -y'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; reboot'
alias updateShutdown='updateAll; poweroff'

# NixOS Neofetch
alias neofetch='neofetch --ascii /home/f16poom/Temp\ Files/NixAscii.txt'

# openSUSE Cleaning
alias cleanLint='bash rmlint.sh -d'
alias cleanAll='sudo zypper clean -a;sudo zypper purge-kernels; sudo snapper delete 1-100; rm -rf ~/.cache/*; sudo rm /tmp/* -rf; sudo journalctl --vacuum-size=50M; sudo journalctl --vacuum-time=4weeks; SystemMaxUse=50M; rmlint; sudo bleachbit -c --preset && bleachbit -c --preset && cleanLint; xdg-su -u root -c bleachbit; exit'
 
# openSUSE Update
alias updateApp='sudo zypper ref; sudo zypper up'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; systemctl reboot'
alias updateShutdown='updateAll; systemctl poweroff'

# Puppy Cleaning
alias cleanLint='bash rmlint.sh -d;rm -rf ./rmlint.*'
alias cleanAll='yes | apt clean && yes | apt autoclean && yes | apt autoremove && yes | rm -rf ~/.cache/* | rm -rf ~/.history | sudo journalctl --vacuum-size=50M | sudo journalctl --vacuum-time=4weeks | SystemMaxUse=50M | rmlint | sudo bleachbit -c --preset && bleachbit -c --preset && cleanLint'

# Puppy Update
alias updateApp='yes | apt update && yes | apt full-upgrade'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; reboot'
alias updateShutdown='updateAll; poweroff'
alias updateRam='save2flash'
 
# Slackware Cleaning
alias cleanLint='bash rmlint.sh -d'
alias cleanAll='sudo find /var/log -type f -name '*.log' -exec truncate -s 0 {} \;; sudo rm -rf /tmp/*; sudo sboclean -d; sudo sboclean -w; flatpak uninstall --unused; yes | rm -rf ~/.cache/* | rmlint | sudo bleachbit -c --preset && bleachbit -c --preset && cleanLint'
 
# Slackware Update
alias updateApp='sudo slackpkg update; sudo slackpkg upgrade-all; sudo sbocheck; sudo sboupgrade --all; flatpak update -y'
alias updateAll='updateApp && cleanAll'

# Void Cleaning
alias cleanLint='bash rmlint.sh -d'
alias cleanAll='flatpak remove --unused; sudo xbps-remove -yOo; sudo vkpurge rm all; rm -rf ~/.cache/*; sudo rm -rf /var/cache/xbps; rmlint; sudo bleachbit -c --preset && bleachbit -c --preset && cleanLint'
 
# Void Update
alias updateApp='sudo xbps-install -Suy; flatpak update -y'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; sudo reboot'
alias updateShutdown='updateAll; sudo poweroff'
