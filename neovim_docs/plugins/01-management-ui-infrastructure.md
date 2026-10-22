# Zarządzanie, UI i infrastruktura

<a id="plugin-lazy-nvim"></a>
## `lazy.nvim`

Menedżer wtyczek. Ładuje wtyczki na żądanie (`event`, `ft`, `cmd`, `keys`), brakujące instaluje automatycznie na commitach z `nvim/lazy-lock.json`. Automatyczne sprawdzanie aktualizacji jest wyłączone.

- **`:Lazy`**: panel wtyczek; `?` pokazuje wszystkie klawisze panelu.
- **`:Lazy check [nazwa]`**: pobiera i pokazuje dostępne zmiany, niczego nie zmienia.
- **`:Lazy update [nazwa]`**: aktualizuje i zapisuje nowe commity do lockfile.
- **`:Lazy restore [nazwa]`**: ustawia wtyczki dokładnie wg lockfile (do odtworzenia repo na nowej maszynie; `:Lazy! restore` czeka na koniec).
- **`:Lazy clean`**: usuwa wtyczki nieobecne w specyfikacji.
- **`:Lazy profile`**: koszt startu; **`:Lazy log [nazwa]`**: ostatnie zmiany.
- W panelu: **`Enter`** szczegóły, **`d`** diff, **`u`/`U`** update wskazanej/wszystkich, **`r`/`R`** restore, **`q`** zamknij.

Bezpieczna aktualizacja jednej wtyczki:

1. `:Lazy check nazwa`, przejrzyj log.
2. `:Lazy update nazwa` (nie globalne `sync`), restart, test.
3. `git diff -- nvim/lazy-lock.json` i świadomie zacommituj nowy hash.
4. Przy regresji: `:Lazy! restore nazwa` i restart.

Uwaga: `sync` = install + clean + update, więc nie służy do wiernego odtworzenia stanu repo — do tego jest `restore`. W widoku profilu `Ctrl-s` (sortowanie) w WezTerm wymaga `Ctrl-s Ctrl-s`.

<a id="plugin-ui"></a>
## `ui`

`nvchad/ui`: statusline, tabufline (lista buforów u góry), renamer LSP, picker motywów, dashboard i cheatsheet. Motyw ustawiony w `chadrc.lua` to `ayu_dark`.

- **`<leader>th`**: picker motywów; filtruj wpisując, `Ctrl-n`/`Ctrl-p` (lub `j`/`k` w Normal), `Enter` zapisuje wybór do `nvim/lua/chadrc.lua`.
- **`<leader>ra`**: rename symbolu przez LSP (tylko gdy LSP jest podłączony); `Enter` zatwierdza, `Esc` anuluje.
- **`Cmd-h` / `Cmd-l`**: poprzedni / następny bufor w tabufline.
- **`Cmd-q`**: zamknij bieżący bufor.
- **`<leader>b`**: nowy pusty bufor.
- **`:Nvdash`**: dashboard (nie jest ekranem startowym).
- **`:NvCheatsheet`**: lista mapowań z opisami; `q`/`Esc` zamyka.

Uwagi:

- Tabufline pojawia się dopiero przy co najmniej dwóch buforach.
- Rename może zmienić wiele plików — zapisz je i obejrzyj `git diff`.
- Kody `#RRGGBB` w plikach dostają kolorową próbkę (colorify).

<a id="plugin-base46"></a>
## `base46`

Silnik motywów NvChad: kompiluje highlighty do cache, z którego korzysta UI. Nie ma własnych mapowań; motyw zmieniasz przez `<leader>th`.

- **`:Inspect`**: jaka grupa highlight jest pod kursorem.
- Rozjechane lub brakujące kolory (np. po usunięciu cache): `:Lazy build base46` albo `:lua require("base46").load_all_highlights()`.

<a id="plugin-volt"></a>
## `volt`

Biblioteka okien UI używana przez Minty i picker motywów. Nie otwierasz jej bezpośrednio. W oknach na niej opartych (np. `:Huefy`):

- **`Tab` / `Shift-Tab`**: następny / poprzedni element klikalny.
- **`Enter`**: uruchom element pod kursorem.
- **`Ctrl-t`**: przełącz okno składowe.
- **`q` / `Esc`**: zamknij (w Normal).

<a id="plugin-menu"></a>
## `menu`

Biblioteka menu kontekstowych na Volt. Instalowana jako zależność; w tej konfiguracji nie ma żadnego skrótu, który ją otwiera (`RightMouse` z README nie jest ustawione).

<a id="plugin-minty"></a>
## `minty`

Narzędzia do kolorów: `:Huefy` (color picker) i `:Shades` (generator odcieni). Ładuje się dopiero po poleceniu.

- **`:Huefy`** / **`:Shades`**: otwórz dla koloru `#RRGGBB` pod kursorem.
- **`Tab` / `Shift-Tab`, `Enter`**: wybór elementu; **`h` / `l`**: ruch suwaka.
- **`Ctrl-s`**: zastosuj kolor w oryginalnej linii i zamknij — w WezTerm wciśnij `Ctrl-s Ctrl-s`.
- **`q` / `Esc`**: zamknij bez zmian.

Jak używać:

1. Ustaw kursor na `#RRGGBB` i wpisz `:Huefy`.
2. Dobierz kolor, zatwierdź `Ctrl-s Ctrl-s` (lub przycisk Save).
3. Kolor zostaje podmieniony w tej linii (nie trafia do schowka); pomyłkę cofasz `u`.

<a id="plugin-nvim-web-devicons"></a>
## `nvim-web-devicons`

Ikony plików dla statusline, tabufline, nvim-tree i Telescope. Kwadraty zamiast ikon oznaczają brak Nerd Font w terminalu. Podgląd ikon i kolorów: `:NvimWebDeviconsHiTest`.

<a id="plugin-plenary-nvim"></a>
## `plenary.nvim`

Biblioteka pomocnicza (procesy, ścieżki, async) dla Telescope, Neogit i NvChad UI. Nie używasz jej bezpośrednio.

<a id="plugin-nui-nvim"></a>
## `nui.nvim`

Biblioteka komponentów UI dla CodeDiff (`<leader>gD`, `<leader>gh`). Brak własnych poleceń. Przy błędzie `module 'nui.tree' not found`: `:Lazy! restore nui.nvim` i restart.

<a id="plugin-nvim-nio"></a>
## `nvim-nio`

Biblioteka async wymagana przez `nvim-dap-ui`. Brak własnych poleceń. Gdy dap-ui zgłasza brak `nio`: `:Lazy! restore nvim-nio` i restart.
