#!/bin/bash
# Build Flatpak for Feral Desktop

set -e

echo "📦 Building Feral Desktop Flatpak..."

# Check if flatpak-builder is installed
if ! command -v flatpak-builder &> /dev/null; then
    echo "❌ flatpak-builder not found. Please install it first:"
    echo "   sudo dnf install flatpak-builder"
    exit 1
fi

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."

cd "$PROJECT_ROOT"

# Ensure we have the tarball
if [ ! -f "dist/element-desktop-1.11.101.tar.gz" ]; then
    echo "❌ Tarball not found. Please build it first with:"
    echo "   yarn electron-builder --linux tar.gz --x64"
    exit 1
fi

# Create build directory
mkdir -p flatpak-build
mkdir -p flatpak-repo

# Install runtime and SDK if needed
echo "📥 Installing Flatpak runtime and SDK..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub org.freedesktop.Platform//23.08 org.freedesktop.Sdk//23.08 org.electronjs.Electron2.BaseApp//23.08 || true

# Build the Flatpak
echo "🔨 Building Flatpak..."
flatpak-builder --force-clean --repo=flatpak-repo flatpak-build io.feral.desktop.yml

# Create a bundle
echo "📦 Creating Flatpak bundle..."
flatpak build-bundle flatpak-repo feral-desktop.flatpak io.feral.desktop

# Copy to media directory
MEDIA_DIR="$PROJECT_ROOT/../../feralism/media/desktop-downloads"
if [ -d "$MEDIA_DIR" ]; then
    cp feral-desktop.flatpak "$MEDIA_DIR/"
    echo "✅ Flatpak bundle copied to $MEDIA_DIR"
fi

echo "✅ Flatpak build complete!"
echo ""
echo "To install locally:"
echo "  flatpak install feral-desktop.flatpak"
echo ""
echo "To run:"
echo "  flatpak run io.feral.desktop"