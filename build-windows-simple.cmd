@echo off
REM Simple Windows build script for Feral Desktop
REM This creates installers for both x64 and ARM64

echo ========================================
echo Building Feral Desktop for Windows
echo ========================================

REM Check if yarn is available
where yarn >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Yarn is not installed. Please install it first.
    echo Run: npm install -g yarn
    exit /b 1
)

REM Clean dist directory
echo Cleaning previous builds...
if exist dist rd /s /q dist

REM Apply patches
echo Applying patches...
for %%f in (patches\*.patch) do (
    echo   Applying %%f
    git apply %%f
)

REM Apply Feral branding
echo Applying Feral branding...
call yarn tsx scripts/apply-feral-branding.ts

REM Install dependencies
echo Installing dependencies...
call yarn install

REM Build TypeScript
echo Building TypeScript...
call yarn build:ts

REM Copy resources
echo Copying resources...
call yarn tsx scripts/copy-res.ts

REM Build native modules
echo Building native modules...
call yarn build:native

REM Create webapp.asar
echo Creating webapp.asar...
if exist webapp (
    call yarn asar pack webapp webapp.asar
)

REM Build x64 installer
echo.
echo Building x64 installer...
call yarn electron-builder --win --x64

REM Build ARM64 installer
echo.
echo Building ARM64 installer...
call yarn electron-builder --win --arm64

REM Restore original files
echo.
echo Restoring original files...
git checkout -- .

REM Show results
echo.
echo ========================================
echo Build completed!
echo ========================================
echo Check the 'dist' directory for installers:
dir /b dist\*.exe dist\*.msi

pause