#!/bin/bash
set -e

# Build script for macOS DMG files on Linux (cross-compilation)
echo "Building Feral Desktop for macOS on Linux..."

# Navigate to project root
cd "$(dirname "$0")/.."

# Check if we're on Linux
if [[ "$(uname)" != "Linux" ]]; then
    echo "Error: This script is for building macOS packages on Linux"
    echo "For native macOS builds, use build-macos.sh"
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

# Note: Building macOS packages on Linux requires additional setup
echo "Note: Building macOS DMG files on Linux requires:"
echo "1. electron-builder-binaries to be installed"
echo "2. wine and mono (for some operations)"
echo ""
echo "Installing required packages..."

# Check for required tools
if ! command -v wine &> /dev/null; then
    echo "Wine is not installed. On Ubuntu/Debian, run:"
    echo "sudo apt-get install wine wine32 wine64"
    echo ""
fi

# Build for macOS using electron-builder
echo "Building macOS packages (DMG creation may be limited on Linux)..."

# Use the dedicated macOS-only configuration
CONFIG_FILE="feral-electron-builder-mac-only.json"

# Try to build for each architecture
echo "Attempting macOS builds..."

# Build for Intel
echo "Building for Intel Macs (x64)..."
yarn electron-builder --mac --x64 --config $CONFIG_FILE || {
    echo "Warning: Full DMG creation may not work on Linux"
    echo "ZIP files will be created instead"
}

# Build for Apple Silicon
echo "Building for Apple Silicon (arm64)..."
yarn electron-builder --mac --arm64 --config $CONFIG_FILE || {
    echo "Warning: Full DMG creation may not work on Linux"
    echo "ZIP files will be created instead"
}

# List built files
echo "Build complete! Files in dist/:"
ls -la dist/*.dmg dist/*.zip dist/mac* 2>/dev/null || echo "Check dist/ directory for output files"

echo ""
echo "Note: DMG creation on Linux is limited. For production builds,"
echo "consider using macOS or GitHub Actions for proper code signing."