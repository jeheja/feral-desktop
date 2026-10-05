# Enhanced Build script for Feral Desktop on Windows
# Supports x64 and ARM64 architectures with proper installer generation

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('x64', 'arm64', 'all')]
    [string]$Architecture = 'all',
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipDependencies,
    
    [Parameter(Mandatory=$false)]
    [switch]$SignBinaries
)

$ErrorActionPreference = "Stop"

Write-Host @"
========================================
Feral Desktop Windows Build Script
========================================
Architecture: $Architecture
Skip Dependencies: $SkipDependencies
Sign Binaries: $SignBinaries
========================================
"@ -ForegroundColor Cyan

# Save original directory
$originalDir = Get-Location

# Define build configurations
$buildConfigs = @{
    'x64' = @{
        Target = 'x64'
        Platform = 'win32'
        Arch = 'x64'
        NodeArch = 'x64'
    }
    'arm64' = @{
        Target = 'arm64'
        Platform = 'win32'
        Arch = 'arm64'
        NodeArch = 'arm64'
    }
}

function Test-Prerequisites {
    Write-Host "Checking build prerequisites..." -ForegroundColor Yellow
    
    $prerequisites = @{
        'node' = 'Node.js'
        'npm' = 'npm'
        'yarn' = 'Yarn'
        'git' = 'Git'
        'python' = 'Python'
    }
    
    $missing = @()
    
    foreach ($cmd in $prerequisites.Keys) {
        if (!(Get-Command $cmd -ErrorAction SilentlyContinue)) {
            $missing += $prerequisites[$cmd]
        }
    }
    
    if ($missing.Count -gt 0) {
        throw "Missing prerequisites: $($missing -join ', '). Please install them first."
    }
    
    # Check Node version
    $nodeVersion = node --version
    Write-Host "  Node.js version: $nodeVersion" -ForegroundColor Gray
    
    # Check for Visual Studio Build Tools
    $vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vsWhere) {
        $vsPath = & $vsWhere -latest -property installationPath
        if ($vsPath) {
            Write-Host "  Visual Studio found at: $vsPath" -ForegroundColor Gray
        }
    } else {
        Write-Warning "Visual Studio Build Tools not found. Native module compilation may fail."
    }
}

function Build-Architecture {
    param(
        [string]$TargetArch
    )
    
    $config = $buildConfigs[$TargetArch]
    
    Write-Host "`nBuilding for $TargetArch..." -ForegroundColor Green
    
    # Set environment variables for native module compilation
    $env:npm_config_arch = $config.Arch
    $env:npm_config_target_arch = $config.Arch
    $env:npm_config_target_platform = $config.Platform
    $env:npm_config_target = (node -p "process.versions.electron" 2>$null) ?? "25.0.0"
    
    # Build command
    $buildCmd = "yarn electron-builder --win --$($config.Target)"
    
    # Add MSI target for better enterprise deployment
    $buildCmd += " --win.target=squirrel,msi,nsis"
    
    Write-Host "Executing: $buildCmd" -ForegroundColor Cyan
    
    # Execute build
    Invoke-Expression $buildCmd
    
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed for $TargetArch"
    }
    
    # Rename output files to include architecture
    Write-Host "Renaming output files..." -ForegroundColor Yellow
    Get-ChildItem -Path "dist" -Filter "*.exe" | Where-Object { $_.Name -notmatch $TargetArch } | ForEach-Object {
        $newName = $_.BaseName + "-$TargetArch" + $_.Extension
        Rename-Item -Path $_.FullName -NewName $newName
        Write-Host "  Renamed: $($_.Name) -> $newName" -ForegroundColor Gray
    }
    
    Get-ChildItem -Path "dist" -Filter "*.msi" | Where-Object { $_.Name -notmatch $TargetArch } | ForEach-Object {
        $newName = $_.BaseName + "-$TargetArch" + $_.Extension
        Rename-Item -Path $_.FullName -NewName $newName
        Write-Host "  Renamed: $($_.Name) -> $newName" -ForegroundColor Gray
    }
}

