![Cinnamon Gruvbox GIF](https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles/refs/heads/main/screenshots/Collection/CinnamonGruvboxMerge2025.gif "Pixel perfect theming across 8 distros.")

**Disclaimer:** *Please go through the scripts carefully so you know what is going on before running them.*

## Supported Distros (with ISO download links)
* [Arch](https://archlinux.org/download/)
* [Fedora 42](https://fedoraproject.org/spins/cinnamon/download/)
* [Gentoo](https://www.gentoo.org/downloads/)
* [Linux Mint (Debian Edition)](https://linuxmint.com/edition.php?id=308)
* [NixOS 25.05](https://nixos.org/download/#nixos-iso)
* [openSUSE Tumbleweed](https://get.opensuse.org/tumbleweed/#download)
* [Slackware Current](https://us.slackware.nl/slackware/slackware64-current-iso/)
* [Void Linux](https://voidlinux.org/download/)

## Install from ISO (cinnamon-ISO)
*Supports UEFI and BIOS, x86_64 Only*

```bash
# For Arch, Gentoo, NixOS & openSUSE Tumbleweed
bash <(curl -fsSL https://tinyurl.com/cinnamon-ISO)
```
```bash
# For Slackware Current (no curl by default)
bash <(wget -qO- https://tinyurl.com/cinnamon-ISO)
```
```bash
# For Void Linux (no curl or wget by default)
sudo xbps-install -Sy xbps wget
bash <(wget -qO- https://tinyurl.com/cinnamon-ISO)
```
*View cinnamon-ISO [source](https://github.com/SpreadiesInSpace/cinnamon-dotfiles/blob/main/extra/Setup-ISO.sh)*

## Installation Steps

1. Clone this repo
```bash
# Installed your distro via cinnamon-ISO? Skip this step.
git clone https://github.com/SpreadiesInSpace/cinnamon-dotfiles
```
2. Head to cinnamon-dotfiles
```bash
cd cinnamon-dotfiles
```
3. Run setup script
```bash
# NixOS installed via cinnamon-ISO? Skip this step.
bash Setup.sh
```
4. Then run theme script
```bash
bash Theme.sh
```
*See this [README](https://github.com/SpreadiesInSpace/cinnamon-dotfiles/tree/main/home#readme) for theming details.*

## Screenshots - [Link](https://github.com/SpreadiesInSpace/cinnamon-dotfiles/blob/main/screenshots/CinnamonGruvbox2024.png)
![LMDE Screenshots](https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles/main/screenshots/CinnamonGruvbox2024.png "GTK, QT and Flatpak apps all thoroughly themed.")
## Wallpapers - [Link](https://github.com/SpreadiesInSpace/cinnamon-dotfiles/tree/main/home/wallpapers)
![Cinnamon Gruvbox Wallpapers](https://raw.githubusercontent.com/SpreadiesInSpace/cinnamon-dotfiles/main/screenshots/Collection/wallpapers.gif "I made the light/dark Cinnamon logo wallpapers.")
