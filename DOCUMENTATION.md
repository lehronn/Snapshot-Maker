# Snapshot Maker - Documentation

## What is Snapshot Maker?

Snapshot Maker is a lightweight macOS application designed to manage QEMU virtual machine snapshots. It provides a simple, native interface for creating, restoring, and deleting snapshots of your virtual machine disk images.

The application works with:
- Standalone `.qcow2` disk images
- UTM virtual machine packages (`.utm`)

## How It Works

Snapshot Maker scans a specified directory for virtual machine images and displays them in a hierarchical list:

**Hierarchy:**
```
UTM Package (.utm)
└── Disk Image 1 (.qcow2)
│   ├── Snapshot 1
│   ├── Snapshot 2
│   └── Snapshot 3
└── Disk Image 2 (.qcow2)
    └── Snapshots...
```

For each disk image, you can:
1. **View** all existing snapshots with creation dates
2. **Create** new snapshots to save the current state
3. **Restore** to a previous snapshot (reverts disk to that state)
4. **Delete** unwanted snapshots to save space

### Technical Details

Snapshot Maker uses `qemu-img` under the hood to perform all snapshot operations:
- `qemu-img snapshot -l` - List snapshots
- `qemu-img snapshot -c <name>` - Create snapshot
- `qemu-img snapshot -a <name>` - Apply/restore snapshot
- `qemu-img snapshot -d <name>` - Delete snapshot

## Limitations

1. **Snapshot operations only**: This application does NOT start, stop, or manage running VMs. Use UTM, QEMU CLI, or other tools for that.

2. **qcow2 format only**: Snapshots are only supported for qcow2 disk format. Raw disk images do not support snapshots.

3. **Manual VM shutdown required**: You MUST manually ensure the VM is shut down before performing snapshot operations (see Warnings below).

4. **No network sharing**: Cannot manage VMs on remote systems; only local disk images.

5. **Hardcoded binary paths**: The system qemu-img is expected at `/opt/homebrew/bin/qemu-img` (default Homebrew location on Apple Silicon).

## Critical Warnings

### ⚠️ NEVER USE SNAPSHOTS ON A RUNNING VM

**This is the most important rule:**

- **DO NOT** create a snapshot while the VM is running
- **DO NOT** restore a snapshot while the VM is running  
- **DO NOT** delete a snapshot while the VM is running

**Why?** When a VM is running, the disk image is actively being written to. Creating or manipulating snapshots during this time can cause:
- **Severe data corruption**
- **Loss of data**
- **Unbootable virtual machines**
- **Inconsistent file systems**

**Always shut down the virtual machine completely before using this application.**

## Installation

### Installing qemu-img (Recommended)

For best results, install QEMU via Homebrew:

```bash
brew install qemu
```

This provides the latest version of `qemu-img` which the application will automatically detect and use.

### Using Embedded Binary

If you don't have qemu-img installed, Snapshot Maker includes an embedded version. However:
- The embedded version may be outdated
- You'll see a warning in the UI
- It's better to install the system version via Homebrew

You can check which version you're using in Settings → General → qemu-img Status.

## Building the Application

### Prerequisites

- macOS 13.0 or later (Ventura+)
- Xcode Command Line Tools: `xcode-select --install`
- Swift 5.9 or later (included with Xcode CLT)

### Build with Script (Recommended)

The easiest way to build the application:

```bash
cd snapshot-maker
./build_app.sh
```

This script will:
1. Build the Swift package in release mode for Apple Silicon
2. Create the `.app` bundle structure
3. Copy all resources (localization files, icon, etc.)
4. Embed the qemu-img binary (if present in `Resources/`)
5. Generate `Info.plist` with proper configuration
6. Set executable permissions

**Output**: `SnapshotMaker.app` in the current directory

### Updating qemu-img Binary

To download and embed the latest qemu-img from Homebrew:

```bash
./build_app.sh --update-qemu
```

This will:
1. Check if Homebrew qemu is installed
2. Copy the qemu-img binary to `Resources/qemu-img`
3. Rebuild the application with the new binary

