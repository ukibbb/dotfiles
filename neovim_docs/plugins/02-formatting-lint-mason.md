# Wcięcia, formatowanie, lint i Mason

<a id="plugin-indent-blankline"></a>
## `indent-blankline.nvim`

**Co robi i po co:** rysuje pionowe prowadnice wcięć i bieżącego scope, dzięki czemu łatwiej śledzić zagnieżdżenie. Ładuje się po jednorazowym evencie `User FilePost` dla realnego pliku.

**Konfiguracja lokalna:** znak `│`, grupy `IblChar` i `IblScopeChar`, ukrycie pierwszego poziomu spacji oraz cache Base46 z kolorami awaryjnymi, gdy cache nie istnieje.

**Mapowania:** brak aktywnych i brak domyślnych.

**Polecenia:** `:IBLEnable`, `:IBLDisable`, `:IBLToggle`, `:IBLEnableScope`, `:IBLDisableScope`, `:IBLToggleScope`.

### Tutorial: prowadnice i scope

1. Otwórz zagnieżdżony plik Lua, Python, TypeScript albo Go i ustaw kursor w wewnętrznym bloku.
2. Zwykłe linie pokazują poziomy białych znaków. Wyróżniony scope próbuje pokazać bieżący blok składniowy i wymaga działającego parsera Treesitter.
3. Wykonaj `:IBLToggleScope`, aby porównać sam scope, a `:IBLToggle`, aby ukryć lub przywrócić wszystkie prowadnice.
4. `:IBLDisable` i `:IBLEnable` przydają się przy nagrywaniu ekranu lub diagnozie kolorów; warianty `Scope` nie wyłączają zwykłych linii.

Polecenia pojawiają się dopiero po pierwszym realnym pliku, ponieważ wtyczka czeka na `User FilePost`. Brak scope przy widocznych prowadnicach najczęściej oznacza brak parsera albo query, nie awarię IBL. Sprawdź `:InspectTree`, `:TSLog` i `:hi IblScopeChar`.

