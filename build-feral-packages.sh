#!/bin/bash
# Build Feral Desktop packages for distribution

set -e

echo "🌿 Building Feral Desktop packages..."

# Check if webapp exists
if [ ! -e "webapp" ]; then
    if [ -d "../feral-web/webapp" ]; then
        echo "Creating webapp symlink..."
        ln -s ../feral-web/webapp ./webapp
    else
        echo "❌ Error: webapp not found. Please ensure feral-web is built first."
        exit 1
    fi
fi

# Install dependencies
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    yarn install
fi

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf dist/ webapp.asar

# Build TypeScript
echo "🔨 Building TypeScript..."
yarn run build:ts

# Copy resources
echo "📂 Copying resources..."
yarn run build:res

# Create webapp.asar
echo "📦 Creating webapp.asar..."
yarn run asar-webapp

# Build Linux packages
echo "🐧 Building Linux packages..."

# DEB for x64
echo "  → Building .deb (x64)..."
yarn electron-builder --linux deb --x64 || echo "Failed to build x64 deb"

# DEB for ARM64
echo "  → Building .deb (ARM64)..."
yarn electron-builder --linux deb --arm64 || echo "Failed to build ARM64 deb"

# RPM for x64
echo "  → Building .rpm (x64)..."
yarn electron-builder --linux rpm --x64 || echo "Failed to build rpm"

# AppImage
echo "  → Building AppImage..."
yarn electron-builder --linux AppImage --x64 || echo "Failed to build AppImage"

# tar.gz
echo "  → Building tar.gz..."
yarn electron-builder --linux tar.gz --x64 || echo "Failed to build tar.gz"

# List built packages
echo ""
echo "✅ Build complete! Packages created:"
ls -lh dist/*.{deb,rpm,AppImage,tar.gz} 2>/dev/null || echo "No packages found in dist/"

# Copy to Django media directory
MEDIA_DIR="../../feralism/media/desktop-downloads"
if [ -d "../../feralism" ]; then
    mkdir -p "$MEDIA_DIR"
    echo ""
    echo "📤 Copying to Django media directory..."
    cp dist/*.{deb,rpm,AppImage,tar.gz} "$MEDIA_DIR/" 2>/dev/null && echo "✅ Files copied to $MEDIA_DIR"
fi