{ config, lib, pkgs, ... }:

let
  user = "f16poom";
  # unstable = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") { config = config.nixpkgs.config; };
  # unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
  nixpkgs_23_05 = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-23.05.tar.gz") { config = config.nixpkgs.config; };
  # nixpkgs_23_05 = import <nixos-23.05> { config = config.nixpkgs.config; };
  theme = {
    package = nixpkgs_23_05.gruvbox-gtk-theme;
    name = "Gruvbox-Dark-BL";
  };
  iconTheme = {
    package = pkgs.gruvbox-dark-icons-gtk;
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
    # systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = 3;
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      gfxmodeEfi = "1920x1080";
      gfxmodeBios = "1920x1080";
      # theme = "/boot/grub/themes/gruvbox-dark";
      # splashImage = null;
    };
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
        # background = /boot/Login_Wallpaper.jpg;
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
    zram-generator = {
      enable = true;
      settings = {
        "zram0" = {
          zram-size = "min(ram / 2, 8192)";
          compression-algorithm = "zstd";
        };
      };
    };
  };

  boot.kernel.sysctl = {
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.page-cluster" = 0;
    "vm.swappiness" = 180;
  };

  xdg.portal.enable = true;
  virtualisation.libvirtd.enable = true;
  systemd.extraConfig = "DefaultTimeoutStopSec=15s\n";
  # sound.enable = true;
  # hardware.pulseaudio.enable = false;
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
    systemPackages = with pkgs.gnome // pkgs; [
      bleachbit
      bottom
      brave
      evince
      eog
      ffmpegthumbnailer
      filezilla
      gcc
      gedit
      git
      gnome-system-monitor
      gparted
      # guestfs-tools
      haruna
      libnotify
      libreoffice
      ncdu
      neofetch
      neovim
      # unstable.neovim
      qbittorrent
      ripgrep
      # rmlint
      rhythmbox
      timeshift
      unzip
      virt-manager
      vscodium
      wget
      xclip
      xorg.xkill
    ];
    cinnamon.excludePackages = with pkgs.gnome // pkgs; [
      bulky
      celluloid
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
      # xplayer
      xreader
      xviewer
      warpinator
    ];
    variables = {
      GTK_THEME = theme.name;
    };
  };

  qt = {
    enable = true;
    style = "kvantum";
    platformTheme = "qt5ct";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    QT_ENABLE_HIGHDPI_SCALING = "1";
  };

  programs = {
    kdeconnect.enable = true;
    dconf.enable = true;
    geary.enable = false;
    gnome-disks.enable = true;
    gpaste.enable = true;
  };

  fonts.packages = with pkgs; [
    cantarell-fonts
    noto-fonts
    noto-fonts-emoji
    nerd-fonts.sauce-code-pro
    # (nerdfonts.override { fonts = [ "SourceCodePro" ]; })
  ];

  system.stateVersion = "22.05";
}
