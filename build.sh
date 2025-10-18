#!/bin/bash

# CameraBoost Build Script
# For iOS 15+ Dopamine rootless jailbreak

echo "Building CameraBoost for iOS 15+..."

# Check if Theos is installed
if [ ! -d "$THEOS" ]; then
    echo "Error: Theos not found. Please install Theos first."
    echo "Visit: https://theos.dev/docs/installation"
    exit 1
fi

# Clean previous builds
echo "Cleaning previous builds..."
make clean

# Build the package
echo "Building package..."
make package

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo "Package location: $(find . -name "*.deb" -type f | head -1)"
    echo ""
    echo "Installation instructions:"
    echo "1. Transfer the .deb file to your device"
    echo "2. Install using your preferred package manager"
    echo "3. Respring your device"
    echo "4. Configure settings in Settings > CameraBoost"
else
    echo "Build failed!"
    exit 1
fi
