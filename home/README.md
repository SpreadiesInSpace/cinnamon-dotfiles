**Disclaimer:** *Please go through the script carefully so you know what is going on. Feel free to comment out whatever you don't want before you run the script.*

**Steps to Install**

1. Clone this repo https://github.com/SpreadiesInSpace/cinnamon-dotfiles
2. Head to cinnamon-dotfiles/home
3. chmod+x then run the Setup.sh of your distro.

**Required Fonts**
*Note: You only need to download Noto, the rest is accounted for in the script.*

 - [ ] Noto-fonts
 - [ ] Cantarell
 - [ ] Source Code Pro
 - [ ] Sauce Code Pro Nerd

**Dependencies** ***- The script will break if these aren't installed.***

 - [ ] dconf (Debian-based systems need dconf-cli)
 - [ ] flatpak (for themeing override)
 - [ ] git
 - [ ] gsettings
 - [ ] neovim
 - [ ] sudo
 - [ ] unzip
 
**Optional Dependencies**
 
 - [ ] gedit
 - [ ] git
 - [ ] gnome-calculator
 - [ ] gnome-screenshot
 - [ ] gnome-system-monitor
 - [ ] gnome-terminal
 - [ ] gpaste
 - [ ] gir1.2-gpaste-4.0 ***# if on Debian or Ubuntu-based distro***
 - [ ] neofetch
 - [ ] kvantum ***# kvantum and qt5/6ct are needed to theme QT apps***
 - [ ] kvantum-qt5
 - [ ] qt5ct
 - [ ] qt6ct

**Additional Theming Info** 

 - [ ] Terminal Prompt Theme - https://github.com/Gogh-Co/Gogh
 - [ ] Synth-Shell - https://github.com/andresgongora/synth-shell-prompt

*Note: This is taken care of in the script. See ~/.config/synth-shell/synth-shell-prompt.config to tweak colors*

**QT & Additional Theming Steps**

1. Apply gruvbox-fallnn theme to kvantum
2. Set qt5ct and qt6ct to kvantum
3. Set QT_QPA_PLATFORMTHEME=qt5ct to /etc/environment
4. Set GTK_THEME=Gruvbox-Dark-BL to /etc/environment
5. Set Default font to Noto Sans Regular,  Document font to Cantarell Regular, and Monospace font to SauceCodePro Nerd Font Regular
6. Set Icon Theme to Gruvbox-Dark (oomox-gruvbox-dark for NixOS)

*Note:  This is taken care of in the script.*

**Other Software I Use (Tied to Exported dconf & Personal Dots)**

 - [ ] bleachbit
 - [ ] brave ***# use Dark Reader, set Sepia to 50% for maximum Gruvbox uniformity***
 - [ ] bottom
 - [ ] celluloid/haruna
 - [ ] filezilla
 - [ ] flatpak ***# GTK and QT Overrides applied***
 - [ ] gparted
 - [ ] grub-customizer
 - [ ] gufw
 - [ ] kdeconnect ***# Gruvbox-Dark Theme applied using custom kdeglobals***
 - [ ] lightdm ***# Gruvbox-Dark-BL Theme applied both for slick and gtk greeter***
 - [ ] libreoffice ***# Dark Theme Applied***
 - [ ] ncdu
 - [ ] neovim ***# NVChad's Gruvchad theme appiled***
 - [ ] qbittorrent
 - [ ] timeshift
 - [ ] virt-manager
 
**Brave Theming**

> The Brave gruvbox profile is NOT applied in the script. The theme is located
> in extra/brave-gruvbox.sh

**Grub Theming**

> The Grub theme is NOT applied in the script. The profile is located in
> boot/grub/themes/gruvbox-dark

**Grub-Btrfs & Theming Setup**

> If you use btrfs and would like to set up grub-btrfs and apply the
> gruvbox-dark theme at the same time, the setup scripts for all distros
> are located in extra/grub-btrfs-setup.

**Gruvbox-Light Theme**

> This is a work in progress, but all the files needed are located in
> extra/gruvbox-light.
