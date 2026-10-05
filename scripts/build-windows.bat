@echo off
REM Build script for Feral Desktop on Windows
REM Usage: build-windows.bat [x64|arm64|all]

set ARCH=%1
if "%ARCH%"=="" set ARCH=all

echo Building Feral Desktop for Windows (%ARCH%)...

REM Check if PowerShell is available
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo PowerShell is not installed or not in PATH
    exit /b 1
)

REM Run the PowerShell build script
powershell -ExecutionPolicy Bypass -File "%~dp0build-windows.ps1" -Architecture %ARCH%

exit /b %ERRORLEVEL%