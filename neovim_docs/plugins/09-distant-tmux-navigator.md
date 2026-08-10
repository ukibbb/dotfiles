# Distant i vim-tmux-navigator po stronie Neovim

<a id="plugin-distant"></a>
## `distant.nvim`

**Co robi i po co:** otwiera i zapisuje zdalne pliki przez lokalny klient i zdalny serwer Distant, zapewnia browser katalogów, shell, spawn, wyszukiwanie i podstawę dla zdalnego LSP.

**Ładowanie lokalne:** na `:DistantInstall`, `:DistantClientVersion`, `:DistantConnect`, `:DistantLaunch`, `:DistantOpen`, `:DistantShell`, `:DistantSpawn` albo lokalne `<leader>r...`. Po setup dostępne są wszystkie polecenia poniżej. `:Distant`, search, health i część poleceń pomocniczych nie są zimnymi triggerami Lazy; na świeżym starcie najpierw użyj jednego z wymienionych poleceń albo `:Lazy load distant.nvim`.

**Konfiguracja lokalna:** klient `~/.local/bin/distant`, manager bez daemona, timeout maksymalny 60 s. Domyślny launch na serwerze używa `/home/ukibbb/.local/bin/distant`. Klucz `servers.raspberry` jest nazwą hosta/profilu, natomiast pola `host` umieszczone w `connect.default` i `launch.default` nie są obsługiwane przez tę rewizję i są ignorowane. UI spróbuje hosta `raspberry`, chyba że SSH/DNS rozwiązuje ten alias. `<leader>rp` przekazuje IP bezpośrednio i korzysta z ustawień wildcard, nie z wpisu profilu.

**Stan zdalnego LSP:** `lsp = { ['*'] = {} }` nie ma semantyki wildcard; `'*'` jest tylko etykietą pustej konfiguracji. Brak `cmd` i `root_dir` oznacza, że żaden remote LSP nie startuje obecnie automatycznie.

**Aktywne lokalne:** `<leader>rl`, `<leader>ro`, `<leader>rs`, `<leader>rx`, `<leader>rp`.

**Polecenia przypiętej rewizji:** `:Distant` (główne UI), `:DistantCancelSearch`, `:DistantCheckHealth`, `:DistantClientVersion`, `:DistantConnect`, `:DistantCopy`, `:DistantInstall`, `:DistantLaunch`, `:DistantMetadata`, `:DistantMkdir`, `:DistantOpen`, `:DistantSearch`, `:DistantSessionInfo`, `:DistantShell`, `:DistantSpawn`, alias `:DistantRun`, `:DistantSystemInfo`, `:DistantRemove`, `:DistantRename`.

### Bufory zdalne i UI

- **`-`**: Otwórz katalog nadrzędny. **Kontekst:** zdalny plik. **Stan:** **Domyślne wtyczki**.
- **`Enter`**: Edytuj wpis. **Kontekst:** zdalny katalog. **Stan:** **Domyślne wtyczki**.
- **`Ctrl-t`**: Otwórz wpis w nowej karcie. **Kontekst:** zdalny katalog. **Stan:** **Domyślne wtyczki**.
- **`-`**: Katalog nadrzędny. **Kontekst:** zdalny katalog. **Stan:** **Domyślne wtyczki**.
- **`K`, `N`**: Nowy katalog / nowy plik. **Kontekst:** zdalny katalog. **Stan:** **Domyślne wtyczki**.
- **`R`, `D`, `M`, `C`**: Rename, remove, metadata, copy. **Kontekst:** zdalny katalog. **Stan:** **Domyślne wtyczki**.
- **`q` / `Esc`**: Zamknięcie. **Kontekst:** główne UI. **Stan:** **Domyślne wtyczki**.
- **`1`, `2`, `?`**: Connections, System Info, Help. **Kontekst:** główne UI. **Stan:** **Domyślne wtyczki**.
- **`R`**: Odświeżenie karty. **Kontekst:** główne UI. **Stan:** **Domyślne wtyczki**.
- **`Enter`**: Przełącz aktywne połączenie albo uruchom skonfigurowany host po potwierdzeniu. **Kontekst:** Connections. **Stan:** **Kontekstowe**.
- **`K`, `I`**: Zabij połączenie / przełącz informacje. **Kontekst:** Connections. **Stan:** **Kontekstowe**.

