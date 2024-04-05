# All packages
packages=(
    # System utilities
    "file-roller"
    "flatpak"
    "gparted"
    "ncdu"
    #"neofetch"
    "timeshift"
    #"unzip" 
    #"xkill" 
    #"xrandr"
    # Network utilities
    ##"filezilla"
    #"gvfs"
    #"kdeconnect"
    #"samba"
    # Desktop environment and related packages
    #"cinnamon"
    #"eog" #using Geeqie instead
    #"evince" #using okular instead
    ##"gdm"
    #"gnome-calculator" #using kcalc instead
    "gnome-screenshot"
    "gnome-system-monitor"
    #"gnome-terminal"
    "ufw"
    "kvantum-qt5"
    "mpv"
    "qt5ct"
    "qt6ct"
    "rhythmbox"
    # Applications
    "bleachbit"
    "brave-browser"
    "clipit"
    "libreoffice"
    "qbittorrent"
    #"noto-fonts"
    "noto-emoji"
    "xclip"
    # For NvChad
    #"gcc"
    #"make"
    "ripgrep"
    # Virtualization tools
    "libslirp"
    "libiscsi"
    "libcacard"
    "spice"
    #"spice-vdagent"
    "usbredir"
    "virglrenderer"
    "libnfs"
    "snappy"
    "device-tree-compiler"
    "glusterfs"
    "vde2"
    "qemu"
    "spice-gtk"
    "gtk-vnc"
    "libvirt"
    "libvirt-glib"
    "libvirt-python"
    "libosinfo"
    "edk2-ovmf"
    "virt-manager"
    #"dnsmasq" # This package and below is already there
    #"bridge-utils"
    #"iptables"
    #"dmidecode"
)

# Update system and install packages
sudo sboinstall "${packages[@]}"

# Adding these to make Nix work properly, preserving old configs
cp ~/.profile ~/.profile.old
if ! grep -q "^\. \${HOME}/\.nix-profile/etc/profile\.d/nix\.sh" ~/.profile; then
    echo '. ${HOME}/.nix-profile/etc/profile.d/nix.sh' >> ~/.profile
fi
sudo chown -R $USER:users /nix

mkdir -p ~/.local/share/applications/
sudo ln -fs ~/.nix-profile/share/applications/*.desktop ~/.local/share/applications/
