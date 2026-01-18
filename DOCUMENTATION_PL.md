# Snapshot Maker - Dokumentacja

## Czym jest Snapshot Maker?

Snapshot Maker to lekka aplikacja na macOS zaprojektowana do zarządzania migawkami (snapshot) maszyn wirtualnych QEMU. Zapewnia prosty, natywny interfejs do tworzenia, przywracania i usuwania migawek obrazów dysków wirtualnych maszyn.

Aplikacja współpracuje z:
- Samodzielnym obrazami dysków `.qcow2`
- Pakietami maszyn wirtualnych UTM (`.utm`)

## Jak to działa

Snapshot Maker skanuje wskazany katalog w poszukiwaniu obrazów maszyn wirtualnych i wyświetla je w hierarchicznej liście:

**Hierarchia:**
```
Pakiet UTM (.utm)
└── Obraz Dysku 1 (.qcow2)
│   ├── Migawka 1
│   ├── Migawka 2
│   └── Migawka 3
└── Obraz Dysku 2 (.qcow2)
    └── Migawki...
```

Dla każdego obrazu dysku możesz:
1. **Wyświetlić** wszystkie istniejące migawki z datami utworzenia
2. **Utworzyć** nowe migawki aby zapisać aktualny stan
3. **Przywrócić** poprzednią migawkę (przywraca dysk do tego stanu)
4. **Usunąć** niepotrzebne migawki aby zaoszczędzić miejsce

### Szczegóły Techniczne

Snapshot Maker używa `qemu-img` do wykonywania wszystkich operacji na migawkach:
- `qemu-img snapshot -l` - Listowanie migawek
- `qemu-img snapshot -c <nazwa>` - Tworzenie migawki
- `qemu-img snapshot -a <nazwa>` - Przywracanie migawki
- `qemu-img snapshot -d <nazwa>` - Usuwanie migawki

## Ograniczenia

1. **Tylko operacje na migawkach**: Ta aplikacja NIE uruchamia, nie zatrzymuje ani nie zarządza działającymi maszynami wirtualnymi. Użyj do tego UTM, QEMU CLI lub innych narzędzi.

2. **Tylko format qcow2**: Migawki są wspierane tylko dla formatu dysku qcow2. Surowe obrazy dysków (raw) nie wspierają migawek.

3. **Wymagane ręczne wyłączenie VM**: MUSISZ ręcznie upewnić się, że VM jest wyłączona przed wykonaniem operacji na migawkach (zobacz Ostrzeżenia poniżej).

4. **Brak udostępniania sieciowego**: Nie można zarządzać maszynami na zdalnych systemach; tylko lokalne obrazy dysków.

5. **Zakodowane ścieżki binarne**: Systemowy qemu-img jest oczekiwany w `/opt/homebrew/bin/qemu-img` (domyślna lokalizacja Homebrew na Apple Silicon).

## Krytyczne Ostrzeżenia

### ⚠️ NIGDY NIE UŻYWAJ MIGAWEK NA URUCHOMIONEJ MASZYNIE WIRTUALNEJ

**To najważniejsza zasada:**

- **NIE** twórz migawki gdy VM jest uruchomiona
- **NIE** przywracaj migawki gdy VM jest uruchomiona
- **NIE** usuwaj migawki gdy VM jest uruchomiona

**Dlaczego?** Gdy VM jest uruchomiona, obraz dysku jest aktywnie zapisywany. Tworzenie lub manipulowanie migawkami w tym czasie może spowodować:
- **Poważne uszkodzenie danych**
- **Utratę danych**
- **Nie-bootowalne maszyny wirtualne**
- **Niespójne systemy plików**

**Zawsze całkowicie wyłącz maszynę wirtualną przed użyciem tej aplikacji.**

## Instalacja

### Instalacja qemu-img (Zalecane)

Dla najlepszych rezultatów, zainstaluj QEMU przez Homebrew:

```bash
brew install qemu
```

To zapewnia najnowszą wersję `qemu-img`, którą aplikacja automatycznie wykryje i użyje.

### Używanie Wbudowanej Binarki

Jeśli nie masz zainstalowanego qemu-img, Snapshot Maker zawiera wbudowaną wersję. Jednak:
- Wbudowana wersja może być nieaktualna
- Zobaczysz ostrzeżenie w interfejsie
- Lepiej zainstalować wersję systemową przez Homebrew

Możesz sprawdzić której wersji używasz w Ustawienia → Ogólne → Status qemu-img.

## Budowanie Aplikacji

### Wymagania Wstępne

- macOS 13.0 lub nowszy (Ventura+)
- Xcode Command Line Tools: `xcode-select --install`
- Swift 5.9 lub nowszy (dołączony do Xcode CLT)

### Budowanie Skryptem (Zalecane)

Najłatwiejszy sposób budowania aplikacji:

```bash
cd snapshot-maker
./build_app.sh
```

Ten skrypt:
1. Zbuduje pakiet Swift w trybie release dla Apple Silicon
2. Utworzy strukturę pakietu `.app`
3. Skopiuje wszystkie zasoby (pliki lokalizacji, ikona, itp.)
4. Wbuduje binarkę qemu-img (jeśli obecna w `Resources/`)
5. Wygeneruje `Info.plist` z właściwą konfiguracją
6. Ustawi uprawnienia wykonywania

**Wynik**: `SnapshotMaker.app` w bieżącym katalogu

### Aktualizacja Binarki qemu-img

