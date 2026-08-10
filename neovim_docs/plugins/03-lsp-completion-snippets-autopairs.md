# LSP, completion, snippety i automatyczne pary

<a id="plugin-nvim-lspconfig"></a>
## `nvim-lspconfig`

**Co robi i po co:** `neovim/nvim-lspconfig` dostarcza definicje konfiguracji serwerów dla wbudowanego klienta LSP Neovim. Nie jest osobnym frameworkiem mapowań. Lokalna konfiguracja używa API Neovim 0.12 `vim.lsp.config()` i `vim.lsp.enable()`.

**Ładowanie lokalne:** `BufReadPre` lub `BufNewFile`, z zależnością `cmp-nvim-lsp`. Wildcard config dodaje możliwości completion i wyłącza semantic tokens, aby uniknąć konfliktu z Treesitter. Autocmd `LspAttach` tworzy mapowania buffer-local.

- **`lua_ls`**: **Filetype/cel:** Lua/Neovim. **Wymagane executable lub pakiet:** `lua-language-server`.
- **`html`**: **Filetype/cel:** HTML. **Wymagane executable lub pakiet:** `vscode-html-language-server`, pakiet Mason `html-lsp`.
- **`cssls`**: **Filetype/cel:** CSS. **Wymagane executable lub pakiet:** `vscode-css-language-server`, pakiet Mason `css-lsp`.
- **`pyright`**: **Filetype/cel:** Typy Python i hover. **Wymagane executable lub pakiet:** `pyright-langserver`, pakiet `pyright`.
- **`ruff`**: **Filetype/cel:** Lint/fix/format Python, bez hover. **Wymagane executable lub pakiet:** `ruff`.
- **`ts_ls`**: **Filetype/cel:** JavaScript/TypeScript/React. **Wymagane executable lub pakiet:** `typescript-language-server` oraz `typescript`; lokalny `node_modules/.bin` ma pierwszeństwo.
- **`dockerls`**: **Filetype/cel:** Dockerfile. **Wymagane executable lub pakiet:** pakiet `dockerfile-language-server`.
- **`docker_compose_language_service`**: **Filetype/cel:** Compose. **Wymagane executable lub pakiet:** pakiet `docker-compose-language-service`.

`lua_ls` zna runtime Neovim, typy NvChad, kod lazy.nvim i bibliotekę luv. `ts_ls` preferuje nierelatywne aliasy z `tsconfig`. Pyright nie zgłasza lokalnie nieużywanych importów/zmiennych, bo ten obszar należy do Ruff; Ruff ma wyłączony hover.

`ts_ls`, HTML i CSS mogą preferować executable z projektowego `node_modules/.bin`. Otwierając niezaufane repozytorium, pamiętaj, że klient może uruchomić kod dostarczony przez projekt. Docker Compose wymaga poprawnie wykrytego filetype, zwykle `yaml.docker-compose`.

### Aktywne mapowania lokalne LSP

- **`gD`, `gd`, `gr`**: Deklaracja, definicja, referencje w Telescope. **Tryb:** `n`.
- **`<leader>ca`**: Akcje kodu i refaktoryzacje. **Tryb:** `n,x`.
- **`<leader>lr`**: Wbudowany restart klientów bieżącego bufora. **Tryb:** `n`.
- **`<leader>wa`, `<leader>wr`, `<leader>wl`**: Dodaj, usuń, wypisz foldery workspace. **Tryb:** `n`.
- **`<leader>D`**: Definicja typu. **Tryb:** `n`.
- **`<leader>ra`**: Rename przez NvChad. **Tryb:** `n`.
- **`gS`, `<leader>ci`**: Source definition; akcje źródłowe całego pliku. **Tryb:** `n`, tylko `ts_ls`.

### Wbudowane mapowania Neovim 0.12

