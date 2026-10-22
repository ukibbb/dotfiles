<a id="aktywne-mapowania-neovim"></a>
# Aktywne mapowania Neovim

## Podstawy, ruch i edycja

- **`jk`**: Wyjście do Normal. **Tryb:** `i`.
- **`Ctrl-b`**: Pierwszy niepusty znak wiersza. **Tryb:** `i`.
- **`Ctrl-e`**: Koniec wiersza. **Tryb:** `i`.
- **`Ctrl-h/j/k/l`**: Lewo / dół / góra / prawo. **Tryb:** `i`.
- **fizyczne `Cmd-\`, `<M-C-\>`**: Nowy pionowy podział, okna obok siebie. **Tryb:** `n`.
- **fizyczne `Cmd--`, `<M-C-_>`**: Nowy poziomy podział, okna góra/dół. **Tryb:** `n`.
- **`Esc`**: Wyłączenie podświetlenia wyszukiwania. **Tryb:** `n`.
- **`<leader>h`**: Ustawienie dosłownego wzorca wyszukiwania z zaznaczenia i podświetlenie wszystkich wystąpień. **Tryb:** `x`.
- **`;`**: Wejście do linii poleceń `:`; zastępuje powtórzenie ruchu `f/t`. **Tryb:** `n`.
- **`Ctrl-c`**: Kopia całego pliku do rejestru systemowego `+`. **Tryb:** `n`.
- **`Ctrl-a`**: Zaznaczenie całego pliku. **Tryb:** `n`.
- **`J` / `K`**: Przesunięcie zaznaczonych wierszy w dół / górę i ponowne wcięcie. **Tryb:** `v`.
- **`J`**: Połączenie wierszy bez przesuwania kursora; pozycja jest zachowywana przez API, więc skrót nie tworzy ani nie przenosi marki `z`. **Tryb:** `n`.
- **`Ctrl-d` / `Ctrl-u`**: Pół strony w dół / górę i wycentrowanie. **Tryb:** `n`.
- **`n` / `N`**: Następny / poprzedni wynik, wycentrowany i odsłonięty z folda. **Tryb:** `n`.
- **`p`**: Wklejenie nad zaznaczenie bez nadpisania rejestru wklejanego tekstu. **Tryb:** `x`.
- **`<leader>n`**: Przełączenie numerów bezwzględnych. **Tryb:** `n`.
- **`<leader>rn`**: Przełączenie numerów względnych. **Tryb:** `n`.
- **`<leader>w`**: Przełączenie zawijania wierszy. **Tryb:** `n`.
- **`<leader>y`**: Kopia całego pliku do schowka systemowego. **Tryb:** `n`.
- **`<leader>/`**: Komentarz bieżącego wiersza przez wbudowane `gcc`. **Tryb:** `n`.
- **`<leader>/`**: Komentarz zaznaczenia przez wbudowane `gc`. **Tryb:** `v`.

Mapowanie `v` jest zainstalowane także w Select. Wbudowany operator komentarza Neovim ma właściwe mapowanie w `n`, `x` i `o`, dlatego komentarz zaznaczenia należy praktycznie uruchamiać z Visual.

## Bufory, formatowanie i listy

- **`<leader>b`**: Nowy pusty bufor. **Tryb:** `n`. Działa, bo NvChad tabufline jest włączone.
- **fizyczne `Cmd-h`, `<M-C-H>`**: Poprzedni bufor tabufline. **Tryb:** `n`. Zależy od tabufline.
- **fizyczne `Cmd-l`, `<M-C-L>`**: Następny bufor tabufline. **Tryb:** `n`. Zależy od tabufline.
- **fizyczne `Cmd-q`, `<M-C-Q>`**: Zamknięcie bieżącego bufora tabufline. **Tryb:** `n`. Zależy od tabufline.
- **`<leader>fm`**: Format całego pliku lub zakresu przez Conform, z fallbackiem LSP. **Tryb:** `n,x`.
- **`<leader>ds`**: Diagnostyka do location list. **Tryb:** `n`.
- **`[d` / `]d`**: Poprzednia / następna diagnostyka i wsparcie licznikami. **Tryb:** `n`. Wbudowane w Neovim 0.12.
- **`<leader>dd`**: Pływający opis diagnostyki. **Tryb:** `n`.
- **`<leader>q`**: Diagnostyka do location list, to samo przeznaczenie co `<leader>ds`. **Tryb:** `n`.
- **`[q` / `]q`**: Poprzedni / następny wpis quickfix i wycentrowanie. **Tryb:** `n`.

## Telescope i wybór motywu

Przed pickerami dwa globalne launchery obsługują drzewo plików:

- **`<leader>e`**: Przełącz nvim-tree. **Tryb:** `n`.
- **`<leader>E`**: Otwórz nvim-tree i odsłoń bieżący plik. **Tryb:** `n`.

- **`<leader>ff`**: Pliki, z dotfiles, z poszanowaniem ignore.
- **`<leader>fa`**: Wszystkie pliki: hidden, ignored i symlinki.
- **`<leader>fw`**: `live_grep`, także pliki ukryte, bez wnętrza `.git/`.
- **`<leader>fW`**: `live_grep` z tekstem początkowym równym słowu pod kursorem.
- **`<leader>fb`**: Otwarte bufory.
- **`<leader>fh`**: Tagi pomocy.
- **`<leader>ma`**: Picker `:Telescope marks` dla natywnych marek Neovim; nie pokazuje bookmarków `marks.nvim`. **Tryb:** `n`.
- **`<leader>fo`**: Ostatnio otwarte pliki.
- **`<leader>fz`**: Wyszukiwanie w bieżącym buforze.
- **`<leader>fZ`**: Wyszukiwanie w buforze ze słowem pod kursorem.
- **`<leader>cm`**: Historia commitów katalogu.
- **`<leader>gt`**: Status Git; `Tab` w tym pickerze stage/unstage.
- **`<leader>th`**: Picker motywów NvChad.

W każdym pickerze lokalne `Alt-j` / `Alt-k` poruszają wyborem w Insert, a `q` zamyka picker w Normal.

## Wayfinder

- **`<leader>Wf`**: Otwórz Wayfinder dla symbolu pod kursorem albo bieżącego pliku. **Tryb:** `n`.
- **`<leader>Wn`**: Otwórz następny poprawny element roboczego Trail, z zawijaniem i pomijaniem brakujących plików. **Tryb:** `n`.
- **`<leader>Wp`**: Otwórz poprzedni poprawny element roboczego Trail. **Tryb:** `n`.
- **`<leader>Wo`**: Otwórz bieżący poprawny element roboczego Trail. **Tryb:** `n`.
- **`<leader>Ws`**: Otwórz Wayfinder bezpośrednio na fasecie `Trail`; nie wykonuje automatycznie resume zapisu po restarcie. **Tryb:** `n`.

Wielkie `W` jest częścią skrótów. Pełna mapa trzech paneli, Explore, filtra, Trail, zapisów i quickfix znajduje się w [tutorialu Wayfinder](plugins/13-wayfinder.md#plugin-wayfinder).

## Natywne marki i `marks.nvim`

Wszystkie poniższe mapowania są aktywnymi defaultami `marks.nvim` w trybie Normal. Operacje na literach kończą się prawdziwą marką Neovim; bookmarki cyfr są osobnymi, sesyjnymi extmarkami wtyczki.

- **`m{a-z}` / `m{A-Z}`**: Ustaw natywną markę lokalną / globalną. Obsługiwane są też specjalne nazwy `.`, `^`, `'`, `` ` ``, `"`, `<` i `>`; dokładne `m[` / `m]` oraz `m0`-`m9` mają opisane niżej znaczenie wtyczki.
- **`m,`**: Ustaw najniższą wolną markę `a`-`z` w bieżącym buforze.
- **`m;`**: Ustaw następną wolną małą markę, gdy wiersz nie ma śledzonej marki; w przeciwnym razie usuń wszystkie śledzone natywne marki tego wiersza.
- **`dm{znak}`**: Usuń wskazaną zarejestrowaną literę albo obsługiwaną markę specjalną; wariant wielkoliterowy działa z cache bieżącego bufora.
- **`dm-`**: Usuń wszystkie śledzone natywne marki bieżącego wiersza.
- **`dm<Space>`**: Wykonaj `:delmarks!` dla bieżącego bufora i wyczyść jego cache oraz znaki. Czyści też changelistę; nie usuwa globalnie `A`-`Z` ani `0`-`9`.
- **`m]` / `m[`**: Następna / poprzednia literowa marka według położenia w bieżącym buforze, z cyklicznym zawijaniem. Nie jest to natywne ustawianie marek specjalnych `]` / `[`.
- **`m:`**: Zapytaj o nazwę marki i otwórz fokusowany, edytowalny podgląd w nowym floacie; zamknij go przez `:close`.
- **`m0`-`m9`**: Dodaj bookmark odpowiedniej grupy w bieżącym wierszu. Nie ustawia to natywnej marki numerowanej.
- **`dm0`-`dm9`**: Usuń całą odpowiednią grupę bookmarków ze wszystkich buforów.
- **`m}` / `m{`**: Z bookmarka dokładnie pod kursorem przejdź do następnego / poprzedniego bookmarka tej samej grupy, także w innym buforze.
- **`dm=`**: Usuń jeden bookmark pod kursorem; przy kilku grupach na tym samym wierszu wybór grupy nie jest gwarantowany.

