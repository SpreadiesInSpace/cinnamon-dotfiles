#!/bin/bash
# Update xdeb, Brave and VSCodium

# Minimal Error Handling function
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

# Set the directory where you want to download and convert packages
WORKDIR="$HOME/.config/xdeb"
mkdir -p "$WORKDIR" || die "Failed to create directory $WORKDIR."
cd "$WORKDIR" || die "Failed to change to directory $WORKDIR."

# Function to install only missing dependencies
install_missing_deps() {
  REQUIRED_PKGS=(binutils tar curl xbps xz)
  MISSING_PKGS=()

  for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! xbps-query -p pkgver "$pkg" &>/dev/null; then
      MISSING_PKGS+=("$pkg")
    fi
  done

  if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo "Installing missing packages: ${MISSING_PKGS[*]}"
    sudo xbps-install -y "${MISSING_PKGS[@]}" || \
      die "Failed to install required packages."
  fi
}

# Function to install and update xdeb
setup_xdeb() {
  install_missing_deps

  echo "Fetching latest xdeb release URL..."
  XDEB_URL=$(curl -sS --retry 10 --retry-delay 10 --connect-timeout 10 \
    --retry-connrefused \
    https://api.github.com/repos/xdeb-org/xdeb/releases/latest | \
    grep -oP '"browser_download_url": "\K(.*xdeb)(?=")') || \
    die "Failed to fetch xdeb release URL."

  echo "Downloading xdeb..."
  curl -sS -fL --retry 10 --retry-delay 10 --connect-timeout 10 \
    --retry-connrefused -O "$XDEB_URL" || die "Failed to download xdeb."
  chmod 0744 xdeb || die "Failed to set permissions on xdeb."
}

