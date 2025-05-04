![Cinnamon Gruvbox GIF](https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles/refs/heads/main/screenshots/Collection/CinnamonGruvboxMerge2025.gif "Pixel perfect theming across 8 distros.")

**Disclaimer:** *Please go through the scripts carefully so you know what is going on before running them.*

## Install Straight from ISO
*Supports UEFI and BIOS, x86_64 Only*

```bash
# For Arch, Gentoo, openSUSE Tumbleweed & Void Linux
bash <(curl -fsSL https://tinyurl.com/cinnamon-ISO)
```
```bash
# For Slackware Current (no curl by default)
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

## Screenshots - [Link](https://github.com/SpreadiesInSpace/cinnamon-dotfiles/blob/main/screenshots/CinnamonGruvbox2024.png)
![LMDE Screenshots](https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles/main/screenshots/CinnamonGruvbox2024.png "GTK, QT and Flatpak apps all thoroughly themed.")
## Wallpapers - [Link](https://github.com/SpreadiesInSpace/cinnamon-dotfiles/tree/main/home/wallpapers)
![Cinnamon Gruvbox Wallpapers](https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles/main/screenshots/Collection/wallpapers.gif "I made the light/dark Cinnamon logo wallpapers.")
