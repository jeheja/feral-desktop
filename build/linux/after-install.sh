#!/bin/bash
# Post-install script for Feral Desktop on Linux

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

# Create system-wide configuration directory
mkdir -p /etc/feral-desktop
chmod 755 /etc/feral-desktop

# Set up default Matrix homeserver (optional - users can change this)
cat > /etc/feral-desktop/config.json << EOF
{
    "default_server_config": {
        "m.homeserver": {
            "base_url": "https://matrix.feral.io",
            "server_name": "feral.io"
        }
    },
    "brand": "Feral",
    "integrations_ui_url": "https://scalar.vector.im/",
    "integrations_rest_url": "https://scalar.vector.im/api",
    "bug_report_endpoint_url": "https://element.io/bugreports/submit",
    "features": {
        "feature_spaces": true,
        "feature_voice_messages": true,
        "feature_polls": true,
        "feature_location_share": true
    }
}
EOF

echo "Feral Desktop has been installed successfully!"
echo "You can start it from your applications menu or by running 'feral-desktop'"