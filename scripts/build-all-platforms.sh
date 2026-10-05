#!/bin/bash
# Build script to generate Feral Desktop for all platforms

set -e

echo "🚀 Building Feral Desktop for all platforms..."

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

# Apply Feral branding
echo -e "${YELLOW}Applying Feral branding...${NC}"
yarn tsx scripts/apply-feral-branding.ts apply

# Build for each platform
echo -e "${GREEN}Building for Linux...${NC}"
yarn run build:ts
yarn run build:res
yarn run asar-webapp
yarn electron-builder --linux --x64 --config feral-electron-builder.json

echo -e "${GREEN}Building for Windows...${NC}"
yarn electron-builder --windows --x64 --config feral-electron-builder.json

echo -e "${GREEN}Building for macOS...${NC}"
# Check if on macOS or Linux
if [[ "$(uname)" == "Darwin" ]]; then
    # Native macOS build
    yarn electron-builder --mac --x64 --config feral-electron-builder.json
    yarn electron-builder --mac --arm64 --config feral-electron-builder.json
else
    # Cross-platform build on Linux
    echo -e "${YELLOW}Note: Building macOS on Linux has limitations${NC}"
    yarn electron-builder --mac --x64 --config feral-electron-builder.json || echo "macOS x64 build may be incomplete"
    yarn electron-builder --mac --arm64 --config feral-electron-builder.json || echo "macOS arm64 build may be incomplete"
fi

echo -e "${GREEN}✅ Build complete!${NC}"
echo "Built files are in the dist/ directory:"
ls -la dist/

# Create a downloads directory for easy access
mkdir -p "$PROJECT_ROOT/../../feralism/media/desktop-downloads"

# Copy built files to media directory
echo -e "${YELLOW}Copying files to media directory...${NC}"
cp dist/*.tar.gz "$PROJECT_ROOT/../../feralism/media/desktop-downloads/" 2>/dev/null || true
cp dist/*.deb "$PROJECT_ROOT/../../feralism/media/desktop-downloads/" 2>/dev/null || true
cp dist/*.rpm "$PROJECT_ROOT/../../feralism/media/desktop-downloads/" 2>/dev/null || true
cp dist/*.exe "$PROJECT_ROOT/../../feralism/media/desktop-downloads/" 2>/dev/null || true
cp dist/*.msi "$PROJECT_ROOT/../../feralism/media/desktop-downloads/" 2>/dev/null || true
cp dist/*.dmg "$PROJECT_ROOT/../../feralism/media/desktop-downloads/" 2>/dev/null || true
cp dist/*.AppImage "$PROJECT_ROOT/../../feralism/media/desktop-downloads/" 2>/dev/null || true

echo -e "${GREEN}✅ Files copied to media/desktop-downloads/${NC}"