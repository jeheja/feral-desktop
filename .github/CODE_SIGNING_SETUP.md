# Code Signing Setup for Feral Desktop

This guide explains how to set up code signing for macOS builds using GitHub Actions.

## Prerequisites

1. Apple Developer Account ($99/year)
2. Developer ID Application certificate
3. App-specific password for notarization

## Steps

### 1. Create Developer ID Certificate

1. Log in to [Apple Developer](https://developer.apple.com)
2. Go to Certificates, Identifiers & Profiles
3. Click the + button to create a new certificate
4. Select "Developer ID Application"
5. Follow the instructions to create a CSR
6. Download the certificate

### 2. Export Certificate as P12

1. Open Keychain Access on macOS
2. Find your Developer ID Application certificate
3. Right-click and select "Export"
4. Save as .p12 format with a password
5. Convert to base64: `base64 -i certificate.p12 -o certificate.txt`

### 3. Create App-Specific Password

1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Sign in and go to Security
3. Under App-Specific Passwords, click Generate Password
4. Name it "Feral Desktop Notarization"
5. Save the password securely

### 4. Set GitHub Secrets

In your GitHub repository settings, add these secrets:

- `MACOS_CERTIFICATE`: The base64-encoded .p12 certificate
- `MACOS_CERTIFICATE_PWD`: The password for the .p12 file
- `KEYCHAIN_PWD`: A random password for the temporary keychain
- `APPLE_ID`: Your Apple ID email
- `APPLE_ID_PASSWORD`: The app-specific password from step 3
- `APPLE_TEAM_ID`: Your Team ID (found in Apple Developer account)

### 5. Update Build Configuration

Make sure your `feral-electron-builder.json` includes:

```json
{
  "mac": {
    "hardenedRuntime": true,
    "gatekeeperAssess": false,
    "entitlements": "build/entitlements.mac.plist",
    "entitlementsInherit": "build/entitlements.mac.plist",
    "notarize": {
      "teamId": "YOUR_TEAM_ID"
    }
  }
}
```

### 6. Create Entitlements File

Create `build/entitlements.mac.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.cs.allow-jit</key>
    <true/>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>
    <key>com.apple.security.cs.allow-dyld-environment-variables</key>
    <true/>
</dict>
</plist>
```

## Testing

1. Push a tag to trigger the workflow: `git tag v1.0.0 && git push --tags`
2. Check the Actions tab in GitHub
3. Download and test the signed DMG files

## Troubleshooting

### Certificate Issues
- Make sure the certificate hasn't expired
- Verify it's a "Developer ID Application" certificate
- Check that the Team ID matches

### Notarization Issues
- Ensure the app-specific password is correct
- Check that all entitlements are properly set
- Review the notarization log for specific errors

### Local Testing

To test locally on macOS:
```bash
# Check code signing
codesign -dv --verbose=4 "Feral Desktop.app"

# Verify notarization
spctl -a -t open --context context:primary-signature -v "Feral Desktop.dmg"
```

## Resources

- [Apple Developer - Notarizing macOS Software](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Electron Builder - Code Signing](https://www.electron.build/code-signing)
- [GitHub Actions - macOS runners](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners#supported-runners-and-hardware-resources)