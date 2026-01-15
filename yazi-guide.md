# Przewodnik Yazi w Neovim

## Co to jest Yazi?

Yazi to nowoczesny, szybki terminal file manager napisany w Rust. Integracja z Neovim pozwala na błyskawiczne przeglądanie i zarządzanie plikami bez opuszczania edytora.

## Twoje Keybindings

### Otwieranie Yazi w Neovim

| Klawisz | Działanie |
|---------|-----------|
| `<leader>i` (Space-i) | Otwórz yazi w lokalizacji obecnego pliku |
| `<leader>iw` (Space-i-w) | Otwórz yazi w working directory projektu |
| `<leader>is` (Space-i-s) | Wznów ostatnią sesję yazi (toggle) |

### Pomoc w Yazi

| Klawisz | Działanie |
|---------|-----------|
| `F1` | Pokaż listę wszystkich komend yazi |

---

## Podstawowa Nawigacja w Yazi

### Poruszanie się

| Klawisz | Działanie |
|---------|-----------|
| `j` lub `↓` | W dół (następny plik) |
| `k` lub `↑` | W górę (poprzedni plik) |
| `h` lub `←` | Przejdź do folderu wyżej (parent directory) |
| `l` lub `→` lub `Enter` | Wejdź do folderu / otwórz plik |
| `g` + `g` | Skocz na górę listy |
| `G` | Skocz na dół listy |
| `Ctrl-d` | Przesuń w dół o pół strony |
| `Ctrl-u` | Przesuń w górę o pół strony |

### Szybkie Skoki

| Klawisz | Działanie |
|---------|-----------|
| `~` | Przejdź do home directory |
| `/` | Szukaj plików (wpisz nazwę) |
| `n` | Następny wynik wyszukiwania |
| `N` | Poprzedni wynik wyszukiwania |

---

## Operacje na Plikach

### Zaznaczanie

| Klawisz | Działanie |
|---------|-----------|
| `Space` | Zaznacz/odznacz obecny plik |
| `v` | Tryb wizualny (zaznaczanie wielu plików) |
| `V` | Odwróć zaznaczenie (toggle wszystkich) |
| `Ctrl-a` | Zaznacz wszystkie pliki |
| `Ctrl-r` | Odznacz wszystkie |

### Operacje Podstawowe

| Klawisz | Działanie |
|---------|-----------|
| `y` | Yank (kopiuj) zaznaczone pliki |
| `x` | Cut (wytnij) zaznaczone pliki |
| `p` | Paste (wklej) skopiowane/wycięte pliki |
| `d` | Delete (usuń) - wymaga potwierdzenia |
| `D` | Delete na stałe (force delete) |
| `r` | Rename (zmień nazwę pliku) |
| `a` | Create file (utwórz nowy plik) |
| `A` | Create directory (utwórz nowy folder) |

### Otwieranie Plików

| Klawisz | Działanie |
|---------|-----------|
| `Enter` | Otwórz plik w Neovim i zamknij yazi |
| `o` | Otwórz plik domyślną aplikacją systemową |
| `O` | Otwórz interaktywnie (wybierz program) |

---

## Widoki i Sortowanie

### Sortowanie

| Klawisz | Działanie |
|---------|-----------|
| `,` + `m` | Sort by modified time (czas modyfikacji) |
| `,` + `n` | Sort by name (nazwa) |
| `,` + `s` | Sort by size (rozmiar) |
| `,` + `e` | Sort by extension (rozszerzenie) |

### Widok

| Klawisz | Działanie |
|---------|-----------|
| `z` | Zmień układ paneli (layout) |
| `Z` | Zmień widok sortowania (ascending/descending) |

---

## Przydatne Funkcje

### Podgląd Plików

- Yazi automatycznie pokazuje podgląd pliku w prawym panelu
- Obsługuje:
  - Pliki tekstowe (z kolorowaniem składni)
  - Obrazy (preview w terminalu)
  - PDF-y
  - Archiwa (pokazuje zawartość)
  - Kodu źródłowego

### Shell Commands

| Klawisz | Działanie |
|---------|-----------|
| `:` | Otwórz command line yazi |
| `!` | Wykonaj shell command |
| `;` | Wykonaj shell command w tle |

### Zakładki (Tabs)

