# Feral Desktop Customization

This document explains how Feral Desktop is customized while maintaining compatibility with upstream Element Desktop.

## Overview

Instead of modifying core files directly, we use a build-time customization approach:

1. **feral-build-config.json** - Contains all Feral-specific branding configuration
2. **scripts/apply-feral-branding.ts** - Applies branding temporarily during build
3. **scripts/build-feral.sh** - Custom build script that handles the entire process
4. **feral.io/** - Directory containing Feral-specific configuration

## Building Feral Desktop

### Prerequisites

1. Ensure feral-web is built and available:
   ```bash
   cd ../feral-web
   yarn build
   ```

2. The webapp symlink should already exist (created during setup):
   ```bash
   ls -la webapp  # Should point to ../feral-web/webapp
   ```

### Build Process

To build Feral Desktop:

```bash
./scripts/build-feral.sh
```

This script will:
1. Apply Feral branding temporarily
2. Build the TypeScript code
3. Copy resources
4. Create webapp.asar from the symlinked feral-web
5. Run electron-builder
6. Restore original files

### Development Mode

For development, you can run:

```bash
yarn start
```

This will use the symlinked webapp directly without packaging.

## Customization Files

- **feral-build-config.json** - Main configuration for Feral branding
- **feral.io/release/config.json** - Feral-specific app configuration
- **build/icons/** - Feral logo files for different platforms

## Updating from Upstream

When updating from upstream Element Desktop:

1. Pull the latest changes from upstream
2. Ensure no conflicts with our customization files
3. Run the build script as usual

The customization approach ensures minimal conflicts with upstream changes.

## Icons

- Windows: `build/icons/feral.ico`
- Linux: `build/icons/feral.png`
- macOS: `build/icons/feral.icns` (needs to be created)

## Configuration

The app will use the configuration from `feral.io/release/config.json` which includes:
- Feral homeserver settings
- Disabled registration (redirects to feralisme.fr)
- Feral branding throughout the app