### Architektura połączenia

1. Lokalny CLI uruchamia managera i operacje sieciowe.
2. Manager utrzymuje wiele connection ID i jedno globalne aktywne połączenie.
3. Shell, spawn, search i bezpośrednie polecenia używają globalnie aktywnego connection ID.
4. Otwarty zdalny bufor zapamiętuje własne `b:distant.client_id`; zapis nadal używa jego połączenia nawet po przełączeniu globalnego active.
5. `:DistantSessionInfo` otwiera globalny widok Connections i nie dowodzi, z którym hostem związany jest bieżący bufor. Sprawdź `:lua =vim.b.distant`.

### Connect kontra Launch

- `DistantLaunch ssh://user@host` uruchamia na hoście skonfigurowany zdalny binarny Distant, a potem się łączy. Tego używa `<leader>rl` i `<leader>rp`, więc `/home/ukibbb/.local/bin/distant` musi istnieć.
- `DistantConnect ssh://user@host` może użyć backendu SSH bez osobnej instalacji zdalnego Distant. Lokalny klient pozostaje wymagany.
- Oba po sukcesie zmieniają globalnie aktywne połączenie. Otwarty wcześniej bufor zachowuje własny ID.

### Tutorial: połączenie, plik i katalog

1. Sprawdź `:DistantClientVersion`, potem uruchom `<leader>rl` i podaj pełne `ssh://user@host` albo użyj jawnego `:DistantConnect`.
2. Otwórz `:Distant` i sprawdź aktywny connection. `I` rozwija informacje; `K` po potwierdzeniu zabija połączenie, ale nie naprawia ani nie zamyka związanych z nim buforów.
3. `<leader>ro` uzupełnia `:DistantOpen `. Bez ścieżki polecenie otwiera zdalne `.`.
4. Istniejący plik staje się buforem `acwrite`; `:write` wysyła treść przez zapamiętane połączenie. Nieistniejąca ścieżka tworzy pusty bufor, a realny plik powstaje dopiero przy zapisie.
5. W katalogu `N` tworzy pusty plik/bufor, `K` katalog rekurencyjnie, `C` kopiuje zdalnie-do-zdalnie, `R` pyta o pełną ścieżkę docelową, a `M` pokazuje metadata.

### Usuwanie zdalne

`D` w browserze pyta `Yes / Force / No`, przy czym pierwszą zaznaczoną odpowiedzią może być Yes. Force pozwala usuwać niepusty katalog. Bezpośrednie `:DistantRemove` nie pyta, a bang wymusza. Operacja nie trafia do lokalnego kosza; przed zatwierdzeniem przeczytaj host i pełną ścieżkę.

### Tutorial: search, shell i spawn

1. Po załadowaniu użyj `:DistantSearch "regex" path=. target=contents`. Pierwszy argument jest regexem; wartości ze spacjami wymagają podwójnych cudzysłowów parsera wtyczki.
2. Wyniki napływają do quickfix, domyślnie stronicowane po 10; `[q`/`]q` nawiguje, a otwarcie wyniku ładuje remote buffer.
3. Tylko jedno wyszukiwanie edytora jest aktywne. Nowe anuluje stare; `:DistantCancelSearch` zatrzymuje bieżące.
4. `<leader>rs` otwiera interaktywny zdalny terminal w bieżącym oknie.
5. `<leader>rx` uzupełnia `:DistantSpawn `. Spawn uruchamia pojedyncze polecenie, czeka i drukuje stdout/stderr. Pipe, redirect i złożone wyrażenia wymagają jawnego uruchomienia zdalnego shella.
6. Shell i spawn używają globalnego active connection, niekoniecznie hosta bieżącego remote buffer.

### Zdalne zmiany i watchdiff

Distant ma własny watcher remote pliku. Czysty bufor może zostać przeładowany, a zmodyfikowany lokalnie prosi o decyzję. Bufory mają `buftype=acwrite`, dlatego lokalny watchdiff ich nie śledzi i nie zapisuje dla nich historii/provenance. Niektóre backendy SSH mogą nie wspierać watch capability.

