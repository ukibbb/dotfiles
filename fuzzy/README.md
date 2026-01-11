# Project Launcher

Narzędzie do szybkiego uruchamiania środowisk programistycznych na macOS z możliwością wyboru projektu (fuzzy finder) i trybu uruchomienia (terminal, tmux, neovim, claude code).

## Funkcjonalności

- **Wybór projektu**: Fuzzy search (fzf) po wszystkich folderach w systemie z konfigurowalnymi wykluczeniami
- **Wybór trybu**: Natywne macOS GUI z 5 trybami uruchomienia
- **Nazwane sesje tmux**: Automatyczne reattach do istniejących sesji
- **Dual trigger**: Uruchamianie z CLI lub globalnym skrótem klawiszowym (Hammerspoon)
- **Konfigurowalne wykluczenia**: YAML config z listą folderów do pominięcia

## Tryby uruchomienia

1. **Terminal (Ghostty)** - Tylko terminal w wybranym katalogu
2. **Terminal + Tmux** - Terminal z uruchomionym tmux (bez nazwanej sesji)
3. **Tmux Session** - Nazwana sesja tmux z możliwością reattach
4. **Tmux + Neovim** - Sesja tmux z automatycznie uruchomionym Neovim
5. **Tmux + Neovim + Claude Code** - Sesja z dwoma oknami: Neovim + Claude Code

## Wymagania

### Wymagane

- **macOS** (testowane na macOS Sonoma+)
- **fzf** - Fuzzy finder do wyboru projektów
  ```bash
  brew install fzf
  ```
- **Swift compiler** - Do kompilacji GUI (Xcode Command Line Tools)
  ```bash
  xcode-select --install
  ```
- **Ghostty** - Terminal
  ```
  Pobierz z: https://ghostty.org/
  ```

### Opcjonalne (zalecane)

- **tmux** - Dla trybów z sesją tmux
  ```bash
  brew install tmux
  ```
- **fd** - Szybsza alternatywa dla find
  ```bash
  brew install fd
  ```
- **yq** - Parser YAML (ułatwia parsowanie config.yaml)
  ```bash
  brew install yq
  ```
- **Hammerspoon** - Dla globalnego skrótu klawiszowego
  ```bash
  brew install --cask hammerspoon
  ```

## Instalacja

1. **Sklonuj/pobierz projekt**:
   ```bash
   cd ~/Desktop/dotfiles/fuzzy
   ```

2. **Uruchom instalator**:
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

   Instalator:
   - Sprawdzi zależności
   - Skompiluje Swift GUI (mode-selector)
   - Ustawi uprawnienia wykonywania
   - Utworzy config.yaml z przykładowej konfiguracji
   - Opcjonalnie doda launcher do PATH
   - Pomoże skonfigurować Hammerspoon

3. **Gotowe!** Możesz teraz uruchomić:
   ```bash
   ./launcher
   # lub (jeśli dodałeś do PATH)
   project-launcher
   ```

## Konfiguracja

### config.yaml

Edytuj `config.yaml` aby dostosować wykluczenia i ustawienia:

```yaml
excluded_dirs:
  - Library
  - Applications
  - .Trash
  - "*/node_modules"
  - "*/.git"
  # Dodaj własne wykluczenia...

search:
  max_depth: null          # null = bez limitu głębokości
  follow_symlinks: false   # Czy podążać za symlinkami

tmux:
  session_prefix: "proj"   # Prefix dla nazw sesji (opcjonalny)
```

### Hammerspoon (globalny skrót klawiszowy)

Aby używać **Cmd+Shift+P** do uruchamiania launcher:

1. Zainstaluj Hammerspoon:
   ```bash
   brew install --cask hammerspoon
   ```

2. Dodaj konfigurację do `~/.hammerspoon/init.lua`:
   ```bash
   cat hammerspoon-init.lua >> ~/.hammerspoon/init.lua
   ```

   LUB skopiuj ręcznie zawartość z `hammerspoon-init.lua`

3. Uruchom Hammerspoon (ikona pojawi się w menu bar)

4. Reload config: **Cmd+Ctrl+R** (lub przez menu Hammerspoon)

**UWAGA**: Hammerspoon musi być uruchomiony w tle aby skrót działał!

## Użycie

### Z linii komend

```bash
# Interaktywny tryb - wybierz projekt i tryb
./launcher

# lub (jeśli w PATH)
project-launcher

# Bezpośrednio dla konkretnego projektu
./launcher /path/to/project
```

### Z Hammerspoon

Naciśnij **Cmd+Shift+P** w dowolnym miejscu w systemie.

