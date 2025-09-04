#!/bin/bash
set -e

# Install Flutter dependencies
flutter pub get

# Build the web app
flutter build web --release

echo "Build completed successfully!"
