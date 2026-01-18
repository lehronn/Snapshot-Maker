#!/bin/bash

set -e

APP_NAME="SnapshotMaker"
DMG_NAME="SnapshotMaker"
VERSION="1.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "💿 Creating DMG for ${APP_NAME}..."

# Check if app exists
if [ ! -d "${APP_NAME}.app" ]; then
    echo -e "${RED}❌ ${APP_NAME}.app not found!${NC}"
    echo "   Run ./build_app.sh first"
    exit 1
fi

# Clean previous DMG
rm -f ${DMG_NAME}.dmg
rm -rf dmg_temp

# Create temporary directory for DMG contents
echo "📁 Preparing DMG contents..."
mkdir -p dmg_temp

# Copy app to temp directory
echo "   Copying application..."
cp -r ${APP_NAME}.app dmg_temp/

# Create symbolic link to Applications folder
echo "   Creating Applications link..."
ln -s /Applications dmg_temp/Applications

# Copy README files
if [ -f "README.md" ]; then
    echo "   Copying README..."
    cp README.md dmg_temp/
fi

# Copy documentation files
if [ -f "DOCUMENTATION.md" ]; then
    cp DOCUMENTATION.md dmg_temp/
fi
if [ -f "DOCUMENTATION_PL.md" ]; then
    cp DOCUMENTATION_PL.md dmg_temp/
fi

# Create DMG
echo "🔨 Creating DMG image..."
hdiutil create -volname "${APP_NAME}" \
    -srcfolder dmg_temp \
    -ov -format UDZO \
    ${DMG_NAME}.dmg

# Clean up
echo "🧹 Cleaning up..."
rm -rf dmg_temp

echo -e "${GREEN}✅ DMG created successfully!${NC}"
echo ""
echo "📍 DMG file: ${DMG_NAME}.dmg"
echo ""
echo "Contents:"
echo "  - ${APP_NAME}.app"
echo "  - Applications (symlink)"
echo "  - README.md"
echo "  - DOCUMENTATION.md"
echo "  - DOCUMENTATION_PL.md"
