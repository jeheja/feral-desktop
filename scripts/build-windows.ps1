# Build script for Feral Desktop on Windows
# Supports both x64 and ARM64 architectures

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('x64', 'arm64', 'all')]
    [string]$Architecture = 'all'
)

$ErrorActionPreference = "Stop"

Write-Host "Building Feral Desktop for Windows..." -ForegroundColor Green

# Save original directory
$originalDir = Get-Location

try {
    # Navigate to feral-desktop directory
    Set-Location -Path $PSScriptRoot\..

    # Check if required tools are installed
    Write-Host "Checking build requirements..." -ForegroundColor Yellow
    
    $requiredCommands = @('node', 'npm', 'yarn', 'git', 'python')
    foreach ($cmd in $requiredCommands) {
        if (!(Get-Command $cmd -ErrorAction SilentlyContinue)) {
            throw "$cmd is not installed. Please install it first."
        }
    }

    # Clean previous builds
    Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
    if (Test-Path "dist") {
        Remove-Item -Path "dist" -Recurse -Force
    }

    # Apply Feral patches
    Write-Host "Applying Feral patches..." -ForegroundColor Yellow
    Get-ChildItem -Path "patches\*.patch" | ForEach-Object {
        Write-Host "  Applying patch: $($_.Name)"
        git apply $_.FullName
    }

    # Apply Feral branding
    Write-Host "Applying Feral branding..." -ForegroundColor Yellow
    yarn tsx scripts/apply-feral-branding.ts

    # Install dependencies
    Write-Host "Installing dependencies..." -ForegroundColor Yellow
    yarn install

    # Build TypeScript
    Write-Host "Building TypeScript..." -ForegroundColor Yellow
    yarn build:ts

    # Copy resources
    Write-Host "Copying resources..." -ForegroundColor Yellow
    yarn tsx scripts/copy-res.ts

    # Build native dependencies
    Write-Host "Building native dependencies..." -ForegroundColor Yellow
    yarn build:native

    # Create webapp.asar
    Write-Host "Creating webapp.asar..." -ForegroundColor Yellow
    if (Test-Path "webapp") {
        yarn asar pack webapp webapp.asar
    }

    # Build for specified architecture(s)
    Write-Host "Building installer(s)..." -ForegroundColor Yellow
    
    $buildCommands = @()
    
    switch ($Architecture) {
        'x64' {
            $buildCommands += "yarn electron-builder --win --x64"
        }
        'arm64' {
            $buildCommands += "yarn electron-builder --win --arm64"
        }
        'all' {
            $buildCommands += "yarn electron-builder --win --x64"
            $buildCommands += "yarn electron-builder --win --arm64"
        }
    }

    foreach ($cmd in $buildCommands) {
        Write-Host "Running: $cmd" -ForegroundColor Cyan
        Invoke-Expression $cmd
    }

    # List built files
    Write-Host "`nBuild completed! Files created:" -ForegroundColor Green
    Get-ChildItem -Path "dist\*.exe", "dist\*.msi" | ForEach-Object {
        Write-Host "  - $($_.Name) ($('{0:N2}' -f ($_.Length / 1MB)) MB)" -ForegroundColor White
    }

    # Restore original files
    Write-Host "`nRestoring original files..." -ForegroundColor Yellow
    git checkout -- .
}
catch {
    Write-Host "Build failed: $_" -ForegroundColor Red
    # Restore original files on error
    Set-Location $originalDir
    git checkout -- . 2>$null
    exit 1
}
finally {
    Set-Location $originalDir
}

Write-Host "`nWindows build completed successfully!" -ForegroundColor Green