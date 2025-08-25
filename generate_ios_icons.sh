#!/bin/bash

# Generate iOS app icon sizes from wheresmybus_appicon.png
# This script uses the macOS sips command to resize images

SOURCE_ICON="assets/images/wheresmybus_appicon.png"
IOS_ICONS_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"

echo "Generating iOS app icon sizes..."

# Create the icons directory if it doesn't exist
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

echo "iOS app icons generated successfully!"
echo "Icons saved to: $IOS_ICONS_DIR"
