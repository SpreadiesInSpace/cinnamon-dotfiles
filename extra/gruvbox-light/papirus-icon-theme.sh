#!/bin/sh

wget -qO- https://git.io/papirus-icon-theme-install | EXTRA_THEMES="Papirus-Light" sh
wget -qO- https://git.io/papirus-icon-theme-install | EXTRA_THEMES="Papirus-Light" env DESTDIR="$HOME/.icons" sh
