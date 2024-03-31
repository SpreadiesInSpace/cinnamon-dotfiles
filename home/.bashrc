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

# Rmlint Cleaning
alias cleanLint='bash rmlint.sh -d && rmlint'

# Arch Cleaning
alias cleanCache='sudo pacman -Rns $(pacman -Qtdq)'
alias cleanAll='flatpak remove --unused;yes | sudo pacman -Scc && yes | rm -rf ~/.cache/* | sudo journalctl --vacuum-size=50M | sudo journalctl --vacuum-time=4weeks | SystemMaxUse=50M | sudo bleachbit -c --preset && bleachbit -c --preset && cleanCache'

# Arch Update
alias updateApp='yay; flatpak update -y'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; systemctl reboot'
alias updateShutdown='updateAll; systemctl poweroff'

# Debian Cleaning
alias cleanAll='flatpak remove --unused;yes | sudo apt clean && yes | sudo apt autoclean && yes | sudo apt autoremove && yes | rm -rf ~/.cache/* | sudo journalctl --vacuum-size=50M | sudo journalctl --vacuum-time=4weeks | SystemMaxUse=50M | sudo bleachbit -c --preset && bleachbit -c --preset'

# Debian Update (Tien)
alias updateApp='yes | sudo apt update && yes | sudo apt full-upgrade;flatpak update -y'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; systemctl reboot'
alias updateShutdown='updateAll; systemctl poweroff'

# Fedora Cleaning
alias cleanGuestFS='sudo rm -rf /var/tmp/.guestfs-1000/*'
alias cleanAll='flatpak remove --unused;yes | sudo dnf clean all | cleanGuestFS | rm -rf ~/.cache/* | sudo journalctl --vacuum-size=50M | sudo journalctl --vacuum-time=4weeks | SystemMaxUse=50M | sudo bleachbit -c --preset && bleachbit -c --preset'
alias cleanKernel='sudo dnf remove $(dnf repoquery --installonly --latest-limit=-1 -q)'
 
# Fedora Update
alias updateApp='yes | sudo dnf upgrade && yes | sudo dnf autoremove; flatpak update -y'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; systemctl reboot'
alias updateShutdown='updateAll; systemctl poweroff'

# FreeBSD Cleaning
alias bleachRoot='cd /home/f16poom/.local/share/applications/bleachbit; sudo python3 bleachbit.py'
alias bleachbit='cd /home/f16poom/.local/share/applications/bleachbit; python3 bleachbit.py'
alias cleanAll='sudo pkg clean; sudo pkg clean -a; sudo pkg autoremove; sudo portsnap auto; rm -rf ~/.cache/* SystemMaxUse=50M | bleachRoot -c --preset; bleachbit -c --preset | bleachRoot;exit'
 
# FreeBSD Update
alias updateApp='cd ./linux-browser-installer/;sudo ./linux-browser-installer chroot upgrade;sudo ./linux-browser-installer clean;cd;sudo freebsd-update fetch; sudo freebsd-update install; sudo pkg upgrade'
alias updateAll='updateApp; cleanAll'
alias updateRestart='updateAll | sudo init 6'
alias updateShutdown='updateAll | sudo poweroff'

# Gentoo Cleaning
alias cleanAll='sudo emerge -a --depclean; flatpak remove --unused; yes | rm -rf ~/.cache/* | sudo rm -rf /var/tmp/portage/ | sudo rm -rf /var/cache/distfiles/ | sudo rm -rf /var/cache/binpkgs/ | sudo eclean-dist --destructive | sudo eclean-pkg | sudo journalctl --vacuum-size=50M | sudo journalctl --vacuum-time=4weeks | SystemMaxUse=50M | sudo bleachbit -c --preset && bleachbit -c --preset'
alias cleanKernel='sudo eclean-kernel -a'
 
# Gentoo Update
alias updateSync='sudo emaint -a sync;'
alias updatePortage='sudo emerge --oneshot sys-apps/portage'
alias updateApp='sudo emerge -avDuN --with-bdeps=y @world; flatpak update -y;sudo grub-mkconfig -o /boot/grub/grub.cfg'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; systemctl reboot'
alias updateShutdown='updateAll; systemctl poweroff'

# NixOS Cleaning
alias cleanAll='flatpak remove --unused;rm -rf ~/.cache/*; sudo rm /nix/var/nix/gcroots/auto/*; sudo nix-collect-garbage -d; nix-collect-garbage -d; sudo nix-store --optimise; nix-store --optimise; sudo nix-env -p /nix/var/nix/profiles/system --delete-generations old; sudo nix-env --delete-generations old; nix-env --delete-generations old; sudo journalctl --flush --rotate;sudo journalctl --vacuum-time=1s; sudo bleachbit -c --preset && bleachbit -c --preset'

# NixOS Update
alias updateApp='sudo nixos-rebuild switch --upgrade; flatpak update -y'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; reboot'
alias updateShutdown='updateAll; poweroff'

# openSUSE Cleaning
alias cleanAll='flatpak remove --unused;sudo zypper clean -a;sudo zypper purge-kernels; sudo snapper delete 1-100; rm -rf ~/.cache/*; sudo rm /tmp/* -rf; sudo journalctl --vacuum-size=50M; sudo journalctl --vacuum-time=4weeks; SystemMaxUse=50M; sudo bleachbit -c --preset && bleachbit -c --preset; sudo -E bleachbit; exit'

# openSUSE Update
alias updateApp='sudo zypper ref; sudo zypper dup;flatpak update -y'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; systemctl reboot'
alias updateShutdown='updateAll; systemctl poweroff'

# Puppy Cleaning
alias cleanAll='flatpak remove --unused;yes | apt clean && yes | apt autoclean && yes | apt autoremove && yes | rm -rf ~/.cache/* | rm -rf ~/.history | sudo journalctl --vacuum-size=50M | sudo journalctl --vacuum-time=4weeks | SystemMaxUse=50M | sudo bleachbit -c --preset && bleachbit -c --preset'

# Puppy Update
alias updateApp='yes | apt update && yes | apt full-upgrade; flatpak update -y'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; reboot'
alias updateShutdown='updateAll; poweroff'
alias updateRam='save2flash'
 
# Slackware Cleaning
alias cleanAll='sudo find /var/log -type f -name "*.log" -exec truncate -s 0 {} \; ; sudo sboclean -d ; sudo sboclean -w ; flatpak uninstall --unused ; rm -rf ~/.cache/*; sudo bleachbit -c --preset && bleachbit -c --preset'

# Slackware Update
alias updateApp='sudo slackpkg update; sudo slackpkg install-new; sudo slackpkg upgrade-all; sudo sbocheck; sudo sboupgrade --all; sudo grub-mkconfig -o /boot/grub/grub.cfg;flatpak update -y'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; sudo reboot'
alias updateShutdown='updateAll; sudo poweroff'

# Void Cleaning
alias cleanAll='flatpak remove --unused; sudo xbps-remove -yROo; sudo vkpurge rm all; rm -rf ~/.cache/*; sudo rm -rf /var/cache/xbps; sudo bleachbit -c --preset && bleachbit -c --preset'
 
# Void Update
alias updateBrave='${HOME}/brave_updates.sh'
alias updateApp='sudo xbps-install -Su xbps && sudo xbps-install -Suvy; updateBrave; flatpak update -y'
alias updateAll='updateApp && cleanAll'
alias updateRestart='updateAll; sudo reboot'
alias updateShutdown='updateAll; sudo poweroff'
