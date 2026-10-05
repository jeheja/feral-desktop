#!/bin/bash

# Build Windows installers from Linux
# This creates ready-to-use Windows installers that users can simply download and run

set -e

echo "================================================"
echo "Building Windows Installers from Linux"
echo "================================================"
echo "This will create .exe installers that Windows users can:"
echo "1. Download with one click"
echo "2. Double-click to install" 
echo "3. No command line needed!"
echo "================================================"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/.."

# Output directory for downloads
DOWNLOAD_DIR="../../feralism/media/desktop-downloads"
mkdir -p "$DOWNLOAD_DIR"

# Clean dist directory
echo -e "${YELLOW}Cleaning previous builds...${NC}"
rm -rf dist

# Apply patches
echo -e "${YELLOW}Applying patches...${NC}"
for patch in patches/*.patch; do
    if [ -f "$patch" ]; then
        echo "  Applying $(basename "$patch")"
        git apply "$patch" || echo "  Warning: Failed to apply $(basename "$patch")"
    fi
done

# Apply Feral branding
echo -e "${YELLOW}Applying Feral branding...${NC}"
yarn tsx scripts/apply-feral-branding.ts

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}Installing dependencies...${NC}"
    yarn install
fi

# Build TypeScript
echo -e "${YELLOW}Building TypeScript...${NC}"
yarn build:ts

# Copy resources
echo -e "${YELLOW}Copying resources...${NC}"
yarn tsx scripts/copy-res.ts

# Build native modules
echo -e "${YELLOW}Building native modules...${NC}"
yarn build:native

# Create webapp.asar
echo -e "${YELLOW}Creating webapp.asar...${NC}"
if [ -d "webapp" ]; then
    yarn asar pack webapp webapp.asar
fi

# Install Wine if needed (for Windows builds on Linux)
if ! command -v wine &> /dev/null; then
    echo -e "${YELLOW}Wine is not installed. Installing Wine for Windows builds...${NC}"
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y wine wine32 wine64
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y wine
    elif command -v yum &> /dev/null; then
        sudo yum install -y wine
    else
        echo -e "${YELLOW}Please install Wine manually to build Windows installers${NC}"
        exit 1
    fi
fi

# Build Windows x64 installer
echo -e "${GREEN}Building Windows x64 installer...${NC}"
yarn electron-builder --win --x64 --config electron-builder-windows.json

# Build Windows ARM64 installer
echo -e "${GREEN}Building Windows ARM64 installer...${NC}"
yarn electron-builder --win --arm64 --config electron-builder-windows.json

# Copy installers to download directory
echo -e "${YELLOW}Copying installers to download directory...${NC}"
for file in dist/*.exe dist/*.msi; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        cp "$file" "$DOWNLOAD_DIR/"
        
        # Generate checksum
        sha256sum "$file" | cut -d' ' -f1 > "$DOWNLOAD_DIR/${filename}.sha256"
        
        # Get file size
        size=$(du -h "$file" | cut -f1)
        echo -e "  ${BLUE}Copied: $filename ($size)${NC}"
    fi
done

# Create download info
echo -e "${YELLOW}Creating download info...${NC}"
cat > "$DOWNLOAD_DIR/windows-downloads.json" << EOF
{
  "generated": "$(date -Iseconds)",
  "platform": "windows",
  "installers": [
EOF

first=true
for file in "$DOWNLOAD_DIR"/*.exe "$DOWNLOAD_DIR"/*.msi; do
    if [ -f "$file" ] && [[ ! "$file" =~ \.sha256$ ]]; then
        filename=$(basename "$file")
        size=$(du -h "$file" | cut -f1)
        
        if [ "$first" = true ]; then
            first=false
        else
            echo "," >> "$DOWNLOAD_DIR/windows-downloads.json"
        fi
        
        cat >> "$DOWNLOAD_DIR/windows-downloads.json" << EOF
    {
      "filename": "$filename",
      "size": "$size",
      "sha256": "$(cat "$file.sha256" 2>/dev/null || echo "pending")"
    }
EOF
    fi
done

cat >> "$DOWNLOAD_DIR/windows-downloads.json" << EOF

  ]
}
EOF

# Restore original files
echo -e "${YELLOW}Restoring original files...${NC}"
git checkout -- .

# Display summary
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Windows Installers Ready!${NC}"
echo -e "${GREEN}================================================${NC}"
echo -e "${YELLOW}Files created in $DOWNLOAD_DIR:${NC}"
ls -lh "$DOWNLOAD_DIR"/*.exe "$DOWNLOAD_DIR"/*.msi 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'

echo -e "\n${BLUE}These installers are ready for Windows users to:${NC}"
echo "  1. Download from the website"
echo "  2. Double-click to install"
echo "  3. Start using Feral Desktop!"
echo -e "\n${GREEN}No command line needed for users! ✨${NC}"