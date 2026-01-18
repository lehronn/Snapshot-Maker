#!/bin/bash

set -e

APP_NAME="SnapshotMaker"
BUNDLE_ID="com.stomski.snapshotmaker"
VERSION="1.0"
MIN_MACOS="13.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔨 Building ${APP_NAME}..."

# Check if --update-qemu flag is present
UPDATE_QEMU=false
if [[ "$1" == "--update-qemu" ]]; then
    UPDATE_QEMU=true
    echo "📥 Will update qemu-img binary from Homebrew"
fi

# Function to update qemu-img
update_qemu() {
    echo "📦 Updating qemu-img binary..."
    
    # Check if Homebrew qemu is installed
    if ! command -v /opt/homebrew/bin/qemu-img &> /dev/null; then
        echo -e "${RED}❌ /opt/homebrew/bin/qemu-img not found!${NC}"
        echo "   Install with: brew install qemu"
        exit 1
    fi
    
    # Create Resources directory if it doesn't exist
    mkdir -p Resources
    
    # Copy qemu-img binary
    echo "   Copying qemu-img from Homebrew..."
    cp /opt/homebrew/bin/qemu-img Resources/qemu-img
    chmod +x Resources/qemu-img
    
    # Get version
    QEMU_VERSION=$(Resources/qemu-img --version | head -n 1)
    echo -e "${GREEN}✅ qemu-img updated: ${QEMU_VERSION}${NC}"
}

# Update qemu-img if requested
if [ "$UPDATE_QEMU" = true ]; then
    update_qemu
fi

# Check if Swift is available
if ! command -v swift &> /dev/null; then
    echo -e "${RED}❌ Swift compiler not found!${NC}"
    echo "   Install Xcode Command Line Tools: xcode-select --install"
    exit 1
fi

# Clean previous build
echo "🧹 Cleaning previous build..."
rm -rf .build
rm -rf ${APP_NAME}.app

# Build the Swift package for Apple Silicon
echo "⚙️  Compiling Swift package (release mode, arm64)..."
swift build -c release --arch arm64

# Create app bundle structure
echo "📦 Creating app bundle..."
mkdir -p ${APP_NAME}.app/Contents/{MacOS,Resources}

# Copy executable
echo "   Copying executable..."
cp .build/arm64-apple-macosx/release/${APP_NAME} ${APP_NAME}.app/Contents/MacOS/
chmod +x ${APP_NAME}.app/Contents/MacOS/${APP_NAME}

# Copy resources (localization files)
echo "   Copying resources..."
if [ -d ".build/arm64-apple-macosx/release/SnapshotMaker_SnapshotMaker.bundle" ]; then
    cp -r .build/arm64-apple-macosx/release/SnapshotMaker_SnapshotMaker.bundle ${APP_NAME}.app/Contents/Resources/
fi

# Copy app icon
if [ -f "AppIcon.png" ]; then
    echo "   Copying app icon..."
    cp AppIcon.png ${APP_NAME}.app/Contents/Resources/
fi

# Copy documentation files for in-app help
if [ -f "DOCUMENTATION.md" ]; then
    cp DOCUMENTATION.md ${APP_NAME}.app/Contents/Resources/
fi
if [ -f "DOCUMENTATION_PL.md" ]; then
    cp DOCUMENTATION_PL.md ${APP_NAME}.app/Contents/Resources/
fi

# Copy embedded qemu-img if available
if [ -f "Resources/qemu-img" ]; then
    echo "   Embedding qemu-img binary..."
    cp Resources/qemu-img ${APP_NAME}.app/Contents/MacOS/qemu-img
    chmod +x ${APP_NAME}.app/Contents/MacOS/qemu-img
    echo -e "${YELLOW}   ⚠️  Using embedded qemu-img${NC}"
else
    echo -e "${YELLOW}   ⚠️  No embedded qemu-img found (will use system binary if available)${NC}"
    echo "      Run './build_app.sh --update-qemu' to embed latest version"
fi

# Create Info.plist
echo "   Creating Info.plist..."
cat > ${APP_NAME}.app/Contents/Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Snapshot Maker</string>
    <key>CFBundleDisplayName</key>
    <string>Snapshot Maker</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>${MIN_MACOS}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 Mateusz Stomski. MIT License.</string>
</dict>
</plist>
EOF

echo -e "${GREEN}✅ Build complete!${NC}"
echo ""
echo "📍 Application created at: ${APP_NAME}.app"
echo ""
echo "To install: mv ${APP_NAME}.app /Applications/"
echo "To create DMG: ./create_dmg.sh"
