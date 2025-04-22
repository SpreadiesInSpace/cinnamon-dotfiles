#!/bin/bash

# Source common functions
source ./theme_common.sh

# Check if the script is run as root
check_not_root

# Install icons and themes
install_icons_and_themes

# Override Cursor Theme for QT Apps
mkdir -p ~/.icons/default
rm -rf ~/.icons/default/*
ln -s ~/.icons/Capitaine\ Cursors\ \(Gruvbox\)\ -\ White/* ~/.icons/default/
sudo mkdir -p /root/.icons/default
sudo rm -rf /root/.icons/default/*
sudo ln -s ~/.icons/Capitaine\ Cursors\ \(Gruvbox\)\ -\ White/* /root/.icons/default/

# Enable GTK & QT Flatpak Theming Override
enable_flatpak_theme_override

# Copies BleachBit config to appropriate directories, preserving old one
copy_bleachbit_config "nixos"

# Copies fonts to appropriate directories
cp -vnpr .fonts/ ~/
# sudo cp -vnpr .fonts/* /usr/share/fonts/

# Copies sounds and wallpapers to home directory
copy_sounds_and_wallpapers

# Copies applets to appropriate directories
copy_applets "applets.640"

# Copies KDE Global Cinnamon defaults to ~/.config, preserving old one
copy_kdeglobals

# Symlink kdeglobals to color-schemes for KDE applications like haruna
sudo mkdir -p ~/.local/share/color-schemes/
sudo ln -sf ~/.config/kdeglobals ~/.local/share/color-schemes/gruvbox-dark.colors

# Copies haruna config to appropriate directory, preserving old config
copy_haruna_config

# Copies Cinnamon spice settings, preserving old ones
copy_cinnamon_spice_settings "nixos"

# Copies My Personal Shortcuts
copy_personal_shortcuts "nixos"

# Copies .bashrc and etc to home directory, preserving old one
cd theming/
cp -vnpr NixOS/* ~/;rm ~/configuration.nix
sudo cp /root/.bashrc /root/.bashrc.old
sudo cp NixOS/.bashrc.root /root/.bashrc;sudo cp NixOS/NixAscii.txt /root/
cp ~/.bashrc ~/.bashrc.old
cat NixOS/.bashrc > bashrc
mv bashrc ~/.bashrc
cd ..

# Copies neofetch config file to appropriate directory, preserving old one
copy_neofetch_config "default"

# Copies Kvantum Themes to appropriate directory and installs them, preserving old config
mv ~/.config/Kvantum ~/.config/Kvantum.old
cp -vnpr .config/Kvantum/ ~/.config/
echo "" >> ~/.config/Kvantum/kvantum.kvconfig
echo "[Applications]
Gruvbox-Dark-Brown=kdeconnect-app, kdeconnect-sms" >> ~/.config/Kvantum/kvantum.kvconfig
sudo mv /root/.config/Kvantum /root/.config/Kvantum.old
# sudo cp -vnpr .config/Kvantum/ /root/.config/Kvantum
kvantummanager --set gruvbox-fallnn
# sudo kvantummanager --set gruvbox-fallnn
sudo ln -s ~/.config/Kvantum /root/.config/

# Copies qt5ct & qt6ct config to appropriate directories, preserving old ones
copy_qtct_configs

# Copies Gedit Theme to appropriate directory
copy_gedit_theme

# Copies Menu Preferences to appropriate directory
copy_menu_preferences "nixos"

# Copies Qbittorent config to appropriate directory, preserving old one
copy_qbittorrent_config "arch"

# Copies LibreOffice config to appropriate directory, preserving old ones
copy_libreoffice_config "gentoo"

# Copies Filezilla config to appropriate directory, preserving old one
copy_filezilla_config

# Copies Profile Picture to home directory, preserving old one
copy_profile_picture

# Import Entire Desktop Configuration, preserving old one
import_desktop_config "NixOS"

# Apply gedit and gnome-terminal configuration to root
apply_gedit_and_gnome_terminal_config "NixOS" "gedit-48.dconf"

# Sets Default Apps
set_default_apps "NixOS"

# Define the home directory (For Menu Applet Icon)
home_dir="${HOME}"
# Define the path to JSON file
json_file="${home_dir}/.config/cinnamon/spices/menu@cinnamon.org/0.json"
# Use sed to replace /home/f16poom with the home directory in the value field on line 91
sed -i "91s|\"value\": \"/home/f16poom/NixOS-Start.png\"|\"value\": \"${home_dir}/.icons/NixOS-Start.png\"|g" $json_file
mv ~/NixOS-Start.png ~/.icons/

# Sets Background and Sounds
set_cinnamon_background_and_sounds

# Install Synth-Shell Prompt
# setup_synth_shell_config "arch"

# Install NVChad for neovim, preserving old configs
install_nvchad

# Restarts Cinnamon
restart_cinnamon

# Places Login Wallpaper
# place_login_wallpaper

# Check if syntax highlighting configurations are already in nanorc, preserving old one
# configure_nanorc_basic
# configure_nanorc_extra

# Check if environment variables for QT & Additional Theming are already set, preserving old one
# set_qt_and_gtk_environment

# Append new settings to slick-greeter.conf, preserving old one
# append_slick_greeter_config

# Append new settings to lightdm-gtk-greeter.conf, preserving old one
# append_lightdm_gtk_greeter_config
