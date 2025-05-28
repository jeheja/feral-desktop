#!/bin/bash
# Script to update from upstream Element Desktop while preserving Feral customizations

set -e

echo "=== Feral Desktop Upstream Update Script ==="
echo

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "ERROR: You have uncommitted changes. Please commit or stash them first."
    exit 1
fi

# Add upstream remote if it doesn't exist
if ! git remote | grep -q "^upstream$"; then
    echo "Adding upstream remote..."
    git remote add upstream https://github.com/element-hq/element-desktop.git
fi

echo "1. Fetching latest from upstream..."
git fetch upstream --tags

echo
echo "2. Finding latest stable release..."
LATEST_TAG=$(git tag -l "v*" | grep -v rc | grep -v alpha | grep -v beta | sort -V | tail -1)
echo "   Latest stable tag: $LATEST_TAG"

echo
echo "3. Checking out the latest stable release..."
git checkout $LATEST_TAG

echo
echo "4. Creating/updating feral-stable branch..."
git branch -f feral-stable

echo
echo "5. Checking out feral-stable branch..."
git checkout feral-stable

echo
echo "6. Applying Feral patches..."
for patch in patches/*.patch; do
    if [ -f "$patch" ]; then
        echo "   Applying $(basename $patch)..."
        git apply "$patch" || {
            echo "ERROR: Failed to apply patch $patch"
            echo "You may need to update the patch for the new version"
            exit 1
        }
    fi
done

echo
echo "=== Update Complete ==="
echo
echo "Current version: $LATEST_TAG"
echo
echo "Next steps:"
echo "1. Test the application thoroughly"
echo "2. If patches failed to apply, update them and re-run this script"
echo "3. Run: yarn install (if package.json changed)"
echo "4. Run: ./scripts/build-feral.sh"
echo "5. Commit the changes if everything works"