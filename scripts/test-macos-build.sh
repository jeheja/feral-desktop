#!/bin/bash
# Quick test script to create dummy DMG files for testing the download page

echo "Creating test DMG files in dist directory..."

cd "$(dirname "$0")/.."
mkdir -p dist

# Get version from package.json
VERSION=$(node -p "require('./package.json').version" 2>/dev/null || echo "1.0.0")

# Create more realistic file names
touch "dist/Feral Desktop-${VERSION}-universal.dmg"
touch "dist/Feral Desktop-${VERSION}-arm64.dmg"  
touch "dist/Feral Desktop-${VERSION}-x64.dmg"

# Add some size to make them realistic
dd if=/dev/zero of="dist/Feral Desktop-${VERSION}-universal.dmg" bs=1M count=150 2>/dev/null
dd if=/dev/zero of="dist/Feral Desktop-${VERSION}-arm64.dmg" bs=1M count=120 2>/dev/null
dd if=/dev/zero of="dist/Feral Desktop-${VERSION}-x64.dmg" bs=1M count=130 2>/dev/null

echo "Test DMG files created:"
ls -lh dist/*.dmg