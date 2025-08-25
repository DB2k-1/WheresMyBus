#!/bin/bash

# Generate Android app icon sizes from wheresmybus_appicon.png
# This script uses the macOS sips command to resize images

SOURCE_ICON="assets/images/wheresmybus_appicon.png"
ANDROID_ICONS_DIR="android/app/src/main/res"

echo "Generating Android app icon sizes..."

# Create the icons directories if they don't exist
mkdir -p "$ANDROID_ICONS_DIR/mipmap-mdpi"
mkdir -p "$ANDROID_ICONS_DIR/mipmap-hdpi"
mkdir -p "$ANDROID_ICONS_DIR/mipmap-xhdpi"
mkdir -p "$ANDROID_ICONS_DIR/mipmap-xxhdpi"
mkdir -p "$ANDROID_ICONS_DIR/mipmap-xxxhdpi"

# Generate all required Android icon sizes
echo "Generating mipmap-mdpi (48x48)..."
sips -z 48 48 "$SOURCE_ICON" --out "$ANDROID_ICONS_DIR/mipmap-mdpi/ic_launcher.png"

echo "Generating mipmap-hdpi (72x72)..."
sips -z 72 72 "$SOURCE_ICON" --out "$ANDROID_ICONS_DIR/mipmap-hdpi/ic_launcher.png"

echo "Generating mipmap-xhdpi (96x96)..."
sips -z 96 96 "$SOURCE_ICON" --out "$ANDROID_ICONS_DIR/mipmap-xhdpi/ic_launcher.png"

echo "Generating mipmap-xxhdpi (144x144)..."
sips -z 144 144 "$SOURCE_ICON" --out "$ANDROID_ICONS_DIR/mipmap-xxhdpi/ic_launcher.png"

echo "Generating mipmap-xxxhdpi (192x192)..."
sips -z 192 192 "$SOURCE_ICON" --out "$ANDROID_ICONS_DIR/mipmap-xxxhdpi/ic_launcher.png"

echo "Android app icons generated successfully!"
echo "Icons saved to: $ANDROID_ICONS_DIR/mipmap-*"
