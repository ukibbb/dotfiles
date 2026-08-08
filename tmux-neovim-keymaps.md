# Tmux i Neovim: mapowania, wtyczki i przepływy pracy

> Stan opisany w tym przewodniku odpowiada konfiguracji repozytorium zweryfikowanej 8 sierpnia 2026. Zachowanie wtyczek pochodzi z lokalnie zainstalowanych rewizji przypiętych w `nvim/lazy-lock.json`, a nie z dokumentacji najnowszej wersji w sieci.

<a id="spis-tresci"></a>
## Spis treści

- [Szybka ściąga](#szybka-sciaga)
- [Najważniejsze ostrzeżenia](#bezpieczenstwo)
- [Notacja i etykiety](#notacja)
- [Tmux](#tmux)
- [Aktywne mapowania Neovim](#aktywne-mapowania-neovim)
- [Praktyczne przepływy pracy](#przeplywy-pracy)
- [Przewodnik po wtyczkach](#wtyczki)
- [Wymagania i środowisko](#wymagania)
- [Manifest źródeł i wersji](#manifest)
- [Diagnostyka](#diagnostyka)

<a id="szybka-sciaga"></a>
## Szybka ściąga

`prefix` tmux to `Ctrl-s`. `<leader>` Neovim to `Spacja`.

### Tmux na co dzień

| Klawisz | Działanie |
|---|---|
| `Ctrl-s c` | Nowe okno w bieżącym katalogu |
| `Ctrl-s \|` | Panel obok, lewo/prawo |
| `Ctrl-s -` | Panel poniżej, góra/dół |
| `Ctrl-h/j/k/l` | Przejście między panelami tmux i splitami Neovim bez prefixu |
| `Ctrl-\` | Poprzedni panel lub split, bez prefixu |
| `Ctrl-s h/j/k/l` | Zmiana rozmiaru panelu o 5 komórek |
| `Ctrl-s m` | Maksymalizacja/przywrócenie panelu |
| `Ctrl-s Ctrl-j` | Wyszukiwarka sesji `tmux-fzf` |
| `Ctrl-s s` | Lista sesji tmux |
| `Ctrl-s d` | Odłączenie od sesji |
| `Ctrl-s r` | Ponowne wczytanie `~/.tmux.conf` |

### Neovim na co dzień

| Cel | Klawisze |
|---|---|
| Plik | `<leader>ff` pliki projektu, `<leader>fa` także ignorowane, `<leader>e` drzewo |
| Tekst | `<leader>fw` w projekcie, `<leader>fW` słowo pod kursorem, `<leader>fz` w buforze, `<leader>fZ` słowo w buforze |
| Bufor | `<leader>fb`, fizyczne `Cmd-h` / `Cmd-l`, fizyczne `Cmd-q` |
| LSP | `gd` definicja, `gD` deklaracja, `gr` referencje, `K` hover, `<leader>ca` akcje, `<leader>ra` zmiana nazwy |
| TypeScript | `gS` źródłowa definicja, `<leader>ci` akcje importów |
| Diagnostyka | `[d` / `]d`, `<leader>dd`, `<leader>ds` |
| Format | `<leader>fm`; zapis także formatuje |
| Git | `<leader>gg` status, `<leader>gv` Diffview, `<leader>gD` CodeDiff, `<leader>gf` bieżący plik kontra `HEAD` |
| Debugger | `F5`, `F10`, `F11`, `F12`, `<leader>db`, `<leader>du` |
| Markdown | `<leader>mr` przełącza renderowanie tylko w buforze Markdown |
| Zdalnie | `<leader>rl` połączenie, `<leader>ro` plik/katalog, `<leader>rs` powłoka |
| Zmiany zewnętrzne | `<leader>ch` zatwierdza obejrzenie podświetleń watchdiff |
| Claude | `<leader>ac` pytanie, `<leader>aC` pytanie i próba natychmiastowego komentarza |

<a id="bezpieczenstwo"></a>
## Najważniejsze ostrzeżenia

> **UWAGA: Git.** `X` w CodeDiff i Diffview, `x` w Neogit, reset hard w Telescope, przywracanie pliku oraz usuwanie nieśledzonego pliku mogą bezpowrotnie usunąć niezapisane lub niezatwierdzone dane. Przed użyciem sprawdź `git status`, zapisz potrzebne bufory i w razie wątpliwości utwórz commit albo stash.

> **UWAGA: historia Git.** `Enter` w pickerze `<leader>cm` wykonuje checkout wybranego commita i zwykle przechodzi do detached `HEAD`. `Ctrl-r m`, `Ctrl-r s` i `Ctrl-r h` przesuwają bieżącą gałąź. Szczególnie `Ctrl-r h` usuwa śledzone zmiany z indeksu i drzewa roboczego.

> **UWAGA: `Ctrl-s`.** Tmux przechwytuje `Ctrl-s` jako prefix. Aby wysłać dosłowne `Ctrl-s` do Neovim lub programu w panelu, naciśnij `Ctrl-s Ctrl-s`. Dotyczy to między innymi wbudowanej pomocy sygnatur LSP, akcji `StageAll` w Neogit i zapisu koloru w Minty. `.zshrc` wykonuje `stty -ixon`, więc terminal nie używa `Ctrl-s` jako XOFF, ale konflikt z prefixem tmux pozostaje.

> **UWAGA: pliki zdalne i zewnętrzne.** `D`, `R`, `K` w interfejsach Distant mogą usuwać, zmieniać nazwę lub zrywać połączenie. `:e!` po konflikcie watchdiff odrzuca lokalne, niezapisane zmiany bufora.

<a id="notacja"></a>
## Notacja i etykiety

### Tryby Neovim

| Symbol | Dokładne znaczenie |
|---|---|
| `n` | Normal |
| `i` | Insert |
| `v` | Visual **oraz Select**; tak działa tryb mapowania `v` w API Neovim |
| `x` | Tylko Visual, bez Select |
| `s` | Tylko Select |
| `o` | Operator-pending |
| `c` | Command-line |
| `t` | Terminal |

`n,x` oznacza dwa mapowania: Normal i tylko Visual. `i,s` oznacza Insert i Select. W nazwach klawiszy `C`, `M` i `S` oznaczają odpowiednio `Ctrl`, `Alt/Meta` i `Shift`.

### Etykiety stanu

| Etykieta | Znaczenie |
|---|---|
| **Aktywne lokalne** | Mapowanie lub zachowanie rzeczywiście włączone przez to repozytorium |
| **Domyślne wtyczki** | Mapowanie instalowane przez przypiętą wtyczkę, bez lokalnej definicji |
| **Kontekstowe** | Działa tylko w określonym buforze, panelu, trybie, filetype albo po podłączeniu LSP |
| **Polecenie** | Publiczne polecenie Ex, które można wpisać po `:`; wewnętrzne funkcje Lua nie są tu nazywane poleceniami |
| **Przykład nieaktywny** | Skrót pokazany przez README jako przykład, ale nieutworzony przez tę konfigurację |
| **Warunkowe/wyłączone** | Istnieje tylko po spełnieniu warunku albo jest jawnie wyłączone |
| **Biblioteka bez UI** | Zależność dla innych wtyczek, bez samodzielnego przepływu klawiaturowego |

### Klawisze fizyczne na macOS

Karabiner dla Ghostty tłumaczy fizyczne `Cmd-h`, `Cmd-l`, `Cmd-q`, `Cmd-\` i `Cmd--` na kombinacje widziane przez terminal jako mapowania `Meta+Ctrl`. Dlatego konfiguracja Neovim zapisuje je jako `<M-C-H>`, `<M-C-L>`, `<M-C-Q>`, `<M-C-\>` i `<M-C-_>`. W tabelach podano zarówno zamiar fizyczny, jak i kod Neovim tam, gdzie to potrzebne.

<a id="tmux"></a>
## Tmux

### Konfiguracja i zachowanie terminala

- Terminal domyślny: `tmux-256color`; dla Ghostty włączone są RGB, synchronized output i extended keys w formacie CSI-u.
- `allow-passthrough` jest wyłączone, aby surowe odpowiedzi DCS nie trafiały do aplikacji TUI.
- Mysz jest włączona.
- Czas powtarzania mapowań wynosi 1000 ms.
- Copy mode używa klawiszy vi.
- Pasek statusu ma tło `#00d9ff` i czarny tekst.

### Wszystkie jawne mapowania z `tmux.conf`

| Kontekst | Klawisz | Działanie | Stan |
|---|---|---|---|
| globalny | `Ctrl-s` | Wejście do tabeli prefix | **Aktywne lokalne** |
| prefix | `Ctrl-s` | `send-prefix`, czyli wysłanie dosłownego klawisza prefix do programu lub zagnieżdżonego tmux | **Aktywne lokalne** |
| prefix | `\|` | `split-window -h` w bieżącym katalogu, panele obok siebie | **Aktywne lokalne** |
| prefix | `-` | `split-window -v` w bieżącym katalogu, panele jeden nad drugim | **Aktywne lokalne** |
| prefix | `c` | Nowe okno w bieżącym katalogu panelu | **Aktywne lokalne** |
| prefix | `r` | `source-file ~/.tmux.conf` | **Aktywne lokalne** |
| prefix, powtarzalne | `h` / `j` / `k` / `l` | Rozmiar panelu w lewo / dół / górę / prawo o 5 | **Aktywne lokalne** |
| prefix, powtarzalne | `m` | Przełączenie zoomu panelu | **Aktywne lokalne** |
| prefix | `Ctrl-j` | Skrypt `tmux-fzf/scripts/session.sh switch` w tle | **Aktywne lokalne** |
| prefix | `Ctrl-g` | Wyłączenie trybów myszy i alternate screen oraz `stty sane -ixon` po zepsutym TUI | **Aktywne lokalne** |
| copy-mode-vi | `v` | Początek zaznaczenia | **Aktywne lokalne** |
| copy-mode-vi | `y` | Kopiowanie zaznaczenia do bufora tmux | **Aktywne lokalne** |
| copy-mode-vi | zakończenie przeciągania myszą | Nie wychodzi automatycznie z copy mode | **Warunkowe/wyłączone**: domyślna akcja została odpięta |

### Przydatne domyślne mapowania tmux 3.6a, które nadal działają

| Obszar | Klawisz po prefixie | Działanie |
|---|---|---|
| sesje | `d` | Odłącz klienta od sesji |
| sesje | `s` | Interaktywna lista sesji |
| sesje | `$` | Zmień nazwę sesji |
| sesje | `(` / `)` | Poprzednia / następna sesja |
| sesje | `L` | Ostatnio używana sesja |
| okna | `n` / `p` | Następne / poprzednie okno |
| okna | `0`...`9` | Okno o podanym numerze |
| okna | `w` | Drzewo okien i sesji |
| okna | `,` | Zmień nazwę okna |
| okna | `&` | Zabij okno po potwierdzeniu |
| panele | `o` | Następny panel |
| panele | `;` | Ostatni panel |
| panele | `q` | Pokaż numery paneli |
| panele | `x` | Zabij panel po potwierdzeniu |
| panele | `!` | Przenieś panel do nowego okna |
| panele | `{` / `}` | Zamień panel z poprzednim / następnym |
| układ | `Spacja` | Następny układ paneli |
| copy mode | `[` | Wejdź do copy mode |
| pomoc | `?` | Lista mapowań tmux |
| polecenie | `:` | Prompt poleceń tmux |

W copy-mode-vi działają między innymi `h/j/k/l`, `Ctrl-u`, `Ctrl-d`, `/`, `?` i `q`. `v` oraz `y` są lokalnie ustawione jawnie.

### Domyślne akcje zastąpione lokalnie

| Dawny klawisz | Domyślna akcja tmux | Stan lokalny |
|---|---|---|
| `Ctrl-b` | Prefix | Odpięty, zastąpiony przez `Ctrl-s` |
| `prefix %` | Split lewo/prawo | Odpięty, użyj `prefix \|` |
| `prefix "` | Split góra/dół | Odpięty, użyj `prefix -` |
| `prefix r` | `refresh-client`, czyli polecenie odświeżenia bieżącego klienta tmux | Zastąpione wczytaniem konfiguracji; nie jest to już domyślne odświeżenie klienta |
| `prefix l` | Ostatnie okno | Zastąpione zmianą rozmiaru w prawo |
| `prefix m` | Oznaczenie panelu | Zastąpione zoomem |

### Trzy wtyczki tmux

#### `tmux-plugins/tpm`

| Klawisz | Działanie | Stan |
|---|---|---|
| `prefix I` | Instalacja brakujących wtyczek i odświeżenie środowiska tmux | **Domyślne wtyczki** |
| `prefix U` | Aktualizacja wtyczek | **Domyślne wtyczki** |
| `prefix Alt-u` | Usunięcie wtyczek nieobecnych w konfiguracji | **Domyślne wtyczki** |

Aktualizacja nie jest ograniczona commitami w `tmux.conf`; patrz manifest.

#### `sainnhe/tmux-fzf`

| Klawisz | Działanie | Stan |
|---|---|---|
| `prefix F` | Pełne menu sesji, okien, paneli, poleceń, klawiszy, schowka i procesów | **Domyślne wtyczki** |
| `prefix Ctrl-j` | Bezpośredni picker przełączania sesji | **Aktywne lokalne** |
| `Tab` / `Shift-Tab` w fzf | Zaznaczenie wielu elementów / ruch wstecz | **Kontekstowe** |

Wymagane są GNU Bash, `sed` i `fzf`; CopyQ i `pstree` są opcjonalne.

#### `christoomey/vim-tmux-navigator`

| Kontekst | Klawisz | Działanie | Stan |
|---|---|---|---|
| root tmux i Normal Neovim | `Ctrl-h/j/k/l` | Lewo / dół / góra / prawo przez granice splitów i paneli | **Domyślne wtyczki** |
| root tmux i Normal Neovim | `Ctrl-\` | Poprzedni split lub panel | **Domyślne wtyczki** |
| copy-mode-vi | `Ctrl-h/j/k/l`, `Ctrl-\` | Nawigacja paneli tmux | **Kontekstowe** |
| prefix tmux | `Ctrl-l` | Wysłanie dosłownego `Ctrl-l` do programu, zwykle wyczyszczenie ekranu powłoki | **Domyślne wtyczki** |

Po stronie tmux wtyczka sprawdza proces w panelu. Gdy wykryje Vim/Neovim lub proces pasujący do jej wzorca, przekazuje klawisz do aplikacji; w innym panelu wykonuje `select-pane`. Nie naciska się prefixu. W Insert Neovim lokalne `Ctrl-h/j/k/l` poruszają kursorem, więc nie przełączają panelu. Polecenia Neovim: `:TmuxNavigateLeft`, `:TmuxNavigateDown`, `:TmuxNavigateUp`, `:TmuxNavigateRight`, `:TmuxNavigatePrevious`, `:TmuxNavigatorProcessList`.

### Mini-tutorial: sesja i panele

1. Uruchom `tmux new -s projekt` w powłoce.
2. Utwórz okno edytora przez `Ctrl-s c`, a potem panel terminala przez `Ctrl-s |`.
3. Uruchom Neovim w jednym panelu i przechodź `Ctrl-h` / `Ctrl-l` przez split Neovim oraz granicę tmux.
4. Zmień rozmiar panelu przez `Ctrl-s`, a następnie powtarzaj `h/j/k/l`.
5. Otwórz inne sesje przez `Ctrl-s Ctrl-j`, wybierz sesję w fzf i zatwierdź `Enter`.
6. Odłącz się przez `Ctrl-s d`; wróć poleceniem `tmux attach -t projekt`.

<a id="aktywne-mapowania-neovim"></a>
## Aktywne mapowania Neovim

### Podstawy, ruch i edycja

| Tryb | Klawisz | Działanie | Stan |
|---|---|---|---|
| `i` | `jk` | Wyjście do Normal | **Aktywne lokalne** |
| `i` | `Ctrl-b` | Pierwszy niepusty znak wiersza | **Aktywne lokalne** |
| `i` | `Ctrl-e` | Koniec wiersza | **Aktywne lokalne** |
| `i` | `Ctrl-h/j/k/l` | Lewo / dół / góra / prawo | **Aktywne lokalne** |
| `n` | fizyczne `Cmd-\`, `<M-C-\>` | Nowy pionowy podział, okna obok siebie | **Aktywne lokalne** |
| `n` | fizyczne `Cmd--`, `<M-C-_>` | Nowy poziomy podział, okna góra/dół | **Aktywne lokalne** |
| `n` | `Esc` | Wyłączenie podświetlenia wyszukiwania | **Aktywne lokalne** |
| `x` | `<leader>h` | Ustawienie dosłownego wzorca wyszukiwania z zaznaczenia i podświetlenie wszystkich wystąpień | **Aktywne lokalne** |
| `n` | `;` | Wejście do linii poleceń `:`; zastępuje powtórzenie ruchu `f/t` | **Aktywne lokalne** |
| `n` | `Ctrl-c` | Kopia całego pliku do rejestru systemowego `+` | **Aktywne lokalne** |
| `n` | `Ctrl-a` | Zaznaczenie całego pliku | **Aktywne lokalne** |
| `v` | `J` / `K` | Przesunięcie zaznaczonych wierszy w dół / górę i ponowne wcięcie | **Aktywne lokalne** |
| `n` | `J` | Połączenie wierszy bez przesuwania kursora | **Aktywne lokalne** |
| `n` | `Ctrl-d` / `Ctrl-u` | Pół strony w dół / górę i wycentrowanie | **Aktywne lokalne** |
| `n` | `n` / `N` | Następny / poprzedni wynik, wycentrowany i odsłonięty z folda | **Aktywne lokalne** |
| `x` | `p` | Wklejenie nad zaznaczenie bez nadpisania rejestru wklejanego tekstu | **Aktywne lokalne** |
| `n` | `<leader>n` | Przełączenie numerów bezwzględnych | **Aktywne lokalne** |
| `n` | `<leader>rn` | Przełączenie numerów względnych | **Aktywne lokalne** |
| `n` | `<leader>w` | Przełączenie zawijania wierszy | **Aktywne lokalne** |
| `n` | `<leader>y` | Kopia całego pliku do schowka systemowego | **Aktywne lokalne** |
| `n` | `<leader>/` | Komentarz bieżącego wiersza przez wbudowane `gcc` | **Aktywne lokalne** |
| `v` | `<leader>/` | Komentarz zaznaczenia przez wbudowane `gc` | **Aktywne lokalne** |

Mapowanie `v` jest zainstalowane także w Select. Wbudowany operator komentarza Neovim ma właściwe mapowanie w `n`, `x` i `o`, dlatego komentarz zaznaczenia należy praktycznie uruchamiać z Visual.

### Bufory, formatowanie i listy

| Tryb | Klawisz | Działanie | Stan |
|---|---|---|---|
| `n` | `<leader>b` | Nowy pusty bufor | **Warunkowe/wyłączone**: aktywne, bo NvChad tabufline jest włączone |
| `n` | fizyczne `Cmd-h`, `<M-C-H>` | Poprzedni bufor tabufline | **Warunkowe/wyłączone**: tabufline |
| `n` | fizyczne `Cmd-l`, `<M-C-L>` | Następny bufor tabufline | **Warunkowe/wyłączone**: tabufline |
| `n` | fizyczne `Cmd-q`, `<M-C-Q>` | Zamknięcie bieżącego bufora tabufline | **Warunkowe/wyłączone**: tabufline |
| `n,x` | `<leader>fm` | Format całego pliku lub zakresu przez Conform, z fallbackiem LSP | **Aktywne lokalne** |
| `n` | `<leader>ds` | Diagnostyka do location list | **Aktywne lokalne** |
| `n` | `[d` / `]d` | Poprzednia / następna diagnostyka i wsparcie licznikami | **Domyślne Neovim 0.12** |
| `n` | `<leader>dd` | Pływający opis diagnostyki | **Aktywne lokalne** |
| `n` | `<leader>q` | Diagnostyka do location list, to samo przeznaczenie co `<leader>ds` | **Aktywne lokalne** |
| `n` | `[q` / `]q` | Poprzedni / następny wpis quickfix i wycentrowanie | **Aktywne lokalne** |

### Telescope i wybór motywu

| Klawisz | Picker lub działanie | Stan |
|---|---|---|
| `<leader>ff` | Pliki, z dotfiles, z poszanowaniem ignore | **Aktywne lokalne** |
| `<leader>fa` | Wszystkie pliki: hidden, ignored i symlinki | **Aktywne lokalne** |
| `<leader>fw` | `live_grep`, także pliki ukryte, bez wnętrza `.git/` | **Aktywne lokalne** |
| `<leader>fW` | `live_grep` z tekstem początkowym równym słowu pod kursorem | **Aktywne lokalne** |
| `<leader>fb` | Otwarte bufory | **Aktywne lokalne** |
| `<leader>fh` | Tagi pomocy | **Aktywne lokalne** |
| `<leader>ma` | Marki | **Aktywne lokalne** |
| `<leader>fo` | Ostatnio otwarte pliki | **Aktywne lokalne** |
| `<leader>fz` | Wyszukiwanie w bieżącym buforze | **Aktywne lokalne** |
| `<leader>fZ` | Wyszukiwanie w buforze ze słowem pod kursorem | **Aktywne lokalne** |
| `<leader>cm` | Historia commitów katalogu | **Aktywne lokalne** |
| `<leader>gt` | Status Git; `Tab` w tym pickerze stage/unstage | **Aktywne lokalne** |
| `<leader>th` | Picker motywów NvChad | **Aktywne lokalne** |

W każdym pickerze lokalne `Alt-j` / `Alt-k` poruszają wyborem w Insert, a `q` zamyka picker w Normal.

### Git i przegląd różnic

| Klawisz | Działanie | Stan |
|---|---|---|
| `<leader>gd` | Przełączenie inline diff `Unified` | **Aktywne lokalne** |
| `<leader>gg` | Status Neogit w nowej karcie | **Aktywne lokalne** |
| `<leader>gc` | Popup commit Neogit | **Aktywne lokalne** |
| `<leader>gp` | Popup push Neogit | **Aktywne lokalne** |
| `<leader>gP` | Popup pull Neogit | **Aktywne lokalne** |
| `<leader>gb` | Popup branch Neogit | **Aktywne lokalne** |
| `<leader>gv` | `DiffviewOpen` dla zmian roboczych | **Aktywne lokalne** |
| `<leader>gm` | Porównanie `origin/main...HEAD` w Diffview | **Aktywne lokalne** |
| `<leader>gl` | Historia bieżącego pliku w Diffview | **Aktywne lokalne** |
| `<leader>gL` | Historia całego repozytorium w Diffview | **Aktywne lokalne** |
| `<leader>gq` | Zamknięcie aktywnego Diffview | **Aktywne lokalne** |
| `<leader>gD` | Explorer CodeDiff | **Aktywne lokalne** |
| `<leader>gf` | Dokładnie `CodeDiff file HEAD`, bieżący zapisany plik kontra `HEAD` | **Aktywne lokalne** |
| `<leader>gh` | Dokładnie `CodeDiff history %`, historia bieżącego pliku | **Aktywne lokalne** |

### DAP

| Tryb | Klawisz | Działanie | Stan |
|---|---|---|---|
| `n` | `F5` | Start albo kontynuacja | **Aktywne lokalne** |
| `n` | `F10` | Krok ponad | **Aktywne lokalne** |
| `n` | `F11` | Krok do środka | **Aktywne lokalne** |
| `n` | `F12` | Krok na zewnątrz | **Aktywne lokalne** |
| `n` | `<leader>db` | Przełączenie breakpointu | **Aktywne lokalne** |
| `n` | `<leader>dB` | Breakpoint warunkowy po wpisaniu warunku | **Aktywne lokalne** |
| `n` | `<leader>dc` | Start albo kontynuacja | **Aktywne lokalne** |
| `n,x` | `<leader>de` | Ewaluacja wyrażenia lub zaznaczenia w UI | **Aktywne lokalne** |
| `n` | `<leader>dn` | Najbliższy test Python albo Go; dla innych filetype ostrzeżenie | **Aktywne lokalne** |
| `n` | `<leader>dp` | Pauza | **Aktywne lokalne** |
| `n` | `<leader>dl` | Ponowne uruchomienie ostatniej konfiguracji | **Aktywne lokalne** |
| `n` | `<leader>dr` | REPL | **Aktywne lokalne** |
| `n` | `<leader>dt` | Zakończenie sesji | **Aktywne lokalne** |
| `n` | `<leader>du` | Przełączenie paneli DAP UI | **Aktywne lokalne** |

### LSP po podłączeniu klienta

| Tryb | Klawisz | Działanie | Stan |
|---|---|---|---|
| `n` | `gD` | Deklaracja | **Kontekstowe**, buffer-local LSP |
| `n` | `gd` | Definicja | **Kontekstowe**, buffer-local LSP |
| `n,x` | `<leader>ca` | Akcja kodu/refaktoryzacja dla pozycji lub zakresu | **Kontekstowe**, buffer-local LSP |
| `n` | `<leader>lr` | Wbudowane `:lsp restart` dla klientów bieżącego bufora | **Kontekstowe**, buffer-local LSP i Neovim 0.12 |
| `n` | `gr` | Referencje w Telescope | **Kontekstowe**, buffer-local LSP |
| `n` | `<leader>wa` / `<leader>wr` | Dodanie / usunięcie folderu workspace | **Kontekstowe**, buffer-local LSP |
| `n` | `<leader>wl` | Wypisanie folderów workspace | **Kontekstowe**, buffer-local LSP |
| `n` | `<leader>D` | Definicja typu | **Kontekstowe**, buffer-local LSP |
| `n` | `<leader>ra` | Zmiana nazwy przez UI NvChad | **Kontekstowe**, buffer-local LSP |
| `n` | `gS` | Źródłowa definicja TypeScript zamiast deklaracji typów | **Kontekstowe**, tylko klient `ts_ls` |
| `n` | `<leader>ci` | Akcje źródłowe TypeScript, np. organizacja importów i usunięcie nieużywanego kodu | **Kontekstowe**, tylko klient `ts_ls` |

Wbudowane globalne skróty Neovim 0.12 pozostają dostępne: `grn` rename, `gra` w `n,x` code action, `gri` implementation, `grr` references, `grt` type definition, `grx` code lens, `gO` symbole dokumentu oraz `Ctrl-s` w `i,s` pomoc sygnatur. Po attach `K` pokazuje hover, o ile `keywordprg` lub własne mapowanie go nie zastąpiło. `[D` / `]D` skaczą do pierwszej / ostatniej diagnostyki, a `Ctrl-w d` i `Ctrl-w Ctrl-d` otwierają jej opis.

### `nvim-cmp`: dokładne tryby

| Tryb | Klawisz | Działanie | Stan |
|---|---|---|---|
| `i` | `Ctrl-p` / `Alt-k` | Poprzednia propozycja | **Aktywne lokalne** |
| `i` | `Ctrl-n` / `Alt-j` | Następna propozycja | **Aktywne lokalne** |
| `i` | `Ctrl-d` / `Ctrl-f` | Dokumentacja o 4 wiersze w górę / w dół | **Aktywne lokalne** |
| `i` | `Ctrl-Spacja` | Ręczne otwarcie completion | **Aktywne lokalne** |
| `i` | `Ctrl-e` | Zamknięcie menu completion | **Aktywne lokalne** |
| `i` | `Enter` | Potwierdzenie; `select=true` wybiera pierwszy element także bez jawnego zaznaczenia | **Aktywne lokalne** |
| `i,s` | `Tab` | Następna propozycja, inaczej rozwinięcie/skok LuaSnip, inaczej zwykły fallback | **Aktywne lokalne** |
| `i,s` | `Shift-Tab` | Poprzednia propozycja, inaczej poprzedni placeholder LuaSnip, inaczej fallback | **Aktywne lokalne** |

Wszystkie pozycje poza `Tab` i `Shift-Tab` są tylko w Insert. Brak jawnej listy trybów w API `cmp.mapping` domyślnie oznacza `i`, nie `i,s`.

### Distant, Markdown i lokalne wtyczki

| Tryb/kontekst | Klawisz | Działanie | Stan |
|---|---|---|---|
| `n` | `<leader>rl` | Prompt celu SSH i `DistantLaunch` | **Aktywne lokalne** |
| `n` | `<leader>ro` | Prefiks linii `:DistantOpen ` do dopisania ścieżki | **Aktywne lokalne** |
| `n` | `<leader>rs` | Powłoka zdalna | **Aktywne lokalne** |
| `n` | `<leader>rx` | Prefiks linii `:DistantSpawn ` do dopisania polecenia | **Aktywne lokalne** |
| `n` | `<leader>rp` | Połączenie `ssh://ukibbb@192.168.101.7` | **Aktywne lokalne** |
| `n`, tylko Markdown | `<leader>mr` | `RenderMarkdown buf_toggle` dla bieżącego bufora | **Kontekstowe** |
| `n` | `<leader>ch` | Usunięcie podświetleń watchdiff i przesunięcie baseline | **Aktywne lokalne** |
| `n,v` | `<leader>ac` | Popup Claude, z zaznaczeniem w `v` | **Aktywne lokalne** |
| `n,v` | `<leader>aC` | Claude w trybie natychmiastowego komentarza | **Aktywne lokalne** |

### Mapowania kontekstowe z autocmdów i paneli

| Kontekst | Klawisz | Działanie | Stan |
|---|---|---|---|
| `help`, `qf`, `lspinfo`, `man`, `notify`, `spectre_panel`, `startuptime`, `checkhealth` | `q` | `:close`, bufor poza listą | **Kontekstowe** |
| bufor nvim-tree | fizyczne `Cmd-\` / `Cmd--` | Otwórz w pionowym / poziomym splicie | **Kontekstowe** |
| plik pod `*/claude.nvim/lua/*.lua`, po pierwszym wejściu w sesji | `<leader>rr` | Reload wszystkich modułów `claude.*` | **Kontekstowe** |
| ten sam tryb deweloperski | `<leader>rt` | Reload i otwarcie popupu | **Kontekstowe** |
| ten sam tryb deweloperski | `<leader>rd` | Lista załadowanych modułów Claude | **Kontekstowe** |
| historia watchdiff | `q` | Zamknięcie splitu historii | **Kontekstowe** |
| obsługiwany bufor tagów | `>` w Insert | Wstawienie `>` i ewentualne domknięcie tagu | **Kontekstowe**, nvim-ts-autotag |

Pełne mapowania paneli każdej wtyczki są w jej sekcji poniżej.

<a id="przeplywy-pracy"></a>
## Praktyczne przepływy pracy

### Plik i wyszukiwanie

1. Otwórz projekt przez `tmux new -s nazwa`, potem `nvim .`.
2. Użyj `<leader>ff`, wpisz część ścieżki i `Enter`; `Ctrl-v` otworzy wynik w pionowym splicie.
3. Otwórz drzewo przez `<leader>e`; `Enter` otwiera plik, `-` idzie katalog wyżej, `g?` pokazuje pomoc.
4. Znajdź tekst przez `<leader>fw`; `Tab` zaznacza wiele wyników, `Alt-q` wysyła zaznaczone do quickfix.
5. Przechodź quickfix przez `[q` / `]q` albo bufory przez `<leader>fb`.

### LSP, refaktoryzacja, completion i snippet

1. Otwórz plik obsługiwany przez aktywny serwer i sprawdź `:checkhealth vim.lsp`.
2. Przejdź `gd`, wróć `Ctrl-o`, znajdź użycia `gr`, a dokumentację zobacz przez `K`.
3. Zaznacz zakres w Visual i naciśnij `<leader>ca`, aby ograniczyć akcję kodu do zakresu.
4. Zmień symbol przez `<leader>ra`. Dla TypeScript użyj `gS` do implementacji i `<leader>ci` do akcji całego pliku.
5. Zacznij pisać. W menu completion etykiety `[LSP]`, `[Snippet]`, `[Nvim]`, `[Buffer]`, `[Path]` pokazują źródło.
6. Wybierz pozycję `Tab` i zatwierdź `Enter`; po rozwinięciu snippetu przechodź placeholdery `Tab` / `Shift-Tab`.
7. Jeśli serwer się zawiesi, naciśnij `<leader>lr`; uruchamia to wbudowane `:lsp restart` dla bieżącego bufora.

### Format i lint

1. Naciśnij `<leader>fm` przed przeglądem zmian albo po prostu zapisz plik.
2. Lua używa `stylua`; Python kolejno `ruff_fix` i `ruff_format`; inne filetype mogą użyć formatowania LSP.
3. Po zapisie Pythona `nvim-lint` uruchamia `mypy`, jeśli executable jest w `PATH`.
4. Otwórz `<leader>ds`, aby przejść po diagnostyce location list. Użyj `:ConformInfo`, gdy formatter nie działa.

### Git: status, stage, review i historia

1. Otwórz `<leader>gg`. W statusie Neogit `s` stage'uje zaznaczenie, `u` cofa stage, `S` stage'uje wszystkie unstaged, a `U` cofa wszystkie staged.
2. Obejrzyj diff przez `<leader>gv` albo char-level przez `<leader>gD`; w CodeDiff `-` przełącza stage bieżącego pliku.
3. Utwórz commit przez `<leader>gc`; napisz wiadomość i zatwierdź `Ctrl-c Ctrl-c`. `Ctrl-c Ctrl-k` anuluje edytor commita.
4. Przed push użyj `<leader>gm`, aby porównać `origin/main...HEAD`, potem `<leader>gp`.
5. Historię pliku pokażą `<leader>gh` albo `<leader>gl`; historię repozytorium `<leader>gL`; picker commitów `<leader>cm` służy do checkout/reset i wymaga szczególnej ostrożności.

### Git: konflikt

1. W Diffview otwartym podczas merge/rebase przechodź konflikty `[x` / `]x`.
2. Wybierz `<leader>co` ours, `<leader>ct` theirs, `<leader>cb` base, `<leader>ca` wszystkie strony albo `dx` usuń region konfliktu. Wielkie warianty działają na cały plik.
3. Alternatywnie uruchom CodeDiff jako mergetool. W nim `<leader>co` oznacza current/ours, `<leader>ct` incoming/theirs, `<leader>cb` inteligentne połączenie obu, a `<leader>cx` powrót do base.
4. Zapisz bufor wyniku, sprawdź treść i dopiero wtedy stage'uj plik. Nie myl akcji rozwiązania konfliktu z odrzuceniem całego pliku przez `X`.

### DAP: Python, Go, JavaScript, TypeScript i Chrome

1. Zainstaluj odpowiedni adapter: `debugpy-adapter`, `dlv` albo `js-debug-adapter` musi być w `PATH`.
2. Ustaw breakpoint przez `<leader>db`, uruchom `F5` i wybierz konfigurację.
3. Python: wybierz konfigurację dap-python; `<leader>dn` debugguje metodę testową nad kursorem. Adapter jest skonfigurowany jako `debugpy-adapter`.
4. Go: wybierz debug programu/testów; `<leader>dn` uruchamia najbliższy test znaleziony przez parser Go.
5. JS/TS: wybierz `Launch current file with Node`, `Attach to Node process`, `Launch Chrome` albo `Attach to Chrome`.
6. Dla Chrome uruchamianego ręcznie użyj portu remote debugging, domyślnie `9222`; dla launch wpisz URL aplikacji, domyślnie `http://localhost:3000`.
7. Projektowe konfiguracje umieść w `.vscode/launch.json` z typem `pwa-node` lub `pwa-chrome`. Ta wersja nvim-dap czyta plik automatycznie na żądanie.
8. Steruj przez `F10/F11/F12`, ewaluuj `<leader>de`, a sesję zakończ `<leader>dt`.

### Markdown i tagi

1. Otwórz `.md`; render-markdown ładuje się tylko dla `markdown` i renderuje również w Normal oraz Insert.
2. Naciśnij `<leader>mr`, aby wyłączyć lub włączyć render tylko dla tego bufora.
3. Parsery `markdown` i `markdown_inline` są instalowane, a Treesitter startuje dla Markdown.
4. W HTML wpisz `<div>`: `>` uruchamia domknięcie do `<div></div>`. Zmień nazwę tagu i wyjdź z Insert, aby sparowany tag został przemianowany.
5. Autotag wymaga parsera `html`; ten parser jest instalowany i Treesitter startuje dla `html`.

### Distant

1. Sprawdź lokalny klient przez `:DistantClientVersion` i połączenie przez `<leader>rl`.
2. Podaj `ssh://user@host`; konfiguracja uruchamia zdalny binarny `distant` i łączy klienta.
3. Wpisz `<leader>ro`, dopisz ścieżkę i zatwierdź. W katalogu `Enter` otwiera wpis, `-` idzie wyżej, `Ctrl-t` otwiera kartę.
4. Otwórz zdalną powłokę `<leader>rs` albo wykonaj pojedyncze polecenie przez `<leader>rx`.
5. Zapis działa na hoście zdalnym. Przed `D` upewnij się, że wskazany wpis można usunąć.

### watchdiff i Claude

1. Pozostaw czysty, zapisany bufor otwarty i pozwól narzędziu zewnętrznemu zmienić plik.
2. watchdiff przeładuje czysty bufor, pokaże zielone dodania/zmiany i czerwone wirtualne usunięcia.
3. Obejrzyj zmianę, opcjonalnie uruchom `:WatchDiffHistory`, a potem `<leader>ch`, aby uznać nowy baseline.
4. Zaznacz kod i użyj `<leader>ac`; wpisz pytanie, `Tab` zmienia model, `Enter` wysyła, `Ctrl-j` dodaje nową linię.
5. W drawerze odpowiedzi `1/2/3` przełącza Answer/Question/Files, `y` kopiuje odpowiedź, `I` próbuje wstawić komentarze.
6. `<leader>aC` od razu próbuje bezpiecznego wstawienia komentarzy; gdy nie jest ono bezpieczne, otwiera drawer do przeglądu. Zmiana jest oznaczana dla historii watchdiff.

<a id="wtyczki"></a>
## Przewodnik po wtyczkach

<details>
<summary><strong>lazy.nvim, NvChad UI, Base46, Volt, Menu i Minty</strong></summary>

### `lazy.nvim`

**Co robi i po co:** menedżer wtyczek. Rozwiązuje zależności, ładuje moduły na żądanie, instaluje i przywraca dokładne rewizje z lockfile.

**Ładowanie lokalne:** `nvim/init.lua` bootstrapuje `folke/lazy.nvim` do `~/.local/share/nvim/lazy/lazy.nvim`, dodaje katalog do runtimepath i wywołuje `require("lazy").setup("plugins", ...)`. Domyślnie wszystkie specyfikacje są lazy, chyba że wskazują `lazy=false`, event, filetype, polecenie albo klawisz. Sprawdzanie aktualizacji jest wyłączone, a zmiany konfiguracji nie generują powiadomień.

**Polecenia:** `:Lazy` lub `:Lazy show`, `:Lazy install`, `:Lazy update`, `:Lazy sync`, `:Lazy clean`, `:Lazy check`, `:Lazy log`, `:Lazy restore`, `:Lazy profile`, `:Lazy debug`, `:Lazy help`, `:Lazy health`, `:Lazy load {plugin}`, `:Lazy build {plugin}`, `:Lazy reload {plugin}`, `:Lazy clear`. Wariant `:Lazy!` czeka na ukończenie operacji; dla `load` omija też sprawdzenie `cond`.

| Kontekst UI Lazy | Klawisz | Działanie | Stan |
|---|---|---|---|
| lista | `Enter` | Szczegóły wtyczki | **Domyślne wtyczki** |
| lista | `K` | Hover | **Domyślne wtyczki** |
| lista | `d` | Diff | **Domyślne wtyczki** |
| lista | `q` | Zamknięcie | **Domyślne wtyczki** |
| lista | `I` / `i` | Instalacja brakujących / wskazanej | **Domyślne wtyczki** |
| lista | `U` / `u` | Aktualizacja wszystkich / wskazanej i zapis lockfile | **Domyślne wtyczki** |
| lista | `S` | Install + clean + update | **Domyślne wtyczki** |
| lista | `X` / `x` | Clean zbędnych / usunięcie wskazanej instalacji | **Domyślne wtyczki** |
| lista | `C` / `c` | Sprawdzenie aktualizacji wszystkich / wskazanej | **Domyślne wtyczki** |
| lista | `L` / `gl` | Log zmian | **Domyślne wtyczki** |
| lista | `R` / `r` | Przywrócenie z lockfile | **Domyślne wtyczki** |
| lista | `P`, `D`, `?`, `H` | Profile, debug, help, home | **Domyślne wtyczki** |
| profil | `Ctrl-s` / `Ctrl-f` | Sortowanie / filtr | **Kontekstowe**; w tmux dosłowny klawisz wymaga `Ctrl-s Ctrl-s` |
| zadanie | `Ctrl-c` | Przerwanie | **Kontekstowe** |
| lista | `[[` / `]]` | Poprzednia / następna sekcja | **Domyślne wtyczki** |

**Bezpieczeństwo:** `update` i `sync` zmieniają `nvim/lazy-lock.json`; `clean` usuwa katalogi wtyczek. Do odtworzenia tego repo używaj `:Lazy! restore`, nie przypadkowego `sync`.

**Szybki tutorial:** otwórz `:Lazy`, sprawdź stan, naciśnij `?` do pomocy, a na nowej maszynie wykonaj `:Lazy! restore`. Po świadomej aktualizacji obejrzyj diff lockfile przed commitem.

### `ui`

**Co robi i po co:** przypięty `nvchad/ui` dostarcza statusline, tabufline, renamer LSP, dashboard, cheatsheet i picker motywów. Ładuje się natychmiast (`lazy=false`). Lokalny `chadrc.lua` włącza tabufline i statusline, pokazuje względną ścieżkę pliku i używa motywu `ayu_dark`.

**Aktywne lokalne:** `<leader>th` otwiera picker motywów; `<leader>ra` po attach LSP otwiera renamer; `<leader>b`, fizyczne `Cmd-h`, `Cmd-l`, `Cmd-q` sterują tabufline.

**Polecenia:** `:Nvdash`, `:NvCheatsheet`, `:MasonInstallAll`. Ostatnie zbiera narzędzia z konfiguracji LSP, Conform i nvim-lint, a następnie zleca instalację Masonowi.

| Kontekst | Klawisz | Działanie | Stan |
|---|---|---|---|
| picker motywów, `i` | `Ctrl-n` / `Down`, `Ctrl-p` / `Up` | Następny / poprzedni motyw | **Kontekstowe** |
| picker motywów, `n` | `j` / `Down`, `k` / `Up` | Następny / poprzedni motyw | **Kontekstowe** |
| picker motywów, `i,n` | `Enter` | Zapis wybranego motywu w `chadrc.lua` i zamknięcie | **Kontekstowe** |
| picker motywów, `i` | `Ctrl-w` | Usunięcie poprzedniego słowa promptu | **Kontekstowe** |
| renamer, `i,n` | `Esc` | Anulowanie i usunięcie popupu | **Kontekstowe** |
| cheatsheet | `q` / `Esc` | Zamknięcie | **Kontekstowe** |

**Wymagania:** `base46`, `volt`, ikony z `nvim-web-devicons` i czcionka Nerd Font. Renamer wymaga serwera LSP obsługującego rename.

**Szybki tutorial:** naciśnij `<leader>th`, filtruj nazwę motywu i zatwierdź `Enter`; nad symbolem z LSP użyj `<leader>ra`, wpisz nową nazwę i zatwierdź prompt.

### `base46`

**Co robi i po co:** silnik motywów NvChad. Build wtyczki generuje cache highlightów, a konfiguracja lokalna dogrywa cache dla statusline, LSP, cmp, Git, Mason, Telescope i Treesitter. Nie ma własnych domyślnych mapowań ani publicznych poleceń użytkownika.

**Konfiguracja lokalna:** motyw `ayu_dark`, bez przezroczystości, z override'ami komentarzy, właściwości, typów, modułów, operatorów, wyjątków i interpunkcji. `require("base46").load_all_highlights()` jest API Lua używanym przez build, nie poleceniem Ex.

**Szybki tutorial:** wybierz motyw przez `<leader>th`; gdy cache został usunięty, odbuduj go świadomie przez `:lua require("base46").load_all_highlights()`, a potem ponownie otwórz Neovim.

### `volt`

**Co robi i po co:** framework interaktywnych okien używany przez picker motywów, Minty, Menu i lokalny drawer `claude.nvim`. Nie oferuje samodzielnego launchera ani polecenia Ex.

| Okno zbudowane na Volt | Klawisz | Działanie | Stan |
|---|---|---|---|
| bufor UI | `Ctrl-t` | Cykliczna zmiana bufora/okna składowego | **Kontekstowe** |
| bufor UI | `q` / `Esc` | Zamknięcie całego UI | **Kontekstowe** |
| interaktywny bufor | `Enter` | Uruchomienie elementu pod kursorem | **Kontekstowe** |
| interaktywny bufor | `Tab` / `Shift-Tab` | Następny / poprzedni element klikalny | **Kontekstowe** |

**Szybki tutorial:** otwórz `<leader>th` lub `:Huefy`, przejdź `Tab`, wykonaj `Enter`, a cały interfejs zamknij `q`.

### `menu`

**Co robi i po co:** biblioteka kontekstowych, także zagnieżdżonych menu na Volt. Lokalna konfiguracja jej nie otwiera i nie definiuje `RightMouse` ani innego launchera.

| Klawisz | Działanie po ręcznym otwarciu menu | Stan |
|---|---|---|
| `h` / `l` | Poprzednia / następna kolumna-okno menu | **Kontekstowe** |
| `Enter` | Wykonanie pozycji pod kursorem | **Kontekstowe** |
| `q` / `Esc` | Zamknięcie przez Volt | **Kontekstowe** |
| klawisz pokazany przy pozycji | Bezpośrednie wykonanie pozycji | **Kontekstowe** |

Mapowania otwierające menu z README są **Przykładem nieaktywnym**. `require("menu").open(...)` jest API Lua, nie poleceniem Ex.

**Szybki tutorial:** w tej konfiguracji nie ma aktywnego wejścia do Menu. Do testu trzeba jawnie wywołać API Lua; po otwarciu użyj `h/l`, `Enter` i `q`.

### `minty`

**Co robi i po co:** dwa narzędzia kolorystyczne zbudowane na Volt: Huefy wybiera kolor, Shades generuje odcienie. Ładuje się dopiero po poleceniu.

**Polecenia:** `:Huefy`, `:Shades`.

| Kontekst | Klawisz | Działanie | Stan |
|---|---|---|---|
| Huefy/Shades | `Ctrl-t` | Zmiana składowego okna | **Kontekstowe**, Volt |
| Huefy/Shades | `Tab` / `Shift-Tab`, `Enter` | Wybór elementu klikalnego | **Kontekstowe**, Volt |
| slider | `h` / `l` | Ruch po suwaku | **Kontekstowe** |
| paleta | `Ctrl-s` | Zapis/wybór koloru | **Kontekstowe**; w tmux wyślij `Ctrl-s Ctrl-s` |
| UI | `q` / `Esc` | Zamknięcie | **Kontekstowe** |

**Wymagania:** `volt`, prawidłowe kolory terminala.

**Szybki tutorial:** wpisz `:Huefy`, przechodź elementy `Tab`, ustawiaj suwaki `h/l`, a kolor zatwierdź dosłownym `Ctrl-s`.

### Infrastruktura tej grupy

| Nazwa lockfile | Rola | Interfejs |
|---|---|---|
| `nvim-web-devicons` | Ikony plików dla UI, drzewa i pickerów | **Biblioteka bez UI**; użyteczne polecenie testowe `:NvimWebDeviconsHiTest` |
| `plenary.nvim` | Narzędzia Lua, procesy i test harness dla Neogit/Diffview/Telescope | **Biblioteka bez UI**; polecenia testowe to `:PlenaryBustedFile {path}` i `:PlenaryBustedDirectory {path}`, a `<Plug>PlenaryTestFile` nie ma przypisanego lokalnego klawisza |
| `nui.nvim` | Komponenty UI wymagane przez CodeDiff | **Biblioteka bez UI** |
| `nvim-nio` | Asynchroniczna biblioteka wymagana przez nvim-dap-ui | **Biblioteka bez UI** |

</details>

<details>
<summary><strong>Wcięcia, formatowanie, lint i Mason</strong></summary>

### `indent-blankline.nvim`

**Co robi i po co:** rysuje pionowe prowadnice wcięć i bieżącego scope, dzięki czemu łatwiej śledzić zagnieżdżenie. Ładuje się po jednorazowym evencie `User FilePost` dla realnego pliku.

**Konfiguracja lokalna:** znak `│`, grupy `IblChar` i `IblScopeChar`, ukrycie pierwszego poziomu spacji oraz cache Base46 z kolorami awaryjnymi, gdy cache nie istnieje.

**Mapowania:** brak aktywnych i brak domyślnych.

**Polecenia:** `:IBLEnable`, `:IBLDisable`, `:IBLToggle`, `:IBLEnableScope`, `:IBLDisableScope`, `:IBLToggleScope`.

**Szybki tutorial:** otwórz zagnieżdżony plik, ustaw kursor wewnątrz bloku, porównaj scope przed i po `:IBLToggleScope`; całe prowadnice przełącz `:IBLToggle`.

### `conform.nvim`

**Co robi i po co:** uruchamia zewnętrzne formatery i zachowuje pozycję kursora lepiej niż ręczne filtrowanie bufora. Ładuje się na `BufWritePre`; użycie `<leader>fm` może go też doładować przez moduł Lazy.

**Konfiguracja lokalna:** Lua używa `stylua`; Python kolejno `ruff_fix` i `ruff_format`. Zapis ma timeout 3000 ms i `lsp_fallback=true`. `<leader>fm` działa w `n,x` i również ma fallback LSP.

**Polecenie:** `:ConformInfo` pokazuje aktywne formatery i ścieżkę logu. Wtyczka nie instaluje domyślnych mapowań.

**Wymagania:** `stylua` i `ruff` w `PATH`; dla innych języków serwer LSP z formatowaniem. Oba narzędzia są w `Brewfile`, a mogą też pochodzić z Mason.

**Szybki tutorial:** zaznacz fragment i użyj `<leader>fm`; zapisz plik, uruchom `:ConformInfo` i sprawdź, czy użyty był zewnętrzny formatter czy LSP.

### `nvim-lint`

**Co robi i po co:** asynchronicznie publikuje diagnostykę narzędzi spoza LSP. Ładuje się przed odczytem lub utworzeniem pliku.

**Konfiguracja lokalna:** tylko Python i `mypy`, uruchamiane na `BufWritePost`. Jeśli `mypy` nie jest wykonywalne, lint jest pomijany, a jedna sesyjna notyfikacja wyjaśnia przyczynę. Wtyczka nie tworzy mapowań ani publicznego polecenia Ex; `lint.try_lint()` to API Lua, nie polecenie użytkownika.

**Wymagania:** `mypy` w `PATH` dla lintowania; bez niego konfiguracja nadal działa bez błędu.

**Szybki tutorial:** zapisz plik Python, przejdź po wynikach `[d` / `]d` albo otwórz `<leader>ds`. Gdy nic się nie pojawia, sprawdź `:messages` i `:echo executable('mypy')`.

### `mason.nvim`

**Co robi i po co:** instaluje niezależne od Neovim serwery LSP, formatery, lintery i adaptery DAP. Nie konfiguruje ich użycia, tylko dostarcza executable.

**Ładowanie lokalne:** Lazy reaguje początkowo na `:Mason`, `:MasonInstall`, `:MasonUpdate`. Po załadowaniu rejestrowane są też pozostałe polecenia. `PATH="skip"`, bo `.zshrc` już dodaje `~/.local/share/nvim/mason/bin`; maksymalnie 10 instalatorów działa równolegle.

**Polecenia:** `:Mason`, `:MasonInstall {pakiet...}`, `:MasonUpdate`, `:MasonUninstall {pakiet...}`, `:MasonUninstallAll`, `:MasonLog`; NvChad dodaje `:MasonInstallAll`.

| UI Mason | Klawisz | Działanie | Stan |
|---|---|---|---|
| pakiet | `Enter` | Rozwinięcie pakietu lub logu instalacji | **Domyślne wtyczki** |
| pakiet | `i` | Instalacja | **Domyślne wtyczki** |
| pakiet | `u` | Ponowna instalacja/aktualizacja | **Domyślne wtyczki** |
| pakiet | `c` | Sprawdzenie nowej wersji | **Domyślne wtyczki** |
| globalnie | `U` | Aktualizacja wszystkich zainstalowanych | **Domyślne wtyczki** |
| globalnie | `C` | Sprawdzenie wszystkich przestarzałych | **Domyślne wtyczki** |
| pakiet | `X` | Odinstalowanie | **Domyślne wtyczki** |
| instalacja | `Ctrl-c` | Anulowanie | **Domyślne wtyczki** |
| lista | `Ctrl-f` | Filtr języka | **Domyślne wtyczki** |
| UI | `g?` | Pomoc | **Domyślne wtyczki** |

**Bezpieczeństwo:** `X` usuwa pakiet i może natychmiast przerwać LSP/formatowanie/debugowanie zależne od jego executable.

**Szybki tutorial:** otwórz `:Mason`, wpisz `/` lub użyj filtra języka, ustaw kursor na pakiecie i naciśnij `i`. Po instalacji sprawdź `:checkhealth vim.lsp`, `:ConformInfo` albo `:DapShowLog` zależnie od narzędzia.

</details>

<details>
<summary><strong>LSP, completion, snippety i automatyczne pary</strong></summary>

### `nvim-lspconfig`

**Co robi i po co:** `neovim/nvim-lspconfig` dostarcza definicje konfiguracji serwerów dla wbudowanego klienta LSP Neovim. Nie jest osobnym frameworkiem mapowań. Lokalna konfiguracja używa API Neovim 0.12 `vim.lsp.config()` i `vim.lsp.enable()`.

**Ładowanie lokalne:** `BufReadPre` lub `BufNewFile`, z zależnością `cmp-nvim-lsp`. Wildcard config dodaje możliwości completion i wyłącza semantic tokens, aby uniknąć konfliktu z Treesitter. Autocmd `LspAttach` tworzy mapowania buffer-local.

| Serwer włączony lokalnie | Filetype/cel | Wymagane executable lub pakiet |
|---|---|---|
| `lua_ls` | Lua/Neovim | `lua-language-server` |
| `html` | HTML | `vscode-html-language-server`, pakiet Mason `html-lsp` |
| `cssls` | CSS | `vscode-css-language-server`, pakiet Mason `css-lsp` |
| `pyright` | Typy Python i hover | `pyright-langserver`, pakiet `pyright` |
| `ruff` | Lint/fix/format Python, bez hover | `ruff` |
| `ts_ls` | JavaScript/TypeScript/React | `typescript-language-server` oraz `typescript`; lokalny `node_modules/.bin` ma pierwszeństwo |
| `dockerls` | Dockerfile | pakiet `dockerfile-language-server` |
| `docker_compose_language_service` | Compose | pakiet `docker-compose-language-service` |

`lua_ls` zna runtime Neovim, typy NvChad, kod lazy.nvim i bibliotekę luv. `ts_ls` preferuje nierelatywne aliasy z `tsconfig`. Pyright nie zgłasza lokalnie nieużywanych importów/zmiennych, bo ten obszar należy do Ruff; Ruff ma wyłączony hover.

#### Aktywne mapowania lokalne LSP

| Tryb | Klawisz | Działanie |
|---|---|---|
| `n` | `gD`, `gd`, `gr` | Deklaracja, definicja, referencje w Telescope |
| `n,x` | `<leader>ca` | Akcje kodu i refaktoryzacje |
| `n` | `<leader>lr` | Wbudowany restart klientów bieżącego bufora |
| `n` | `<leader>wa`, `<leader>wr`, `<leader>wl` | Dodaj, usuń, wypisz foldery workspace |
| `n` | `<leader>D` | Definicja typu |
| `n` | `<leader>ra` | Rename przez NvChad |
| `n`, tylko `ts_ls` | `gS`, `<leader>ci` | Source definition; akcje źródłowe całego pliku |

#### Wbudowane mapowania Neovim 0.12

| Tryb | Klawisz | Działanie | Stan |
|---|---|---|---|
| `n` | `grn` | Rename | **Domyślne wtyczki**: w rzeczywistości domyślne Neovim |
| `n,x` | `gra` | Code action | **Domyślne wtyczki**: Neovim |
| `n` | `gri` | Implementation | **Domyślne wtyczki**: Neovim |
| `n` | `grr` | References bez lokalnego pickera | **Domyślne wtyczki**: Neovim |
| `n` | `grt` | Type definition | **Domyślne wtyczki**: Neovim |
| `n` | `grx` | Uruchomienie code lens | **Domyślne wtyczki**: Neovim |
| `n` | `gO` | Symbole dokumentu | **Domyślne wtyczki**: Neovim |
| `i,s` | `Ctrl-s` | Signature help | **Domyślne wtyczki**: Neovim; konflikt z prefixem tmux |
| `n`, po attach | `K` | Hover, jeśli nie zastąpiono `keywordprg`/mapowania | **Kontekstowe** |
| `i`, po attach | `Ctrl-x Ctrl-o` | Wbudowane omnifunc completion LSP | **Kontekstowe** |
| `n`, po attach | `Ctrl-]`, `Ctrl-w ]`, `Ctrl-w }` | Nawigacja tagfunc przez LSP | **Kontekstowe** |
| `n,x`, po attach | `gq` | Format przez formatexpr LSP, jeśli wspierane | **Kontekstowe** |

Wbudowane diagnostyki: `[d`, `]d`, `[D`, `]D`, `Ctrl-w d`, `Ctrl-w Ctrl-d`. Lokalna konfiguracja zachowuje ich implementację Neovim 0.12 i dodaje `<leader>dd`, `<leader>ds`, `<leader>q`.

**Polecenia Neovim 0.12:** `:lsp enable [config]`, `:lsp disable [config]`, `:lsp restart [client]`, `:lsp stop [client]`, `:checkhealth vim.lsp`. Gdy wbudowane `:lsp` istnieje, przypięty lspconfig nie rejestruje starszych aliasów `:LspInfo`, `:LspStart`, `:LspStop` ani `:LspRestart`. TypeScript tworzy buffer-local `:LspTypescriptSourceAction` i `:LspTypescriptGoToSourceDefinition`. Pyright tworzy buffer-local `:LspPyrightOrganizeImports` oraz `:LspPyrightSetPythonPath {path}`.

**Wymagania:** Neovim 0.12 dla używanego interfejsu i restartu, executable serwerów w `PATH`, poprawny root projektu. Dla TypeScript zalecany jest `tsconfig.json`/`jsconfig.json` oraz lockfile menedżera pakietów.

**Szybki tutorial:** otwórz plik, uruchom `:checkhealth vim.lsp`, sprawdź `gd`, `K` i `<leader>ca`; w TypeScript użyj `<leader>ci`, a po zmianie konfiguracji serwera `<leader>lr`.

### `nvim-cmp`

**Co robi i po co:** silnik popupu completion. Ładuje się przy `InsertEnter`, łączy semantyczne propozycje LSP, snippety, API Neovim, słowa bufora i ścieżki.

**Konfiguracja lokalna:** `completeopt=menu,menuone`; potwierdzenie ma zachowanie Insert i `select=true`. Menu pokazuje dostawcę. Pierwsza grupa ma `nvim_lsp` z priorytetem 1000 i `luasnip` 750. Dopiero gdy grupa podstawowa nie daje kandydatów, używana jest grupa `nvim_lua` 500, `buffer` 250, `async_path` 200. Integracja nvim-autopairs działa po `confirm_done`.

| Tryb | Klawisz | Działanie |
|---|---|---|
| `i` | `Ctrl-p` / `Alt-k`, `Ctrl-n` / `Alt-j` | Poprzedni / następny kandydat |
| `i` | `Ctrl-d` / `Ctrl-f` | Dokumentacja w górę / w dół |
| `i` | `Ctrl-Spacja`, `Ctrl-e`, `Enter` | Otwórz, zamknij, zatwierdź |
| `i,s` | `Tab`, `Shift-Tab` | Kandydat lub placeholder snippetu |

Wtyczka nie instaluje użytecznych domyślnych mapowań bez konfiguracji; upstreamowe presety są szablonami. **Polecenie:** `:CmpStatus` wypisuje status źródeł.

**Szybki tutorial:** wpisz początek symbolu, sprawdź etykietę `[LSP]`, wybierz `Alt-j`, przejrzyj opis `Ctrl-f` i zatwierdź `Enter`. Do ręcznego wywołania użyj `Ctrl-Spacja`.

### `LuaSnip`

**Co robi i po co:** rozwija snippety i utrzymuje placeholdery. Ładuje się jako zależność nvim-cmp; historia snippetów jest włączona, a placeholdery aktualizują się na `TextChanged` i `TextChangedI`.

**Ładowanie snippetów:** lokalna konfiguracja ładuje format VS Code na żądanie, a formaty SnipMate i Lua z domyślnych oraz opcjonalnych ścieżek. `friendly-snippets` dostarcza kolekcję VS Code. Po wyjściu z Insert nieaktywny snippet jest odłączany, aby nie pozostawić uszkodzonego stanu.

**Aktywne lokalne:** `Tab` i `Shift-Tab` w `i,s` przez nvim-cmp. LuaSnip tworzy cele `<Plug>`, ale żaden dodatkowy bezpośredni klawisz nie jest tu przypisany.

**Polecenia:** `:LuaSnipUnlinkCurrent`, `:LuaSnipListAvailable`. Wzmiankowane w dokumentacji mapowanie edytora snippetów nie jest w tej rewizji zarejestrowanym poleceniem użytkownika.

**Szybki tutorial:** wpisz trigger snippetu, wybierz pozycję `[Snippet]`, zatwierdź i przechodź pola `Tab`; `Shift-Tab` wraca. `:LuaSnipListAvailable` pomaga znaleźć dostępne triggery.

### Dostawcy completion i snippetów

| Nazwa lockfile | Rola | Stan |
|---|---|---|
| `cmp-nvim-lsp` | Możliwości klienta i kandydaci LSP, w tym additional text edits dla auto-importów | **Biblioteka bez UI** |
| `cmp_luasnip` | Kandydaci z LuaSnip | **Biblioteka bez UI** |
| `cmp-nvim-lua` | API Lua Neovim | **Biblioteka bez UI** |
| `cmp-buffer` | Słowa z bufora | **Biblioteka bez UI** |
| `cmp-async-path` | Asynchroniczne ścieżki plików | **Biblioteka bez UI** |
| `friendly-snippets` | Gotowe snippety VS Code | **Biblioteka bez UI** |

Żaden z tych providerów nie ma własnych aktywnych mapowań ani publicznych poleceń Ex.

### `nvim-autopairs`

**Co robi i po co:** domyka nawiasy i cudzysłowy, obsługuje pary przy Backspace/Enter i integruje się z completion. Ładuje się z nvim-cmp.

**Konfiguracja lokalna:** `fast_wrap={}` włącza FastWrap. Wtyczka jest wyłączona dla `TelescopePrompt` i filetype `vim`. Domyślne mapowanie `Ctrl-h` do usuwania pary oraz `Ctrl-w` do usuwania słowa-pary są wyłączone.

| Tryb | Klawisz | Działanie | Stan |
|---|---|---|---|
| `i` | znaki otwierające | Automatyczne dodanie pary | **Kontekstowe** |
| `i` | `Backspace` | Usunięcie pustej pary | **Domyślne wtyczki** |
| `i` | `Enter` | Inteligentna nowa linia między parami | **Domyślne wtyczki**; nvim-cmp przekazuje fallback, a confirm ma integrację |
| `i` | `Alt-e` | FastWrap istniejącego tekstu | **Kontekstowe**, aktywne przez lokalne `fast_wrap` |
| `i` | `Ctrl-h`, `Ctrl-w` | Specjalne usuwanie par | **Warunkowe/wyłączone** |

Brak publicznych poleceń Ex.

**Szybki tutorial:** wpisz `(` i tekst, użyj `Alt-e`, a potem wybierz wskazany punkt docelowy, aby przesunąć zamykający nawias. W pustej parze naciśnij `Backspace`, aby usunąć oba znaki.

</details>

<details>
<summary><strong>Telescope i nvim-tree</strong></summary>

### `telescope.nvim`

**Co robi i po co:** fuzzy finder plików, tekstu, buforów, pomocy, Git i LSP. Ładuje się po `:Telescope` albo po jednym z lokalnych mapowań.

**Konfiguracja lokalna:** układ 87% szerokości i 80% wysokości, prompt u góry, preview 55%, wyniki rosnąco. Pliki ukryte są widoczne, `.git/` jest ignorowane, `live_grep` dodaje `--hidden`. Lokalne mapowania pickerów: `Alt-j`, `Alt-k` w Insert i `q` w Normal.

**Aktywne launchery:** `<leader>ff`, `<leader>fa`, `<leader>fw`, `<leader>fW`, `<leader>fb`, `<leader>fh`, `<leader>ma`, `<leader>fo`, `<leader>fz`, `<leader>fZ`, `<leader>cm`, `<leader>gt`; `<leader>th` korzysta z powiązanego pickera NvChad.

#### Domyślne klawisze pickera

| Tryb | Klawisz | Działanie |
|---|---|---|
| `i` | `Ctrl-n` / `Down`, `Ctrl-p` / `Up` | Następny / poprzedni wynik |
| `i,n` | `Enter` | Domyślna akcja pickera |
| `i,n` | `Ctrl-x`, `Ctrl-v`, `Ctrl-t` | Split poziomy, split pionowy, nowa karta |
| `i,n` | `Ctrl-u`, `Ctrl-d` | Preview w górę / w dół |
| `i,n` | `Ctrl-f`, `Ctrl-k` | Preview w lewo / w prawo |
| `i,n` | `PageUp`, `PageDown` | Lista wyników w górę / w dół |
| `i,n` | `Alt-f`, `Alt-k` | Lista wyników w lewo / w prawo; lokalne `Alt-k` w `i` nadpisuje to ruchem wyboru |
| `i,n` | `Tab`, `Shift-Tab` | Zaznacz i idź do gorszego / lepszego wyniku |
| `i,n` | `Ctrl-q` | Wszystkie wyniki do quickfix i otwarcie listy |
| `i,n` | `Alt-q` | Tylko zaznaczone wyniki do quickfix i otwarcie listy |
| `i` | `Ctrl-/` lub kod `Ctrl-_` | Podgląd mapowań |
| `i` | `Ctrl-c` | Zamknięcie |
| `i` | `Ctrl-r Ctrl-w/a/f/l` | Wstawienie bieżącego word/WORD/pliku/wiersza do promptu |
| `n` | `j/k`, `H/M/L`, `gg/G` | Ruch i skoki po wynikach |
| `n` | `?`, `Esc`, lokalne `q` | Pomoc / zamknięcie |

#### Git pickery

| Picker | Klawisz | Dokładna akcja |
|---|---|---|
| `git_commits` (`<leader>cm`) | `Enter` | `git checkout` wybranego commita, zwykle detached `HEAD` |
| `git_commits` | `Ctrl-r m` | Potwierdzony `git reset --mixed` do commita: przesuwa `HEAD`, resetuje indeks, zachowuje pliki robocze |
| `git_commits` | `Ctrl-r s` | Potwierdzony `git reset --soft`: przesuwa `HEAD`, zachowuje indeks i pliki robocze |
| `git_commits` | `Ctrl-r h` | Potwierdzony `git reset --hard`: przesuwa `HEAD` i odrzuca śledzone zmiany indeksu oraz drzewa roboczego |
| `git_status` (`<leader>gt`) | `Tab` | Stage albo unstage zaznaczonego pliku; zastępuje tu zwykły multiselect |
| `git_status` | `Enter` | Otwarcie pliku |
| `git_branches` | `Enter`, `Ctrl-t`, `Ctrl-r`, `Ctrl-a`, `Ctrl-s`, `Ctrl-d`, `Ctrl-y` | Checkout, track, rebase, utwórz, `git switch`, usuń, merge; w tmux `Ctrl-s` wymaga `Ctrl-s Ctrl-s` |

**Polecenie:** `:Telescope {builtin} [opcje]`, na przykład `:Telescope resume`, `:Telescope lsp_references`, `:Telescope git_branches`. To jedno publiczne polecenie udostępnia builtiny i rozszerzenia.

**Wymagania:** Neovim co najmniej 0.10.4, `ripgrep` dla live grep, `fd` dla szybkiego find files, Git dla pickerów Git. Wszystkie trzy executable są przewidziane przez środowisko repo.

**Szybki tutorial:** użyj `<leader>fW`, zawęź wynik, otwórz `Ctrl-v`; zaznacz kilka wyników `Tab`, wyślij je `Alt-q` i nawiguj `[q` / `]q`.

### `nvim-tree.lua`

**Co robi i po co:** boczne drzewo plików z ikonami, statusem Git i operacjami plikowymi. Netrw jest wyłączone. Wtyczka ładuje się po lokalnych klawiszach albo poleceniach.

**Konfiguracja lokalna:** lewa strona, szerokość 35, synchronizacja root z cwd, śledzenie aktywnego pliku bez zmiany root, Git włączony, `.DS_Store` i `.git` w filtrze niestandardowym. Watchery ignorują `.next`, `node_modules`, `.git`. Otwieranie pliku nie zamyka drzewa.

**Aktywne lokalne:** `<leader>e` toggle, `<leader>E` reveal bieżącego pliku; w drzewie fizyczne `Cmd-\` i `Cmd--` otwierają pionowy/poziomy split. Wszystkie poniższe defaulty są instalowane przed lokalnymi dodatkami.

| Klawisz w drzewie | Działanie |
|---|---|
| `Enter` / `o` | Otwórz; `O` otwiera bez wyboru okna; `Tab` preview |
| `Ctrl-v` / `Ctrl-x` / `Ctrl-t` | Split pionowy / poziomy / karta |
| `Ctrl-]` | Ustaw root na node; `-` root wyżej; `P` rodzic |
| `Ctrl-e` | Otwórz node w miejscu bufora drzewa |
| `Ctrl-k` | Informacje o node |
| `Backspace` | Zamknij katalog; `E` rozwiń wszystko; `W` zwiń wszystko |
| `>` / `<`, `J` / `K` | Następny/poprzedni oraz ostatni/pierwszy sibling |
| `a` | Utwórz plik lub katalog |
| `r`, `e`, `u`, `Ctrl-r` | Rename pełny, basename, pełna ścieżka, bez nazwy pliku |
| `c`, `x`, `p` | Copy, cut, paste |
| `d` / `Del`, `D` | Usuń / przenieś do kosza |
| `y`, `Y`, `gy`, `ge` | Nazwa, ścieżka względna, absolutna, basename |
| `m`, `bd`, `bt`, `bmv` | Bookmark; usuń, trash, przenieś zaznaczone bookmarki |
| `H` | Przełącz filtr dotfiles |
| `I` | Przełącz filtr `.gitignore` |
| `U` | Przełącz filtr **niestandardowy**, opisany w UI jako Hidden; lokalnie odsłania/chowa `.DS_Store` i `.git`, nie wszystkie dotfiles |
| `B`, `C`, `M` | Filtry no-buffer, git-clean, no-bookmark |
| `[c` / `]c` | Poprzedni / następny wpis Git |
| `[e` / `]e` | Poprzednia / następna diagnostyka |
| `f` / `F` | Start / wyczyszczenie live filter |
| `L` | Przełącz grupowanie pustych katalogów |
| `.` | Prompt polecenia; `s` uruchom program systemowy; `S` wyszukaj node |
| `R` | Odśwież; `q` zamknij; `g?` pomoc |
| `2-LeftMouse` / `2-RightMouse` | Otwórz / ustaw root |

**Polecenia:** `:NvimTreeOpen [dir]`, `:NvimTreeClose`, `:NvimTreeToggle [dir]`, `:NvimTreeFocus`, `:NvimTreeRefresh`, `:NvimTreeClipboard`, `:NvimTreeFindFile[!]`, `:NvimTreeFindFileToggle[!] [dir]`, `:NvimTreeResize {width}`, `:NvimTreeCollapse`, `:NvimTreeCollapseKeepBuffers`, `:NvimTreeHiTest`. Początkowymi triggerami Lazy są tylko `NvimTreeToggle`, `NvimTreeFocus` i `NvimTreeFindFile`; pozostałe polecenia pojawiają się po załadowaniu wtyczki.

**Bezpieczeństwo:** `d`, `Del`, `D`, `bd` i `bt` usuwają albo przenoszą pliki; sprawdź node i potwierdzenie. Cut nie zmienia dysku do `p`, lecz wynik paste może nadpisać/kolizjonować.

**Wymagania:** `nvim-web-devicons` i Nerd Font dla ikon, Git dla statusów.

**Szybki tutorial:** `<leader>E` odsłania plik, `a` tworzy nowy, `Ctrl-v` otwiera obok, `H/I/U` diagnozują brakujący wpis, a `g?` pokazuje mapowania tej konkretnej wersji.

</details>

<details>
<summary><strong>Treesitter, autotag i Markdown</strong></summary>

### `nvim-treesitter`

**Co robi i po co:** instaluje przypięte parsery i uruchamia wbudowane podświetlanie oraz, gdy istnieje query, indent Treesitter. To gałąź `main` po przepisaniu API dla Neovim 0.12.

**Ładowanie lokalne:** `lazy=false`, bo ta wersja nie wspiera lazy-loadingu; build wykonuje `:TSUpdate`. Setup instaluje parsery i przy `FileType` wywołuje `vim.treesitter.start`.

**Konfigurowany zestaw parserów:** `lua`, `luadoc`, `printf`, `vim`, `vimdoc`, `go`, `python`, `typescript`, `tsx`, `javascript`, `html`, `markdown`, `markdown_inline`.

**Filetype z automatycznym startem:** `lua`, `vim`, `help`, `go`, `python`, `typescript`, `typescriptreact`, `javascript`, `javascriptreact`, `html`, `markdown`. Język `tsx` jest zarejestrowany dla `typescriptreact`.

**Polecenia:** `:TSInstall[!] {language...}`, `:TSInstallFromGrammar[!] {language...}`, `:TSUpdate [language...]`, `:TSUninstall {language...}`, `:TSLog`. Wariant `!` nadal wymaga co najmniej jednej nazwy języka.

**Mapowania:** ta konfiguracja nie włącza modułu incremental selection i nie instaluje żadnej tabeli skrótów selekcji. Nie należy przenosić mapowań ze starego API do tej rewizji.

**Wymagania:** Neovim 0.12+, `curl`, `tar`, kompilator C/C++ oraz `tree-sitter-cli >= 0.26.1`. Przypięta gałąź `main` używa `tree-sitter build` również przy zwykłej instalacji parsera. Po aktualizacji wtyczki parsery trzeba zaktualizować.

**Szybki tutorial:** uruchom `:TSInstall html markdown markdown_inline`, otwórz HTML/Markdown i sprawdź `:InspectTree`; po zmianie rewizji wykonaj `:TSUpdate`.

### `nvim-ts-autotag`

**Co robi i po co:** na podstawie Treesitter domyka tag po wpisaniu `>`, a po zmianie nazwy jednego tagu aktualizuje jego parę. Przydaje się w HTML, JSX/TSX, Vue, Svelte, XML, Markdown z HTML i innych wspieranych gramatykach.

**Ładowanie lokalne:** `BufReadPre` i `BufNewFile`, opcje domyślne. `enable_close=true`, `enable_rename=true`, `enable_close_on_slash=false`.

| Kontekst | Klawisz/zachowanie | Działanie | Stan |
|---|---|---|---|
| wspierany filetype, `i` | `>` | Wstaw znak i domknij tag, gdy drzewo składniowe wskazuje start tag | **Kontekstowe** |
| wspierany filetype | wyjście z Insert | Rename sparowanego tagu | **Kontekstowe** |
| `i` | `/` | Automatyczne domknięcie po `</` | **Warunkowe/wyłączone** lokalnie |

Brak publicznych poleceń Ex i dodatkowych globalnych mapowań.

**Wymagania:** Neovim co najmniej 0.9.5 oraz parser odpowiadający filetype. Bieżąca konfiguracja zapewnia `html`; zapewnia też TSX, JavaScript i Markdown.

**Szybki tutorial:** w HTML wpisz `<section>` i obserwuj dopisanie `</section>`; wykonaj `ciwarticle`, wyjdź z Insert i sprawdź zmianę drugiego tagu.

### `render-markdown.nvim`

**Co robi i po co:** renderuje nagłówki, listy, kod, checkboxy, tabele i callouty Markdown bez zmiany tekstu pliku. Ładuje się tylko dla filetype `markdown`.

**Konfiguracja lokalna:** renderowanie domyślnie aktywne, limit pliku 10 MB, tryby `n`, `c`, `v`, `i`, domyślne ikony nagłówków, lokalnie ustawione ikony list oraz code block o szerokości `block` z nazwą języka. Mapowanie Markdown-only `<leader>mr` wywołuje `RenderMarkdown buf_toggle`.

**Polecenia:** `:RenderMarkdown`, `:RenderMarkdown enable`, `buf_enable`, `disable`, `buf_disable`, `toggle`, `buf_toggle`, `get`, `set [true|false]`, `set_buf [true|false]`, `preview`, `log`, `expand`, `contract`, `debug`, `config`.

Wtyczka nie ma własnych domyślnych mapowań. `<leader>mr` jest **Aktywne lokalne** i ograniczone do Markdown.

**Wymagania:** parsery Treesitter `markdown` i `markdown_inline`; ikony korzystają z Nerd Font.

**Szybki tutorial:** otwórz README, naciśnij `<leader>mr`, porównaj tekst surowy i renderowany, użyj `:RenderMarkdown preview` do widoku obok oraz `:RenderMarkdown config` do diagnozy opcji.

</details>

<details>
<summary><strong>Git: Gitsigns, Unified i Neogit</strong></summary>

### `gitsigns.nvim`

**Co robi i po co:** pokazuje dodane, zmienione i usunięte linie w signcolumn oraz blame bieżącego wiersza. Jest lekkim podglądem zmian bieżącego pliku, nie pełnym klientem Git.

**Ładowanie lokalne:** `User FilePost`. Lokalne znaki zmieniają ikonę delete i changedelete. `current_line_blame=true`, opóźnienie 300 ms, tekst na końcu wiersza.

**Aktywne mapowania:** brak globalnych lub buffer-local z konfiguracji. Gitsigns nie instaluje domyślnej warstwy klawiszy. Popup otwarty przez akcję ma kontekstowe `q` do zamknięcia.

**Polecenie:** `:Gitsigns {subcommand}`. Użyteczne subcommandy przypiętej rewizji: `stage_hunk`, `stage_buffer`, `reset_hunk`, `reset_buffer`, `preview_hunk`, `preview_hunk_inline`, `nav_hunk next`, `nav_hunk prev`, `blame`, `blame_line`, `toggle_current_line_blame`, `change_base`, `diffthis`, `toggle_word_diff`, `setqflist`, `setloclist`, `show`, `toggle_signs`, `toggle_numhl`, `toggle_linehl`.

> `reset_hunk` i `reset_buffer` odrzucają zmiany. `stage_hunk` na znaku staged działa w tej wersji jak cofnięcie stage danego hunka.

#### README: przykład, który nie jest aktywny

Poniższe klawisze są **Przykładem nieaktywnym**, bo lokalny `configs/gitsigns.lua` nie definiuje `on_attach`:

| Przykład | Akcja proponowana upstream |
|---|---|
| `]c` / `[c` | Następny / poprzedni hunk; w oknie diff delegacja do wbudowanego ruchu diff |
| `<leader>hs` w `n,v` | Stage hunka / zakresu |
| `<leader>hr` w `n,v` | Reset hunka / zakresu |
| `<leader>hS` / `<leader>hR` | Stage / reset bufora |
| `<leader>hp` / `<leader>hi` | Preview zwykły / inline |
| `<leader>hb` | Pełny blame wiersza |
| `<leader>hd` / `<leader>hD` | Diff z indeksem / poprzednim commitem |
| `<leader>hQ` / `<leader>hq` | Quickfix całego repo / bieżącego bufora |
| `<leader>tb` / `<leader>tw` | Blame bieżącej linii / word diff |
| `ih` w `o,x` | Text object hunka |

**Wymagania:** plik w repozytorium Git; signcolumn jest globalnie włączone.

**Szybki tutorial:** zmień plik, obserwuj gutter i blame, uruchom `:Gitsigns preview_hunk_inline`, przejdź `:Gitsigns nav_hunk next`, a po przeglądzie stage'uj bezpiecznie przez Neogit lub `:Gitsigns stage_hunk`.

### `unified.nvim`

**Co robi i po co:** pokazuje unified diff bezpośrednio w zwykłym buforze i otwiera boczne drzewo zmienionych plików. Dobrze nadaje się do szybkiego przeglądu bez dwóch kolumn.

**Ładowanie lokalne:** po `:Unified` lub `<leader>gd`, z domyślnymi opcjami i auto-refresh.

**Aktywne lokalne:** `<leader>gd` przełącza widok.

| Drzewo Unified | Działanie | Stan |
|---|---|---|
| `j` / `Down`, `k` / `Up` | Następny / poprzedni plik, z pominięciem węzłów katalogu | **Domyślne wtyczki** |
| `l` | Otwórz/przełącz node i diff pliku | **Domyślne wtyczki** |
| `R` | Odśwież | **Domyślne wtyczki** |
| `q` | Zamknij drzewo | **Domyślne wtyczki** |
| `?` | Pomoc; w pomocy `Spacja`, `q`, `Enter`, `Esc` zamykają | **Domyślne wtyczki** |

**Polecenia:** `:Unified`, `:Unified {commit_ref}`, `:Unified reset`.

Upstream pokazuje własne mapowania nawigacji i stage/unstage/revert hunka jako **Przykład nieaktywny**. API hunk actions nie jest poleceniem Ex ani lokalnym mapowaniem.

**Wymagania:** Neovim, Git i Nerd Font dla ikon.

**Szybki tutorial:** naciśnij `<leader>gd`, wybieraj pliki `j/k`, otwieraj `l`, a po zakończeniu ponownie `<leader>gd`. Do porównania z rewizją wpisz `:Unified HEAD~1`.

### `neogit`

**Co robi i po co:** pełny, inspirowany Magit klient Git: status, staging hunka/pliku, commit, branch, pull/push, log, rebase i stash. Lokalnie otwiera się w nowej karcie i integruje z Telescope oraz Diffview.

**Ładowanie lokalne:** po `:Neogit` lub lokalnych `<leader>gg`, `<leader>gc`, `<leader>gp`, `<leader>gP`, `<leader>gb`. File watcher odświeża status, hinty są widoczne, graf jest Unicode, commit editor otwiera kartę i pokazuje staged diff.

**Polecenia:** `:Neogit [kind]`, `:NeogitResetState`, `:NeogitLogCurrent [path]` także z zakresem, `:NeogitCommit [sha]`.

#### Finder Neogit: dokładne defaulty

| Klawisz | Akcja |
|---|---|
| `Enter` | `Select` |
| `Ctrl-c` / `Esc` | `Close` |
| `Ctrl-n` / `Down` | `Next` |
| `Ctrl-p` / `Up` | `Previous` |
| `Tab` | `InsertCompletion`, nie multiselect |
| `Ctrl-y` | `CopySelection`, nie zatwierdzenie wielu pozycji |
| `Spacja` / `Shift-Spacja` | Multiselect i ruch do następnej / poprzedniej pozycji |
| `Ctrl-j` | `NOP`, nie ruch w dół |
| `ScrollWheelDown` / `ScrollWheelUp` | Scroll w dół / górę |
| `ScrollWheelLeft` / `ScrollWheelRight` | `NOP` |
| `LeftMouse` | Wybór pozycji |
| `2-LeftMouse` | `NOP` |

#### Status Neogit: dokładne defaulty

| Klawisz | Akcja Neogit | Ryzyko/uwaga |
|---|---|---|
| `j` / `k` | `MoveDown` / `MoveUp` | Bezpieczne |
| `o` | `OpenTree` | Otwiera drzewo/element |
| `q` | `Close` | Bezpieczne |
| `I` | `InitRepo` | Inicjalizacja repo, tylko poza repo |
| `1` / `2` / `3` / `4` | Głębokość rozwinięcia 1..4 | Widok |
| `Q` | `Command` | Prompt dowolnego polecenia Git |
| `Tab` / `za` | `Toggle` sekcji/elementu | Widok |
| `zo` / `zc` | Otwórz / zamknij fold | Widok |
| `zC` / `zO` | Głębokość 1 / 4 | Widok |
| `x` | `Discard` | **Destrukcyjne**, odrzuca wskazane zmiany po przepływie potwierdzenia |
| `s` | `Stage` zaznaczenia | Zmienia indeks |
| `S` | `StageUnstaged` | Stage wszystkich unstaged |
| `Ctrl-s` | `StageAll` | Stage wszystkiego; w tmux naciśnij `Ctrl-s Ctrl-s` |
| `u` | `Unstage` zaznaczenia | Zmienia indeks, nie plik roboczy |
| `K` | `Untrack` | Usuwa z indeksu; sprawdź zamiar |
| `R` | `Rename` | Zmienia nazwę pliku |
| `U` | `UnstageStaged` | Unstage wszystkich staged |
| `y` | `ShowRefs` | Pokazuje referencje |
| `$` | `CommandHistory` | Historia poleceń Git |
| `Y` | `YankSelected` | Kopiuje zaznaczoną wartość |
| `gp` | `GoToParentRepo` | Repo nadrzędne/submodule |
| `Ctrl-r` | `RefreshBuffer` | Odświeżenie |
| `Enter` / `Shift-Enter` | `GoToFile` / `PeekFile` | Otwórz / podgląd |
| `Ctrl-v` / `Ctrl-x` / `Ctrl-t` | Otwórz w pionowym, poziomym splicie, karcie | Nawigacja |
| `{` / `}` | Poprzedni / następny nagłówek hunka | Nawigacja |
| `[c` / `]c` | `OpenOrScrollUp` / `OpenOrScrollDown` | Zmiana/hunk |
| `Ctrl-k` / `Ctrl-j` | `PeekUp` / `PeekDown` | Podgląd |
| `Ctrl-n` / `Ctrl-p` | Następna / poprzednia sekcja | Nawigacja |

#### Popupy, commit i rebase

| Kontekst | Klawisz | Akcja |
|---|---|---|
| popup | `?`, `A`, `d`, `M`, `P`, `X`, `Z` | Pomoc, cherry-pick, diff, remote, push, reset, stash |
| popup | `i`, `t`, `b`, `B`, `w` | Ignore, tag, branch, bisect, worktree |
| popup | `c`, `f`, `l`, `L`, `m`, `p`, `r`, `v` | Commit, fetch, log, margin, merge, pull, rebase, revert |
| commit editor `n,i` | `Ctrl-c Ctrl-c` | Submit |
| commit editor `n,i` | `Ctrl-c Ctrl-k` | Abort |
| commit editor `n` | `q`, `Alt-p`, `Alt-n`, `Alt-r` | Close, poprzednia/następna wiadomość, reset wiadomości |
| rebase editor `n` | `p`, `r`, `e`, `s`, `f` | Pick, reword, edit, squash, fixup |
| rebase editor `n` | `x`, `d`, `b` | Execute, drop, break |
| rebase editor `n` | `Enter`, `gk`, `gj` | Otwórz commit, przenieś pozycję w górę/dół |
| rebase editor `n,i` | `Ctrl-c Ctrl-c`, `Ctrl-c Ctrl-k` | Submit planu / abort |
| rebase editor `n` | `[c`, `]c` | `OpenOrScrollUp` / `OpenOrScrollDown` |

`d` w rebase oznacza drop commita z przepisywanej historii. `X` w popupie otwiera operacje reset. Obie ścieżki wymagają rozumienia skutków przed zatwierdzeniem.

**Wymagania:** Git, `plenary.nvim`; lokalnie także Telescope i Diffview jako aktywne integracje.

**Szybki tutorial:** `<leader>gg`, rozwiń plik lub hunk przez `Tab`, ustaw kursor na zmianie i użyj `s`; `Enter` przechodzi do realnego pliku. Uruchom commit przez `c c` albo `<leader>gc`, wpisz wiadomość i zatwierdź `Ctrl-c Ctrl-c`; push otwórz `P` lub `<leader>gp`.

</details>

<details>
<summary><strong>Git: Diffview i CodeDiff</strong></summary>

### `diffview.nvim`

**Co robi i po co:** otwiera kartę z dwu-, trzy- lub czterostronnym diffem, panelem plików, historią oraz narzędziami konfliktów. Najlepiej sprawdza się w przeglądzie wielu plików i merge/rebase.

**Ładowanie lokalne:** po poleceniach Diffview lub `<leader>gv/gm/gl/gL/gq`. Pliki binarne są pomijane, enhanced highlights włączone, panel jest drzewem po lewej o szerokości 35. Hook wyłącza foldcolumn w buforach diff.

**Aktywne lokalne:** `<leader>gv`, `<leader>gm`, `<leader>gl`, `<leader>gL`, `<leader>gq`. W samym widoku `Tab` skupia panel plików i tym samym celowo zastępuje pinned default przejścia do następnego pliku. `q` zamyka Diffview w widoku, panelu plików i panelu historii. Nawigacja oraz staging panelu korzystają z defaultów przypiętej rewizji.

**Polecenia:** `:DiffviewOpen [rev] [options] [-- paths]`, `:DiffviewFileHistory [paths] [options]`, `:DiffviewClose`, `:DiffviewFocusFiles`, `:DiffviewToggleFiles`, `:DiffviewRefresh`, `:DiffviewLog`.

#### Widok diff

| Klawisz | Działanie | Źródło |
|---|---|---|
| `Tab` | Fokus panelu plików | **Aktywne lokalne**, nadpisuje next file |
| `q` | Zamknięcie całego Diffview | **Aktywne lokalne** |
| `Shift-Tab` | Otwórz poprzedni wpis | **Domyślne wtyczki** |
| `[F` / `]F` | Pierwszy / ostatni wpis | **Domyślne wtyczki** |
| `gf` | Otwórz realny plik w poprzedniej karcie | **Domyślne wtyczki** |
| `Ctrl-w Ctrl-f` / `Ctrl-w gf` | Otwórz plik w splicie / nowej karcie | **Domyślne wtyczki** |
| `<leader>e` / `<leader>b` | Fokus / przełączenie panelu plików | **Domyślne wtyczki** |
| `g Ctrl-x` | Następny dostępny layout | **Domyślne wtyczki** |
| `[x` / `]x` | Poprzedni / następny konflikt | **Kontekstowe** |
| `<leader>co/ct/cb/ca` | Ours / theirs / base / wszystkie wersje konfliktu | **Kontekstowe** |
| `dx` | Usuń region konfliktu | **Kontekstowe**, destrukcyjne dla wyniku |
| `<leader>cO/cT/cB/cA` | Ours / theirs / base / wszystkie dla całego pliku | **Kontekstowe** |
| `dX` | Usuń wszystkie regiony konfliktów w pliku | **Kontekstowe**, destrukcyjne |

Buffer-local `<leader>ca` Diffview oznacza „wybierz wszystkie wersje konfliktu” i w tej karcie ma pierwszeństwo przed akcją kodu LSP.

#### Panel plików: pinned defaults zachowane

| Klawisz | Działanie |
|---|---|
| `j` / `Down`, `k` / `Up` | Następny / poprzedni wpis panelu |
| `Enter` / `o` / `l` / `2-LeftMouse` | Otwórz diff wpisu |
| `-` / `s` | Toggle stage/unstage zaznaczonego wpisu zależnie od sekcji |
| `S` | Stage wszystkich wpisów |
| `U` | Unstage wszystkich wpisów |
| `X` | Przywróć wpis do stanu po lewej stronie |
| `L` | Panel logu commita |
| `zo`, `h` / `zc`, `za`, `zR`, `zM` | Otwórz, zamknij, toggle, otwórz wszystkie, zamknij wszystkie foldy |
| `Ctrl-b` / `Ctrl-f` | Przewiń główny widok w górę / w dół |
| `Tab` / `Shift-Tab` | Otwórz następny / poprzedni wpis, a nie tylko zmień fokus |
| `[F` / `]F` | Pierwszy / ostatni wpis |
| `gf`, `Ctrl-w Ctrl-f`, `Ctrl-w gf` | Otwórz realny plik |
| `i` | Lista kontra drzewo |
| `f` | Flatten directories |
| `R` | Odśwież statystyki i wpisy |
| `<leader>e` / `<leader>b` | Fokus / toggle panelu |
| `g Ctrl-x`, `[x`, `]x`, `g?` | Layout, konflikty, pomoc |
| `q` | Zamknij Diffview (**Aktywne lokalne**) |

Nie ma lokalnego `u` do cofania stage pojedynczego pliku. Użyj toggle `-`/`s` na wpisie staged albo `U` dla wszystkich.

#### Panel historii i layout konfliktów

| Kontekst | Klawisz | Działanie |
|---|---|---|
| historia | `g!` | Opcje historii |
| historia | `Ctrl-Alt-d` | Otwórz zaznaczony commit w osobnym Diffview |
| historia | `y`, `L` | Kopiuj hash, pokaż szczegóły commita |
| historia | `X` | Przywróć plik do wersji wybranego wpisu, po potwierdzeniu |
| historia | `j/k`, `Enter/o/l`, foldy, scroll, `Tab/Shift-Tab`, `[F/]F` | Nawigacja analogiczna do panelu plików |
| historia | `gf`, split/tab, `<leader>e/b`, `g Ctrl-x`, `g?` | Plik, panel, layout, pomoc |
| historia | `q` | Zamknij Diffview (**Aktywne lokalne**) |
| layout diff3 `n,x` | `2do` / `3do` | Pobierz hunk z ours / theirs |
| layout diff4 `n,x` | `1do` / `2do` / `3do` | Pobierz hunk z base / ours / theirs |
| dowolny layout | `g?` | Pomoc właściwa dla layoutu |
| panel opcji | `Tab`, `q`, `g?` | Zmień opcję, zamknij, pomoc |
| panel pomocy | `q` / `Esc` | Zamknięcie |

**Bezpieczeństwo:** `X` w panelu plików lub historii może nadpisać zawartość pliku. Akcje konfliktów modyfikują wynik merge. Najpierw sprawdź stronę lewą i zachowaj kopię zmian.

**Wymagania:** Git albo Mercurial, lokalnie Git; opcjonalne ikony przez `nvim-web-devicons`.

**Szybki tutorial:** `<leader>gv`, `Tab` do panelu, `j/k` wybierz plik, `Enter` otwórz, `-` stage/unstage, `Shift-Tab` poprzedni wpis; zamknij `q` lub `<leader>gq`.

### `codediff.nvim`

**Co robi i po co:** VS Code-style side-by-side diff z osobnym podświetleniem linii i znaków, explorerem Git, historią oraz mergetool. Jest wygodny do szczegółowego przeglądu jednego hunka lub pliku.

**Ładowanie lokalne:** po `:CodeDiff` albo `<leader>gD/gf/gh`, z zależnością `nui.nvim`. Biblioteka C algorytmu diff pobiera się automatycznie przy pierwszym użyciu. Bieżąca konfiguracja nie nadpisuje highlightów i korzysta z `line_insert`, `line_delete` oraz automatycznego char highlight z defaultów wtyczki.

**Aktywne lokalne:** `<leader>gD` uruchamia `CodeDiff`; `<leader>gf` uruchamia dokładnie `CodeDiff file HEAD`; `<leader>gh` uruchamia dokładnie `CodeDiff history %`.

**Polecenie i tryby:** `:CodeDiff`, `:CodeDiff {rev}`, `:CodeDiff {rev1} {rev2}`, `:CodeDiff file {rev} [rev2]`, `:CodeDiff file {file_a} {file_b}`, `:CodeDiff dir {dir1} {dir2}`, `:CodeDiff {dir1} {dir2}`, `:CodeDiff history [range] [file]`, `:CodeDiff merge {file}`, `:CodeDiff install`, `:CodeDiff install!`. Po załadowaniu dostępny jest też zgodnościowy alias `:VscodeDiff` o tej samej składni.

#### Widok i explorer

| Kontekst | Klawisz | Dokładne działanie |
|---|---|---|
| cała karta | `q` | Zamknij kartę CodeDiff |
| explorer mode | `<leader>b` | Pokaż/ukryj explorer |
| diff | `]c` / `[c` | Następny / poprzedni hunk |
| explorer mode | `]f` / `[f` | Następny / poprzedni plik |
| modyfikowalny diff | `do` | Pobierz hunk z **drugiego** bufora do bieżącego |
| modyfikowalny diff | `dp` | Wyślij hunk z bieżącego bufora do **drugiego** |
| diff | `gf` | Otwórz realny bufor w poprzedniej karcie; wirtualna rewizja nie ma pliku do otwarcia |
| explorer mode | `-` | Stage/unstage bieżącego pliku lub wpisu; konflikt stage oznacza resolved |
| explorer | `Enter` | Wybór pliku/katalogu |
| explorer | `K` | Szczegóły/hover wpisu |
| explorer | `R` | Odświeżenie |
| explorer | `i` | Przełączenie płaskiej listy i drzewa, nie ignored files |
| explorer | `S` / `U` | Stage all / unstage all |
| explorer | `X` | Dla unstaged: discard do indeksu/HEAD; dla untracked: usuń po potwierdzeniu |
| historia | `Enter` | Rozwiń commit albo otwórz jego plik/diff |
| historia | `i` | Przełączenie listy/drzewa plików historii |

`do` i `dp` zależą od bieżącego okna, a nie od stałej etykiety ours/theirs. W trybie „plik kontra rewizja Git” bufory są readonly, więc akcja zgłosi brak modyfikowalności. Stosuj ją do porównań, w których docelowy bufor jest modyfikowalny.

#### Konflikty CodeDiff

| Klawisz | Semantyka |
|---|---|
| `<leader>ct` | Accept incoming, czyli theirs po lewej |
| `<leader>co` | Accept current, czyli ours po prawej |
| `<leader>cb` | Accept both: inteligentne połączenie zmian jak VS Code; kolejność zaczyna się od strony, na której jest kursor, a fallback konkatenacji zachowuje tę kolejność |
| `<leader>cx` | Discard obu stron konfliktu i przywrócenie zawartości **base**; działa także na wcześniej rozwiązanym bloku |
| `]x` / `[x` | Następny / poprzedni konflikt |
| `2do` w result buffer | Pobierz incoming/theirs do wyniku |
| `3do` w result buffer | Pobierz current/ours do wyniku |

W conflict mode zwykłe `do`/`dp` są usuwane, a numerowane akcje działają tylko w result buffer.

**Bezpieczeństwo:** `X` może skasować nieśledzony plik lub odrzucić unstaged. `<leader>cx` nie oznacza „usuń markery”, lecz reset konkretnego konfliktu do base. Zawsze sprawdź result buffer i zapisz go świadomie.

**Wymagania:** zapisany plik w repo Git dla trybu rewizji, `curl` albo `wget` do pobrania biblioteki C, Git dla explorera/historii.

**Szybki tutorial:** w zmienionym pliku naciśnij `<leader>gf`, przejdź hunki `]c/[c`, zamknij `q`; do wielu plików użyj `<leader>gD`, wybierz `Enter`, a stage przełącz `-`.

</details>

<details>
<summary><strong>DAP: klient, UI, virtual text, Python i Go</strong></summary>

### `nvim-dap`

**Co robi i po co:** klient Debug Adapter Protocol. Steruje breakpointami, uruchomieniem, krokami, stosami, REPL i konfiguracjami adapterów.

**Ładowanie lokalne:** po dowolnym klawiszu DAP albo publicznym poleceniu DAP. Setup konfiguruje UI, virtual text, znaki breakpoint/stop, adaptery Python i Go oraz `pwa-node`/`pwa-chrome` przez `js-debug-adapter`.

**Aktywne lokalne:** `F5`, `F10`, `F11`, `F12`, `<leader>db`, `<leader>dB`, `<leader>dc`, `<leader>de` w `n,x`, `<leader>dn`, `<leader>dp`, `<leader>dl`, `<leader>dr`, `<leader>dt`, `<leader>du`. Sam upstream nie instaluje domyślnych klawiszy.

**Polecenia przypiętej wersji:** `:DapSetLogLevel`, `:DapShowLog`, `:DapContinue`, `:DapToggleBreakpoint`, `:DapClearBreakpoints`, `:DapToggleRepl`, `:DapStepOver`, `:DapStepInto`, `:DapStepOut`, `:DapPause`, `:DapTerminate`, `:DapDisconnect`, `:DapRestartFrame`, `:DapNew`, `:DapEval`.

**Konfiguracje JS/TS lokalne:** Launch current file with Node, attach do procesu Node wybranego z listy, launch Chrome pod wpisanym URL i attach Chrome pod portem. Filetype: `javascript`, `javascriptreact`, `typescript`, `typescriptreact`. Source maps są włączone, a node internals i `node_modules` pomijane przy krokach.

**`launch.json`:** nvim-dap tej rewizji ma provider, który automatycznie czyta `./.vscode/launch.json` na żądanie. Lokalne aliasy adapterów to `pwa-node` i `pwa-chrome`. Nie trzeba wywoływać starego loadera Lua.

**Wymagania:** co najmniej jeden adapter w `PATH`; poprawna konfiguracja projektu; dla browser attach Chrome uruchomiony z remote debugging.

**Szybki tutorial:** ustaw `<leader>db`, naciśnij `F5`, wybierz konfigurację, przejdź `F10/F11`, sprawdź zmienną `<leader>de`, otwórz REPL `<leader>dr` i zakończ `<leader>dt`.

### `nvim-dap-ui`

**Co robi i po co:** panele Scopes, Stacks, Breakpoints, Watches po prawej oraz REPL i Console na dole. Lokalny listener otwiera UI po starcie sesji i zamyka po jej końcu; `<leader>du` pozwala przełączyć ręcznie.

**Konfiguracja lokalna:** prawa kolumna szerokości 40 z proporcjami 0.40/0.25/0.20/0.15, dolny panel wysokości 10 i rounded border dla floatów.

| Element UI | Klawisz | Działanie | Stan |
|---|---|---|---|
| zmienna/watch | `Enter` / `2-LeftMouse` | Rozwinięcie dzieci | **Kontekstowe** |
| stack frame | `o` | Przejście do lokalizacji | **Kontekstowe** |
| watch/breakpoint | `d` | Usunięcie pozycji | **Kontekstowe** |
| zmienna/watch | `e` | Edycja wartości lub wyrażenia | **Kontekstowe** |
| zmienna/watch | `r` | Wysłanie do REPL | **Kontekstowe** |
| stack/breakpoint | `t` | Przełączenie subtelnych ramek albo enabled breakpointu | **Kontekstowe** |
| floating element | `q` / `Esc` | Zamknięcie floata | **Domyślne wtyczki** |

Nie ma domyślnego `w` dodającego dowolne wyrażenie w panelu Watches. W Watches wejdź do Insert, wpisz wyrażenie w prompt i zatwierdź `Enter`. Kod tej rewizji ma osobną kontekstową akcję `watch` pod `w` na zmiennej w Scopes; wysyła istniejącą zmienną do Watches, a nie otwiera promptu „add watch”.

Wtyczka nie rejestruje poleceń Ex; `require("dapui").open()` i podobne nazwy są API Lua.

**Wymagania:** `nvim-dap` i `nvim-nio`.

**Szybki tutorial:** rozpocznij sesję, rozwiń scope `Enter`, wyślij zmienną do REPL `r`; w panelu Watches naciśnij `i`, wpisz `object.field`, zatwierdź i wróć `Esc`.

### `nvim-dap-virtual-text`

**Co robi i po co:** pokazuje wartości zmiennych obok kodu podczas zatrzymania. Lokalnie `commented=true`, więc tekst wygląda jak komentarz.

**Mapowania:** brak. **Polecenia:** `:DapVirtualTextEnable`, `:DapVirtualTextDisable`, `:DapVirtualTextToggle`, `:DapVirtualTextForceRefresh`.

**Wymagania:** aktywna sesja nvim-dap; Treesitter jest zależnością lokalną.

**Szybki tutorial:** zatrzymaj program na breakpointcie, porównaj wartości w wierszach, przełącz je `:DapVirtualTextToggle`; użyj force refresh tylko gdy adapter nie zgłosił zakończenia.

### `nvim-dap-python`

**Co robi i po co:** rejestruje debugpy, konfiguracje Python oraz debug testów unittest/pytest/django.

**Konfiguracja lokalna:** setup wskazuje executable `debugpy-adapter`. Interpreter programu/testu jest rozwiązywany między innymi z `VIRTUAL_ENV` lub `CONDA_PREFIX`. `<leader>dn` w Python uruchamia metodę testową nad kursorem.

**Mapowania i polecenia:** brak własnych defaultów i brak publicznych poleceń Ex. Lokalne `<leader>dn` wywołuje API test method.

**Wymagania:** `debugpy-adapter` w `PATH` albo interpreter z zainstalowanym `debugpy`; framework testowy projektu.

**Szybki tutorial:** aktywuj virtualenv, ustaw breakpoint, `F5` i wybierz Python; dla testu ustaw kursor w metodzie i naciśnij `<leader>dn`.

### `nvim-dap-go`

**Co robi i po co:** rejestruje Delve, konfiguracje debug programu/testu/attach i odnajdywanie najbliższego testu przez Treesitter.

**Konfiguracja lokalna:** domyślne `require("dap-go").setup()`. `<leader>dn` dla filetype Go uruchamia nearest test.

**Mapowania i polecenia:** brak własnych aktywnych klawiszy i publicznych poleceń Ex. README pokazuje przykładowe mapowania debug test/last test, ale są **Przykładem nieaktywnym**.

**Wymagania:** `dlv` w `PATH` i parser Treesitter Go, który jest instalowany lokalnie.

**Szybki tutorial:** w funkcji `Test...` ustaw breakpoint, naciśnij `<leader>dn`; do zwykłego programu naciśnij `F5` i wybierz konfigurację Debug.

</details>

<details>
<summary><strong>Distant i vim-tmux-navigator po stronie Neovim</strong></summary>

### `distant.nvim`

**Co robi i po co:** otwiera i zapisuje zdalne pliki przez lokalny klient i zdalny serwer Distant, zapewnia browser katalogów, shell, spawn, wyszukiwanie i podstawę dla zdalnego LSP.

**Ładowanie lokalne:** na `:DistantInstall`, `:DistantClientVersion`, `:DistantConnect`, `:DistantLaunch`, `:DistantOpen`, `:DistantShell`, `:DistantSpawn` albo lokalne `<leader>r...`. Po setup dostępne są wszystkie polecenia poniżej.

**Konfiguracja lokalna:** klient `~/.local/bin/distant`, manager bez daemona, timeout maksymalny 60 s. Domyślny launch na serwerze używa `/home/ukibbb/.local/bin/distant`; profil `raspberry` wskazuje `ukibbb@192.168.101.7`. Wildcard zdalnego LSP jest dopuszczony, lecz wymagany serwer nadal musi istnieć na hoście.

**Aktywne lokalne:** `<leader>rl`, `<leader>ro`, `<leader>rs`, `<leader>rx`, `<leader>rp`.

**Polecenia przypiętej rewizji:** `:Distant` (główne UI), `:DistantCancelSearch`, `:DistantCheckHealth`, `:DistantClientVersion`, `:DistantConnect`, `:DistantCopy`, `:DistantInstall`, `:DistantLaunch`, `:DistantMetadata`, `:DistantMkdir`, `:DistantOpen`, `:DistantSearch`, `:DistantSessionInfo`, `:DistantShell`, `:DistantSpawn`, `:DistantSystemInfo`, `:DistantRemove`, `:DistantRename`.

#### Bufory zdalne i UI

| Kontekst | Klawisz | Działanie | Stan |
|---|---|---|---|
| zdalny plik | `-` | Otwórz katalog nadrzędny | **Domyślne wtyczki** |
| zdalny katalog | `Enter` | Edytuj wpis | **Domyślne wtyczki** |
| zdalny katalog | `Ctrl-t` | Otwórz wpis w nowej karcie | **Domyślne wtyczki** |
| zdalny katalog | `-` | Katalog nadrzędny | **Domyślne wtyczki** |
| zdalny katalog | `K`, `N` | Nowy katalog / nowy plik | **Domyślne wtyczki** |
| zdalny katalog | `R`, `D`, `M`, `C` | Rename, remove, metadata, copy | **Domyślne wtyczki** |
| główne UI | `q` / `Esc` | Zamknięcie | **Domyślne wtyczki** |
| główne UI | `1`, `2`, `?` | Connections, System Info, Help | **Domyślne wtyczki** |
| główne UI | `R` | Odświeżenie karty | **Domyślne wtyczki** |
| Connections | `K`, `I` | Zabij połączenie / przełącz informacje | **Kontekstowe** |

**Bezpieczeństwo:** `DistantRemove` i `D` usuwają na serwerze, a operacja nie trafia do lokalnego kosza. `K` w Connections kończy połączenie. Przed zmianą nazwy/spawn sprawdź host i ścieżkę.

**Wymagania:** Neovim co najmniej 0.8, klient Distant 0.20.x zgodny z gałęzią v0.3, SSH i zdalny executable. Wtyczka jest oznaczona upstream jako alpha.

**Szybki tutorial:** `<leader>rl`, podaj URI SSH, `<leader>ro` i ścieżkę, edytuj/zapisz plik, otwórz `<leader>rs`, a stan połączenia sprawdź `:Distant`.

### `vim-tmux-navigator`

**Co robi i po co:** tworzy jedną siatkę nawigacji ze splitów Neovim i paneli tmux. Ładuje się natychmiast po obu stronach.

**Mapowania:** `Ctrl-h/j/k/l` oraz `Ctrl-\` w Normal Neovim i root tmux. W Terminal Neovim działają `Ctrl-h/j/k/l`, ale nie `Ctrl-\`; dla filetype `fzf` są przekazywane do terminala zamiast nawigować. Wtyczka tmux instaluje wszystkie pięć klawiszy w copy-mode-vi oraz `prefix Ctrl-l` do wysłania clear-screen. Lokalne mapowania Insert `Ctrl-h/j/k/l` mają pierwszeństwo w Neovim i poruszają kursorem.

**Polecenia:** `:TmuxNavigateLeft`, `:TmuxNavigateDown`, `:TmuxNavigateUp`, `:TmuxNavigateRight`, `:TmuxNavigatePrevious`, `:TmuxNavigatorProcessList`.

**Wymagania:** tmux co najmniej 1.8, działające `ps` i wspólny plugin po obu stronach. Zagnieżdżony tmux wymaga świadomego `send-prefix` i nie ma pełnej automatycznej nawigacji między warstwami.

**Szybki tutorial:** utwórz split Neovim oraz sąsiedni panel tmux, przejdź kilka razy `Ctrl-l`; gdy wykrywanie zawodzi, uruchom `:TmuxNavigatorProcessList` i sprawdź nazwę procesu.

</details>

<details>
<summary><strong>Lokalne watchdiff.nvim i claude.nvim</strong></summary>

### `watchdiff.nvim`

**Ścieżka:** `/Users/lukasz/Desktop/dotfiles/watchdiff.nvim`.

**Co robi i po co:** obserwuje rekursywnie bieżący katalog przez `vim.uv` i pokazuje, co narzędzie zewnętrzne zmieniło od ostatniego „uznanego” stanu. To inny punkt odniesienia niż Gitsigns: baseline użytkownika zamiast Git HEAD/index.

**Ładowanie lokalne:** `VeryLazy`, `opts={}`. Debounce 200 ms, maksymalnie 50 wpisów historii na plik, ignorowanie między innymi `.git`, `.next`, `node_modules`, swapów i `.DS_Store`. Domyślnie śledzone są tylko już załadowane bufory.

**Zachowanie:** czysty bufor jest przeładowywany przez `checktime`; zmienione/dodane linie dostają zielone tło, usunięte pojawiają się jako czerwone virtual lines. Dla plików ponad 5000 wierszy inline highlight jest pomijany. Baseline aktualizuje otwarcie, własny zapis i clear, lecz nie zewnętrzna edycja.

| Kontekst | Klawisz | Działanie | Stan |
|---|---|---|---|
| globalny `n` | `<leader>ch` | Wyczyść highlight i uznaj bieżącą treść jako baseline | **Aktywne lokalne** |
| scratch historii | `q` | Zamknij historię | **Kontekstowe** |
| globalny | mapowanie historii | Brak, bo `keys.history=false` | **Warunkowe/wyłączone** |

**Polecenie:** `:WatchDiffHistory` pokazuje zapamiętaną historię bieżącego pliku. Funkcje provenance używane przez Claude są API Lua, nie poleceniami Ex.

**Bezpieczeństwo:** gdy bufor ma niezapisane zmiany, watchdiff nie przeładowuje go i prosi o decyzję. `:e!` oznacza świadome odrzucenie wersji bufora. Historia jest tylko w pamięci bieżącej sesji.

**Wymagania:** Neovim z `vim.uv`; recursive fs events zależą od systemu plików. CWD powinien być rootem obserwowanego projektu.

**Szybki tutorial:** otwórz i zapisz plik, zmień go w drugiej powłoce, wróć do Neovim, obejrzyj podświetlenia i `:WatchDiffHistory`, a dopiero potem `<leader>ch`.

### `claude.nvim`

**Ścieżka:** `/Users/lukasz/Desktop/dotfiles/claude.nvim`.

**Co robi i po co:** lokalny popup do wysyłania pytania z kontekstem pliku/zaznaczenia do CLI Claude, z drawerem odpowiedzi i kontrolowanym wstawianiem komentarzy do kodu.

**Ładowanie lokalne:** `VeryLazy`, `opts={}`. Backend to executable `claude` z argumentami `-p --output-format json --permission-mode plan`. Modele: `opus 4.5`, `sonnet`, `haiku`; domyślny alias `opus 4.5` wysyła `opus`. Odpowiedzi używają drawera Volt, a scratch jest fallbackiem.

**Aktywne globalne:** `<leader>ac` w `n,v` oraz `<leader>aC` w `n,v`.

**Polecenia:** `:Claude`, `:ClaudeCommentNow`, `:ClaudeComment`.

#### Popup wejściowy

| Tryb | Klawisz | Działanie |
|---|---|---|
| `i,n` | `Enter` | Wyślij prompt |
| `i` | `Ctrl-j` | Wstaw nową linię bez wysyłania |
| `n` | `q` / `Esc` | Zamknij |
| `i` | `Esc` | Zamknij |
| `i` | `Ctrl-c` | Anuluj trwające żądanie |
| `i` | `Ctrl-l` | Wyczyść prompt |
| `i,n` | `Tab` | Następny model |
| `i,n` | `F2` | Answer kontra comment-now |

#### Drawer odpowiedzi

| Kontekst | Klawisz | Działanie |
|---|---|---|
| body | `q` / `Esc` | Zamknij drawer |
| body | `I` | Spróbuj wstawić ostatnią odpowiedź jako komentarze |
| body | `y` / `Y` | Kopiuj odpowiedź / gotowy blok komentarza |
| body | `o` | Zamknij drawer i otwórz pełny scratch |
| body | `Tab` / `Shift-Tab` | Następna / poprzednia karta |
| body | `1` / `2` / `3` | Answer / Question / Files |
| body, Files | `Enter` | Podgląd wskazanego consulted file w splicie, drawer pozostaje otwarty |
| shell Volt | `q` / `Esc`, `1/2/3`, `y/Y` | Zamknięcie, karta, kopiowanie |
| shell Volt | `Enter`, `Tab`, `Shift-Tab` | Kliknięcie i cykl interaktywnych elementów dodany przez Volt |
| scratch | `q`, `I`, `y`, `Y` | Zamknij, komentarz, kopia odpowiedzi, kopia bloku |

#### Tryb deweloperski

Autocmd repo ładuje go raz po wejściu do `*/claude.nvim/lua/*.lua`.

| Klawisz | Działanie | Stan |
|---|---|---|
| `<leader>rr` | Reload modułów i ponowny setup | **Kontekstowe** |
| `<leader>rt` | Reload i natychmiastowy popup | **Kontekstowe** |
| `<leader>rd` | Debug lista modułów | **Kontekstowe** |

**Wstawianie komentarzy:** answer mode zawsze daje przegląd. Comment-now zapisuje od razu tylko wtedy, gdy kontrola stanu pliku uzna operację za bezpieczną; inaczej wraca do drawera. Przy aktywnym watchdiff zapis dostaje provenance `claude.nvim` i pojawia się w `:WatchDiffHistory`.

**Wymagania:** zainstalowane i uwierzytelnione CLI `claude`, dostęp do backendu oraz `volt` dla preferowanego drawera. Bez Volt pozostaje scratch fallback.

**Szybki tutorial:** zaznacz funkcję, `<leader>ac`, wpisz pytanie, zmień model `Tab`, wyślij `Enter`; w odpowiedzi sprawdź Files przez `3`, wróć `1`, skopiuj `y` lub wstaw komentarze `I`, potem przejrzyj watchdiff.

</details>

<a id="wymagania"></a>
## Wymagania i środowisko

### Wersje bazowe sprawdzone lokalnie

| Składnik | Wersja/stan | Dlaczego ma znaczenie |
|---|---|---|
| macOS + Ghostty | konfiguracja repo dla Ghostty | True color, synchronized output i extended keys CSI-u |
| Neovim | `v0.12.4`, LuaJIT | nowe API LSP i gałąź `main` nvim-treesitter |
| tmux | `3.6a` | tabela defaultów tmux w tym przewodniku odpowiada tej wersji |
| zsh + Oh My Zsh | shell użytkownika | ładuje `PATH`, NVM i wyłącza XON/XOFF |
| Karabiner-Elements | reguły repo dla Ghostty | fizyczne `Cmd-h`, `Cmd-l`, `Cmd-q`, `Cmd-\` i `Cmd--` do kodów terminalowych |
| Nerd Font | wymagana w wybranym foncie Ghostty | poprawne ikony NvChad, drzewa, Git, DAP i Markdown |

### Instalacja warstw

1. W katalogu repo uruchom `brew bundle --file Brewfile`. Deklarowane są: Neovim, tree-sitter-cli, tmux, fzf, fd, ripgrep, jq, stylua, ruff, Ghostty i Karabiner-Elements.
2. Zainstaluj NVM oraz domyślne Node LTS zgodnie z `README.md`; Node uruchamia część serwerów Mason i adapter JS/TS.
3. Utwórz dowiązania przez `bash install.sh install` i sprawdź je przez `bash install.sh status`. Instalator wykonuje timestampowane backupy zastępowanych celów.
4. Sklonuj TPM do `~/.tmux/plugins/tpm`, wczytaj konfigurację przez `tmux source-file "$HOME/.tmux.conf"`, a wewnątrz tmux naciśnij `Ctrl-s I`.
5. Odtwórz wtyczki Neovim dokładnie z lockfile przez `nvim --headless "+Lazy! restore" +qa`.
6. Zainstaluj narzędzia Mason: `lua-language-server pyright ruff typescript-language-server html-lsp css-lsp dockerfile-language-server docker-compose-language-service stylua mypy debugpy delve js-debug-adapter`.
7. Dla Claude opcjonalnie zainstaluj `@anthropic-ai/claude-code` i wykonaj pierwsze logowanie poleceniem `claude`.
8. Dla Distant zapewnij lokalne `~/.local/bin/distant` oraz `/home/ukibbb/.local/bin/distant` na skonfigurowanym hoście; obie strony powinny używać zgodnej linii 0.20.x.

### Executable według funkcji

| Funkcja | Wymagane/zalecane executable |
|---|---|
| bootstrap i Git UI | `git` |
| runtime narzędzi opartych na JavaScript | `node`, `npm`; wymagane przez Pyright, HTML/CSS, Docker/Compose LSP oraz `js-debug-adapter` |
| Telescope | `rg`, `fd`; `fzf` jest potrzebne przez tmux-fzf |
| tmux-fzf | GNU `bash`, `sed`, `fzf`; opcjonalnie `pstree` i CopyQ |
| format Lua/Python | `stylua`, `ruff` |
| lint Python | `mypy` |
| LSP | executable wymienione w tabeli sekcji nvim-lspconfig; Node dla serwerów JS oraz projektowy `typescript` dla TS |
| DAP Python | `debugpy-adapter` |
| DAP Go | `dlv` z pakietu Mason `delve` |
| DAP JS/TS/Chrome | `node`, `js-debug-adapter`; Chrome z remote debugging dla attach |
| parsery Treesitter | `curl`, `tar`, kompilator C/C++ i `tree-sitter >= 0.26.1` |
| CodeDiff | `curl` albo `wget` do pierwszego pobrania biblioteki natywnej |
| Distant | `ssh`, lokalny i zdalny `distant` |
| vim-tmux-navigator | `ps`, tmux i Neovim/Vim |
| claude.nvim | uwierzytelnione `claude` CLI i sieć do backendu |

`.zshrc` dodaje do `PATH` między innymi `~/.local/share/nvim/mason/bin`, środowisko NVM, Bun i OpenCode. Po zmianie uruchom nową powłokę albo `source ~/.zshrc`. `stty -ixon` uwalnia `Ctrl-s` od terminalowego XOFF; tmux nadal używa tego klawisza jako prefixu.

### Co jest, a czego nie ma w lockfile

- `nvim/lazy-lock.json` przypina 41 zewnętrznych wtyczek Neovim do pełnych hashy Git.
- `watchdiff.nvim` i `claude.nvim` są ładowane z katalogów tego repo i nie mają osobnych wpisów lockfile.
- `tmux.conf` zapisuje tylko trzy identyfikatory repozytoriów TPM, bez commitów. Aktualny commit instalacji tmux jest więc stanem lokalnym, nie gwarancją odtworzenia.
- Homebrew i Mason nie są tu przypięte do wersji. `brew bundle` oraz ręczna lista Mason odtwarzają zestaw, ale nie historyczne wydania narzędzi.

<a id="manifest"></a>
## Manifest źródeł i wersji

### Neovim: 41 wpisów `lazy-lock.json`

Wszystkie poniższe lokalne katalogi w `~/.local/share/nvim/lazy` miały `HEAD` równy lockfile podczas weryfikacji 8 sierpnia 2026. Nazwa w pierwszej kolumnie jest zarazem nazwą katalogu instalacji Lazy.

| Nazwa lockfile | Repozytorium źródłowe | Gałąź | Commit |
|---|---|---|---|
| `LuaSnip` | [L3MON4D3/LuaSnip](https://github.com/L3MON4D3/LuaSnip) | `master` | `3732756842a2f7e0e76a7b0487e9692072857277` |
| `base46` | [NvChad/base46](https://github.com/NvChad/base46) | `v3.0` | `884b990dcdbe07520a0892da6ba3e8d202b46337` |
| `cmp-async-path` | [FelipeLema/cmp-async-path](https://codeberg.org/FelipeLema/cmp-async-path) | `main` | `9c2374deb32c2bec8b27e928c6f57090e9a875d2` |
| `cmp-buffer` | [hrsh7th/cmp-buffer](https://github.com/hrsh7th/cmp-buffer) | `main` | `b74fab3656eea9de20a9b8116afa3cfc4ec09657` |
| `cmp-nvim-lsp` | [hrsh7th/cmp-nvim-lsp](https://github.com/hrsh7th/cmp-nvim-lsp) | `main` | `cbc7b02bb99fae35cb42f514762b89b5126651ef` |
| `cmp-nvim-lua` | [hrsh7th/cmp-nvim-lua](https://github.com/hrsh7th/cmp-nvim-lua) | `main` | `e3a22cb071eb9d6508a156306b102c45cd2d573d` |
| `cmp_luasnip` | [saadparwaiz1/cmp_luasnip](https://github.com/saadparwaiz1/cmp_luasnip) | `master` | `98d9cb5c2c38532bd9bdb481067b20fea8f32e90` |
| `codediff.nvim` | [esmuellert/codediff.nvim](https://github.com/esmuellert/codediff.nvim) | `main` | `32ccb9b66645b3b93148854b9b4421770709ad20` |
| `conform.nvim` | [stevearc/conform.nvim](https://github.com/stevearc/conform.nvim) | `master` | `5ac2bb57a9096f00ca50e1a3c46020d5930319b8` |
| `diffview.nvim` | [sindrets/diffview.nvim](https://github.com/sindrets/diffview.nvim) | `main` | `4516612fe98ff56ae0415a259ff6361a89419b0a` |
| `distant.nvim` | [chipsenkbeil/distant.nvim](https://github.com/chipsenkbeil/distant.nvim) | `v0.3` | `67d6b066e8490725718b79f643966f4eafc7da3c` |
| `friendly-snippets` | [rafamadriz/friendly-snippets](https://github.com/rafamadriz/friendly-snippets) | `main` | `572f5660cf05f8cd8834e096d7b4c921ba18e175` |
| `gitsigns.nvim` | [lewis6991/gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | `main` | `42d6aed4e94e0f0bbced16bbdcc42f57673bd75e` |
| `indent-blankline.nvim` | [lukas-reineke/indent-blankline.nvim](https://github.com/lukas-reineke/indent-blankline.nvim) | `master` | `005b56001b2cb30bfa61b7986bc50657816ba4ba` |
| `lazy.nvim` | [folke/lazy.nvim](https://github.com/folke/lazy.nvim) | `main` | `306a05526ada86a7b30af95c5cc81ffba93fef97` |
| `mason.nvim` | [mason-org/mason.nvim](https://github.com/mason-org/mason.nvim) | `main` | `44d1e90e1f66e077268191e3ee9d2ac97cc18e65` |
| `menu` | [nvzone/menu](https://github.com/nvzone/menu) | `main` | `7a0a4a2896b715c066cfbe320bdc048091874cc6` |
| `minty` | [nvzone/minty](https://github.com/nvzone/minty) | `main` | `aafc9e8e0afe6bf57580858a2849578d8d8db9e0` |
| `neogit` | [NeogitOrg/neogit](https://github.com/NeogitOrg/neogit) | `master` | `73870229977fdd8747025820e15e98cfde787b9c` |
| `nui.nvim` | [MunifTanjim/nui.nvim](https://github.com/MunifTanjim/nui.nvim) | `main` | `de740991c12411b663994b2860f1a4fd0937c130` |
| `nvim-autopairs` | [windwp/nvim-autopairs](https://github.com/windwp/nvim-autopairs) | `master` | `c2a0dd0d931d0fb07665e1fedb1ea688da3b80b4` |
| `nvim-cmp` | [hrsh7th/nvim-cmp](https://github.com/hrsh7th/nvim-cmp) | `main` | `2ffe79f1f021def8dd1fcd81deb16f1bb0d989f3` |
| `nvim-dap` | [mfussenegger/nvim-dap](https://github.com/mfussenegger/nvim-dap) | `master` | `9e848e09a697ee95302a3ef2dd43fd6eb709e570` |
| `nvim-dap-go` | [leoluz/nvim-dap-go](https://github.com/leoluz/nvim-dap-go) | `main` | `b4421153ead5d726603b02743ea40cf26a51ed5f` |
| `nvim-dap-python` | [mfussenegger/nvim-dap-python](https://github.com/mfussenegger/nvim-dap-python) | `master` | `1808458eba2b18f178f990e01376941a42c7f93b` |
| `nvim-dap-ui` | [rcarriga/nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui) | `master` | `cc9dd33aade7f20bae414d0cba163bc60d4d4b43` |
| `nvim-dap-virtual-text` | [theHamsta/nvim-dap-virtual-text](https://github.com/theHamsta/nvim-dap-virtual-text) | `master` | `fbdb48c2ed45f4a8293d0d483f7730d24467ccb6` |
| `nvim-lint` | [mfussenegger/nvim-lint](https://github.com/mfussenegger/nvim-lint) | `master` | `bcd1a44edbea8cd473af7e7582d3f7ffc60d8e81` |
| `nvim-lspconfig` | [neovim/nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | `master` | `1c0d8f70dbc8827263eedc3cf7021ceba0f68689` |
| `nvim-nio` | [nvim-neotest/nvim-nio](https://github.com/nvim-neotest/nvim-nio) | `master` | `edcc181a875301dd21840189aa2f2f9ad69fc172` |
| `nvim-tree.lua` | [nvim-tree/nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua) | `master` | `037d89e60fb01a6c11a48a19540253b8c72a3c32` |
| `nvim-treesitter` | [nvim-treesitter/nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | `main` | `7b6cc8949f9999c5ed91436cbe24aa5f99c42025` |
| `nvim-ts-autotag` | [windwp/nvim-ts-autotag](https://github.com/windwp/nvim-ts-autotag) | `main` | `88c1453db4ba7dd24131086fe51fdf74e587d275` |
| `nvim-web-devicons` | [nvim-tree/nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) | `master` | `803353450c374192393f5387b6a0176d0972b848` |
| `plenary.nvim` | [nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim) | `master` | `b9fd5226c2f76c951fc8ed5923d85e4de065e509` |
| `render-markdown.nvim` | [MeanderingProgrammer/render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) | `main` | `c54380dd4d8d1738b9691a7c349ecad7967ac12e` |
| `telescope.nvim` | [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | `master` | `a8c2223ea6b185701090ccb1ebc7f4e41c4c9784` |
| `ui` | [NvChad/ui](https://github.com/NvChad/ui) | `v3.0` | `aa95aca6936f277417d2565d9416713198b6dbd1` |
| `unified.nvim` | [axkirillov/unified.nvim](https://github.com/axkirillov/unified.nvim) | `main` | `6b9d94b83cdaf7a33afeb1d66a9de386f02d8c55` |
| `vim-tmux-navigator` | [christoomey/vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) | `master` | `c45243dc1f32ac6bcf6068e5300f3b2b237e576a` |
| `volt` | [nvzone/volt](https://github.com/nvzone/volt) | `main` | `620de1321f275ec9d80028c68d1b88b409c0c8b1` |

### Dwie wtyczki lokalne

Oba katalogi są częścią głównego repozytorium `git@github.com:ukibbb/dotfiles.git`, a nie niezależnymi repozytoriami. Ich wersję przypina commit całego repozytorium, dlatego nie potrzebują osobnego lockfile.

| Nazwa | Katalog źródłowy | Sposób ładowania | Osobny pin |
|---|---|---|---|
| `watchdiff.nvim` | `/Users/lukasz/Desktop/dotfiles/watchdiff.nvim` | `dir = dotfiles_dir .. "/watchdiff.nvim"` | brak |
| `claude.nvim` | `/Users/lukasz/Desktop/dotfiles/claude.nvim` | `dir = dotfiles_dir .. "/claude.nvim"` | brak |

### Trzy instalacje tmux

| Specyfikacja w `tmux.conf` | Repozytorium | Lokalnie zainstalowany commit |
|---|---|---|
| `tmux-plugins/tpm` | [tmux-plugins/tpm](https://github.com/tmux-plugins/tpm) | `99469c4a9b1ccf77fade25842dc7bafbc8ce9946` |
| `sainnhe/tmux-fzf` | [sainnhe/tmux-fzf](https://github.com/sainnhe/tmux-fzf) | `05af76daa2487575b93a4f604693b00969f19c2f` |
| `christoomey/vim-tmux-navigator` | [christoomey/vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) | `c45243dc1f32ac6bcf6068e5300f3b2b237e576a` |

TPM może pobrać nowsze `HEAD` przy kolejnej instalacji lub aktualizacji. Jeśli te hashe mają być naprawdę odtwarzalne, potrzebna jest osobna deklaratywna procedura checkoutu; obecny `tmux.conf` jej nie zawiera.

### Kontrola zgodności instalacji Lazy

Poniższy skrypt niczego nie aktualizuje. Wypisuje tylko brakujące katalogi albo różnice `HEAD` względem lockfile; brak wyniku oznacza zgodność.

```sh
jq -r 'to_entries[] | [.key, .value.commit] | @tsv' nvim/lazy-lock.json |
while IFS=$'\t' read -r name expected; do
  actual=$(git -C "$HOME/.local/share/nvim/lazy/$name" rev-parse HEAD 2>/dev/null || true)
  if [[ "$actual" != "$expected" ]]; then
    printf '%s expected=%s actual=%s\n' "$name" "$expected" "${actual:-missing}"
  fi
done
```

<a id="diagnostyka"></a>
## Diagnostyka

### Kontrola bazowa

```sh
bash install.sh status
nvim --version
tmux -V
git --version
command -v rg fd fzf jq stylua ruff tree-sitter
command -v node npm curl tar cc
command -v lua-language-server pyright-langserver typescript-language-server mypy
command -v debugpy-adapter dlv js-debug-adapter distant claude
```

Brak pojedynczego opcjonalnego executable nie musi blokować całego edytora. Przykładowo brak `mypy` wyłącza tylko lokalny lint Python, a brak `claude` tylko backend claude.nvim.

### Neovim nie startuje lub wtyczka się nie ładuje

1. Uruchom `nvim --headless "+checkhealth" +qa` i zwykłe `:messages`.
2. Otwórz `:Lazy`, sprawdź błędy i commit problematycznej wtyczki. Do bezpiecznego powrotu do lockfile służy `:Lazy! restore`.
3. Uruchom `:checkhealth lazy`; dla startupu użyj `:Lazy profile`.
4. Gdy zniknęły kolory UI, wykonaj `:lua require("base46").load_all_highlights()` i uruchom Neovim ponownie.
5. Sprawdź nadpisanie klawisza przez `:verbose nmap <leader>gf` albo odpowiednie `:verbose imap`, `:verbose xmap`, `:verbose smap`.

### LSP, completion, format i parsery

| Objaw | Kontrola |
|---|---|
| brak klienta LSP | `:checkhealth vim.lsp`, `:lua =vim.lsp.get_clients({bufnr=0})` |
| brak konkretnego serwera | `:echo executable('lua-language-server')` z właściwą nazwą executable |
| TypeScript nie trafia do implementacji | upewnij się, że klient nazywa się `ts_ls`, potem `:verbose nmap gS` |
| completion bez LSP/importu | `:CmpStatus`, sprawdź etykietę `[LSP]`, capabilities i root projektu |
| formatter nie działa | `:ConformInfo`, `:echo executable('stylua')`, `:echo executable('ruff')` |
| mypy się nie uruchamia | zapisz plik Python, sprawdź `:messages` i `:echo executable('mypy')` |
| brak parsera | `:TSLog`, `:TSInstall {język}`, potem `:InspectTree` |
| stary parser po zmianie rewizji | `:TSUpdate` |
| render Markdown nie działa | `:RenderMarkdown config`, `:RenderMarkdown debug`, sprawdź `markdown` i `markdown_inline` |

### Tmux, Ghostty i kod klawisza

1. Sprawdź składnię i przeładuj przez `tmux source-file "$HOME/.tmux.conf"`.
2. Obejrzyj efektywne mapowania przez `tmux list-keys -T root`, `tmux list-keys -T prefix` i `tmux list-keys -T copy-mode-vi`.
3. Sprawdź opcje przez `tmux show-options -gv prefix`, `tmux show-options -gv extended-keys`, `tmux show-options -gv extended-keys-format` i `tmux show-options -gv allow-passthrough`.
4. Gdy nawigator nie przechodzi przez granicę, użyj `:TmuxNavigatorProcessList`, a potem sprawdź proces panelu przez `tmux display-message -p '#{pane_current_command}'`.
5. Aby zobaczyć kod wysyłany przez terminal, wykonaj w Neovim `:lua print(vim.fn.keytrans(vim.fn.getcharstr()))`, zatwierdź i naciśnij badany klawisz.
6. Jeśli TUI pozostawiło w panelu mysz lub alternate screen, użyj `Ctrl-s Ctrl-g`; polecenie naprawcze zmienia stan terminala i powinno służyć tylko do tej awarii.

Jeśli `Ctrl-s` zamraża samą powłokę poza tmux, sprawdź `stty -a` i ponownie wykonaj `stty -ixon`. W tmux `Ctrl-s` jest świadomie prefixem, więc dosłowny klawisz do aplikacji to `Ctrl-s Ctrl-s`.

### Git UI i różnice

| Problem | Kontrola/naprawa |
|---|---|
| Telescope nie widzi plików/tekstu | `:checkhealth telescope`, potem `:echo executable('fd')` i `:echo executable('rg')` |
| Neogit pokazuje błąd Git | panel `$`/console, `:messages`, zwykłe `git status` w root repo |
| Diffview ma zły zakres | zamknij `:DiffviewClose`, sprawdź ref przez Git i podaj go jawnie do `:DiffviewOpen` |
| CodeDiff nie ma biblioteki natywnej | `:CodeDiff install`; wariant z `!` wymusza ponowną instalację |
| operacja stage nie daje oczekiwanego wyniku | natychmiast sprawdź `git status` i sekcję staged/unstaged przed dalszą akcją |

Nie diagnozuj problemu Git przez próbne `X`, discard albo hard reset. Najpierw użyj operacji tylko do odczytu: `git status`, diff i log.

### DAP

1. Sprawdź adapter przez `:echo executable('debugpy-adapter')`, `:echo executable('dlv')` albo `:echo executable('js-debug-adapter')`.
2. Włącz log przez `:DapSetLogLevel TRACE`, odtwórz problem i otwórz `:DapShowLog`.
3. Dla Node sprawdź `cwd`, source mapy i czy program istnieje. Dla attach wybierz właściwy proces.
4. Dla Chrome sprawdź port remote debugging, domyślnie `9222`, oraz zgodność `webRoot` z root projektu.
5. Jeśli UI się nie otworzy, wykonaj `<leader>du`; sprawdź też `:messages`, bo dap-ui jest zależnością ładowaną razem z nvim-dap.
6. Gdy `.vscode/launch.json` nie daje konfiguracji, sprawdź jego JSON, `type` równy `pwa-node`/`pwa-chrome` i filetype bieżącego bufora.

### Distant

1. Wykonaj `:DistantClientVersion`, `:DistantCheckHealth` i `:DistantSystemInfo`.
2. Sprawdź `:echo executable(expand('~/.local/bin/distant'))` oraz ręczne SSH do celu.
3. Przy timeout sprawdź host, użytkownika, zdalną ścieżkę executable i limit 60 s.
4. Gdy zdalny LSP nie startuje, sprawdź executable serwera na hoście zdalnym, nie tylko lokalny Mason.
5. Przed powtórzeniem operacji zapisu/usunięcia ustal przez `:DistantSessionInfo`, z którym połączeniem pracuje bufor.

### watchdiff i Claude

| Objaw | Kontrola |
|---|---|
| brak zewnętrznego diffu | sprawdź, czy plik jest otwartym buforem, CWD obejmuje plik, wzorzec nie jest ignorowany i bufor był czysty |
| konflikt z niezapisanym buforem | najpierw skopiuj/zapisz potrzebną treść; nie wybieraj odruchowo `:e!` |
| historia jest pusta | historia nie jest trwała i zaczyna się dopiero po zdarzeniach w bieżącej sesji |
| popup Claude nie startuje | `:echo executable('claude')`, `:messages`, potem ręczne `claude` w powłoce |
| drawer Volt zawodzi | odpowiedź powinna przejść do scratch fallbacku; sprawdź `:messages` i stan wtyczki `volt` w Lazy |
| komentarz nie został zapisany od razu | to oczekiwany fallback bezpieczeństwa; przejrzyj drawer i stan pliku/watchdiff |

### Gdzie pytać o mapowanie

- Neovim: `:map`, `:nmap`, `:imap`, `:xmap`, `:smap`, a dla źródła definicji `:verbose {tryb}map {klawisz}`.
- Lazy: `:Lazy help`, a potem `?` w UI konkretnej rewizji.
- Panel wtyczki: najpierw `g?` albo `?`, jeśli dana sekcja ten klawisz dokumentuje.
- Tmux: `prefix ?` lub `tmux list-keys`; pamiętaj o osobnych tabelach root, prefix i copy-mode-vi.
- Polecenia: `:help :commands`, `:command`, `:verbose command {nazwa}`; nazwa funkcji Lua z README nie oznacza automatycznie polecenia Ex.