**Źródła przypiętej rewizji:** [README](https://github.com/lukas-reineke/indent-blankline.nvim/blob/005b56001b2cb30bfa61b7986bc50657816ba4ba/README.md), [help](https://github.com/lukas-reineke/indent-blankline.nvim/blob/005b56001b2cb30bfa61b7986bc50657816ba4ba/doc/indent_blankline.txt), [polecenia](https://github.com/lukas-reineke/indent-blankline.nvim/blob/005b56001b2cb30bfa61b7986bc50657816ba4ba/after/plugin/commands.lua).

<a id="plugin-conform"></a>
## `conform.nvim`

**Co robi i po co:** uruchamia zewnętrzne formatery i zachowuje pozycję kursora lepiej niż ręczne filtrowanie bufora. Ładuje się na `BufWritePre`; użycie `<leader>fm` może go też doładować przez moduł Lazy.

**Konfiguracja lokalna:** Lua używa `stylua`; Python kolejno `ruff_fix` i `ruff_format`. Zapis ma timeout 3000 ms i `lsp_fallback=true`. `<leader>fm` działa w `n,x` i również ma fallback LSP.

**Polecenie:** `:ConformInfo` pokazuje aktywne formatery i ścieżkę logu. Wtyczka nie instaluje domyślnych mapowań.

**Wymagania:** `stylua` i `ruff` w `PATH`; dla innych języków serwer LSP z formatowaniem. Oba narzędzia są w `Brewfile`, a mogą też pochodzić z Mason.

### Jak wybierany jest formatter

- **Lua**: `stylua`.
- **Python**: `ruff_fix`, następnie `ruff_format`.
- **Pozostałe**: Formatter LSP tylko wtedy, gdy brak dostępnego zewnętrznego formattera.

`ruff_fix` uruchamia `ruff check --fix`, więc może usunąć nieużywany import lub zastosować regułę naprawczą. `ruff_format` dopiero potem formatuje kod. Timeout 3000 ms dotyczy zapisu; ręczne `<leader>fm` nie podaje timeoutu i korzysta z domyślnego limitu Conform, zwykle 1000 ms.

### Tutorial: plik i zaznaczenie

1. Otwórz Lua lub Python i wykonaj `:ConformInfo`. Sprawdź nazwę formattera, jego status oraz ścieżkę logu.
2. Zapisz plik. Formatowanie jest synchroniczne w `BufWritePre`, więc na dysk trafia już wynik formattera.
3. Zaznacz kilka wierszy w Visual i użyj `<leader>fm`. Zaznaczenie znakowe i wierszowe staje się zakresem; blockwise Visual nie jest rozpoznawane jako zakres i może sformatować cały bufor.
4. W Python `ruff_format` obsługuje zakres natywnie, lecz `ruff_fix` analizuje pełne wejście i Conform aplikuje nakładające się zmiany. Po operacji zawsze obejrzyj diff.
5. W HTML, CSS albo TypeScript bez skonfigurowanego zewnętrznego formattera fallback może użyć podłączonego LSP, o ile serwer reklamuje formatowanie.

### Diagnostyka

- `:ConformInfo` jest podstawowym źródłem: pokazuje formatter, executable i log.
- `:echo executable('stylua')` oraz `:echo executable('ruff')` odróżniają brak programu od błędu konfiguracji.
- Jeżeli zapis trwa ponad 3 sekundy, formatowanie zgłosi timeout. Ręczne wywołanie może zakończyć się wcześniej ze względu na inny limit.
- Brak formattera i brak zdolnego LSP oznacza no-op lub komunikat; Conform nie instaluje programów, robi to Homebrew albo Mason.

**Źródła przypiętej rewizji:** [README](https://github.com/stevearc/conform.nvim/blob/5ac2bb57a9096f00ca50e1a3c46020d5930319b8/README.md), [help](https://github.com/stevearc/conform.nvim/blob/5ac2bb57a9096f00ca50e1a3c46020d5930319b8/doc/conform.txt), [formatter `ruff_fix`](https://github.com/stevearc/conform.nvim/blob/5ac2bb57a9096f00ca50e1a3c46020d5930319b8/lua/conform/formatters/ruff_fix.lua).

<a id="plugin-nvim-lint"></a>
## `nvim-lint`

**Co robi i po co:** asynchronicznie publikuje diagnostykę narzędzi spoza LSP. Ładuje się przed odczytem lub utworzeniem pliku.

**Konfiguracja lokalna:** tylko Python i `mypy`, uruchamiane na `BufWritePost`. Jeśli `mypy` nie jest wykonywalne, lint jest pomijany, a jedna sesyjna notyfikacja wyjaśnia przyczynę. Wtyczka nie tworzy mapowań ani publicznego polecenia Ex; `lint.try_lint()` to API Lua, nie polecenie użytkownika.

**Wymagania:** `mypy` w `PATH` dla lintowania; bez niego konfiguracja nadal działa bez błędu.

### Tutorial: lint Python

1. Otwórz projekt Python z właściwego katalogu i sprawdź `:pwd`; mypy jest uruchamiane z bieżącego CWD, więc od niego zależy odnalezienie konfiguracji i importów.
2. Wykonaj `:echo executable('mypy')`. Wynik `1` oznacza, że zapis może uruchomić linter.
3. Zapisz plik. `BufWritePost` uruchamia mypy na treści z dysku, a kolejny szybki zapis anuluje poprzedni proces dla tego bufora.
4. Przechodź diagnostykę `[d` / `]d`, pokaż szczegóły `<leader>dd` albo wypełnij location list przez `<leader>ds`.
5. Pyright i mypy mogą zgłaszać podobne błędy typów. Sprawdź źródło diagnostyki w floacie, zanim uznasz wpis za duplikat.

W tej konfiguracji upstreamowa lista linterów została zastąpiona tabelą zawierającą tylko `python = { 'mypy' }`. Brak mypy pomija uruchomienie i pokazuje jedno ostrzeżenie na sesję. Nie czyści to automatycznie starych diagnostyk mypy z wcześniejszego udanego przebiegu; po zmianie środowiska ponownie zapisz lub zrestartuj bufor.

Nie istnieje publiczne polecenie Ex nvim-lint. Ręczne `require('lint').try_lint()` jest **Opcjonalnym upstream API**, a nie aktywnym skrótem.

**Źródła przypiętej rewizji:** [README](https://github.com/mfussenegger/nvim-lint/blob/bcd1a44edbea8cd473af7e7582d3f7ffc60d8e81/README.md), [help](https://github.com/mfussenegger/nvim-lint/blob/bcd1a44edbea8cd473af7e7582d3f7ffc60d8e81/doc/lint.txt), [definicja mypy](https://github.com/mfussenegger/nvim-lint/blob/bcd1a44edbea8cd473af7e7582d3f7ffc60d8e81/lua/lint/linters/mypy.lua).

<a id="plugin-mason"></a>
## `mason.nvim`

**Co robi i po co:** instaluje niezależne od Neovim serwery LSP, formatery, lintery i adaptery DAP. Nie konfiguruje ich użycia, tylko dostarcza executable.

**Ładowanie lokalne:** Lazy reaguje początkowo na `:Mason`, `:MasonInstall`, `:MasonUpdate`. Po załadowaniu rejestrowane są też pozostałe polecenia. `PATH="skip"`, bo `.zshrc` już dodaje `~/.local/share/nvim/mason/bin`; maksymalnie 10 instalatorów działa równolegle.

**Polecenia:** `:Mason`, `:MasonInstall {pakiet...}`, `:MasonUpdate`, `:MasonUninstall {pakiet...}`, `:MasonUninstallAll`, `:MasonLog`; NvChad dodaje `:MasonInstallAll`.

- **`Enter`**: Rozwinięcie pakietu lub logu instalacji. **UI Mason:** pakiet. **Stan:** **Domyślne wtyczki**.
- **`i`**: Instalacja. **UI Mason:** pakiet. **Stan:** **Domyślne wtyczki**.
- **`u`**: Ponowna instalacja/aktualizacja. **UI Mason:** pakiet. **Stan:** **Domyślne wtyczki**.
- **`c`**: Sprawdzenie nowej wersji. **UI Mason:** pakiet. **Stan:** **Domyślne wtyczki**.
- **`U`**: Aktualizacja wszystkich zainstalowanych. **UI Mason:** globalnie. **Stan:** **Domyślne wtyczki**.
- **`C`**: Sprawdzenie wszystkich przestarzałych. **UI Mason:** globalnie. **Stan:** **Domyślne wtyczki**.
- **`X`**: Odinstalowanie. **UI Mason:** pakiet. **Stan:** **Domyślne wtyczki**.
- **`Ctrl-c`**: Anulowanie. **UI Mason:** instalacja. **Stan:** **Domyślne wtyczki**.
- **`Ctrl-f`**: Filtr języka. **UI Mason:** lista. **Stan:** **Domyślne wtyczki**.
- **`1` / `2` / `3` / `4` / `5`**: Wszystkie / LSP / DAP / Linter / Formatter. **UI Mason:** lista. **Stan:** **Domyślne wtyczki**.
- **`q` / `Esc`**: Zamknięcie; `Esc` najpierw czyści aktywny filtr. **UI Mason:** UI. **Stan:** **Domyślne wtyczki**.
- **`g?`**: Pomoc. **UI Mason:** UI. **Stan:** **Domyślne wtyczki**.

### Tutorial: instalacja i aktualizacja narzędzia

1. Otwórz `:Mason` i naciśnij `g?`. Klawisze `2`–`5` ograniczają kategorię, `Ctrl-f` filtruje język, a zwykłe `/` wyszukuje tekst bufora.
2. Ustaw kursor na pakiecie i `Enter`, aby zobaczyć wersje, linki i log. `i` instaluje, `u` reinstaluje lub aktualizuje wskazany pakiet.
3. `c` sprawdza jedną wersję, `C` wszystkie, a `U` aktualizuje wszystkie przestarzałe instalacje. `:MasonUpdate` tylko odświeża rejestry; nie aktualizuje pakietów.
4. Polecenie obsługuje między innymi `pakiet@wersja`, `--force`, `--debug`, `--strict` i `--target=...`; używaj ich tylko, gdy dany pakiet wspiera wersje lub target.
5. Po instalacji sprawdź rzeczywisty executable, na przykład `:echo executable('typescript-language-server')`, potem odpowiedni konsument: `:checkhealth vim.lsp`, `:ConformInfo` albo `:checkhealth dap`.

### `:MasonInstallAll` bez nieporozumień

Polecenie NvChad zbiera włączone konfiguracje LSP oraz formatery Conform i lintery nvim-lint. Nie skanuje adapterów DAP i nie aktualizuje istniejących instalacji. Na pustym starcie może odczytać serwery zanim `nvim-lspconfig` je zarejestruje, dlatego najpewniejsza procedura to najpierw otworzyć plik aktywujący LSP albo jawnie wykonać:

```vim
:MasonInstall lua-language-server html-lsp css-lsp pyright ruff
:MasonInstall typescript-language-server dockerfile-language-server
:MasonInstall docker-compose-language-service stylua mypy
:MasonInstall debugpy delve js-debug-adapter
```

**Bezpieczeństwo:** `X` odinstalowuje pakiet. Już działający proces może przetrwać, ale kolejne uruchomienie LSP, formattera lub adaptera nie znajdzie executable. `PATH="skip"` oznacza, że GUI Neovim bez środowiska `.zshrc` może nie widzieć Masona mimo poprawnej instalacji.

**Diagnostyka:** `:checkhealth mason`, `:MasonLog`, `:echo $PATH` i sprawdzenie `~/.local/share/nvim/mason/bin` odróżniają błąd pobierania, instalacji i widoczności programu.

**Źródła przypiętej rewizji:** [README](https://github.com/mason-org/mason.nvim/blob/44d1e90e1f66e077268191e3ee9d2ac97cc18e65/README.md), [help](https://github.com/mason-org/mason.nvim/blob/44d1e90e1f66e077268191e3ee9d2ac97cc18e65/doc/mason.txt), [mapowania UI](https://github.com/mason-org/mason.nvim/blob/44d1e90e1f66e077268191e3ee9d2ac97cc18e65/lua/mason/settings.lua).
