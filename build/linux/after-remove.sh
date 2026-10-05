#!/bin/bash
# Post-remove script for Feral Desktop on Linux

# Update desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database /usr/share/applications || true
fi

# Update icon cache
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t /usr/share/icons/hicolor || true
fi

# Update MIME database
if command -v update-mime-database >/dev/null 2>&1; then
    update-mime-database /usr/share/mime || true
fi

# Remove configuration directory only if empty
rmdir /etc/feral-desktop 2>/dev/null || true

echo "Feral Desktop has been removed."