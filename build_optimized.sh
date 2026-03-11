#!/bin/bash

# Flutter APK Size Optimization Script
echo "🚀 Building optimized Flutter APK..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
fvm flutter clean
fvm flutter pub get

# Build for specific architectures to reduce size
echo "📱 Building ARM64 APK (modern devices)..."
fvm flutter build apk --target-platform android-arm64 --release --split-per-abi

echo "📱 Building ARM32 APK (older devices)..."
fvm flutter build apk --target-platform android-arm --release --split-per-abi

# Build universal APK for testing
echo "📱 Building universal APK..."
fvm flutter build apk --release

# Show APK sizes
echo "📊 APK Size Analysis:"
echo "ARM64 APK:"
ls -lh build/app/outputs/flutter-apk/app-arm64-v8a-release.apk 2>/dev/null || echo "ARM64 APK not found"
echo "ARM32 APK:"
ls -lh build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk 2>/dev/null || echo "ARM32 APK not found"
echo "Universal APK:"
ls -lh build/app/outputs/flutter-apk/app-release.apk 2>/dev/null || echo "Universal APK not found"

echo "✅ Build complete! Use split APKs for production to reduce download size."