Aby pobrać i wbudować najnowszy qemu-img z Homebrew:

```bash
./build_app.sh --update-qemu
```

To:
1. Sprawdzi czy Homebrew qemu jest zainstalowany
2. Skopiuje binarkę qemu-img do `Resources/qemu-img`
3. Przebuduje aplikację z nową binarką

### Ręczny Proces Budowania

Jeśli chcesz budować ręcznie:

```bash
# Krok 1: Zbuduj plik wykonywalny
swift build -c release --arch arm64

# Krok 2: Utwórz katalogi pakietu aplikacji
mkdir -p SnapshotMaker.app/Contents/{MacOS,Resources}

# Krok 3: Skopiuj plik wykonywalny
cp .build/arm64-apple-macosx/release/SnapshotMaker \
   SnapshotMaker.app/Contents/MacOS/

# Krok 4: Skopiuj zasoby
cp AppIcon.png SnapshotMaker.app/Contents/Resources/
cp -r .build/arm64-apple-macosx/release/SnapshotMaker.resources/* \
      SnapshotMaker.app/Contents/Resources/

# Krok 5: Skopiuj qemu-img jeśli dostępny
if [ -f "Resources/qemu-img" ]; then
    cp Resources/qemu-img SnapshotMaker.app/Contents/MacOS/
    chmod +x SnapshotMaker.app/Contents/MacOS/qemu-img
fi

# Krok 6: Utwórz Info.plist
# (Zobacz build_app.sh dla pełnego szablonu)

# Krok 7: Ustaw uprawnienia
chmod +x SnapshotMaker.app/Contents/MacOS/SnapshotMaker
```

### Tworzenie DMG do Dystrybucji

Aby utworzyć plik DMG do dystrybucji:

```bash
./create_dmg.sh
```

To tworzy `SnapshotMaker.dmg` zawierający:
- Pakiet aplikacji
- Symboliczny link do `/Applications` dla łatwej instalacji
- Pliki README (angielski i polski)
- Pliki dokumentacji

## Tworzenie Tłumaczeń

Snapshot Maker wspiera wiele języków przez pliki `.strings`. Oto jak dodać lub zmodyfikować tłumaczenia:

### Struktura Plików Tłumaczeń

Pliki tłumaczeń znajdują się w:
```
Sources/Localization/[język].lproj/Localizable.strings
```

Gdzie `[język]` to kod języka:
- `en` - Angielski
- `pl` - Polski
- `de` - Niemiecki
- `fr` - Francuski

### Format Pliku

Każda linia ma format:
```
"klucz_tekstu" = "Przetłumaczony tekst";
```

Przykład:
```
"welcome_title" = "Witamy w Snapshot Maker";
"create_snapshot" = "Utwórz migawkę";
"error_title" = "Błąd";
```

### Dodawanie Nowego Języka

1. Utwórz nowy katalog: `Sources/Localization/es.lproj/` (dla hiszpańskiego, itp.)
2. Skopiuj `en.lproj/Localizable.strings` do nowego katalogu
3. Przetłumacz wszystkie ciągi tekstowe
4. Dodaj język do wyboru języka w `SettingsView.swift`
5. Dodaj tłumaczenia dla nazwy języka we wszystkich istniejących plikach językowych
6. Przebuduj aplikację

### Testowanie Tłumaczeń

1. Zbuduj aplikację z nowymi tłumaczeniami
2. Idź do Ustawienia → Wygląd → Język
3. Wybierz swój język z listy rozwijanej
4. Interfejs powinien natychmiast się zaktualizować

## Funkcje Skryptów Budowania

### build_app.sh

**Podstawowe użycie:**
```bash
./build_app.sh
```

**Z aktualizacją qemu-img:**
```bash
./build_app.sh --update-qemu
```

**Co robi:**
1. Sprawdza kompilator Swift
2. Opcjonalnie aktualizuje binarkę qemu-img z Homebrew
3. Buduje pakiet Swift w trybie release dla arm64
4. Tworzy strukturę pakietu .app
5. Kopiuje plik wykonywalny i wszystkie zasoby
6. Wbudowuje qemu-img jeśli dostępny
7. Tworzy Info.plist z informacjami o wersji
8. Ustawia właściwe uprawnienia plików
9. Raportuje sukces i lokalizację pliku .app

### create_dmg.sh

**Użycie:**
```bash
./create_dmg.sh
```

**Co robi:**
1. Sprawdza czy SnapshotMaker.app istnieje
2. Tworzy tymczasowy katalog dla zawartości DMG
3. Kopiuje pakiet .app
4. Tworzy symboliczny link do /Applications
5. Kopiuje pliki README i dokumentacji
6. Używa `hdiutil` do utworzenia skompresowanego DMG
7. Czyści pliki tymczasowe

## Wsparcie i Kontrybucje

- **Problemy**: Zgłaszaj błędy przez GitHub issues
- **Tłumaczenia**: Mile widziane kontrybucje poprawiające tłumaczenia niemieckie/francuskie
- **Kod**: Akceptowane pull requesty

## Licencja

MIT License - Darmowe i otwartoźródłowe

## Autor

Stworzony przez Mateusz Stomski (mateusz.stomski@gmail.com) przy pomocy AI.

**Zastrzeżenie**: To oprogramowanie jest dostarczane "tak jak jest" bez gwarancji. Nie przeznaczone do użytku produkcyjnego. Używasz na własne ryzyko.
