{ config, lib, pkgs, ... }:

let
  user = "f16poom";
  nixpkgs_23_05 = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-23.05.tar.gz") { config = config.nixpkgs.config; };
  unstable = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") { config = config.nixpkgs.config; };
  # unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
  # nixpkgs_23_05 = import <nixos-23.05> { config = config.nixpkgs.config; };
  theme = {
    package = nixpkgs_23_05.gruvbox-gtk-theme;
    name = "Gruvbox-Dark-BL";
  };
  iconTheme = {
    package = nixpkgs_23_05.pkgs.gruvbox-dark-icons-gtk;
    name = "oomox-gruvbox-dark";
  };
  cursorTheme = {
    package = pkgs.capitaine-cursors-themed;
    name = "Capitaine Cursors (Gruvbox) - White";
  };
in
{
  imports = [ ./hardware-configuration.nix ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = 2;
    # grub = {
      # enable = true;
      # efiSupport = true;
      # device = "nodev";
      # theme = "/boot/grub/themes/gruvbox-dark";
      # gfxmodeEfi = "1920x1080";
    # };
  };
  
  networking = {
    hostName = "NixOS";
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
      allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
    };
  };

  time.timeZone = "Asia/Bangkok";
  i18n.defaultLocale = "en_US.UTF-8";

  services = {
    xserver = {
      enable = true;
      resolutions = [ { x = 1920; y = 1080; } ];
      xkb.layout = "us";
      xkb.variant = "";
      desktopManager.cinnamon.enable = true;
      desktopManager.cinnamon.sessionPath = [ pkgs.gpaste ];
      displayManager.lightdm = {
        enable = true;
        background = /boot/Login_Wallpaper.jpg;
        greeters.slick = {
          enable = true;
          theme = theme;
          iconTheme = iconTheme;
          cursorTheme = cursorTheme;
          extraConfig = "clock-format=%a, %-e %b %-l:%M %p ";
        };
      };
    };
    displayManager.autoLogin = {
      enable = true;
      user = user;
    };
    flatpak.enable = true;
    spice-vdagentd.enable = true;
    # teamviewer.enable = true;
    # printing.enable = true;
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
    };
  };
  
  xdg.portal.enable = true;
  virtualisation.libvirtd.enable = true;
  systemd.extraConfig = "DefaultTimeoutStopSec=15s\n";
  
  # sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;

  users.users.${user} = {
    isNormalUser = true;
    description = "";
    extraGroups = [ "networkmanager" "wheel" "sudo" "libvirtd" ];
    packages = with pkgs; [];
  };

  nixpkgs.config = {
    allowUnfree = true;
    # permittedInsecurePackages = [ "qbittorrent-4.6.4" ];
  };

  environment = {
    systemPackages = with pkgs.gnome // pkgs.kdePackages // pkgs; [
      bleachbit
      bottom
      brave
      celluloid
      ffmpegthumbnailer
      filezilla
      gcc
      gedit
      git
      gnome-system-monitor
      gparted
      guestfs-tools
      libreoffice
      ncdu
      neofetch
      unstable.neovim
      qbittorrent
      qtstyleplugin-kvantum
      # qt5ct
      ripgrep
      # rmlint
      rhythmbox
      timeshift
      unzip
      virt-manager
      wget
      xclip
      xorg.xkill
    ];
    cinnamon.excludePackages = with pkgs.cinnamon // pkgs.gnome // pkgs; [
      bulky
      gnome-calendar
      hexchat
      mint-artwork
      mint-cursor-themes
      mint-l-icons
      mint-l-theme
      mint-themes
      mint-x-icons
      mint-y-icons
      nixos-artwork.wallpapers.simple-dark-gray
      onboard
      orca
      pix
      sound-theme-freedesktop
      xed-editor
      xplayer
      warpinator
    ];
    variables = {
      QT_STYLE_OVERRIDE = lib.mkForce "kvantum";
      GTK_THEME = theme.name;
    };
  };
  
  programs = {
    kdeconnect.enable = true;
    dconf.enable = true;
    geary.enable = false;
    gnome-disks.enable = false;
    gpaste.enable = true;
  };

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-emoji
    (nerdfonts.override { fonts = [ "SourceCodePro" ]; })
  ];

  system.stateVersion = "22.05";
}