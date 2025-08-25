#!/bin/bash

# Update app icons using AppIcon_doubledecker.png
# This script generates all required iOS and Android icon sizes

SOURCE_ICON="assets/images/AppIcon_doubledecker.png"
IOS_ICONS_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"
ANDROID_ICONS_DIR="android/app/src/main/res"

echo "Updating app icons with AppIcon_doubledecker.png..."

# Generate iOS app icons
echo "Generating iOS app icon sizes..."

# Create the iOS icons directory if it doesn't exist
mkdir -p "$IOS_ICONS_DIR"

# Generate all required iOS icon sizes
echo "Generating 20x20@1x..."
sips -z 20 20 "$SOURCE_ICON" --out "$IOS_ICONS_DIR/Icon-App-20x20@1x.png"

echo "Generating 20x20@2x..."
sips -z 40 40 "$SOURCE_ICON" --out "$IOS_ICONS_DIR/Icon-App-20x20@2x.png"

echo "Generating 20x20@3x..."
sips -z 60 60 "$SOURCE_ICON" --out "$IOS_ICONS_DIR/Icon-App-20x20@3x.png"

echo "Generating 29x29@1x..."
sips -z 29 29 "$SOURCE_ICON" --out "$IOS_ICONS_DIR/Icon-App-29x29@1x.png"

echo "Generating 29x29@2x..."
sips -z 58 58 "$SOURCE_ICON" --out "$IOS_ICONS_DIR/Icon-App-29x29@2x.png"

echo "Generating 29x29@3x..."
sips -z 87 87 "$SOURCE_ICON" --out "$IOS_ICONS_DIR/Icon-App-29x29@3x.png"

echo "Generating 40x40@1x..."
sips -z 40 40 "$SOURCE_ICON" --out "$IOS_ICONS_DIR/Icon-App-40x40@1x.png"

echo "Generating 40x40@2x..."
sips -z 80 80 "$SOURCE_ICON" --out "$IOS_ICONS_DIR/Icon-App-40x40@2x.png"

echo "Generating 40x40@3x..."
sips -z 120 120 "$SOURCE_ICON" --out "$IOS_ICONS_DIR/Icon-App-40x40@3x.png"

echo "Generating 60x60@2x..."
sips -z 120 120 "$SOURCE_ICON" --out "$IOS_ICONS_DIR/Icon-App-60x60@2x.png"

echo "Generating 60x60@3x..."
sips -z 180 180 "$SOURCE_ICON" --out "$IOS_ICONS_DIR/Icon-App-60x60@3x.png"

echo "Generating 76x76@1x..."
sips -z 76 76 "$SOURCE_ICON" --out "$IOS_ICONS_DIR/Icon-App-76x76@1x.png"

echo "Generating 76x76@2x..."
sips -z 152 152 "$SOURCE_ICON" --out "$IOS_ICONS_DIR/Icon-App-76x76@2x.png"

echo "Generating 83.5x83.5@2x..."
sips -z 167 167 "$SOURCE_ICON" --out "$IOS_ICONS_DIR/Icon-App-83.5x83.5@2x.png"

echo "Generating 1024x1024@1x..."
sips -z 1024 1024 "$SOURCE_ICON" --out "$IOS_ICONS_DIR/Icon-App-1024x1024@1x.png"

echo "iOS app icons updated successfully!"

# Generate Android app icons
echo "Generating Android app icon sizes..."

# Create the Android icons directories if they don't exist
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

echo "Android app icons updated successfully!"

echo "All app icons have been updated with AppIcon_doubledecker.png!"
echo "iOS icons saved to: $IOS_ICONS_DIR"
echo "Android icons saved to: $ANDROID_ICONS_DIR/mipmap-*"
