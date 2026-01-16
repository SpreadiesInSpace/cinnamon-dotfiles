{ config, lib, pkgs, ... }:

let
  # Channels Added Beforehand
  unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
  nixpkgs_23_05 = import <nixos-23.05> { config = config.nixpkgs.config; };
  # No Added Channels
  unstable = import (fetchTarball
    "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz"
  ) { config = config.nixpkgs.config; };
  # No Added Channels - Alternative
  nixpkgs_23_05 = import (builtins.fetchGit {
    url = "https://github.com/NixOS/nixpkgs";
    ref = "nixos-23.05";
    # rev = "commit-hash-here";
  }) { config = config.nixpkgs.config; };
in
  environment = {
    systemPackages = with pkgs.gnome // pkgs; [
      # unstable.neovim
      # rmlint
    ];
    cinnamon.excludePackages = with pkgs.gnome // pkgs; [
      # xplayer
    ];
    variables = {
      # GTK_THEME = theme.name;
    };
  };
  # sound.enable = true;
  # hardware.pulseaudio.enable = false;
  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "SourceCodePro" ]; })
  ];
}