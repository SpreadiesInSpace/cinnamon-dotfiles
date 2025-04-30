![Cinnamon Gruvbox Merge](https://github.com/SpreadiesInSpace/cinnamon-dotfiles/blob/main/screenshots/Collection/CinnamonGruvboxMerge2025.gif "Cult of Cinnamon")

**Disclaimer:** *Please go through the scripts carefully so you know what is going on before running them.*

## Install Straight from ISO
*Supports UEFI and BIOS, x86_64 Only*

```bash
# For Arch, Gentoo, openSUSE Tumbleweed & Void
bash <(curl -sL https://tinyurl.com/cinnamon-ISO)
```
```bash
# For Slackware Current
bash <(wget -qO- https://tinyurl.com/cinnamon-ISO)
```
*View cinnamon-ISO [source](https://github.com/SpreadiesInSpace/cinnamon-dotfiles/blob/main/extra/Setup-ISO.sh)*

## Steps to Install

1. Clone this repo
```bash
git clone https://github.com/SpreadiesInSpace/cinnamon-dotfiles
```
2. Head to cinnamon-dotfiles
```bash
cd cinnamon-dotfiles
```
3. Run setup script
```bash
# Default NixOS behavior doesn't let you chmod+x then ./Setup.sh
bash Setup.sh
```
4. Then run theme script
```bash
bash Theme.sh
```

## Screenshots
![Fedora](https://github.com/SpreadiesInSpace/cinnamon-dotfiles/blob/main/screenshots/CinnamonGruvbox2024.png "Cinnamon Gruvbox")
![Cinnamon Gruvbox Wallpapers](https://github.com/SpreadiesInSpace/cinnamon-dotfiles/blob/main/screenshots/Collection/wallpapers.gif "Cult of Cinnamon")
