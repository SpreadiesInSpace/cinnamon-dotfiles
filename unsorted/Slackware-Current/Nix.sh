# Adding these to make Nix work properly, preserving old configs
cp ~/.profile ~/.profile.old
if ! grep -q "^\. \${HOME}/\.nix-profile/etc/profile\.d/nix\.sh" ~/.profile; then
    echo '. ${HOME}/.nix-profile/etc/profile.d/nix.sh' >> ~/.profile
fi
sudo chown -R $USER:users /nix

mkdir -p ~/.local/share/applications/
sudo ln -fs ~/.nix-profile/share/applications/*.desktop ~/.local/share/applications/
