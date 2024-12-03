#!/usr/local/bin/bash
sudo echo
# Copies icons and themes to appropriate directories
mv .icons/*.zip ${PWD}
unzip Capitaine\ Cursors\ \(Gruvbox\)\ -\ White.zip
unzip gruvbox-dark-icons-gtk-1.0.0.zip
mv gruvbox-dark-icons-gtk-1.0.0 .icons/gruvbox-dark-icons-gtk
mv Capitaine\ Cursors\ \(Gruvbox\)\ -\ White .icons/
sudo cp -Rpv .icons/* /usr/local/share/icons/
mv Capitaine\ Cursors\ \(Gruvbox\)\ -\ White.zip .icons/
mv gruvbox-dark-icons-gtk-1.0.0.zip .icons/
rm -rf .icons/Capitaine\ Cursors\ \(Gruvbox\)\ -\ White
rm -rf .icons/gruvbox-dark-icons-gtk
mv .themes/*.zip ${PWD}
unzip 1670604530-Gruvbox-Dark-BL.zip
mv Gruvbox-Dark-BL .themes/
sudo cp -Rpv .themes/* /usr/local/share/themes/
mv 1670604530-Gruvbox-Dark-BL.zip .themes/
rm -rf .themes/Gruvbox-Dark-BL/

# Copies fonts to appropriate directories
cp -Rpv .fonts ~/ 

# Copies system sounds to home directory
cp -Rpv sounds ~/

# Copies wallpapers to home directory
cp -Rpv wallpapers ~/

# Copies applets to appropriate directories
cp -Rpv .local/share/cinnamon/applets.freebsd/* ~/.local/share/cinnamon/applets

# Copies KDE Global Cinnamon defaults to ~/.config, preserving old one
# Check if the destination file exists
if [ -e ~/.config/kdeglobals ]; then
    # If it does, rename it with a .old suffix
    mv ~/.config/kdeglobals ~/.config/kdeglobals.old
fi
# Then copy the source file to the destination
cp -vR .config/kdeglobals ~/.config/

# Copies Cinnamon spice settings, preserving old ones (Cinnamon 5.4.9)
mkdir -p ~/.cinnamon/configs/old
mv ~/.cinnamon/configs/* ~/.cinnamon/configs/old
cp -vpR .cinnamon/configs.freebsd/* ~/.cinnamon/configs/

# Copies My Personal Shortcuts
mkdir -p ~/.local/share/applications
cp -vpR .local/share/applications/freebsd/* ~/.local/share/applications/

# Copies .bashrc to home directory, preserving old one
cp -Rpv FreeBSD/* ~/
sudo cp /root/.bashrc /root/.bashrc.old
sudo cp FreeBSD/.bashrc /root/.bashrc
cp ~/.bashrc ~/.bashrc.old
cat FreeBSD/.bashrc > bashrc
mv bashrc ~/.bashrc

# Replaces IBus Autostart with CopyQ
rm -rf ~/.config/autostart/*
cp -vpR .config/autostart/freebsd/  ~/.config/autostart/

# Copies neofetch config file to appropriate directory, preserving old one
sudo mv ~/neofetch /usr/local/bin/neofetch
neofetch
mv ~/.config/neofetch/config.conf ~/.config/neofetch/config.conf.old
cp -Rpv .config/neofetch/config.conf.freebsd ~/.config/neofetch/config.conf
sudo neofetch
sudo mv /root/.config/neofetch/config.conf /root/.config/neofetch/config.conf.old
sudo cp -Rpv .config/neofetch/config.conf.freebsd /root/.config/neofetch/config.conf

# Copies Kvantum Themes to appropriate directory and installs them, preserving old config
mv ~/.config/Kvantum/kvantum.kvconfig ~/.config/Kvantum/kvantum.kvconfig.old
cp -Rpv Kvantum ~/.config/
sudo mv /root/.config/Kvantum/kvantum.kvconfig /root/.config/Kvantum/kvantum.kvconfig.old
sudo cp -Rpv Kvantum /root/.config
kvantummanager --set gruvbox-fallnn
sudo kvantummanager --set gruvbox-fallnn

# Copies qt5ct & qt6ct config to appropriate directories, preserving old ones
mv ~/.config/qt5ct/qt5ct.conf ~/.config/qt5ct/qt5ct.conf.old
cp -Rpv .config/qt5ct/ ~/.config/qt5ct
mv ~/.config/qt6ct/qt6ct.conf ~/.config/qt6ct/qt6ct.conf.old
cp -Rpv .config/qt6ct/ ~/.config/qt6ct
sudo mv /root/.config/qt5ct/qt5ct.conf /root/.config/qt5ct/qt5ct.conf.old
sudo cp -Rpv .config/qt5ct/ /root/.config/qt5ct
sudo mv /root/.config/qt6ct/qt6ct.conf /root/.config/qt6ct/qt6ct.conf.old
sudo cp -Rpv .config/qt6ct/ /root/.config/qt6ct

# Copies Gedit Theme to appropriate directory
mkdir -p ~/.local/share/gedit/styles
cp -vpR gruvbox-dark.xml ~/.local/share/gedit/styles/
sudo mkdir -p /root/.local/share/gedit/styles
sudo cp -vprf gruvbox-dark.xml /root/.local/share/gedit/styles/

# Copies Menu Preferences to appropriate directory
mkdir -p ~/.config/menus/old
mv ~/.config/menus/*.menu ~/.config/menus/old
cp -vpR .config/menus/freebsd/* ~/.config/menus/

# Copies Qbittorent config to appropriate directory, preserving old one
mv ~/.config/qBittorrent/qBittorrent.conf ~/.config/qBittorrent/qBittorrent.conf.old
mkdir -p ~/.config/qBittorrent/
cp -vpR .config/qBittorrent/qBittorrent.conf.freebsd ~/.config/qBittorrent/qBittorrent.conf
cp -vpR mumble-dark.qbtheme ~/.config/qBittorrent/

# Copies LibreOffice config to appropriate directory, preserving old ones
mkdir -p ~/.config/libreoffice
mv ~/.config/libreoffice/4 ~/.config/libreoffice/4_old
cp -vpR .config/libreoffice/freebsd ~/.config/libreoffice/4
sudo mkdir -p /root/.config/libreoffice
sudo mv /root/.config/libreoffice/4 /root/.config/libreoffice/4_old
sudo cp -vprf .config/libreoffice/freebsd /root/.config/libreoffice/4

# Copies Profile Picture to home directory
mv ~/.face ~/.faceold 
cp -vpR .face ~/

# Import Entire Desktop Configuration
dconf load / < FreeBSD.dconf

# Define the path to .desktop file
desktop_file_path="${HOME}/.local/share/applications/Services_Settings.desktop"
# Sets Authy Icon
cp -vpR .icons/authy.png ~/
sed -i '' "s|Icon=.*|Icon=${HOME}/authy.png|g" $desktop_file_path

# Define the home directory (For Menu Applet Icon)
# home_dir="${HOME}"
# Define the path to JSON file
# json_file="${home_dir}/.config/cinnamon/spices/menu@cinnamon.org/0.json"
# Use sed to replace /home/f16poom with the home directory in the value field on line 91
# sed -i "91s|\"value\": \"/home/f16poom/NixOS-Start.png\"|\"value\": \"${home_dir}/NixOS-Start.png\"|g" $json_file

# Sets Default Apps
chmod +x Default-Apps.sh
sh Default-Apps.sh

# Sets Wallpaper
gsettings set org.cinnamon.desktop.background picture-uri file://${HOME}/wallpapers/Desktop_Wallpaper.png

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
nvim --headless +qa

# Restarts Cinnamon
cinnamon-dbus-command RestartCinnamon 1

# Places Login Wallpaper
sudo cp -vnr wallpapers/Login_Wallpaper.jpg /boot/

# Check if syntax highlighting configurations are already in nanorc, preserving old one
sudo cp /usr/local/etc/nanorc /usr/local/etc/nanorc.old
if ! grep -q "^include \"/usr/local/share/nano/\*.nanorc\"" /usr/local/etc/nanorc; then
    echo 'include "/usr/local/share/nano/*.nanorc"' | sudo tee -a /usr/local/etc/nanorc
fi
if ! grep -q "^include \"/usr/local/share/nano/extra/\*.nanorc\"" /usr/local/etc/nanorc; then
    echo 'include "/usr/local/share/nano/extra/*.nanorc"' | sudo tee -a /usr/local/etc/nanorc
fi

# Copies .profile to home & root directories, preserving old ones (QT & Additional Theming variables)
cat FreeBSD/.profile > profile
mv profile ~/.profile
sudo cp ~/.profile /root/

# Get the current logged-in user
username=$(whoami)
# Backs up old lightdm.conf
sudo cp /usr/local/etc/lightdm/lightdm.conf /usr/local/etc/lightdm/lightdm.conf.old

# Replace specific lines in lightdm.conf
sudo awk '
/^\[Seat:\*\]/ {a=1}
a==1 && /^#?greeter-session=/ {
    print "greeter-session=lightdm-gtk-greeter"
    next
}
a==1 && /^#?display-setup-script=/ {
    print "#display-setup-script=xrandr --output Virtual-1 --mode 1920x1080 --rate 60"
    next
}
a==1 && /^#?autologin-user=/ {
    print "autologin-user='"$username"'"
    next
}
a==1 && /^#?autologin-session=/ {
    print "autologin-session=cinnamon"
    next
}
{print}
' /usr/local/etc/lightdm/lightdm.conf > /tmp/lightdm.conf && sudo mv /tmp/lightdm.conf /usr/local/etc/lightdm/lightdm.conf

# Create a new group named 'autologin' if it doesn't already exist
sudo pw groupadd -n autologin
# Add the current user to the 'autologin' group
sudo pw groupmod autologin -m $username

# Append new settings to slick-greeter.conf, preserving old one
sudo cp /usr/local/etc/lightdm/slick-greeter.conf /usr/local/etc/lightdm/slick-greeter.conf.old
echo "
[Greeter]
show-hostname=true
theme-name=Gruvbox-Dark-BL
icon-theme-name=gruvbox-dark-icons-gtk
cursor-theme-name=Capitaine Cursors (Gruvbox) - White
clock-format=%a, %-e %b %-l:%M %p 
background=/boot/Login_Wallpaper.jpg
draw-user-backgrounds=false
" | sudo tee /usr/local/etc/lightdm/slick-greeter.conf > /dev/null

# Append new settings to lightdm-gtk-greeter.conf, preserving old one
sudo cp /usr/local/etc/lightdm/lightdm-gtk-greeter.conf /usr/local/etc/lightdm/lightdm-gtk-greeter.conf.old
echo "
[greeter]
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
hide-user-image = true
" | sudo tee /usr/local/etc/lightdm/lightdm-gtk-greeter.conf > /dev/null

# Modify systemd configuration to change the default timeout for stopping services during shutdown, preserving old one
# sudo cp /etc/systemd/system.conf /etc/systemd/system.conf.old
# sudo sed -i 's/^#DefaultTimeoutStopSec=.*/DefaultTimeoutStopSec=15s/' /etc/systemd/system.conf

# Reload the systemd configuration
# sudo systemctl daemon-reload
