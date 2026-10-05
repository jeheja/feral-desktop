#!/bin/bash

# Simple script to build Windows installers from Linux

echo "Building Windows installers..."

# Clean dist
rm -rf dist

# Apply patches and branding
./scripts/build-feral.sh

# Build Windows x64
echo "Building Windows x64..."
yarn electron-builder --win --x64

# Build Windows ARM64  
echo "Building Windows ARM64..."
yarn electron-builder --win --arm64

# Copy to downloads
DOWNLOAD_DIR="../../feralism/media/desktop-downloads"
mkdir -p "$DOWNLOAD_DIR"

echo "Copying installers..."
cp dist/*.exe dist/*.msi "$DOWNLOAD_DIR/" 2>/dev/null || true

echo "Done! Windows installers are in:"
ls -lh "$DOWNLOAD_DIR"/*.exe "$DOWNLOAD_DIR"/*.msi 2>/dev/null

# Restore files
git checkout -- .