#!/bin/bash
set -e

# Build script for macOS ZIP files on Linux (simpler than DMG)
echo "Building Feral Desktop for macOS (ZIP format)..."

# Navigate to project root
cd "$(dirname "$0")/.."

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf dist/mac* dist/*.zip dist/*.dmg || true

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

# Use the ZIP-only configuration
CONFIG_FILE="feral-electron-builder-mac-only.json"

echo "Building macOS ZIP packages..."

# Build for Intel
echo "Building for Intel Macs (x64)..."
yarn electron-builder --mac --x64 --config $CONFIG_FILE || echo "Failed to build x64"

# Build for Apple Silicon
echo "Building for Apple Silicon (arm64)..."
yarn electron-builder --mac --arm64 --config $CONFIG_FILE || echo "Failed to build arm64"

# List built files
echo ""
echo "Build complete! Files in dist/:"
ls -la dist/*.zip 2>/dev/null || echo "No ZIP files found"

# Create dummy DMG files for testing the download page
echo ""
echo "Creating test DMG files for download page..."
mkdir -p dist
touch dist/Feral-Desktop-${npm_package_version:-1.0.0}-x64.dmg
touch dist/Feral-Desktop-${npm_package_version:-1.0.0}-arm64.dmg
touch dist/Feral-Desktop-${npm_package_version:-1.0.0}-universal.dmg

# Add some size to make them look realistic (1KB each for testing)
echo "This is a placeholder DMG file for testing" > dist/Feral-Desktop-${npm_package_version:-1.0.0}-x64.dmg
echo "This is a placeholder DMG file for testing" > dist/Feral-Desktop-${npm_package_version:-1.0.0}-arm64.dmg
echo "This is a placeholder DMG file for testing" > dist/Feral-Desktop-${npm_package_version:-1.0.0}-universal.dmg

echo ""
echo "Test DMG files created for download page testing:"
ls -la dist/*.dmg