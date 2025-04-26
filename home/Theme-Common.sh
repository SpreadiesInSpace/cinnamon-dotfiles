#!/bin/bash

# TO DO: 
# - Make Variables for Theme Related Entries (for Light Mode)
# - Remove All Verbose Copies 
# - Suppress All Functions' Outputs
# - Echo Relavent Descriptions for All Functions

check_not_root() {
    # Prevents script from being run as root
    if [ "$EUID" -eq 0 ]; then
        echo "This script must NOT be run as root. Please execute it as a regular user."
        exit 1
    fi
}

check_dependencies() {
  local missing=0
  local deps=(dconf flatpak git gsettings nvim sudo unzip)

  for cmd in "${deps[@]}"; do
    command -v "$cmd" >/dev/null 2>&1 || {
      printf '%s\n' "Missing dependency: $cmd"
      missing=1
    }
  done

  # Ensure DBus session is available for gsettings/dconf
  if ! env | grep -q '^DBUS_SESSION_BUS_ADDRESS='; then
    printf '%s\n' "D-Bus session not detected. Run this in a user session with a graphical environment."
    missing=1
  fi

  # Check if gsettings can actually read schemas
  if command -v gsettings >/dev/null 2>&1 && ! gsettings list-schemas >/dev/null 2>&1; then
    printf '%s\n' "gsettings is present but non-functional (no schemas available)."
    missing=1
  fi

  if [ "$missing" -eq 1 ]; then
    printf '\n%s\n' "Resolve the above issues before continuing. Press Enter to exit."
    read -r
    exit 1
  fi
}