try {
    # Navigate to feral-desktop directory
    Set-Location -Path $PSScriptRoot\..
    
    # Test prerequisites
    Test-Prerequisites
    
    # Clean previous builds
    Write-Host "`nCleaning previous builds..." -ForegroundColor Yellow
    if (Test-Path "dist") {
        Remove-Item -Path "dist" -Recurse -Force
    }
    
    # Apply Feral patches
    Write-Host "`nApplying Feral patches..." -ForegroundColor Yellow
    Get-ChildItem -Path "patches\*.patch" | ForEach-Object {
        Write-Host "  Applying: $($_.Name)" -ForegroundColor Gray
        git apply $_.FullName
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Failed to apply patch: $($_.Name)"
        }
    }
    
    # Apply Feral branding
    Write-Host "`nApplying Feral branding..." -ForegroundColor Yellow
    yarn tsx scripts/apply-feral-branding.ts
    
    if (!$SkipDependencies) {
        # Install dependencies
        Write-Host "`nInstalling dependencies..." -ForegroundColor Yellow
        yarn install --frozen-lockfile
    }
    
    # Build TypeScript
    Write-Host "`nBuilding TypeScript..." -ForegroundColor Yellow
    yarn build:ts
    
    # Copy resources
    Write-Host "`nCopying resources..." -ForegroundColor Yellow
    yarn tsx scripts/copy-res.ts
    
    # Build native dependencies
    Write-Host "`nBuilding native dependencies..." -ForegroundColor Yellow
    yarn build:native
    
    # Create webapp.asar
    Write-Host "`nCreating webapp.asar..." -ForegroundColor Yellow
    if (Test-Path "webapp") {
        if (Get-Command asar -ErrorAction SilentlyContinue) {
            asar pack webapp webapp.asar
        } else {
            yarn asar pack webapp webapp.asar
        }
    }
    
    # Build for specified architecture(s)
    switch ($Architecture) {
        'x64' {
            Build-Architecture -TargetArch 'x64'
        }
        'arm64' {
            Build-Architecture -TargetArch 'arm64'
        }
        'all' {
            Build-Architecture -TargetArch 'x64'
            Build-Architecture -TargetArch 'arm64'
        }
    }
    
    # Sign binaries if requested
    if ($SignBinaries) {
        Write-Host "`nSigning binaries..." -ForegroundColor Yellow
        if ($env:ED_SIGNTOOL_SUBJECT_NAME -and $env:ED_SIGNTOOL_THUMBPRINT) {
            # Signing is handled by electron-builder
            Write-Host "  Binaries were signed during build process" -ForegroundColor Gray
        } else {
            Write-Warning "Signing requested but ED_SIGNTOOL_SUBJECT_NAME and ED_SIGNTOOL_THUMBPRINT not set"
        }
    }
    
    # Create checksums
    Write-Host "`nGenerating checksums..." -ForegroundColor Yellow
    Get-ChildItem -Path "dist" -Include "*.exe", "*.msi" | ForEach-Object {
        $hash = Get-FileHash -Path $_.FullName -Algorithm SHA256
        "$($hash.Hash)  $($_.Name)" | Out-File -FilePath "$($_.FullName).sha256" -Encoding utf8
        Write-Host "  Created: $($_.Name).sha256" -ForegroundColor Gray
    }
    
    # List built files
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "Build completed successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "`nFiles created:" -ForegroundColor Yellow
    
    Get-ChildItem -Path "dist" -Include "*.exe", "*.msi" | ForEach-Object {
        $size = "{0:N2}" -f ($_.Length / 1MB)
        Write-Host "  $($_.Name) ($size MB)" -ForegroundColor White
    }
    
    # Restore original files
    Write-Host "`nRestoring original files..." -ForegroundColor Yellow
    git checkout -- .
}
catch {
    Write-Host "`n========================================" -ForegroundColor Red
    Write-Host "Build failed!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    
    # Restore original files on error
    Set-Location $originalDir
    git checkout -- . 2>$null
    exit 1
}
finally {
    Set-Location $originalDir
}

Write-Host "`nTo distribute the installers, copy the files from the 'dist' directory." -ForegroundColor Cyan