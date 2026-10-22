# Wcięcia, formatowanie, lint i Mason

<a id="plugin-indent-blankline"></a>
## `indent-blankline.nvim`

Rysuje pionowe linie wcięć (`│`) i wyróżnia bieżący blok (scope), żeby łatwiej śledzić zagnieżdżenie. Działa sam po otwarciu pliku; nie ma mapowań.

- **`:IBLToggle`**: ukryj/pokaż wszystkie prowadnice.
- **`:IBLToggleScope`**: ukryj/pokaż samo wyróżnienie bieżącego bloku.

Brak wyróżnienia scope zwykle oznacza brak parsera Treesitter dla języka.

<a id="plugin-conform"></a>
## `conform.nvim`

Formatuje kod zewnętrznymi narzędziami przy każdym zapisie. Lua: `stylua`; Python: `ruff_fix` (`ruff check --fix`), potem `ruff_format`; pozostałe języki: formatowanie z LSP, jeśli serwer je obsługuje.

- **`<leader>fm`**: sformatuj plik albo zaznaczenie (Normal/Visual).
- **`:w`**: zapis automatycznie formatuje plik (limit 3 s).
- **`:ConformInfo`**: jakie formatery działają dla bieżącego pliku i gdzie jest log.

**Uwaga:** `ruff_fix` może przy zapisie usunąć nieużywane importy. Formatery (`stylua`, `ruff`) muszą być w `PATH` (Homebrew lub Mason).

<a id="plugin-nvim-lint"></a>
## `nvim-lint`

Uruchamia `mypy` po zapisie pliku Python i pokazuje błędy typów jako diagnostykę (uzupełnia Pyright). Nie ma mapowań ani poleceń.

- **`]d`** / **`[d`**: następny / poprzedni błąd.
- **`<leader>dd`**: szczegóły błędu pod kursorem; **`<leader>ds`**: wszystkie błędy w location list.

**Uwaga:** mypy działa z bieżącego katalogu (`:pwd`), więc uruchamiaj Neovim z roota projektu. Jeśli `mypy` nie jest zainstalowany, lint jest pomijany z jednym ostrzeżeniem na sesję.

<a id="plugin-mason"></a>
## `mason.nvim`

Instaluje serwery LSP, formatery, lintery i adaptery DAP do `~/.local/share/nvim/mason/bin` (ten katalog jest w `PATH` przez `.zshrc`). Sam niczego nie konfiguruje — tylko dostarcza programy.

- **`:Mason`**: okno z pakietami; **`:MasonInstall {pakiet}`**: instalacja z linii poleceń.
- W oknie `:Mason`: **`i`** instaluj, **`u`** aktualizuj pakiet, **`U`** aktualizuj wszystkie, **`X`** odinstaluj, **`Enter`** szczegóły, **`2`-`5`** filtr kategorii (LSP/DAP/Linter/Formatter), **`g?`** pomoc, **`q`** zamknij.
- **`:MasonUpdate`**: odświeża tylko rejestr pakietów, nie aktualizuje zainstalowanych.

Pełny zestaw narzędzi tej konfiguracji:

```vim
:MasonInstall lua-language-server html-lsp css-lsp pyright ruff
:MasonInstall typescript-language-server dockerfile-language-server
:MasonInstall docker-compose-language-service stylua mypy
:MasonInstall debugpy delve js-debug-adapter
```

Problemy: `:checkhealth mason`, `:MasonLog`.
