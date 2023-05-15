# cinnamon-dotfiles
Dots for a person who is WAY too addicted to the Cinnamon DE.

Login Manager
lightdm

Mount Shared Folder
chmod 777 Share

virtio-9p
sudo mount -t 9p -o trans=virtio /sharepoint /home/f16poom/Share;sudo nano /etc/fstab
/sharepoint /home/f16poom/Share 9p trans=virtio,version=9p2000.L,rw 0 0

virtiofs
sudo mount -t virtiofs /sharepoint /home/f16poom/Share;sudo nano /etc/fstab
/sharepoint /home/f16poom/Share virtiofs rw,_netdev 0 0
System Apps
galculator gnome-screenshot gnome-system-monitor gnome-terminal gedit

Brave Browser Setup
https://brave.com/linux/#release-channel-installation

Bash Scripts
https://pastebin.com/3KEhUUzF

General App List
bottom bleachbit brave-browser filezilla flatpak git gparted gpaste grub-customizer gufw haruna kdeconnect libreoffice ncdu neofetch neovim qbittorrent rmlint snapd timeshift virt-manager

Proprietary App List
snap install authy
https://www.teamviewer.com/en/download/linux/?t=1654784627439

Distro Specific Apps

Arch - bauh python-lxml beautifulsoup4 (pip)
yay -S --mflags "--nocheck" guestfs-tools

Debian/Ubuntu - Synaptic

KDE Neon - Cinnamon 5.2.7
sudo nano /etc/apt/sources.list
deb [trusted=yes] https://mirror.kku.ac.th/linuxmint-packages una main upstream import backport

Mint Bloat - baobab celluloid drawing gnome-calendar gnome-disk-utility hexchat hypnotix mintbackup mintstick mintupdate redshift rhythmbox simple-scan thingy thunderbird transmission warpinator webapp-manager

Distro Specific Instructions

Arch 
sudo nano /etc/pacman.conf
sudo nano /etc/pacman.d/mirrorlist
Server=https://archive.archlinux.org/repos/2022/06/17/$repo/os/$arch
sudo pacman -Syyuu
IgnorePkg = cinnamon cinnamon-control-center cinnamon-desktop cinnamon-menus cinnamon-screensaver cinnamon-session cinnamon-settings-daemon cinnamon-translations cjs muffin nemo nemo-fileroller nemo-image-converter nemo-preview nemo-share

Gentoo
/etc/portage/package.mask                                   
>=gnome-extra/cinnamon-translations-5.4.2
>=x11-misc/xdotool-3.20211022.1
>=gnome-extra/cinnamon-menus-5.4.0
>=gnome-extra/cjs-5.4.1
>=x11-libs/xapp-2.2.15
>=dev-python/python3-xapp-2.2.2
>=gnome-extra/cinnamon-desktop-5.4.2
>=x11-wm/muffin-5.4.7
>=gnome-extra/cinnamon-control-center-5.4.7
>=gnome-extra/cinnamon-screensaver-5.4.4
>=gnome-extra/cinnamon-session-5.4.0
>=gnome-extra/cinnamon-settings-daemon-5.4.5
>=gnome-extra/nemo-5.4.3
>=gnome-extra/cinnamon-5.4.12
>=app-shells/bash-5.1.1.6
sudo nano /etc/portage/make.conf.
# These settings were set by the catalyst build script that automatically
# built this stage.
# Please consult /usr/share/portage/config/make.conf.example for a more
# detailed example.
COMMON_FLAGS="-march=native -O2 -pipe"
CFLAGS="${COMMON_FLAGS}"
CXXFLAGS="${COMMON_FLAGS}"
FCFLAGS="${COMMON_FLAGS}"
FFLAGS="${COMMON_FLAGS}"
MAKEOPTS="-j8 -l9"
# NOTE: This stage was built with the bindist Use flag enabled
PORTDIR="/var/db/repos/gentoo"
DISTDIR="/var/cache/distfiles"
PKGDIR="/var/cache/binpkgs"
USE="-suid -bluetooth -nautilus -gnome-shell gstreamer icu pulseaudio gnomekeyring alsa"
LINGUAS="en"
ACCEPT_LICENSE="*"
ACCEPT_KEYWORDS="~amd64"
# This sets the language of build output to English.
# Please keep this setting intact when reporting bugs.
LC_MESSAGES=C
GENTOO_MIRRORS="http://download.nus.edu.sg/mirror/gentoo/ \
    https://download.nus.edu.sg/mirror/gentoo/ \
    http://gentoo.aditsu.net:8000/ \
    http://mirrors.aliyun.com/gentoo/ \
    https://mirrors.aliyun.com/gentoo/"

KDE Neon
GRUB_RECORDFAIL_TIMEOUT=0

Puppy
Set Drive to USB

Slackware 
# Bash Hostname
PS1='[\u@\h:\W]\$ '

Void
Terminal Bold Color #27A268
sudo xbps-pkgdb -m hold cinnamon cinnamon-control-center cinnamon-desktop cinnamon-menus cinnamon-screensaver cinnamon-session cinnamon-settings-daemon cinnamon-translations cjs libnemo muffin nemo nemo-fileroller nemo-image-converter nemo-preview nemo-share os-prober python-xapp xapp xed

Custom Keyboard Shortcuts
xkill                                             
gnome-terminal -- bash -c 'neofetch;exec bash;'
gnome-screenshot -i
gnome-system-monitor
cinnamon-session-quit --power-off

System Shortcuts
Log Out - Ctrl+Alt+End
Lock Screen - Win+L

Clock Formatting
Desktop 
 %-l:%M %p   
Screensaver
%-l:%M %p
 %A %B %-e
Login Window
%a, %-e %b %-l:%M %p 

Misc. Settings
Windows Tiling - Maximize Top Edge
Sounds - 70% Login Logout & Volume

Themes
git clone https://github.com/jmattheis/gruvbox-dark-icons-gtk ~/.icons/gruvbox-dark-icons-gtk
https://github.com/sainnhe/capitaine-cursors/releases
https://www.pling.com/p/1681313/

Themes (Old)
git clone https://github.com/vinceliuice/Qogir-icon-theme
Mint-Y + Mint-Y-Dark-Drey

Fonts
(Noto) Sans Regular 9
Noto Sans Display Regular 10
Cantarell Regular 11
Source Code Pro Regular 10
(Noto) Sans Bold 10

Taskbar Settings
46px Size

Cinnamon Grouped Window List Padding (Cinnamon 5.4+)
/usr/share/cinnamon/applets/grouped-window-list@cinnamon.org/appGroup.js
setIconPadding(panelHeight) {
    this.iconBox.style = 'padding: 5.5px';
    if (!this.state.isHorizontal) return;
    this.actor.style = 'padding-left: 0px; padding-right: 0px;';
}
Cinnamon Menu Width 
/usr/share/cinnamon/applets/menu@cinnamon.org/applet.js
Applications Directory Width
const MAX_BUTTON_WIDTH = "max-width: 10em;"; (12 for Gruvbox)

Applications List Width
this.applicationsBox.set_width(width + 22); // The answer to life... (12 for Gruvbox)
Applets: Gpaste Reloaded, Drawer

Gpaste Setup
gir1.2-gpaste-4.0
https://github.com/Feuerfuchs/GPaste-Reloaded-Cinnamon-Applet/blob/master/gpaste-reloaded%40feuerfuchs.eu/GPasteHistoryItem.js
