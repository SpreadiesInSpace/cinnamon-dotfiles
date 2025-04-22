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
    local src_file=".config/bleachbit/bleachbit.ini.$distro"
    local user_target="$HOME/.config/bleachbit/bleachbit.ini"
    local root_target="/root/.config/bleachbit/bleachbit.ini"

    # Copies BleachBit config to appropriate directories, preserving old one
    if [ -f "$user_target" ]; then
        mv "$user_target" "$user_target.old"
    fi
    mkdir -p "$(dirname "$user_target")"
    cp -vnpr "$src_file" "$user_target"

    if sudo test -f "$root_target"; then
        sudo mv "$root_target" "$root_target.old"
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
  # Copies KDE Global Cinnamon defaults to ~/.config, preserving old one
  mv ~/.config/kdeglobals ~/.config/kdeglobals.old
  cp -vnpr .config/kdeglobals ~/.config/
  sudo mv /root/.config/kdeglobals /root/.config/kdeglobals.old
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

# Void doesn't need this
copy_haruna_config() {
    # Copies haruna config to appropriate directory, preserving old config
    mv ~/.config/haruna ~/.config/haruna.old
    cp -vnpr .config/haruna/ ~/.config/
}

copy_cinnamon_spice_settings() {
    # Copies Cinnamon spice settings, preserving old ones
    local distro=$1
    mkdir -p ~/.config/cinnamon/spices/old
    mv ~/.config/cinnamon/spices/* ~/.config/cinnamon/spices/old
    cp -vnpr .config/cinnamon/spices.$distro/* ~/.config/cinnamon/spices/
}

copy_personal_shortcuts() {
    # Copies My Personal Shortcuts
    local distro=$1
    mkdir -p ~/.local/share/applications
    cp -vnpr .local/share/applications/$distro/* ~/.local/share/applications/
}

copy_bashrc_and_etc() {
    # Copies .bashrc and etc to home directory, preserving old one
    local distro=$1

    if [ "$distro" = "nixos" ]; then
        cd theming/
        cp -vnpr NixOS/* ~/; rm ~/configuration.nix
        sudo cp /root/.bashrc /root/.bashrc.old
        sudo cp NixOS/.bashrc.root /root/.bashrc
        sudo cp NixOS/NixAscii.txt /root/
        cp ~/.bashrc ~/.bashrc.old
        cat NixOS/.bashrc > bashrc
        mv bashrc ~/.bashrc
        cd ..
    else
        # Copies distro-specific theming files to home directory
        cp -vnpr "theming/$distro/"* ~/

        # Preserve old root .bashrc
        sudo cp /root/.bashrc /root/.bashrc.old

        # Create minimal root .bashrc with tty check and source user .bashrc
        echo 'if [[ $(tty) == /dev/tty[0-9]* ]]; then
        return
    fi' | sudo tee /root/.bashrc

        echo "source $HOME/.bashrc" | sudo tee -a /root/.bashrc

        # Preserve and replace user .bashrc
        cp ~/.bashrc ~/.bashrc.old
        cp "theming/$distro/.bashrc" ~/.bashrc
    fi
}

copy_neofetch_config() {
    local variant=${1:-default}  # Use "default" if no argument is passed

    # Copies neofetch config file to appropriate directory, preserving old one
    neofetch
    mv ~/.config/neofetch/config.conf ~/.config/neofetch/config.conf.old

    # Check if the variant-specific config file exists
    if [ "$variant" != "default" ] && [ -f ".config/neofetch/config.conf.$variant" ]; then
        cp -vnpr ".config/neofetch/config.conf.$variant" ~/.config/neofetch/config.conf
    else
        cp -vnpr ".config/neofetch/config.conf" ~/.config/neofetch/config.conf
    fi

    # Preserve and replace root's neofetch config
    sudo neofetch
    sudo mv /root/.config/neofetch/config.conf /root/.config/neofetch/config.conf.old
    sudo ln -s ~/.config/neofetch/config.conf /root/.config/neofetch/config.conf
}

copy_kvantum_themes() {
    # Installs Kvantum Themes to appropriate directory, preserving old config
    local theme_variant=$1
    local distro=$2

    if [ "$distro" = "nixos" ]; then
        mv ~/.config/Kvantum ~/.config/Kvantum.old
        cp -vnpr .config/Kvantum/ ~/.config/
        echo "" >> ~/.config/Kvantum/kvantum.kvconfig
        echo "[Applications]
Gruvbox-Dark-Brown=kdeconnect-app, kdeconnect-sms" >> ~/.config/Kvantum/kvantum.kvconfig
        sudo mv /root/.config/Kvantum /root/.config/Kvantum.old
        kvantummanager --set gruvbox-fallnn
        sudo ln -s ~/.config/Kvantum /root/.config/
    else
        mv ~/.config/Kvantum ~/.config/Kvantum.old
        cp -vnpr .config/Kvantum/ ~/.config/
        sudo mv /root/.config/Kvantum /root/.config/Kvantum.old
        kvantummanager --set "$theme_variant"
        sudo ln -s ~/.config/Kvantum /root/.config/
    fi
}

copy_qtct_configs() {
    # Copies qt5ct & qt6ct config to appropriate directories, preserving old ones

    # Handle qt5ct
    mv ~/.config/qt5ct ~/.config/qt5ct.old
    cp -vnpr .config/qt5ct/ ~/.config/
    sudo mv /root/.config/qt5ct /root/.config/qt5ct.old
    sudo ln -s ~/.config/qt5ct/ /root/.config/

    # Handle qt6ct
    mv ~/.config/qt6ct ~/.config/qt6ct.old
    cp -vnpr .config/qt6ct/ ~/.config/
    sudo mv /root/.config/qt6ct /root/.config/qt6ct.old
    sudo ln -s ~/.config/qt6ct/ /root/.config/
}

# Gentoo and LMDE see below
copy_gedit_theme() {
    # Copies Gedit Theme to appropriate directory

    # User directory
    mkdir -p ~/.local/share/libgedit-gtksourceview-300/styles
    cp -vnpr gruvbox-dark-gedit46.xml ~/.local/share/libgedit-gtksourceview-300/styles

    # Root directory
    sudo mkdir -p /root/.local/share/libgedit-gtksourceview-300/styles
    sudo cp -vprf gruvbox-dark-gedit46.xml /root/.local/share/libgedit-gtksourceview-300/styles
}

# Gentoo and LMDE Needs This One
copy_gedit_old_theme() {
    # Copies Gedit Theme to appropriate directory (for Gentoo, LMDE, and older versions)

    # User directory
    mkdir -p ~/.local/share/gedit/styles
    cp -vnpr gruvbox-dark.xml ~/.local/share/gedit/styles/

    # Root directory
    sudo mkdir -p /root/.local/share/gedit/styles
    sudo cp -vprf gruvbox-dark.xml /root/.local/share/gedit/styles/
}

copy_menu_preferences() {
    # Copies Menu Preferences to appropriate directory, preserving old ones
    local distro=$1

    mkdir -p ~/.config/menus/old
    mv ~/.config/menus/*.menu ~/.config/menus/old
    cp -vnpr .config/menus/$distro/* ~/.config/menus/
}

copy_qbittorrent_config() {
    # Copies Qbittorrent config to appropriate directory, preserving old one
    local distro=$1

    mv ~/.config/qBittorrent/qBittorrent.conf ~/.config/qBittorrent/qBittorrent.conf.old
    mkdir -p ~/.config/qBittorrent/
    cp -vnpr .config/qBittorrent/qBittorrent.conf.$distro ~/.config/qBittorrent/qBittorrent.conf
    cp -vnpr .config/qBittorrent/mumble-dark.qbtheme ~/.config/qBittorrent/
}

copy_libreoffice_config() {
    # Copies LibreOffice config to appropriate directory, preserving old ones
    local distro=$1

    mkdir -p ~/.config/libreoffice
    mv ~/.config/libreoffice/4 ~/.config/libreoffice/4_old
    cp -vnpr .config/libreoffice/$distro ~/.config/libreoffice/4

    sudo mkdir -p /root/.config/libreoffice
    sudo mv /root/.config/libreoffice/4 /root/.config/libreoffice/4_old
    sudo cp -vprf .config/libreoffice/$distro /root/.config/libreoffice/4
}

copy_filezilla_config() {
    # Copies Filezilla config to appropriate directory, preserving old one
    mv ~/.config/filezilla/ ~/.config/filezilla.old
    cp -vnpr .config/filezilla/ ~/.config/
}

copy_profile_picture() {
    # Copies Profile Picture to home directory, preserving old one
    mv ~/.face ~/.faceold
    cp -vnpr .face ~/
}

import_desktop_config() {
    local distro=$1

    # Import Entire Desktop Configuration, preserving old one
    cd theming/$distro/
    dconf dump / > Old_Desktop_Configuration.dconf
    mv Old_Desktop_Configuration.dconf ~/
    dconf load / < $distro.dconf
    rm ~/$distro.dconf
}

# openSUSE Needs Seperate One
apply_gedit_and_gnome_terminal_config() {
    local distro=$1
    local gedit_config=$2

    # Apply gnome-terminal configuration to root
    sudo dbus-launch dconf load / < gnome-terminal-$distro.dconf
    rm ~/gnome-terminal-$distro.dconf
    cd ..

    # Apply gedit configuration to root (with given gedit config)
    sudo dbus-launch dconf load / < $gedit_config
    cd $distro/
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

# NixOS doesn't need this
setup_synth_shell_config() {
    local distro=$1
    # Clone Synth-Shell and run setup
    git clone --recursive https://github.com/andresgongora/synth-shell-prompt.git
    yes | synth-shell-prompt/setup.sh
    yes | sudo synth-shell-prompt/setup.sh
    rm -rf synth-shell-prompt/

    # Place Synth-Shell config, preserving old ones
    mkdir -p ~/.config/synth-shell/old
    cp -vnpr ~/.config/synth-shell/* ~/.config/synth-shell/old
    cp -vprf .config/synth-shell/$distro/* ~/.config/synth-shell/

    sudo mkdir -p /root/.config/synth-shell/old
    sudo cp -vnpr /root/.config/synth-shell/* /root/.config/synth-shell/old
    sudo cp -vprf .config/synth-shell/root-synth-shell-prompt.config /root/.config/synth-shell/synth-shell-prompt.config
}

install_nvchad() {
    # Install NVChad for neovim, preserving old configs
    mv ~/.config/nvim ~/.config/nvim.old
    mv ~/.local/share/nvim ~/.local/share/nvim.old
    mv ~/.cache/nvim ~/.cache/nvim.old
    rm -rf ~/.config/nvim
    rm -rf ~/.local/share/nvim
    rm -rf ~/.cache/nvim

    # Clone NVChad starter config
    git clone https://github.com/NvChad/starter ~/.config/nvim

    # Backup and copy custom chadrc.lua config
    mv ~/.config/nvim/lua/chadrc.lua ~/.config/nvim/lua/chadrc.lua.old
    cp -vpnr .config/nvim/lua/chadrc.lua ~/.config/nvim/lua/

    # Install all mason plugins and quit Neovim
    nvim --headless "+MasonInstallAll" +qa
}

restart_cinnamon() {
    # Restarts Cinnamon
    cinnamon-dbus-command RestartCinnamon 1
}

# NixOS doesn't need this
place_login_wallpaper() {
    # Places Login Wallpaper
    sudo cp -vnr wallpapers/Login_Wallpaper.jpg /boot/
}

# NixOS doesn't need this
configure_nanorc_basic() {
    # Enables basic syntax highlighting in nano, preserving old config
    sudo cp /etc/nanorc /etc/nanorc.old

    if ! grep -q '^include "/usr/share/nano/\*.nanorc"' /etc/nanorc; then
        echo 'include "/usr/share/nano/*.nanorc"' | sudo tee -a /etc/nanorc > /dev/null
    fi
}

# NixOS, Fedora and Gentoo doesn't need this
configure_nanorc_extra() {
    # Adds extra nano syntax highlighting rules
    if ! grep -q '^include "/usr/share/nano/extra/\*.nanorc"' /etc/nanorc; then
        echo 'include "/usr/share/nano/extra/*.nanorc"' | sudo tee -a /etc/nanorc > /dev/null
    fi
}

# NixOS doesn't need this, openSUSE needs 2 ZYPP variables
set_qt_and_gtk_environment() {
    # Sets QT and GTK theming variables, preserving old environment config
    sudo cp /etc/environment /etc/environment.old

    if ! grep -q "^QT_QPA_PLATFORMTHEME=qt5ct" /etc/environment; then
        echo 'QT_QPA_PLATFORMTHEME=qt5ct' | sudo tee -a /etc/environment > /dev/null
    fi

    if ! grep -q "^GTK_THEME=Gruvbox-Dark-BL" /etc/environment; then
        echo 'GTK_THEME=Gruvbox-Dark-BL' | sudo tee -a /etc/environment > /dev/null
    fi
}

# NixOS doesn't need this
append_slick_greeter_config() {
    # Append new settings to slick-greeter.conf, preserving old one
    sudo cp /etc/lightdm/slick-greeter.conf /etc/lightdm/slick-greeter.conf.old
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

# NixOS doesn't need this
append_lightdm_gtk_greeter_config() {
    # Append new settings to lightdm-gtk-greeter.conf, preserving old one
    sudo cp /etc/lightdm/lightdm-gtk-greeter.conf /etc/lightdm/lightdm-gtk-greeter.conf.old
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

