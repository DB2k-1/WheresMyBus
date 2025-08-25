#!/bin/bash

# Generate comprehensive launch icons for iOS and Android
# This script creates all required icon sizes from AppIcon_doubledecker.png

SOURCE_ICON="assets/images/AppIcon_doubledecker.png"
IOS_ICONS_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"
ANDROID_ICONS_DIR="android/app/src/main/res"

echo "Generating comprehensive launch icons for iOS and Android..."
echo "Source image: $SOURCE_ICON"

# Create directories
mkdir -p "$IOS_ICONS_DIR"
mkdir -p "$ANDROID_ICONS_DIR/mipmap-mdpi"
mkdir -p "$ANDROID_ICONS_DIR/mipmap-hdpi"
mkdir -p "$ANDROID_ICONS_DIR/mipmap-xhdpi"
mkdir -p "$ANDROID_ICONS_DIR/mipmap-xxhdpi"
mkdir -p "$ANDROID_ICONS_DIR/mipmap-xxxhdpi"

echo ""
echo "=== Generating iOS Launch Icons ==="

# iOS App Icons (all required sizes)
echo "Generating iOS icons..."

# iPhone icons
sips -z 20 20 "$SOURCE_ICON" --out "$IOS_ICONS_DIR/Icon-App-20x20@1x.png"
sips -z 40 40 "$SOURCE_ICON" --out "$IOS_ICONS_DIR/Icon-App-20x20@2x.png"
sips -z 60 60 "$SOURCE_ICON" --out "$IOS_ICONS_DIR/Icon-App-20x20@3x.png"

sips -z 29 29 "$SOURCE_ICON" --out "$IOS_ICONS_DIR/Icon-App-29x29@1x.png"
sips -z 58 58 "$SOURCE_ICON" --out "$IOS_ICONS_DIR/Icon-App-29x29@2x.png"
sips -z 87 87 "$SOURCE_ICON" --out "$IOS_ICONS_DIR/Icon-App-29x29@3x.png"

sips -z 40 40 "$SOURCE_ICON" --out "$IOS_ICONS_DIR/Icon-App-40x40@1x.png"
sips -z 80 80 "$SOURCE_ICON" --out "$IOS_ICONS_DIR/Icon-App-40x40@2x.png"
sips -z 120 120 "$SOURCE_ICON" --out "$IOS_ICONS_DIR/Icon-App-40x40@3x.png"

sips -z 120 120 "$SOURCE_ICON" --out "$IOS_ICONS_DIR/Icon-App-60x60@2x.png"
sips -z 180 180 "$SOURCE_ICON" --out "$IOS_ICONS_DIR/Icon-App-60x60@3x.png"

# iPad icons
sips -z 76 76 "$SOURCE_ICON" --out "$IOS_ICONS_DIR/Icon-App-76x76@1x.png"
sips -z 152 152 "$SOURCE_ICON" --out "$IOS_ICONS_DIR/Icon-App-76x76@2x.png"

# iPad Pro
sips -z 167 167 "$SOURCE_ICON" --out "$IOS_ICONS_DIR/Icon-App-83.5x83.5@2x.png"

# App Store
sips -z 1024 1024 "$SOURCE_ICON" --out "$IOS_ICONS_DIR/Icon-App-1024x1024@1x.png"

echo "iOS icons generated successfully!"

echo ""
echo "=== Generating Android Launch Icons ==="

# Android App Icons (all density variants)
echo "Generating Android icons..."

# Different densities
sips -z 48 48 "$SOURCE_ICON" --out "$ANDROID_ICONS_DIR/mipmap-mdpi/ic_launcher.png"
sips -z 72 72 "$SOURCE_ICON" --out "$ANDROID_ICONS_DIR/mipmap-hdpi/ic_launcher.png"
sips -z 96 96 "$SOURCE_ICON" --out "$ANDROID_ICONS_DIR/mipmap-xhdpi/ic_launcher.png"
sips -z 144 144 "$SOURCE_ICON" --out "$ANDROID_ICONS_DIR/mipmap-xxhdpi/ic_launcher.png"
sips -z 192 192 "$SOURCE_ICON" --out "$ANDROID_ICONS_DIR/mipmap-xxxhdpi/ic_launcher.png"

# Adaptive icons for modern Android (API 26+)
# Background layer (solid color)
sips -z 108 108 "$SOURCE_ICON" --out "$ANDROID_ICONS_DIR/mipmap-mdpi/ic_launcher_background.png"
sips -z 162 162 "$SOURCE_ICON" --out "$ANDROID_ICONS_DIR/mipmap-hdpi/ic_launcher_background.png"
sips -z 216 216 "$SOURCE_ICON" --out "$ANDROID_ICONS_DIR/mipmap-xhdpi/ic_launcher_background.png"
sips -z 324 324 "$SOURCE_ICON" --out "$ANDROID_ICONS_DIR/mipmap-xxhdpi/ic_launcher_background.png"
sips -z 432 432 "$SOURCE_ICON" --out "$ANDROID_ICONS_DIR/mipmap-xxxhdpi/ic_launcher_background.png"

# Foreground layer (icon with transparency)
sips -z 108 108 "$SOURCE_ICON" --out "$ANDROID_ICONS_DIR/mipmap-mdpi/ic_launcher_foreground.png"
sips -z 162 162 "$SOURCE_ICON" --out "$ANDROID_ICONS_DIR/mipmap-hdpi/ic_launcher_foreground.png"
sips -z 216 216 "$SOURCE_ICON" --out "$ANDROID_ICONS_DIR/mipmap-xhdpi/ic_launcher_foreground.png"
sips -z 324 324 "$SOURCE_ICON" --out "$ANDROID_ICONS_DIR/mipmap-xxhdpi/ic_launcher_foreground.png"
sips -z 432 432 "$SOURCE_ICON" --out "$ANDROID_ICONS_DIR/mipmap-xxxhdpi/ic_launcher_foreground.png"

echo "Android icons generated successfully!"

echo ""
echo "=== Creating iOS Contents.json ==="

# Create iOS Contents.json file
cat > "$IOS_ICONS_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "Icon-App-20x20@1x.png",
      "idiom" : "iphone",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-20x20@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-20x20@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-29x29@1x.png",
      "idiom" : "iphone",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-29x29@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-29x29@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-40x40@1x.png",
      "idiom" : "iphone",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-40x40@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-40x40@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-60x60@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "filename" : "Icon-App-60x60@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "filename" : "Icon-App-76x76@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "76x76"
    },
    {
      "filename" : "Icon-App-76x76@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "filename" : "Icon-App-83.5x83.5@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "filename" : "Icon-App-1024x1024@1x.png",
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo "iOS Contents.json created successfully!"

echo ""
echo "=== Summary ==="
echo "✅ iOS Launch Icons: $IOS_ICONS_DIR"
echo "✅ Android Launch Icons: $ANDROID_ICONS_DIR/mipmap-*"
echo "✅ Total iOS Icons: 15 files"
echo "✅ Total Android Icons: 15 files (including adaptive icons)"
echo ""
echo "🎉 All launch icons generated successfully!"
echo ""
echo "Next steps:"
echo "1. Clean and rebuild your app"
echo "2. Test on both iOS and Android devices"
echo "3. Icons will appear on home screen and app switcher"
