#!/bin/bash

# Source common functions
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }
[ -f ./Theme-Common.sh ] || die "Theme-Common.sh not found."
source ./Theme-Common.sh || die "Failed to source Theme-Common.sh"

# Check if the script is run as root
check_not_root

# Check for missing dependencies
check_dependencies

# VM Prompt
prompt_for_vm

# Install icons and themes
install_icons_and_themes

# Configure MIME type icons for custom file types
configure_icons

# Override Cursor Theme for QT Apps
override_qt_cursor_theme "default"

# Enable GTK & QT Flatpak Theming Override
enable_flatpak_theme_override

# Backup and copy BleachBit config to appropriate directories
copy_bleachbit_config "slackware"

# Copies fonts to appropriate directories
copy_fonts "default"

# Symlink Fonts for Root
symlink_fonts

# Copies sounds and wallpapers to home directory
copy_sounds_and_wallpapers

# Copies applets to appropriate directories
copy_applets "applets.660"

# Backup and copy KDE Global defaults to ~/.config
copy_kdeglobals

# Symlink kdeglobals to color-schemes for KDE applications like haruna
symlink_kdeglobals "default"

# Backup and copy Haruna config to appropriate directory
copy_haruna_config

# Backup and copy Cinnamon spice settings
copy_cinnamon_spice_settings "slackware.current"

# Copies My Personal Shortcuts
copy_personal_shortcuts "slackware"

# Backup and copy .bashrc and etc to home directory
copy_bashrc_and_etc "Slackware"

# Backup and copy neofetch config file to appropriate directory
copy_neofetch_config "slackware"

# Backup and copy Kvantum Themes to appropriate directory
copy_kvantum_themes "gruvbox-fallnn"

# Backup and copy qt5ct & qt6ct config to appropriate directories
copy_qtct_configs

# Backup and copy xfce4 config to appropriate directories
timestamp=$(date +%s)
[ -d ~/.config/xfce4 ] && mv ~/.config/xfce4 ~/.config/xfce4.old."$timestamp"
cp -npr .config/xfce4/ ~/.config/
if sudo test -d /root/.config/xfce4; then
  sudo mv /root/.config/xfce4 /root/.config/xfce4.old."$timestamp"
fi
sudo cp -npr .config/xfce4/ /root/.config/

# Copies Gedit Theme to appropriate directory
copy_gedit_theme

# Copies Menu Preferences to appropriate directory
copy_menu_preferences "slackware"

# Backup and copy Qbittorrent config to appropriate directory
copy_qbittorrent_config "arch"

# Backup and copy LibreOffice config to appropriate directory
copy_libreoffice_config "arch"

# Backup and copy Filezilla config to appropriate directory
copy_filezilla_config

# Backup and copy Profile Picture to home directory
copy_profile_picture

# Backup and Import Entire Desktop Configuration
import_desktop_config "Slackware"

# Apply gedit and gnome-terminal configuration to root
apply_gedit_and_gnome_terminal_config "Slackware" "gedit-48.dconf"

# Sets Default Apps
set_default_apps "Slackware"

# Backup and copy VSCodium config + plugins to appropriate directory
copy_vscodium_config

# Set Cinnamon Menu Icon
set_cinnamon_menu_icon "none" "24"

# Sets Background and Sounds
set_cinnamon_background_and_sounds

# Install Synth-Shell Prompt
setup_synth_shell_config "fedora"

# Backup old configs and install NVChad for neovim
install_nvchad

# Places Login Wallpaper
place_login_wallpaper

# Backup old config and enable syntax highlighting for nano
configure_nanorc_basic
configure_nanorc_extra

# Backup old config and set QT and GTK theming variables
set_qt_and_gtk_environment

# Backup old config and append new settings to slick-greeter.conf
append_slick_greeter_config

# Backup old config and append new settings to lightdm-gtk-greeter.conf
append_lightdm_gtk_greeter_config

# Restarts Cinnamon
restart_cinnamon

# Display Logoff Message
print_finish_message