- **`grn`**: Rename. **Tryb:** `n`. **Stan:** **Domyślne Neovim**.
- **`gra`**: Code action. **Tryb:** `n,x`. **Stan:** **Domyślne Neovim**.
- **`gri`**: Implementation. **Tryb:** `n`. **Stan:** **Domyślne Neovim**.
- **`grr`**: References bez lokalnego pickera. **Tryb:** `n`. **Stan:** **Domyślne Neovim**.
- **`grt`**: Type definition. **Tryb:** `n`. **Stan:** **Domyślne Neovim**.
- **`grx`**: Uruchomienie code lens. **Tryb:** `n`. **Stan:** **Domyślne Neovim**.
- **`gO`**: Symbole dokumentu. **Tryb:** `n`. **Stan:** **Domyślne Neovim**.
- **`gx`**: Otworzenie linku pod kursorem, także linku dokumentu LSP. **Tryb:** `n,x`. **Stan:** **Domyślne Neovim**.
- **`an` / `in`**: Zewnętrzna / wewnętrzna selekcja węzła Treesitter z fallbackiem LSP. **Tryb:** `x,o`. **Stan:** **Domyślne Neovim**.
- **`Ctrl-s`**: Signature help. **Tryb:** `i,s`. **Stan:** **Domyślne Neovim**; konflikt z prefixem tmux.
- **`K`**: Hover, jeśli nie zastąpiono `keywordprg`/mapowania. **Tryb:** `n`, po attach. **Stan:** **Kontekstowe**.
- **`Ctrl-]`, `Ctrl-w ]`, `Ctrl-w }`**: Nawigacja tagfunc przez LSP. **Tryb:** `n`, po attach. **Stan:** **Kontekstowe**.
- **`gq`**: Format przez formatexpr LSP, jeśli wspierane. **Tryb:** `n,x`, po attach. **Stan:** **Kontekstowe**.

Wbudowane diagnostyki: `[d`, `]d`, `[D`, `]D`, `Ctrl-w d`, `Ctrl-w Ctrl-d`. Lokalna konfiguracja zachowuje ich implementację Neovim 0.12 i dodaje `<leader>dd`, `<leader>ds`, `<leader>q`. Neovim może po attach uruchamiać file watching i podświetlenie kolorów dokumentu. LuaLS reklamuje inlay hints i code lenses, lecz wyświetlanie inlay hints oraz adnotacji code lens nie jest tutaj jawnie włączone.

**Polecenia Neovim 0.12:** `:lsp enable [config]`, `:lsp disable [config]`, `:lsp restart [client]`, `:lsp stop [client]`, `:checkhealth vim.lsp`. `stop` kończy bieżącego klienta tymczasowo, `disable` wyłącza konfigurację i bieżące/przyszłe uruchomienia, a `restart` zachowuje konfigurację. Gdy wbudowane `:lsp` istnieje, przypięty lspconfig nie rejestruje starszych aliasów `:LspInfo`, `:LspStart`, `:LspStop`, `:LspRestart` ani `:LspLog`. TypeScript tworzy buffer-local `:LspTypescriptSourceAction` i `:LspTypescriptGoToSourceDefinition`. Pyright tworzy buffer-local `:LspPyrightOrganizeImports` oraz `:LspPyrightSetPythonPath {path}`; zmiana interpretera jest sesyjna.

**Wymagania:** Neovim 0.12 dla używanego interfejsu i restartu, executable serwerów w `PATH`, poprawny root projektu. Dla TypeScript zalecany jest `tsconfig.json`/`jsconfig.json` oraz lockfile menedżera pakietów.

### Tutorial: od uruchomienia do refaktoryzacji

1. Uruchom Neovim w katalogu projektu i otwórz obsługiwany plik. Sprawdź `:set filetype?`, ponieważ filetype wybiera konfigurację serwera.
2. Wykonaj `:checkhealth vim.lsp` oraz `:lua =vim.lsp.get_clients({ bufnr = 0 })`. Pusta lista oznacza problem executable, root albo filetype, nie problem mapowania `gd`.
3. Nad symbolem użyj `gd`, wróć `Ctrl-o`, pokaż dokumentację `K`, znajdź użycia lokalnym `gr` i implementację wbudowanym `gri`.
4. Zaznacz zakres i użyj `<leader>ca`; LSP otrzyma range. Do zmiany nazwy użyj `<leader>ra` i po operacji obejrzyj wszystkie zmienione bufory.
5. Diagnostykę przeglądaj `]d` / `[d`, szczegół `<leader>dd`, a cały bieżący zestaw `<leader>ds`.

### Tutorial: TypeScript i auto-importy

