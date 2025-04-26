#!/bin/bash

# Source common functions
source ./Theme-Common.sh

# Check if the script is run as root
check_not_root

# Check for missing dependencies
check_dependencies

# Install icons and themes
install_icons_and_themes

# Disable Cinnamon 6.4's built in polkit
dconf write /org/cinnamon/enable-polkit-agent "false"

# Override Cursor Theme for QT Apps
override_qt_cursor_theme

# Enable GTK & QT Flatpak Theming Override
enable_flatpak_theme_override

# Copies BleachBit config to appropriate directories, preserving old one
copy_bleachbit_config "openSUSE"

# Copies fonts to appropriate directories
copy_fonts

# Copies sounds and wallpapers to home directory
copy_sounds_and_wallpapers

# Copies applets to appropriate directories
copy_applets "applets.640"

# Copies KDE Global Cinnamon defaults to ~/.config, preserving old one
copy_kdeglobals

# Symlink kdeglobals to color-schemes for KDE applications like haruna
symlink_kdeglobals

# Copies haruna config to appropriate directory, preserving old config
copy_haruna_config

# Copies Cinnamon spice settings, preserving old ones
copy_cinnamon_spice_settings "openSUSE"

# Copies My Personal Shortcuts
copy_personal_shortcuts "openSUSE"

# Copies .bashrc and etc to home directory, preserving old one
copy_bashrc_and_etc "openSUSE"

# Copies neofetch config file to appropriate directory, preserving old one
copy_neofetch_config "openSUSE"

# Installs Kvantum Themes to appropriate directory, preserving old config
copy_kvantum_themes "gruvbox-fallnn"

# Copies qt5ct & qt6ct config to appropriate directories, preserving old ones
copy_qtct_configs

# Copies Gedit Theme to appropriate directory
copy_gedit_theme

# Copies Menu Preferences to appropriate directory
copy_menu_preferences "openSUSE"

# Copies Qbittorent config to appropriate directory, preserving old one
copy_qbittorrent_config "arch"

# Copies LibreOffice config to appropriate directory, preserving old ones
copy_libreoffice_config "arch"

# Copies Filezilla config to appropriate directory, preserving old one
copy_filezilla_config

# Copies Profile Picture to home directory, preserving old one
copy_profile_picture

# Import Entire Desktop Configuration, preserving old one
import_desktop_config "openSUSE"

# Apply gedit and gnome-terminal configuration to root
apply_gedit_and_gnome_terminal_config "openSUSE" "gedit-48.dconf"

# Sets Default Apps
set_default_apps "openSUSE"

# Sets Background and Sounds
set_cinnamon_background_and_sounds

# Install Synth-Shell Prompt
setup_synth_shell_config "lmde"

# Install NVChad for neovim, preserving old configs
install_nvchad

# Restarts Cinnamon
restart_cinnamon

# Places Login Wallpaper
place_login_wallpaper

# Check if syntax highlighting configurations are already in nanorc, preserving old one
configure_nanorc_basic
configure_nanorc_extra

# Check if environment variables for QT & Additional Theming are already set, preserving old one
set_qt_and_gtk_environment

# Append new settings to slick-greeter.conf, preserving old one
append_slick_greeter_config

# Append new settings to lightdm-gtk-greeter.conf, preserving old one
append_lightdm_gtk_greeter_config