# Function to check and download the latest Brave version
check_and_download_brave() {
  echo "Checking latest Brave release info..."
  LATEST_RELEASE=$(curl -sS --retry 10 --retry-delay 10 \
    --connect-timeout 10 --retry-connrefused \
    https://api.github.com/repos/brave/brave-browser/releases/latest) || \
    die "Failed to fetch Brave release info."

  VERSION=$(echo "$LATEST_RELEASE" | \
    grep -oP '"tag_name": "\K(.*)(?=")') || \
    die "Failed to parse Brave version."
  DEB_URL=$(echo "$LATEST_RELEASE" | \
    grep -oP '"browser_download_url": "\K(.*amd64.deb)(?=")') || \
    die "Failed to find Brave .deb URL."
  echo "Latest Brave version: ${VERSION#v}"

  # Check installed Brave version
  if command -v brave-browser-stable &>/dev/null; then
    INSTALLED_VERSION=$(brave-browser-stable --version | \
      grep -oP '\d+\.\d+\.\d+\.\d+' | cut -d. -f2-) || \
      die "Failed to get installed Brave version."
    echo "Installed version: $INSTALLED_VERSION"
    if [[ "$INSTALLED_VERSION" == "${VERSION#v}" ]]; then
      echo "Brave is already up to date."
      return 1
    fi
  else
    echo "Brave is not currently installed."
  fi

  echo "Downloading Brave $VERSION..."
  curl -sS -fL --retry 10 --retry-delay 10 --connect-timeout 10 \
    --retry-connrefused -O "$DEB_URL" || \
    die "Failed to download Brave .deb package."
}

# Function to convert and install the Brave package
convert_and_install_brave() {
  echo "Converting .deb to xbps..."
  ./xdeb -Sedf brave-browser*.deb || \
    die "Failed to convert .deb to xbps."

  echo "Installing Brave package..."
  sudo xbps-install -y -R ./binpkgs brave-browser || \
    die "Failed to install Brave package."
}

# Function to check and download the latest VSCodium version
check_and_download_vscodium() {
  echo "Checking latest VSCodium release info..."
  LATEST_RELEASE=$(curl -sS --retry 10 --retry-delay 10 \
    --connect-timeout 10 --retry-connrefused \
    https://api.github.com/repos/VSCodium/vscodium/releases/latest) || \
    die "Failed to fetch VSCodium release info."

  VERSION=$(echo "$LATEST_RELEASE" | \
    grep -oP '"tag_name": "\K(.*)(?=")') || \
    die "Failed to parse VSCodium version."
  DEB_URL=$(echo "$LATEST_RELEASE" | \
    grep -oP '"browser_download_url": "\K(.*codium_.*_amd64\.deb)(?=")') || \
    die "Failed to find VSCodium .deb URL."

  echo "Latest VSCodium version: $VERSION"

  if command -v codium &>/dev/null; then
    INSTALLED_VERSION=$(codium --no-sandbox --user-data-dir "$HOME" \
      --version | head -n1 | grep -oP '^\d+(\.\d+)+') || \
      die "Failed to get installed VSCodium version."
    echo "Installed version: $INSTALLED_VERSION"
    if [[ "$INSTALLED_VERSION" == "${VERSION#v}" ]]; then
      echo "VSCodium is already up to date."
      return 1
    fi
  else
    echo "VSCodium is not currently installed."
  fi

  echo "Downloading VSCodium $VERSION..."
  curl -sS -fL --retry 10 --retry-delay 10 --connect-timeout 10 \
    --retry-connrefused -O "$DEB_URL" || \
    die "Failed to download VSCodium .deb package."
}

# Function to convert and install the VSCodium package
convert_and_install_vscodium() {
  echo "Locating VSCodium .deb package..."
  CODIUM_DEB=$(find . -maxdepth 1 -type f -name 'codium_*_amd64.deb' | \
    sort -V | tail -n1) || die "Failed to find VSCodium .deb package."

  [ -n "$CODIUM_DEB" ] || die "No VSCodium .deb package found."

  echo "Converting $CODIUM_DEB to xbps..."
  ./xdeb -Sedf "$CODIUM_DEB" || \
    die "Failed to convert VSCodium .deb to xbps."

  echo "Installing VSCodium package..."
  sudo xbps-install -y -R ./binpkgs codium || \
    die "Failed to install VSCodium package."

  # Symlink codium binary to /usr/local/bin if it's not already in PATH
  if ! command -v codium &>/dev/null; then
    echo "Adding codium to PATH via symlink..."
    [ -x /usr/share/codium/bin/codium ] && \
      sudo ln -sf /usr/share/codium/bin/codium /usr/local/bin/codium || \
      die "Failed to symlink codium to /usr/local/bin."
  fi
}

# Function to check and download neofetch
check_and_download_neofetch() {
  VERSION="7.1.0"
  DEB_URL="http://ftp.de.debian.org/debian/pool/main/n/neofetch"
  DEB_URL="$DEB_URL/neofetch_7.1.0-4_all.deb"
  
  echo "Latest neofetch version: $VERSION"

  if command -v neofetch &>/dev/null; then
    INSTALLED_VERSION=$(neofetch --version | \
      grep -oP 'Neofetch \K\d+\.\d+\.\d+') || \
      die "Failed to get installed neofetch version."
    echo "Installed version: $INSTALLED_VERSION"
    if [[ "$INSTALLED_VERSION" == "$VERSION" ]]; then
      echo "Neofetch is already up to date."
      return 1
    fi
  else
    echo "Neofetch is not currently installed."
  fi

  echo "Downloading neofetch $VERSION..."
  curl -sS -fL --retry 10 --retry-delay 10 --connect-timeout 10 \
    --retry-connrefused -O "$DEB_URL" || \
    die "Failed to download neofetch .deb package."
}

# Function to convert and install the neofetch package
convert_and_install_neofetch() {
  echo "Converting .deb to xbps..."
  ./xdeb -Sedf neofetch*.deb || \
    die "Failed to convert .deb to xbps."

  echo "Installing neofetch package..."
  sudo xbps-install -y -R ./binpkgs neofetch || \
    die "Failed to install neofetch package."
}

# Update xdeb
setup_xdeb

# Update/Install Brave
if check_and_download_brave; then
  convert_and_install_brave
fi

# Update/Install VSCodium
if check_and_download_vscodium; then
  convert_and_install_vscodium
fi

# Update/Install neofetch
if check_and_download_neofetch; then
  convert_and_install_neofetch
fi

# Cleanup - remove everything in $WORKDIR except xdeb
rm -rf "$WORKDIR"/binpkgs/ "$WORKDIR"/*dir/ "$WORKDIR"/*.deb \
  "$WORKDIR"/shlibs || die "Failed to clean up $WORKDIR."