### Jak naprawdę włączyć remote LSP

Potrzebna jest jawna etykieta z remote `cmd`, `root_dir` lub resolverem i ewentualnie `filetypes`. Distant uruchamia proces na hoście i tłumaczy URI. Lokalny Mason nie instaluje executable na serwerze. Obecny pusty wpis `'*'` nie spełnia tych warunków, więc diagnozowanie zaczyna się od poprawy konfiguracji, nie od restartu lokalnego LSP.

**Bezpieczeństwo:** `DistantRemove`/`D`, rename, copy, spawn i `K` w Connections zmieniają host zdalny. Globalny active i buforowy client ID mogą wskazywać różne hosty.

**Wymagania:** Neovim co najmniej 0.8, lokalny klient Distant 0.20.x zgodny z gałęzią v0.3 i SSH. Zdalny executable jest wymagany przez skonfigurowany Launch, ale nie przez każdy możliwy tryb Connect. Wtyczka jest oznaczona upstream jako alpha.

**Diagnostyka:** `:DistantClientVersion`, `:DistantCheckHealth`, `:DistantSystemInfo`, `:messages`, ręczne SSH, `:echo executable(expand('~/.local/bin/distant'))`, aktywny wpis w `:Distant` i `:lua =vim.b.distant`. Timeout sprawdzaj na właściwym hoście i ścieżce binarnej.

