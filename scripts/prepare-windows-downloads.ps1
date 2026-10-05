# Script to prepare Windows downloads for the Feral Desktop download page
# This creates ready-to-download installers that users can simply run

param(
    [Parameter(Mandatory=$false)]
    [string]$OutputDir = "..\..\..\feralism\media\desktop-downloads"
)

$ErrorActionPreference = "Stop"

Write-Host @"
================================================
Preparing Windows Downloads for Feral Desktop
================================================
This will create installers that users can:
1. Download with one click
2. Double-click to install
3. No command line needed!
================================================
"@ -ForegroundColor Cyan

# Ensure output directory exists
$outputPath = Join-Path $PSScriptRoot $OutputDir
if (!(Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
}

# Build installers
Write-Host "`nBuilding Windows installers..." -ForegroundColor Yellow

# Build x64
Write-Host "Building x64 installer..." -ForegroundColor Green
& "$PSScriptRoot\build-windows-enhanced.ps1" -Architecture x64

# Build ARM64
Write-Host "`nBuilding ARM64 installer..." -ForegroundColor Green
& "$PSScriptRoot\build-windows-enhanced.ps1" -Architecture arm64

# Copy installers to download directory
Write-Host "`nCopying installers to download directory..." -ForegroundColor Yellow

$distPath = Join-Path $PSScriptRoot "..\dist"
$installers = @()

# Find and copy installers
Get-ChildItem -Path $distPath -Include "*.exe", "*.msi" | ForEach-Object {
    $targetPath = Join-Path $outputPath $_.Name
    Copy-Item -Path $_.FullName -Destination $targetPath -Force
    
    $installers += @{
        Name = $_.Name
        Size = "{0:N2} MB" -f ($_.Length / 1MB)
        Path = $targetPath
    }
    
    Write-Host "  Copied: $($_.Name)" -ForegroundColor Gray
}

# Generate checksums
Write-Host "`nGenerating checksums..." -ForegroundColor Yellow
foreach ($installer in $installers) {
    $hash = Get-FileHash -Path $installer.Path -Algorithm SHA256
    "$($hash.Hash)  $($installer.Name)" | Out-File -FilePath "$($installer.Path).sha256" -Encoding utf8
}

# Create download info JSON
Write-Host "`nCreating download info..." -ForegroundColor Yellow
$downloadInfo = @{
    Generated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Installers = $installers
}

$downloadInfo | ConvertTo-Json -Depth 10 | Out-File -FilePath (Join-Path $outputPath "windows-downloads.json") -Encoding utf8

# Display summary
Write-Host "`n================================================" -ForegroundColor Green
Write-Host "Windows Downloads Ready!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host "`nInstallers created:" -ForegroundColor Yellow

foreach ($installer in $installers) {
    Write-Host "  $($installer.Name) ($($installer.Size))" -ForegroundColor White
}

Write-Host "`nThese files are ready for users to:" -ForegroundColor Cyan
Write-Host "  1. Download from the website" -ForegroundColor White
Write-Host "  2. Double-click to install" -ForegroundColor White
Write-Host "  3. Start using Feral Desktop!" -ForegroundColor White

Write-Host "`nNo command line needed! ✨" -ForegroundColor Green