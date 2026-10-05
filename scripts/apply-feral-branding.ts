#!/usr/bin/env tsx
/*
 * Script to apply Feral branding during build process
 * This allows us to maintain upstream compatibility while customizing the build
 */

import * as fs from "node:fs";
import * as path from "node:path";

const FERAL_CONFIG_PATH = "./feral-build-config.json";
const ELECTRON_BUILDER_PATH = "./electron-builder.ts";

interface FeralConfig {
    productName: string;
    appId: string;
    protocolScheme: string;
    description: string;
    configDir: string;
    icons: {
        linux: string;
        mac: string;
        win: string;
    };
}

function applyFeralBranding(): void {
    console.log("Applying Feral branding...");
    
    // Read Feral config
    const feralConfig: FeralConfig = JSON.parse(fs.readFileSync(FERAL_CONFIG_PATH, "utf8"));
    
    // Create temporary package.json with Feral branding
    const packageJson = JSON.parse(fs.readFileSync("package.json", "utf8"));
    const originalPackageJson = { ...packageJson };
    
    packageJson.productName = feralConfig.productName;
    packageJson.description = feralConfig.description;
    packageJson.name = "feral-desktop";
    packageJson.author = "Feralisme";
    packageJson.homepage = "https://feralisme.fr";
    
    // Write temporary package.json
    fs.writeFileSync("package.json.original", JSON.stringify(originalPackageJson, null, 2));
    fs.writeFileSync("package.json", JSON.stringify(packageJson, null, 2));
    
    // Update electron-builder config
    let builderConfig = fs.readFileSync(ELECTRON_BUILDER_PATH, "utf8");
    
    // Replace app ID
    builderConfig = builderConfig.replace(
        /appId: DEFAULT_APP_ID/g,
        `appId: "${feralConfig.appId}"`
    );
    
    // Replace protocol scheme
    builderConfig = builderConfig.replace(
        /electron_appId: DEFAULT_APP_ID/g,
        `electron_appId: "${feralConfig.appId}"`
    );
    builderConfig = builderConfig.replace(
        /electron_protocol: DEFAULT_PROTOCOL_SCHEME/g,
        `electron_protocol: "${feralConfig.protocolScheme}"`
    );
    
    // Replace icon paths
    builderConfig = builderConfig.replace(
        /icon: "build\/icons\/"/g,
        `icon: "${feralConfig.icons.linux.replace('.png', '')}"`
    );
    
    // Write temporary electron-builder config
    fs.writeFileSync("electron-builder.ts.original", fs.readFileSync(ELECTRON_BUILDER_PATH));
    fs.writeFileSync(ELECTRON_BUILDER_PATH, builderConfig);
    
    console.log("Feral branding applied successfully!");
}

function restoreOriginalFiles(): void {
    console.log("Restoring original files...");
    
    if (fs.existsSync("package.json.original")) {
        fs.renameSync("package.json.original", "package.json");
    }
    
    if (fs.existsSync("electron-builder.ts.original")) {
        fs.renameSync("electron-builder.ts.original", "electron-builder.ts");
    }
    
    console.log("Original files restored!");
}

// Check command line arguments
const command = process.argv[2];

if (command === "apply") {
    applyFeralBranding();
} else if (command === "restore") {
    restoreOriginalFiles();
} else {
    console.log("Usage: tsx apply-feral-branding.ts [apply|restore]");
    process.exit(1);
}