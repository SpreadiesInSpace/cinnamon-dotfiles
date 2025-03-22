#!/bin/sh

# Get the current username
username=$(whoami)

# Update the pkg repository
sudo pkg update

# Install git
sudo pkg install -y git

# List of packages to install
packages="xorg cinnamon dbus lightdm lightdm-gtk-greeter bash bottom celluloid copyq-qt5 eog engrampa evince filezilla gedit gnome-calculator gnome-screenshot gnome-system-monitor gnome-terminal gthumb kdeconnect-kde kvantum-qt5 libreoffice ncdu neofetch neovim noto-basic noto-emoji python3 qbittorrent qt5ct qt6ct rmlint spice-gtk spice-protocol unzip utouch-kmod virt-manager xrandr"

# Install packages
sudo pkg install -y $packages

# Add entries to loader.conf
if ! grep -q 'utouch_load="YES"' /boot/loader.conf; then
    echo 'utouch_load="YES"' | sudo tee -a /boot/loader.conf
fi
if ! grep -q 'autoboot_delay="0"' /boot/loader.conf; then
    echo 'autoboot_delay="0"' | sudo tee -a /boot/loader.conf
fi

# Add entries to rc.conf
if ! grep -q 'sendmail_enable="NONE"' /etc/rc.conf; then
    echo 'sendmail_enable="NONE"' | sudo tee -a /etc/rc.conf
fi
if ! grep -q 'dbus_enable="YES"' /etc/rc.conf; then
    echo 'dbus_enable="YES"' | sudo tee -a /etc/rc.conf
fi
if ! grep -q 'lightdm_enable="YES"' /etc/rc.conf; then
    echo 'lightdm_enable="YES"' | sudo tee -a /etc/rc.conf
fi

# Add entries to sysctl.conf
if ! grep -q 'kern.coredump=0' /etc/sysctl.conf; then
    echo 'kern.coredump=0' | sudo tee -a /etc/sysctl.conf
fi

# Add entry to fstab
if ! grep -q 'proc /proc procfs rw 0 0' /etc/fstab; then
    echo 'proc /proc procfs rw 0 0' | sudo tee -a /etc/fstab
fi

# Create a configuration file for display driver
echo 'Section "Device"
    Identifier "Card0"
    Driver "scfb"
EndSection' | sudo tee /usr/local/etc/X11/xorg.conf.d/display.conf

# Check if the configuration file was created successfully
if [ $? -ne 0 ]; then
    echo "Failed to create scfb configuration."
    exit 1
fi

# Change the shell for the user and root to bash
sudo chsh -s /usr/local/bin/bash "$username"
sudo chsh -s /usr/local/bin/bash root

# Run the setup script
# cd home/
# chmod +x Setup-FreeBSD-Theme.sh
# ./Setup-FreeBSD-Theme.sh
# cd ..

# Set up linux-browser-installer and install Brave *
cd ${HOME}
git clone https://github.com/mrclksr/linux-browser-installer
cd linux-browser-installer
sudo ./linux-browser-installer install brave
cd ..

# Reboot for the changes to take effect
echo "Installation complete! Please reboot for the changes to take effect."
