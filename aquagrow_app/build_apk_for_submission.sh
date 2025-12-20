#!/bin/bash

# Build Optimized APK for Submission
# This script creates a small, optimized APK file ready for upload

echo "🧹 Cleaning previous builds..."
flutter clean

echo "🔨 Building optimized split APK (ARM64 - works on 99% of devices)..."
flutter build apk --split-per-abi --release

echo "📦 Copying APK to Desktop..."
cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk ~/Desktop/Mazen_Saeed.apk

echo "✅ APK created successfully!"
echo ""
echo "📊 APK Details:"
ls -lh ~/Desktop/Mazen_Saeed.apk

echo ""
echo "📝 Next steps:"
echo "1. Compress the APK: zip Mazen_Saeed.zip ~/Desktop/Mazen_Saeed.apk"
echo "2. The ZIP file will be ~40-50MB (well under 900MB limit!)"
echo ""
echo "🎯 Location: ~/Desktop/Mazen_Saeed.apk"
