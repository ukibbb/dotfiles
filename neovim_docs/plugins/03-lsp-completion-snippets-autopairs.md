# LSP, completion, snippety i automatyczne pary

<a id="plugin-nvim-lspconfig"></a>
## `nvim-lspconfig`

Gotowe konfiguracje serwerów dla wbudowanego LSP Neovim: definicje, referencje, rename, akcje kodu, diagnostyka. Włączone serwery: `lua_ls`, `html`, `cssls`, `pyright` (typy, hover), `ruff` (lint/fix Python), `ts_ls` (JS/TS/React), `dockerls`, `docker_compose_language_service`.

- **`gd`**: definicja; **`gD`**: deklaracja; **`<leader>D`**: definicja typu; wróć przez `Ctrl-o`.
- **`gr`**: referencje w Telescope; **`gri`**: implementacje.
- **`K`**: dokumentacja (hover) symbolu pod kursorem.
- **`<leader>ca`**: akcje kodu / szybkie poprawki (Normal i Visual).
- **`<leader>ra`**: zmiana nazwy symbolu w całym projekcie.
- **`]d`** / **`[d`**: następny / poprzedni błąd; **`<leader>dd`**: szczegóły błędu; **`<leader>ds`**: lista błędów.
- **`gO`**: symbole dokumentu.
- **`<leader>lr`**: restart serwerów LSP bieżącego bufora.
- **`<leader>wa`** / **`<leader>wr`** / **`<leader>wl`**: dodaj / usuń / wypisz folder workspace.
- Tylko TypeScript: **`gS`**: skok do źródła zamiast do `.d.ts`; **`<leader>ci`**: akcje importów (organizacja, usuwanie nieużywanych).
- **`Ctrl-s`** (Insert): podpowiedź sygnatury funkcji.

**Uwaga:** `Ctrl-s` to leader WezTerm — w Neovim naciśnij `Ctrl-s Ctrl-s`. `ts_ls` sam restartuje się po utracie synchronizacji; gdy LSP „zgłupieje”, użyj `<leader>lr`.

Problemy: `:checkhealth vim.lsp` (sprawdź, czy serwer jest zainstalowany i czy Neovim uruchomiono w roocie projektu).

<a id="plugin-nvim-cmp"></a>
## `nvim-cmp`

Popup podpowiedzi w trybie Insert. Łączy źródła: `[LSP]`, `[Snippet]`, a gdy te nic nie dają — `[Nvim]`, `[Buffer]`, `[Path]`; w SQL także `[DB]`. Etykieta po prawej mówi, skąd jest podpowiedź.

- **`Ctrl-n`** / **`Alt-j`** / **`Tab`**: następna pozycja; **`Ctrl-p`** / **`Alt-k`** / **`Shift-Tab`**: poprzednia.
- **`Enter`**: zatwierdź (bez wyboru bierze pierwszą pozycję).
- **`Ctrl-Spacja`**: otwórz menu ręcznie; **`Ctrl-e`**: zamknij.
- **`Ctrl-f`** / **`Ctrl-d`**: przewijaj dokumentację pozycji.

**Uwaga:** auto-importy (np. w TypeScript) dodaje tylko pozycja `[LSP]`; `[Buffer]` wstawia zwykły tekst.

<a id="plugin-luasnip"></a>
## `LuaSnip`

Silnik snippetów: rozwija skrót w szablon kodu z polami do wypełnienia. Snippety pochodzą z `friendly-snippets`.

- **`Tab`** / **`Shift-Tab`**: następne / poprzednie pole snippetu (gdy menu completion jest zamknięte).
- **`:LuaSnipListAvailable`**: lista snippetów dla bieżącego pliku.

### Jak używać

1. Wpisz trigger, np. `ifmain` w Pythonie albo `!` w HTML.
2. Wybierz pozycję `[Snippet]` i zatwierdź `Enter`.
3. Przechodź między polami `Tab`, wracaj `Shift-Tab`.

Po wyjściu z Insert snippet jest „odłączany” — nie da się wrócić do jego pól.

<a id="plugin-cmp-nvim-lsp"></a>
## `cmp-nvim-lsp`

Źródło `[LSP]` dla nvim-cmp: podpowiedzi z serwera LSP, w tym auto-importy. Brak własnych mapowań.

<a id="plugin-cmp-luasnip"></a>
## `cmp_luasnip`

Źródło `[Snippet]`: pokazuje snippety LuaSnip w menu completion. Brak własnych mapowań.

<a id="plugin-cmp-nvim-lua"></a>
## `cmp-nvim-lua`

Źródło `[Nvim]`: podpowiada API Neovim (`vim.api.`, `vim.fn.` ...) w plikach Lua i Vim. Brak własnych mapowań.

<a id="plugin-cmp-buffer"></a>
## `cmp-buffer`

Źródło `[Buffer]`: słowa z bieżącego pliku (od 3 znaków), gdy LSP i snippety nic nie podpowiadają. Brak własnych mapowań.

<a id="plugin-cmp-async-path"></a>
## `cmp-async-path`

Źródło `[Path]`: ścieżki plików po wpisaniu `./`, `../` lub `~/` (pliki ukryte: `./.`). Brak własnych mapowań.

<a id="plugin-friendly-snippets"></a>
## `friendly-snippets`

Gotowa kolekcja snippetów dla wielu języków (np. Lua `req`, Python `ifmain`, HTML `!`, Go `pkgm`). Tylko dane — obsługuje je LuaSnip; listę zobaczysz przez `:LuaSnipListAvailable`.

<a id="plugin-nvim-autopairs"></a>
## `nvim-autopairs`

Automatycznie domyka nawiasy i cudzysłowy. Wyłączone w prompcie Telescope i plikach `vim`.

- **`(`, `[`, `{`, `"`**: wstawia parę; wpisanie znaku zamykającego przeskakuje przez istniejący.
- **`Backspace`** w pustej parze: usuwa oba znaki.
- **`Enter`** między `{}`: nowa wcięta linia w środku.
- **`Alt-e`**: FastWrap — z kursorem zaraz po `(` w `(|)foobar` naciśnij `Alt-e` i wybierz cel, by otrzymać `(foobar)`.
- Zatwierdzenie funkcji z completion dopisuje `()`.
