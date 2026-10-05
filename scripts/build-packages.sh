#!/bin/bash
# Build script to create proper distribution packages for Feral Desktop

set -e

echo "🚀 Building Feral Desktop packages..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."

cd "$PROJECT_ROOT"

# Check if webapp symlink exists
if [ ! -L "webapp" ]; then
    echo -e "${YELLOW}Creating webapp symlink...${NC}"
    ln -s ../feral-web/webapp ./webapp
fi

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}Installing dependencies...${NC}"
    yarn install
fi

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
rm -rf dist/

# Apply Feral branding (skip if tsx not available)
if command -v tsx >/dev/null 2>&1; then
    echo -e "${YELLOW}Applying Feral branding...${NC}"
    tsx ./scripts/apply-feral-branding.ts
else
    echo -e "${YELLOW}Skipping branding script (tsx not found)...${NC}"
fi

# Build TypeScript and resources
echo -e "${YELLOW}Building application...${NC}"
yarn run build:ts
yarn run build:res
yarn run asar-webapp

# Build for Linux with proper packages
echo -e "${GREEN}Building Linux packages...${NC}"

# Build DEB packages (for Debian/Ubuntu)
echo -e "${YELLOW}Building .deb packages...${NC}"
yarn electron-builder --linux deb --x64
yarn electron-builder --linux deb --arm64

# Build RPM packages (for Fedora/RHEL)
echo -e "${YELLOW}Building .rpm packages...${NC}"
yarn electron-builder --linux rpm --x64

# Build AppImage (universal)
echo -e "${YELLOW}Building AppImage...${NC}"
yarn electron-builder --linux AppImage --x64

# Build tar.gz (fallback)
echo -e "${YELLOW}Building tar.gz archive...${NC}"
yarn electron-builder --linux tar.gz --x64

echo -e "${GREEN}✅ Linux packages built!${NC}"

# Create desktop entry for proper integration
echo -e "${YELLOW}Creating desktop integration files...${NC}"

# Create a proper desktop file
cat > dist/feral-desktop.desktop << EOF
[Desktop Entry]
Name=Feral Desktop
Comment=Secure messaging and collaboration
Exec=/usr/bin/feral-desktop %u
Terminal=false
Type=Application
Icon=feral-desktop
Categories=Network;InstantMessaging;Chat;
MimeType=x-scheme-handler/element;x-scheme-handler/matrix;
StartupWMClass=feral
X-GNOME-UsesNotifications=true
Keywords=chat;messaging;matrix;riot;element;feral;
EOF

# Ensure packages include proper permissions and dependencies
echo -e "${YELLOW}Configuring package metadata...${NC}"

# Update electron-builder config to ensure proper installation
cat > build-config-override.json << EOF
{
  "linux": {
    "target": [
      {
        "target": "deb",
        "arch": ["x64", "arm64"]
      },
      {
        "target": "rpm",
        "arch": ["x64"]
      },
      {
        "target": "AppImage",
        "arch": ["x64"]
      }
    ],
    "category": "Network;InstantMessaging",
    "desktop": {
      "Name": "Feral Desktop",
      "Comment": "Secure messaging and collaboration",
      "Categories": "Network;InstantMessaging;Chat;",
      "StartupWMClass": "feral"
    },
    "executableName": "feral-desktop",
    "artifactName": "feral-desktop-\${version}-\${arch}.\${ext}"
  },
  "deb": {
    "depends": [
      "libgtk-3-0",
      "libnotify4",
      "libnss3",
      "libxss1",
      "libxtst6",
      "xdg-utils",
      "libatspi2.0-0",
      "libuuid1",
      "libsecret-1-0"
    ],
    "recommends": [
      "libappindicator3-1"
    ],
    "category": "net",
    "priority": "optional"
  },
  "rpm": {
    "depends": [
      "gtk3",
      "libnotify",
      "nss",
      "libXScrnSaver",
      "libXtst",
      "xdg-utils",
      "at-spi2-core",
      "libuuid",
      "libsecret"
    ],
    "category": "Network;InstantMessaging"
  }
}
EOF

echo -e "${GREEN}✅ Package configuration complete!${NC}"

# Copy built packages to a distribution directory
DIST_DIR="$PROJECT_ROOT/../../feralism/media/desktop-downloads"
mkdir -p "$DIST_DIR"

echo -e "${YELLOW}Copying packages to distribution directory...${NC}"
cp dist/*.deb "$DIST_DIR/" 2>/dev/null || true
cp dist/*.rpm "$DIST_DIR/" 2>/dev/null || true
cp dist/*.AppImage "$DIST_DIR/" 2>/dev/null || true
cp dist/*.tar.gz "$DIST_DIR/" 2>/dev/null || true

# Create a simple install script for users
cat > "$DIST_DIR/install-feral.sh" << 'EOF'
#!/bin/bash
# Simple installer for Feral Desktop

echo "Installing Feral Desktop..."

# Detect distribution
if [ -f /etc/debian_version ]; then
    # Debian/Ubuntu
    echo "Detected Debian/Ubuntu system"
    if [ "$(uname -m)" = "aarch64" ]; then
        sudo apt install ./feral-desktop-*-arm64.deb
    else
        sudo apt install ./feral-desktop-*-amd64.deb
    fi
elif [ -f /etc/fedora-release ] || [ -f /etc/redhat-release ]; then
    # Fedora/RHEL
    echo "Detected Fedora/RHEL system"
    sudo rpm -i feral-desktop-*.rpm
else
    # Fallback to AppImage
    echo "Using AppImage (universal package)"
    chmod +x feral-desktop-*.AppImage
    ./feral-desktop-*.AppImage
fi

echo "Installation complete! You can now run 'feral-desktop' or find it in your applications menu."
EOF

chmod +x "$DIST_DIR/install-feral.sh"

echo -e "${GREEN}✅ All packages built successfully!${NC}"
echo -e "${GREEN}Packages available in: $DIST_DIR${NC}"
echo -e "${GREEN}Users can now:${NC}"
echo -e "  1. Download their platform's package"
echo -e "  2. Install with their package manager"
echo -e "  3. Click the app icon to start - no configuration needed!"

# List all built files
echo -e "\n${YELLOW}Built packages:${NC}"
ls -lh dist/*.{deb,rpm,AppImage,tar.gz} 2>/dev/null || echo "No packages found"