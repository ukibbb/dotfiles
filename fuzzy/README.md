# Project Launcher

Minimalistyczne narzędzie do szybkiego uruchamiania środowisk programistycznych na macOS z fuzzy finderem do wyboru projektu.

## Funkcjonalności

- **Wybór projektu**: Fuzzy search (fzf) po wszystkich folderach w systemie
- **Automatyczne uruchomienie**: Domyślny tryb: Tmux + Neovim + Claude Code
- **Nazwane sesje tmux**: Automatyczne reattach do istniejących sesji
- **Dual trigger**: Uruchamianie z CLI lub globalnym skrótem klawiszowym (Hammerspoon)
- **Wbudowane wykluczenia**: Automatycznie pomija foldery systemowe i cache

## Tryby uruchomienia

Domyślny tryb: **Tmux + Neovim + Claude Code** - Sesja z dwoma oknami tmux

Możesz użyć innych trybów przekazując parametr:

1. **terminal-only** - Tylko terminal w wybranym katalogu
2. **terminal-tmux** - Terminal z uruchomionym tmux (bez nazwanej sesji)
3. **tmux-session** - Nazwana sesja tmux z możliwością reattach
4. **tmux-nvim** - Sesja tmux z automatycznie uruchomionym Neovim
5. **tmux-nvim-claude** - Sesja z dwoma oknami: Neovim + Claude Code (domyślny)

## Wymagania

### Wymagane

- **macOS** (testowane na macOS Sonoma+)
- **fzf** - Fuzzy finder do wyboru projektów
  ```bash
  brew install fzf
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
   - Ustawi uprawnienia wykonywania
   - Opcjonalnie doda launcher do PATH
   - Pomoże skonfigurować Hammerspoon

3. **Gotowe!** Możesz teraz uruchomić:
   ```bash
   ./launcher
   # lub (jeśli dodałeś do PATH)
   project-launcher
   ```

## Konfiguracja

### Wykluczenia folderów

Domyślne wykluczenia (hardcoded w `lib/find-projects.sh`):
- System: `Library`, `Applications`, `.Trash`
- Cache: `.cache`, `.npm`, `.yarn`
- Dev: `node_modules`, `.git`, `.svn`, `dist`, `build`, `target`

Możesz edytować `lib/find-projects.sh` i zmienić tablicę `DEFAULT_EXCLUSIONS` aby dostosować wykluczenia.

### Domyślny tryb

Domyślnie launcher używa trybu `tmux-nvim-claude`. Możesz zmienić to w `launcher`:

```bash
# Znajdź linię:
DEFAULT_MODE="tmux-nvim-claude"

# Zmień na np.:
DEFAULT_MODE="tmux-nvim"
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
# Interaktywny tryb - wybierz projekt (domyślny tryb)
./launcher

# lub (jeśli w PATH)
project-launcher

# Bezpośrednio dla konkretnego projektu
./launcher /path/to/project

# Konkretny projekt z konkretnym trybem
./launcher /path/to/project tmux-nvim
```

### Z Hammerspoon

Naciśnij **Cmd+Shift+P** w dowolnym miejscu w systemie.

### Flow użycia

1. **Wybór projektu** (fzf):
   - Fuzzy search po wszystkich folderach
   - Podgląd zawartości folderu (prawy panel)
   - Enter = wybierz, Escape = anuluj

2. **Uruchomienie**:
   - Ghostty otwiera się z wybranym projektem
   - Domyślnie uruchamia się tryb: Tmux + Neovim + Claude Code

## Struktura projektu

```
/Users/uki/Desktop/dotfiles/fuzzy/
├── launcher                    # Główny skrypt (punkt wejścia)
├── lib/
│   ├── find-projects.sh       # Skanowanie systemu plików
│   └── launch-project.sh      # Logika uruchamiania w różnych trybach
├── hammerspoon-init.lua        # Config dla Hammerspoon
├── install.sh                  # Skrypt instalacyjny
└── README.md                   # Ten plik
```

## Przykłady użycia

### Szybkie uruchomienie

1. Naciśnij **Cmd+Shift+P**
2. Wpisz nazwę projektu w fzf (np. "dotfiles")
3. Ghostty otwiera się z tmux, neovim i claude code

### Reattach do istniejącej sesji

Jeśli uruchomisz ten sam projekt ponownie, launcher automatycznie podłączy się do istniejącej sesji zamiast tworzyć nową.

### Praca z wieloma oknami tmux

Domyślny tryb tworzy dwa okna:
- Okno 1 (editor): Neovim
- Okno 2 (claude): Claude Code
- Przełączanie: **Ctrl+B, 1** lub **Ctrl+B, 2**

### Użycie z konkretnym trybem

```bash
# Tylko terminal bez tmux
./launcher ~/projects/myapp terminal-only

# Tylko tmux z neovim (bez claude)
./launcher ~/projects/myapp tmux-nvim
```

## Rozwiązywanie problemów

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

1. Sprawdź wykluczenia w `lib/find-projects.sh` (tablica `DEFAULT_EXCLUSIONS`)
2. Uruchom ręcznie:
   ```bash
   ./lib/find-projects.sh
   ```
3. Sprawdź czy `fd` lub `find` jest dostępne:
   ```bash
   command -v fd
   command -v find
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

### Zmiana domyślnego trybu

Edytuj `launcher` i zmień wartość `DEFAULT_MODE`:
```bash
# Linia ~60
DEFAULT_MODE="tmux-nvim"  # Zmień z tmux-nvim-claude na cokolwiek innego
```

### Dodanie/usunięcie wykluczeń

Edytuj `lib/find-projects.sh` i zmodyfikuj tablicę `DEFAULT_EXCLUSIONS`:
```bash
DEFAULT_EXCLUSIONS=(
    "Library"
    "Applications"
    ".Trash"
    "node_modules"
    ".git"
    "dist"
    "build"
    # Dodaj więcej...
)
```

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

### v2.0.0 (2026-01-11)
- Usunięto GUI dla wyboru trybu
- Usunięto config.yaml (hardcoded exclusions)
- Usunięto Swift/AppleScript zależności
- Domyślny tryb: tmux-nvim-claude
- Znacznie uproszczona instalacja

### v1.0.0 (2026-01-11)
- Pierwsza wersja
- 5 trybów uruchomienia z GUI
- Integracja z Hammerspoon
- Konfigurowalne wykluczenia
- Automatyczne reattach do sesji tmux