install_icons_and_themes() {
    # Run installer
    sudo echo
    bash icons-and-fonts.sh

    # Set filenames
    ICON_ZIP="gruvbox-dark-icons-gtk-1.0.0.zip"
    ICON_EXTRACTED="gruvbox-dark-icons-gtk-1.0.0"
    ICON_RENAME="gruvbox-dark-icons-gtk"
    CURSOR_ZIP="Capitaine Cursors (Gruvbox) - White.zip"
    CURSOR_DIR="Capitaine Cursors (Gruvbox) - White"
    THEME_ZIP="1670604530-Gruvbox-Dark-BL.zip"
    THEME_DIR="Gruvbox-Dark-BL"

    # Extract icons
    mv .icons/*.zip "$PWD"
    unzip "$ICON_ZIP"
    unzip "$CURSOR_ZIP"
    mv "$ICON_EXTRACTED" ".icons/$ICON_RENAME"
    mv "$CURSOR_DIR" .icons/

    # Extract themes
    mv .themes/*.zip "$PWD"
    unzip "$THEME_ZIP"
    mv "$THEME_DIR" .themes/

    # Always install to user directories
    mkdir -p ~/.icons ~/.themes
    cp -vnpr .icons/* ~/.icons/
    cp -vnpr .themes/* ~/.themes/

    # If not NixOS, also install to system-wide directories
    if ! grep -qi "nixos" /etc/os-release; then
        sudo cp -vnpr .icons/* /usr/share/icons/
        sudo cp -vnpr .themes/* /usr/share/themes/
    fi

    # Move ZIPs back & clean up
    mv "$CURSOR_ZIP" "$ICON_ZIP" .icons/
    mv "$THEME_ZIP" .themes/
    rm -rf ".icons/$ICON_RENAME" ".icons/$CURSOR_DIR" ".themes/$THEME_DIR"
}

override_qt_cursor_theme() {
    # Override Cursor Theme for QT Apps
    local distro="$1"

    if [ "$distro" = "nixos" ]; then
        mkdir -p ~/.icons/default
        rm -rf ~/.icons/default/*
        ln -s ~/.icons/"Capitaine Cursors (Gruvbox) - White/"* ~/.icons/default/
        sudo mkdir -p /root/.icons/default
        sudo rm -rf /root/.icons/default/*
        sudo ln -s ~/.icons/"Capitaine Cursors (Gruvbox) - White/"* /root/.icons/default/
    else
        rm -rf ~/.icons/default
        sudo mkdir -p /usr/share/icons/default
        sudo rm -rf /usr/share/icons/default/*
        sudo ln -s "/usr/share/icons/Capitaine Cursors (Gruvbox) - White/"* /usr/share/icons/default/
    fi
}

enable_flatpak_theme_override() {
    # Ensure Flathub exists
    flatpak remotes | grep -q flathub || {
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    }
    
    # Enable GTK & QT Flatpak Theming Override
    sudo flatpak override --filesystem="$HOME/.themes"
    sudo flatpak override --filesystem="$HOME/.icons"
    sudo flatpak override --env=GTK_THEME=Gruvbox-Dark-BL
    sudo flatpak override --env=ICON_THEME=gruvbox-dark-icons-gtk
    sudo flatpak override --filesystem=xdg-config/Kvantum:ro
    sudo flatpak override --env=QT_STYLE_OVERRIDE=kvantum
}

copy_bleachbit_config() {
    local distro="$1"
    local timestamp=$(date +%s)
    local src_file=".config/bleachbit/bleachbit.ini.$distro"
    local user_target="$HOME/.config/bleachbit/bleachbit.ini"
    local root_target="/root/.config/bleachbit/bleachbit.ini"

    # Backup and copy BleachBit config to appropriate directories
    if [ -f "$user_target" ]; then
        mv "$user_target" "$user_target.$timestamp"
    fi
    mkdir -p "$(dirname "$user_target")"
    cp -vnpr "$src_file" "$user_target"

    if sudo test -f "$root_target"; then
        sudo mv "$root_target" "$root_target.$timestamp"
    fi
    sudo mkdir -p "$(dirname "$root_target")"
    sudo cp -vprf "$src_file" "$root_target"
}

copy_fonts() {
  # Copies fonts to appropriate directories
  local distro="$1"

  # NixOS doesn’t use /usr/share/fonts/ for user fonts
  if [ "$distro" = "nixos" ]; then
    cp -vnpr .fonts/ ~/
  else
    sudo cp -vnpr .fonts/* /usr/share/fonts/
    mkdir -p ~/.fonts
    sudo ln -s /usr/share/fonts/* ~/.fonts/
  fi
}

copy_sounds_and_wallpapers() {
  # Copies sounds and wallpapers to home directory
  cp -vnpr sounds/ ~/
  cp -vnpr wallpapers/ ~/
}

copy_applets() {
    # Copies applets to appropriate directories
    local applet_variant=$1
    cp -vnpr .local/share/cinnamon/$applet_variant/* ~/.local/share/cinnamon/applets/
}

copy_kdeglobals() {
  # Creates a timestamp for backup
  local timestamp=$(date +%s)

  # Backup and copy KDE Global Cinnamon defaults to ~/.config
  if [ -f ~/.config/kdeglobals ]; then
    mv ~/.config/kdeglobals ~/.config/kdeglobals.$timestamp
  fi
  cp -vnpr .config/kdeglobals ~/.config/

  if sudo test -f /root/.config/kdeglobals; then
    sudo mv /root/.config/kdeglobals /root/.config/kdeglobals.$timestamp
  fi
  sudo mkdir -p /root/.config/
  sudo ln -s ~/.config/kdeglobals /root/.config/
}

symlink_kdeglobals() {
  # Symlink kdeglobals to color-schemes for KDE applications like haruna
  local distro="$1"

  if [ "$distro" = "nixos" ]; then
    sudo mkdir -p ~/.local/share/color-schemes/
    sudo ln -sf ~/.config/kdeglobals ~/.local/share/color-schemes/gruvbox-dark.colors
  else
    sudo mkdir -p /usr/share/color-schemes/
    sudo ln -sf ~/.config/kdeglobals /usr/share/color-schemes/gruvbox-dark.colors
  fi
}

# Void doesn't use this
copy_haruna_config() {
    # Creates a timestamp for backup
    local timestamp=$(date +%s)

    # Backup and copy Haruna config to appropriate directory
    if [ -d ~/.config/haruna ]; then
        mv ~/.config/haruna ~/.config/haruna.$timestamp
    fi
    cp -vnpr .config/haruna/ ~/.config/
}

copy_cinnamon_spice_settings() {
    # Backup and copy Cinnamon spice settings
    local distro=$1
    local timestamp=$(date +%s)  # Generate timestamp for backup

    # Create backup directory and move old settings to a timestamped backup folder
    mkdir -p ~/.config/cinnamon/spices/old_$timestamp
    mv ~/.config/cinnamon/spices/* ~/.config/cinnamon/spices/old_$timestamp/

    # Copy new settings for the specified distro
    cp -vnpr .config/cinnamon/spices.$distro/* ~/.config/cinnamon/spices/
}

copy_personal_shortcuts() {
    # Copies My Personal Shortcuts
    local distro=$1
    mkdir -p ~/.local/share/applications
    cp -vnpr .local/share/applications/$distro/* ~/.local/share/applications/
}

copy_bashrc_and_etc() {
    # Backup and copy .bashrc and etc to home directory
    local distro=$1
    local timestamp=$(date +%s)

    if [ "$distro" = "nixos" ]; then
        cd theming/
        cp -vnpr NixOS/* ~/; rm ~/configuration.nix
        sudo cp /root/.bashrc /root/.bashrc.$timestamp
        sudo cp NixOS/.bashrc.root /root/.bashrc
        sudo cp NixOS/NixAscii.txt /root/
        cp ~/.bashrc ~/.bashrc.$timestamp
        cat NixOS/.bashrc > bashrc
        mv bashrc ~/.bashrc
        cd ..
    else
        # Copies distro-specific theming files to home directory
        cp -vnpr "theming/$distro/"* ~/

        # Preserve old root .bashrc with timestamp
        sudo cp /root/.bashrc /root/.bashrc.$timestamp

        # Create minimal root .bashrc with tty check and source user .bashrc
        echo 'if [[ $(tty) == /dev/tty[0-9]* ]]; then
        return
    fi' | sudo tee /root/.bashrc

        echo "source $HOME/.bashrc" | sudo tee -a /root/.bashrc

        # Preserve and replace user .bashrc with timestamp
        cp ~/.bashrc ~/.bashrc.$timestamp
        cp "theming/$distro/.bashrc" ~/.bashrc
    fi
}

copy_neofetch_config() {
    local variant=${1:-default}  # Use "default" if no argument is passed
    local timestamp=$(date +%s)  # Generate timestamp for backups

    # Backup and copy neofetch config file to appropriate directory
    neofetch
    mv ~/.config/neofetch/config.conf ~/.config/neofetch/config.conf.$timestamp

    # Check if the variant-specific config file exists
    if [ "$variant" != "default" ] && [ -f ".config/neofetch/config.conf.$variant" ]; then
        cp -vnpr ".config/neofetch/config.conf.$variant" ~/.config/neofetch/config.conf
    else
        cp -vnpr ".config/neofetch/config.conf" ~/.config/neofetch/config.conf
    fi

    # Preserve and replace root's neofetch config
    sudo neofetch
    sudo mv /root/.config/neofetch/config.conf /root/.config/neofetch/config.conf.$timestamp
    sudo ln -s ~/.config/neofetch/config.conf /root/.config/neofetch/config.conf
}

copy_kvantum_themes() {
    # Backup and copy Kvantum Themes to appropriate directory
    local theme_variant=$1
    local distro=$2
    local timestamp=$(date +%s)  # Generate timestamp for backups

    if [ "$distro" = "nixos" ]; then
        mv ~/.config/Kvantum ~/.config/Kvantum.$timestamp
        cp -vnpr .config/Kvantum/ ~/.config/
        echo "" >> ~/.config/Kvantum/kvantum.kvconfig
        echo "[Applications]
Gruvbox-Dark-Brown=kdeconnect-app, kdeconnect-sms" >> ~/.config/Kvantum/kvantum.kvconfig
        sudo mv /root/.config/Kvantum /root/.config/Kvantum.$timestamp
        kvantummanager --set gruvbox-fallnn
        sudo ln -s ~/.config/Kvantum /root/.config/
    else
        mv ~/.config/Kvantum ~/.config/Kvantum.$timestamp
        cp -vnpr .config/Kvantum/ ~/.config/
        sudo mv /root/.config/Kvantum /root/.config/Kvantum.$timestamp
        kvantummanager --set "$theme_variant"
        sudo ln -s ~/.config/Kvantum /root/.config/
    fi
}

copy_qtct_configs() {
    # Backup and copy qt5ct & qt6ct config to appropriate directories
    local timestamp=$(date +%s)  # Generate timestamp for backups

    # Handle qt5ct
    mv ~/.config/qt5ct ~/.config/qt5ct.$timestamp
    cp -vnpr .config/qt5ct/ ~/.config/
    sudo mv /root/.config/qt5ct /root/.config/qt5ct.$timestamp
    sudo ln -s ~/.config/qt5ct/ /root/.config/

    # Handle qt6ct
    mv ~/.config/qt6ct ~/.config/qt6ct.$timestamp
    cp -vnpr .config/qt6ct/ ~/.config/
    sudo mv /root/.config/qt6ct /root/.config/qt6ct.$timestamp
    sudo ln -s ~/.config/qt6ct/ /root/.config/
}

# Gentoo/LMDE doesn't use this
copy_gedit_theme() {
    # Copies Gedit Theme to appropriate directory

    # User directory
    mkdir -p ~/.local/share/libgedit-gtksourceview-300/styles
    cp -vnpr gruvbox-dark-gedit46.xml ~/.local/share/libgedit-gtksourceview-300/styles

    # Root directory
    sudo mkdir -p /root/.local/share/libgedit-gtksourceview-300/styles
    sudo cp -vprf gruvbox-dark-gedit46.xml /root/.local/share/libgedit-gtksourceview-300/styles
}

# Gentoo/LMDE uses this
copy_gedit_old_theme() {
    # Copies Gedit Theme to appropriate directory

    # User directory
    mkdir -p ~/.local/share/gedit/styles
    cp -vnpr gruvbox-dark.xml ~/.local/share/gedit/styles/

    # Root directory
    sudo mkdir -p /root/.local/share/gedit/styles
    sudo cp -vprf gruvbox-dark.xml /root/.local/share/gedit/styles/
}

copy_menu_preferences() {
    # Backup and copy Menu Preferences to appropriate directory
    local distro=$1
    local timestamp=$(date +%s)  # Generate timestamp for backup

    # Create timestamped backup directory and move old menu preferences
    mkdir -p ~/.config/menus/old_$timestamp
    mv ~/.config/menus/*.menu ~/.config/menus/old_$timestamp/

    # Copy new menu preferences for the specified distro
    cp -vnpr .config/menus/$distro/* ~/.config/menus/
}

copy_qbittorrent_config() {
    # Backup and copy Qbittorrent config to appropriate directory
    local distro=$1
    local timestamp=$(date +%s)  # Generate timestamp for backups

    # Backup the old config with timestamp
    mv ~/.config/qBittorrent/qBittorrent.conf ~/.config/qBittorrent/qBittorrent.conf.$timestamp
    mkdir -p ~/.config/qBittorrent/

    # Copy distro-specific config
    cp -vnpr .config/qBittorrent/qBittorrent.conf.$distro ~/.config/qBittorrent/qBittorrent.conf
    cp -vnpr .config/qBittorrent/mumble-dark.qbtheme ~/.config/qBittorrent/
}

copy_libreoffice_config() {
    # Backup and copy LibreOffice config to appropriate directory
    local distro=$1
    local timestamp=$(date +%s)  # Generate timestamp for backup

    # User-side config
    mkdir -p ~/.config/libreoffice
    mv ~/.config/libreoffice/4 ~/.config/libreoffice/4_$timestamp  # Rename to include timestamp
    cp -vnpr .config/libreoffice/$distro ~/.config/libreoffice/4

    # Root-side config
    sudo mkdir -p /root/.config/libreoffice
    sudo mv /root/.config/libreoffice/4 /root/.config/libreoffice/4_$timestamp  # Rename to include timestamp
    sudo cp -vprf .config/libreoffice/$distro /root/.config/libreoffice/4
}

copy_filezilla_config() {
    # Backup and copy Filezilla config to appropriate directory
    local timestamp=$(date +%s)  # Generate timestamp for backups

    # Backup the old config with timestamp
    mv ~/.config/filezilla ~/.config/filezilla.$timestamp
    cp -vnpr .config/filezilla/ ~/.config/
}

copy_profile_picture() {
    # Backup and copy Profile Picture to home directory
    local timestamp=$(date +%s)  # Generate timestamp for backup

    # Create timestamped backup for the old profile picture
    mv ~/.face ~/.face_$timestamp

    # Copy new profile picture
    cp -vnpr .face ~/
}

import_desktop_config() {
    local distro=$1
    local timestamp=$(date +%s)  # Generate timestamp for backup

    # Backup and Import Entire Desktop Configuration
    cd theming/$distro/
    dconf dump / > Old_Desktop_Configuration_$timestamp.dconf  # Timestamped backup
    mv Old_Desktop_Configuration_$timestamp.dconf ~/
    dconf load / < $distro.dconf
    rm ~/$distro.dconf
}

apply_gedit_and_gnome_terminal_config() {
    local distro=$1
    local gedit_config=$2

    if [[ "$distro" == "openSUSE" ]]; then
        # Use gnomesu for openSUSE
        gnomesu dconf load / < "gnome-terminal-$distro.dconf"
        rm ~/gnome-terminal-$distro.dconf
        cd ..
        gnomesu dconf load / < "$gedit_config"
    else
        # Use sudo dbus-launch for other distros
        sudo dbus-launch dconf load / < "gnome-terminal-$distro.dconf"
        rm ~/gnome-terminal-$distro.dconf
        cd ..
        sudo dbus-launch dconf load / < "$gedit_config"
    fi

    cd "$distro/"
}

set_default_apps() {
    local distro=$1

    # Set default apps for the given distro
    chmod +x Default-Apps-$distro.sh
    bash Default-Apps-$distro.sh
    sudo bash Default-Apps-$distro.sh
    rm ~/Default-Apps-$distro.sh
    cd ../..
}

# Only Fedora/LMDE/NixOS uses this
set_cinnamon_menu_icon() {
    # Replaces hardcoded Cinnamon menu icon path with $HOME-based path
    local icon_file="$1"
    local json_file="${HOME}/.config/cinnamon/spices/menu@cinnamon.org/0.json"
    local original_path="/home/f16poom/${icon_file}"
    local new_path="${HOME}/.icons/${icon_file}"

    # Replace the hardcoded path with $HOME-based path on line 91
    sed -i "91s|\"value\": \"${original_path}\"|\"value\": \"${new_path}\"|g" "$json_file"

    # Move the icon file to .icons
    mv ~/"$icon_file" ~/.icons/
}

set_cinnamon_background_and_sounds() {
    # Set Wallpaper
    gsettings set org.cinnamon.desktop.background picture-uri file://${HOME}/wallpapers/Desktop_Wallpaper.png
    mkdir -p ~/Pictures
    ln -s ~/wallpapers/* ~/Pictures
    gsettings set org.cinnamon.desktop.background.slideshow image-source directory://${HOME}/Pictures

    # Set Login Sounds
    gsettings set org.cinnamon.sounds login-enabled true
    gsettings set org.cinnamon.sounds login-file ${HOME}/sounds/login.oga
    gsettings set org.cinnamon.sounds logout-enabled true
    gsettings set org.cinnamon.sounds logout-file ${HOME}/sounds/logout.ogg

    # Set Volume Toggle Sound
    gsettings set org.cinnamon.desktop.sound volume-sound-enabled true
    gsettings set org.cinnamon.desktop.sound volume-sound-file ${HOME}/sounds/volume.oga

    # Disable all other Cinnamon Sound Events
    for key in \
      switch-enabled \
      map-enabled \
      close-enabled \
      minimize-enabled \
      maximize-enabled \
      unmaximize-enabled \
      tile-enabled \
      plug-enabled \
      unplug-enabled \
      notification-enabled; do
        gsettings set org.cinnamon.sounds $key false
    done
}

# NixOS doesn't use this
setup_synth_shell_config() {
    local distro=$1
    local timestamp=$(date +%s)  # Generate timestamp for backup

    # Clone Synth-Shell and run setup
    git clone --recursive https://github.com/andresgongora/synth-shell-prompt.git
    yes | synth-shell-prompt/setup.sh
    yes | sudo synth-shell-prompt/setup.sh
    rm -rf synth-shell-prompt/

    # Place Synth-Shell config, preserving old ones with timestamped backup
    mkdir -p ~/.config/synth-shell
    cp -vnpr ~/.config/synth-shell/* ~/.config/synth-shell/old_$timestamp/
    cp -vprf .config/synth-shell/$distro/* ~/.config/synth-shell/

    sudo mkdir -p /root/.config/synth-shell
    sudo cp -vnpr /root/.config/synth-shell/* /root/.config/synth-shell/old_$timestamp/
    sudo cp -vprf .config/synth-shell/root-synth-shell-prompt.config /root/.config/synth-shell/synth-shell-prompt.config
}

install_nvchad() {
    # Timestamp for unique backups
    timestamp=$(date +%s)

    # Backup existing NVim configs if they exist
    [ -d ~/.config/nvim ] && mv ~/.config/nvim ~/.config/nvim."$timestamp"
    [ -d ~/.local/share/nvim ] && mv ~/.local/share/nvim ~/.local/share/nvim."$timestamp"
    [ -d ~/.cache/nvim ] && mv ~/.cache/nvim ~/.cache/nvim."$timestamp"

    # Clone NVChad starter config
    git clone https://github.com/NvChad/starter ~/.config/nvim

    # Backup and copy custom chadrc.lua config
    [ -f ~/.config/nvim/lua/chadrc.lua ] && mv ~/.config/nvim/lua/chadrc.lua ~/.config/nvim/lua/chadrc.lua."$timestamp"
    cp -vpnr .config/nvim/lua/chadrc.lua ~/.config/nvim/lua/

    # Install all mason plugins and quit Neovim
    nvim --headless "+MasonInstallAll" +qa
}

restart_cinnamon() {
    # Restarts Cinnamon
    cinnamon-dbus-command RestartCinnamon 1
}

# NixOS doesn't use this
place_login_wallpaper() {
    # Places Login Wallpaper
    sudo cp -vnr wallpapers/Login_Wallpaper.jpg /boot/
}

# NixOS doesn't use this
configure_nanorc_basic() {
    # Enables basic syntax highlighting in nano, preserving old config
    local timestamp=$(date +%s)  # Generate timestamp for backups

    # Backup the old nanorc file with timestamp
    sudo cp /etc/nanorc /etc/nanorc.$timestamp

    # Add the syntax highlighting inclusion line if it's not already present
    if ! grep -q '^include "/usr/share/nano/\*.nanorc"' /etc/nanorc; then
        echo 'include "/usr/share/nano/*.nanorc"' | sudo tee -a /etc/nanorc > /dev/null
    fi
}

# Fedora/Gentoo/NixOS doesn't use this
configure_nanorc_extra() {
    # Adds extra nano syntax highlighting rules
    if ! grep -q '^include "/usr/share/nano/extra/\*.nanorc"' /etc/nanorc; then
        echo 'include "/usr/share/nano/extra/*.nanorc"' | sudo tee -a /etc/nanorc > /dev/null
    fi
}

# NixOS doesn't use this, openSUSE needs 2 ZYPP variables
set_qt_and_gtk_environment() {
    # Sets QT and GTK theming variables, preserving old environment config
    local timestamp=$(date +%s)  # Generate timestamp for backups

    # Backup the old environment file with timestamp
    sudo cp /etc/environment /etc/environment.$timestamp

    # Set QT and GTK theming variables if not already present
    if ! grep -q "^QT_QPA_PLATFORMTHEME=qt5ct" /etc/environment; then
        echo 'QT_QPA_PLATFORMTHEME=qt5ct' | sudo tee -a /etc/environment > /dev/null
    fi

    if ! grep -q "^GTK_THEME=Gruvbox-Dark-BL" /etc/environment; then
        echo 'GTK_THEME=Gruvbox-Dark-BL' | sudo tee -a /etc/environment > /dev/null
    fi
}

# NixOS doesn't use this
append_slick_greeter_config() {
    # Append new settings to slick-greeter.conf, preserving old one
    local timestamp=$(date +%s)  # Generate timestamp for backup

    # Backup the old slick-greeter.conf with timestamp
    sudo cp /etc/lightdm/slick-greeter.conf /etc/lightdm/slick-greeter.conf.$timestamp

    # Append new settings to slick-greeter.conf
    echo "[Greeter]
show-hostname=true
theme-name=Gruvbox-Dark-BL
icon-theme-name=gruvbox-dark-icons-gtk
cursor-theme-name=Capitaine Cursors (Gruvbox) - White
clock-format=%a, %-e %b %-l:%M %p 
background=/boot/Login_Wallpaper.jpg
logo=
draw-user-backgrounds=false" | sudo tee /etc/lightdm/slick-greeter.conf > /dev/null
}

# NixOS doesn't use this
append_lightdm_gtk_greeter_config() {
    # Append new settings to lightdm-gtk-greeter.conf, preserving old one
    local timestamp=$(date +%s)  # Generate timestamp for backup

    # Backup the old lightdm-gtk-greeter.conf with timestamp
    sudo cp /etc/lightdm/lightdm-gtk-greeter.conf /etc/lightdm/lightdm-gtk-greeter.conf.$timestamp

    # Append new settings to lightdm-gtk-greeter.conf
    echo "[greeter]
background=/boot/Login_Wallpaper.jpg
theme-name=Gruvbox-Dark-BL
icon-name=gruvbox-dark-icons-gtk
cursor-theme-name=Capitaine Cursors (Gruvbox) - White
font-name=Cantarell 11
xft-antialias=true
xft-dpi=96
xft-hintstyle=hintslight
xft-rgba=rgb
clock-format=%a, %-e %b %-l:%M %p 
indicators=~host;~spacer;~session;~clock;~power
user-background=false
hide-user-image = true" | sudo tee /etc/lightdm/lightdm-gtk-greeter.conf > /dev/null
}

