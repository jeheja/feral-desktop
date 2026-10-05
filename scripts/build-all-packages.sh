#!/bin/bash
# Build all Feral Desktop packages for distribution

set -e

echo "🚀 Building Feral Desktop packages for all platforms..."

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
    echo -e "${RED}❌ Error: webapp symlink not found.${NC}"
    echo "Creating webapp symlink..."
    ln -s ../feral-web/webapp ./webapp
fi

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}Installing dependencies...${NC}"
    yarn install
fi

# Use the existing Feral build process
echo -e "${GREEN}Running Feral build process...${NC}"

# Clean previous builds
rm -rf dist/

# Build TypeScript
echo -e "${YELLOW}Building TypeScript...${NC}"
yarn run build:ts

# Copy resources
echo -e "${YELLOW}Copying resources...${NC}"
yarn run build:res

# Create webapp.asar
echo -e "${YELLOW}Creating webapp.asar...${NC}"
yarn run asar-webapp

# Now build packages for each platform
echo -e "${GREEN}Building distribution packages...${NC}"

# Linux DEB packages
echo -e "${YELLOW}Building Debian packages...${NC}"
yarn electron-builder --linux deb --x64 || echo -e "${RED}Failed to build x64 deb${NC}"
yarn electron-builder --linux deb --arm64 || echo -e "${RED}Failed to build arm64 deb${NC}"

# Linux RPM package
echo -e "${YELLOW}Building RPM package...${NC}"
yarn electron-builder --linux rpm --x64 || echo -e "${RED}Failed to build rpm${NC}"

# Linux AppImage
echo -e "${YELLOW}Building AppImage...${NC}"
yarn electron-builder --linux AppImage --x64 || echo -e "${RED}Failed to build AppImage${NC}"

# Linux tar.gz
echo -e "${YELLOW}Building tar.gz archive...${NC}"
yarn electron-builder --linux tar.gz --x64 || echo -e "${RED}Failed to build tar.gz${NC}"

# Windows (if on Linux, requires Wine)
echo -e "${YELLOW}Building Windows packages...${NC}"
yarn electron-builder --win --x64 || echo -e "${YELLOW}Skipping Windows build (requires Wine on Linux)${NC}"

# macOS (only works on macOS)
echo -e "${YELLOW}Building macOS package...${NC}"
yarn electron-builder --mac --x64 || echo -e "${YELLOW}Skipping macOS build (requires macOS)${NC}"

# Copy to media directory
MEDIA_DIR="$PROJECT_ROOT/../../feralism/media/desktop-downloads"
mkdir -p "$MEDIA_DIR"

echo -e "${YELLOW}Copying packages to media directory...${NC}"
find dist -name "*.deb" -o -name "*.rpm" -o -name "*.AppImage" -o -name "*.tar.gz" -o -name "*.exe" -o -name "*.dmg" | while read file; do
    if [ -f "$file" ]; then
        cp "$file" "$MEDIA_DIR/"
        echo -e "  ${GREEN}✓${NC} Copied $(basename "$file")"
    fi
done

echo -e "${GREEN}✅ Build complete!${NC}"
echo -e "${GREEN}Packages available in: $MEDIA_DIR${NC}"
ls -lh "$MEDIA_DIR"/*.{deb,rpm,AppImage,tar.gz} 2>/dev/null || echo "Check the dist/ directory for built packages"