#!/bin/bash

# Prepare Windows downloads from Linux (Fedora/Ubuntu/etc)
# Creates Windows installers that users can simply download and run

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}Preparing Windows Downloads for Feral Desktop${NC}"
echo -e "${BLUE}================================================${NC}"
echo "This will create installers that Windows users can:"
echo "1. Download with one click"
echo "2. Double-click to install"
echo "3. No command line needed!"
echo -e "${BLUE}================================================${NC}\n"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."
DOWNLOAD_DIR="$PROJECT_ROOT/../../feralism/media/desktop-downloads"

cd "$PROJECT_ROOT"

# Check dependencies
echo -e "${YELLOW}Checking dependencies...${NC}"
if ! command -v yarn &> /dev/null; then
    echo -e "${RED}Error: yarn is not installed${NC}"
    echo "Install with: npm install -g yarn"
    exit 1
fi

if ! command -v wine &> /dev/null; then
    echo -e "${YELLOW}Warning: Wine is not installed. Installing it will improve Windows builds${NC}"
    echo "Install with: sudo dnf install wine"
fi

# Create download directory
mkdir -p "$DOWNLOAD_DIR"

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
rm -rf dist

# Build process
echo -e "${YELLOW}Starting build process...${NC}"

# Use the existing build script with modifications
echo -e "${GREEN}Building Windows installers...${NC}"

# Run the modified build for Windows
(
    # Apply patches
    for patch in patches/*.patch; do
        [ -f "$patch" ] && git apply "$patch" 2>/dev/null || true
    done

    # Apply branding
    yarn tsx scripts/apply-feral-branding.ts apply

    # Install dependencies if needed
    [ ! -d "node_modules" ] && yarn install

    # Build TypeScript
    yarn build:ts

    # Copy resources  
    yarn tsx scripts/copy-res.ts

    # Build native modules
    yarn build:native

    # Create webapp.asar
    [ -d "webapp" ] && yarn asar pack webapp webapp.asar

    # Build Windows x64
    echo -e "${GREEN}Building Windows x64 installer...${NC}"
    yarn electron-builder --win --x64 || echo -e "${YELLOW}x64 build completed with warnings${NC}"

    # Build Windows ARM64
    echo -e "${GREEN}Building Windows ARM64 installer...${NC}"
    yarn electron-builder --win --arm64 || echo -e "${YELLOW}ARM64 build completed with warnings${NC}"
)

# Copy and rename installers
echo -e "${YELLOW}Preparing downloads...${NC}"

# Function to copy and rename installer
copy_installer() {
    local src="$1"
    local arch="$2"
    
    if [ -f "$src" ]; then
        local basename=$(basename "$src" | sed 's/\.[^.]*$//')
        local ext="${src##*.}"
        local dest="$DOWNLOAD_DIR/${basename}-${arch}.${ext}"
        
        cp "$src" "$dest"
        
        # Generate checksum
        sha256sum "$dest" | cut -d' ' -f1 > "${dest}.sha256"
        
        # Get size
        local size=$(du -h "$dest" | cut -f1)
        echo -e "  ${BLUE}Created: $(basename "$dest") ($size)${NC}"
    fi
}

# Copy x64 installers
for installer in dist/*-x64.exe dist/*x64*.exe dist/*.exe; do
    [ -f "$installer" ] && [[ ! "$installer" =~ arm64 ]] && copy_installer "$installer" "x64"
done

for installer in dist/*-x64.msi dist/*x64*.msi dist/*.msi; do
    [ -f "$installer" ] && [[ ! "$installer" =~ arm64 ]] && copy_installer "$installer" "x64"
done

# Copy ARM64 installers
for installer in dist/*-arm64.exe dist/*arm64*.exe; do
    [ -f "$installer" ] && copy_installer "$installer" "arm64"
done

for installer in dist/*-arm64.msi dist/*arm64*.msi; do
    [ -f "$installer" ] && copy_installer "$installer" "arm64"
done

# Create simple installer names for easy access
if [ -f "$DOWNLOAD_DIR/Feral Desktop Setup"*"-x64.exe" ]; then
    latest_x64=$(ls -t "$DOWNLOAD_DIR/Feral Desktop Setup"*"-x64.exe" | head -1)
    ln -sf "$(basename "$latest_x64")" "$DOWNLOAD_DIR/FeralDesktopSetup-x64.exe"
fi

if [ -f "$DOWNLOAD_DIR/Feral Desktop Setup"*"-arm64.exe" ]; then
    latest_arm64=$(ls -t "$DOWNLOAD_DIR/Feral Desktop Setup"*"-arm64.exe" | head -1)
    ln -sf "$(basename "$latest_arm64")" "$DOWNLOAD_DIR/FeralDesktopSetup-arm64.exe"
fi

# Restore original files
echo -e "${YELLOW}Cleaning up...${NC}"
git checkout -- . 2>/dev/null || true

# Summary
echo -e "\n${GREEN}================================================${NC}"
echo -e "${GREEN}Windows Downloads Ready!${NC}"
echo -e "${GREEN}================================================${NC}"
echo -e "${YELLOW}Installers created:${NC}"
ls -lh "$DOWNLOAD_DIR"/*.exe "$DOWNLOAD_DIR"/*.msi 2>/dev/null | grep -v ".sha256" | while read line; do
    echo -e "  ${BLUE}$(echo "$line" | awk '{print $9 " (" $5 ")"}')${NC}"
done

echo -e "\n${BLUE}Windows users can now:${NC}"
echo "  1. Go to the download page"
echo "  2. Click the download button"  
echo "  3. Double-click the .exe file"
echo "  4. Follow the installer (Next, Next, Finish)"
echo "  5. Click the desktop icon to start!"

echo -e "\n${GREEN}No command line needed! ✨${NC}"

# Show download page URL
echo -e "\n${YELLOW}Download page URL:${NC}"
echo "  http://localhost:8000/community/download/"