`<leader>ma` pozostaje niezależnym pickerem Telescope dla natywnych marek, a nie interfejsem bookmarków. Polecenia list, quickfix, znaki, trwałość ShaDa i komplet ograniczeń są opisane w [tutorialu marek](plugins/14-marks.md#plugin-marks).

## Bazy danych

- **`<leader>Bd`**: Przełącz czteropanelowy workspace DBee. **Tryb:** `n`.
- **`<leader>Bo`**: Otwórz manager połączeń Dbout w Telescope. **Tryb:** `n`.
- **`<leader>Bu`**: Przełącz drawer Dadbod UI. **Tryb:** `n`.
- **`<leader>Bg`**: Otwórz picker połączeń Dadbod Grip. **Tryb:** `n`.
- **`<leader>Bs`**: Zapisz tymczasowy query utworzony przez DBUI. **Tryb/kontekst:** `n`, bufor DBUI `sql`, `mysql` albo `plsql` z dostępną akcją save.
- **`<leader>Bp`**: Edytuj bind parameters query DBUI. **Tryb/kontekst:** `n`, bufor SQL faktycznie przypisany do DBUI.
- **`F6`**: Wykonaj cały bufor albo wizualny zakres pełnych wierszy. **Tryb/kontekst:** `n,i,v`, tylko Queryer Dbout.
- **`F7`**: Sformatuj cały bufor albo wizualny zakres pełnych wierszy i zastąp wskazany tekst wynikiem formattera. **Tryb/kontekst:** `n,i,v`, tylko Queryer Dbout.
- **`F8`**: Przełącz Inspector powiązany z aktywnym Queryerem. **Tryb/kontekst:** `n,i`, Queryer, Inspector albo Viewer Dbout.
- **`F9`**: Przełącz Viewer powiązany z aktywnym Queryerem. **Tryb/kontekst:** `n,i`, Queryer, Inspector albo Viewer Dbout.

`F6` i `F7` nie wybierają instrukcji pod kursorem, a Visual ogranicza wiersze, nie kolumny. Surowy Dadbod jest dostępny przez `:DB` bez globalnego klawisza. `g:db_ui_disable_mappings_sql=1` wyłącza upstreamowe DBUI `<leader>W`, `<leader>S` i `<leader>E`, dzięki czemu nie kolidują z Wayfinderem. `Bs` i `Bp` są dodawane tylko po rozpoznaniu `b:dbui_db_key_name`; zapis `:write` nadal wykonuje query DBUI.

Grip ma własne mapowania buforowe: `Ctrl-p` otwiera palette, `1`/`2`/`3` przechodzi między sidebarem, query padem i gridem, `Ctrl-Enter` wykonuje query, `a` stosuje obejrzane zmiany, `u` je wycofuje, a `?` pokazuje pomoc. Pełne mapy zawierają [tutorial DBee](plugins/11-nvim-dbee.md#plugin-nvim-dbee), [tutorial Dbout](plugins/12-dbout.md#plugin-dbout), [tutorial Dadbod/DBUI](plugins/15-vim-dadbod.md#plugin-vim-dadbod) i [tutorial Grip](plugins/16-dadbod-grip.md#plugin-dadbod-grip).

## Git i przegląd różnic

- **`<leader>gd`**: Otwarcie lub odświeżenie inline diff `Unified` względem `HEAD`; drzewo automatycznie otwiera pierwszy zmieniony plik, a `:Unified reset` czyści bieżący bufor.
- **`<leader>gg`**: Status Neogit w nowej karcie.
- **`<leader>gc`**: Popup commit Neogit.
- **`<leader>gp`**: Popup push Neogit.
- **`<leader>gP`**: Popup pull Neogit.
- **`<leader>gb`**: Popup branch Neogit.
- **`<leader>gv`**: `DiffviewOpen` dla zmian roboczych.
- **`<leader>gm`**: Porównanie `origin/main...HEAD` w Diffview.
- **`<leader>gl`**: Historia bieżącego pliku w Diffview.
- **`<leader>gL`**: Historia całego repozytorium w Diffview.
- **`<leader>gq`**: Zamknięcie aktywnego Diffview.
- **`<leader>gD`**: Explorer CodeDiff.
- **`<leader>gf`**: Dokładnie `CodeDiff file HEAD`, bieżący zapisany plik kontra `HEAD`.
- **`<leader>gh`**: Dokładnie `CodeDiff history %`, historia bieżącego pliku.

## DAP

- **`F5`**: Start albo kontynuacja. **Tryb:** `n`.
- **`F10`**: Krok ponad. **Tryb:** `n`.
- **`F11`**: Krok do środka. **Tryb:** `n`.
- **`F12`**: Krok na zewnątrz. **Tryb:** `n`.
- **`<leader>db`**: Przełączenie breakpointu. **Tryb:** `n`.
- **`<leader>dB`**: Breakpoint warunkowy po wpisaniu warunku. **Tryb:** `n`.
- **`<leader>dc`**: Start albo kontynuacja. **Tryb:** `n`.
- **`<leader>de`**: Ewaluacja wyrażenia lub zaznaczenia w UI. **Tryb:** `n,x`.
- **`<leader>dn`**: Najbliższy test Python albo Go; dla innych filetype ostrzeżenie. **Tryb:** `n`.
- **`<leader>dp`**: Pauza. **Tryb:** `n`.
- **`<leader>dl`**: Ponowne uruchomienie ostatniej konfiguracji. **Tryb:** `n`.
- **`<leader>dr`**: REPL. **Tryb:** `n`.
- **`<leader>dt`**: Zakończenie sesji. **Tryb:** `n`.
- **`<leader>du`**: Przełączenie paneli DAP UI. **Tryb:** `n`.

## LSP po podłączeniu klienta

- **`gD`**: Deklaracja. **Tryb:** `n`. Gdy działa LSP.
- **`gd`**: Definicja. **Tryb:** `n`. Gdy działa LSP.
- **`<leader>ca`**: Akcja kodu/refaktoryzacja dla pozycji lub zakresu. **Tryb:** `n,x`. Gdy działa LSP.
- **`<leader>lr`**: Wbudowane `:lsp restart` dla klientów bieżącego bufora. **Tryb:** `n`. Gdy działa LSP; Neovim 0.12.
- **`gr`**: Referencje w Telescope. **Tryb:** `n`. Gdy działa LSP.
- **`<leader>wa` / `<leader>wr`**: Dodanie / usunięcie folderu workspace. **Tryb:** `n`. Gdy działa LSP.
- **`<leader>wl`**: Wypisanie folderów workspace. **Tryb:** `n`. Gdy działa LSP.
- **`<leader>D`**: Definicja typu. **Tryb:** `n`. Gdy działa LSP.
- **`<leader>ra`**: Zmiana nazwy przez UI NvChad. **Tryb:** `n`. Gdy działa LSP.
- **`gS`**: Źródłowa definicja TypeScript zamiast deklaracji typów. **Tryb:** `n`. Tylko TypeScript (`ts_ls`).
- **`<leader>ci`**: Akcje źródłowe TypeScript, np. organizacja importów i usunięcie nieużywanego kodu. **Tryb:** `n`. Tylko TypeScript (`ts_ls`).

Wbudowane globalne skróty Neovim 0.12 pozostają dostępne: `grn` rename, `gra` w `n,x` code action, `gri` implementation, `grr` references, `grt` type definition, `grx` code lens, `gO` symbole dokumentu, `gx` link dokumentu, `an`/`in` wybór węzła oraz `Ctrl-s` w `i,s` pomoc sygnatur. Po attach `K` pokazuje hover, o ile `keywordprg` lub własne mapowanie go nie zastąpiło. `[D` / `]D` skaczą do pierwszej / ostatniej diagnostyki, a `Ctrl-w d` i `Ctrl-w Ctrl-d` otwierają jej opis.

## `nvim-cmp`: dokładne tryby

- **`Ctrl-p` / `Alt-k`**: Poprzednia propozycja. **Tryb:** `i`.
- **`Ctrl-n` / `Alt-j`**: Następna propozycja. **Tryb:** `i`.
- **`Ctrl-d` / `Ctrl-f`**: Dokumentacja o 4 wiersze w górę / w dół. **Tryb:** `i`.
- **`Ctrl-Spacja`**: Ręczne otwarcie completion. **Tryb:** `i`.
- **`Ctrl-e`**: Zamknięcie menu completion. **Tryb:** `i`.
- **`Enter`**: Potwierdzenie; `select=true` wybiera pierwszy element także bez jawnego zaznaczenia. **Tryb:** `i`.
- **`Tab`**: Następna propozycja, inaczej rozwinięcie/skok LuaSnip, inaczej zwykły fallback. **Tryb:** `i,s`.
- **`Shift-Tab`**: Poprzednia propozycja, inaczej poprzedni placeholder LuaSnip, inaczej fallback. **Tryb:** `i,s`.

Wszystkie pozycje poza `Tab` i `Shift-Tab` są tylko w Insert. Brak jawnej listy trybów w API `cmp.mapping` domyślnie oznacza `i`, nie `i,s`.

## Distant, Markdown i lokalne wtyczki

- **`<leader>rl`**: Prompt celu SSH i `DistantLaunch`. **Tryb/kontekst:** `n`.
- **`<leader>ro`**: Prefiks linii `:DistantOpen ` do dopisania ścieżki. **Tryb/kontekst:** `n`.
- **`<leader>rs`**: Powłoka zdalna. **Tryb/kontekst:** `n`.
- **`<leader>rx`**: Prefiks linii `:DistantSpawn ` do dopisania polecenia. **Tryb/kontekst:** `n`.
- **`<leader>rp`**: Połączenie `ssh://ukibbb@192.168.101.7`. **Tryb/kontekst:** `n`.
- **`<leader>mr`**: `RenderMarkdown buf_toggle` dla bieżącego bufora. **Tryb/kontekst:** `n`, tylko Markdown.
- **`<leader>ch`**: Usunięcie podświetleń watchdiff i przesunięcie baseline. **Tryb/kontekst:** `n`.

## Mapowania kontekstowe z autocmdów i paneli

- **`q`**: `:close`, bufor poza listą. **Kontekst:** `help`, `qf`, `lspinfo`, `man`, `notify`, `spectre_panel`, `startuptime`, `checkhealth`.
- **fizyczne `Cmd-\` / `Cmd--`**: Otwórz w pionowym / poziomym splicie. **Kontekst:** bufor nvim-tree.
- **`q`**: Zamknięcie splitu historii. **Kontekst:** historia watchdiff.
- **`>` w Insert**: Wstawienie `>` i ewentualne domknięcie tagu. **Kontekst:** obsługiwany bufor tagów. Z nvim-ts-autotag.

Pełne mapowania paneli każdej wtyczki są dostępne w [indeksie wtyczek](plugins/README.md#indeks-wtyczek).
