#!/bin/bash

# build_for_appstore.sh
# Script to properly build the Flutter app for App Store submission
# This ensures the correct release configuration is used

set -e  # Exit on any error

echo "🚀 Building WheresMyBus for App Store submission..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Set environment variable to force release mode in Flutter backend script
export FLUTTER_BUILD_MODE=release

# Build for iOS release
echo "🔨 Building Flutter for iOS release..."
flutter build ios --release --no-codesign

echo "✅ Flutter build completed successfully!"
echo ""
echo "📱 Next steps:"
echo "1. Open ios/Runner.xcworkspace in Xcode"
echo "2. Select 'Runner' scheme"
echo "3. Select 'Any iOS Device (arm64)' as destination"
echo "4. Product > Archive"
echo "5. Upload to App Store Connect"
echo ""
echo "⚠️  Important: Make sure to use the 'Archive' action in Xcode, not 'Build'"
echo "    The Archive action uses the Release configuration automatically."
echo ""
echo "🔧 Note: FLUTTER_BUILD_MODE=release has been set to fix build script issues."
