# Snapshot Maker

**Snapshot Maker** is a lightweight, native macOS application (optimized for Apple Silicon) that provides an easy-to-use interface for managing QEMU virtual machine snapshots. It supports both `.qcow2` disk images and UTM virtual machines.

---

## 🇬🇧 English Documentation

### Features

- **Hierarchical VM List**: Displays `.utm` packages with their contained disk images in an expandable tree view
- **Snapshot Management** via `qemu-img`:
  - List all snapshots
  - Create new snapshots
  - Restore to any snapshot
  - Delete snapshots
- **UTM Integration**:
  - Automatically detects `.utm` packages
  - Shows all `.qcow2` disks within UTM VMs
  - Built-in `config.plist` viewer with export functionality
- **Multi-language Support**: English, Polish, German, and French (auto-detection with manual override)
- **Appearance Settings**: Light, Dark, and System modes
- **qemu-img Integration**: Uses system binary if available, falls back to embedded version
- **Minimalist Design**: Focused purely on snapshot management functionality

### Important Warnings

⚠️ **CRITICAL**: Never create, restore, or delete snapshots while a virtual machine is running! This may cause severe data corruption. Always shut down the VM before performing snapshot operations.

### Requirements & Dependencies

- **Hardware**: macOS on Apple Silicon (M1/M2/M3/M4)
- **OS**: macOS 13.0 (Ventura) or later
- **Dependencies**:
  - **QEMU**: Recommended to install via Homebrew for latest version: `brew install qemu`
  - If not installed, the application will use an embedded `qemu-img` binary (may be outdated)

### Installation

#### Option 1: Download DMG (Recommended)
1. Download the latest `SnapshotMaker.dmg` from releases
2. Open the DMG and drag `Snapshot Maker.app` to Applications
3. Launch from Applications folder

#### Option 2: Build from Source
See "Building" section below.

### Usage

1. Launch Snapshot Maker
2. Configure scan path in Settings (default: `~/Library/Containers/`)
3. Click "Scan" to find VMs
4. Select a VM from the sidebar
5. For UTM VMs, select a specific disk from the disk list
6. View, create, restore, or delete snapshots in the snapshot panel

### Building

#### Prerequisites
- Xcode Command Line Tools: `xcode-select --install`
- Swift 5.9 or later

#### Build with Script (Recommended)
```bash
cd snapshot-maker
./build_app.sh
```

This will create `SnapshotMaker.app` in the current directory.

#### Update qemu-img Binary
To download and embed the latest qemu-img:
```bash
./build_app.sh --update-qemu
```

#### Manual Build
```bash
# Build the executable
swift build -c release --arch arm64

# Create app bundle structure
mkdir -p SnapshotMaker.app/Contents/MacOS
mkdir -p SnapshotMaker.app/Contents/Resources

# Copy binary
cp .build/arm64-apple-macosx/release/SnapshotMaker SnapshotMaker.app/Contents/MacOS/

# Copy resources (icon, localization files, etc.)
cp AppIcon.png SnapshotMaker.app/Contents/Resources/
cp -r .build/arm64-apple-macosx/release/SnapshotMaker.resources/* SnapshotMaker.app/Contents/Resources/

# Create Info.plist
# (See build_app.sh for full Info.plist template)
```

#### Create DMG
```bash
./create_dmg.sh
```

This creates `SnapshotMaker.dmg` with:
- Application bundle
- Symbolic link to Applications folder
- README files
- Documentation files

### Translations

The application supports four languages:
- **English** (en)
- **Polish** (pl)
- **German** (de)
- **French** (fr)

To add or modify translations, edit the files in `Sources/Localization/[lang].lproj/Localizable.strings`.

Each translation file uses the format:
```
"key" = "Translated text";
```

After modifying translations, rebuild the application.

### License

MIT License - see LICENSE file for details.

### AI Disclosure

This application was developed with the assistance of Artificial Intelligence. While efforts have been made to ensure functionality and safety, it may contain errors. **This software is not intended for use in production environments.** The author is not responsible for any issues arising from its use.

---

## 🇵🇱 Polska Dokumentacja

### Funkcjonalność

**Snapshot Maker** to natywna, lekka aplikacja na macOS (zoptymalizowana dla Apple Silicon), będąca graficznym interfejsem dla `qemu-img`. Umożliwia zarządzanie migawkami (snapshots) obrazów maszyn wirtualnych.

**Główne Funkcje:**
- **Lista hierarchiczna**: Pakiety `.utm` wyświetlane jako rozwijane elementy z zawartymi obrazami dysków
- **Zarządzanie migawkami** przez `qemu-img`:
  - Listowanie migawek
  - Tworzenie nowych migawek
  - Przywracanie migawek
  - Usuwanie migawek
- **Integracja z UTM**: Automatyczne wykrywanie pakietów `.utm` i wyświetlanie dysków `.qcow2`
- **Wsparcie wielojęzyczne**: Polski, angielski, niemiecki i francuski
- **Ustawienia wyglądu**: Tryby jasny, ciemny i systemowy

### Ważne Ostrzeżenia

⚠️ **UWAGA**: Nigdy nie twórz, nie przywracaj ani nie usuwaj migawek gdy maszyna wirtualna jest uruchomiona! Może to spowodować poważne uszkodzenie danych.

### Wymagania

- **Sprzęt**: macOS na Apple Silicon (M1/M2/M3/M4)
- **System**: macOS 13.0 (Ventura) lub nowszy
- **Zależności**: QEMU (zalecana instalacja: `brew install qemu`)

### Budowanie

Szczegółowe instrukcje budowania w sekcji angielskiej powyżej.

```bash
# Budowanie aplikacji
./build_app.sh

# Aktualizacja qemu-img do najnowszej wersji
./build_app.sh --update-qemu

# Tworzenie DMG
./create_dmg.sh
```

### Tłumaczenia

Aby dodać lub zmodyfikować tłumaczenia, edytuj pliki w `Sources/Localization/[lang].lproj/Localizable.strings`.

### Licencja

MIT License

### Zastrzeżenie

Program stworzony przy pomocy Sztucznej Inteligencji. Nie jest przeznaczony do użytku produkcyjnego. Autor nie odpowiada za błędy i problemy wynikające z użytkowania.
