#!/bin/bash
echo
./icons-and-fonts.sh
# Copies icons and themes to appropriate directories
mv .icons/*.zip ${PWD}
unzip Capitaine\ Cursors\ \(Gruvbox\)\ -\ White.zip
unzip gruvbox-dark-icons-gtk-1.0.0.zip
mv gruvbox-dark-icons-gtk-1.0.0 .icons/gruvbox-dark-icons-gtk
mv Capitaine\ Cursors\ \(Gruvbox\)\ -\ White .icons/
cp -vnpr .icons/* /usr/share/icons/
mkdir -p ~/.icons
cp -vnpr .icons/* ~/.icons/
mv Capitaine\ Cursors\ \(Gruvbox\)\ -\ White.zip .icons/
mv gruvbox-dark-icons-gtk-1.0.0.zip .icons/
rm -rf .icons/Capitaine\ Cursors\ \(Gruvbox\)\ -\ White
rm -rf .icons/gruvbox-dark-icons-gtk
mv .themes/*.zip ${PWD}
unzip 1670604530-Gruvbox-Dark-BL.zip
mv Gruvbox-Dark-BL .themes/
cp -vnpr .themes/* /usr/share/themes/
mkdir -p ~/.themes
cp -vnpr .themes/* ~/.themes/
mv 1670604530-Gruvbox-Dark-BL.zip .themes/
rm -rf .themes/Gruvbox-Dark-BL/

# Override Cursor Theme for QT Apps
rm -rf ~/.icons/default
mkdir -p /usr/share/icons/default
rm -rf /usr/share/icons/default/*
ln -s /usr/share/icons/Capitaine\ Cursors\ \(Gruvbox\)\ -\ White/* /usr/share/icons/default/

# Enable GTK & QT Flatpak Theming Override
flatpak override --filesystem=$HOME/.themes
flatpak override --filesystem=$HOME/.icons
flatpak override --env=GTK_THEME=Gruvbox-Dark-BL
flatpak override --env=ICON_THEME=gruvbox-dark-icons-gtk
flatpak override --filesystem=xdg-config/Kvantum:ro
flatpak override --env=QT_STYLE_OVERRIDE=kvantum

# Copies Brave config to appropriate directories, preserving old one
# mv ~/.config/BraveSoftware ~/.config/BraveSoftware.old
# cp -vnpr .config/BraveSoftware/ ~/.config/

# Copies fonts to appropriate directories
# cp -vnpr .fonts/ ~/
cp -vnpr .fonts/* /usr/share/fonts/
mkdir -p ~/.fonts
ln -s /usr/share/fonts/* ~/.fonts/

# Copies system sounds to home directory
cp -vnpr sounds/ ~/

# Copies wallpapers to home directory
cp -vnpr wallpapers/ ~/

# Copies applets to appropriate directories
cp -vnpr .local/share/cinnamon/applets.puppy/* ~/.local/share/cinnamon/applets/

# Copies KDE Global Cinnamon defaults to ~/.config, preserving old one
mv ~/.config/kdeglobals ~/.config/kdeglobals.old
cp -vnpr .config/kdeglobals ~/.config/
# mv /root/.config/kdeglobals /root/.config/kdeglobals.old
# cp -vnpr .config/kdeglobals /root/.config/

# Symlink kdeglobals to color-schemes for KDE applications like haruna
mkdir -p /usr/share/color-schemes/
ln -sf ~/.config/kdeglobals /usr/share/color-schemes/gruvbox-dark.colors

# Copies haruna config to appropriate directory, preserving old config
mv ~/.config/haruna ~/.config/haruna.old
cp -vnpr .config/haruna/ ~/.config/

# Copies Cinnamon spice settings, preserving old ones
mkdir -p ~/.config/cinnamon/spices/old
mv ~/.config/cinnamon/spices/* ~/.config/cinnamon/spices/old
cp -vnpr .config/cinnamon/spices.puppy/* ~/.config/cinnamon/spices/

# Copies My Personal Shortcuts
mkdir -p ~/.local/share/applications
cp -vnpr .local/share/applications/puppy/* ~/.local/share/applications/

# Copies .bashrc to home directory, preserving old one
cd theming/
cp -vnpr Puppy/* ~/
# cp /root/.bashrc /root/.bashrc.old
# cp Puppy/.bashrc /root/.bashrc
cp ~/.bashrc ~/.bashrc.old
cat Puppy/.bashrc > bashrc
mv bashrc ~/.bashrc
cd ..

# Turn off Puppy tray icons & autostart NetworkManager
rm -rf ~/.config/autostart/
mkdir -p ~/.config/autostart/
cp -vnpr .config/autostart/puppy/*  ~/.config/autostart/

# Copies neofetch config file to appropriate directory, preserving old one
neofetch
mv ~/.config/neofetch/config.conf ~/.config/neofetch/config.conf.old
cp -vnpr .config/neofetch/config.conf.puppy ~/.config/neofetch/config.conf
neofetch
# mv /root/.config/neofetch/config.conf /root/.config/neofetch/config.conf.old
# cp -vprf .config/neofetch/config.conf.puppy /root/.config/neofetch/config.conf

# Copies Kvantum Themes to appropriate directory and installs them, preserving old config
mv ~/.config/Kvantum ~/.config/Kvantum.old
cp -vnpr .config/Kvantum/ ~/.config/
kvantummanager --set gruvbox-fallnn

# Copies qt5ct & qt6ct config to appropriate directories, preserving old ones
mv ~/.config/qt5ct ~/.config/qt5ct.old
cp -vnpr .config/qt5ct/ ~/.config/
mv ~/.config/qt6ct ~/.config/qt6ct.old
cp -vnpr .config/qt6ct/ ~/.config/
# sudo mv /root/.config/qt5ct /root/.config/qt5ct.old
# sudo cp -vprf .config/qt5ct/ /root/.config/
# sudo ln -s ~/.config/qt5ct/ /root/.config/
# sudo mv /root/.config/qt6ct /root/.config/qt6ct.old
# sudo cp -vprf .config/qt6ct/ /root/.config/
# sudo ln -s ~/.config/qt6ct/ /root/.config/

# Copies Gedit Theme to appropriate directory
mkdir -p ~/.local/share/gedit/styles
cp -vnpr gruvbox-dark.xml ~/.local/share/gedit/styles/
# mkdir -p /root/.local/share/gedit/styles
# cp -vprf gruvbox-dark.xml /root/.local/share/gedit/styles/

# Copies Menu Preferences to appropriate directory
mkdir -p ~/.config/menus/old
mv ~/.config/menus/*.menu ~/.config/menus/old
cp -vnpr .config/menus/puppy/* ~/.config/menus/
cp -vnpr .local/share/desktop-directories/ ~/.local/share/

# Copies Qbittorent config to appropriate directory, preserving old one
mv ~/.config/qBittorrent/qBittorrent.conf ~/.config/qBittorrent/qBittorrent.conf.old
mkdir -p ~/.config/qBittorrent/
cp -vnpr .config/qBittorrent/qBittorrent.conf.arch ~/.config/qBittorrent/qBittorrent.conf
cp -vnpr .config/qBittorrent/mumble-dark.qbtheme ~/.config/qBittorrent/

# Copies LibreOffice config to appropriate directory, preserving old ones
mkdir -p ~/.config/libreoffice
mv ~/.config/libreoffice/4 ~/.config/libreoffice/4_old
cp -vpnr .config/libreoffice/arch ~/.config/libreoffice/4
# mkdir -p /root/.config/libreoffice
# mv /root/.config/libreoffice/4 /root/.config/libreoffice/4_old
# cp -vprf .config/libreoffice/arch /root/.config/libreoffice/4

# Copies Filezilla config to appropriate directory, preserving old one
mv ~/.config/filezilla/ ~/.config/filezilla.old
cp -vnpr .config/filezilla/ ~/.config/

# Copies Profile Picture to home directory, preserving old one
mv ~/.face ~/.faceold
cp -vnpr .face ~/

# Import Entire Desktop Configuration, preserving old one
cd theming/Puppy/
dconf dump / > Old_Desktop_Configuration.dconf
mv Old_Desktop_Configuration.dconf ~/
dconf load / < Puppy.dconf
rm ~/Puppy.dconf

# Sets Default Apps
chmod +x Default-Apps-Puppy.sh
./Default-Apps-Puppy.sh
rm ~/Default-Apps-Puppy.sh
cd ../..

# Define the home directory (For Menu Applet Icon)
home_dir="${HOME}"
# Define the path to JSON file
json_file="${home_dir}/.config/cinnamon/spices/menu@cinnamon.org/0.json"
# Use sed to replace /home/f16poom with the home directory in the value field on line 91
sed -i "91s|\"value\": \"/home/f16poom/linuxmint-logo-filled-ring.svg\"|\"value\": \"${home_dir}/.icons/linuxmint-logo-filled-ring.svg\"|g" $json_file
mv ~/linuxmint-logo-filled-ring.svg ~/.icons/

# Sets Wallpaper
gsettings set org.cinnamon.desktop.background picture-uri file://${HOME}/wallpapers/Desktop_Wallpaper.png
mkdir -p ~/Pictures
ln -s ~/wallpapers/* ~/Pictures
gsettings set org.cinnamon.desktop.background.slideshow image-source directory://${HOME}/Pictures

# Sets Login Sounds
gsettings set org.cinnamon.sounds login-enabled true
gsettings set org.cinnamon.sounds login-file ${HOME}/sounds/login.oga
gsettings set org.cinnamon.sounds logout-enabled true
gsettings set org.cinnamon.sounds logout-file ${HOME}/sounds/logout.ogg

# Sets Volume Toggle Sound
gsettings set org.cinnamon.desktop.sound volume-sound-enabled true
gsettings set org.cinnamon.desktop.sound volume-sound-file ${HOME}/sounds/volume.oga

# Sets Nemo to run as root normally
gsettings set org.nemo.preferences treat-root-as-normal true

# Install Synth-Shell Prompt
git clone --recursive https://github.com/andresgongora/synth-shell-prompt.git
yes | synth-shell-prompt/setup.sh
# yes | synth-shell-prompt/setup.sh
rm -rf synth-shell-prompt/
# Places My Synth-Shell Config, preserving old ones
mkdir -p ~/.config/synth-shell/old
cp -vnpr ~/.config/synth-shell/* ~/.config/synth-shell/old
cp -vprf .config/synth-shell/fedora/* ~/.config/synth-shell/
# mkdir -p /root/.config/synth-shell/old
# cp -vnpr /root/.config/synth-shell/* /root/.config/synth-shell/old
# cp -vprf .config/synth-shell/root-synth-shell-prompt.config /root/.config/synth-shell/synth-shell-prompt.config

# Install NVChad for neovim, preserving old configs
mv ~/.config/nvim ~/.config/nvim.old
mv ~/.local/share/nvim ~/.local/share/nvim.old
mv ~/.cache/nvim ~/.cache/nvim.old
rm -rf ~/.config/nvim
rm -rf ~/.local/share/nvim
rm -rf ~/.cache/nvim
git clone https://github.com/NvChad/starter ~/.config/nvim
mv ~/.config/nvim/lua/chadrc.lua ~/.config/nvim/lua/chadrc.lua.old
cp -vpnr .config/nvim/lua/chadrc.lua ~/.config/nvim/lua/
nvim --headless "+MasonInstallAll" +qa

# Restarts Cinnamon
cinnamon-dbus-command RestartCinnamon 1

# Places Login Wallpaper
cp -vnr wallpapers/Login_Wallpaper.jpg /boot/

# Check if syntax highlighting configurations are already in nanorc, preserving old one
cp /etc/nanorc /etc/nanorc.old
if ! grep -q "^include \"/usr/share/nano/\*.nanorc\"" /etc/nanorc; then
	echo 'include "/usr/share/nano/*.nanorc"' | tee -a /etc/nanorc
fi
if ! grep -q "^include \"/usr/share/nano/extra/\*.nanorc\"" /etc/nanorc; then
	echo 'include "/usr/share/nano/extra/*.nanorc"' | tee -a /etc/nanorc
fi

# Check if environment variables for QT & Additional Theming are already set, preserving old one
cp /etc/environment /etc/environment.old
if ! grep -q "^QT_QPA_PLATFORMTHEME=qt5ct" /etc/environment; then
	echo 'QT_QPA_PLATFORMTHEME=qt5ct' | tee -a /etc/environment
fi
if ! grep -q "^GTK_THEME=Gruvbox-Dark-BL" /etc/environment; then
	echo 'GTK_THEME=Gruvbox-Dark-BL' | tee -a /etc/environment
fi

# Set Default Apps (puppyapps)
puppyapps -setdefs
puppyapps -c archiver "file-roller"
puppyapps -c audioeditor "audiomixer"
puppyapps -c audioplayer "rhythmbox-client --select-source"
puppyapps -c barehtmlviewer "gedit"
puppyapps -c browser "/usr/bin/brave-browser-stable"
puppyapps -c calendar "osmo"
puppyapps -c cdplayer "deadbeef all.cda"
puppyapps -c cdrecorder "burniso2cd"
puppyapps -c chat "weechat-shell"
# puppyapps -c chmviewer "###"
puppyapps -c connect "connman-gtk"
puppyapps -c contact "osmo"
puppyapps -c draw "libreoffice --draw"
puppyapps -c email "claws-mail"
puppyapps -c filemanager "nemo"
puppyapps -c htmleditor "gedit"
puppyapps -c htmlviewer "gedit"
puppyapps -c imageeditor "mtpaint"
puppyapps -c imageviewer "eog"
puppyapps -c mediaplayer "haruna"
puppyapps -c musicplayer "rhythmbox-client --select-source"
puppyapps -c paint "mtpaint"
puppyapps -c pdfviewer "evince"
puppyapps -c processmanager "gnome-system-monitor"
puppyapps -c screenshot "gnome-screenshot --interactive"
puppyapps -c run "gexec"
puppyapps -c search "nemo"
puppyapps -c spreadsheet "libreoffice --calc"
puppyapps -c terminal "gnome-terminal"
puppyapps -c texteditor "gedit"
puppyapps -c textviewer "gedit"
puppyapps -c torrent "qbittorrent"
puppyapps -c wordprocessor "libreoffice --writer"
