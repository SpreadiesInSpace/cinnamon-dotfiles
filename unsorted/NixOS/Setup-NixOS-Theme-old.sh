#!/bin/bash
sudo echo
# Copies icons and themes to appropriate directories
mv .icons/*.zip ${PWD}
unzip Capitaine\ Cursors\ \(Gruvbox\)\ -\ White.zip
unzip gruvbox-dark-icons-gtk-1.0.0.zip
mv gruvbox-dark-icons-gtk-1.0.0 .icons/gruvbox-dark-icons-gtk
mv Capitaine\ Cursors\ \(Gruvbox\)\ -\ White .icons/
# sudo cp -vnpr .icons/* /usr/share/icons/
mkdir -p ~/.icons
cp -vnpr .icons/* ~/.icons/
mv Capitaine\ Cursors\ \(Gruvbox\)\ -\ White.zip .icons/
mv gruvbox-dark-icons-gtk-1.0.0.zip .icons/
rm -rf .icons/Capitaine\ Cursors\ \(Gruvbox\)\ -\ White
rm -rf .icons/gruvbox-dark-icons-gtk
mv .themes/*.zip ${PWD}
unzip 1670604530-Gruvbox-Dark-BL.zip
mv Gruvbox-Dark-BL .themes/
# sudo cp -vnpr .themes/* /usr/share/themes/
mkdir -p ~/.themes
cp -vnpr .themes/* ~/.themes/
mv 1670604530-Gruvbox-Dark-BL.zip .themes/
rm -rf .themes/Gruvbox-Dark-BL/

# Enable GTK & QT Flatpak Theming Override
sudo flatpak override --filesystem=$HOME/.themes
sudo flatpak override --filesystem=$HOME/.icons
sudo flatpak override --env=GTK_THEME=Gruvbox-Dark-BL 
sudo flatpak override --env=ICON_THEME=gruvbox-dark-icons-gtk
sudo flatpak override --filesystem=xdg-config/Kvantum:ro
sudo flatpak override --env=QT_STYLE_OVERRIDE=kvantum

# Copies Brave config to appropriate directories, preserving old one
# mv ~/.config/BraveSoftware ~/.config/BraveSoftware.old
# cp -vnpr .config/BraveSoftware/ ~/.config/

# Copies fonts to appropriate directories
cp -vnpr .fonts/ ~/
# sudo cp -vnpr .fonts/* /usr/share/fonts/

# Copies system sounds to home directory
cp -vnpr sounds/ ~/

# Copies wallpapers to home directory
cp -vnpr wallpapers/ ~/

# Copies applets to appropriate directories
cp -vnpr .local/share/cinnamon/applets/* ~/.local/share/cinnamon/applets/

# Copies KDE Global Cinnamon defaults to ~/.config, preserving old one
mv ~/.config/kdeglobals ~/.config/kdeglobals.old
cp -vnpr .config/kdeglobals ~/.config/
sudo mv /root/.config/kdeglobals /root/.config/kdeglobals.old
sudo cp -vnpr .config/kdeglobals /root/.config/

# Copies Cinnamon spice settings, preserving old ones
mkdir -p ~/.config/cinnamon/spices/old
mv ~/.config/cinnamon/spices/* ~/.config/cinnamon/spices/old
cp -vnpr .config/cinnamon/spices.nixos/* ~/.config/cinnamon/spices/

# Copies My Personal Shortcuts
mkdir -p ~/.local/share/applications
cp -vnpr .local/share/applications/nixos/* ~/.local/share/applications/

# Copies Start Menu Icon, Neofetch ASCII & .bashrc to home directory, preserving old one
cd theming/
cp -vnpr NixOS/* ~/;rm ~/configuration.nix ~/configuration.nix.vm
sudo cp /root/.bashrc /root/.bashrc.old
sudo cp NixOS/.bashrc.root /root/.bashrc;sudo cp NixOS/NixOS-Start.png /root/
cp ~/.bashrc ~/.bashrc.old
cat NixOS/.bashrc > bashrc
mv bashrc ~/.bashrc
cd ..

# Copies neofetch config file to appropriate directory, preserving old one
neofetch
mv ~/.config/neofetch/config.conf ~/.config/neofetch/config.conf.old
cp -vnpr .config/neofetch/config.conf.nixos ~/.config/neofetch/config.conf
sudo neofetch
sudo mv /root/.config/neofetch/config.conf /root/.config/neofetch/config.conf.old
sudo cp -vprf .config/neofetch/config.conf.nixos /root/.config/neofetch/config.conf

# Copies Kvantum Themes to appropriate directory and installs them, preserving old config
mv ~/.config/Kvantum ~/.config/Kvantum.old
cp -vnpr Kvantum/ ~/.config/
sudo mv /root/.config/Kvantum /root/.config/Kvantum.old
sudo cp -vnpr Kvantum/ /root/.config/Kvantum
kvantummanager --set gruvbox-fallnn
sudo kvantummanager --set gruvbox-fallnn

# Copies qt5ct & qt6ct config to appropriate directories, preserving old ones
mv ~/.config/qt5ct/qt5ct.conf ~/.config/qt5ct/qt5ct.conf.old
cp -vnpr .config/qt5ct/ ~/.config/
mv ~/.config/qt6ct/qt6ct.conf ~/.config/qt6ct/qt6ct.conf.old
cp -vnpr .config/qt6ct/ ~/.config/
sudo mv /root/.config/qt5ct/qt5ct.conf /root/.config/qt5ct/qt5ct.conf.old
sudo cp -vprf .config/qt5ct/ /root/.config/
sudo mv /root/.config/qt6ct/qt6ct.conf /root/.config/qt6ct/qt6ct.conf.old
sudo cp -vprf .config/qt6ct/ /root/.config/

# Copies Gedit Theme to appropriate directory
mkdir -p ~/.local/share/libgedit-gtksourceview-300/styles
cp -vnpr gruvbox-dark-gedit46.xml ~/.local/share/libgedit-gtksourceview-300/styles
sudo mkdir -p /root/.local/share/libgedit-gtksourceview-300/styles
sudo cp -vprf gruvbox-dark-gedit46.xml /root/.local/share/libgedit-gtksourceview-300/styles

# Copies Menu Preferences to appropriate directory
mkdir -p ~/.config/menus/old
mv ~/.config/menus/*.menu ~/.config/menus/old
cp -vpnr .config/menus/nixos/* ~/.config/menus/

# Copies Qbittorent config to appropriate directory, preserving old one
mv ~/.config/qBittorrent/qBittorrent.conf ~/.config/qBittorrent/qBittorrent.conf.old
mkdir -p ~/.config/qBittorrent/
cp -vnpr .config/qBittorrent/qBittorrent.conf.arch ~/.config/qBittorrent/qBittorrent.conf
cp -vnpr mumble-dark.qbtheme ~/.config/qBittorrent/

# Copies LibreOffice config to appropriate directory, preserving old ones
mkdir -p ~/.config/libreoffice
mv ~/.config/libreoffice/4 ~/.config/libreoffice/4_old
cp -vpnr .config/libreoffice/nixos ~/.config/libreoffice/4
sudo mkdir -p /root/.config/libreoffice
sudo mv /root/.config/libreoffice/4 /root/.config/libreoffice/4_old
sudo cp -vprf .config/libreoffice/nixos /root/.config/libreoffice/4

# Copies Filezilla config to appropriate directory, preserving old one
mv ~/.config/filezilla/ ~/.config/filezilla.old
cp -vnpr .config/filezilla/ ~/.config/

# Copies Profile Picture to home directory, preserving old one
mv ~/.face ~/.faceold 
cp -vnpr .face ~/

# Import Entire Desktop Configuration, preserving old one
cd theming/NixOS/
dconf dump / > Old_Desktop_Configuration.dconf
mv Old_Desktop_Configuration.dconf ~/
dconf load / < NixOS.dconf
rm ~/NixOS.dconf

# Sets Default Apps
chmod +x Default-Apps-NixOS.sh
sh Default-Apps-NixOS.sh
sudo sh Default-Apps-NixOS.sh
rm ~/Default-Apps-NixOS.sh
cd ../..

# Define the home directory (For Menu Applet Icon)
home_dir="${HOME}"
# Define the path to JSON file
json_file="${home_dir}/.config/cinnamon/spices/menu@cinnamon.org/0.json"
# Use sed to replace /home/f16poom with the home directory in the value field on line 91
sed -i "91s|\"value\": \"/home/f16poom/NixOS-Start.png\"|\"value\": \"${home_dir}/.icons/NixOS-Start.png\"|g" $json_file
mv ~/NixOS-Start.png ~/.icons/

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

# Install Synth-Shell Prompt
# git clone --recursive https://github.com/andresgongora/synth-shell-prompt.git
# yes | synth-shell-prompt/setup.sh
# yes | sudo synth-shell-prompt/setup.sh
# rm -rf synth-shell-prompt/
# Places My Synth-Shell Config, preserving old ones
# mkdir -p ~/.config/synth-shell/old
# cp -vnpr ~/.config/synth-shell/* ~/.config/synth-shell/old
# cp -vprf .config/synth-shell/arch/* ~/.config/synth-shell/
# sudo mkdir -p /root/.config/synth-shell/old
# sudo cp -vnpr /root/.config/synth-shell/* /root/.config/synth-shell/old
# sudo cp -vprf .config/synth-shell/root-synth-shell-prompt.config /root/.config/synth-shell/synth-shell-prompt.config

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