### Manual Build Process

If you want to build manually:

```bash
# Step 1: Build the executable
swift build -c release --arch arm64

# Step 2: Create app bundle directories
mkdir -p SnapshotMaker.app/Contents/{MacOS,Resources}

# Step 3: Copy the executable
cp .build/arm64-apple-macosx/release/SnapshotMaker \
   SnapshotMaker.app/Contents/MacOS/

# Step 4: Copy resources
cp AppIcon.png SnapshotMaker.app/Contents/Resources/
cp -r .build/arm64-apple-macosx/release/SnapshotMaker.resources/* \
      SnapshotMaker.app/Contents/Resources/

# Step 5: Copy qemu-img if available
if [ -f "Resources/qemu-img" ]; then
    cp Resources/qemu-img SnapshotMaker.app/Contents/MacOS/
    chmod +x SnapshotMaker.app/Contents/MacOS/qemu-img
fi

# Step 6: Create Info.plist
cat > SnapshotMaker.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
   "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Snapshot Maker</string>
    <key>CFBundleExecutable</key>
    <string>SnapshotMaker</string>
    <key>CFBundleIdentifier</key>
    <string>com.stomski.snapshotmaker</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Step 7: Set permissions
chmod +x SnapshotMaker.app/Contents/MacOS/SnapshotMaker
```

### Creating a DMG Distribution

To create a distributable DMG file:

```bash
./create_dmg.sh
```

This creates `SnapshotMaker.dmg` containing:
- The application bundle
- A symbolic link to `/Applications` for easy installation
- README files (English and Polish)
- Documentation files

## Creating Translations

Snapshot Maker supports multiple languages through `.strings` files. Here's how to add or modify translations:

### Translation File Structure

Translation files are located at:
```
Sources/Localization/[lang].lproj/Localizable.strings
```

Where `[lang]` is the language code:
- `en` - English
- `pl` - Polish
- `de` - German
- `fr` - French

### File Format

Each line has the format:
```
"string_key" = "Translated text";
```

Example:
```
"welcome_title" = "Welcome to Snapshot Maker";
"create_snapshot" = "Create Snapshot";
"error_title" = "Error";
```

### Adding a New Language

1. Create new directory: `Sources/Localization/es.lproj/` (for Spanish, etc.)
2. Copy `en.lproj/Localizable.strings` to the new directory
3. Translate all strings
4. Add the language to `SettingsView.swift` language picker
5. Add translations for the language name itself in all existing language files
6. Rebuild the application

### Testing Translations

1. Build the app with your new translations
2. Go to Settings → Appearance → Language
3. Select your language from the dropdown
4. The UI should immediately update

## Build Script Functions

### build_app.sh

**Basic usage:**
```bash
./build_app.sh
```

**With qemu-img update:**
```bash
./build_app.sh --update-qemu
```

**What it does:**
1. Checks for Swift compiler
2. Optionally updates qemu-img binary from Homebrew
3. Builds Swift package in release mode for arm64
4. Creates .app bundle structure
5. Copies executable and all resources
6. Embeds qemu-img if available
7. Creates Info.plist with version info
8. Sets proper file permissions
9. Reports success and location of .app file

### create_dmg.sh

**Usage:**
```bash
./create_dmg.sh
```

**What it does:**
1. Checks that SnapshotMaker.app exists
2. Creates a temporary directory for DMG contents
3. Copies the .app bundle
4. Creates symbolic link to /Applications
5. Copies README and documentation files
6. Uses `hdiutil` to create compressed DMG
7. Cleans up temporary files

## Support & Contributing

- **Issues**: Report bugs via GitHub issues
- **Translations**: Contributions for improving German/French translations welcome
- **Code**: Pull requests accepted

## License

MIT License - Free and open source

## Author

Created by Mateusz Stomski (mateusz.stomski@gmail.com) with AI assistance.

**Disclaimer**: This software is provided "as is" without warranty. Not intended for production use. Use at your own risk.