**Źródła przypiętej rewizji:** [README](https://github.com/chipsenkbeil/distant.nvim/blob/67d6b066e8490725718b79f643966f4eafc7da3c/README.md), [domyślna konfiguracja](https://github.com/chipsenkbeil/distant.nvim/blob/67d6b066e8490725718b79f643966f4eafc7da3c/lua/distant/default.lua), [remote LSP client](https://github.com/chipsenkbeil/distant.nvim/blob/67d6b066e8490725718b79f643966f4eafc7da3c/lua/distant-core/client.lua), [search](https://github.com/chipsenkbeil/distant.nvim/blob/67d6b066e8490725718b79f643966f4eafc7da3c/lua/distant/editor/search.lua).

<a id="plugin-vim-tmux-navigator"></a>
## `vim-tmux-navigator`

**Co robi i po co:** tworzy jedną siatkę nawigacji ze splitów Neovim i paneli tmux. Ładuje się natychmiast po obu stronach.

**Mapowania:** `Ctrl-h/j/k/l` oraz `Ctrl-\` w Normal Neovim i root tmux. W Terminal Neovim działają `Ctrl-h/j/k/l`, ale nie `Ctrl-\`; dla filetype `fzf` są przekazywane do terminala zamiast nawigować. Wtyczka tmux instaluje wszystkie pięć klawiszy w copy-mode-vi oraz `prefix Ctrl-l` do wysłania clear-screen. Lokalne mapowania Insert `Ctrl-h/j/k/l` mają pierwszeństwo w Neovim i poruszają kursorem.

**Polecenia:** `:TmuxNavigateLeft`, `:TmuxNavigateDown`, `:TmuxNavigateUp`, `:TmuxNavigateRight`, `:TmuxNavigatePrevious`, `:TmuxNavigatorProcessList`.

**Wymagania:** tmux co najmniej 1.8, Bash, `ps`, `grep` i wspólny plugin po obu stronach. Zagnieżdżony tmux wymaga świadomego `send-prefix` i nie ma pełnej automatycznej nawigacji między warstwami.

### Jak przebiega jeden klawisz

1. Zewnętrzny tmux odbiera `Ctrl-h/j/k/l` albo `Ctrl-\` w tabeli root.
2. Skrypt sprawdza przez `ps` procesy na TTY panelu i odrzuca stany stopped/dead/zombie.
3. Jeśli widzi Vim/Neovim/fzf, wysyła klawisz do aplikacji; w zwykłej powłoce od razu wykonuje `select-pane`.
4. Neovim próbuje `wincmd` wewnątrz bieżącej karty. Jeśli okno się zmieniło, kończy.
5. Na krawędzi Neovim wywołuje `tmux select-pane` dla własnego `$TMUX_PANE`.

Dlatego plugin musi istnieć po obu stronach, a wykrywanie nie opiera się wyłącznie na `pane_current_command`.

### Macierz trybów

- **Normal Neovim**: Nawigacja split/panel wszystkimi pięcioma klawiszami.
- **Insert Neovim**: Lokalne `Ctrl-h/j/k/l` porusza kursorem; nie opuszcza Neovim.
- **Terminal Neovim**: `Ctrl-h/j/k/l` nawiguje, `Ctrl-\` nie jest mapowane.
- **terminal filetype `fzf`**: Klawisze są przekazywane do fzf.
- **tmux copy-mode-vi**: Tmux bezpośrednio wybiera panel.
- **poza tmux**: Polecenia kierunkowe Neovim działają na splity; `TmuxNavigatorProcessList` może nie istnieć.
- **Visual/Select/Operator/Command-line**: Brak specjalnych mapowań navigatora.

### Tutorial: split do panelu i previous

1. Utwórz pionowy split Neovim oraz panel tmux po jego prawej stronie.
2. W Normal naciskaj `Ctrl-l`: najpierw zmieni split, potem przekroczy granicę tmux. `Ctrl-h` wróci.
3. `Ctrl-\` próbuje poprzedni split Neovim; gdy odpowiedni poprzedni split nie istnieje, przekazuje previous do tmux. Nie jest prostym globalnym MRU wszystkich warstw.
4. Nawigacja kierunkowa nie przełącza kart Neovim.

### Aktywne defaulty, które wpływają na zachowanie

- `save_on_switch=0`: przejście do tmux nie zapisuje pliku.
- Nawigacja jest dozwolona przy zoomie; wyjście przez krawędź zwykle odzoomowuje okno tmux.
- Preserve zoom i no-wrap nie są skonfigurowane. Na zewnętrznej krawędzi Vim/tmux może przejść na przeciwną stronę zależnie od układu.
- Opcjonalne `g:tmux_navigator_disable_when_zoomed`, `preserve_zoom`, `no_wrap` i `save_on_switch` są dostępne upstream, ale nieaktywne.

### Konflikty klawiszy

- Root `Ctrl-h` nie jest zwykłym terminalowym backspace.
- Root `Ctrl-l` nie czyści powłoki; użyj `Ctrl-s Ctrl-l`, bo plugin zachowuje clear-screen pod prefixem.
- Root `Ctrl-\` nie wysyła SIGQUIT do procesu i konfiguracja nie dodaje osobnego zamiennika.
- W Insert lokalny `Ctrl-h` jest ruchem w lewo, więc kasowanie pozostaje pod Backspace.

### Diagnostyka

1. `:verbose nmap <C-h>` i `:verbose tmap <C-h>` pokazuje stronę Neovim.
2. `:TmuxNavigatorProcessList` wypisuje wynik detekcji procesów panelu.
3. `tmux list-keys -T root` i `tmux list-keys -T copy-mode-vi` pokazują stronę tmux.
4. Sprawdź `$TMUX`, `$TMUX_PANE`, zoom oraz `ps -o state= -o comm= -t "$(tmux display -p '#{pane_tty}')"`.
5. Wrappery, Docker TTY, SSH, nested tmux i nietypowy `ps` mogą oszukać detekcję. fzf jest celowo częścią wzorca.

**Źródła przypiętej rewizji:** [README i konfiguracja](https://github.com/christoomey/vim-tmux-navigator/blob/c45243dc1f32ac6bcf6068e5300f3b2b237e576a/README.md), [help](https://github.com/christoomey/vim-tmux-navigator/blob/c45243dc1f32ac6bcf6068e5300f3b2b237e576a/doc/tmux-navigator.txt), [kod Neovim/Vim](https://github.com/christoomey/vim-tmux-navigator/blob/c45243dc1f32ac6bcf6068e5300f3b2b237e576a/plugin/tmux_navigator.vim), [kod tmux](https://github.com/christoomey/vim-tmux-navigator/blob/c45243dc1f32ac6bcf6068e5300f3b2b237e576a/vim-tmux-navigator.tmux).
