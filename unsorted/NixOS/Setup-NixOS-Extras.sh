#!/usr/bin/env bash

# Add Nix Unstable and 23.05 Channels (for Neovim, icons and themes)
nix-channel --add https://nixos.org/channels/nixos-unstable nixos || \
	die "Failed to add Nix unstable channel."
nix-channel --add https://nixos.org/channels/nixos-23.05 nixos-23.05 || \
	die "Failed to add Nix 23.05 channel."
nix-channel --update || die "Failed to update Nix channels."