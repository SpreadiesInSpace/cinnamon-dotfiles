#!/bin/bash
# Update Neovim Appimage

# Minimal Error Handling function
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

# Function to fetch and update Neovim if a new version is available
update_neovim() {
  echo "Checking latest Neovim version..."
  LATEST_VERSION=$(curl -sS \
    https://api.github.com/repos/neovim/neovim/releases/latest | \
    grep -oP '"tag_name": "\Kv?\d+\.\d+\.\d+(?=")') || \
    die "Failed to fetch latest Neovim version."

  echo "Latest Neovim version: ${LATEST_VERSION#v}"

  if command -v nvim &>/dev/null; then
    INSTALLED_VERSION=$(nvim --version | head -n1 | \
      grep -oP '\d+\.\d+\.\d+') || \
      die "Failed to determine installed Neovim version."
    echo "Installed Neovim version: $INSTALLED_VERSION"
    if [[ "$INSTALLED_VERSION" == "${LATEST_VERSION#v}" ]]; then
      echo "Neovim is already up to date."
      return 1
    fi
  else
    echo "Neovim is not currently installed."
  fi

  echo "Downloading Neovim $LATEST_VERSION AppImage..."
  url=https://github.com/neovim/neovim
  url="$url/releases/latest/download/nvim-linux-x86_64.appimage"
  curl -LO "$url" || \
    die "Failed to download Neovim AppImage."

  chmod u+x nvim-linux-x86_64.appimage || \
    die "Failed to make AppImage executable."

  echo "Extracting AppImage..."
  ./nvim-linux-x86_64.appimage --appimage-extract || \
    die "Failed to extract AppImage."

  ./squashfs-root/AppRun --version || \
    die "Failed to verify extracted Neovim version."

  echo "Installing Neovim..."
  sudo rm -rf /squashfs-root/ || \
    die "Failed to remove old Neovim squashfs-root."
  sudo mv squashfs-root / || \
    die "Failed to move Neovim to root directory."

  sudo rm -f /usr/bin/nvim || \
    die "Failed to remove old Neovim binary."
  sudo ln -s /squashfs-root/AppRun /usr/bin/nvim || \
    die "Failed to symlink new Neovim binary."

  rm -f nvim-linux-x86_64.appimage || \
    die "Failed to remove downloaded AppImage."

  echo "Neovim $LATEST_VERSION installation complete."
}

# Run the updater
update_neovim
