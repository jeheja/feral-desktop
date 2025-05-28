#!/bin/bash
# Feral Desktop Build Script
# This script builds Feral Desktop with custom branding

set -e

echo "🌿 Building Feral Desktop..."

# Check if webapp symlink exists
if [ ! -L "webapp" ] || [ ! -d "webapp" ]; then
    echo "❌ Error: webapp symlink not found. Please create symlink to feral-web/webapp first."
    exit 1
fi

# Apply patches
echo "🔧 Applying Feral patches..."
for patch in patches/*.patch; do
    if [ -f "$patch" ]; then
        echo "   Applying $(basename $patch)..."
        git apply "$patch" || {
            echo "❌ Error: Failed to apply patch $patch"
            exit 1
        }
    fi
done

# Apply Feral branding
echo "🎨 Applying Feral branding..."
yarn tsx scripts/apply-feral-branding.ts apply

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf dist/

# Build TypeScript
echo "🔨 Building TypeScript..."
yarn run build:ts

# Copy resources
echo "📦 Copying resources..."
yarn run build:res

# Create webapp.asar from symlinked webapp
echo "📦 Creating webapp.asar..."
yarn run asar-webapp

# Run electron-builder
echo "🚀 Running electron-builder..."
yarn electron-builder --config electron-builder.ts --dir

# Restore original files
echo "♻️  Restoring original files..."
yarn tsx scripts/apply-feral-branding.ts restore

# Revert patches
echo "🔧 Reverting patches..."
for patch in patches/*.patch; do
    if [ -f "$patch" ]; then
        git apply -R "$patch" || true
    fi
done

echo "✅ Feral Desktop build complete! Check the dist/ directory."