### Flow użycia

1. **Wybór projektu** (fzf):
   - Fuzzy search po wszystkich folderach
   - Podgląd zawartości folderu (prawy panel)
   - Enter = wybierz, Escape = anuluj

2. **Wybór trybu** (macOS GUI):
   - Natywne okno z 5 opcjami
   - Kliknij wybrany tryb
   - "Anuluj" = wyjdź bez uruchamiania

3. **Uruchomienie**:
   - Ghostty otwiera się z wybranym projektem
   - W zależności od trybu: tylko terminal, tmux, neovim, lub claude code

## Struktura projektu

```
/Users/uki/Desktop/dotfiles/fuzzy/
├── launcher                    # Główny skrypt (punkt wejścia)
├── lib/
│   ├── find-projects.sh       # Skanowanie systemu plików
│   ├── mode-selector.swift    # Źródło Swift GUI
│   ├── mode-selector          # Skompilowany binary (po install.sh)
│   └── launch-project.sh      # Logika uruchamiania w różnych trybach
├── config.yaml                 # Konfiguracja użytkownika
├── config.example.yaml         # Przykładowa konfiguracja
├── hammerspoon-init.lua        # Config dla Hammerspoon
├── install.sh                  # Skrypt instalacyjny
└── README.md                   # Ten plik
```

## Przykłady użycia

### Szybkie uruchomienie z neovim

1. Naciśnij **Cmd+Shift+P**
2. Wpisz nazwę projektu w fzf (np. "dotfiles")
3. Wybierz "Tmux + Neovim"
4. Ghostty otwiera się z neovim w projekcie

### Reattach do istniejącej sesji

Jeśli uruchomisz ten sam projekt ponownie w trybie "Tmux Session", launcher automatycznie podłączy się do istniejącej sesji zamiast tworzyć nową.

### Praca z wieloma oknami tmux

Tryb "Tmux + Neovim + Claude Code":
- Okno 1 (editor): Neovim
- Okno 2 (claude): Claude Code
- Przełączanie: **Ctrl+B, 1** lub **Ctrl+B, 2**

## Rozwiązywanie problemów

### "mode-selector: command not found"

Uruchom ponownie instalator:
```bash
./install.sh
```

Lub skompiluj ręcznie:
```bash
swiftc -o lib/mode-selector lib/mode-selector.swift
```

### Ghostty nie otwiera się

Sprawdź czy Ghostty jest zainstalowany:
```bash
ls -la /Applications/Ghostty.app
```

Jeśli nie, pobierz z: https://ghostty.org/

### Hammerspoon hotkey nie działa

1. Sprawdź czy Hammerspoon jest uruchomiony (ikona w menu bar)
2. Sprawdź czy config został dodany do `~/.hammerspoon/init.lua`
3. Reload config: **Cmd+Ctrl+R**
4. Sprawdź Hammerspoon Console (przez menu) czy są błędy

### fzf nie znajduje projektów

1. Sprawdź config.yaml - czy wykluczenia nie są zbyt restrykcyjne
2. Sprawdź czy `excluded_dirs` nie wykluczają wszystkich folderów
3. Uruchom ręcznie:
   ```bash
   ./lib/find-projects.sh
   ```

### Sesje tmux się nie tworzą

Sprawdź czy tmux jest zainstalowany:
```bash
tmux -V
```

Jeśli nie:
```bash
brew install tmux
```

## Zaawansowane

### Dodanie własnego trybu

Edytuj:
1. `lib/mode-selector.swift` - dodaj nowy case do enum `LaunchMode`
2. `lib/launch-project.sh` - dodaj case do switcha z logiką uruchomienia
3. Przekompiluj: `./install.sh`

### Zmiana skrótu klawiszowego

Edytuj `~/.hammerspoon/init.lua`:
```lua
-- Zmień na np. Cmd+Shift+O
local hotkey_mods = {"cmd", "shift"}
local hotkey_key = "O"
```

Reload Hammerspoon: **Cmd+Ctrl+R**

### Integracja z innymi terminalami

Edytuj `lib/launch-project.sh` i zmień:
```bash
# Z:
open -a Ghostty --args ...

# Na (np. iTerm2):
open -a iTerm --args ...
```

## Licencja

MIT

## Autor

Utworzone dla efektywnego zarządzania środowiskami programistycznymi na macOS.

## Changelog

### v1.0.0 (2026-01-11)
- Pierwsza wersja
- 5 trybów uruchomienia
- Integracja z Hammerspoon
- Konfigurowalne wykluczenia
- Automatyczne reattach do sesji tmux