1. Sprawdź obecność `typescript-language-server` oraz projektowego `typescript`; serwer preferuje `node_modules/.bin` i root wyznaczony przez pliki projektu.
2. `gS` próbuje przejść z deklaracji `.d.ts` do źródłowej implementacji. Zwykłe `gd` pozostaje definicją protokołu LSP.
3. `<leader>ci` otwiera akcje źródłowe całego pliku, między innymi organizację importów i usuwanie nieużywanego kodu. Przeczytaj nazwę akcji przed zatwierdzeniem.
4. Auto-import z completion działa tylko dla pozycji `[LSP]`, bo provider musi dostarczyć `additionalTextEdits`.
5. Lokalny handler obserwuje log `ts_ls`. Przy utracie synchronizacji dokumentu albo `SIGABRT` planuje automatyczny restart; w Insert/Replace czeka do `InsertLeave`, poza nimi około 100 ms. Ręczne `<leader>lr` pozostaje awaryjnym restartem.

### Tutorial: Python bez nakładających się odpowiedzialności

1. Pyright dostarcza typy i hover, a Ruff lint/fix/format bez hover. Nieużywane importy i zmienne są wyłączone w Pyright, więc brak executable `ruff` pozostawia w tym obszarze lukę.
2. Sprawdź oba klienty przez `:lua =vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients({bufnr=0}))`.
3. `:LspPyrightSetPythonPath /ścieżka/do/python` zmienia interpreter tylko w bieżącej sesji; trwalsze środowisko ustaw w projekcie lub aktywuj przed startem Neovim.
4. Formatowanie i poprawki przy zapisie wykonuje Conform, a mypy po zapisie nvim-lint. Źródło diagnostyki odróżnia te warstwy.

### Completion omnifunc i pozostałe ograniczenia

`cmp-nvim-lsp.default_capabilities()` rozszerza możliwości klienta dla nvim-cmp i upstream ostrzega, że wbudowany przepływ `Ctrl-x Ctrl-o` nie jest wtedy wspieranym zamiennikiem. Korzystaj z nvim-cmp. Semantic tokens są usuwane dla wszystkich klientów, aby podstawowe podświetlanie pochodziło z Treesitter.

**Diagnostyka:** oprócz health sprawdź `:messages`, `:echo executable('nazwa')`, bieżący `:pwd`, root klienta w `vim.lsp.get_clients()` i `:verbose nmap gd`. Na macOS file watching dużego workspace może kosztować zasoby; ustal najpierw, który klient i root obserwuje katalog.

