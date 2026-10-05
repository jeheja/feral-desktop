# Windows Build Guide for Feral Desktop

This guide explains how to build Feral Desktop installers for Windows, supporting both x64 and ARM64 architectures.

## Prerequisites

### Required Software

1. **Git for Windows** - https://git-scm.com/download/win
2. **Node.js 16+** - https://nodejs.org/ (includes npm)
3. **Yarn** - Install via npm: `npm install -g yarn`
4. **Python 3** - https://www.python.org/downloads/
5. **Visual Studio 2019/2022 Build Tools** - Required for native modules
   - Download from: https://visualstudio.microsoft.com/downloads/
   - Select "Desktop development with C++" workload
6. **Windows SDK** - Usually installed with Visual Studio Build Tools

### Optional (for specific features)

- **Strawberry Perl** - For OpenSSL compilation
- **NASM** - For assembly compilation
- **Rustup** - For Rust-based dependencies

## Building Installers

### Quick Build (All Architectures)

```powershell
cd matrix\feral-desktop
.\scripts\build-windows.bat
```

### Building Specific Architecture

```powershell
# For x64 only
.\scripts\build-windows.bat x64

# For ARM64 only
.\scripts\build-windows.bat arm64

# For both architectures
.\scripts\build-windows.bat all
```

### Advanced Build Options

Use the enhanced PowerShell script for more control:

```powershell
# Skip dependency installation (if already installed)
.\scripts\build-windows-enhanced.ps1 -Architecture x64 -SkipDependencies

# Build with code signing
$env:ED_SIGNTOOL_SUBJECT_NAME = "Your Company Name"
$env:ED_SIGNTOOL_THUMBPRINT = "YOUR_CERT_THUMBPRINT"
.\scripts\build-windows-enhanced.ps1 -Architecture all -SignBinaries
```

## Output Files

The build process creates the following installer types in the `dist` directory:

### For x64 Architecture
- `Feral Desktop Setup x.x.x-x64.exe` - Squirrel installer (recommended)
- `Feral Desktop x.x.x-x64.msi` - MSI installer (for enterprise deployment)
- `Feral Desktop Setup x.x.x-x64.exe` - NSIS installer (alternative)

### For ARM64 Architecture
- `Feral Desktop Setup x.x.x-arm64.exe` - Squirrel installer
- `Feral Desktop x.x.x-arm64.msi` - MSI installer
- `Feral Desktop Setup x.x.x-arm64.exe` - NSIS installer

### Checksums
- `*.sha256` files for each installer

## Installer Types Explained

### Squirrel Installer (.exe)
- **Pros**: Auto-updates, delta updates, fast installation
- **Cons**: Installs per-user (not system-wide)
- **Best for**: Individual users

### MSI Installer (.msi)
- **Pros**: System-wide installation, Group Policy support, silent installation
- **Cons**: No auto-update
- **Best for**: Enterprise deployment

### NSIS Installer (.exe)
- **Pros**: Customizable, system-wide installation option
- **Cons**: Larger file size
- **Best for**: Users who prefer traditional installers

## Code Signing

To sign the installers, you need a code signing certificate:

1. Set environment variables before building:
   ```powershell
   $env:ED_SIGNTOOL_SUBJECT_NAME = "Your Company Name"
   $env:ED_SIGNTOOL_THUMBPRINT = "YOUR_CERTIFICATE_THUMBPRINT"
   ```

2. Run the build with signing enabled:
   ```powershell
   .\scripts\build-windows-enhanced.ps1 -SignBinaries
   ```

## Troubleshooting

### Native Module Compilation Fails
- Ensure Visual Studio Build Tools are installed with C++ workload
- Check that Python is in PATH
- Try cleaning npm cache: `npm cache clean --force`

### ARM64 Build Issues
- ARM64 builds require cross-compilation on x64 machines
- Some native modules may not support ARM64

### Missing Dependencies
- Run `yarn install` in the project directory
- Ensure all prerequisites are installed and in PATH

### Build Fails with "Module not found"
- Delete `node_modules` and run `yarn install` again
- Check that all patches applied successfully

## Distribution

After building, the installers in the `dist` directory are ready for distribution:

1. **Direct Download**: Upload to your server
2. **Windows Store**: Convert using Desktop Bridge
3. **Enterprise**: Distribute MSI via Group Policy or SCCM
4. **Auto-update Server**: Set up Squirrel update server for .exe installers

## Notes for ARM64

- ARM64 support on Windows is still evolving
- Test thoroughly on actual ARM64 hardware
- Some antivirus software may flag ARM64 binaries as unusual
- Consider providing both x64 (with emulation) and native ARM64 options