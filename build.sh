#!/bin/bash
set -e

# Install Flutter using the official installation script
echo "Installing Flutter..."
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
tar xf flutter_linux_3.24.5-stable.tar.xz
export PATH="$PATH:`pwd`/flutter/bin"

# Verify Flutter installation
echo "Verifying Flutter installation..."
flutter doctor --android-licenses || true
flutter config --enable-web

# Install Flutter dependencies
echo "Installing dependencies..."
flutter pub get

# Build the web app
echo "Building web app..."
flutter build web --release

echo "Build completed successfully!"
