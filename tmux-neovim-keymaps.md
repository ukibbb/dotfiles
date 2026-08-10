# Tmux i Neovim: mapowania, wtyczki i przepływy pracy

> Stan opisany w tym przewodniku odpowiada konfiguracji repozytorium zweryfikowanej 9 sierpnia 2026. Zachowanie wtyczek pochodzi z lokalnie zainstalowanych rewizji przypiętych w `nvim/lazy-lock.json`, a nie z dokumentacji najnowszej wersji w sieci. Dla każdej wtyczki źródłem nadrzędnym jest kod przypiętego commita; internetowe README i strony dokumentacji służą tylko wtedy, gdy odpowiadają tej samej rewizji.

<a id="spis-tresci"></a>
## Spis treści

- [Szybka ściąga](#szybka-sciaga)
- [Najważniejsze ostrzeżenia](#bezpieczenstwo)
- [Notacja i etykiety](#notacja)
- [Tmux](#tmux)
- [Aktywne mapowania Neovim](#aktywne-mapowania-neovim)
- [Praktyczne przepływy pracy](#przeplywy-pracy)
- [Przewodnik po wtyczkach](#wtyczki)
- [Indeks wszystkich wtyczek](#indeks-wtyczek)
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

> **UWAGA: automatyczne zmiany przy zapisie.** Zapis Lua lub Pythona uruchamia Conform. Dla Pythona najpierw działa `ruff check --fix`, a dopiero potem `ruff format`, więc zapis może usuwać importy i stosować poprawki kodu, nie tylko zmieniać odstępy. Po pierwszym użyciu w projekcie obejrzyj `git diff`.

> **UWAGA: interfejs nie zawsze pokazuje historyczny stan, na którym operuje.** Stage, unstage i discard w historycznych widokach CodeDiff albo Diffview nadal mogą zmieniać realny indeks i drzewo robocze. Operacji `-`, `S`, `U` i `X` używaj do stagingu tylko w zwykłym widoku bieżących zmian, po sprawdzeniu `git status`.

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
| **Domyślne Neovim** | Mapowanie lub zachowanie dostarczane przez używaną wersję Neovim, niezależne od wtyczki |
| **Kontekstowe** | Działa tylko w określonym buforze, panelu, trybie, filetype albo po podłączeniu LSP |
| **Polecenie** | Publiczne polecenie Ex, które można wpisać po `:`; wewnętrzne funkcje Lua nie są tu nazywane poleceniami |
| **Przykład nieaktywny** | Skrót pokazany przez README jako przykład, ale nieutworzony przez tę konfigurację |
| **Warunkowe/wyłączone** | Istnieje tylko po spełnieniu warunku albo jest jawnie wyłączone |
| **Opcjonalne upstream** | Funkcja obecna w przypiętym kodzie, ale wymagająca dodatkowego mapowania, konfiguracji albo ręcznego API Lua |
| **Biblioteka bez samodzielnego UI** | Zależność używana przez inne wtyczki; użytkownik diagnozuje ją pośrednio, zamiast otwierać osobny panel |

### Klawisze fizyczne na macOS

WezTerm bezpośrednio koduje fizyczne `Cmd-h`, `Cmd-l`, `Cmd-q`, `Cmd-\` i `Cmd--` jako sekwencje CSI-u widziane przez Neovim jako `Meta+Ctrl`. Dlatego konfiguracja Neovim zapisuje je jako `<M-C-H>`, `<M-C-L>`, `<M-C-Q>`, `<M-C-\>` i `<M-C-_>`. `Cmd-j` i `Cmd-k` są kodowane jako sekwencje używane przez mapowania `<M-j>` i `<M-k>`. W tabelach podano zarówno zamiar fizyczny, jak i kod Neovim tam, gdzie to potrzebne.

<a id="tmux"></a>
## Tmux

### Konfiguracja i zachowanie terminala

- Terminal domyślny: `tmux-256color`; dla WezTerm włączone są RGB, synchronized output i extended keys w formacie CSI-u.
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
| `<leader>gd` | Otwarcie lub odświeżenie inline diff `Unified` względem `HEAD`; drzewo automatycznie otwiera pierwszy zmieniony plik, a `:Unified reset` czyści bieżący bufor | **Aktywne lokalne** |
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

Wbudowane globalne skróty Neovim 0.12 pozostają dostępne: `grn` rename, `gra` w `n,x` code action, `gri` implementation, `grr` references, `grt` type definition, `grx` code lens, `gO` symbole dokumentu, `gx` link dokumentu, `an`/`in` wybór węzła oraz `Ctrl-s` w `i,s` pomoc sygnatur. Po attach `K` pokazuje hover, o ile `keywordprg` lub własne mapowanie go nie zastąpiło. `[D` / `]D` skaczą do pierwszej / ostatniej diagnostyki, a `Ctrl-w d` i `Ctrl-w Ctrl-d` otwierają jej opis.

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
7. `ts_ls` próbuje automatycznie odzyskać utratę synchronizacji lub crash; jeśli inny serwer się zawiesi albo restart nie nastąpił, użyj `<leader>lr`.

### Format i lint

1. Naciśnij `<leader>fm` przed przeglądem zmian albo po prostu zapisz plik.
2. Lua używa `stylua`; Python kolejno `ruff check --fix` i `ruff format`, więc zapis może także poprawić kod lub usunąć import. Inne filetype mogą użyć formatowania LSP.
3. Po zapisie Pythona `nvim-lint` uruchamia `mypy`, jeśli executable jest w `PATH`.
4. Otwórz `<leader>ds`, aby przejść po diagnostyce location list. Użyj `:ConformInfo`, gdy formatter nie działa.

### Od instalacji narzędzia do widocznego efektu

1. Mason albo Homebrew dostarcza executable, lecz samo zainstalowanie pakietu nie uruchamia funkcji.
2. `nvim-lspconfig` wybiera serwer po filetype/root i uruchamia wbudowanego klienta Neovim.
3. `cmp-nvim-lsp` reklamuje capabilities i dostarcza kandydaty `[LSP]`; nvim-cmp renderuje menu.
4. LuaSnip rozwija body snippetu, `cmp_luasnip` tylko wystawia je w menu, a friendly-snippets jest wyłącznie kolekcją danych.
5. nvim-autopairs reaguje po zatwierdzeniu completion i może dopisać parę.
6. Conform używa osobnego executable przy formatowaniu, a nvim-lint uruchamia mypy po zapisie. Diagnostyka LSP i lint może więc pochodzić z kilku niezależnych procesów.

Przy awarii diagnozuj od dołu: `executable()` → filetype/root → klient/provider → mapowanie/UI. Naprawianie samego popupu nie uruchomi brakującego serwera.

### Git: status, stage, review i historia

1. Otwórz `<leader>gg`. W statusie Neogit `s` stage'uje zaznaczenie, `u` cofa stage, `S` stage'uje zmiany wszystkich śledzonych plików, dosłowny `Ctrl-s` także untracked, a `U` cofa cały staged zestaw.
2. Obejrzyj diff przez `<leader>gv` albo char-level przez `<leader>gD`; w zwykłym statusie CodeDiff `-` przełącza stage całego pliku. Nie używaj stagingu w widoku rewizji.
3. Utwórz commit przez `<leader>gc`; napisz wiadomość i zatwierdź `Ctrl-c Ctrl-c`. `Ctrl-c Ctrl-k` anuluje edytor commita.
4. Przed push użyj `<leader>gm`, aby porównać `origin/main...HEAD`, potem `<leader>gp`.
5. Historię pliku pokażą `<leader>gh` albo `<leader>gl`; historię repozytorium `<leader>gL`; picker commitów `<leader>cm` służy do checkout/reset i wymaga szczególnej ostrożności.

### Git: konflikt

1. W Diffview otwartym podczas merge/rebase przechodź konflikty `[x` / `]x`.
2. Wybierz `<leader>co` ours, `<leader>ct` theirs, `<leader>cb` base, `<leader>ca` wszystkie strony albo `dx` usuń region konfliktu. Wielkie warianty działają na cały plik.
3. Alternatywnie uruchom CodeDiff jako mergetool. W nim `<leader>co` oznacza current/ours, `<leader>ct` incoming/theirs, `<leader>cb` inteligentne połączenie obu, a `<leader>cx` powrót do base.
4. Zapisz bufor wyniku, sprawdź treść i dopiero wtedy stage'uj plik. Nie myl akcji rozwiązania konfliktu z odrzuceniem całego pliku przez `X`.

### Git: którego narzędzia użyć

| Potrzeba | Najprostszy wybór |
|---|---|
| znaki i blame bieżącego pliku | Gitsigns |
| czytelny inline review bez dwóch kolumn | Unified |
| częściowy stage hunka lub zakresu | Gitsigns albo Neogit |
| commit, branch, pull, push, stash, rebase | Neogit |
| review wielu plików/brancha i klasyczne konflikty | Diffview |
| char-level diff, dwa pliki/katalogi, result buffer konfliktu | CodeDiff |

Bezpieczny porządek to: obserwacja Gitsigns → review Unified/CodeDiff/Diffview → staging Gitsigns/Neogit → commit/push Neogit. Historyczne viewery nie są bezpiecznym miejscem do eksperymentowania z `S/U/X`.

### DAP: Python, Go, JavaScript, TypeScript i Chrome

1. Zainstaluj odpowiedni adapter: `debugpy-adapter`, `dlv` albo `js-debug-adapter` musi być w `PATH`.
2. Ustaw breakpoint przez `<leader>db`, uruchom `F5` i wybierz konfigurację.
3. Python: wybierz konfigurację dap-python; `<leader>dn` debugguje metodę testową nad kursorem. Adapter jest skonfigurowany jako `debugpy-adapter`.
4. Go: wybierz debug programu/testów; `<leader>dn` uruchamia najbliższy test znaleziony przez parser Go.
5. JS/TS: wybierz `Launch current file with Node`, `Attach to Node process`, `Launch Chrome` albo `Attach to Chrome`.
6. Dla Chrome uruchamianego ręcznie użyj portu remote debugging, domyślnie `9222`; dla launch wpisz URL aplikacji, domyślnie `http://localhost:3000`.
7. Projektowe konfiguracje umieść dokładnie w `${cwd}/.vscode/launch.json`. Typ musi odpowiadać adapterowi, na przykład `pwa-node`, `pwa-chrome`, `python`, `debugpy` albo `go`; provider czyta plik na żądanie.
8. Steruj przez `F10/F11/F12`, ewaluuj `<leader>de`, a sesję zakończ `<leader>dt`.

### Markdown i tagi

1. Otwórz `.md`; render-markdown ładuje się tylko dla `markdown` i renderuje również w Normal oraz Insert.
2. Naciśnij `<leader>mr`, aby wyłączyć lub włączyć render tylko dla tego bufora.
3. Parsery `markdown` i `markdown_inline` są instalowane, a Treesitter startuje dla Markdown.
4. W HTML wpisz `<div>`: `>` uruchamia domknięcie do `<div></div>`. Zmień nazwę tagu i wyjdź z Insert, aby sparowany tag został przemianowany.
5. Autotag wymaga parsera `html`; ten parser jest instalowany i Treesitter startuje dla `html`.

### Distant

1. Sprawdź lokalny klient przez `:DistantClientVersion`. `<leader>rl` używa Launch, więc wymaga skonfigurowanego zdalnego binarnego; `:DistantConnect ssh://...` może użyć samego backendu SSH.
2. Podaj `ssh://user@host`, a potem potwierdź globalnie aktywne połączenie w `:Distant`. Otwarty bufor zachowuje własny connection ID.
3. Wpisz `<leader>ro`, dopisz ścieżkę i zatwierdź. W katalogu `Enter` otwiera wpis, `-` idzie wyżej, `Ctrl-t` otwiera kartę.
4. Otwórz zdalną powłokę `<leader>rs` albo wykonaj pojedyncze polecenie przez `<leader>rx`.
5. Zapis działa na hoście zdalnym. Przed `D` upewnij się, że wskazany wpis można usunąć.

### watchdiff i Claude

1. Pozostaw czysty, zapisany bufor otwarty i pozwól narzędziu zewnętrznemu zmienić plik.
2. watchdiff przeładuje czysty bufor, pokaże zielone dodania/zmiany i czerwone wirtualne usunięcia.
3. Obejrzyj zmianę, opcjonalnie uruchom `:WatchDiffHistory`, a potem `<leader>ch`, aby uznać nowy baseline.
4. Zaznacz kod i użyj `<leader>ac`; wpisz pytanie, `Tab` zmienia model, `Enter` wysyła, `Ctrl-j` dodaje nową linię.
5. W drawerze odpowiedzi `1/2/3` przełącza Answer/Question/Files, `y` kopiuje odpowiedź, `I` próbuje wstawić komentarze.
6. `<leader>aC` próbuje natychmiastowego zapisu po kontrolach stanu pliku, ale nie gwarantuje semantycznego bezpieczeństwa komentarza. Obejrzyj `git diff`; wpis watchdiff jest warunkową adnotacją i może nie powstać.

### Granice lokalne, zdalne i zewnętrzne

| Kombinacja | Faktyczne zachowanie |
|---|---|
| Distant + watchdiff | remote buffer ma `acwrite`; działa watcher Distant, ale nie historia watchdiff |
| Distant + lokalny Mason | lokalny executable nie staje się automatycznie remote LSP |
| Claude + Distant | zaznaczony tekst może trafić do promptu, lecz inspekcja ścieżki i writer zakładają lokalny plik; workflow nie jest wspierany |
| Claude writer + watchdiff | zapis następuje pierwszy, a watcher później może dodać highlight/provenance, jeśli spełnione są wszystkie warunki |
| zewnętrzne Claude Code + watchdiff | wykrycie pochodzi z filesystem event; repo nie ma aktywnego hooka PostToolUse przypisującego autora |
| Gitsigns + watchdiff | Gitsigns porównuje Git index/base, watchdiff użytkownikowy baseline; oba widoki mogą jednocześnie pokazywać inne różnice |

<a id="wtyczki"></a>
## Przewodnik po wtyczkach

Każdy tutorial opisuje najpierw to, co działa bez zmiany konfiguracji. Funkcje dostępne jedynie przez ręczne polecenie lub API mają osobną etykietę, a przykłady z README, których konfiguracja nie instaluje, nie są przedstawiane jako aktywne skróty.

<a id="indeks-wtyczek"></a>
### Indeks wszystkich wtyczek

#### Zarządzanie, UI i infrastruktura

- [`lazy.nvim`](#plugin-lazy-nvim), [`ui`](#plugin-ui), [`base46`](#plugin-base46), [`volt`](#plugin-volt), [`menu`](#plugin-menu), [`minty`](#plugin-minty)
- [`nvim-web-devicons`](#plugin-nvim-web-devicons), [`plenary.nvim`](#plugin-plenary-nvim), [`nui.nvim`](#plugin-nui-nvim), [`nvim-nio`](#plugin-nvim-nio)

#### Formatowanie, LSP, completion i snippety

- [`indent-blankline.nvim`](#plugin-indent-blankline), [`conform.nvim`](#plugin-conform), [`nvim-lint`](#plugin-nvim-lint), [`mason.nvim`](#plugin-mason)
- [`nvim-lspconfig`](#plugin-nvim-lspconfig), [`nvim-cmp`](#plugin-nvim-cmp), [`LuaSnip`](#plugin-luasnip), [`nvim-autopairs`](#plugin-nvim-autopairs)
- [`cmp-nvim-lsp`](#plugin-cmp-nvim-lsp), [`cmp_luasnip`](#plugin-cmp-luasnip), [`cmp-nvim-lua`](#plugin-cmp-nvim-lua), [`cmp-buffer`](#plugin-cmp-buffer), [`cmp-async-path`](#plugin-cmp-async-path), [`friendly-snippets`](#plugin-friendly-snippets)

#### Nawigacja, składnia i Markdown

- [`telescope.nvim`](#plugin-telescope), [`nvim-tree.lua`](#plugin-nvim-tree), [`nvim-treesitter`](#plugin-nvim-treesitter), [`nvim-ts-autotag`](#plugin-nvim-ts-autotag), [`render-markdown.nvim`](#plugin-render-markdown)

#### Git

- [`gitsigns.nvim`](#plugin-gitsigns), [`unified.nvim`](#plugin-unified), [`neogit`](#plugin-neogit), [`diffview.nvim`](#plugin-diffview), [`codediff.nvim`](#plugin-codediff)

#### Debugowanie

- [`nvim-dap`](#plugin-nvim-dap), [`nvim-dap-ui`](#plugin-nvim-dap-ui), [`nvim-dap-virtual-text`](#plugin-nvim-dap-virtual-text), [`nvim-dap-python`](#plugin-nvim-dap-python), [`nvim-dap-go`](#plugin-nvim-dap-go)

#### Zdalna praca i wtyczki lokalne

- [`distant.nvim`](#plugin-distant), [`vim-tmux-navigator`](#plugin-vim-tmux-navigator), [`watchdiff.nvim`](#plugin-watchdiff), [`claude.nvim`](#plugin-claude)

<details>
<summary><strong>lazy.nvim, NvChad UI, Base46, Volt, Menu i Minty</strong></summary>

<a id="plugin-lazy-nvim"></a>
### `lazy.nvim`

**Co robi i po co:** menedżer wtyczek. Rozwiązuje zależności, ładuje moduły na żądanie, instaluje i przywraca dokładne rewizje z lockfile.

**Ładowanie lokalne:** `nvim/init.lua` bootstrapuje `folke/lazy.nvim` do `~/.local/share/nvim/lazy/lazy.nvim`, dodaje katalog do runtimepath i wywołuje `require("lazy").setup("plugins", ...)`. `defaults.lazy=true` oznacza ładowanie na żądanie. `event`, `ft`, `cmd` i `keys` są właśnie wyzwalaczami takiego ładowania; `lazy=false` ładuje wtyczkę przy starcie. Brakujące wtyczki są instalowane automatycznie i ustawiane na commit z lockfile. Sprawdzanie aktualizacji jest wyłączone, a wykrywanie zmiany specyfikacji pozostaje aktywne, tylko bez notyfikacji.

**Polecenia:** `:Lazy` lub `:Lazy show`, `:Lazy home`, `:Lazy install`, `:Lazy update`, `:Lazy sync`, `:Lazy clean`, `:Lazy check`, `:Lazy log`, `:Lazy restore`, `:Lazy profile`, `:Lazy debug`, `:Lazy help`, `:Lazy health`, `:Lazy load {plugin}`, `:Lazy build {plugin}`, `:Lazy reload {plugin}`, `:Lazy clear`. Wariant `:Lazy!` czeka na ukończenie operacji; dla `load` omija też sprawdzenie `cond`.

#### Co naprawdę robią operacje

| Operacja | Znaczenie praktyczne |
|---|---|
| `check` | Wykonuje fetch i pokazuje dostępne zmiany, ale ich nie checkoutuje |
| `install` | Instaluje brakujące katalogi i zapisuje osiągnięty stan do lockfile |
| `update` | Aktualizuje wskazane wtyczki i zapisuje nowe commity do lockfile |
| `sync` | Łączy install, clean i update; nie jest poleceniem do wiernego odtworzenia repo |
| `restore` | Ustawia wtyczki zgodnie z lockfile; dla commita pod kursorem może także przepiąć lockfile |
| `clean` | Usuwa instalacje nieobecne w specyfikacji i może przepisać lockfile |
| `build` | Uruchamia zadeklarowany build, czyli potencjalnie kod Lua lub polecenie powłoki |
| `reload` | Eksperymentalnie przeładowuje wtyczkę; pełny restart jest pewniejszy |
| `clear` | Czyści zakończone zadania z widoku, nie usuwa cache ani wtyczek |

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
| lista | `gx` | To samo co kontekstowe `K`: README, help, repo, issue albo commit | **Domyślne wtyczki** |
| wtyczka | `gb` | Wymuszenie build wskazanej wtyczki | **Domyślne wtyczki** |
| wtyczka | `<localleader>i` | Inspekcja pełnego obiektu specyfikacji | **Domyślne wtyczki**; zwykle `\i` |
| wtyczka | `<localleader>t` | Terminal w katalogu wtyczki | **Domyślne wtyczki**; zwykle `\t` |
| wtyczka | `<localleader>l` | Log przez `lazygit`, jeśli program jest dostępny | **Kontekstowe**; zwykle `\l` |
| zaznaczenie Visual | mała litera akcji | Operacja na kilku zaznaczonych wtyczkach | **Kontekstowe** |
| profil | `Ctrl-s` / `Ctrl-f` | Sortowanie / filtr | **Kontekstowe**; w tmux dosłowny klawisz wymaga `Ctrl-s Ctrl-s` |
| zadanie | `Ctrl-c` | Przerwanie | **Kontekstowe** |
| lista | `[[` / `]]` | Poprzednia / następna sekcja | **Domyślne wtyczki** |

#### Tutorial: kontrola i wierne odtworzenie

1. Otwórz `:Lazy` i sprawdź, czy sekcje błędów albo brakujących instalacji są puste.
2. Naciśnij `?`, aby zobaczyć mapowania dokładnie tej rewizji, oraz `Enter` na wtyczce, aby rozwinąć jej commit, zależności i czasy ładowania.
3. Na nowej maszynie wykonaj `:Lazy! restore`. Bang czeka na koniec, a `restore` respektuje `nvim/lazy-lock.json`.
4. Zamknij i ponownie uruchom Neovim. `:Lazy health` sprawdzi sam menedżer, a `:Lazy profile` pokaże koszt startu.

#### Tutorial: bezpieczna aktualizacja jednej wtyczki

1. Wykonaj `:Lazy check nazwa`, przeczytaj log i diff bez zmiany checkoutu.
2. Uruchom `:Lazy update nazwa`, nie globalne `sync`, jeżeli chcesz ograniczyć zakres.
3. Zrestartuj Neovim i przetestuj funkcje zależne od wtyczki.
4. W powłoce sprawdź `git diff -- nvim/lazy-lock.json`; nowy hash jest częścią zmiany, którą trzeba świadomie zaakceptować.
5. Przy regresji wykonaj `:Lazy! restore nazwa`, zrestartuj i ponownie sprawdź lockfile.

#### Diagnostyka i bezpieczeństwo

- `:Lazy debug` pokazuje runtimepath i źródło specyfikacji, a `:Lazy log nazwa` historię ostatnich zmian.
- Gołe biblioteki bez wyzwalacza mogą zostać doładowane przy pierwszym `require()`, dlatego „niezaładowana przy starcie” nie oznacza „nieużywana”.
- Domyślne `local_spec=true` pozwala projektowi zaproponować `.lazy.lua`. Lazy używa `vim.secure.read`; przed udzieleniem zaufania przeczytaj plik, bo specyfikacja może uruchamiać kod i buildy.
- `install`, `update`, `restore`, `clean` i `sync` mogą przepisać lockfile. `clean` usuwa katalogi, a `build` uruchamia kod. Do odtworzenia tego repo używaj `restore`.

**Źródła przypiętej rewizji:** [help `lazy.nvim.txt`](https://github.com/folke/lazy.nvim/blob/306a05526ada86a7b30af95c5cc81ffba93fef97/doc/lazy.nvim.txt), [polecenia UI](https://github.com/folke/lazy.nvim/blob/306a05526ada86a7b30af95c5cc81ffba93fef97/lua/lazy/view/commands.lua), [obsługa lockfile](https://github.com/folke/lazy.nvim/blob/306a05526ada86a7b30af95c5cc81ffba93fef97/lua/lazy/manage/lock.lua).

<a id="plugin-ui"></a>
### `ui`

**Co robi i po co:** przypięty `nvchad/ui` dostarcza statusline, tabufline, renamer LSP, dashboard, cheatsheet, picker motywów, automatyczne signature help i podgląd kolorów. Ładuje się natychmiast (`lazy=false`). Lokalny `chadrc.lua` włącza tabufline i statusline, pokazuje względną ścieżkę pliku i używa motywu `ayu_dark`.

**Aktywne lokalne:** `<leader>th` otwiera picker motywów; `<leader>ra` po attach LSP otwiera renamer; `<leader>b`, fizyczne `Cmd-h`, `Cmd-l`, `Cmd-q` sterują tabufline.

**Polecenia:** `:Nvdash`, `:NvCheatsheet`, `:MasonInstallAll`. Ostatnie próbuje zebrać narzędzia z konfiguracji LSP, Conform i nvim-lint, ale nie obejmuje adapterów DAP ani aktualizacji już zainstalowanych pakietów. Na świeżym starcie, zanim konfiguracje LSP zostaną załadowane, pierwszy przebieg może wykryć tylko formatery i lintery; najpierw otwórz obsługiwany plik albo użyj jawnej listy `:MasonInstall`.

| Kontekst | Klawisz | Działanie | Stan |
|---|---|---|---|
| picker motywów, `i` | `Ctrl-n` / `Down`, `Ctrl-p` / `Up` | Następny / poprzedni motyw | **Kontekstowe** |
| picker motywów, `n` | `j` / `Down`, `k` / `Up` | Następny / poprzedni motyw | **Kontekstowe** |
| picker motywów, `i,n` | `Enter` | Zapis wybranego motywu w `chadrc.lua` i zamknięcie | **Kontekstowe** |
| picker motywów, `i` | `Ctrl-w` | Usunięcie poprzedniego słowa promptu | **Kontekstowe** |
| renamer, `i,n` | `Esc` | Anulowanie i usunięcie popupu | **Kontekstowe** |
| cheatsheet | `q` / `Esc` | Zamknięcie | **Kontekstowe** |

#### Co pokazują statusline i tabufline

- Statusline pokazuje tryb, ikonę i względną ścieżkę, branch i statystyki Gitsigns, diagnostykę, klienta LSP, katalog roboczy oraz pozycję. Przy małej szerokości mniej ważne moduły znikają.
- Tabufline pojawia się dopiero przy co najmniej dwóch listowanych buforach albo kartach. Każda karta utrzymuje własny zestaw buforów.
- Kliknięcie nazwy przełącza bufor, ikona zamknięcia go zamyka, a zmodyfikowany plik wywołuje `confirm bd`. Zamknięty terminal jest ukrywany zamiast zabijania procesu i można go odnaleźć przez `:Telescope terms`.
- Przycisk przełączania motywu w tabufline używa pary `theme_toggle`. Lokalny `ayu_dark` nie należy do domyślnej pary `onedark`/`one_light`, dlatego korzystaj z `<leader>th`.

#### Tutorial: motyw, dashboard i cheatsheet

1. Naciśnij `<leader>th`. W Insert filtruj nazwę, poruszaj się `Ctrl-n` / `Ctrl-p`; po `Esc` używaj `j/k`.
2. `Enter` zapisuje wybór przez tekstową zmianę `nvim/lua/chadrc.lua`. Po wyborze sprawdź diff tego pliku. Zamknięcie bez zatwierdzenia przywraca zapisany motyw.
3. Wpisz `:Nvdash`. W dashboardzie działają lokalne `ff`, `fo`, `fw`, `th`, `ch`, `j/k` i `Enter`, bez leadera. Polecenie nie jest skonfigurowane jako ekran startowy.
4. Otwórz `:NvCheatsheet`. Lista jest budowana z aktywnych mapowań mających `desc`; nie zastępuje `:verbose map`, bo pomija część trybów i `<Plug>`.

#### Tutorial: rename i automatyczna pomoc LSP

1. W buforze z podłączonym LSP ustaw kursor na symbolu i użyj `<leader>ra`.
2. Wpisz nową nazwę i zatwierdź `Enter`; pusta lub niezmieniona nazwa nic nie robi, a `Esc` anuluje.
3. Rename może zmienić wiele buforów lub plików workspace. Zapisz je i obejrzyj `git diff`.
4. Podczas wpisywania argumentów funkcji UI może automatycznie otwierać signature help po znakach triggerujących serwera. Jest to niezależne od ręcznego `Ctrl-s` Neovim.

#### Colorify i terminale

- Aktywne domyślnie `colorify` rozpoznaje `#RRGGBB`, dodaje próbkę inline i może pytać LSP o `documentColor`. Nie ma lokalnego toggle; przy problemach wydajnościowych kontroluje je opcja `M.colorify.enabled` w `chadrc.lua`.
- Moduł terminali NvChad oraz `:Telescope terms` istnieją w kodzie, lecz repo nie definiuje launchera terminala NvChad. Przykładowe `<leader>pt` z README jest **Przykładem nieaktywnym**.

**Wymagania:** `base46`, `volt`, ikony z `nvim-web-devicons` i czcionka Nerd Font. Renamer wymaga serwera LSP obsługującego rename.

**Diagnostyka:** `:verbose nmap <leader>th`, `:verbose nmap <leader>ra`, `:NvCheatsheet`, `:messages` oraz `:lua =require("nvconfig").ui` pokazują odpowiednio źródło mapowań, aktywne opcje i błędy. Brak danych Git/LSP w statusline zwykle oznacza brak repo albo klienta, nie awarię całego UI.

**Źródła przypiętej rewizji:** [help `nvui.txt`](https://github.com/NvChad/ui/blob/aa95aca6936f277417d2565d9416713198b6dbd1/doc/nvui.txt), [picker motywów](https://github.com/NvChad/ui/blob/aa95aca6936f277417d2565d9416713198b6dbd1/lua/nvchad/themes/init.lua), [tabufline](https://github.com/NvChad/ui/tree/aa95aca6936f277417d2565d9416713198b6dbd1/lua/nvchad/tabufline), [colorify](https://github.com/NvChad/ui/tree/aa95aca6936f277417d2565d9416713198b6dbd1/lua/nvchad/colorify).

<a id="plugin-base46"></a>
### `base46`

**Co robi i po co:** silnik motywów NvChad. Build wtyczki generuje cache highlightów, a konfiguracja lokalna dogrywa cache dla statusline, blankline, składni, LSP, cmp, Git, Mason, Telescope i Treesitter. Nie ma własnych domyślnych mapowań ani publicznych poleceń użytkownika.

**Konfiguracja lokalna:** motyw `ayu_dark`, bez przezroczystości, z override'ami komentarzy, właściwości, typów, modułów, operatorów, wyjątków i interpunkcji. `require("base46").load_all_highlights()` jest API Lua używanym przez build, nie poleceniem Ex.

#### Tutorial: wybór, inspekcja i naprawa kolorów

1. Do zwykłej zmiany użyj `<leader>th`; zapis trafia do `chadrc.lua`, nie tylko do bieżącej sesji.
2. Aby ustalić źródło koloru pod kursorem, użyj `:Inspect`; drzewo składni pokaże `:InspectTree`, a konkretną grupę `:hi NazwaGrupy`.
3. Gdy cache został usunięty lub jest niespójny, wykonaj `:Lazy build base46` albo `:lua require("base46").load_all_highlights()`.
4. `load_all_highlights()` kompiluje i natychmiast ładuje grupy, więc restart nie jest wymagany. Można go wykonać dopiero jako niezależny test czystego startu.

**Opcjonalne upstream:** `compile()` tylko generuje cache, `toggle_theme()` zapisuje przełączenie skonfigurowanej pary, a `toggle_transparency()` zapisuje zmianę przezroczystości. Oba toggle modyfikują `chadrc.lua` tekstowo i nie mają lokalnych mapowań.

**Źródła przypiętej rewizji:** [README](https://github.com/NvChad/base46/blob/884b990dcdbe07520a0892da6ba3e8d202b46337/README.md), [kompilacja i ładowanie](https://github.com/NvChad/base46/blob/884b990dcdbe07520a0892da6ba3e8d202b46337/lua/base46/init.lua).

<a id="plugin-volt"></a>
### `volt`

**Co robi i po co:** framework interaktywnych okien używany przez picker motywów, Minty, Menu i lokalny drawer `claude.nvim`. Nie oferuje samodzielnego launchera ani polecenia Ex.

| Okno zbudowane na Volt | Klawisz | Działanie | Stan |
|---|---|---|---|
| bufor UI | `Ctrl-t` | Cykliczna zmiana bufora/okna składowego | **Kontekstowe** |
| bufor UI | `q` / `Esc` | Zamknięcie całego UI | **Kontekstowe** |
| bufor zarejestrowany przez `volt.events.add()` | `Enter` | Uruchomienie elementu pod kursorem | **Kontekstowe** |
| bufor zarejestrowany przez `volt.events.add()` | `Tab` / `Shift-Tab` | Następny / poprzedni wiersz z elementem klikalnym | **Kontekstowe** |

#### Jak używać Volta pośrednio

1. Otwórz `:Huefy`: Minty rejestruje interaktywne eventy, więc `Tab`, `Shift-Tab`, `Enter`, mysz i `Ctrl-t` działają.
2. Otwórz `<leader>th`: picker motywów używa własnych `Ctrl-n`/`Ctrl-p` i `j/k`; nie rejestruje eventów Volta, więc `Tab` nie jest tam nawigacją.
3. W drawerze Claude część skrótów pochodzi z samego drawera, a `Enter`/`Tab` w shellu z Volta. Zawsze pierwszeństwo ma opis konkretnego konsumenta.
4. `q` i `Esc` zamykają UI w Normal. W buforze promptu Insert litera `q` pozostaje tekstem; wyjdź do Normal albo użyj lokalnego skrótu zamknięcia.

Volt nie ma własnego health checku ani launchera. Gdy UI konsumenta nie powstaje, sprawdź `:Lazy`, `:messages` i stan tej konkretnej wtyczki.

**Źródła przypiętej rewizji:** [README](https://github.com/nvzone/volt/blob/620de1321f275ec9d80028c68d1b88b409c0c8b1/README.md), [wspólne mapowania](https://github.com/nvzone/volt/blob/620de1321f275ec9d80028c68d1b88b409c0c8b1/lua/volt/init.lua), [eventy interaktywne](https://github.com/nvzone/volt/blob/620de1321f275ec9d80028c68d1b88b409c0c8b1/lua/volt/events.lua).

<a id="plugin-menu"></a>
### `menu`

**Co robi i po co:** biblioteka kontekstowych, także zagnieżdżonych menu na Volt. Lokalna konfiguracja jej nie otwiera i nie definiuje `RightMouse` ani innego launchera.

| Klawisz | Działanie po ręcznym otwarciu menu | Stan |
|---|---|---|
| `h` / `l` | Poprzednia / następna kolumna-okno menu | **Kontekstowe** |
| `Enter` | Wykonanie pozycji pod kursorem | **Kontekstowe** |
| `q` / `Esc` | Zamknięcie przez Volt | **Kontekstowe** |
| klawisz pokazany przy pozycji | Bezpośrednie wykonanie pozycji | **Kontekstowe** |

Mapowania otwierające menu z README są **Przykładem nieaktywnym**. `require("menu").open(...)` jest API Lua, nie poleceniem Ex.

#### Co jest dostępne, ale nieaktywne

Przypięta rewizja zawiera presety `default`, `nvimtree`, `gitsigns`, `lsp` i `neo-tree`. Można je otworzyć dopiero ręcznym API, na przykład `:lua require("menu").open("default")`. `h/l` przełącza kolumny, `Enter` wykonuje pozycję, `Tab` porusza się po klikalnych wierszach, a `q` zamyka.

Nie jest to bezpieczny „podgląd”: presety zawierają między innymi usunięcie treści bufora, operacje cut/paste/delete nvim-tree oraz reset Gitsigns. Nie otwieraj i nie wykonuj nieznanej pozycji tylko w celu sprawdzenia interfejsu. `nvzone/menu` jest inną biblioteką niż komponent `nui.menu` z `nui.nvim`.

**Tutorial użytkownika:** w bieżącej konfiguracji nie ma codziennego przepływu Menu. Pełne zrozumienie oznacza właśnie świadomość, że instalacja jest biblioteką opcjonalną, a skróty `RightMouse` i `Ctrl-t` z README nie istnieją lokalnie.

**Źródła przypiętej rewizji:** [README i przykładowe launchery](https://github.com/nvzone/menu/blob/7a0a4a2896b715c066cfbe320bdc048091874cc6/README.md), [presety](https://github.com/nvzone/menu/tree/7a0a4a2896b715c066cfbe320bdc048091874cc6/lua/menus), [mapowania menu](https://github.com/nvzone/menu/blob/7a0a4a2896b715c066cfbe320bdc048091874cc6/lua/menu/mappings.lua).

<a id="plugin-minty"></a>
### `minty`

**Co robi i po co:** dwa narzędzia kolorystyczne zbudowane na Volt: Huefy wybiera kolor, Shades generuje odcienie. Ładuje się dopiero po poleceniu.

**Polecenia:** `:Huefy`, `:Shades`.

| Kontekst | Klawisz | Działanie | Stan |
|---|---|---|---|
| Huefy/Shades | `Ctrl-t` | Zmiana składowego okna | **Kontekstowe**, Volt |
| Huefy/Shades | `Tab` / `Shift-Tab`, `Enter` | Wybór elementu klikalnego | **Kontekstowe**, Volt |
| slider | `h` / `l` | Ruch po suwaku | **Kontekstowe** |
| paleta | `Ctrl-s` | Zastosowanie koloru w oryginalnym wierszu i zamknięcie | **Kontekstowe**; w tmux wyślij `Ctrl-s Ctrl-s` |
| UI | `q` / `Esc` | Zamknięcie | **Kontekstowe** |

**Wymagania:** `volt`, prawidłowe kolory terminala.

#### Tutorial: Huefy

1. Ustaw kursor na istniejącym kodzie dokładnie w formacie `#RRGGBB`, na przykład `#61afef`, i uruchom `:Huefy`. Gdy pod kursorem nie ma poprawnego kodu, punktem startowym jest `#61afef`.
2. `Tab` / `Shift-Tab` przechodzi po klikalnych wierszach, `Enter` wybiera element, `Ctrl-t` zmienia składowe okno, a na sliderze `h/l` zmienia wartość.
3. Porównuj sekcje wariantów jasnych/ciemnych, hue, RGB, saturation, lightness i kolorów komplementarnych. Prompt ręczny powinien zawierać pełne `#RRGGBB`.
4. `q` lub `Esc` w Normal zamyka bez zastosowania. `Ctrl-s` albo przycisk Save zamyka UI i zastępuje na oryginalnym wierszu wszystkie dokładne wystąpienia sześciu cyfr starego koloru nowym kodem.
5. Save nie kopiuje do schowka. Po zastosowaniu sprawdź wiersz; w razie pomyłki użyj od razu `u`.

#### Tutorial: Shades

1. Ustaw kursor na `#RRGGBB` i uruchom `:Shades`.
2. Przełączaj zakładki `Variants`, `Saturation` i `Hues`; wybierz układ 6 albo 12 kolumn i dopasuj intensywność.
3. Zastosowanie ma tę samą semantykę co Huefy: modyfikuje oryginalny wiersz, a nie globalną paletę czy schowek.

W tmux dosłowny `Ctrl-s` to `Ctrl-s Ctrl-s`. Stary help tej rewizji pokazuje nieaktualne API `require("minty.huefy").save_color()`; rzeczywista funkcja znajduje się w module `.api`, ale nie należy wywoływać jej poza aktywnym UI.

**Źródła przypiętej rewizji:** [help Minty](https://github.com/nvzone/minty/blob/aafc9e8e0afe6bf57580858a2849578d8d8db9e0/doc/minty.txt), [Huefy](https://github.com/nvzone/minty/tree/aafc9e8e0afe6bf57580858a2849578d8d8db9e0/lua/minty/huefy), [Shades](https://github.com/nvzone/minty/tree/aafc9e8e0afe6bf57580858a2849578d8d8db9e0/lua/minty/shades).

### Infrastruktura tej grupy

<a id="plugin-nvim-web-devicons"></a>
### `nvim-web-devicons`

**Rola:** dostarcza ikony według pełnej nazwy i rozszerzenia dla statusline, tabufline, nvim-tree i Telescope. Nie ma osobnego eksploratora ani codziennego launchera.

#### Tutorial diagnostyczny

1. Otwórz kilka plików różnych typów i porównaj ikony w tabufline, drzewie i pickerze.
2. Wykonaj `:NvimWebDeviconsHiTest`; polecenie pojawia się po pierwszym setup, który zwykle wywołuje konsument. Na całkiem świeżym starcie użyj najpierw `:Lazy load nvim-web-devicons` i `:lua require("nvim-web-devicons").get_icon("init.lua", "lua")`.
3. Bufor testowy pokazuje glyph, nazwę kategorii, highlight i jego efektywną definicję; zamknij go przez `:bd`.
4. Kwadraty lub tofu oznaczają zwykle zły font. Ustaw Nerd Font co najmniej z linii 2.3. Nazwy plików są dopasowywane bez uwzględnienia wielkości liter, rozszerzenia z uwzględnieniem.

API override ikon jest przeznaczone dla konfiguracji i powinno być uruchomione przed pierwszym setup. Nie jest potrzebne do normalnego użycia.

**Źródła przypiętej rewizji:** [README](https://github.com/nvim-tree/nvim-web-devicons/blob/803353450c374192393f5387b6a0176d0972b848/README.md), [test highlightów](https://github.com/nvim-tree/nvim-web-devicons/blob/803353450c374192393f5387b6a0176d0972b848/lua/nvim-web-devicons/hi-test.lua).

<a id="plugin-plenary-nvim"></a>
### `plenary.nvim`

**Rola:** biblioteka procesów, ścieżek i asynchroniczności używana tutaj przez Telescope, Neogit, NvChad UI i Base46. Przypięty Diffview nie wymaga już Plenary w runtime.

Zwykły użytkownik nie otwiera Plenary. Dla autorów wtyczek dostępny jest test harness:

1. W razie potrzeby załaduj bibliotekę przez `:Lazy load plenary.nvim`, bo lokalna specyfikacja nie ma triggera `cmd`.
2. `:PlenaryBustedFile %` uruchamia bieżący plik testowy, a `:PlenaryBustedDirectory ścieżka` rekurencyjnie znajduje `*_spec.lua` i domyślnie uruchamia je równolegle.
3. Wynik pojawia się w popupie zamykanym `q`; headless zwraca kod 0 albo 1.
4. Testy to dowolny kod Lua i mogą zmieniać pliki lub uruchamiać procesy. Opcje directory są parsowane jako Lua, więc nie wklejaj niezaufanych argumentów.

`<Plug>PlenaryTestFile` istnieje, ale repo nie przypisuje mu klawisza. Pozostałe moduły `async`, `job`, `path`, `scandir`, `curl` i profiler są API deweloperskim.

**Źródła przypiętej rewizji:** [README](https://github.com/nvim-lua/plenary.nvim/blob/b9fd5226c2f76c951fc8ed5923d85e4de065e509/README.md), [help test harness](https://github.com/nvim-lua/plenary.nvim/blob/b9fd5226c2f76c951fc8ed5923d85e4de065e509/doc/plenary-test.txt).

<a id="plugin-nui-nvim"></a>
### `nui.nvim`

**Rola:** biblioteka komponentów UI używana przez CodeDiff, przede wszystkim `nui.tree`, `nui.line` i `nui.split`. Nie ma `setup()`, polecenia Ex, globalnych mapowań ani panelu do samodzielnego otwarcia.

**Jak sprawdzić działanie:** otwórz `<leader>gD` albo `<leader>gh`. Jeżeli explorer i historia CodeDiff renderują się poprawnie, NUI działa. Przy błędzie `module 'nui.tree' not found` sprawdź `:Lazy`, `:messages`, zgodność commita i wykonaj `:Lazy! restore nui.nvim`, a następnie restart.

Przykłady Popup, Input, Menu, Layout i Split z README są kodem dla autorów wtyczek. Ich `j/k/Tab/Enter/Esc` nie są globalnymi mapowaniami ani skrótami panelu CodeDiff.

**Źródła przypiętej rewizji:** [README i API komponentów](https://github.com/MunifTanjim/nui.nvim/blob/de740991c12411b663994b2860f1a4fd0937c130/README.md), [komponent Menu](https://github.com/MunifTanjim/nui.nvim/blob/de740991c12411b663994b2860f1a4fd0937c130/lua/nui/menu/init.lua).

<a id="plugin-nvim-nio"></a>
### `nvim-nio`

**Rola:** asynchroniczna biblioteka wymagana przez `nvim-dap-ui`. Nie ma konfiguracji użytkownika, poleceń, mapowań ani własnego interfejsu debuggera.

**Jak sprawdzić działanie:** uruchom dowolny trigger DAP i `<leader>du`. Poprawne otwarcie paneli jest testem NIO. Jeżeli dap-ui zgłasza brak `nio`, sprawdź zależność w `:Lazy`, `:messages`, wykonaj `:Lazy! restore nvim-nio` i zrestartuj Neovim.

`nio.run`, taski, eventy, future, queue, semaphore, async file/process/libuv/LSP/UI oraz test wrappery są **Opcjonalnym upstream API** dla autorów pluginów, nie osobnym workflow użytkownika.

**Źródła przypiętej rewizji:** [README](https://github.com/nvim-neotest/nvim-nio/blob/edcc181a875301dd21840189aa2f2f9ad69fc172/README.md), [help API](https://github.com/nvim-neotest/nvim-nio/blob/edcc181a875301dd21840189aa2f2f9ad69fc172/doc/nio.txt).

</details>

<details>
<summary><strong>Wcięcia, formatowanie, lint i Mason</strong></summary>

<a id="plugin-indent-blankline"></a>
### `indent-blankline.nvim`

**Co robi i po co:** rysuje pionowe prowadnice wcięć i bieżącego scope, dzięki czemu łatwiej śledzić zagnieżdżenie. Ładuje się po jednorazowym evencie `User FilePost` dla realnego pliku.

**Konfiguracja lokalna:** znak `│`, grupy `IblChar` i `IblScopeChar`, ukrycie pierwszego poziomu spacji oraz cache Base46 z kolorami awaryjnymi, gdy cache nie istnieje.

**Mapowania:** brak aktywnych i brak domyślnych.

**Polecenia:** `:IBLEnable`, `:IBLDisable`, `:IBLToggle`, `:IBLEnableScope`, `:IBLDisableScope`, `:IBLToggleScope`.

#### Tutorial: prowadnice i scope

1. Otwórz zagnieżdżony plik Lua, Python, TypeScript albo Go i ustaw kursor w wewnętrznym bloku.
2. Zwykłe linie pokazują poziomy białych znaków. Wyróżniony scope próbuje pokazać bieżący blok składniowy i wymaga działającego parsera Treesitter.
3. Wykonaj `:IBLToggleScope`, aby porównać sam scope, a `:IBLToggle`, aby ukryć lub przywrócić wszystkie prowadnice.
4. `:IBLDisable` i `:IBLEnable` przydają się przy nagrywaniu ekranu lub diagnozie kolorów; warianty `Scope` nie wyłączają zwykłych linii.

Polecenia pojawiają się dopiero po pierwszym realnym pliku, ponieważ wtyczka czeka na `User FilePost`. Brak scope przy widocznych prowadnicach najczęściej oznacza brak parsera albo query, nie awarię IBL. Sprawdź `:InspectTree`, `:TSLog` i `:hi IblScopeChar`.

**Źródła przypiętej rewizji:** [README](https://github.com/lukas-reineke/indent-blankline.nvim/blob/005b56001b2cb30bfa61b7986bc50657816ba4ba/README.md), [help](https://github.com/lukas-reineke/indent-blankline.nvim/blob/005b56001b2cb30bfa61b7986bc50657816ba4ba/doc/indent_blankline.txt), [polecenia](https://github.com/lukas-reineke/indent-blankline.nvim/blob/005b56001b2cb30bfa61b7986bc50657816ba4ba/after/plugin/commands.lua).

<a id="plugin-conform"></a>
### `conform.nvim`

**Co robi i po co:** uruchamia zewnętrzne formatery i zachowuje pozycję kursora lepiej niż ręczne filtrowanie bufora. Ładuje się na `BufWritePre`; użycie `<leader>fm` może go też doładować przez moduł Lazy.

**Konfiguracja lokalna:** Lua używa `stylua`; Python kolejno `ruff_fix` i `ruff_format`. Zapis ma timeout 3000 ms i `lsp_fallback=true`. `<leader>fm` działa w `n,x` i również ma fallback LSP.

**Polecenie:** `:ConformInfo` pokazuje aktywne formatery i ścieżkę logu. Wtyczka nie instaluje domyślnych mapowań.

**Wymagania:** `stylua` i `ruff` w `PATH`; dla innych języków serwer LSP z formatowaniem. Oba narzędzia są w `Brewfile`, a mogą też pochodzić z Mason.

#### Jak wybierany jest formatter

| Filetype | Kolejność aktywna lokalnie |
|---|---|
| Lua | `stylua` |
| Python | `ruff_fix`, następnie `ruff_format` |
| Pozostałe | Formatter LSP tylko wtedy, gdy brak dostępnego zewnętrznego formattera |

`ruff_fix` uruchamia `ruff check --fix`, więc może usunąć nieużywany import lub zastosować regułę naprawczą. `ruff_format` dopiero potem formatuje kod. Timeout 3000 ms dotyczy zapisu; ręczne `<leader>fm` nie podaje timeoutu i korzysta z domyślnego limitu Conform, zwykle 1000 ms.

#### Tutorial: plik i zaznaczenie

1. Otwórz Lua lub Python i wykonaj `:ConformInfo`. Sprawdź nazwę formattera, jego status oraz ścieżkę logu.
2. Zapisz plik. Formatowanie jest synchroniczne w `BufWritePre`, więc na dysk trafia już wynik formattera.
3. Zaznacz kilka wierszy w Visual i użyj `<leader>fm`. Zaznaczenie znakowe i wierszowe staje się zakresem; blockwise Visual nie jest rozpoznawane jako zakres i może sformatować cały bufor.
4. W Python `ruff_format` obsługuje zakres natywnie, lecz `ruff_fix` analizuje pełne wejście i Conform aplikuje nakładające się zmiany. Po operacji zawsze obejrzyj diff.
5. W HTML, CSS albo TypeScript bez skonfigurowanego zewnętrznego formattera fallback może użyć podłączonego LSP, o ile serwer reklamuje formatowanie.

#### Diagnostyka

- `:ConformInfo` jest podstawowym źródłem: pokazuje formatter, executable i log.
- `:echo executable('stylua')` oraz `:echo executable('ruff')` odróżniają brak programu od błędu konfiguracji.
- Jeżeli zapis trwa ponad 3 sekundy, formatowanie zgłosi timeout. Ręczne wywołanie może zakończyć się wcześniej ze względu na inny limit.
- Brak formattera i brak zdolnego LSP oznacza no-op lub komunikat; Conform nie instaluje programów, robi to Homebrew albo Mason.

**Źródła przypiętej rewizji:** [README](https://github.com/stevearc/conform.nvim/blob/5ac2bb57a9096f00ca50e1a3c46020d5930319b8/README.md), [help](https://github.com/stevearc/conform.nvim/blob/5ac2bb57a9096f00ca50e1a3c46020d5930319b8/doc/conform.txt), [formatter `ruff_fix`](https://github.com/stevearc/conform.nvim/blob/5ac2bb57a9096f00ca50e1a3c46020d5930319b8/lua/conform/formatters/ruff_fix.lua).

<a id="plugin-nvim-lint"></a>
### `nvim-lint`

**Co robi i po co:** asynchronicznie publikuje diagnostykę narzędzi spoza LSP. Ładuje się przed odczytem lub utworzeniem pliku.

**Konfiguracja lokalna:** tylko Python i `mypy`, uruchamiane na `BufWritePost`. Jeśli `mypy` nie jest wykonywalne, lint jest pomijany, a jedna sesyjna notyfikacja wyjaśnia przyczynę. Wtyczka nie tworzy mapowań ani publicznego polecenia Ex; `lint.try_lint()` to API Lua, nie polecenie użytkownika.

**Wymagania:** `mypy` w `PATH` dla lintowania; bez niego konfiguracja nadal działa bez błędu.

#### Tutorial: lint Python

1. Otwórz projekt Python z właściwego katalogu i sprawdź `:pwd`; mypy jest uruchamiane z bieżącego CWD, więc od niego zależy odnalezienie konfiguracji i importów.
2. Wykonaj `:echo executable('mypy')`. Wynik `1` oznacza, że zapis może uruchomić linter.
3. Zapisz plik. `BufWritePost` uruchamia mypy na treści z dysku, a kolejny szybki zapis anuluje poprzedni proces dla tego bufora.
4. Przechodź diagnostykę `[d` / `]d`, pokaż szczegóły `<leader>dd` albo wypełnij location list przez `<leader>ds`.
5. Pyright i mypy mogą zgłaszać podobne błędy typów. Sprawdź źródło diagnostyki w floacie, zanim uznasz wpis za duplikat.

W tej konfiguracji upstreamowa lista linterów została zastąpiona tabelą zawierającą tylko `python = { 'mypy' }`. Brak mypy pomija uruchomienie i pokazuje jedno ostrzeżenie na sesję. Nie czyści to automatycznie starych diagnostyk mypy z wcześniejszego udanego przebiegu; po zmianie środowiska ponownie zapisz lub zrestartuj bufor.

Nie istnieje publiczne polecenie Ex nvim-lint. Ręczne `require('lint').try_lint()` jest **Opcjonalnym upstream API**, a nie aktywnym skrótem.

**Źródła przypiętej rewizji:** [README](https://github.com/mfussenegger/nvim-lint/blob/bcd1a44edbea8cd473af7e7582d3f7ffc60d8e81/README.md), [help](https://github.com/mfussenegger/nvim-lint/blob/bcd1a44edbea8cd473af7e7582d3f7ffc60d8e81/doc/lint.txt), [definicja mypy](https://github.com/mfussenegger/nvim-lint/blob/bcd1a44edbea8cd473af7e7582d3f7ffc60d8e81/lua/lint/linters/mypy.lua).

<a id="plugin-mason"></a>
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
| lista | `1` / `2` / `3` / `4` / `5` | Wszystkie / LSP / DAP / Linter / Formatter | **Domyślne wtyczki** |
| UI | `q` / `Esc` | Zamknięcie; `Esc` najpierw czyści aktywny filtr | **Domyślne wtyczki** |
| UI | `g?` | Pomoc | **Domyślne wtyczki** |

#### Tutorial: instalacja i aktualizacja narzędzia

1. Otwórz `:Mason` i naciśnij `g?`. Klawisze `2`–`5` ograniczają kategorię, `Ctrl-f` filtruje język, a zwykłe `/` wyszukuje tekst bufora.
2. Ustaw kursor na pakiecie i `Enter`, aby zobaczyć wersje, linki i log. `i` instaluje, `u` reinstaluje lub aktualizuje wskazany pakiet.
3. `c` sprawdza jedną wersję, `C` wszystkie, a `U` aktualizuje wszystkie przestarzałe instalacje. `:MasonUpdate` tylko odświeża rejestry; nie aktualizuje pakietów.
4. Polecenie obsługuje między innymi `pakiet@wersja`, `--force`, `--debug`, `--strict` i `--target=...`; używaj ich tylko, gdy dany pakiet wspiera wersje lub target.
5. Po instalacji sprawdź rzeczywisty executable, na przykład `:echo executable('typescript-language-server')`, potem odpowiedni konsument: `:checkhealth vim.lsp`, `:ConformInfo` albo `:checkhealth dap`.

#### `:MasonInstallAll` bez nieporozumień

Polecenie NvChad zbiera włączone konfiguracje LSP oraz formatery Conform i lintery nvim-lint. Nie skanuje adapterów DAP i nie aktualizuje istniejących instalacji. Na pustym starcie może odczytać serwery zanim `nvim-lspconfig` je zarejestruje, dlatego najpewniejsza procedura to najpierw otworzyć plik aktywujący LSP albo jawnie wykonać:

```vim
:MasonInstall lua-language-server html-lsp css-lsp pyright ruff typescript-language-server dockerfile-language-server docker-compose-language-service stylua mypy debugpy delve js-debug-adapter
```

**Bezpieczeństwo:** `X` odinstalowuje pakiet. Już działający proces może przetrwać, ale kolejne uruchomienie LSP, formattera lub adaptera nie znajdzie executable. `PATH="skip"` oznacza, że GUI Neovim bez środowiska `.zshrc` może nie widzieć Masona mimo poprawnej instalacji.

**Diagnostyka:** `:checkhealth mason`, `:MasonLog`, `:echo $PATH` i sprawdzenie `~/.local/share/nvim/mason/bin` odróżniają błąd pobierania, instalacji i widoczności programu.

**Źródła przypiętej rewizji:** [README](https://github.com/mason-org/mason.nvim/blob/44d1e90e1f66e077268191e3ee9d2ac97cc18e65/README.md), [help](https://github.com/mason-org/mason.nvim/blob/44d1e90e1f66e077268191e3ee9d2ac97cc18e65/doc/mason.txt), [mapowania UI](https://github.com/mason-org/mason.nvim/blob/44d1e90e1f66e077268191e3ee9d2ac97cc18e65/lua/mason/settings.lua).

</details>

<details>
<summary><strong>LSP, completion, snippety i automatyczne pary</strong></summary>

<a id="plugin-nvim-lspconfig"></a>
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

`ts_ls`, HTML i CSS mogą preferować executable z projektowego `node_modules/.bin`. Otwierając niezaufane repozytorium, pamiętaj, że klient może uruchomić kod dostarczony przez projekt. Docker Compose wymaga poprawnie wykrytego filetype, zwykle `yaml.docker-compose`.

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
| `n` | `grn` | Rename | **Domyślne Neovim** |
| `n,x` | `gra` | Code action | **Domyślne Neovim** |
| `n` | `gri` | Implementation | **Domyślne Neovim** |
| `n` | `grr` | References bez lokalnego pickera | **Domyślne Neovim** |
| `n` | `grt` | Type definition | **Domyślne Neovim** |
| `n` | `grx` | Uruchomienie code lens | **Domyślne Neovim** |
| `n` | `gO` | Symbole dokumentu | **Domyślne Neovim** |
| `n,x` | `gx` | Otworzenie linku pod kursorem, także linku dokumentu LSP | **Domyślne Neovim** |
| `x,o` | `an` / `in` | Zewnętrzna / wewnętrzna selekcja węzła Treesitter z fallbackiem LSP | **Domyślne Neovim** |
| `i,s` | `Ctrl-s` | Signature help | **Domyślne Neovim**; konflikt z prefixem tmux |
| `n`, po attach | `K` | Hover, jeśli nie zastąpiono `keywordprg`/mapowania | **Kontekstowe** |
| `n`, po attach | `Ctrl-]`, `Ctrl-w ]`, `Ctrl-w }` | Nawigacja tagfunc przez LSP | **Kontekstowe** |
| `n,x`, po attach | `gq` | Format przez formatexpr LSP, jeśli wspierane | **Kontekstowe** |

Wbudowane diagnostyki: `[d`, `]d`, `[D`, `]D`, `Ctrl-w d`, `Ctrl-w Ctrl-d`. Lokalna konfiguracja zachowuje ich implementację Neovim 0.12 i dodaje `<leader>dd`, `<leader>ds`, `<leader>q`. Neovim może po attach uruchamiać file watching i podświetlenie kolorów dokumentu. LuaLS reklamuje inlay hints i code lenses, lecz wyświetlanie inlay hints oraz adnotacji code lens nie jest tutaj jawnie włączone.

**Polecenia Neovim 0.12:** `:lsp enable [config]`, `:lsp disable [config]`, `:lsp restart [client]`, `:lsp stop [client]`, `:checkhealth vim.lsp`. `stop` kończy bieżącego klienta tymczasowo, `disable` wyłącza konfigurację i bieżące/przyszłe uruchomienia, a `restart` zachowuje konfigurację. Gdy wbudowane `:lsp` istnieje, przypięty lspconfig nie rejestruje starszych aliasów `:LspInfo`, `:LspStart`, `:LspStop`, `:LspRestart` ani `:LspLog`. TypeScript tworzy buffer-local `:LspTypescriptSourceAction` i `:LspTypescriptGoToSourceDefinition`. Pyright tworzy buffer-local `:LspPyrightOrganizeImports` oraz `:LspPyrightSetPythonPath {path}`; zmiana interpretera jest sesyjna.

**Wymagania:** Neovim 0.12 dla używanego interfejsu i restartu, executable serwerów w `PATH`, poprawny root projektu. Dla TypeScript zalecany jest `tsconfig.json`/`jsconfig.json` oraz lockfile menedżera pakietów.

#### Tutorial: od uruchomienia do refaktoryzacji

1. Uruchom Neovim w katalogu projektu i otwórz obsługiwany plik. Sprawdź `:set filetype?`, ponieważ filetype wybiera konfigurację serwera.
2. Wykonaj `:checkhealth vim.lsp` oraz `:lua =vim.lsp.get_clients({ bufnr = 0 })`. Pusta lista oznacza problem executable, root albo filetype, nie problem mapowania `gd`.
3. Nad symbolem użyj `gd`, wróć `Ctrl-o`, pokaż dokumentację `K`, znajdź użycia lokalnym `gr` i implementację wbudowanym `gri`.
4. Zaznacz zakres i użyj `<leader>ca`; LSP otrzyma range. Do zmiany nazwy użyj `<leader>ra` i po operacji obejrzyj wszystkie zmienione bufory.
5. Diagnostykę przeglądaj `]d` / `[d`, szczegół `<leader>dd`, a cały bieżący zestaw `<leader>ds`.

#### Tutorial: TypeScript i auto-importy

1. Sprawdź obecność `typescript-language-server` oraz projektowego `typescript`; serwer preferuje `node_modules/.bin` i root wyznaczony przez pliki projektu.
2. `gS` próbuje przejść z deklaracji `.d.ts` do źródłowej implementacji. Zwykłe `gd` pozostaje definicją protokołu LSP.
3. `<leader>ci` otwiera akcje źródłowe całego pliku, między innymi organizację importów i usuwanie nieużywanego kodu. Przeczytaj nazwę akcji przed zatwierdzeniem.
4. Auto-import z completion działa tylko dla pozycji `[LSP]`, bo provider musi dostarczyć `additionalTextEdits`.
5. Lokalny handler obserwuje log `ts_ls`. Przy utracie synchronizacji dokumentu albo `SIGABRT` planuje automatyczny restart; w Insert/Replace czeka do `InsertLeave`, poza nimi około 100 ms. Ręczne `<leader>lr` pozostaje awaryjnym restartem.

#### Tutorial: Python bez nakładających się odpowiedzialności

1. Pyright dostarcza typy i hover, a Ruff lint/fix/format bez hover. Nieużywane importy i zmienne są wyłączone w Pyright, więc brak executable `ruff` pozostawia w tym obszarze lukę.
2. Sprawdź oba klienty przez `:lua =vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients({bufnr=0}))`.
3. `:LspPyrightSetPythonPath /ścieżka/do/python` zmienia interpreter tylko w bieżącej sesji; trwalsze środowisko ustaw w projekcie lub aktywuj przed startem Neovim.
4. Formatowanie i poprawki przy zapisie wykonuje Conform, a mypy po zapisie nvim-lint. Źródło diagnostyki odróżnia te warstwy.

#### Completion omnifunc i pozostałe ograniczenia

`cmp-nvim-lsp.default_capabilities()` rozszerza możliwości klienta dla nvim-cmp i upstream ostrzega, że wbudowany przepływ `Ctrl-x Ctrl-o` nie jest wtedy wspieranym zamiennikiem. Korzystaj z nvim-cmp. Semantic tokens są usuwane dla wszystkich klientów, aby podstawowe podświetlanie pochodziło z Treesitter.

**Diagnostyka:** oprócz health sprawdź `:messages`, `:echo executable('nazwa')`, bieżący `:pwd`, root klienta w `vim.lsp.get_clients()` i `:verbose nmap gd`. Na macOS file watching dużego workspace może kosztować zasoby; ustal najpierw, który klient i root obserwuje katalog.

**Źródła przypiętej rewizji:** [README lspconfig](https://github.com/neovim/nvim-lspconfig/blob/1c0d8f70dbc8827263eedc3cf7021ceba0f68689/README.md), [help](https://github.com/neovim/nvim-lspconfig/blob/1c0d8f70dbc8827263eedc3cf7021ceba0f68689/doc/lspconfig.txt), [konfiguracja `ts_ls`](https://github.com/neovim/nvim-lspconfig/blob/1c0d8f70dbc8827263eedc3cf7021ceba0f68689/lsp/ts_ls.lua), [wbudowany help LSP Neovim 0.12](https://github.com/neovim/neovim/blob/v0.12.4/runtime/doc/lsp.txt).

<a id="plugin-nvim-cmp"></a>
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

#### Kolejność i fallback klawiszy

- Grupa pierwsza (`nvim_lsp`, `luasnip`) ma pierwszeństwo jako całość. `nvim_lua`, `buffer` i `async_path` pojawiają się dopiero, gdy pierwsza grupa nie ma pasujących kandydatów.
- `Enter` ma `select=true`, więc może zatwierdzić pierwszy element bez jawnego ruchu. Przeczytaj etykietę źródła przed zatwierdzeniem, szczególnie przy auto-importach.
- `Ctrl-e` używa `close()`, nie `abort()`. Po przejściu po kandydatach podgląd wstawionego tekstu może pozostać; nie ma lokalnego skrótu „anuluj i przywróć oryginał”. Bez widocznego menu `Ctrl-e` wpada w lokalny ruch na koniec wiersza.
- Bez dokumentacji `Ctrl-d`/`Ctrl-f` wracają do zachowania Insert. Bez menu `Ctrl-n`/`Ctrl-p` mogą uruchomić natywne keyword completion.
- `Tab` najpierw porusza menu, potem rozwija lub przeskakuje LuaSnip, a dopiero na końcu wykonuje zwykły fallback.

#### Tutorial: semantyczne completion

1. Otwórz plik z aktywnym LSP, wejdź do Insert i wpisz początek symbolu.
2. Sprawdź etykietę `[LSP]`, przechodź `Alt-j` / `Alt-k` i przewijaj dokumentację `Ctrl-f` / `Ctrl-d`.
3. Zatwierdź `Enter`. W TypeScript pozycja zawierająca auto-import może jednocześnie dopisać import; od razu obejrzyj początek pliku.
4. `Ctrl-Spacja` otwiera menu ręcznie, a `Ctrl-e` je zamyka z opisanym wyżej ograniczeniem.

#### Tutorial: źródła fallback

1. Wpisz trzy pierwsze znaki unikalnego słowa istniejącego w bieżącym buforze; gdy LSP i snippety nie pasują, pojawi się `[Buffer]`.
2. Wpisz `./`, `../` albo `~/`, aby zobaczyć `[Path]`. Ukryty plik wymaga jawnej kropki, na przykład `./.`.
3. W pliku `vim` wpisz fragment polecenia `lua vim.api.`; `[Nvim]` pochodzi z runtime API, o ile grupa pierwsza nie ma kandydata.
4. `:CmpStatus` pokazuje status providerów po pierwszym `InsertEnter`. Stan `unknown` nie zawsze jest błędem, bo część źródeł jest kontekstowa.

Command-line completion i ghost text są w kodzie dostępne konfiguracyjnie, lecz tutaj **Warunkowe/wyłączone**. Menu nie otwiera się automatycznie w promptach i podczas wykonywania makr.

**Źródła przypiętej rewizji:** [README](https://github.com/hrsh7th/nvim-cmp/blob/2ffe79f1f021def8dd1fcd81deb16f1bb0d989f3/README.md), [help](https://github.com/hrsh7th/nvim-cmp/blob/2ffe79f1f021def8dd1fcd81deb16f1bb0d989f3/doc/cmp.txt), [domyślna konfiguracja](https://github.com/hrsh7th/nvim-cmp/blob/2ffe79f1f021def8dd1fcd81deb16f1bb0d989f3/lua/cmp/config/default.lua).

<a id="plugin-luasnip"></a>
### `LuaSnip`

**Co robi i po co:** rozwija snippety i utrzymuje placeholdery. Ładuje się jako zależność nvim-cmp; historia snippetów jest włączona, a placeholdery aktualizują się na `TextChanged` i `TextChangedI`.

**Ładowanie snippetów:** lokalna konfiguracja uruchamia loadery VS Code, SnipMate i Lua, lecz realną kolekcję dostarcza obecnie tylko `friendly-snippets` w formacie VS Code. Nie ma lokalnych katalogów SnipMate/Lua ani ustawionych niestandardowych ścieżek. Po wyjściu z Insert nieaktywny snippet jest odłączany, aby nie pozostawić uszkodzonego stanu.

**Aktywne lokalne:** `Tab` i `Shift-Tab` w `i,s` przez nvim-cmp. LuaSnip tworzy cele `<Plug>`, ale żaden dodatkowy bezpośredni klawisz nie jest tu przypisany.

**Polecenia:** `:LuaSnipUnlinkCurrent`, `:LuaSnipListAvailable`. Wzmiankowane w dokumentacji mapowanie edytora snippetów nie jest w tej rewizji zarejestrowanym poleceniem użytkownika.

#### Tutorial: znalezienie i rozwinięcie snippetu

1. Otwórz plik obsługiwany przez friendly-snippets i po pierwszym `InsertEnter` wykonaj `:LuaSnipListAvailable`.
2. W Python spróbuj triggera `ifmain`, w HTML `!`, w Lua `req`, a w Go `pkgm`. Lista zależy od filetype i rewizji kolekcji.
3. Wybierz kandydat `[Snippet]`, zatwierdź `Enter`, a między polami przechodź `Tab`; `Shift-Tab` wraca.
4. Placeholdery zależne aktualizują się na `TextChanged` i `TextChangedI`.
5. Jeżeli wyjdziesz z Insert przez `jk`/`Esc` poza aktywnym skokiem, lokalny autocmd odłącza snippet. Po ponownym wejściu nie oczekuj wznowienia starych placeholderów.

Autosnippety, osobna nawigacja choice node i edytor snippetów nie mają lokalnych mapowań. Transformacje wymagające `jsregexp` mogą działać w ograniczonym trybie, jeśli natywna biblioteka LuaSnip nie została zbudowana; sprawdź `:checkhealth luasnip`.

**Diagnostyka:** sprawdź `:set filetype?`, `:LuaSnipListAvailable`, etykietę `[Snippet]`, `:checkhealth luasnip` oraz czy `friendly-snippets` jest załadowane w `:Lazy`. `:LuaSnipUnlinkCurrent` ręcznie kończy uszkodzony kontekst.

**Źródła przypiętej rewizji:** [README](https://github.com/L3MON4D3/LuaSnip/blob/3732756842a2f7e0e76a7b0487e9692072857277/README.md), [help](https://github.com/L3MON4D3/LuaSnip/blob/3732756842a2f7e0e76a7b0487e9692072857277/doc/luasnip.txt), [polecenia](https://github.com/L3MON4D3/LuaSnip/blob/3732756842a2f7e0e76a7b0487e9692072857277/plugin/luasnip.lua).

#### Jak współpracują dostawcy

Każdy provider zasila wspólny popup nvim-cmp. Nie ma własnego polecenia Ex ani mapowania; etykiety `[LSP]`, `[Snippet]`, `[Nvim]`, `[Buffer]` i `[Path]` są jego widocznym interfejsem.

<a id="plugin-cmp-nvim-lsp"></a>
### `cmp-nvim-lsp`

**Rola:** rozszerza capabilities klienta i przekazuje kandydatów serwera, w tym snippet text oraz `additionalTextEdits` potrzebne do auto-importów.

**Tutorial:** otwórz TypeScript z aktywnym `ts_ls`, wpisz nazwę niezaimportowanego symbolu, wybierz pozycję `[LSP]` i zatwierdź. Sprawdź, czy import pojawił się w pliku. Kandydat bez etykiety `[LSP]` jest zwykłym tekstem i nie niesie edycji importu. Klient podłączony dopiero podczas Insert może wymagać wyjścia i ponownego `InsertEnter`, aby źródło zostało odświeżone.

**Źródła przypiętej rewizji:** [README](https://github.com/hrsh7th/cmp-nvim-lsp/blob/cbc7b02bb99fae35cb42f514762b89b5126651ef/README.md), [provider](https://github.com/hrsh7th/cmp-nvim-lsp/blob/cbc7b02bb99fae35cb42f514762b89b5126651ef/lua/cmp_nvim_lsp/init.lua).

<a id="plugin-cmp-luasnip"></a>
### `cmp_luasnip`

**Rola:** zamienia dostępne snippety LuaSnip na kandydatów `[Snippet]`. Respektuje warunek widoczności snippetu; autosnippety są domyślnie ukryte i lokalnie nie są włączone.

**Tutorial:** porównaj `:LuaSnipListAvailable` z pozycjami `[Snippet]` po wpisaniu triggera. Provider tylko proponuje element; rozwinięcie i placeholdery wykonuje LuaSnip, a klawisze dostarcza nvim-cmp.

**Źródła przypiętej rewizji:** [README](https://github.com/saadparwaiz1/cmp_luasnip/blob/98d9cb5c2c38532bd9bdb481067b20fea8f32e90/README.md), [provider](https://github.com/saadparwaiz1/cmp_luasnip/blob/98d9cb5c2c38532bd9bdb481067b20fea8f32e90/lua/cmp_luasnip/init.lua).

<a id="plugin-cmp-nvim-lua"></a>
### `cmp-nvim-lua`

**Rola:** proponuje pola globalnych tabel runtime Neovim dla filetype `lua` i `vim`. Ukrywa pola zaczynające się od `_`.

**Tutorial:** najłatwiej zobaczyć `[Nvim]` w buforze Vimscript bez aktywnej pierwszej grupy: wpisz `lua vim.api.`. W zwykłym Lua `lua_ls` często dostarcza lepszy kandydat `[LSP]`, więc grupa druga celowo pozostaje niewidoczna.

**Źródła przypiętej rewizji:** [README](https://github.com/hrsh7th/cmp-nvim-lua/blob/e3a22cb071eb9d6508a156306b102c45cd2d573d/README.md), [provider](https://github.com/hrsh7th/cmp-nvim-lua/blob/e3a22cb071eb9d6508a156306b102c45cd2d573d/lua/cmp_nvim_lua/init.lua).

<a id="plugin-cmp-buffer"></a>
### `cmp-buffer`

**Rola:** indeksuje słowa bieżącego bufora. Domyślny minimalny token ma 3 znaki; indeksowanie odbywa się asynchronicznie partiami, a bardzo długie wiersze są ograniczane.

**Tutorial:** wpisz w innym miejscu unikalne słowo o długości co najmniej 3, wróć i zacznij je przepisywać. `[Buffer]` pojawi się tylko wtedy, gdy LSP i snippety z pierwszej grupy nie mają pasującej pozycji. Inne otwarte bufory nie są lokalnie źródłem.

**Źródła przypiętej rewizji:** [README i opcje](https://github.com/hrsh7th/cmp-buffer/blob/b74fab3656eea9de20a9b8116afa3cfc4ec09657/README.md), [provider](https://github.com/hrsh7th/cmp-buffer/blob/b74fab3656eea9de20a9b8116afa3cfc4ec09657/lua/cmp_buffer/init.lua).

<a id="plugin-cmp-async-path"></a>
### `cmp-async-path`

**Rola:** asynchronicznie proponuje ścieżki względem katalogu bieżącego pliku. Rozpoznaje między innymi `./`, `../`, `~/` i `$VAR/`.

**Tutorial:** w Insert wpisz `./`, wybierz `[Path]`, a do pliku ukrytego wpisz jawnie `./.`. Dokumentacja pozycji może pokazać do 20 pierwszych wierszy pliku. Jeśli bufor nie ma ścieżki, katalog bazowy może być mniej intuicyjny; sprawdź nazwę bufora i CWD.

**Źródła przypiętej rewizji:** [README na Codeberg](https://codeberg.org/FelipeLema/cmp-async-path/src/commit/9c2374deb32c2bec8b27e928c6f57090e9a875d2/README.md), [provider](https://codeberg.org/FelipeLema/cmp-async-path/src/commit/9c2374deb32c2bec8b27e928c6f57090e9a875d2/lua/cmp_async_path/init.lua).

<a id="plugin-friendly-snippets"></a>
### `friendly-snippets`

**Rola:** kolekcja danych VS Code, a nie silnik. LuaSnip ładuje ją na żądanie, cmp_luasnip pokazuje kandydaty, a nvim-cmp obsługuje wybór.

**Tutorial:** użyj `:LuaSnipListAvailable`, potem wypróbuj typowy trigger dla filetype, na przykład Lua `req`, Python `ifmain`, HTML `!`, Markdown `h1` albo Go `pkgm`. Snippety React przypisane do `javascriptreact`/`typescriptreact` działają, lecz wirtualne frameworkowe filetype wymagające `filetype_extend()` nie są lokalnie rozszerzone.

Kolekcja nie ma mapowań ani poleceń. Brak triggera diagnozuj przez filetype, listę LuaSnip i wpis `friendly-snippets` w Lazy.

**Źródła przypiętej rewizji:** [README](https://github.com/rafamadriz/friendly-snippets/blob/572f5660cf05f8cd8834e096d7b4c921ba18e175/README.md), [manifest snippetów](https://github.com/rafamadriz/friendly-snippets/blob/572f5660cf05f8cd8834e096d7b4c921ba18e175/package.json).

<a id="plugin-nvim-autopairs"></a>
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

#### Tutorial: pary, Enter i completion

1. Wpisz `(`, `{`, `[` albo cudzysłów. Gdy para jest pusta, `Backspace` usuwa oba znaki; wpisanie istniejącego znaku zamykającego przesuwa przez niego zamiast duplikować.
2. Ustaw kursor między `{}` i naciśnij `Enter`, aby otrzymać inteligentnie wciętą pustą linię.
3. Zatwierdź funkcję lub metodę z nvim-cmp. Hook `confirm_done` może dopisać `()`, chyba że kandydat już zawiera nawiasy albo filetype jest wyłączony.
4. Pary są wyłączone dokładnie dla `TelescopePrompt` i `vim`. Lokalna lista zastępuje listę upstream, więc nie należy zakładać innych domyślnych wykluczeń.

#### Tutorial: poprawny FastWrap

1. Przygotuj tekst tak, aby kursor był bezpośrednio po znaku otwierającym, na przykład `(|)foobar`, gdzie `|` oznacza kursor.
2. Naciśnij `Alt-e`. Wtyczka oznaczy możliwe miejsca docelowe po tekście.
3. Wybierz pokazany znak celu za `foobar`; nawias zamykający zostanie przesunięty i powstanie `(foobar)`.
4. FastWrap nie służy do uruchamiania na końcu już wpisanego `(foobar)`; punkt startowy musi znajdować się przy otwarciu.

Makra i Replace mode nie dostają par domyślnie, sprawdzanie kontekstu Treesitter jest wyłączone. Reguły Markdown fences, potrójnych cudzysłowów, komentarzy i Enter są nadal częścią przypiętych defaultów. Wyłączone mapowania autopairs `Ctrl-h`/`Ctrl-w` nie usuwają lokalnego `Ctrl-h` do ruchu ani natywnego kasowania słowa.

**Diagnostyka:** sprawdź filetype, `:verbose imap <M-e>`, konflikt terminala z Alt oraz czy nvim-cmp został już załadowany. Wtyczka nie ma publicznego polecenia Ex.

**Źródła przypiętej rewizji:** [README](https://github.com/windwp/nvim-autopairs/blob/c2a0dd0d931d0fb07665e1fedb1ea688da3b80b4/README.md), [help](https://github.com/windwp/nvim-autopairs/blob/c2a0dd0d931d0fb07665e1fedb1ea688da3b80b4/doc/nvim-autopairs.txt), [integracja cmp](https://github.com/windwp/nvim-autopairs/blob/c2a0dd0d931d0fb07665e1fedb1ea688da3b80b4/lua/nvim-autopairs/completion/cmp.lua).

</details>

<details>
<summary><strong>Telescope i nvim-tree</strong></summary>

<a id="plugin-telescope"></a>
### `telescope.nvim`

**Co robi i po co:** fuzzy finder plików, tekstu, buforów, pomocy, Git i LSP. Ładuje się po `:Telescope` albo po jednym z lokalnych mapowań.

**Konfiguracja lokalna:** układ 87% szerokości i 80% wysokości, prompt u góry, preview 55%, wyniki rosnąco. Pliki ukryte są widoczne, `.git/` jest ignorowane, `live_grep` dodaje `--hidden`. Lokalne mapowania pickerów: `Alt-j`, `Alt-k` w Insert i `q` w Normal.

**Aktywne launchery:** `<leader>ff`, `<leader>fa`, `<leader>fw`, `<leader>fW`, `<leader>fb`, `<leader>fh`, `<leader>ma`, `<leader>fo`, `<leader>fz`, `<leader>fZ`, `<leader>cm`, `<leader>gt`. `<leader>th` używa osobnego pickera NvChad i nie dziedziczy mapowań Telescope.

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

#### Mentalny model pickera

Picker składa się z promptu, listy wyników i preview. Startuje w Insert, aby od razu filtrować. `Esc` przechodzi do Normal, a dopiero kolejne `Esc` lub lokalne `q` zamyka. Domyślna akcja `Enter` zależy od pickera: zwykle otwiera plik, lecz w `git_commits` wykonuje checkout, a w `git_status` otwiera wskazany plik.

`Tab` nie oznacza zwykłego ruchu: zaznacza element i przechodzi dalej. `Ctrl-q` wysyła wszystkie wyniki do quickfix, `Alt-q` tylko jawnie zaznaczone. Po zamknięciu pickera `[q` / `]q` nawiguje listę.

#### Katalog builtinów dostępnych przez `:Telescope`

| Obszar | Przydatne builtiny bez lokalnego skrótu |
|---|---|
| pliki i tekst | `grep_string`, `git_files`, `search_history`, `command_history` |
| stan Neovim | `commands`, `keymaps`, `registers`, `jumplist`, `quickfix`, `loclist`, `diagnostics`, `autocommands`, `filetypes` |
| LSP | `lsp_definitions`, `lsp_implementations`, `lsp_type_definitions`, `lsp_document_symbols`, `lsp_workspace_symbols`, `lsp_dynamic_workspace_symbols`, `lsp_incoming_calls`, `lsp_outgoing_calls` |
| Git | `git_bcommits`, `git_branches`, `git_stash` oraz lokalnie używane `git_commits`, `git_status` |
| składnia i historia | `treesitter`, `pickers`, `resume`, `builtin` |
| rozszerzenia UI | `themes` i `terms` dostarczane przez NvChad UI po dynamicznym załadowaniu |

`builtin` pozwala wybrać nazwę pickera z listy, `pickers` pokazuje wcześniejsze pickery, a `resume` wraca do ostatniego promptu i stanu. Opcje można dopisać po nazwie, na przykład `:Telescope find_files hidden=true no_ignore=true`.

#### Tutorial: plik, split i bufor

1. Uruchom Neovim w root projektu; domyślny CWD jest punktem wyszukiwania.
2. `<leader>ff` pokazuje także dotfiles, ale respektuje ignore. `<leader>fa` dodatkowo ignoruje reguły ignore i śledzi symlinki, więc może zwrócić bardzo dużo wyników.
3. Filtruj fragmentem ścieżki. `Enter` otwiera normalnie, `Ctrl-v` pionowo, `Ctrl-x` poziomo, a `Ctrl-t` w nowej karcie.
4. `<leader>fb` przełącza już otwarte bufory, a `<leader>fo` wraca do historii plików.

#### Tutorial: wyszukiwanie i lista wyników

1. `<leader>fw` uruchamia ripgrep w projekcie z plikami ukrytymi poza wnętrzem `.git/`. `<leader>fW` zaczyna od słowa pod kursorem.
2. Zaznacz kilka trafień `Tab`; `Shift-Tab` cofa zaznaczenie/ruch.
3. Wyślij wybrane `Alt-q`, zamknij picker i przechodź `[q` / `]q`. `:copen` pokazuje całą listę.
4. Dla bieżącego pliku użyj `<leader>fz` albo `<leader>fZ`; ten picker nie uruchamia ripgrep po całym projekcie.
5. `:Telescope resume` przywraca ostatni picker, co jest wygodne po obejrzeniu jednego wyniku.

#### Bezpieczeństwo pickerów Git

`<leader>cm` nie jest tylko przeglądarką: `Enter` checkoutuje commit, a `Ctrl-r m/s/h` resetuje bieżącą gałąź. `<leader>gt` zmienia indeks przez `Tab`. Przed akcją sprawdź nagłówek pickera, `git status` i tabelę Git powyżej. Do bezpiecznego samego podglądu historii lepszy bywa Diffview albo CodeDiff.

**Diagnostyka:** `:checkhealth telescope`, `:echo executable('fd')`, `:echo executable('rg')`, `:pwd` i `:messages`. Brak wyników w `<leader>ff` może wynikać z ignore; porównaj `<leader>fa`. `Ctrl-/` w Insert albo `?` w Normal pokazuje mapowania konkretnego pickera.

**Źródła przypiętej rewizji:** [README](https://github.com/nvim-telescope/telescope.nvim/blob/a8c2223ea6b185701090ccb1ebc7f4e41c4c9784/README.md), [pełny help](https://github.com/nvim-telescope/telescope.nvim/blob/a8c2223ea6b185701090ccb1ebc7f4e41c4c9784/doc/telescope.txt), [builtiny](https://github.com/nvim-telescope/telescope.nvim/blob/a8c2223ea6b185701090ccb1ebc7f4e41c4c9784/lua/telescope/builtin/init.lua).

<a id="plugin-nvim-tree"></a>
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

#### Root, fokus i reveal

- `<leader>e` przełącza drzewo bez gwarancji odsłonięcia bieżącego pliku.
- `<leader>E` otwiera potrzebne katalogi i ustawia kursor na bieżącym lokalnym pliku.
- Root synchronizuje się z CWD przy jego zmianie, ale samo śledzenie aktywnego pliku nie zmienia root.
- `Ctrl-]` ustawia wskazany katalog jako root, `-` idzie poziom wyżej, a `P` tylko przechodzi na node rodzica.

#### Tutorial: utworzenie i otwarcie pliku

1. Użyj `<leader>E`, aby zobaczyć położenie bieżącego pliku, albo `<leader>e` do zwykłego toggle.
2. `a` otwiera prompt tworzenia. Ścieżka zakończona `/` tworzy katalog, pozostała plik; przeczytaj prompt przed zatwierdzeniem.
3. `Enter` otwiera w wybranym oknie, `Ctrl-v` pionowo, `Ctrl-x` poziomo, `Ctrl-t` w karcie, a `Tab` robi preview bez trwałego opuszczenia drzewa.
4. Fizyczne `Cmd-\` i `Cmd--` są lokalnymi odpowiednikami splitów w tym buforze.
5. `q` zamyka panel, ale otwarte pliki pozostają buforami.

#### Tutorial: rename, copy, cut i bookmarki

1. `r` zmienia pełną nazwę, `e` basename, `u` pełną ścieżkę, a `Ctrl-r` usuwa nazwę pliku z początkowego promptu. Sprawdź docelową ścieżkę.
2. `c` kopiuje node do wewnętrznego schowka nvim-tree, `x` zaznacza cut, a `p` wykonuje operację w wskazanym katalogu. `:NvimTreeClipboard` pokazuje stan schowka.
3. `m` przełącza bookmark. `bmv` przenosi zaznaczone bookmarki, `bd` usuwa, a `bt` przenosi do kosza; prefiks `b` nie czyni operacji bezpieczną.
4. `y/Y/gy/ge` kopiuje różne warianty nazwy i ścieżki, bez modyfikowania dysku.

#### Filtry, Git i diagnostyka

1. Gdy pliku nie widać, kolejno sprawdź `H` dla dotfiles, `I` dla `.gitignore` i `U` dla lokalnego filtra `.DS_Store`/`.git`.
2. `C` ukrywa lub pokazuje pliki Git clean, `B` node bez bufora, `M` elementy bez bookmarka.
3. `[c` / `]c` przechodzi po statusach Git, `[e` / `]e` po diagnostyce.
4. `f` uruchamia live filter nazw w już zbudowanym drzewie, `F` go czyści; nie jest to wyszukiwanie zawartości plików.
5. `g?` jest najpewniejszą pomocą, ponieważ pokazuje mapowania po lokalnym `on_attach`.

#### Operacje destrukcyjne

`d`/`Del` usuwa po ścieżce potwierdzenia, `D` wysyła do skonfigurowanego kosza, a `bd`/`bt` działa na bookmarkach. `s` uruchamia program systemowy, a `.` prompt polecenia w katalogu node. Nie używaj ich do diagnozy. Po każdej operacji sprawdź ścieżkę, komunikat i w repo także `git status`.

**Diagnostyka:** `R` odświeża, `:NvimTreeHiTest` sprawdza highlighty, `:NvimTreeRefresh` działa po załadowaniu, a `:messages` pokazuje błędy watchera i operacji. Na zimnym starcie Lazy zna tylko trzy polecenia-trigger: `NvimTreeToggle`, `NvimTreeFocus`, `NvimTreeFindFile`; pozostałe pojawiają się po pierwszym załadowaniu.

**Źródła przypiętej rewizji:** [README](https://github.com/nvim-tree/nvim-tree.lua/blob/037d89e60fb01a6c11a48a19540253b8c72a3c32/README.md), [pełny help i mapowania](https://github.com/nvim-tree/nvim-tree.lua/blob/037d89e60fb01a6c11a48a19540253b8c72a3c32/doc/nvim-tree-lua.txt), [publiczne API](https://github.com/nvim-tree/nvim-tree.lua/blob/037d89e60fb01a6c11a48a19540253b8c72a3c32/lua/nvim-tree/api.lua).

</details>

<details>
<summary><strong>Treesitter, autotag i Markdown</strong></summary>

<a id="plugin-nvim-treesitter"></a>
### `nvim-treesitter`

**Co robi i po co:** instaluje przypięte parsery i uruchamia wbudowane podświetlanie oraz, gdy istnieje query, indent Treesitter. To gałąź `main` po przepisaniu API dla Neovim 0.12.

**Ładowanie lokalne:** `lazy=false`, bo ta wersja nie wspiera lazy-loadingu; build wykonuje `:TSUpdate`. Setup instaluje parsery i przy `FileType` wywołuje `vim.treesitter.start`.

**Konfigurowany zestaw parserów:** `lua`, `luadoc`, `printf`, `vim`, `vimdoc`, `go`, `python`, `typescript`, `tsx`, `javascript`, `html`, `markdown`, `markdown_inline`.

**Filetype z automatycznym startem:** `lua`, `vim`, `help`, `go`, `python`, `typescript`, `typescriptreact`, `javascript`, `javascriptreact`, `html`, `markdown`. Język `tsx` jest zarejestrowany dla `typescriptreact`.

**Polecenia:** `:TSInstall[!] {language...}`, `:TSInstallFromGrammar[!] {language...}`, `:TSUpdate [language...]`, `:TSUninstall {language...}`, `:TSLog`. Wariant `!` nadal wymaga co najmniej jednej nazwy języka.

**Mapowania:** ta konfiguracja nie włącza modułu incremental selection i nie instaluje żadnej tabeli skrótów selekcji. Nie należy przenosić mapowań ze starego API do tej rewizji.

**Wymagania:** Neovim 0.12+, `curl`, `tar`, kompilator C/C++ oraz `tree-sitter-cli >= 0.26.1`. Przypięta gałąź `main` używa `tree-sitter build` również przy zwykłej instalacji parsera. Po aktualizacji wtyczki parsery trzeba zaktualizować.

#### Parser, query i funkcja to trzy osobne warstwy

1. Parser zamienia tekst na drzewo składniowe. Sama instalacja parsera nie włącza żadnego wyglądu ani mapowania.
2. Query opisuje, które węzły są highlightem, wcięciem, injection albo `locals`. Dla jednej funkcji może istnieć query, a dla innej nie.
3. Funkcję uruchamia Neovim lub konsument. Lokalny autocmd włącza highlight i eksperymentalny indent tylko dla wymienionych filetype.
4. Injections pozwalają parserowi HTML działać we fragmencie Markdown albo parserowi języka w fenced code block. Nie wymagają osobnego modułu konfiguracji.

Folding Treesitter nie jest lokalnie ustawiony, incremental selection starego `nvim-treesitter.configs` nie istnieje, a text objects nie są zainstalowaną osobną wtyczką. Query `locals` są natomiast wykorzystywane pośrednio przez nvim-dap-virtual-text.

#### Tutorial: instalacja i inspekcja

1. Sprawdź narzędzia: `:echo executable('tree-sitter')`, `:echo executable('cc')`, `:echo executable('curl')`.
2. `:TSInstall html markdown markdown_inline` instaluje parsery asynchronicznie. `:TSLog` pokazuje pobieranie, generowanie i kompilację.
3. Otwórz plik i wykonaj `:InspectTree`, aby zobaczyć drzewo; `:Inspect` pokazuje capture/highlight pod kursorem.
4. Jeżeli parser istnieje, ale podświetlanie nie startuje, sprawdź czy filetype znajduje się na lokalnej liście i ręcznie porównaj `:lua vim.treesitter.start()`.
5. Po zmianie commita wtyczki wykonaj `:TSUpdate`, ponieważ parsery są zgodne z konkretnymi rewizjami definicji w pluginie.

`TSInstallFromGrammar` buduje z gramatyki i wymaga jeszcze pełniejszego toolchainu; zwykły użytkownik powinien preferować `TSInstall`. `TSUninstall` usuwa parser, co natychmiast odbiera funkcje zależne od niego, na przykład autotag lub render Markdown.

**Diagnostyka:** `:TSLog`, `:InspectTree`, `:set filetype?`, `:lua =vim.treesitter.language.get_lang(vim.bo.filetype)` oraz `:messages`. Błąd indent nie musi oznaczać błędu highlightu, bo to różne query.

**Źródła przypiętej rewizji:** [README gałęzi `main`](https://github.com/nvim-treesitter/nvim-treesitter/blob/7b6cc8949f9999c5ed91436cbe24aa5f99c42025/README.md), [help i polecenia](https://github.com/nvim-treesitter/nvim-treesitter/blob/7b6cc8949f9999c5ed91436cbe24aa5f99c42025/doc/nvim-treesitter.txt), [lista obsługiwanych języków](https://github.com/nvim-treesitter/nvim-treesitter/blob/7b6cc8949f9999c5ed91436cbe24aa5f99c42025/SUPPORTED_LANGUAGES.md).

<a id="plugin-nvim-ts-autotag"></a>
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

#### Tutorial: domknięcie i rename

1. W HTML wpisz `<section` i zakończ `>`. Gdy drzewo rozpoznaje start tag, wtyczka dopisuje `</section>` i pozostawia kursor między tagami.
2. Ustaw kursor w nazwie tagu otwierającego, wykonaj `ciwarticle` i wyjdź z Insert. Sparowany tag zamykający powinien zmienić się na `</article>`.
3. Powtórz w TSX/JSX na prawidłowym elemencie. Sam parser `typescript` nie zastępuje `tsx`; lokalna rejestracja mapuje `typescriptreact` na parser TSX.
4. W Markdown funkcja zadziała tylko we fragmencie rozpoznanym jako HTML injection.

Wtyczka nie domyka dowolnego tekstu wyglądającego jak tag: potrzebuje poprawnego węzła parsera, respektuje elementy void/self-closing i własne konfiguracje języka. `enable_close_on_slash=false`, więc wpisanie samego `</` nie wywołuje lokalnego automatycznego zakończenia.

**Diagnostyka:** sprawdź `:set filetype?`, `:InspectTree`, obecność parsera i `:verbose imap >`. Nvim-ts-autotag mapuje `>` buforowo tylko w obsługiwanym kontekście. Nie ma polecenia Ex ani globalnego toggle; aliasy i per-filetype overrides są **Opcjonalnym upstream API**.

**Źródła przypiętej rewizji:** [README i lista języków](https://github.com/windwp/nvim-ts-autotag/blob/88c1453db4ba7dd24131086fe51fdf74e587d275/README.md), [konfiguracje tagów](https://github.com/windwp/nvim-ts-autotag/tree/88c1453db4ba7dd24131086fe51fdf74e587d275/lua/nvim-ts-autotag/config), [obsługa close/rename](https://github.com/windwp/nvim-ts-autotag/blob/88c1453db4ba7dd24131086fe51fdf74e587d275/lua/nvim-ts-autotag/internal.lua).

<a id="plugin-render-markdown"></a>
### `render-markdown.nvim`

**Co robi i po co:** renderuje nagłówki, listy, kod, checkboxy, tabele i callouty Markdown bez zmiany tekstu pliku. Ładuje się tylko dla filetype `markdown`.

**Konfiguracja lokalna:** renderowanie domyślnie aktywne, limit pliku 10 MB, tryby `n`, `c`, `v`, `i`, domyślne ikony nagłówków, lokalnie ustawione ikony list oraz code block o szerokości `block` z nazwą języka. Mapowanie Markdown-only `<leader>mr` wywołuje `RenderMarkdown buf_toggle`.

**Polecenia:** `:RenderMarkdown`, `:RenderMarkdown enable`, `buf_enable`, `disable`, `buf_disable`, `toggle`, `buf_toggle`, `get`, `set [true|false]`, `set_buf [true|false]`, `preview`, `log`, `expand`, `contract`, `debug`, `config`.

Wtyczka nie ma własnych domyślnych mapowań. `<leader>mr` jest **Aktywne lokalne** i ograniczone do Markdown.

**Wymagania:** parsery Treesitter `markdown` i `markdown_inline`; ikony korzystają z Nerd Font.

#### Co jest renderowane lokalnie

Nagłówki, akapity, fenced i inline code, poziome linie, listy z ikonami `● ○ ◆ ◇`, checkboxy, cytaty, callouty GitHub/Obsidian, tabele, linki i komentarze HTML korzystają z defaultów. Code block ma lokalnie szerokość `block`, znak w signcolumn i nazwę języka.

LaTeX wymaga parsera `latex` oraz `utftex` albo `latex2text`, a frontmatter parsera YAML; te dodatki nie są w lokalnej liście parserów, więc należy je traktować jako **Warunkowe/wyłączone**. Completion checkboxów/calloutów przez wewnętrzny LSP również jest domyślnie wyłączone.

#### Renderowany tekst a prawdziwy plik

Wtyczka używa conceal, extmarks, virtual text i highlightów; nie zmienia znaków zapisanych w pliku. Lokalnie renderuje także w Insert i Visual. Anti-conceal odsłania elementy na linii kursora, ale ponieważ `i` należy do `render_modes`, pełny surowy widok uzyskasz najpewniej przez `<leader>mr`.

#### Tutorial: czytanie, edycja i preview

1. Otwórz `.md` mniejszy niż 10 MB. Sprawdź nagłówki, listy, kod, tabelę i linki.
2. `<leader>mr` przełącza tylko bieżący bufor. Porównaj render z surowym Markdown i ponownie włącz.
3. `:RenderMarkdown preview` otwiera renderowany podgląd obok, bez zmiany stanu głównego bufora.
4. `:RenderMarkdown expand` zwiększa o jeden margines anti-conceal nad i pod kursorem; `contract` go zmniejsza.
5. `:RenderMarkdown get` pokazuje stan, `set`/`toggle` zmienia stan globalny, a warianty `set_buf`/`buf_toggle` tylko bieżący bufor.

#### Diagnostyka

- `:RenderMarkdown config` pokazuje różnice konfiguracji względem defaultów.
- `:RenderMarkdown debug` opisuje markery na bieżącej linii, a `:RenderMarkdown log` otwiera log.
- Brak całego renderu: sprawdź filetype, limit 10 MB, parsery `markdown` i `markdown_inline` oraz `:checkhealth render-markdown`.
- Brak pojedynczej funkcji: ustal jej parser/query lub opcjonalne executable; działające nagłówki nie dowodzą działania LaTeX.

**Źródła przypiętej rewizji:** [README i pełna konfiguracja](https://github.com/MeanderingProgrammer/render-markdown.nvim/blob/c54380dd4d8d1738b9691a7c349ecad7967ac12e/README.md), [help](https://github.com/MeanderingProgrammer/render-markdown.nvim/blob/c54380dd4d8d1738b9691a7c349ecad7967ac12e/doc/render-markdown.txt), [troubleshooting](https://github.com/MeanderingProgrammer/render-markdown.nvim/blob/c54380dd4d8d1738b9691a7c349ecad7967ac12e/doc/troubleshooting.md).

</details>

<details>
<summary><strong>Git: Gitsigns, Unified i Neogit</strong></summary>

<a id="plugin-gitsigns"></a>
### `gitsigns.nvim`

**Co robi i po co:** pokazuje dodane, zmienione i usunięte linie w signcolumn oraz blame bieżącego wiersza. Jest lekkim podglądem zmian bieżącego pliku, nie pełnym klientem Git.

**Ładowanie lokalne:** `User FilePost`. Efektywne znaki tej rewizji to między innymi `┃` dla add/change, lokalne ikony dla delete/changedelete, `▔` dla topdelete i `┆` dla untracked. `current_line_blame=true`, opóźnienie 300 ms, tekst na końcu wiersza.

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

#### Mentalny model

Domyślną bazą jest indeks Git. Znak pokazuje różnicę bieżącego bufora względem indeksu, niekoniecznie względem `HEAD`. Po stage hunka może pojawić się stan staged, a kolejne `stage_hunk` na takim znaku działa jak unstage tego hunka.

#### Tutorial: przegląd i częściowy stage

1. Zmień śledzony plik i obserwuj signcolumn oraz blame po około 300 ms.
2. `:Gitsigns preview_hunk_inline` pokazuje usunięcia i zmiany inline; `:Gitsigns preview_hunk` otwiera popup zamykany `q`.
3. Przechodź `:Gitsigns nav_hunk next` i `:Gitsigns nav_hunk prev`. Nie myl ich z nieaktywnymi lokalnie `[c`/`]c` z przykładu README.
4. Aby stage'ować cały bieżący hunk, wykonaj `:Gitsigns stage_hunk`. Dla części zakresu zaznacz linie w Visual i wykonaj zakresowe `:Gitsigns stage_hunk`.
5. Natychmiast sprawdź `git diff --cached`; Gitsigns zmienia indeks, ale nie tworzy commita.

#### Reset, baza i listy

- `reset_hunk` i `reset_buffer` zmieniają treść bufora względem indeksu. Zapis utrwala odrzucenie; przed akcją zachowaj potrzebne zmiany.
- `change_base REV` porównuje z inną rewizją, a `change_base` bez poprawnego ref może zmienić interpretację wszystkich znaków.
- `setqflist` i `setloclist` budują listy hunków do nawigacji; `blame` otwiera pełniejszy widok historii, `blame_line` szczegół linii.
- `toggle_current_line_blame`, `toggle_word_diff`, `toggle_signs`, `toggle_numhl` i `toggle_linehl` zmieniają tylko sposób prezentacji.

**Diagnostyka:** `:Gitsigns refresh`, `:messages`, `git status` i `:lua =vim.b.gitsigns_status_dict`. Brak znaków może oznaczać plik poza repo, nieśledzony stan, brak attach albo bazę równą treści.

**Źródła przypiętej rewizji:** [README](https://github.com/lewis6991/gitsigns.nvim/blob/42d6aed4e94e0f0bbced16bbdcc42f57673bd75e/README.md), [help](https://github.com/lewis6991/gitsigns.nvim/blob/42d6aed4e94e0f0bbced16bbdcc42f57673bd75e/doc/gitsigns.txt), [polecenia i API](https://github.com/lewis6991/gitsigns.nvim/blob/42d6aed4e94e0f0bbced16bbdcc42f57673bd75e/lua/gitsigns/actions.lua).

<a id="plugin-unified"></a>
### `unified.nvim`

**Co robi i po co:** pokazuje unified diff bezpośrednio w zwykłym buforze i otwiera boczne drzewo zmienionych plików. Dobrze nadaje się do szybkiego przeglądu bez dwóch kolumn.

**Ładowanie lokalne:** po `:Unified` lub `<leader>gd`, z domyślnymi opcjami i auto-refresh.

**Aktywne lokalne:** `<leader>gd` otwiera albo odświeża widok względem `HEAD`; nie jest przełącznikiem zamknięcia. Po zbudowaniu drzewa wtyczka automatycznie otwiera pierwszy zmieniony plik w głównym oknie, więc nie musi to być plik, z którego wywołano skrót.

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

#### Tutorial: szybki inline review

1. Naciśnij `<leader>gd`. Drzewo zawiera zmienione pliki i automatycznie otwiera pierwszy z nich w głównym oknie z unified diff względem `HEAD`; plik początkowy może zostać zastąpiony.
2. W drzewie przechodź `j/k`, otwieraj `l`, odśwież `R`, a `?` pokaże pomoc.
3. `q` zamyka tylko drzewo. Inline diff nadal pozostaje aktywny w buforze.
4. `:Unified reset` usuwa znaki, extmarki i hunki tylko z bieżącego bufora oraz zamyka aktywne drzewo. Wykonaj je osobno w każdym odwiedzonym pliku, który nadal ma markery.
5. `:Unified HEAD~1` porównuje z pojedynczym refem. Ta rewizja nie interpretuje zakresów `A..B` jak pełny viewer branchy.

#### Ograniczenia hunk actions

Upstreamowe przykłady stage/unstage/revert nie są mapowane. Ich API buduje patch na podstawie dyskowego `git diff`, może wybrać najbliższy hunk, a następnie wykonać przeładowanie `edit!`; przy niezapisanym buforze grozi to utratą pracy. Do stagingu używaj tutaj Gitsigns lub Neogit, a Unified traktuj jako czytelny podgląd.

**Diagnostyka:** `git rev-parse --verify REF`, `git status`, `:messages`, `R` w drzewie i `:Unified reset` w każdym buforze z markerami. Ponowne `<leader>gd` nie zamyka widoku.

**Źródła przypiętej rewizji:** [README](https://github.com/axkirillov/unified.nvim/blob/6b9d94b83cdaf7a33afeb1d66a9de386f02d8c55/README.md), [help](https://github.com/axkirillov/unified.nvim/blob/6b9d94b83cdaf7a33afeb1d66a9de386f02d8c55/doc/unified.txt), [obsługa polecenia](https://github.com/axkirillov/unified.nvim/blob/6b9d94b83cdaf7a33afeb1d66a9de386f02d8c55/lua/unified/command.lua).

<a id="plugin-neogit"></a>
### `neogit`

**Co robi i po co:** pełny, inspirowany Magit klient Git: status, staging hunka/pliku, commit, branch, pull/push, log, rebase i stash. Lokalnie otwiera się w nowej karcie i integruje z Telescope oraz Diffview.

**Ładowanie lokalne:** po `:Neogit` lub lokalnych `<leader>gg`, `<leader>gc`, `<leader>gp`, `<leader>gP`, `<leader>gb`. File watcher odświeża status, hinty są widoczne, graf jest Unicode, commit editor otwiera kartę i pokazuje staged diff.

**Polecenia:** `:Neogit [popup] [kind=tab|split|vsplit|floating|...] [cwd=...]`, `:NeogitResetState`, `:NeogitLogCurrent [path]` także z zakresem, `:NeogitCommit [sha]`. Pierwszy argument pozycyjny `commit`, `push`, `pull` lub `branch` wybiera popup, a nie rodzaj okna.

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
| `S` | `StageUnstaged` | `git add --update`: stage zmian wszystkich śledzonych plików, bez nowych untracked |
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

#### Jak czytać popupy Neogit

Pierwszy klawisz otwiera transient popup, w którym małe/duże flagi zmieniają parametry, a klawisz akcji uruchamia Git. Zawsze czytaj opis w popupie. `?` pokazuje pomoc. Finder Telescope używa `Spacja` do multiselect; `Tab` jest completion, a `Ctrl-j` celowo nie porusza listą.

#### Tutorial: hunk, commit i push

1. Otwórz `<leader>gg`. `Tab` rozwija sekcję pliku i jego hunki, `j/k` porusza się, a `Enter` przechodzi do realnego pliku.
2. Na hunku użyj `s`, aby stage'ować tylko zaznaczenie, lub `u`, aby je cofnąć. `S` obejmuje wszystkie zmiany śledzonych plików; dosłowny `Ctrl-s` obejmuje także untracked.
3. Przed commitem sprawdź sekcję Staged i ewentualnie otwórz diff. Użyj `c c` albo `<leader>gc`.
4. W edytorze wpisz wiadomość, zatwierdź `Ctrl-c Ctrl-c`; `Ctrl-c Ctrl-k` anuluje.
5. Otwórz popup push przez `P` lub `<leader>gp`, przeczytaj remote/ref i dopiero wykonaj akcję.

#### Tutorial: branch, pull, stash i log

1. `<leader>gb` otwiera popup branch. Tworzenie, checkout, usuwanie i zmiana upstream to osobne akcje; sprawdź wskazaną gałąź.
2. `<leader>gP` otwiera pull, małe `f` fetch, `l` log, `Z` stash. Flagi popupu pozostają zapamiętane przez konfigurację Neogit.
3. `:NeogitLogCurrent %` pokazuje log bieżącej ścieżki, a zwykły popup `l` pozwala dobrać zakres i filtry.
4. `:NeogitResetState` czyści zapamiętany stan/flagę popupów; nie wykonuje `git reset` repozytorium.

#### Rebase i polecenia zaawansowane

W edytorze rebase `p/r/e/s/f/x/d/b` oznacza pick/reword/edit/squash/fixup/exec/drop/break, a `gk/gj` zmienia kolejność. Submit przepisuje historię po zatwierdzeniu. Najpierw utwórz backup branch lub upewnij się, że historia nie została wypchnięta.

`Q` uruchamia prompt surowego Git, którego parser dzieli argumenty po spacjach i nie zachowuje się jak pełny shell z cytowaniem. `x` discarduje po przepływie potwierdzenia, `K` usuwa z indeksu, `U` unstaginguje cały staged zestaw. Nie używaj ich eksperymentalnie.

**Diagnostyka:** `$` otwiera historię poleceń, błędy trafiają do konsoli i `:messages`; porównaj zawsze z `git status`. Opcjonalny debug zapisuje log Neogit po uruchomieniu Neovim z `NEOGIT_LOG_FILE=1 NEOGIT_LOG_LEVEL=debug`.

**Źródła przypiętej rewizji:** [README](https://github.com/NeogitOrg/neogit/blob/73870229977fdd8747025820e15e98cfde787b9c/README.md), [pełny help i mapowania](https://github.com/NeogitOrg/neogit/blob/73870229977fdd8747025820e15e98cfde787b9c/doc/neogit.txt), [domyślne mapowania](https://github.com/NeogitOrg/neogit/blob/73870229977fdd8747025820e15e98cfde787b9c/lua/neogit/config.lua).

</details>

<details>
<summary><strong>Git: Diffview i CodeDiff</strong></summary>

<a id="plugin-diffview"></a>
### `diffview.nvim`

**Co robi i po co:** otwiera kartę z dwu-, trzy- lub czterostronnym diffem, panelem plików, historią oraz narzędziami konfliktów. Najlepiej sprawdza się w przeglądzie wielu plików i merge/rebase.

**Ładowanie lokalne:** po poleceniach Diffview lub `<leader>gv/gm/gl/gL/gq`. Dla plików binarnych wpis pozostaje w panelu, ale `diff_binaries=false` zastępuje treść pustym/null bufferem. Enhanced highlights są włączone, panel jest drzewem po lewej o szerokości 35, a hook wyłącza foldcolumn w buforach diff.

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
| `S` | Stage realnych working/conflict entries widoku |
| `U` | Unstage całego repozytorium przez reset indeksu |
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
| historia | `X` | Natychmiast przywróć plik do wersji wpisu, jeśli realny bufor nie ma niezapisanych zmian; brak promptu potwierdzenia |
| historia | `j/k`, `Enter/o/l`, foldy, scroll, `Tab/Shift-Tab`, `[F/]F` | Nawigacja analogiczna do panelu plików |
| historia | `gf`, split/tab, `<leader>e/b`, `g Ctrl-x`, `g?` | Plik, panel, layout, pomoc |
| historia | `q` | Zamknij Diffview (**Aktywne lokalne**) |
| layout diff3 `n,x` | `2do` / `3do` | Pobierz hunk z ours / theirs |
| layout diff4 `n,x` | `1do` / `2do` / `3do` | Pobierz hunk z base / ours / theirs |
| dowolny layout | `g?` | Pomoc właściwa dla layoutu |
| panel opcji | `Tab`, `q`, `g?` | Zmień opcję, zamknij, pomoc |
| panel pomocy | `q` / `Esc` | Zamknięcie |

#### Tutorial: bieżące zmiany wielu plików

1. Otwórz `<leader>gv`; to właściwy kontekst do stagingu, bo porównuje indeks z worktree.
2. Lokalny `Tab` z widoku ustawia fokus na panelu. `j/k` wybiera plik, `Enter` otwiera diff, `Shift-Tab` przechodzi do poprzedniego wpisu.
3. `-` albo `s` przełącza stage całego wskazanego wpisu zależnie od sekcji. Sprawdź `git status` po operacji.
4. `S` stage'uje realne working/conflict entries widoku, a `U` resetuje cały indeks repozytorium. Nie traktuj ich jak działań ograniczonych do jednego widocznego pliku.
5. `q` albo `<leader>gq` zamyka całą kartę.

#### Zaawansowany partial staging przez bufor indeksu

W zwykłym `<leader>gv` lewa strona unstaged diff reprezentuje indeks, prawa worktree. Możesz pobrać wybrany hunk semantyką wbudowanego diff `do`/`dp` do modyfikowalnego bufora indeksu, a następnie zapisać właśnie ten bufor przez `:write`. Jest to bezpośrednia edycja indeksu; po każdym zapisie sprawdź `git diff --cached`. Jeśli nie rozpoznajesz, która strona jest indeksem, użyj prostszego Gitsigns albo Neogit.

#### Tutorial: branch review i historia

1. `<leader>gm` otwiera `origin/main...HEAD`, czyli porównanie od merge-base do `HEAD`. Służy do review branch, nie do stagingu.
2. `<leader>gl` pokazuje historię bieżącego pliku, `<leader>gL` całego repo. `g!` zmienia opcje historii, `y` kopiuje hash, `L` pokazuje szczegóły.
3. `Ctrl-Alt-d` otwiera commit w osobnym Diffview. `gf` wraca do realnego pliku.
4. Nie używaj `S/U/X` w historycznym lub branchowym widoku tylko dlatego, że panel je pokazuje. Operacje nadal dotykają realnego repozytorium.

#### Tutorial: konflikt merge/rebase

1. Przechodź konflikty `[x` / `]x` i sprawdź etykiety layoutu.
2. Dla regionu wybierz `<leader>co` ours, `<leader>ct` theirs, `<leader>cb` base, `<leader>ca` wszystkie albo `dx` usuń. Wielkie warianty dotyczą całego pliku.
3. W layoutach diff3/diff4 numerowane `do` pobiera hunk ze wskazanej strony.
4. Przejrzyj realny wynik, wykonaj `:write`, sprawdź markery i dopiero wtedy stage'uj.
5. Buffer-local `<leader>ca` oznacza tutaj wszystkie strony konfliktu, nie code action LSP.

#### Bezpieczeństwo `X`

`X` w panelu plików może przywrócić wpis do lewej strony. W historii nie ma potwierdzenia: przywrócenie może wykonać odpowiednik checkoutu historycznej wersji ścieżki i zmienić worktree oraz indeks. Wtyczka może wypisać obiekt/komendę odzyskania starej treści, lecz nie jest to pełne undo indeksu. Najpierw zachowaj potrzebne zmiany i nie testuj `X` na ważnym pliku.

**Wymagania:** Neovim z LuaJIT, Git co najmniej 2.31 albo Mercurial co najmniej 5.4; lokalnie Git. Ikony przez `nvim-web-devicons` są opcjonalne.

**Diagnostyka:** `:checkhealth diffview`, `:DiffviewLog`, `:messages`, `:DiffviewRefresh` i jawny ref w `:DiffviewOpen`. Zły zakres najpierw zweryfikuj zwykłym `git rev-parse`/`git diff`, bez operacji przywracania.

**Źródła przypiętej rewizji:** [README](https://github.com/sindrets/diffview.nvim/blob/4516612fe98ff56ae0415a259ff6361a89419b0a/README.md), [pełny help](https://github.com/sindrets/diffview.nvim/blob/4516612fe98ff56ae0415a259ff6361a89419b0a/doc/diffview.txt), [domyślne mapowania](https://github.com/sindrets/diffview.nvim/blob/4516612fe98ff56ae0415a259ff6361a89419b0a/lua/diffview/config.lua).

<a id="plugin-codediff"></a>
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

`do` i `dp` zależą od bieżącego okna, a nie od stałej etykiety ours/theirs. W `:CodeDiff file HEAD` lewa rewizja jest readonly, ale prawa strona jest realnym, modyfikowalnym plikiem. `do` wykonane po prawej może więc pobrać hunk z `HEAD` i zmienić plik.

#### Modyfikowalność trybów

| Tryb | Strona lewa | Strona prawa |
|---|---|---|
| `CodeDiff file HEAD` | wirtualny `HEAD`, readonly | bieżący realny plik, edytowalny |
| `CodeDiff file REV1 REV2` | readonly | readonly |
| `CodeDiff file FILE1 FILE2` | realny, edytowalny | realny, edytowalny |
| zwykły explorer `CodeDiff` | zależy od wybranego wpisu | realny stan repo albo rewizja |

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

W conflict mode zwykłe `do`/`dp` są usuwane. Akcje `<leader>ct/co/cb/cx` wykonuj z lewej lub prawej strony; mimo mapowania w result buffer implementacja je tam odrzuca. W result buffer używaj `2do` albo `3do`.

#### Tutorial: jeden plik kontra `HEAD`

1. Zapisz bieżący plik i naciśnij `<leader>gf`.
2. Przechodź hunki `]c` / `[c`. Lewa strona to `HEAD`, prawa to realny plik.
3. Na prawej stronie `do` pobiera hunk z lewej i odrzuca tę część bieżącej zmiany. To realna edycja; użyj tylko świadomie, potem zapisz albo cofnij `u`.
4. `gf` wraca do realnego bufora w poprzedniej karcie, a `q` zamyka całą kartę CodeDiff.

#### Tutorial: explorer, historia i katalogi

1. `<leader>gD` otwiera explorer bieżącego statusu. `Enter` wybiera plik, `]f/[f` przechodzi, `<leader>b` ukrywa panel.
2. W zwykłym statusie `-` przełącza cały plik, `S` wykonuje `git add -A`, a `U` odpowiednik `git reset HEAD` dla całego repo.
3. `<leader>gh` pokazuje historię bieżącego pliku; domyślnie do 100 commitów i bez merge commitów. `Enter` rozwija commit i pliki.
4. `:CodeDiff file REV1 REV2` porównuje dwa snapshoty, a `:CodeDiff file FILE1 FILE2` dwa realne pliki.
5. `:CodeDiff dir DIR1 DIR2` skanuje rekurencyjnie katalogi; wykrywanie zmian pliku bazuje na rozmiarze i mtime, więc nie jest kryptograficzną weryfikacją identyczności.

#### Staging w widokach historycznych

W explorerze otwartym dla rewizji wpisy mogą nadal wyglądać jak grupa unstaged, ale `-`, `S`, `U` i `X` operują na realnym indeksie/worktree, nie na historycznym snapshotcie. Używaj ich wyłącznie w zwykłym `:CodeDiff` bez argumentów. `X` dla tracked wykonuje restore, a dla untracked może wykonać usunięcie przez Git po promptcie.

#### Tutorial: mergetool

1. Otwórz conflict mode odpowiednim `:CodeDiff merge plik` lub integracją Git.
2. Z lewej/prawej strony wybierz incoming/current/both/base przez `<leader>ct/co/cb/cx` i przechodź `]x/[x`.
3. W result buffer używaj `2do` incoming lub `3do` current.
4. Zapisz result buffer przez `:write`, przeczytaj wynik i dopiero potem stage'uj plik.

**Bezpieczeństwo:** `X` może skasować nieśledzony plik lub odrzucić unstaged. `<leader>cx` nie oznacza „usuń markery”, lecz reset konkretnego konfliktu do base. `S` i `U` działają na całym repo. Zawsze sprawdź `git status` i realny result buffer.

**Wymagania:** zapisany plik w repo Git dla trybu rewizji, `curl` albo `wget` do pobrania biblioteki C, Git dla explorera/historii.

**Diagnostyka:** `:CodeDiff install` pobiera brakującą bibliotekę, `:CodeDiff install!` wymusza reinstalację. Dalej użyj `:messages`, sprawdź Git i zapisany plik. Wtyczka nie ma osobnego health/log command. Alias `:VscodeDiff` pojawia się dopiero po załadowaniu CodeDiff.

**Źródła przypiętej rewizji:** [README](https://github.com/esmuellert/codediff.nvim/blob/32ccb9b66645b3b93148854b9b4421770709ad20/README.md), [pełny help](https://github.com/esmuellert/codediff.nvim/blob/32ccb9b66645b3b93148854b9b4421770709ad20/doc/codediff.txt), [akcje explorera](https://github.com/esmuellert/codediff.nvim/blob/32ccb9b66645b3b93148854b9b4421770709ad20/lua/codediff/ui/explorer/actions.lua), [akcje konfliktów](https://github.com/esmuellert/codediff.nvim/blob/32ccb9b66645b3b93148854b9b4421770709ad20/lua/codediff/ui/conflict/actions.lua).

</details>

<details>
<summary><strong>DAP: klient, UI, virtual text, Python i Go</strong></summary>

<a id="plugin-nvim-dap"></a>
### `nvim-dap`

**Co robi i po co:** klient Debug Adapter Protocol. Steruje breakpointami, uruchomieniem, krokami, stosami, REPL i konfiguracjami adapterów.

**Ładowanie lokalne:** po dowolnym klawiszu DAP albo publicznym poleceniu DAP. Setup konfiguruje UI, virtual text, znaki breakpoint/stop, adaptery Python i Go oraz `pwa-node`/`pwa-chrome` przez `js-debug-adapter`.

**Aktywne lokalne:** `F5`, `F10`, `F11`, `F12`, `<leader>db`, `<leader>dB`, `<leader>dc`, `<leader>de` w `n,x`, `<leader>dn`, `<leader>dp`, `<leader>dl`, `<leader>dr`, `<leader>dt`, `<leader>du`. Sam upstream nie instaluje domyślnych klawiszy.

**Polecenia przypiętej wersji:** `:DapSetLogLevel`, `:DapShowLog`, `:DapContinue`, `:DapToggleBreakpoint`, `:DapClearBreakpoints`, `:DapToggleRepl`, `:DapStepOver`, `:DapStepInto`, `:DapStepOut`, `:DapPause`, `:DapTerminate`, `:DapDisconnect`, `:DapRestartFrame`, `:DapNew`, `:DapEval`.

**Konfiguracje JS/TS lokalne:** Launch current file with Node, attach do procesu Node wybranego z listy, launch Chrome pod wpisanym URL i attach Chrome pod portem. Filetype: `javascript`, `javascriptreact`, `typescript`, `typescriptreact`. Source maps są włączone, a node internals i `node_modules` pomijane przy krokach.

**`launch.json`:** nvim-dap tej rewizji ma provider, który na żądanie czyta dokładnie `${cwd}/.vscode/launch.json`; nie szuka w katalogach nadrzędnych. `${workspaceFolder}` również oznacza bieżący CWD Neovim. Lokalne aliasy adapterów to `pwa-node` i `pwa-chrome`. Nie trzeba wywoływać starego loadera Lua.

**Wymagania:** co najmniej jeden adapter w `PATH`; poprawna konfiguracja projektu; dla browser attach Chrome uruchomiony z remote debugging.

#### Mentalny model

- `nvim-dap` jest klientem protokołu i zarządza sesją.
- Adapter (`debugpy-adapter`, `dlv`, `js-debug-adapter`) tłumaczy DAP na protokół debuggera.
- Debugger kontroluje docelowy proces. Błąd na każdej warstwie daje inny objaw.
- Konfiguracja launch/attach musi mieć co najmniej `type`, `request` i `name`; pozostałe pola są specyficzne dla adaptera.

#### Cykl życia `F5`

1. Bez sesji `F5` zbiera konfiguracje i prosi o wybór.
2. W zatrzymanej sesji `F5` kontynuuje.
3. W uruchomionej lub inicjalizowanej sesji pokazuje menu: pause, terminate, restart, disconnect, nowa sesja albo anulowanie.
4. `<leader>dt` kończy domyślnie fokusowaną sesję i zwykle proces debugowany. `:DapDisconnect` odłącza z `terminateDebuggee=false`, gdy adapter to wspiera.
5. `:DapNew` wymusza kolejną sesję. `<leader>dl` ponawia ostatnią konfigurację, także utworzoną przez helper testu Python/Go.

Breakpointy są przechowywane w pamięci Neovim między sesjami, ale nie są lokalnie zapisywane na dysku.

#### Tutorial: pierwsza sesja

1. Uruchom Neovim w root projektu, sprawdź `:pwd`, `:set filetype?` i executable adaptera.
2. Ustaw zwykły breakpoint `<leader>db`; warunkowy `<leader>dB` pyta o wyrażenie w języku programu.
3. Naciśnij `F5`, wybierz launch lub attach i poczekaj na zatrzymanie. Odrzucony breakpoint ma osobny znak.
4. Użyj `F10` step over, `F11` step into, `F12` step out, `F5` continue i `<leader>dp` pause.
5. `<leader>de` w Normal ocenia wyrażenie pod kursorem, a w Visual zaznaczenie przez dap-ui.
6. `<leader>dr` otwiera REPL, `<leader>du` przełącza panele, `<leader>dt` kończy sesję.

#### Breakpointy i kroki dostępne bez lokalnego skrótu

| Funkcja | Sposób użycia | Stan |
|---|---|---|
| hit condition | `:lua require('dap').set_breakpoint(nil, vim.fn.input('Hit condition: '))` | **Opcjonalne upstream**; składnia adaptera |
| logpoint | `:lua require('dap').set_breakpoint(nil, nil, vim.fn.input('Log message: '))` | **Opcjonalne upstream**; `{variable}` zależy od adaptera |
| exception filters | `:lua require('dap').set_exception_breakpoints()` | **Opcjonalne upstream** |
| run to cursor | `:lua require('dap').run_to_cursor()` | **Opcjonalne upstream** |
| reverse continue / step back | API `reverse_continue()` / `step_back()` | **Kontekstowe**, tylko gdy adapter wspiera reverse debugging |
| restart frame | `:DapRestartFrame` | **Polecenie**, zależne od adaptera |

`goto_()` skacze bez wykonania kodu po drodze, więc nie jest odpowiednikiem run-to-cursor. `:DapEval` tworzy edytowalny bufor `dap-eval://`, którego treść jest oceniana przy `:write`; nie jest tym samym co lokalne `<leader>de`.

#### Konfiguracje dostępne po lokalnym setup

| Język | Nazwy wyborów |
|---|---|
| Python | `file`, `file:args`, `attach`, `file:doctest` |
| Go | `Debug`, `Debug (Arguments)`, `Debug (Arguments & Build Flags)`, `Debug Package`, `Attach`, `Debug test`, `Debug test (go.mod)` |
| JS/TS/React | `Launch current file with Node`, `Attach to Node process`, `Launch Chrome`, `Attach to Chrome` |

`file:doctest` ma `noDebug=true`, więc uruchamia doctest bez zwykłego zatrzymywania na breakpointach. Lokalne `skipFiles` dotyczy dwóch konfiguracji Node, nie Chrome.

#### Tutorial: Node, TypeScript i Chrome

1. `Launch current file with Node` przekazuje `${file}` bez kompilacji. Samo `sourceMaps=true` nie uruchomi surowego TypeScript, jeśli runtime projektu go nie obsługuje.
2. `Attach to Node process` wybiera proces z listy; na macOS wymaga działającego `ps` i właściwych uprawnień.
3. `Launch Chrome` pyta o URL, domyślnie `http://localhost:3000`. `Attach to Chrome` wymaga procesu Chrome z remote debugging, domyślnie port `9222`.
4. Dla kompilowanego TS dodaj projektowe `outFiles` i program JavaScript do `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "pwa-node",
      "request": "launch",
      "name": "Launch compiled TypeScript",
      "program": "${workspaceFolder}/dist/index.js",
      "cwd": "${workspaceFolder}",
      "sourceMaps": true,
      "outFiles": ["${workspaceFolder}/dist/**/*.js"]
    }
  ]
}
```

Provider obsługuje `configurations`, `inputs` typu `promptString`/`pickString` oraz systemowe overrides. Nie implementuje VS Code tasks ani compounds, a JSON nie może zawierać trailing comma. Typ musi odpowiadać lokalnemu adapterowi, na przykład `pwa-node`, `pwa-chrome`, `python`, `debugpy` albo `go`.

#### Diagnostyka warstwowa

1. Załaduj DAP dowolnym skrótem i uruchom `:checkhealth dap`.
2. Sprawdź adaptery: `:lua =vim.tbl_keys(require('dap').adapters)`.
3. Sprawdź konfiguracje bieżącego filetype: `:lua =vim.tbl_map(function(c) return c.name end, require('dap').configurations[vim.bo.filetype] or {})`.
4. Dla `launch.json`: `:pwd` i `:lua =require('dap.ext.vscode').getconfigs()`.
5. Ustaw `:DapSetLogLevel TRACE`, odtwórz błąd i otwórz `:DapShowLog`. W REPL `.capabilities` pokazuje funkcje adaptera.

**Źródła przypiętej rewizji:** [README](https://github.com/mfussenegger/nvim-dap/blob/9e848e09a697ee95302a3ef2dd43fd6eb709e570/README.md), [pełny help](https://github.com/mfussenegger/nvim-dap/blob/9e848e09a697ee95302a3ef2dd43fd6eb709e570/doc/dap.txt), [provider `launch.json`](https://github.com/mfussenegger/nvim-dap/blob/9e848e09a697ee95302a3ef2dd43fd6eb709e570/lua/dap/ext/vscode.lua).

<a id="plugin-nvim-dap-ui"></a>
### `nvim-dap-ui`

**Co robi i po co:** panele Scopes, Stacks, Breakpoints, Watches po prawej oraz REPL i Console na dole. Lokalny listener otwiera UI, gdy sesja staje się aktywna, i zamyka dopiero po zniknięciu ostatniej sesji; `<leader>du` pozwala przełączyć ręcznie.

**Konfiguracja lokalna:** prawa kolumna szerokości 40 z proporcjami 0.40/0.25/0.20/0.15, dolny panel wysokości 10 i rounded border dla floatów.

| Element UI | Klawisz | Działanie | Stan |
|---|---|---|---|
| zmienna/watch | `Enter` / `2-LeftMouse` | Rozwinięcie dzieci | **Kontekstowe** |
| stack frame | `o` | Przejście do lokalizacji | **Kontekstowe** |
| watch/breakpoint | `d` | Usunięcie watcha lub włączonego breakpointu | **Kontekstowe** |
| zmienna/watch | `e` | Edycja wartości lub wyrażenia | **Kontekstowe** |
| zmienna/watch | `r` | Wysłanie do REPL | **Kontekstowe** |
| stack/breakpoint | `t` | Przełączenie subtelnych ramek albo enabled breakpointu | **Kontekstowe** |
| floating element | `q` / `Esc` | Zamknięcie floata | **Domyślne wtyczki** |

Nie ma domyślnego `w` dodającego dowolne wyrażenie w panelu Watches. W Watches wejdź do Insert, wpisz wyrażenie w prompt i zatwierdź `Enter`. Kod tej rewizji ma osobną kontekstową akcję `watch` pod `w` na zmiennej w Scopes; wysyła istniejącą zmienną do Watches, a nie otwiera promptu „add watch”.

Wtyczka nie rejestruje poleceń Ex; `require("dapui").open()` i podobne nazwy są API Lua.

**Wymagania:** `nvim-dap` i `nvim-nio`.

#### Co pokazuje każdy panel

| Panel | Znaczenie |
|---|---|
| Scopes | Zmienne aktualnie wybranej ramki stosu |
| Stacks | Wątki i ramki; `o` wybiera ramkę i zmienia kontekst Scopes/eval |
| Breakpoints | Lista breakpointów; `t` przełącza enabled, `o` skacze, `d` usuwa włączony |
| Watches | Wyrażenia oceniane przy zatrzymaniu; prompt znajduje się bezpośrednio w panelu |
| REPL | Wyrażenia debuggera, komendy DAP, frames/threads/scopes i output adaptera |
| Console | Zintegrowany terminal/stdin procesu dla konfiguracji z `integratedTerminal` |

REPL i Console nie są zamienne. W Console wejdź do trybu terminalowego/Insert, aby odpowiedzieć programowi. W REPL wpisuj wyrażenia lub komendy `.help`, `.frames`, `.threads`, `.scopes`, `.capabilities`, `.c`, `.n`, `.into`, `.out`, `.up`, `.down`, `.pause`.

#### Tutorial: scope, stack i watch

1. Zatrzymaj program. Rozwiń obiekt w Scopes przez `Enter` i przejdź do jego dzieci.
2. `r` wysyła zmienną do REPL, a `w` jest dostępne tylko dla odpowiednich zmiennych z `evaluateName` i dodaje właśnie tę zmienną do Watches.
3. W Stacks ustaw kursor na innej ramce i `o`; Scopes i ocena powinny przełączyć kontekst.
4. W Watches naciśnij `i`, wpisz `object.field`, zatwierdź `Enter`, wróć `Esc`. W Normal `e` edytuje wyrażenie, `d` usuwa, `r` wysyła do REPL.
5. Watch pozostaje między sesjami w bieżącym życiu pluginu, ale nie jest utrwalany po restarcie Neovim.

#### Eval, floaty i sterowanie sesją

- `<leader>de` w Normal ocenia `<cexpr>`, a w Visual zaznaczenie. Domyślny kontekst `hover` ma ograniczać skutki uboczne; niektóre adaptery wymagają kontekstu REPL.
- `q`/`Esc` zamyka float, nie całą sesję. `<leader>du` chowa/pokazuje layout bez zatrzymania programu.
- REPL ma klikalny winbar z play/pause, krokami, run last, terminate i disconnect. Klawiaturowe skróty globalne pozostają pewniejsze.
- **Opcjonalne upstream API:** `dapui.open({layout=1})`, `close`, `float_element('scopes')`, `elements.watches.add(...)`; repo nie mapuje tych wywołań.

**Diagnostyka:** jeśli sesja działa bez paneli, użyj `<leader>du`, `:messages` i sprawdź `nvim-dap-ui` oraz `nvim-nio` w Lazy. Akcja na wierszu bez obsługi wypisuje „No ... action for current line”; nie oznacza awarii całego panelu.

**Źródła przypiętej rewizji:** [README](https://github.com/rcarriga/nvim-dap-ui/blob/cc9dd33aade7f20bae414d0cba163bc60d4d4b43/README.md), [pełny help](https://github.com/rcarriga/nvim-dap-ui/blob/cc9dd33aade7f20bae414d0cba163bc60d4d4b43/doc/nvim-dap-ui.txt), [domyślne mapowania elementów](https://github.com/rcarriga/nvim-dap-ui/blob/cc9dd33aade7f20bae414d0cba163bc60d4d4b43/lua/dapui/config/init.lua).

<a id="plugin-nvim-dap-virtual-text"></a>
### `nvim-dap-virtual-text`

**Co robi i po co:** pokazuje wartości zmiennych obok kodu podczas zatrzymania. Lokalnie `commented=true`, więc tekst wygląda jak komentarz.

**Mapowania:** brak. **Polecenia po załadowaniu nadrzędnego DAP:** `:DapVirtualTextEnable`, `:DapVirtualTextDisable`, `:DapVirtualTextToggle`, `:DapVirtualTextForceRefresh`. Na całkiem świeżym starcie nie są triggerami Lazy i pojawią się dopiero po użyciu skrótu lub polecenia `nvim-dap`.

**Wymagania:** zatrzymana ramka z realną ścieżką źródła, załadowane scopes/variables, parser Treesitter i query `locals` dla języka.

#### Tutorial: wartości inline

1. Zatrzymaj program i najpierw sprawdź, czy panel Scopes zawiera zmienne.
2. Wartości pojawiają się przy węzłach definicji znalezionych przez query `locals`; `commented=true` formatuje je przy użyciu `commentstring` filetype.
3. Wykonaj krok i porównaj highlight wartości zmienionych względem poprzedniego zatrzymania.
4. Po continue tekst może pozostać widoczny, bo aktywny default `clear_on_continue=false`; to ostatni snapshot, nie wartość live.
5. `:DapVirtualTextToggle` przełącza, a `ForceRefresh` czyści i buduje od nowa, gdy adapter ominął typowe zdarzenie.

Domyślnie widoczna jest bieżąca ramka, pierwsza definicja i bez wszystkich referencji. `all_frames`, `all_references`, `virt_lines` oraz custom `display_callback` są **Opcjonalnym upstream**, nie aktywnym stanem.

**Diagnostyka:** gdy Scopes działa, ale tekst nie, sprawdź parser i query: `:lua =pcall(vim.treesitter.get_parser, 0)` oraz `:lua =vim.treesitter.query.get(vim.treesitter.language.get_lang(vim.bo.filetype), 'locals')`. Brak source path lub scopes powoduje cichy brak tekstu.

**Źródła przypiętej rewizji:** [README i opcje](https://github.com/theHamsta/nvim-dap-virtual-text/blob/fbdb48c2ed45f4a8293d0d483f7730d24467ccb6/README.md), [implementacja i polecenia](https://github.com/theHamsta/nvim-dap-virtual-text/blob/fbdb48c2ed45f4a8293d0d483f7730d24467ccb6/lua/nvim-dap-virtual-text.lua), [mapowanie zmiennych na Treesitter](https://github.com/theHamsta/nvim-dap-virtual-text/blob/fbdb48c2ed45f4a8293d0d483f7730d24467ccb6/lua/nvim-dap-virtual-text/virtual_text.lua).

<a id="plugin-nvim-dap-python"></a>
### `nvim-dap-python`

**Co robi i po co:** rejestruje debugpy, konfiguracje Python oraz debug testów unittest/pytest/django.

**Konfiguracja lokalna:** setup wskazuje executable `debugpy-adapter`. Interpreter programu/testu jest rozwiązywany między innymi z `VIRTUAL_ENV` lub `CONDA_PREFIX`. `<leader>dn` w Python uruchamia metodę testową nad kursorem.

**Mapowania i polecenia:** brak własnych defaultów i brak publicznych poleceń Ex. Lokalne `<leader>dn` wywołuje API test method.

**Wymagania:** aktywna konfiguracja wywołuje dokładnie `debugpy-adapter` z `PATH`. Inny interpreter z zainstalowanym `debugpy` nie jest automatycznym fallbackiem bez zmiany setup. Framework testowy musi być zainstalowany w środowisku docelowym.

#### Adapter a interpreter programu

- Adapter to lokalny wrapper `debugpy-adapter`, zwykle z Masona.
- Interpreter targetu/testu jest rozwiązywany osobno: `VIRTUAL_ENV`, `CONDA_PREFIX`, opcjonalny resolver, potem `venv`, `.venv`, `env`, `.env` pod CWD/rootami.
- Plik `envFile` albo domyślne `./.env` może dostarczyć proste wartości `KEY=VALUE`.

#### Konfiguracje Python

| Nazwa | Działanie |
|---|---|
| `file` | Uruchom bieżący plik |
| `file:args` | Zapytaj o argumenty i uruchom plik |
| `attach` | Połącz z debugpy, domyślnie `127.0.0.1:5678` |
| `file:doctest` | Uruchom `python -m doctest`, ale z `noDebug=true` |

#### Tutorial: program i attach

1. Aktywuj środowisko przed uruchomieniem Neovim i sprawdź `:echo executable('debugpy-adapter')`, `$VIRTUAL_ENV`, `$CONDA_PREFIX` oraz `:pwd`.
2. Ustaw breakpoint, `F5`, wybierz `file`; dla argumentów użyj `file:args`.
3. Przy błędnych importach odróżnij adapter od target interpretera. Działający adapter nie gwarantuje właściwych pakietów projektu.
4. `attach` wymaga już uruchomionego procesu debugpy nasłuchującego pod adresem; nie startuje aplikacji sam.

#### Tutorial: najbliższy test

1. Ustaw kursor wewnątrz funkcji testowej i naciśnij `<leader>dn`.
2. Helper wybiera najbliższą definicję funkcji powyżej kursora i uwzględnia klasę; nie sprawdza, czy nazwa naprawdę oznacza test.
3. Runner jest wykrywany kolejno przez `pytest.ini`, `manage.py`, konfigurację pytest w `pyproject.toml`, a w pozostałych przypadkach unittest.
4. Sesja używa integrated terminal. Po udanym uruchomieniu `<leader>dl` ponawia wygenerowaną konfigurację.
5. `test_class()` i `debug_selection()` istnieją jako **Opcjonalne upstream API**, bez lokalnych mapowań.

**Diagnostyka:** zły test zwykle oznacza położenie kursora lub parser Python; błąd pytest/Django brak frameworka w target environment; unverified breakpoint może oznaczać path mapping, `justMyCode` albo niezaładowany moduł. Log DAP rozstrzyga, czy zawiódł adapter czy program.

**Źródła przypiętej rewizji:** [README](https://github.com/mfussenegger/nvim-dap-python/blob/1808458eba2b18f178f990e01376941a42c7f93b/README.md), [help](https://github.com/mfussenegger/nvim-dap-python/blob/1808458eba2b18f178f990e01376941a42c7f93b/doc/dap-python.txt), [konfiguracje i test discovery](https://github.com/mfussenegger/nvim-dap-python/blob/1808458eba2b18f178f990e01376941a42c7f93b/lua/dap-python.lua).

<a id="plugin-nvim-dap-go"></a>
### `nvim-dap-go`

**Co robi i po co:** rejestruje Delve, konfiguracje debug programu/testu/attach i odnajdywanie najbliższego testu przez Treesitter.

**Konfiguracja lokalna:** domyślne `require("dap-go").setup()`. `<leader>dn` dla filetype Go uruchamia nearest test.

**Mapowania i polecenia:** brak własnych aktywnych klawiszy i publicznych poleceń Ex. README pokazuje przykładowe mapowania debug test/last test, ale są **Przykładem nieaktywnym**.

**Wymagania:** `dlv` w `PATH` i parser Treesitter Go, który jest instalowany lokalnie.

#### Konfiguracje Go

| Nazwa | Działanie |
|---|---|
| `Debug` | Debug bieżącego pliku |
| `Debug (Arguments)` | Prompt prostych argumentów |
| `Debug (Arguments & Build Flags)` | Prompt argumentów i build flags |
| `Debug Package` | Debug katalogu bieżącego pliku |
| `Attach` | Wybór lokalnego procesu |
| `Debug test` | Test mode dla bieżącego pliku |
| `Debug test (go.mod)` | Test package względem CWD/modułu |

Prompty argumentów dzielą tekst po spacjach i nie implementują pełnego cytowania shell. Dla argumentu zawierającego spację użyj projektowej konfiguracji Lua/`launch.json`, zamiast zakładać obsługę cudzysłowów.

#### Tutorial: program, package i attach

1. Otwórz moduł z jego root, sprawdź `:pwd`, `:echo executable('dlv')` i `dlv version` w powłoce.
2. Ustaw breakpoint i wybierz `F5 → Debug` dla pliku albo `Debug Package` dla pakietu.
3. `Attach` wybiera istniejący lokalny proces; wymaga uprawnień systemu do debugowania.
4. Build tags i flags ustawiaj jako build flags, nie zwykłe args Delve w trybie DAP.

#### Tutorial: test i subtest

1. Ustaw kursor wewnątrz `Test...` z parametrem `*testing.T`/`*testing.M` albo obsługiwanego `t.Run("literal", ...)`.
2. `<leader>dn` buduje zakotwiczony wzorzec `-test.run` dla testu/subtestu i package na podstawie pliku względem CWD.
3. Helper nie obsługuje jako nearest test benchmarków, examples, fuzz ani dowolnych wrapperów.
4. `<leader>dl` ponawia ostatni wygenerowany test. `require('dap-go').debug_last_test()` istnieje, ale nie ma lokalnego mapowania.

**Diagnostyka:** brak testu oznacza zwykle zły CWD, kursor przed deklaracją, nieobsługiwaną sygnaturę albo brak parsera. Odrzucony breakpoint może wskazywać build tags lub plik niewłączony do kompilacji. Użyj TRACE logu DAP dla błędu `dlv dap`.

**Źródła przypiętej rewizji:** [README](https://github.com/leoluz/nvim-dap-go/blob/b4421153ead5d726603b02743ea40cf26a51ed5f/README.md), [help](https://github.com/leoluz/nvim-dap-go/blob/b4421153ead5d726603b02743ea40cf26a51ed5f/doc/nvim-dap-go.txt), [konfiguracje](https://github.com/leoluz/nvim-dap-go/blob/b4421153ead5d726603b02743ea40cf26a51ed5f/lua/dap-go.lua), [parser testów](https://github.com/leoluz/nvim-dap-go/blob/b4421153ead5d726603b02743ea40cf26a51ed5f/lua/dap-go-ts.lua).

</details>

<details>
<summary><strong>Distant i vim-tmux-navigator po stronie Neovim</strong></summary>

<a id="plugin-distant"></a>
### `distant.nvim`

**Co robi i po co:** otwiera i zapisuje zdalne pliki przez lokalny klient i zdalny serwer Distant, zapewnia browser katalogów, shell, spawn, wyszukiwanie i podstawę dla zdalnego LSP.

**Ładowanie lokalne:** na `:DistantInstall`, `:DistantClientVersion`, `:DistantConnect`, `:DistantLaunch`, `:DistantOpen`, `:DistantShell`, `:DistantSpawn` albo lokalne `<leader>r...`. Po setup dostępne są wszystkie polecenia poniżej. `:Distant`, search, health i część poleceń pomocniczych nie są zimnymi triggerami Lazy; na świeżym starcie najpierw użyj jednego z wymienionych poleceń albo `:Lazy load distant.nvim`.

**Konfiguracja lokalna:** klient `~/.local/bin/distant`, manager bez daemona, timeout maksymalny 60 s. Domyślny launch na serwerze używa `/home/ukibbb/.local/bin/distant`. Klucz `servers.raspberry` jest nazwą hosta/profilu, natomiast pola `host` umieszczone w `connect.default` i `launch.default` nie są obsługiwane przez tę rewizję i są ignorowane. UI spróbuje hosta `raspberry`, chyba że SSH/DNS rozwiązuje ten alias. `<leader>rp` przekazuje IP bezpośrednio i korzysta z ustawień wildcard, nie z wpisu profilu.

**Stan zdalnego LSP:** `lsp = { ['*'] = {} }` nie ma semantyki wildcard; `'*'` jest tylko etykietą pustej konfiguracji. Brak `cmd` i `root_dir` oznacza, że żaden remote LSP nie startuje obecnie automatycznie.

**Aktywne lokalne:** `<leader>rl`, `<leader>ro`, `<leader>rs`, `<leader>rx`, `<leader>rp`.

**Polecenia przypiętej rewizji:** `:Distant` (główne UI), `:DistantCancelSearch`, `:DistantCheckHealth`, `:DistantClientVersion`, `:DistantConnect`, `:DistantCopy`, `:DistantInstall`, `:DistantLaunch`, `:DistantMetadata`, `:DistantMkdir`, `:DistantOpen`, `:DistantSearch`, `:DistantSessionInfo`, `:DistantShell`, `:DistantSpawn`, alias `:DistantRun`, `:DistantSystemInfo`, `:DistantRemove`, `:DistantRename`.

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
| Connections | `Enter` | Przełącz aktywne połączenie albo uruchom skonfigurowany host po potwierdzeniu | **Kontekstowe** |
| Connections | `K`, `I` | Zabij połączenie / przełącz informacje | **Kontekstowe** |

#### Architektura połączenia

1. Lokalny CLI uruchamia managera i operacje sieciowe.
2. Manager utrzymuje wiele connection ID i jedno globalne aktywne połączenie.
3. Shell, spawn, search i bezpośrednie polecenia używają globalnie aktywnego connection ID.
4. Otwarty zdalny bufor zapamiętuje własne `b:distant.client_id`; zapis nadal używa jego połączenia nawet po przełączeniu globalnego active.
5. `:DistantSessionInfo` otwiera globalny widok Connections i nie dowodzi, z którym hostem związany jest bieżący bufor. Sprawdź `:lua =vim.b.distant`.

#### Connect kontra Launch

- `DistantLaunch ssh://user@host` uruchamia na hoście skonfigurowany zdalny binarny Distant, a potem się łączy. Tego używa `<leader>rl` i `<leader>rp`, więc `/home/ukibbb/.local/bin/distant` musi istnieć.
- `DistantConnect ssh://user@host` może użyć backendu SSH bez osobnej instalacji zdalnego Distant. Lokalny klient pozostaje wymagany.
- Oba po sukcesie zmieniają globalnie aktywne połączenie. Otwarty wcześniej bufor zachowuje własny ID.

#### Tutorial: połączenie, plik i katalog

1. Sprawdź `:DistantClientVersion`, potem uruchom `<leader>rl` i podaj pełne `ssh://user@host` albo użyj jawnego `:DistantConnect`.
2. Otwórz `:Distant` i sprawdź aktywny connection. `I` rozwija informacje; `K` po potwierdzeniu zabija połączenie, ale nie naprawia ani nie zamyka związanych z nim buforów.
3. `<leader>ro` uzupełnia `:DistantOpen `. Bez ścieżki polecenie otwiera zdalne `.`.
4. Istniejący plik staje się buforem `acwrite`; `:write` wysyła treść przez zapamiętane połączenie. Nieistniejąca ścieżka tworzy pusty bufor, a realny plik powstaje dopiero przy zapisie.
5. W katalogu `N` tworzy pusty plik/bufor, `K` katalog rekurencyjnie, `C` kopiuje zdalnie-do-zdalnie, `R` pyta o pełną ścieżkę docelową, a `M` pokazuje metadata.

#### Usuwanie zdalne

`D` w browserze pyta `Yes / Force / No`, przy czym pierwszą zaznaczoną odpowiedzią może być Yes. Force pozwala usuwać niepusty katalog. Bezpośrednie `:DistantRemove` nie pyta, a bang wymusza. Operacja nie trafia do lokalnego kosza; przed zatwierdzeniem przeczytaj host i pełną ścieżkę.

#### Tutorial: search, shell i spawn

1. Po załadowaniu użyj `:DistantSearch "regex" path=. target=contents`. Pierwszy argument jest regexem; wartości ze spacjami wymagają podwójnych cudzysłowów parsera wtyczki.
2. Wyniki napływają do quickfix, domyślnie stronicowane po 10; `[q`/`]q` nawiguje, a otwarcie wyniku ładuje remote buffer.
3. Tylko jedno wyszukiwanie edytora jest aktywne. Nowe anuluje stare; `:DistantCancelSearch` zatrzymuje bieżące.
4. `<leader>rs` otwiera interaktywny zdalny terminal w bieżącym oknie.
5. `<leader>rx` uzupełnia `:DistantSpawn `. Spawn uruchamia pojedyncze polecenie, czeka i drukuje stdout/stderr. Pipe, redirect i złożone wyrażenia wymagają jawnego uruchomienia zdalnego shella.
6. Shell i spawn używają globalnego active connection, niekoniecznie hosta bieżącego remote buffer.

#### Zdalne zmiany i watchdiff

Distant ma własny watcher remote pliku. Czysty bufor może zostać przeładowany, a zmodyfikowany lokalnie prosi o decyzję. Bufory mają `buftype=acwrite`, dlatego lokalny watchdiff ich nie śledzi i nie zapisuje dla nich historii/provenance. Niektóre backendy SSH mogą nie wspierać watch capability.

#### Jak naprawdę włączyć remote LSP

Potrzebna jest jawna etykieta z remote `cmd`, `root_dir` lub resolverem i ewentualnie `filetypes`. Distant uruchamia proces na hoście i tłumaczy URI. Lokalny Mason nie instaluje executable na serwerze. Obecny pusty wpis `'*'` nie spełnia tych warunków, więc diagnozowanie zaczyna się od poprawy konfiguracji, nie od restartu lokalnego LSP.

**Bezpieczeństwo:** `DistantRemove`/`D`, rename, copy, spawn i `K` w Connections zmieniają host zdalny. Globalny active i buforowy client ID mogą wskazywać różne hosty.

**Wymagania:** Neovim co najmniej 0.8, lokalny klient Distant 0.20.x zgodny z gałęzią v0.3 i SSH. Zdalny executable jest wymagany przez skonfigurowany Launch, ale nie przez każdy możliwy tryb Connect. Wtyczka jest oznaczona upstream jako alpha.

**Diagnostyka:** `:DistantClientVersion`, `:DistantCheckHealth`, `:DistantSystemInfo`, `:messages`, ręczne SSH, `:echo executable(expand('~/.local/bin/distant'))`, aktywny wpis w `:Distant` i `:lua =vim.b.distant`. Timeout sprawdzaj na właściwym hoście i ścieżce binarnej.

**Źródła przypiętej rewizji:** [README](https://github.com/chipsenkbeil/distant.nvim/blob/67d6b066e8490725718b79f643966f4eafc7da3c/README.md), [domyślna konfiguracja](https://github.com/chipsenkbeil/distant.nvim/blob/67d6b066e8490725718b79f643966f4eafc7da3c/lua/distant/default.lua), [remote LSP client](https://github.com/chipsenkbeil/distant.nvim/blob/67d6b066e8490725718b79f643966f4eafc7da3c/lua/distant-core/client.lua), [search](https://github.com/chipsenkbeil/distant.nvim/blob/67d6b066e8490725718b79f643966f4eafc7da3c/lua/distant/editor/search.lua).

<a id="plugin-vim-tmux-navigator"></a>
### `vim-tmux-navigator`

**Co robi i po co:** tworzy jedną siatkę nawigacji ze splitów Neovim i paneli tmux. Ładuje się natychmiast po obu stronach.

**Mapowania:** `Ctrl-h/j/k/l` oraz `Ctrl-\` w Normal Neovim i root tmux. W Terminal Neovim działają `Ctrl-h/j/k/l`, ale nie `Ctrl-\`; dla filetype `fzf` są przekazywane do terminala zamiast nawigować. Wtyczka tmux instaluje wszystkie pięć klawiszy w copy-mode-vi oraz `prefix Ctrl-l` do wysłania clear-screen. Lokalne mapowania Insert `Ctrl-h/j/k/l` mają pierwszeństwo w Neovim i poruszają kursorem.

**Polecenia:** `:TmuxNavigateLeft`, `:TmuxNavigateDown`, `:TmuxNavigateUp`, `:TmuxNavigateRight`, `:TmuxNavigatePrevious`, `:TmuxNavigatorProcessList`.

**Wymagania:** tmux co najmniej 1.8, Bash, `ps`, `grep` i wspólny plugin po obu stronach. Zagnieżdżony tmux wymaga świadomego `send-prefix` i nie ma pełnej automatycznej nawigacji między warstwami.

#### Jak przebiega jeden klawisz

1. Zewnętrzny tmux odbiera `Ctrl-h/j/k/l` albo `Ctrl-\` w tabeli root.
2. Skrypt sprawdza przez `ps` procesy na TTY panelu i odrzuca stany stopped/dead/zombie.
3. Jeśli widzi Vim/Neovim/fzf, wysyła klawisz do aplikacji; w zwykłej powłoce od razu wykonuje `select-pane`.
4. Neovim próbuje `wincmd` wewnątrz bieżącej karty. Jeśli okno się zmieniło, kończy.
5. Na krawędzi Neovim wywołuje `tmux select-pane` dla własnego `$TMUX_PANE`.

Dlatego plugin musi istnieć po obu stronach, a wykrywanie nie opiera się wyłącznie na `pane_current_command`.

#### Macierz trybów

| Kontekst | Zachowanie |
|---|---|
| Normal Neovim | Nawigacja split/panel wszystkimi pięcioma klawiszami |
| Insert Neovim | Lokalne `Ctrl-h/j/k/l` porusza kursorem; nie opuszcza Neovim |
| Terminal Neovim | `Ctrl-h/j/k/l` nawiguje, `Ctrl-\` nie jest mapowane |
| terminal filetype `fzf` | Klawisze są przekazywane do fzf |
| tmux copy-mode-vi | Tmux bezpośrednio wybiera panel |
| poza tmux | Polecenia kierunkowe Neovim działają na splity; `TmuxNavigatorProcessList` może nie istnieć |
| Visual/Select/Operator/Command-line | Brak specjalnych mapowań navigatora |

#### Tutorial: split do panelu i previous

1. Utwórz pionowy split Neovim oraz panel tmux po jego prawej stronie.
2. W Normal naciskaj `Ctrl-l`: najpierw zmieni split, potem przekroczy granicę tmux. `Ctrl-h` wróci.
3. `Ctrl-\` próbuje poprzedni split Neovim; gdy odpowiedni poprzedni split nie istnieje, przekazuje previous do tmux. Nie jest prostym globalnym MRU wszystkich warstw.
4. Nawigacja kierunkowa nie przełącza kart Neovim.

#### Aktywne defaulty, które wpływają na zachowanie

- `save_on_switch=0`: przejście do tmux nie zapisuje pliku.
- Nawigacja jest dozwolona przy zoomie; wyjście przez krawędź zwykle odzoomowuje okno tmux.
- Preserve zoom i no-wrap nie są skonfigurowane. Na zewnętrznej krawędzi Vim/tmux może przejść na przeciwną stronę zależnie od układu.
- Opcjonalne `g:tmux_navigator_disable_when_zoomed`, `preserve_zoom`, `no_wrap` i `save_on_switch` są dostępne upstream, ale nieaktywne.

#### Konflikty klawiszy

- Root `Ctrl-h` nie jest zwykłym terminalowym backspace.
- Root `Ctrl-l` nie czyści powłoki; użyj `Ctrl-s Ctrl-l`, bo plugin zachowuje clear-screen pod prefixem.
- Root `Ctrl-\` nie wysyła SIGQUIT do procesu i konfiguracja nie dodaje osobnego zamiennika.
- W Insert lokalny `Ctrl-h` jest ruchem w lewo, więc kasowanie pozostaje pod Backspace.

#### Diagnostyka

1. `:verbose nmap <C-h>` i `:verbose tmap <C-h>` pokazuje stronę Neovim.
2. `:TmuxNavigatorProcessList` wypisuje wynik detekcji procesów panelu.
3. `tmux list-keys -T root` i `tmux list-keys -T copy-mode-vi` pokazują stronę tmux.
4. Sprawdź `$TMUX`, `$TMUX_PANE`, zoom oraz `ps -o state= -o comm= -t "$(tmux display -p '#{pane_tty}')"`.
5. Wrappery, Docker TTY, SSH, nested tmux i nietypowy `ps` mogą oszukać detekcję. fzf jest celowo częścią wzorca.

**Źródła przypiętej rewizji:** [README i konfiguracja](https://github.com/christoomey/vim-tmux-navigator/blob/c45243dc1f32ac6bcf6068e5300f3b2b237e576a/README.md), [help](https://github.com/christoomey/vim-tmux-navigator/blob/c45243dc1f32ac6bcf6068e5300f3b2b237e576a/doc/tmux-navigator.txt), [kod Neovim/Vim](https://github.com/christoomey/vim-tmux-navigator/blob/c45243dc1f32ac6bcf6068e5300f3b2b237e576a/plugin/tmux_navigator.vim), [kod tmux](https://github.com/christoomey/vim-tmux-navigator/blob/c45243dc1f32ac6bcf6068e5300f3b2b237e576a/vim-tmux-navigator.tmux).

</details>

<details>
<summary><strong>Lokalne watchdiff.nvim i claude.nvim</strong></summary>

<a id="plugin-watchdiff"></a>
### `watchdiff.nvim`

**Ścieżka:** `watchdiff.nvim/` w tym repozytorium.

**Co robi i po co:** obserwuje rekursywnie bieżący katalog przez `vim.uv` i pokazuje, co narzędzie zewnętrzne zmieniło od ostatniego „uznanego” stanu. To inny punkt odniesienia niż Gitsigns: baseline użytkownika zamiast Git HEAD/index.

**Ładowanie lokalne:** `VeryLazy`, `opts={}`. Debounce 200 ms, maksymalnie 50 wpisów historii na plik, ignorowanie między innymi `.git`, `.next`, `node_modules`, swapów i `.DS_Store`. Domyślnie śledzone są tylko już załadowane bufory.

**Zachowanie:** czysty bufor jest przeładowywany przez `checktime`; zmienione/dodane linie dostają zielone tło, usunięte pojawiają się jako czerwone virtual lines. Baseline aktualizuje otwarcie, własny zapis i clear, lecz nie zewnętrzna edycja.

| Kontekst | Klawisz | Działanie | Stan |
|---|---|---|---|
| globalny `n` | `<leader>ch` | Wyczyść highlight i uznaj bieżącą treść jako baseline | **Aktywne lokalne** |
| scratch historii | `q` | Zamknij historię | **Kontekstowe** |
| globalny | mapowanie historii | Brak, bo `keys.history=false` | **Warunkowe/wyłączone** |

**Polecenie:** `:WatchDiffHistory` pokazuje zapamiętaną historię bieżącego pliku. Funkcje provenance używane przez Claude są API Lua, nie poleceniami Ex.

#### Dokładny model baseline

| Zdarzenie | Baseline | Highlight | Historia |
|---|---|---|---|
| otwarcie pliku | ustawiony na treść bufora | brak zmiany | brak wpisu |
| zewnętrzna zmiana czystego bufora | pozostaje stary | przeliczony baseline → nowa treść | nowy skumulowany wpis |
| własne `:write` | przesunięty do zapisanej treści | istniejące extmarki chwilowo pozostają | brak wpisu |
| następna zewnętrzna zmiana po zapisie | używa post-save baseline | stare markery znikają i są przeliczane | nowy wpis |
| `<leader>ch` | przesunięty do bieżącej treści | wyczyszczony | wcześniejsza historia pozostaje |
| restart Neovim | utracony | utracony | utracona cała historia |

Kolejne zewnętrzne zmiany bez clear są porównywane do tego samego uznanego baseline. Drugi wpis może więc opisywać `A → C`, a nie tylko ostatni krok `B → C`.

#### Tutorial: kontrolowana zmiana zewnętrzna

1. Uruchom Neovim w root testowego projektu i sprawdź `:pwd`. Otwórz oraz zapisz zwykły lokalny plik.
2. Zmień go z drugiej powłoki lub narzędzia. Wróć do Neovim; czysty bufor powinien się przeładować.
3. Zielone tło oznacza dodane/zmienione wiersze, czerwone virtual lines usunięcia względem baseline. Zamiana może liczyć jednocześnie dodania i usunięcia.
4. Otwórz `:WatchDiffHistory`. Najnowszy wpis pokazuje czas, ścieżkę, source/action, liczniki, opcjonalny summary i `meta.question`; pozostałe metadata są w Lua `get_history()`, ale UI ich nie renderuje. Historia nie przechowuje patcha ani starej/nowej treści.
5. Dopiero po review użyj `<leader>ch`. To akceptuje bieżącą treść jako nowy punkt odniesienia; nie usuwa zapisanej w pamięci listy historii.

#### Konflikt z niezapisanym buforem

W głównej ścieżce fs-event zmodyfikowany bufor dostaje ostrzeżenie i nie jest przeładowywany; nie zawsze pojawia się interaktywny prompt. Prompt należy do fallbacku `FileChangedShell`. Nie powstaje wtedy wpis historii, a `:e!` bezpowrotnie odrzuca lokalną wersję bufora. Najpierw skopiuj ją do innego bufora/pliku albo porównaj dysk osobno.

#### Historia i provenance bez fałszywych gwarancji

- Zwykły event dostaje `source="external"`; watcher nie zna procesu, który zapisał plik.
- Claude może przez API oznaczyć następny pasujący diff, ale jest to adnotacja, nie dowód autorstwa ani atomowe powiązanie z konkretnymi bajtami.
- Na ścieżkę istnieje jeden pending annotation bez kolejki i expiry. Konflikt, identyczna treść, zignorowany event albo pominięcie dużego pliku może pozostawić oznaczenie dla późniejszej, innej zmiany.
- Liczniki wpisu są skumulowane względem baseline. Historia ma maksymalnie 50 rekordów na canonical path i istnieje tylko w bieżącej sesji.

#### Ograniczenia zakresu

- Plik ponad 5000 wierszy kończy obsługę przed highlightem, liczeniem, historią, notyfikacją i konsumpcją provenance, nie tylko przed rysowaniem inline.
- Domyślnie zmiana nieotwartego pliku jest ignorowana. Opcjonalne `track_unopened_files=true` ładuje plik i używa Git `HEAD` jako baseline, co jest innym modelem.
- Usunięcie całego pliku, rename i trwała historia patchy nie są implementowane.
- Watcher obserwuje jeden CWD i restartuje się przy `DirChanged`; wsparcie recursive zależy od filesystemu/platformy.
- Bufory Distant `acwrite` nie są śledzone.

**Bezpieczeństwo:** `<leader>ch` nie cofa zmian, tylko je uznaje. `:e!` odrzuca niezapisany bufor. Provenance nie powinno być używane jako audyt bezpieczeństwa.

**Wymagania:** Neovim z `vim.uv`; recursive fs events zależą od systemu plików. CWD powinien być rootem obserwowanego projektu.

**Diagnostyka:** `:pwd`, `:set modified? autoread?`, `:messages`, `:autocmd WatchDiff`, sprawdzenie czy bufor jest załadowany i zwykły oraz czy ścieżka nie pasuje do ignore. `watchdiff.nvim/VALIDATION.md` zawiera ręczny scenariusz, ale nie pokrywa wszystkich ograniczeń provenance i dużych plików.

**Źródła lokalne:** [README](watchdiff.nvim/README.md), [implementacja](watchdiff.nvim/lua/watchdiff.lua), [ręczna walidacja](watchdiff.nvim/VALIDATION.md).

<a id="plugin-claude"></a>
### `claude.nvim`

**Ścieżka:** `claude.nvim/` w tym repozytorium.

**Co robi i po co:** lokalny popup do wysyłania pytania z kontekstem pliku/zaznaczenia do CLI Claude, z drawerem odpowiedzi i kontrolowanym wstawianiem komentarzy do kodu.

**Ładowanie lokalne:** `VeryLazy`, `opts={}`. Backend to executable `claude` z argumentami `-p --output-format json --permission-mode plan --model ... --json-schema ...`. Modele: `opus 4.5`, `sonnet`, `haiku`; etykieta `opus 4.5` wysyła alias CLI `opus`, którego faktyczną wersję rozwiązuje zainstalowane Claude CLI. Odpowiedzi używają drawera Volt, a scratch jest fallbackiem.

**Aktywne globalne:** `<leader>ac` w `n,v` oraz `<leader>aC` w `n,v`.

**Polecenia:** `:Claude`, `:ClaudeCommentNow`, `:ClaudeComment`.

#### Popup wejściowy

| Tryb | Klawisz | Działanie |
|---|---|---|
| `i,n` | `Enter` | Wyślij prompt |
| `i` | `Ctrl-j` | Wstaw nową linię bez wysyłania |
| `n` | `q` / `Esc` | Zamknij |
| `i` | `Esc` | Zamknij |
| `i` | `Ctrl-c` | Gdy busy: anuluj żądanie i pozostaw popup; gdy idle: zamknij popup |
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

#### Jaki kontekst jest wysyłany

Prompt zawiera root repozytorium, ścieżkę/etykietę pliku, pozycję kursora, zakres zaznaczenia, zaznaczony tekst, pytanie, tryb answer/comment-now i wymagany schema output. Bez zaznaczenia cała treść pliku nie jest wklejana do promptu; proces CLI startuje z `cwd=repo_root` i może sam przeczytać zapisany plik oraz inne pliki repo.

Konsekwencje prywatności:

- pytanie i zaznaczony kod trafiają jako argument do lokalnego procesu Claude;
- `--permission-mode plan` i prompt proszą o read-only, ale CLI może czytać dodatkowe pliki repo;
- `consulted_files` jest deklaracją modelu, nie niezależnym audytem odczytów;
- każda prośba jest nowym procesem, bez historii rozmowy;
- unnamed buffer bez zaznaczenia nie daje użytecznej ścieżki ani pełnej treści.

Submit jest blokowany dla comment-now z niezapisanym buforem oraz answer bez zaznaczenia w zmodyfikowanym buforze. Answer z Visual może wysłać zaznaczony, niezapisany tekst, ale późniejsze `I` zwykle nie przejdzie kontroli stanu pliku.

#### Modele i cykl żądania

- Każdy nowy popup zaczyna od pierwszego modelu. `Tab` cyklicznie idzie tylko naprzód; `Shift-Tab` nie ma mapowania.
- F2 zmienia answer/comment-now tylko gdy request nie jest busy.
- Busy `Ctrl-c` wysyła zakończenie procesu i ustawia UI jako idle. Callback starego procesu nie ma osobnego tokenu generacji, więc po anulowaniu może jeszcze pojawić się spóźniony błąd, a bardzo szybki resubmit ma ryzyko wyścigu.
- Zamknięcie popupu albo zmiana/reopen także anuluje proces. Nie ma lokalnego timeoutu.
- Błąd backendu pozostawia popup z footerem Error, dzięki czemu można poprawić prompt i wysłać ponownie.
- Plugin przechowuje tylko ostatni rekord w pamięci. Nie ma historii konwersacji ani polecenia reopen-last-answer.

#### Tutorial: odpowiedź do przeglądu

1. Zaznacz funkcję i użyj `<leader>ac`, albo użyj skrótu bez zaznaczenia na czystym, zapisanym pliku.
2. Wpisz pytanie; `Ctrl-j` tworzy nową linię, `Ctrl-l` czyści, `Tab` zmienia model, `Enter` wysyła.
3. W drawerze `1/2/3` przełącza Answer/Question/Files. `Tab`/`Shift-Tab` robi to samo cyklicznie.
4. `y` kopiuje surową odpowiedź, `Y` buduje i kopiuje preview komentarza bez rygorystycznego sprawdzenia bieżącego stanu pliku.
5. W Files `Enter` otwiera zgłoszoną ścieżkę w splicie. Lista jest model-reported; plugin sprawdza czy plik da się przeczytać, ale nie stanowi audytu bezpieczeństwa i nie gwarantuje, że relative path pozostaje w repo.
6. `o` przenosi odpowiedź do prostszego scratcha. Fallback scratch nie ma kart ani file preview.
7. `I` próbuje wstawić komentarz dla rekordu widocznego w drawerze; `:ClaudeComment` używa globalnie ostatniej odpowiedzi.

#### Dokładne zabezpieczenia wstawiania

Przed zapisem plugin sprawdza: obecność source path w rekordzie, modyfikowalny bufor, brak niezapisanych zmian, identyczny `changedtick` jak przy otwarciu popupu, hash dysku równy snapshotowi oraz poprawne `commentstring` z `%s`. Nawet edit + undo zmienia `changedtick` i może konserwatywnie zablokować operację. Nie ma jednak jawnego `filereadable()` ani chronionego odczytu w ścieżce insert: usunięty lub nieczytelny plik może zgłosić `E484` zamiast kontrolowanego fallbacku.

Komentarz nie jest umieszczany przez AST ani model. Trafia po końcu zaznaczenia albo po pierwotnej linii kursora, dziedziczy wcięcie, dostaje prefiks `Claude: `, maksymalnie 6 zawiniętych wierszy po 92 bajty. Marker heading/list jest usuwany; obsługa fenced code nie śledzi pełnego stanu bloku.

> **Ograniczenie semantyczne:** prompt prosi model, aby zwrócił pusty `comment_candidate`, gdy komentarz inline jest niebezpieczny. Obecna implementacja przy pustym kandydacie fallbackuje jednak do pierwszych oczyszczonych linii ogólnej odpowiedzi. Comment-now może więc wstawić komentarz mimo odmowy modelu. Zawsze traktuj wynik jak zwykłą edycję wymagającą review.

#### Tutorial: comment-now

1. Upewnij się, że plik jest zapisany i czysty, ustaw kursor lub zaznacz zakres, użyj `<leader>aC`.
2. Przeczytaj badge `comment-now`, wybierz model i wyślij.
3. Gdy kontrole pliku przejdą, writer zapisuje komentarz bez otwierania drawera. Kontrolowana odmowa bezpieczeństwa otwiera drawer; błąd odczytu brakującego lub nieczytelnego pliku może natomiast przerwać operację przez `E484`.
4. Natychmiast obejrzyj bufor, `git diff` oraz, jeśli powstał, `:WatchDiffHistory`. Nie używaj `<leader>ch` przed review.

#### Writer i integracja z watchdiff

Writer ponownie czyta i synchronicznie przepisuje cały plik. Nie ma atomowego compare-and-swap ani locka między kontrolą a zapisem. Używa tekstowych `readfile()`/`writefile()`, więc może przy okazji zamienić CRLF na LF, usunąć UTF-8 BOM i dodać końcowy newline. Hash obejmuje znormalizowaną treść linii, a nie reprezentację bajtową, więc nie wykrywa tych zmian; automatyczne komentarze są najbezpieczniejsze w zwykłych plikach LF bez BOM. Przed zapisem writer oznacza następną zmianę w watchdiff, ale historia `source=claude.nvim` powstaje tylko wtedy, gdy watcher działa, widzi ścieżkę, bufor jest czysty, reload się powiedzie, plik mieści się w limicie i diff jest niepusty. To warunkowa adnotacja, nie dowód autorstwa.

Jeżeli watchdiff jest załadowany, ale nie zobaczy eventu, writer nie zawsze wykonuje własny fallback `checktime`; bufor może pozostać chwilowo nieaktualny mimo komunikatu sukcesu. Porównaj dysk i bufor przed kolejną edycją.

#### Tryb deweloperski

Autocmd repo ładuje go raz po wejściu do `*/claude.nvim/lua/*.lua`.

| Klawisz | Działanie | Stan |
|---|---|---|
| `<leader>rr` | Reload modułów i ponowny setup | **Kontekstowe** |
| `<leader>rt` | Reload i natychmiastowy popup | **Kontekstowe** |
| `<leader>rd` | Debug lista modułów | **Kontekstowe** |

Po aktywacji mapowania deweloperskie są globalne do końca sesji, nie tylko buffer-local. Służą do rozwijania samej wtyczki.

**Wymagania:** zainstalowane i uwierzytelnione CLI `claude`, dostęp do backendu oraz `volt` dla preferowanego drawera. Bez Volt pozostaje scratch fallback.

**Diagnostyka:** `:echo executable('claude')`, ręczne logowanie/wywołanie `claude`, `:messages`, `:verbose nmap <leader>ac`, stan `modified`, `changedtick`, readable source i `commentstring`. Brak wsparcia drawera albo jego zwrot `false` przechodzi do scratch, ale wyjątek podczas tworzenia drawera może przerwać operację bez fallbacku; sprawdź wtedy Volt w `:Lazy`.

**Źródła lokalne:** [README](claude.nvim/README.md), [architektura](claude.nvim/ARCHITECTURE.md), [budowa promptu](claude.nvim/lua/claude/request.lua), [cykl żądania](claude.nvim/lua/claude/controller.lua), [kontrole komentarzy](claude.nvim/lua/claude/comments.lua), [writer](claude.nvim/lua/claude/writer.lua), [drawer](claude.nvim/lua/claude/output_drawer.lua).

</details>

<a id="wymagania"></a>
## Wymagania i środowisko

### Wersje bazowe sprawdzone lokalnie

| Składnik | Wersja/stan | Dlaczego ma znaczenie |
|---|---|---|
| macOS + WezTerm | konfiguracja repo dla WezTerm | True color, synchronized output i extended keys CSI-u |
| Neovim | `v0.12.4`, LuaJIT | nowe API LSP i gałąź `main` nvim-treesitter |
| tmux | `3.6a` | tabela defaultów tmux w tym przewodniku odpowiada tej wersji |
| zsh + Oh My Zsh | shell użytkownika | ładuje `PATH`, NVM i wyłącza XON/XOFF |
| WezTerm keybindings | mapowania `Cmd` w `wezterm.lua` | fizyczne `Cmd-h/j/k/l/q`, `Cmd-\`, `Cmd--` i `Cmd-n` do kodów terminalowych |
| Nerd Font Symbols | dołączone do WezTerm jako fallback | poprawne ikony NvChad, drzewa, Git, DAP i Markdown |

### Instalacja warstw

1. W katalogu repo uruchom `brew bundle --file Brewfile`. Deklarowane są: Neovim, tree-sitter-cli, tmux, fzf, fd, ripgrep, jq, stylua, ruff i WezTerm.
2. Zainstaluj NVM oraz domyślne Node LTS zgodnie z `README.md`; Node uruchamia część serwerów Mason i adapter JS/TS.
3. Utwórz dowiązania przez `bash install.sh install` i sprawdź je przez `bash install.sh status`. Instalator wykonuje timestampowane backupy zastępowanych celów.
4. Sklonuj TPM do `~/.tmux/plugins/tpm`, wczytaj konfigurację przez `tmux source-file "$HOME/.tmux.conf"`, a wewnątrz tmux naciśnij `Ctrl-s I`.
5. Odtwórz wtyczki Neovim dokładnie z lockfile przez `nvim --headless "+Lazy! restore" +qa`.
6. Zainstaluj narzędzia Mason: `lua-language-server pyright ruff typescript-language-server html-lsp css-lsp dockerfile-language-server docker-compose-language-service stylua mypy debugpy delve js-debug-adapter`.
7. Dla Claude opcjonalnie zainstaluj `@anthropic-ai/claude-code` i wykonaj pierwsze logowanie poleceniem `claude`.
8. Dla Distant zapewnij lokalne `~/.local/bin/distant`. Skonfigurowany przepływ `DistantLaunch` wymaga także `/home/ukibbb/.local/bin/distant` na hoście; bezpośredni `DistantConnect ssh://...` może nie wymagać zdalnej instalacji. Używane binaria powinny należeć do zgodnej linii 0.20.x.

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
| Distant | `ssh`, lokalny `distant`; zdalny `distant` dla skonfigurowanego Launch |
| vim-tmux-navigator | Bash, `ps`, `grep`, tmux i Neovim/Vim |
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

Wszystkie poniższe lokalne katalogi w `~/.local/share/nvim/lazy` miały `HEAD` równy lockfile podczas weryfikacji 9 sierpnia 2026. Nazwa w pierwszej kolumnie jest zarazem nazwą katalogu instalacji Lazy.

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
| `watchdiff.nvim` | `watchdiff.nvim/` | `dir = dotfiles_dir .. "/watchdiff.nvim"` | brak |
| `claude.nvim` | `claude.nvim/` | `dir = dotfiles_dir .. "/claude.nvim"` | brak |

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
4. Gdy zniknęły kolory UI, wykonaj `:lua require("base46").load_all_highlights()`; funkcja ładuje wynik od razu. Restart służy dopiero do sprawdzenia czystego startu.
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

### Tmux, WezTerm i kod klawisza

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
6. Gdy `.vscode/launch.json` nie daje konfiguracji, sprawdź `:pwd`, dokładną ścieżkę `${cwd}/.vscode/launch.json`, poprawny JSON i `type` odpowiadający zarejestrowanemu adapterowi. Provider launch.json nie filtruje wpisów według bieżącego filetype.

### Distant

1. Wykonaj `:DistantClientVersion`, `:DistantCheckHealth` i `:DistantSystemInfo`.
2. Sprawdź `:echo executable(expand('~/.local/bin/distant'))` oraz ręczne SSH do celu.
3. Przy timeout sprawdź host i użytkownika; dla Launch także zdalną ścieżkę executable oraz limit 60 s.
4. Obecny pusty wpis `lsp['*']` nie uruchamia remote LSP. Najpierw skonfiguruj realne `cmd` i `root_dir`, potem sprawdź executable na hoście zdalnym.
5. `:DistantSessionInfo` pokazuje globalne Connections. Przed zapisem/usunięciem porównaj active connection z `:lua =vim.b.distant` bieżącego remote buffer.

### watchdiff i Claude

| Objaw | Kontrola |
|---|---|
| brak zewnętrznego diffu | sprawdź, czy plik jest otwartym buforem, CWD obejmuje plik, wzorzec nie jest ignorowany i bufor był czysty |
| konflikt z niezapisanym buforem | najpierw skopiuj/zapisz potrzebną treść; nie wybieraj odruchowo `:e!` |
| historia jest pusta | historia nie jest trwała i zaczyna się dopiero po zdarzeniach w bieżącej sesji |
| popup Claude nie startuje | `:echo executable('claude')`, `:messages`, potem ręczne `claude` w powłoce |
| drawer Volt zawodzi | brak wsparcia lub zwrot `false` daje scratch; wyjątek runtime może przerwać bez fallbacku, więc sprawdź `:messages` i `volt` w Lazy |
| komentarz nie został zapisany od razu | kontrolowana odmowa bezpieczeństwa daje drawer; `E484` może oznaczać brakujący lub nieczytelny plik źródłowy |

### Gdzie pytać o mapowanie

- Neovim: `:map`, `:nmap`, `:imap`, `:xmap`, `:smap`, a dla źródła definicji `:verbose {tryb}map {klawisz}`.
- Lazy: `:Lazy help`, a potem `?` w UI konkretnej rewizji.
- Panel wtyczki: najpierw `g?` albo `?`, jeśli dana sekcja ten klawisz dokumentuje.
- Tmux: `prefix ?` lub `tmux list-keys`; pamiętaj o osobnych tabelach root, prefix i copy-mode-vi.
- Polecenia: `:help :commands`, `:command`, `:verbose command {nazwa}`; nazwa funkcji Lua z README nie oznacza automatycznie polecenia Ex.
