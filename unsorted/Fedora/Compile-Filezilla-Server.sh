#!/bin/bash

# Define the FileZilla Project download page URL
DOWNLOAD_PAGE_URL="https://filezilla-project.org/download.php?show_all=1&type=server"
# Define the debug log file
DEBUG_LOG="debug_log.txt"

# Fetch the webpage content and save to a file
wget -q -O download_page.html "$DOWNLOAD_PAGE_URL"

# Extract the latest version number
VERSION=$(grep -oP 'FileZilla_Server_\K[0-9]+\.[0-9]+\.[0-9]+(?=_src\.tar\.xz)' download_page.html | head -1)

# Extract the latest source code URL
URL=$(grep -oP "https://dl[0-9]\.cdn\.filezilla-project\.org/server/FileZilla_Server_${VERSION}_src\.tar\.xz\?h=[a-zA-Z0-9_-]+&x=[0-9]+" download_page.html | head -1)

# Verify that we have successfully retrieved the URL
if [ -z "$URL" ]; then
    echo "Error: Could not find the download URL for FileZilla Server version ${VERSION}." | tee "$DEBUG_LOG"
    echo "Check download_page.html for the webpage content and the URL extraction regex." | tee -a "$DEBUG_LOG"
    # Save the webpage content to the log file
    cat download_page.html >> "$DEBUG_LOG"
    read -p "Press Enter to exit..."
    exit 1
fi

# Define directories
SRC_DIR="filezilla-server-${VERSION}"
BUILD_DIR="${PWD}/${SRC_DIR}"
PKG_DIR="${PWD}/package"

# Prepare directories
mkdir -p "$PKG_DIR/usr/lib/systemd/system"
mkdir -p "$PKG_DIR/usr/share/applications"

# Download Source Code
curl -L -o "FileZilla_Server_${VERSION}_src.tar.xz" "$URL"

# Extract Source Code
tar -xvJf "FileZilla_Server_${VERSION}_src.tar.xz"

build() {
  # Install Dependencies
  sudo dnf install -y libfilezilla-devel wxGTK-devel pugixml-devel

  # Compile
  cd "$BUILD_DIR"
  ./configure --prefix=/usr --with-pugixml=system
  make -j$(nproc)
}

package() {
  cd "$BUILD_DIR"
  make DESTDIR="$PKG_DIR" install

  # Create systemd service file
  install -D pkg/unix/filezilla-server.service -t "$PKG_DIR/usr/lib/systemd/system/"
  
  # Create desktop entry
  install -D pkg/unix/filezilla-server-gui.desktop -t "$PKG_DIR/usr/share/applications/"
  
  # Adjust paths in service file
  sed -i 's"opt/filezilla-server/bin"usr/bin"g' "$PKG_DIR/usr/lib/systemd/system/filezilla-server.service"
  sed -i 's"opt/filezilla-server/etc"etc/filezilla-server"g' "$PKG_DIR/usr/lib/systemd/system/filezilla-server.service"

  # Adjust paths in desktop entry
  sed -i 's"/opt/filezilla-server/share/icons/hicolor/scalable/apps/filezilla-server-gui.svg"filezilla-server-gui"g' \
    "$PKG_DIR/usr/share/applications/filezilla-server-gui.desktop"
  sed -i 's"opt/filezilla-server"usr"g' "$PKG_DIR/usr/share/applications/filezilla-server-gui.desktop"
}

install_package() {
  # Copy the files to the actual filesystem
  sudo cp -r "${PKG_DIR}/." /

  # Reload systemd daemon and enable the service
  sudo systemctl daemon-reload
  sudo systemctl enable --now filezilla-server.service
}

clean_up() {
  cd ..
  sudo rm -rf "$BUILD_DIR"
  rm FileZilla_Server_${VERSION}_src.tar.xz
  sudo dnf remove -y libfilezilla-devel wxGTK-devel pugixml-devel
}

# Execute functions
build
package
install_package
clean_up

# Indicate script completion
echo
echo "FileZilla Server Version ${VERSION} installed successfully."
read -p "Press Enter to exit..."