**Źródła przypiętej rewizji:** [README lspconfig](https://github.com/neovim/nvim-lspconfig/blob/1c0d8f70dbc8827263eedc3cf7021ceba0f68689/README.md), [help](https://github.com/neovim/nvim-lspconfig/blob/1c0d8f70dbc8827263eedc3cf7021ceba0f68689/doc/lspconfig.txt), [konfiguracja `ts_ls`](https://github.com/neovim/nvim-lspconfig/blob/1c0d8f70dbc8827263eedc3cf7021ceba0f68689/lsp/ts_ls.lua), [wbudowany help LSP Neovim 0.12](https://github.com/neovim/neovim/blob/v0.12.4/runtime/doc/lsp.txt).

<a id="plugin-nvim-cmp"></a>
## `nvim-cmp`

**Co robi i po co:** silnik popupu completion. Ładuje się przy `InsertEnter`, łączy semantyczne propozycje LSP, snippety, API Neovim, słowa bufora i ścieżki.

**Konfiguracja lokalna:** `completeopt=menu,menuone`; potwierdzenie ma zachowanie Insert i `select=true`. Menu pokazuje dostawcę. Pierwsza grupa ma `nvim_lsp` z priorytetem 1000 i `luasnip` 750. Dopiero gdy grupa podstawowa nie daje kandydatów, używana jest grupa `nvim_lua` 500, `buffer` 250, `async_path` 200. Integracja nvim-autopairs działa po `confirm_done`.

- **`Ctrl-p` / `Alt-k`, `Ctrl-n` / `Alt-j`**: Poprzedni / następny kandydat. **Tryb:** `i`.
- **`Ctrl-d` / `Ctrl-f`**: Dokumentacja w górę / w dół. **Tryb:** `i`.
- **`Ctrl-Spacja`, `Ctrl-e`, `Enter`**: Otwórz, zamknij, zatwierdź. **Tryb:** `i`.
- **`Tab`, `Shift-Tab`**: Kandydat lub placeholder snippetu. **Tryb:** `i,s`.

Wtyczka nie instaluje użytecznych domyślnych mapowań bez konfiguracji; upstreamowe presety są szablonami. **Polecenie:** `:CmpStatus` wypisuje status źródeł.

### Jak współpracują dostawcy

Każdy provider zasila wspólny popup nvim-cmp. Nie ma własnego polecenia Ex ani mapowania; etykiety `[LSP]`, `[Snippet]`, `[Nvim]`, `[Buffer]` i `[Path]` są jego widocznym interfejsem.

### Kolejność i fallback klawiszy

- Grupa pierwsza (`nvim_lsp`, `luasnip`) ma pierwszeństwo jako całość. `nvim_lua`, `buffer` i `async_path` pojawiają się dopiero, gdy pierwsza grupa nie ma pasujących kandydatów.
- `Enter` ma `select=true`, więc może zatwierdzić pierwszy element bez jawnego ruchu. Przeczytaj etykietę źródła przed zatwierdzeniem, szczególnie przy auto-importach.
- `Ctrl-e` używa `close()`, nie `abort()`. Po przejściu po kandydatach podgląd wstawionego tekstu może pozostać; nie ma lokalnego skrótu „anuluj i przywróć oryginał”. Bez widocznego menu `Ctrl-e` wpada w lokalny ruch na koniec wiersza.
- Bez dokumentacji `Ctrl-d`/`Ctrl-f` wracają do zachowania Insert. Bez menu `Ctrl-n`/`Ctrl-p` mogą uruchomić natywne keyword completion.
- `Tab` najpierw porusza menu, potem rozwija lub przeskakuje LuaSnip, a dopiero na końcu wykonuje zwykły fallback.

### Tutorial: semantyczne completion

1. Otwórz plik z aktywnym LSP, wejdź do Insert i wpisz początek symbolu.
2. Sprawdź etykietę `[LSP]`, przechodź `Alt-j` / `Alt-k` i przewijaj dokumentację `Ctrl-f` / `Ctrl-d`.
3. Zatwierdź `Enter`. W TypeScript pozycja zawierająca auto-import może jednocześnie dopisać import; od razu obejrzyj początek pliku.
4. `Ctrl-Spacja` otwiera menu ręcznie, a `Ctrl-e` je zamyka z opisanym wyżej ograniczeniem.

### Tutorial: źródła fallback

1. Wpisz trzy pierwsze znaki unikalnego słowa istniejącego w bieżącym buforze; gdy LSP i snippety nie pasują, pojawi się `[Buffer]`.
2. Wpisz `./`, `../` albo `~/`, aby zobaczyć `[Path]`. Ukryty plik wymaga jawnej kropki, na przykład `./.`.
3. W pliku `vim` wpisz fragment polecenia `lua vim.api.`; `[Nvim]` pochodzi z runtime API, o ile grupa pierwsza nie ma kandydata.
4. `:CmpStatus` pokazuje status providerów po pierwszym `InsertEnter`. Stan `unknown` nie zawsze jest błędem, bo część źródeł jest kontekstowa.

Command-line completion i ghost text są w kodzie dostępne konfiguracyjnie, lecz tutaj **Warunkowe/wyłączone**. Menu nie otwiera się automatycznie w promptach i podczas wykonywania makr.

**Źródła przypiętej rewizji:** [README](https://github.com/hrsh7th/nvim-cmp/blob/2ffe79f1f021def8dd1fcd81deb16f1bb0d989f3/README.md), [help](https://github.com/hrsh7th/nvim-cmp/blob/2ffe79f1f021def8dd1fcd81deb16f1bb0d989f3/doc/cmp.txt), [domyślna konfiguracja](https://github.com/hrsh7th/nvim-cmp/blob/2ffe79f1f021def8dd1fcd81deb16f1bb0d989f3/lua/cmp/config/default.lua).

<a id="plugin-luasnip"></a>
## `LuaSnip`

**Co robi i po co:** rozwija snippety i utrzymuje placeholdery. Ładuje się jako zależność nvim-cmp; historia snippetów jest włączona, a placeholdery aktualizują się na `TextChanged` i `TextChangedI`.

**Ładowanie snippetów:** lokalna konfiguracja uruchamia loadery VS Code, SnipMate i Lua, lecz realną kolekcję dostarcza obecnie tylko `friendly-snippets` w formacie VS Code. Nie ma lokalnych katalogów SnipMate/Lua ani ustawionych niestandardowych ścieżek. Po wyjściu z Insert nieaktywny snippet jest odłączany, aby nie pozostawić uszkodzonego stanu.

**Aktywne lokalne:** `Tab` i `Shift-Tab` w `i,s` przez nvim-cmp. LuaSnip tworzy cele `<Plug>`, ale żaden dodatkowy bezpośredni klawisz nie jest tu przypisany.

**Polecenia:** `:LuaSnipUnlinkCurrent`, `:LuaSnipListAvailable`. Wzmiankowane w dokumentacji mapowanie edytora snippetów nie jest w tej rewizji zarejestrowanym poleceniem użytkownika.

### Tutorial: znalezienie i rozwinięcie snippetu

1. Otwórz plik obsługiwany przez friendly-snippets i po pierwszym `InsertEnter` wykonaj `:LuaSnipListAvailable`.
2. W Python spróbuj triggera `ifmain`, w HTML `!`, w Lua `req`, a w Go `pkgm`. Lista zależy od filetype i rewizji kolekcji.
3. Wybierz kandydat `[Snippet]`, zatwierdź `Enter`, a między polami przechodź `Tab`; `Shift-Tab` wraca.
4. Placeholdery zależne aktualizują się na `TextChanged` i `TextChangedI`.
5. Jeżeli wyjdziesz z Insert przez `jk`/`Esc` poza aktywnym skokiem, lokalny autocmd odłącza snippet. Po ponownym wejściu nie oczekuj wznowienia starych placeholderów.

Autosnippety, osobna nawigacja choice node i edytor snippetów nie mają lokalnych mapowań. Transformacje wymagające `jsregexp` mogą działać w ograniczonym trybie, jeśli natywna biblioteka LuaSnip nie została zbudowana; sprawdź `:checkhealth luasnip`.

**Diagnostyka:** sprawdź `:set filetype?`, `:LuaSnipListAvailable`, etykietę `[Snippet]`, `:checkhealth luasnip` oraz czy `friendly-snippets` jest załadowane w `:Lazy`. `:LuaSnipUnlinkCurrent` ręcznie kończy uszkodzony kontekst.

**Źródła przypiętej rewizji:** [README](https://github.com/L3MON4D3/LuaSnip/blob/3732756842a2f7e0e76a7b0487e9692072857277/README.md), [help](https://github.com/L3MON4D3/LuaSnip/blob/3732756842a2f7e0e76a7b0487e9692072857277/doc/luasnip.txt), [polecenia](https://github.com/L3MON4D3/LuaSnip/blob/3732756842a2f7e0e76a7b0487e9692072857277/plugin/luasnip.lua).

<a id="plugin-cmp-nvim-lsp"></a>
## `cmp-nvim-lsp`

**Rola:** rozszerza capabilities klienta i przekazuje kandydatów serwera, w tym snippet text oraz `additionalTextEdits` potrzebne do auto-importów.

**Tutorial:** otwórz TypeScript z aktywnym `ts_ls`, wpisz nazwę niezaimportowanego symbolu, wybierz pozycję `[LSP]` i zatwierdź. Sprawdź, czy import pojawił się w pliku. Kandydat bez etykiety `[LSP]` jest zwykłym tekstem i nie niesie edycji importu. Klient podłączony dopiero podczas Insert może wymagać wyjścia i ponownego `InsertEnter`, aby źródło zostało odświeżone.

**Źródła przypiętej rewizji:** [README](https://github.com/hrsh7th/cmp-nvim-lsp/blob/cbc7b02bb99fae35cb42f514762b89b5126651ef/README.md), [provider](https://github.com/hrsh7th/cmp-nvim-lsp/blob/cbc7b02bb99fae35cb42f514762b89b5126651ef/lua/cmp_nvim_lsp/init.lua).

<a id="plugin-cmp-luasnip"></a>
## `cmp_luasnip`

**Rola:** zamienia dostępne snippety LuaSnip na kandydatów `[Snippet]`. Respektuje warunek widoczności snippetu; autosnippety są domyślnie ukryte i lokalnie nie są włączone.

**Tutorial:** porównaj `:LuaSnipListAvailable` z pozycjami `[Snippet]` po wpisaniu triggera. Provider tylko proponuje element; rozwinięcie i placeholdery wykonuje LuaSnip, a klawisze dostarcza nvim-cmp.

**Źródła przypiętej rewizji:** [README](https://github.com/saadparwaiz1/cmp_luasnip/blob/98d9cb5c2c38532bd9bdb481067b20fea8f32e90/README.md), [provider](https://github.com/saadparwaiz1/cmp_luasnip/blob/98d9cb5c2c38532bd9bdb481067b20fea8f32e90/lua/cmp_luasnip/init.lua).

<a id="plugin-cmp-nvim-lua"></a>
## `cmp-nvim-lua`

**Rola:** proponuje pola globalnych tabel runtime Neovim dla filetype `lua` i `vim`. Ukrywa pola zaczynające się od `_`.

**Tutorial:** najłatwiej zobaczyć `[Nvim]` w buforze Vimscript bez aktywnej pierwszej grupy: wpisz `lua vim.api.`. W zwykłym Lua `lua_ls` często dostarcza lepszy kandydat `[LSP]`, więc grupa druga celowo pozostaje niewidoczna.

**Źródła przypiętej rewizji:** [README](https://github.com/hrsh7th/cmp-nvim-lua/blob/e3a22cb071eb9d6508a156306b102c45cd2d573d/README.md), [provider](https://github.com/hrsh7th/cmp-nvim-lua/blob/e3a22cb071eb9d6508a156306b102c45cd2d573d/lua/cmp_nvim_lua/init.lua).

<a id="plugin-cmp-buffer"></a>
## `cmp-buffer`

**Rola:** indeksuje słowa bieżącego bufora. Domyślny minimalny token ma 3 znaki; indeksowanie odbywa się asynchronicznie partiami, a bardzo długie wiersze są ograniczane.

**Tutorial:** wpisz w innym miejscu unikalne słowo o długości co najmniej 3, wróć i zacznij je przepisywać. `[Buffer]` pojawi się tylko wtedy, gdy LSP i snippety z pierwszej grupy nie mają pasującej pozycji. Inne otwarte bufory nie są lokalnie źródłem.

**Źródła przypiętej rewizji:** [README i opcje](https://github.com/hrsh7th/cmp-buffer/blob/b74fab3656eea9de20a9b8116afa3cfc4ec09657/README.md), [provider](https://github.com/hrsh7th/cmp-buffer/blob/b74fab3656eea9de20a9b8116afa3cfc4ec09657/lua/cmp_buffer/init.lua).

<a id="plugin-cmp-async-path"></a>
## `cmp-async-path`

**Rola:** asynchronicznie proponuje ścieżki względem katalogu bieżącego pliku. Rozpoznaje między innymi `./`, `../`, `~/` i `$VAR/`.

**Tutorial:** w Insert wpisz `./`, wybierz `[Path]`, a do pliku ukrytego wpisz jawnie `./.`. Dokumentacja pozycji może pokazać do 20 pierwszych wierszy pliku. Jeśli bufor nie ma ścieżki, katalog bazowy może być mniej intuicyjny; sprawdź nazwę bufora i CWD.

**Źródła przypiętej rewizji:** [README na Codeberg](https://codeberg.org/FelipeLema/cmp-async-path/src/commit/9c2374deb32c2bec8b27e928c6f57090e9a875d2/README.md), [provider](https://codeberg.org/FelipeLema/cmp-async-path/src/commit/9c2374deb32c2bec8b27e928c6f57090e9a875d2/lua/cmp_async_path/init.lua).

<a id="plugin-friendly-snippets"></a>
## `friendly-snippets`

**Rola:** kolekcja danych VS Code, a nie silnik. LuaSnip ładuje ją na żądanie, cmp_luasnip pokazuje kandydaty, a nvim-cmp obsługuje wybór.

**Tutorial:** użyj `:LuaSnipListAvailable`, potem wypróbuj typowy trigger dla filetype, na przykład Lua `req`, Python `ifmain`, HTML `!`, Markdown `h1` albo Go `pkgm`. Snippety React przypisane do `javascriptreact`/`typescriptreact` działają, lecz wirtualne frameworkowe filetype wymagające `filetype_extend()` nie są lokalnie rozszerzone.

Kolekcja nie ma mapowań ani poleceń. Brak triggera diagnozuj przez filetype, listę LuaSnip i wpis `friendly-snippets` w Lazy.

**Źródła przypiętej rewizji:** [README](https://github.com/rafamadriz/friendly-snippets/blob/572f5660cf05f8cd8834e096d7b4c921ba18e175/README.md), [manifest snippetów](https://github.com/rafamadriz/friendly-snippets/blob/572f5660cf05f8cd8834e096d7b4c921ba18e175/package.json).

<a id="plugin-nvim-autopairs"></a>
## `nvim-autopairs`

**Co robi i po co:** domyka nawiasy i cudzysłowy, obsługuje pary przy Backspace/Enter i integruje się z completion. Ładuje się z nvim-cmp.

**Konfiguracja lokalna:** `fast_wrap={}` włącza FastWrap. Wtyczka jest wyłączona dla `TelescopePrompt` i filetype `vim`. Domyślne mapowanie `Ctrl-h` do usuwania pary oraz `Ctrl-w` do usuwania słowa-pary są wyłączone.

- **znaki otwierające**: Automatyczne dodanie pary. **Tryb:** `i`. **Stan:** **Kontekstowe**.
- **`Backspace`**: Usunięcie pustej pary. **Tryb:** `i`. **Stan:** **Domyślne wtyczki**.
- **`Enter`**: Inteligentna nowa linia między parami. **Tryb:** `i`. **Stan:** **Domyślne wtyczki**; nvim-cmp przekazuje fallback, a confirm ma integrację.
- **`Alt-e`**: FastWrap istniejącego tekstu. **Tryb:** `i`. **Stan:** **Kontekstowe**, aktywne przez lokalne `fast_wrap`.
- **`Ctrl-h`, `Ctrl-w`**: Specjalne usuwanie par. **Tryb:** `i`. **Stan:** **Warunkowe/wyłączone**.

Brak publicznych poleceń Ex.

### Tutorial: pary, Enter i completion

1. Wpisz `(`, `{`, `[` albo cudzysłów. Gdy para jest pusta, `Backspace` usuwa oba znaki; wpisanie istniejącego znaku zamykającego przesuwa przez niego zamiast duplikować.
2. Ustaw kursor między `{}` i naciśnij `Enter`, aby otrzymać inteligentnie wciętą pustą linię.
3. Zatwierdź funkcję lub metodę z nvim-cmp. Hook `confirm_done` może dopisać `()`, chyba że kandydat już zawiera nawiasy albo filetype jest wyłączony.
4. Pary są wyłączone dokładnie dla `TelescopePrompt` i `vim`. Lokalna lista zastępuje listę upstream, więc nie należy zakładać innych domyślnych wykluczeń.

### Tutorial: poprawny FastWrap

1. Przygotuj tekst tak, aby kursor był bezpośrednio po znaku otwierającym, na przykład `(|)foobar`, gdzie `|` oznacza kursor.
2. Naciśnij `Alt-e`. Wtyczka oznaczy możliwe miejsca docelowe po tekście.
3. Wybierz pokazany znak celu za `foobar`; nawias zamykający zostanie przesunięty i powstanie `(foobar)`.
4. FastWrap nie służy do uruchamiania na końcu już wpisanego `(foobar)`; punkt startowy musi znajdować się przy otwarciu.

Makra i Replace mode nie dostają par domyślnie, sprawdzanie kontekstu Treesitter jest wyłączone. Reguły Markdown fences, potrójnych cudzysłowów, komentarzy i Enter są nadal częścią przypiętych defaultów. Wyłączone mapowania autopairs `Ctrl-h`/`Ctrl-w` nie usuwają lokalnego `Ctrl-h` do ruchu ani natywnego kasowania słowa.

**Diagnostyka:** sprawdź filetype, `:verbose imap <M-e>`, konflikt terminala z Alt oraz czy nvim-cmp został już załadowany. Wtyczka nie ma publicznego polecenia Ex.

**Źródła przypiętej rewizji:** [README](https://github.com/windwp/nvim-autopairs/blob/c2a0dd0d931d0fb07665e1fedb1ea688da3b80b4/README.md), [help](https://github.com/windwp/nvim-autopairs/blob/c2a0dd0d931d0fb07665e1fedb1ea688da3b80b4/doc/nvim-autopairs.txt), [integracja cmp](https://github.com/windwp/nvim-autopairs/blob/c2a0dd0d931d0fb07665e1fedb1ea688da3b80b4/lua/nvim-autopairs/completion/cmp.lua).