| Klawisz | Działanie |
|---------|-----------|
| `t` | Utwórz nową zakładkę |
| `1-9` | Przełącz się do zakładki o numerze 1-9 |
| `[` | Poprzednia zakładka |
| `]` | Następna zakładka |
| `q` | Zamknij obecną zakładkę |

---

## Workflow - Typowe Scenariusze

### 1. Szybkie Otwieranie Pliku
```
1. Naciśnij Space-i
2. Nawiguj strzałkami lub hjkl
3. Naciśnij Enter aby otworzyć plik w Neovim
```

### 2. Kopiowanie Plików
```
1. Otwórz yazi (Space-i)
2. Zaznacz pliki spacją lub 'v'
3. Naciśnij 'y' (yank/copy)
4. Przejdź do docelowego folderu (hjkl)
5. Naciśnij 'p' (paste)
```

### 3. Tworzenie Nowego Pliku
```
1. Otwórz yazi w odpowiednim folderze (Space-i-w)
2. Naciśnij 'a' (create file)
3. Wpisz nazwę pliku
4. Enter - plik zostanie utworzony i otwarty w Neovim
```

### 4. Szukanie Pliku
```
1. Otwórz yazi (Space-i)
2. Naciśnij '/' (search)
3. Zacznij wpisywać nazwę pliku
4. Używaj 'n' i 'N' do nawigacji między wynikami
5. Enter aby otworzyć
```

### 5. Usuwanie Wielu Plików
```
1. Otwórz yazi (Space-i)
2. Naciśnij 'v' (visual mode)
3. Zaznacz pliki używając j/k
4. Naciśnij 'd' (delete)
5. Potwierdź usunięcie
```

### 6. Przeglądanie Struktury Projektu
```
1. Space-i-w (otwórz w working directory)
2. Używaj h/l do wchodzenia/wychodzenia z folderów
3. Prawy panel pokazuje podgląd zawartości
4. Szybko eksploruj całą strukturę
```

---

## Zaawansowane Wskazówki

### Integracja z Git
- Yazi pokazuje status git dla plików (M = modified, ?? = untracked, etc.)
- Kolory w liście plików wskazują na zmiany git

### Bulk Operations
- Zaznacz wiele plików (Space lub v)
- Operacje (y/x/d) działają na wszystkich zaznaczonych

### Szybka Nawigacja
- `~` - home directory
- `gg` - top of list
- `G` - bottom of list
- `/` + nazwa - search

### Multiple Tabs
- Pracuj z wieloma lokalizacjami jednocześnie
- `t` aby utworzyć nową zakładkę
- `1-9` aby przełączać się między nimi

---

## Najważniejsze Komendy - Ściągawka

| Akcja | Klawisz |
|-------|---------|
| **Otwórz yazi** | `Space-i` |
| **Pomoc** | `F1` |
| **Nawigacja** | `hjkl` lub strzałki |
| **Otwórz plik** | `Enter` |
| **Zaznacz** | `Space` |
| **Kopiuj** | `y` |
| **Wytnij** | `x` |
| **Wklej** | `p` |
| **Usuń** | `d` |
| **Zmień nazwę** | `r` |
| **Nowy plik** | `a` |
| **Nowy folder** | `A` |
| **Szukaj** | `/` |
| **Wyjdź** | `q` lub `Esc` |

---

## Troubleshooting

### Yazi się nie otwiera
- Sprawdź czy yazi jest zainstalowany: `yazi --version`
- Instalacja: `brew install yazi` (macOS)

### Podgląd obrazków nie działa
- Zainstaluj dodatkowe dependencies:
  ```bash
  brew install imagemagick
  brew install ffmpegthumbnailer
  ```

### Chcę zmienić keybindings
- Edytuj: `nvim/lua/plugins/init.lua` (sekcja yazi keys)
- Dokumentacja: `nvim/lua/configs/yazi.lua`

---

## Dodatkowe Zasoby

- **Oficjalna dokumentacja yazi**: https://yazi-rs.github.io/
- **Plugin yazi.nvim**: https://github.com/mikavilpas/yazi.nvim
- **Twoja konfiguracja**: `nvim/lua/configs/yazi.lua`

---

**Protip**: Naciśnij `F1` w yazi aby zobaczyć PEŁNĄ listę wszystkich dostępnych komend!
