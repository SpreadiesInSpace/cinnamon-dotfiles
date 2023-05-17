# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  networking.hostName = "XPS13-NixOS"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Bangkok";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.utf8";

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the Cinnamon Desktop Environment.
  services.xserver.desktopManager.cinnamon.enable = true;
  
  # Enable Lightdm Slick Greeter & Config
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.displayManager.lightdm.background = "/boot/background.jpg";
  services.xserver.displayManager.lightdm.greeters.slick.enable = true;
  services.xserver.displayManager.lightdm.greeters.slick.theme.package = pkgs.gruvbox-gtk-theme;
  services.xserver.displayManager.lightdm.greeters.slick.theme.name = "Gruvbox-Dark-BL";
  services.xserver.displayManager.lightdm.greeters.slick.iconTheme.package = pkgs.gruvbox-dark-icons-gtk;
  services.xserver.displayManager.lightdm.greeters.slick.iconTheme.name = "oomox-gruvbox-dark";
  services.xserver.displayManager.lightdm.greeters.slick.cursorTheme.package = pkgs.capitaine-cursors-themed;
  services.xserver.displayManager.lightdm.greeters.slick.cursorTheme.name = "Capitaine Cursors (Gruvbox) - White";
  services.xserver.displayManager.lightdm.greeters.slick.extraConfig = "clock-format=%a, %-e %b %-l:%M %p ";
  
  # Enable automatic login for the user.
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "f16poom";

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    # jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    # media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.f16poom = {
    isNormalUser = true;
    description = "Poom Chitnuchtaranon";
    extraGroups = [ "networkmanager" "wheel" "sudo" "libvirtd" ];
    packages = with pkgs; [
        # neovim
      ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Allow insecure packages
  nixpkgs.config.permittedInsecurePackages = [ "electron-9.4.4" ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget

  environment.systemPackages = with pkgs.gnome // pkgs.libsForQt5 // pkgs; ([
    authy
    bleachbit
    bottom
    brave
    copyq
    filezilla
    gcc
    git
    gnome-system-monitor
    gparted
    haruna
    home-manager
    libreoffice-fresh
    ncdu
    neofetch
    qbittorrent
    # qt5ct
    ripgrep
    rmlint
    virt-manager
    wget
    xorg.xkill
    qtstyleplugin-kvantum
  ]);
  
  # Cinnamon DE Packages Exclude List
  environment.cinnamon.excludePackages = with pkgs.cinnamon // pkgs.gnome // pkgs; ([
    bulky
    gnome-calendar
    hexchat
    mint-artwork
    mint-cursor-themes
    mint-themes
    mint-x-icons
    mint-y-icons
    nixos-artwork.wallpapers.simple-dark-gray
    onboard
    orca
    pix
    sound-theme-freedesktop
    xplayer
    warpinator
  ]);
  
  # Disable Gnome Packages
    programs.geary.enable = false;
    programs.gnome-disks.enable = false;
  
  # Environment Variables
  environment.variables = {
    QT_STYLE_OVERRIDE = lib.mkForce "kvantum";
    # QT_QPA_PLATFORMTHEME = lib.mkForce "qt5ct";
    GTK_THEME = "Gruvbox-Dark-BL";
  };
  
  # Enable Select Nerd Fonts + Other Fonts
  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-emoji
    (nerdfonts.override { fonts = [ "SourceCodePro" ]; }) 
  ];

  # Enable Zsh & Set as Default Shell
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # Enable KDE Connect
  programs.kdeconnect.enable = true;

  # Enable Flatpak
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  xdg.portal.enable = true;
  services.flatpak.enable = true;

  # Enable GPaste Services
  # programs.gpaste.enable = true;
  # services.xserver.desktopManager.cinnamon.sessionPath = [
    # pkgs.gnome.gpaste
  # ];
  
  # Enable Neovim + Config
  programs.neovim.defaultEditor = true;
  programs.neovim.enable = true;
  programs.neovim.vimAlias = true;
  programs.neovim.viAlias = true;

  # Enable Virt-Manager Services
  virtualisation.libvirtd.enable = true;
  programs.dconf.enable = true;

  # Enable Teamviewer Service
  services.teamviewer.enable = true;

  # System.d Stop Job Timer Reduction
  systemd.extraConfig = ''
    DefaultTimeoutStopSec=15s
  '';

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.

  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  networking.firewall = {
    enable = true;
    allowedTCPPortRanges = [{
      from = 1714;
      to = 1764;
    } # KDE Connect
      ];
    allowedUDPPortRanges = [{
      from = 1714;
      to = 1764;
    } # KDE Connect
      ];
  };
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}
