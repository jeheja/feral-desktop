#!/bin/bash
set -e

# Build script for macOS DMG files
echo "Building Feral Desktop for macOS..."

# Navigate to project root
cd "$(dirname "$0")/.."

# Check if we're on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "Error: This script must be run on macOS to create DMG files"
    echo "For cross-platform builds, use build-macos-on-linux.sh"
    exit 1
fi

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf dist/mac* dist/*.dmg || true

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    yarn install
fi

# Build TypeScript
echo "Building TypeScript..."
yarn build:ts

# Build resources
echo "Building resources..."
yarn build:res

# Package the webapp if it exists
if [ -d "webapp" ]; then
    echo "Packaging webapp..."
    yarn asar-webapp
fi

# Apply Feral branding
echo "Applying Feral branding..."
yarn tsx scripts/apply-feral-branding.ts apply

# Build for different architectures
echo "Building macOS packages..."

# Build for Apple Silicon (arm64)
echo "Building for Apple Silicon (M1/M2)..."
yarn electron-builder --mac --arm64 --config feral-electron-builder.json

# Build for Intel (x64)
echo "Building for Intel Macs..."
yarn electron-builder --mac --x64 --config feral-electron-builder.json

# Build Universal (if possible)
echo "Building Universal package..."
yarn electron-builder --mac --universal --config feral-electron-builder.json || echo "Universal build not available"

# Rename DMG files with architecture info
cd dist
for dmg in *.dmg; do
    if [[ -f "$dmg" ]]; then
        if [[ "$dmg" == *"-arm64.dmg" ]]; then
            # Already has architecture suffix
            continue
        elif [[ "$dmg" == *"-x64.dmg" ]]; then
            # Already has architecture suffix
            continue
        elif [[ "$dmg" == *"-universal.dmg" ]]; then
            # Already has architecture suffix
            continue
        else
            # Add architecture suffix based on file
            if file "$dmg" | grep -q "arm64"; then
                mv "$dmg" "${dmg%.dmg}-arm64.dmg"
            elif file "$dmg" | grep -q "x86_64"; then
                mv "$dmg" "${dmg%.dmg}-x64.dmg"
            fi
        fi
    fi
done

echo "Build complete! DMG files are in the dist/ directory:"
ls -la *.dmg 2>/dev/null || echo "No DMG files found"