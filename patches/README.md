# Feral Desktop Patches

This directory contains patches that are applied to Element Desktop to create Feral Desktop.

## Current Patches

- **001-fix-getConfig-handler.patch** - Adds missing getConfig IPC handler required for proper Electron platform detection

## How it works

1. During build (`./scripts/build-feral.sh`):
   - All patches in this directory are applied
   - The build proceeds with Feral customizations
   - After build, patches are reverted to keep the repository clean

2. When updating from upstream (`./scripts/update-from-upstream.sh`):
   - The script fetches the latest stable Element Desktop release
   - Applies all patches from this directory
   - If any patch fails, you'll need to update it for the new version

## Creating new patches

To create a new patch:
1. Make your changes to the code
2. Create a patch: `git diff path/to/file > patches/NNN-description.patch`
3. Test that it applies cleanly: `git apply patches/NNN-description.patch`
4. Revert your changes: `git checkout -- path/to/file`

## Patch naming convention

Use the format: `NNN-short-description.patch`
- NNN: Three-digit number (001, 002, etc.) for ordering
- short-description: Brief description of what the patch does