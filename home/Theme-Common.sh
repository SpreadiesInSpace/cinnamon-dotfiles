#!/bin/bash

# TO DO:
# - Make Variables for Theme Related Entries (for Light Mode)
# - Suppress Synth Shell Prompt Output

# Source common functions
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }
cd .. || die "Failed to move up one directory."
[ -f ./Master-Common.sh ] || die "Master-Common.sh not found."
source ./Master-Common.sh || die "Failed to source Master-Common.sh"
cd home/ || die "Failed to return to /home directory."

# Only Theme-Common.sh uses this
check_app() {
  local app="$1"
  local msg="${2:-Skipping $app configuration...}"

  if ! command -v "$app" >/dev/null 2>&1; then
    echo "$app not found. $msg"
    return 1
  fi
  return 0
}

check_dependencies() {
  local missing=()
  local deps=(dconf git gsettings kvantummanager qt5ct qt6ct sudo unzip)

  # Verify array has elements
  if [ ${#deps[@]} -eq 0 ]; then
    die "Internal error: No dependencies defined to check"
  fi

  for cmd in "${deps[@]}"; do
    if ! check_app "$cmd" ""; then  # Empty message to suppress output
      if [ "$cmd" = "dconf" ]; then
        missing+=("dconf (Debian-based systems need 'dconf-cli')")
      else
        missing+=("$cmd")
      fi
    fi
  done

  # Ensure DBus session is available for gsettings/dconf
  if ! env | grep -q '^DBUS_SESSION_BUS_ADDRESS='; then
    missing+=("DBus session")
  fi

  # Check if gsettings can actually read schemas
  if command -v gsettings >/dev/null 2>&1 && ! gsettings list-schemas \
    >/dev/null 2>&1; then
    missing+=("functional gsettings")
  fi

  # If anything is missing, display and exit
  if [ ${#missing[@]} -gt 0 ]; then
    printf '%s\n' "Missing dependencies:"
    for item in "${missing[@]}"; do
      printf '  - %s\n' "$item"
    done
    die "Resolve the above issues before continuing."
  fi
}

prompt_for_vm() {
  if [[ -f ".vm" ]]; then
    is_vm=true
  elif [[ -f ".physical" ]]; then
    is_vm=false
  else
    # Only prompt if neither .vm nor .physical file exists
    while true; do
      read -rp "Is this a Virtual Machine? [y/N]: " response
      if [[ "$response" =~ ^([yY]|[yY][eE][sS])$ ]]; then
        is_vm=true
        break
      elif [[ "$response" =~ ^([nN]|[nN][oO])$ || -z "$response" ]]; then
        is_vm=false
        break
      else
        echo "Invalid input. Please answer y or n."
      fi
    done
  fi
}

install_icons_and_themes() {
  # Download icons and fonts
  sudo echo || die "Failed to gain sudo privileges."
  bash icons-and-fonts.sh || die "Failed to execute icons-and-fonts.sh."

  # Set filenames
  ICON_ZIP="gruvbox-dark-icons-gtk-1.0.0.zip"
  ICON_EXTRACTED="gruvbox-dark-icons-gtk-1.0.0"
  ICON_RENAME="gruvbox-dark-icons-gtk"
  CURSOR_ZIP="Capitaine Cursors (Gruvbox) - White.zip"
  CURSOR_DIR="Capitaine Cursors (Gruvbox) - White"
  THEME_ZIP="1670604530-Gruvbox-Dark-BL.zip"
  THEME_DIR="Gruvbox-Dark-BL"

  # Extract icons
  echo "Extracting Icons..."
  mv .icons/*.zip "$PWD" || \
    die "Failed to move icon zip files."
  unzip -q "$ICON_ZIP" || \
    die "Failed to unzip $ICON_ZIP."
  unzip -q "$CURSOR_ZIP" || \
    die "Failed to unzip $CURSOR_ZIP."
  mv "$ICON_EXTRACTED" ".icons/$ICON_RENAME" || \
    die "Failed to rename extracted icon directory."
  mv "$CURSOR_DIR" .icons/ || \
    die "Failed to move cursor directory."

  # Extract themes
  echo "Extracting Themes..."
  mv .themes/*.zip "$PWD" || \
    die "Failed to move theme zip files."
  unzip -q "$THEME_ZIP" || \
    die "Failed to unzip $THEME_ZIP."
  mv "$THEME_DIR" .themes/ || \
    die "Failed to move extracted theme directory."

  # Always install to user directories
  echo "Installing Icons and Themes..."
  mkdir -p ~/.icons ~/.themes || \
    die "Failed to create user icon or theme directories."
  cp -npr .icons/* ~/.icons/ || \
    die "Failed to copy icons to user directory."
  cp -npr .themes/* ~/.themes/ || \
    die "Failed to copy themes to user directory."

  # If not NixOS, also install to system-wide directories
  if ! grep -qi "nixos" /etc/os-release; then
    sudo cp -npr .icons/* /usr/share/icons/ || \
      die "Failed to copy icons to system directory."
    sudo cp -npr .themes/* /usr/share/themes/ || \
      die "Failed to copy themes to system directory."
  fi

  # Move ZIPs back & clean up
  mv "$CURSOR_ZIP" "$ICON_ZIP" .icons/ || \
    die "Failed to move icon and cursor zip files back."
  mv "$THEME_ZIP" .themes/ || \
    die "Failed to move theme zip file back."
  rm -rf ".icons/$ICON_RENAME" ".icons/$CURSOR_DIR" ".themes/$THEME_DIR" || \
    die "Failed to clean up extracted directories."
}

override_qt_cursor_theme() {
  # Override Cursor Theme for QT Apps
  local distro="${1:-}"

  echo "Setting Cursor Theme Override for QT Apps..."
  if [ "$distro" = "nixos" ]; then
    mkdir -p ~/.icons/default
    rm -rf ~/.icons/default/*
    ln -sf ~/.icons/"Capitaine Cursors (Gruvbox) - White/"* \
      ~/.icons/default/ || \
      die "Failed to override cursor theme."
    sudo mkdir -p /root/.icons/default
    sudo rm -rf /root/.icons/default/*
    sudo ln -sf ~/.icons/"Capitaine Cursors (Gruvbox) - White/"* \
      /root/.icons/default/ || \
      die "Failed to override cursor theme."
  else
    rm -rf ~/.icons/default
    sudo mkdir -p /usr/share/icons/default
    sudo rm -rf /usr/share/icons/default/*
    sudo ln -sf "/usr/share/icons/Capitaine Cursors (Gruvbox) - White/"* \
      /usr/share/icons/default/ || \
      die "Failed to override cursor theme."
  fi
}

enable_flatpak_theme_override() {

  # Ensure flatpak is available
  check_app "flatpak"

  # Ensure Flathub exists
  flatpak remotes | grep -q flathub || {
    flatpak remote-add --if-not-exists flathub \
      https://dl.flathub.org/repo/flathub.flatpakrepo || \
      die "Failed to enable Flathub remote."
  }

  echo "Setting GTK & QT Flatpak Theme Override..."
  # Enable GTK & QT Flatpak Theming Override
  sudo flatpak override --filesystem="$HOME/.themes" || \
    die "Failed to override Flatpak themes directory."
  sudo flatpak override --filesystem="$HOME/.icons" || \
    die "Failed to override Flatpak icons directory."
  sudo flatpak override --env=GTK_THEME=Gruvbox-Dark-BL || \
    die "Failed to override Flatpak GTK themes."
  sudo flatpak override --env=ICON_THEME=gruvbox-dark-icons-gtk || \
    die "Failed to override Flatpak icons."
  sudo flatpak override --filesystem=xdg-config/Kvantum:ro || \
    die "Failed to override Flatpak kvantum themes."
  sudo flatpak override --env=QT_STYLE_OVERRIDE=kvantum || \
    die "Failed to override Flatpak kvantum QT style."
}

copy_bleachbit_config() {
  local distro="${1:-}"
  local timestamp
  timestamp=$(date +%s)
  local src_file=".config/bleachbit/bleachbit.ini.$distro"
  local user_target="$HOME/.config/bleachbit/bleachbit.ini"
  local root_target="/root/.config/bleachbit/bleachbit.ini"

  # Ensure BleachBit is available
  check_app "bleachbit"

  echo "Configuring BleachBit..."
  # Backup and copy BleachBit config to appropriate directories
  if [ -f "$user_target" ]; then
    mv "$user_target" "$user_target.old.$timestamp"
  fi
  mkdir -p "$(dirname "$user_target")"
  cp -npr "$src_file" "$user_target" || \
    die "Failed to copy BleachBit config."

  if sudo test -f "$root_target"; then
    sudo mv "$root_target" "$root_target.old.$timestamp"
  fi
  sudo mkdir -p "$(dirname "$root_target")"
  sudo cp -prf "$src_file" "$root_target" || \
    die "Failed to copy BleachBit config."

  # Extra VM Handling
  if [ "$is_vm" = true ]; then
    # Configure Autostart Entries
    mkdir -p ~/.config/autostart
    cp -npr .config/autostart/"$distro"/* ~/.config/autostart
    # Set up VM Shares
    cp -npr toggle_share.sh ~/
    mkdir -p ~/.local/share/applications
    cp -npr .local/share/applications/toggle-share.desktop \
      ~/.local/share/applications/
  fi
}

copy_fonts() {
  # Copies fonts to appropriate directories
  local distro="${1:-}"

  echo "Setting Fonts..."
  # NixOS doesn’t use /usr/share/fonts/ for user fonts
  if [ "$distro" = "nixos" ]; then
    cp -npr .fonts/ ~/ >/dev/null 2>&1 || true
  else
    sudo cp -npr .fonts/* /usr/share/fonts/ >/dev/null 2>&1 || true
    if [ "$distro" != "arch" ]; then
      mkdir -p ~/.fonts
      sudo ln -sf /usr/share/fonts/* ~/.fonts/ || \
        die "Failed to symlink fonts."
    fi
  fi
}

# Only Slackware/Void uses this
symlink_fonts() {
  # Symlink Fonts for Root
  sudo mkdir -p /root/.fonts
  sudo ln -sf /usr/share/fonts/* /root/.fonts/ || \
    die "Failed to symlink fonts."
}

copy_sounds_and_wallpapers() {
  # Copies sounds and wallpapers to home directory
  bash wallpapers.sh || \
    die "Failed to execute wallpapers.sh."
  cp -npr sounds/ ~/ || \
    die "Failed to copy sounds."
  cp -npr wallpapers/ ~/ || \
    die "Failed to copy wallpapers."
}

copy_applets() {
  # Copies applets to appropriate directories
  local applet_variant=$1
  echo "Configuring Cinnamon Applets..."
  cp -npr .local/share/cinnamon/"$applet_variant"/* \
    ~/.local/share/cinnamon/applets/ || \
    die "Failed to copy applets."
}

copy_kdeglobals() {
  # Creates a timestamp for backup
  local timestamp
  timestamp=$(date +%s)

  echo "Applying Gruvbbox Colors to kdeglobals System-wide..."
  # Backup and copy KDE Global defaults to ~/.config
  if [ -f ~/.config/kdeglobals ]; then
    mv ~/.config/kdeglobals ~/.config/kdeglobals.old."$timestamp"
  fi
  cp -npr .config/kdeglobals ~/.config/ || die "Failed to copy kdeglobals."

  if sudo test -f /root/.config/kdeglobals; then
    sudo mv /root/.config/kdeglobals /root/.config/kdeglobals.old."$timestamp"
  fi
  sudo mkdir -p /root/.config/
  sudo ln -sf ~/.config/kdeglobals /root/.config/ || \
    die "Failed to symlink kdeglobals."
}

symlink_kdeglobals() {
  # Symlink kdeglobals to color-schemes for KDE applications like haruna
  local distro="${1:-}"

  if [ "$distro" = "nixos" ]; then
    sudo mkdir -p ~/.local/share/color-schemes/
    sudo ln -sf ~/.config/kdeglobals \
      ~/.local/share/color-schemes/gruvbox-dark.colors || \
      die "Failed to symlink kdeglobals color schemes."
  else
    sudo mkdir -p /usr/share/color-schemes/
    sudo ln -sf ~/.config/kdeglobals \
      /usr/share/color-schemes/gruvbox-dark.colors || \
      die "Failed to symlink kdeglobals color schemes."
  fi
}

# Void doesn't use this
copy_haruna_config() {
  # Creates a timestamp for backup
  local timestamp
  timestamp=$(date +%s)

  # Ensure haruna is available
  check_app "haruna"

  echo "Configuring Haruna..."
  # Backup and copy Haruna config to appropriate directory
  if [ -d ~/.config/haruna ]; then
    mv ~/.config/haruna ~/.config/haruna.old."$timestamp"
  fi
  cp -npr .config/haruna/ ~/.config/ || \
    die "Failed to copy haruna config."
}

copy_cinnamon_spice_settings() {
  # Backup and copy Cinnamon spice settings
  local distro="${1:-}"
  local timestamp
  timestamp=$(date +%s)
  if [ -d ~/.config/cinnamon/spices ]; then
    mv ~/.config/cinnamon/spices/ ~/.config/cinnamon/spices.old."$timestamp"/
  fi
  mkdir -p ~/.config/cinnamon/spices/

  echo "Applying Cinnamon Spice Settings..."
  # Copy new settings for the specified distro
  cp -npr .config/cinnamon/spices."$distro"/* ~/.config/cinnamon/spices/ || \
    die "Failed to copy Cinnamon spices."
}

copy_personal_shortcuts() {
  # Copies My Personal Shortcuts
  local distro="${1:-}"
  mkdir -p ~/.local/share/applications
  echo "Setting Shortcuts..."
  cp -npr .local/share/applications/"$distro"/* ~/.local/share/applications/ \
    || die "Failed to copy shortcuts."
}

copy_bashrc_and_etc() {
  # Backup and copy .bashrc and etc to home directory
  local distro="${1:-}"
  local timestamp
  timestamp=$(date +%s)

  echo "Backing Up .bashrc and Adding New bash Aliases..."
  # Backup .bashrc.d directory with timestamp
  if [ -d ~/.bashrc.d ]; then
    mv ~/.bashrc.d ~/.bashrc.d.old."$timestamp"
  fi

  # Copy ASCII to /root/ if NixOS
  if [ "$distro" = "NixOS" ]; then
    sudo cp "theming/$distro/NixAscii.txt" /root/ || \
      die "Failed to copy NixOS ASCII."
  fi

  # Copy new .bashrc.d alias scripts to appropriate directory
  mkdir -p ~/.bashrc.d/
  cp -npr ".bashrc.d/$distro.sh" ~/.bashrc.d/  || \
    die "Failed to copy .bashrc.d alias."

  # Preserve and replace user .bashrc with timestamp
  cp ~/.bashrc ~/.bashrc.old."$timestamp" >/dev/null 2>&1 || true
  cp .bashrc ~/.bashrc || \
    die "Failed to copy bashrc."

  # Copies distro-specific theming files to home directory
  cp -npr "theming/$distro/"* ~/  || \
    die "Failed to copy theming files."

  # Preserve old root .bashrc with timestamp
  sudo cp /root/.bashrc /root/.bashrc.old."$timestamp" \
    >/dev/null 2>&1 || true

  # Copy root .bashrc to appropriate directory
  sudo cp -prf root.bashrc /root/.bashrc || \
    die "Failed to copy root .bashrc"
}

copy_neofetch_config() {
  local variant=${1:-default}  # Use "default" if no argument is passed
  local timestamp
  timestamp=$(date +%s)

  # Ensure neofetch is available
  check_app "neofetch"

  echo "Configuring neofetch..."
  # Backup and copy neofetch config file to appropriate directory
  neofetch >/dev/null 2>&1 || true
  mv ~/.config/neofetch/config.conf \
    ~/.config/neofetch/config.conf.old."$timestamp" || true

  # Check if the variant-specific config file exists
  if [ "$variant" != "default" ] &&
    [ -f ".config/neofetch/config.conf.$variant" ]; then
    cp -npr ".config/neofetch/config.conf.$variant" \
      ~/.config/neofetch/config.conf || \
      die "Failed to copy neofetch config."
  else
    cp -npr ".config/neofetch/config.conf" \
      ~/.config/neofetch/config.conf || \
      die "Failed to copy neofetch config."
  fi

  # Preserve and replace root's neofetch config
  sudo neofetch >/dev/null 2>&1 || true
  sudo mv /root/.config/neofetch/config.conf \
    /root/.config/neofetch/config.conf.old."$timestamp" || true
  sudo ln -sf ~/.config/neofetch/config.conf \
    /root/.config/neofetch/config.conf || \
    die "Failed to symlink neofetch config."
}

copy_kvantum_themes() {
  # Backup and copy Kvantum Themes to appropriate directory
  local theme_variant="${1:-}"
  local distro="${2:-}"
  local timestamp
  timestamp=$(date +%s)

  echo "Installing Kvantum Themes..."
  if [ "$distro" = "nixos" ]; then
    mv ~/.config/Kvantum ~/.config/Kvantum.old."$timestamp" \
      >/dev/null 2>&1 || true
    cp -npr .config/Kvantum/ ~/.config/ || \
      die "Failed to copy kvantum config."
    echo "" >> ~/.config/Kvantum/kvantum.kvconfig || \
      die "Failed to append kvantum config."
    echo "[Applications]
Gruvbox-Dark-Brown=kdeconnect-app, kdeconnect-sms" >> \
      ~/.config/Kvantum/kvantum.kvconfig || \
      die "Failed to append kvantum config."
    sudo mv /root/.config/Kvantum /root/.config/Kvantum.old."$timestamp" \
      >/dev/null 2>&1 || true
    kvantummanager --set gruvbox-fallnn || \
      die "Failed to set kvantum theme."
    sudo ln -sf ~/.config/Kvantum /root/.config/ || \
      die "Failed to symlink kvantum config."
  else
    mv ~/.config/Kvantum ~/.config/Kvantum.old."$timestamp" \
      >/dev/null 2>&1 || true
    cp -npr .config/Kvantum/ ~/.config/ || \
      die "Failed to copy kvantum config."
    sudo mv /root/.config/Kvantum /root/.config/Kvantum.old."$timestamp" \
      >/dev/null 2>&1 || true
    kvantummanager --set "$theme_variant" || \
      die "Failed to set kvantum theme."
    sudo ln -sf ~/.config/Kvantum /root/.config/ || \
      die "Failed to symlink kvantum config."
  fi
}

copy_qtct_configs() {
  # Backup and copy qt5ct & qt6ct config to appropriate directories
  local timestamp
  timestamp=$(date +%s)

  echo "Applying Kvantum Themes System-wide..."
  # Handle qt5ct
  mv ~/.config/qt5ct ~/.config/qt5ct.old."$timestamp" \
    >/dev/null 2>&1 || true
  cp -npr .config/qt5ct/ ~/.config/ || \
    die "Failed to copy qt5ct config."
  sudo mv /root/.config/qt5ct /root/.config/qt5ct.old."$timestamp" \
    >/dev/null 2>&1 || true
  sudo ln -sf ~/.config/qt5ct/ /root/.config/ || \
    die "Failed to symlink qt5ct config."

  # Handle qt6ct
  mv ~/.config/qt6ct ~/.config/qt6ct.old."$timestamp" \
    >/dev/null 2>&1 || true
  cp -npr .config/qt6ct/ ~/.config/ || \
    die "Failed to copy qt6ct config."
  sudo mv /root/.config/qt6ct /root/.config/qt6ct.old."$timestamp" \
    >/dev/null 2>&1 || true
  sudo ln -sf ~/.config/qt6ct/ /root/.config/ || \
    die "Failed to symlink qt6ct config."
}

copy_gedit_theme() {
  # Copies Gedit Theme to appropriate directory

  # Ensure gedit is available
  check_app "gedit"

  # User directory
  mkdir -p ~/.local/share/libgedit-gtksourceview-300/styles
  cp -npr gruvbox-dark-gedit46.xml \
    ~/.local/share/libgedit-gtksourceview-300/styles || \
    die "Failed to copy gedit theme."

  # Root directory
  sudo mkdir -p /root/.local/share/libgedit-gtksourceview-300/styles
  sudo cp -prf gruvbox-dark-gedit46.xml \
    /root/.local/share/libgedit-gtksourceview-300/styles || \
    die "Failed to copy gedit theme."
}

# Gentoo/LMDE uses this
copy_gedit_old_theme() {
  # Copies Gedit Theme to appropriate directory

  # Ensure gedit is available
  check_app "gedit"

  # User directory
  mkdir -p ~/.local/share/gedit/styles
  cp -npr gruvbox-dark.xml ~/.local/share/gedit/styles/ || \
    die "Failed to copy gedit theme."

  # Root directory
  sudo mkdir -p /root/.local/share/gedit/styles
  sudo cp -prf gruvbox-dark.xml /root/.local/share/gedit/styles/ || \
    die "Failed to copy gedit theme."
}

copy_menu_preferences() {
  # Backup and copy Menu Preferences to appropriate directory
  local distro="${1:-}"
  local timestamp
  timestamp=$(date +%s)

  echo "Applying Cinnamon Menu Preferences..."
  # Create timestamped backup directory and move old menu preferences
  cp -npr ~/.config/menus/ ~/.config/menus.old."$timestamp"/ || true
  mkdir -p ~/.config/menus/
  # Copy new menu preferences for the specified distro
  cp -npr .config/menus/"$distro"/* ~/.config/menus/ || \
    die "Failed to copy menu config."
}

copy_qbittorrent_config() {
  # Backup and copy Qbittorrent config to appropriate directory
  local distro="${1:-}"
  local timestamp
  timestamp=$(date +%s)

  # Ensure qBittorrent is available
  check_app "qbittorrent"

  echo "Configuring qBittorrent..."
  # Backup the old config with timestamp
  mv ~/.config/qBittorrent/qBittorrent.conf \
    ~/.config/qBittorrent/qBittorrent.conf.old."$timestamp" \
    >/dev/null 2>&1 || true
  mkdir -p ~/.config/qBittorrent/

  # Copy distro-specific config
  cp -npr .config/qBittorrent/qBittorrent.conf."$distro" \
    ~/.config/qBittorrent/qBittorrent.conf || \
    die "Failed to copy qBittorrent config."
  cp -npr .config/qBittorrent/mumble-dark.qbtheme \
    ~/.config/qBittorrent/ || \
    die "Failed to copy qBittorrent theme."
}

copy_libreoffice_config() {
  # Backup and copy LibreOffice config to appropriate directory
  local distro="${1:-}"
  local timestamp
  timestamp=$(date +%s)

  # Ensure LibreOffice is available
  if grep -qi "gentoo" /etc/os-release; then
    check_app "libreoffice-bin"
  else
    check_app "libreoffice"
  fi

  echo "Configuring LibreOffice..."
  # User-side config
  mkdir -p ~/.config/libreoffice
  mv ~/.config/libreoffice/4 ~/.config/libreoffice/4.old."$timestamp" \
    >/dev/null 2>&1 || true
  cp -npr .config/libreoffice/"$distro" ~/.config/libreoffice/4 || \
    die "Failed to copy LibreOffice config."

  # Root-side config
  sudo mkdir -p /root/.config/libreoffice
  sudo mv /root/.config/libreoffice/4 \
    /root/.config/libreoffice/4.old."$timestamp" >/dev/null 2>&1 || true
  sudo cp -prf .config/libreoffice/"$distro" /root/.config/libreoffice/4 || \
    die "Failed to copy LibreOffice config."
}

copy_filezilla_config() {
  # Backup and copy Filezilla config to appropriate directory
  local timestamp
  timestamp=$(date +%s)

  # Ensure FileZilla is available
  check_app "filezilla"

  echo "Configuring FileZilla..."
  # Backup the old config with timestamp
  mv ~/.config/filezilla ~/.config/filezilla.old."$timestamp" \
    >/dev/null 2>&1 || true
  cp -npr .config/filezilla/ ~/.config/ || \
    die "Failed to copy FileZilla config."
}

copy_profile_picture() {
  # Backup and copy Profile Picture to home directory
  local timestamp
  timestamp=$(date +%s)

  echo "Setting Profile Picture..."
  # Create timestamped backup for the old profile picture
  mv ~/.face ~/.face.old."$timestamp" >/dev/null 2>&1 || true

  # Copy new profile picture
  cp -npr .face ~/ || \
    die "Failed to set profile picture."
}

import_desktop_config() {
  local distro="${1:-}"
  local timestamp
  timestamp=$(date +%s)

  echo "Applying Proper Look & Feel System-wide..."
  # Backup and Import Entire Desktop Configuration
  dconf dump / > Old_Desktop_Configuration_"$timestamp".dconf || \
    die "Failed to back up old dconf settings."
  dconf load / < "theming/$distro/$distro.dconf" || \
    die "Failed to apply dconf settings."
  # Remove dconf copied from earlier functions
  rm ~/"$distro".dconf >/dev/null 2>&1 || true
}

apply_gedit_and_gnome_terminal_config() {
  # Apply gedit and gnome-terminal configuration to root
  local distro="${1:-}"
  local gedit_config="${2:-}"

  # Ensure gedit and gnome-terminal is available
  check_app "gedit"
  check_app "gnome-terminal"

  if [[ "$distro" == "openSUSE" ]]; then
    # Use gnomesu for openSUSE
    cat "theming/$distro/gnome-terminal-$distro.dconf" \
        "theming/$gedit_config" > combined.dconf
    gnomesu dconf load / < "combined.dconf" || \
      die "Failed to apply gedit and/or gnome-terminal dconf."
    rm combined.dconf >/dev/null 2>&1 || true
  else
    # Use sudo cat with pipe for other distros
    sudo cat "theming/$distro/gnome-terminal-$distro.dconf" | \
      sudo dbus-launch dconf load / || \
      die "Failed to apply gnome-terminal dconf."
    sudo cat "theming/$gedit_config" | sudo dbus-launch dconf load / || \
      die "Failed to apply gedit dconf."
  fi
  # Remove gnome-terminal dconf copied from earlier functions
  rm ~/gnome-terminal-"$distro".dconf >/dev/null 2>&1 || true
  # Set gedit sidebar root to user's home directory
  dconf write /org/gnome/gedit/plugins/filebrowser/virtual-root \
    "'file:///home/$(whoami)'" || die "Failed to apply gedit settings."

  # Gentoo gedit admin:///etc/portage/make.conf INI syntax highlighting
  if [[ "$distro" == "Gentoo" ]]; then
    # Create the local language specs directory
    mkdir -p ~/.local/share/libgedit-gtksourceview-300/language-specs
    # Copy the existing INI language specification
    cp /usr/share/libgedit-gtksourceview-300/language-specs/ini.lang \
      ~/.local/share/libgedit-gtksourceview-300/language-specs/ || \
      die "Failed to copy existing INI language specification."
    # Add make.conf to the globs pattern in the INI language spec
    sed -i 's/<property name="globs">\([^<]*\)</<property name="globs">\1;make.conf</' \
      ~/.local/share/libgedit-gtksourceview-300/language-specs/ini.lang || \
      die "Failed to add make.conf to globs pattern in INI language spec."
  fi
}

set_default_apps() {
  local distro="${1:-}"

  echo "Setting Default Apps..."
  # Set default apps for the given distro
  chmod +x theming/"$distro"/Default-Apps-"$distro".sh
  bash theming/"$distro"/Default-Apps-"$distro".sh || true
  sudo bash theming/"$distro"/Default-Apps-"$distro".sh || true
  rm ~/Default-Apps-"$distro".sh >/dev/null 2>&1 || true
}

copy_vscodium_config() {
  # Ensure VSCodium is available
  check_app "codium"

  # Backup VSCodium config & plugins
  local timestamp
  timestamp=$(date +%s)

  echo "Configuring VSCodium..."
  if [ -d ~/.config/VSCodium ]; then
    mv ~/.config/VSCodium ~/.config/VSCodium.old."$timestamp"
  fi
  if [ -d ~/.vscode-oss ]; then
    mv ~/.vscode-oss ~/.vscode-oss.old."$timestamp"
  fi

  # Cleanup function
  cleanup_codium() {
    cd .. 2>/dev/null || true
    rm -rf codium/ 2>/dev/null || true
  }

  # Copy VSCodium config and plugins to appropriate directory
  retry git clone https://github.com/spreadiesinspace/codium \
    >/dev/null 2>&1 || \
    die "Failed to download VSCodium config."

  cd codium/ || {
    cleanup_codium
    die "Failed to move to codium folder."
  }

  cp -npr VSCodium/ ~/.config/ || {
    cleanup_codium
    die "Failed to copy VSCodium config."
  }

  bash extensions-restore.sh >/dev/null 2>&1 || {
    cleanup_codium
    die "Failed to install VSCodium extensions."
  }

  bash Default-Apps-VSCodium.sh || {
    cleanup_codium
    die "Failed to set VSCodium as default editor."
  }

  # Normal cleanup
  cleanup_codium
}

# Only Fedora/LMDE/NixOS uses this
set_cinnamon_menu_icon() {

  echo "Setting Cinnamon Menu Icon..."
  # Replaces hardcoded Cinnamon menu icon path with $HOME-based path
  local icon_file="$1"
  local json_file="${HOME}/.config/cinnamon/spices/menu@cinnamon.org/0.json"
  local original_path="/home/f16poom/${icon_file}"
  local new_path="${HOME}/.icons/${icon_file}"

  # Replace the hardcoded path with $HOME-based path on line 91
  sed -i "91s|\"value\": \"${original_path}\"|\"value\": \"${new_path}\"|g" \
    "$json_file" || \
    die "Failed to set menu icon path."

  # Move the icon file to .icons
  mv ~/"$icon_file" ~/.icons/ || \
    die "Failed to move menu icon."
}

set_cinnamon_background_and_sounds() {

  echo "Setting Wallpaper..."
  # Set Wallpaper
  if [ "$is_vm" = true ]; then
    wallpaper="Desktop_Wallpaper.png"
  else
    wallpaper="Desktop_Wallpaper_Dark.png"
  fi
  gsettings set org.cinnamon.desktop.background picture-uri \
    "file://${HOME}/wallpapers/${wallpaper}" || \
    die "Failed to set wallpaper."
  mkdir -p ~/Pictures
  ln -sf ~/wallpapers/* ~/Pictures || \
    die "Failed to symlink Pictures."
  gsettings set org.cinnamon.desktop.background.slideshow image-source \
    directory://"${HOME}"/Pictures || \
    die "Failed to set wallpaper directory."

  echo "Setting Cinnamon Sound Events..."
  # Set Login Sounds
  gsettings set org.cinnamon.sounds login-enabled true || \
    die "Failed to enable log-in sound."
  gsettings set org.cinnamon.sounds login-file "${HOME}"/sounds/login.oga || \
    die "Failed to set log-in sound."
  gsettings set org.cinnamon.sounds logout-enabled true || \
    die "Failed to enable log-out sound."
  gsettings set org.cinnamon.sounds logout-file "${HOME}"/sounds/logout.ogg \
    || die "Failed to set log-out sound."

  # Set Volume Toggle Sound
  gsettings set org.cinnamon.desktop.sound volume-sound-enabled true || \
    die "Failed to enable volume toggle sound."
  gsettings set org.cinnamon.desktop.sound volume-sound-file \
    "${HOME}"/sounds/volume.oga || \
    die "Failed to set volume toggle sound."

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
    gsettings set org.cinnamon.sounds $key false || \
      die "Failed to disable $key"
  done
}

setup_synth_shell_config() {
  local distro="${1:-}"
  local timestamp
  timestamp=$(date +%s)

  echo "Configuring Synth Shell Prompt..."
  # Ensure synth-shell-prompt is removed if script fails
  trap 'rm -rf synth-shell-prompt/' ERR INT TERM

  # Clone Synth-Shell and run setup
  retry git clone --recursive \
    https://github.com/andresgongora/synth-shell-prompt.git >/dev/null 2>&1 \
    || die "Failed to download Synth Shell Prompt."
  yes "no" | synth-shell-prompt/setup.sh >/dev/null 2>&1
  yes "no" | sudo synth-shell-prompt/setup.sh >/dev/null 2>&1
  rm -rf synth-shell-prompt/

  # Place Synth-Shell config, preserving old ones with timestamped backup
  cp -npr ~/.config/synth-shell/ ~/.config/synth-shell.old."$timestamp"/ \
    || true
  cp -prf .config/synth-shell/"$distro"/* ~/.config/synth-shell/ || \
    die "Failed to copy Synth Shell config."
  sudo cp -npr /root/.config/synth-shell/ \
    /root/.config/synth-shell.old."$timestamp"/ || true
  sudo cp -prf .config/synth-shell/root-synth-shell-prompt.config \
    /root/.config/synth-shell/synth-shell-prompt.config || \
    die "Failed to copy Synth Shell config."
}

install_nvchad() {

  # Ensure nvim is available
  check_app "nvim"

  # Timestamp for unique backups
  local timestamp
  timestamp=$(date +%s)

  echo "Configuring NvChad..."
  # Backup existing NVim configs if they exist
  [ -d ~/.config/nvim ] && mv ~/.config/nvim ~/.config/nvim.old."$timestamp"
  [ -d ~/.local/share/nvim ] && mv \
    ~/.local/share/nvim ~/.local/share/nvim.old."$timestamp"
  [ -d ~/.cache/nvim ] && mv ~/.cache/nvim ~/.cache/nvim.old."$timestamp"

  # Clone NVChad starter config
  retry git clone https://github.com/NvChad/starter ~/.config/nvim \
    >/dev/null 2>&1 || \
    die "Failed to download NvChad."

  # Backup and copy custom chadrc.lua config
  [ -f ~/.config/nvim/lua/chadrc.lua ] && mv ~/.config/nvim/lua/chadrc.lua \
    ~/.config/nvim/lua/chadrc.lua.old."$timestamp"
  cp -npr .config/nvim/lua/chadrc.lua ~/.config/nvim/lua/ || \
    die "Failed to set NVChad theme to gruvbox."

  # Install all mason plugins and quit Neovim
  nvim --headless "+MasonInstallAll" +qa >/dev/null 2>&1
}

# NixOS doesn't use this
place_login_wallpaper() {
  echo "Setting Login Wallpaper..."
  # Places Login Wallpaper
  sudo cp -nr wallpapers/Login_Wallpaper.jpg /boot/ || \
    die "Failed to set Login Wallpaper."
}

# NixOS doesn't use this
configure_nanorc_basic() {
  # Backup old config and enable basic syntax highlighting in nano
  local timestamp
  timestamp=$(date +%s)

  # Ensure nano is available
  check_app "nano"

  # Backup the old nanorc file with timestamp
  sudo cp /etc/nanorc /etc/nanorc.old."$timestamp" >/dev/null 2>&1 || true

  # Add Syntax Highlighting and soft wrap
  echo "Configuring nano..."
  if ! grep -q '^include "/usr/share/nano/\*.nanorc"' /etc/nanorc; then
    echo 'include "/usr/share/nano/*.nanorc"' | sudo tee -a /etc/nanorc > \
      /dev/null || \
      die "Failed to enable syntax highlighting for nano."
  fi
  if ! grep -q '^set softwrap' /etc/nanorc; then
    echo 'set softwrap' | sudo tee -a /etc/nanorc > /dev/null || \
      die "Failed to enable softwrap for nano."
  fi
  if ! grep -q '^set atblanks' /etc/nanorc; then
    echo 'set atblanks' | sudo tee -a /etc/nanorc > /dev/null || \
      die "Failed to enable set atblanks for nanorc."
  fi
}

# Fedora/Gentoo/NixOS doesn't use this
configure_nanorc_extra() {

  # Ensure nano is available
  check_app "nano"

  # Adds extra nano syntax highlighting rules
  if ! grep -q '^include "/usr/share/nano/extra/\*.nanorc"' /etc/nanorc; then
    echo 'include "/usr/share/nano/extra/*.nanorc"' | \
      sudo tee -a /etc/nanorc > /dev/null || \
        die "Failed to enable extra syntax highlighting for nano."
  fi
}

# NixOS doesn't use this
set_qt_and_gtk_environment() {
  # Backup old config and set QT and GTK theming variables
  local timestamp
  timestamp=$(date +%s)

  echo "Setting QT and GTK Theme Variables..."
  # Backup the old environment file with timestamp
  sudo cp /etc/environment /etc/environment.old."$timestamp" \
    >/dev/null 2>&1 || true

  # Set QT and GTK theming variables if not already present
  if ! grep -q "^QT_QPA_PLATFORMTHEME=qt5ct" /etc/environment; then
    echo 'QT_QPA_PLATFORMTHEME=qt5ct' | \
      sudo tee -a /etc/environment > /dev/null || \
        die "Failed to override QT theme in /etc/environment."
  fi
  if ! grep -q "^GTK_THEME=Gruvbox-Dark-BL" /etc/environment; then
    echo 'GTK_THEME=Gruvbox-Dark-BL' | \
      sudo tee -a /etc/environment > /dev/null || \
        die "Failed to override GTK theme in /etc/environment."
  fi

  # Set HiDPI for QT Apps
  if ! grep -q "^QT_AUTO_SCREEN_SCALE_FACTOR=1" /etc/environment; then
    echo 'QT_AUTO_SCREEN_SCALE_FACTOR=1' | \
      sudo tee -a /etc/environment > /dev/null || \
        die "Failed to enable QT automatic DPI scaling detection."
  fi
  if ! grep -q "^QT_ENABLE_HIGHDPI_SCALING=1" /etc/environment; then
    echo 'QT_ENABLE_HIGHDPI_SCALING=1' | \
      sudo tee -a /etc/environment > /dev/null || \
        die "Failed to enable QT HiDPI scaling support."
  fi
}

# NixOS doesn't use this
append_slick_greeter_config() {
  # Backup old config and append new settings to slick-greeter.conf
  local timestamp
  timestamp=$(date +%s)

  echo "Configuring LightDM Greeter..."
  # Backup the old slick-greeter.conf with timestamp
  sudo cp /etc/lightdm/slick-greeter.conf \
    /etc/lightdm/slick-greeter.conf.old."$timestamp" \
    >/dev/null 2>&1 || true

  # Append new settings to slick-greeter.conf
  echo "[Greeter]
show-hostname=true
theme-name=Gruvbox-Dark-BL
icon-theme-name=gruvbox-dark-icons-gtk
cursor-theme-name=Capitaine Cursors (Gruvbox) - White
clock-format=%a, %-e %b %-l:%M %p
background=/boot/Login_Wallpaper.jpg
logo=
draw-user-backgrounds=false" | \
  sudo tee /etc/lightdm/slick-greeter.conf >/dev/null || true
}

# NixOS doesn't use this
append_lightdm_gtk_greeter_config() {
  # Backup old config and append new settings to lightdm-gtk-greeter.conf
  local timestamp
  timestamp=$(date +%s)

  # Backup the old lightdm-gtk-greeter.conf with timestamp
  sudo cp /etc/lightdm/lightdm-gtk-greeter.conf \
    /etc/lightdm/lightdm-gtk-greeter.conf.old."$timestamp" >/dev/null 2>&1

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
hide-user-image = true" | \
  sudo tee /etc/lightdm/lightdm-gtk-greeter.conf > /dev/null || true
}

restart_cinnamon() {
  echo "Restarting Cinnamon..."
  # Restarts Cinnamon
  cinnamon-dbus-command RestartCinnamon 1 >/dev/null 2>&1 || true
}

print_finish_message() {
  echo "Theme installation complete! Log out and back in to apply changes."
}
