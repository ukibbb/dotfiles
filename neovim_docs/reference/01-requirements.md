<a id="wymagania"></a>
# Wymagania i środowisko

## Wersje bazowe sprawdzone lokalnie

- **macOS + WezTerm**: **Wersja/stan:** konfiguracja repo dla WezTerm. **Dlaczego ma znaczenie:** True color, synchronized output i extended keys CSI-u.
- **Neovim**: **Wersja/stan:** `v0.12.4`, LuaJIT. **Dlaczego ma znaczenie:** nowe API LSP i gałąź `main` nvim-treesitter.
- **tmux**: **Wersja/stan:** `3.7b`. **Dlaczego ma znaczenie:** [lista domyślnych mapowań tmux](../03-tmux.md#tmux) odpowiada tej wersji.
- **zsh + Oh My Zsh**: **Wersja/stan:** shell użytkownika. **Dlaczego ma znaczenie:** ładuje `PATH`, NVM i wyłącza XON/XOFF.
- **WezTerm keybindings**: **Wersja/stan:** mapowania `Cmd` w `wezterm.lua`. **Dlaczego ma znaczenie:** fizyczne `Cmd-h/j/k/l/q`, `Cmd-\`, `Cmd--` i `Cmd-n` do kodów terminalowych.
- **Nerd Font Symbols**: **Wersja/stan:** dołączone do WezTerm jako fallback. **Dlaczego ma znaczenie:** poprawne ikony NvChad, drzewa, Git, DAP i Markdown.

## Instalacja warstw

1. W katalogu repo uruchom `brew bundle --file Brewfile`. Deklarowane są: Neovim, Go, `govulncheck`, GitHub CLI, tree-sitter-cli, tmux, fzf, fd, ripgrep, jq, stylua, ruff, `libpq`, `mysql-client`, SQLite, DuckDB, `sqlcmd` i WezTerm.
2. Zainstaluj NVM oraz domyślne Node LTS zgodnie z [głównym README repozytorium](../../README.md#fresh-mac-setup); Node uruchamia część serwerów Mason i adapter JS/TS.
3. Utwórz dowiązania przez `bash install.sh install` i sprawdź je przez `bash install.sh status`. Instalator wykonuje timestampowane backupy zastępowanych celów.
4. Sklonuj TPM do `~/.tmux/plugins/tpm`, wczytaj konfigurację przez `tmux source-file "$HOME/.tmux.conf"`, a wewnątrz tmux naciśnij `Ctrl-s I`.
5. Odtwórz wtyczki Neovim dokładnie z lockfile przez `nvim --headless "+Lazy! restore" +qa`. Restore może od razu uruchomić hooki DBee i Dbout, więc Go 1.26.6, `cc`, `govulncheck`, `node` oraz `npm` muszą już być na `PATH` tego procesu.
6. Zainstaluj narzędzia Mason: `lua-language-server pyright ruff typescript-language-server html-lsp css-lsp dockerfile-language-server docker-compose-language-service stylua mypy debugpy delve js-debug-adapter`.
7. Dla Claude opcjonalnie zainstaluj `@anthropic-ai/claude-code` i wykonaj pierwsze logowanie poleceniem `claude`.
8. Dla Distant zapewnij lokalne `~/.local/bin/distant`. Skonfigurowany przepływ `DistantLaunch` wymaga także `/home/ukibbb/.local/bin/distant` na hoście; bezpośredni `DistantConnect ssh://...` może nie wymagać zdalnej instalacji. Używane binaria powinny należeć do zgodnej linii 0.20.x.

## Executable według funkcji

- **bootstrap i Git UI**: `git`.
- **ekosystem JavaScript**: `node` uruchamia Pyright, HTML/CSS, Docker/Compose LSP, `js-debug-adapter` oraz backend Dbout; `npm` instaluje ich pakiety i wykonuje build Dbout.
- **Telescope**: `rg`, `fd`; `fzf` jest potrzebne przez tmux-fzf.
- **tmux-fzf**: GNU `bash`, `sed`, `fzf`; opcjonalnie `pstree` i CopyQ.
- **format Lua/Python**: `stylua`, `ruff`.
- **lint Python**: `mypy`.
- **LSP**: executable wymienione w [sekcji nvim-lspconfig](../plugins/03-lsp-completion-snippets-autopairs.md#plugin-nvim-lspconfig); Node dla serwerów JS oraz projektowy `typescript` dla TS.
- **DAP Python**: `debugpy-adapter`.
- **DAP Go**: `dlv` z pakietu Mason `delve`.
- **DAP JS/TS/Chrome**: `node`, `js-debug-adapter`; Chrome z remote debugging dla attach.
- **parsery Treesitter**: `curl`, `tar`, kompilator C/C++ i `tree-sitter >= 0.26.1`; lokalna lista instaluje także `sql` dla DBee/Dbout oraz `json` dla Dbout.
- **nvim-dbee**: dokładnie Go 1.26.6, `cc`, Git i `govulncheck` podczas instalacji, aktualizacji lub jawnego rebuildu. Hook odrzuca inny toolchain, niezgodny HEAD, zmodyfikowane źródła albo zły hash osadzony w kandydacie. Dopiero po skanie atomowo podmienia `stdpath("data")/dbee/bin/dbee`; błąd zachowuje poprzedni przeskanowany backend. Klient CLI konkretnej bazy nie jest potrzebny.
- **dbout.nvim**: `npm` podczas wykonywanego przez Lazy `npm ci`, a `node` w runtime do uruchomienia `server/main.js`. Nie są wymagane `psql`, `mysql`, `sqlite3`, `sqlcmd` ani `mongosh`, ponieważ połączenia realizują pakiety Node.
- **vim-dadbod, DBUI i completion**: co najmniej jeden klient odpowiadający adapterowi. Lokalny zestaw to `psql` dla PostgreSQL, `mysql` dla MySQL/MariaDB, `sqlite3` dla SQLite, `duckdb` dla DuckDB i `sqlcmd` dla SQL Server. DBUI i completion nie zastępują tych executable.
- **dadbod-grip.nvim**: ten sam zestaw `psql`, `mysql`, `sqlite3`, `duckdb`, `sqlcmd`. SQL Server ma tylko read-only grid, choć query pad nadal może wysłać DML/DDL. Telescope jest lokalnym backendem prostych pickerów.
- **wayfinder.nvim**: `rg` dla tekstowych referencji, `git` dla historii i najlepszej ścieżki wykrywania testów oraz opcjonalny klient LSP dołączony do bieżącego bufora dla definicji, semantycznych referencji i incoming callers.
- **CodeDiff**: `curl` albo `wget` do pierwszego pobrania biblioteki natywnej.
- **Distant**: `ssh`, lokalny `distant`; zdalny `distant` dla skonfigurowanego Launch.
- **vim-tmux-navigator**: Bash, `ps`, `grep`, tmux i Neovim/Vim.
- **claude.nvim**: uwierzytelnione `claude` CLI i sieć do backendu.

`.zshrc` wykrywa Homebrew pod `/opt/homebrew` albo `/usr/local`, ładuje `brew shellenv` i wylicza aktywny prefix dla keg-only `libpq/bin`, `mysql-client/bin` i `sqlite/bin`. Dodaje też `~/.local/share/nvim/mason/bin`, środowisko NVM, Bun i OpenCode. Po zmianie uruchom nową powłokę albo `source ~/.zshrc`. `stty -ixon` uwalnia `Ctrl-s` od terminalowego XOFF; tmux nadal używa tego klawisza jako prefixu.

## Stan lokalny i sekrety

- **DBee**: profile FileSource trafiają do `stdpath("state")/dbee/persistence.json`, notatki do `stdpath("state")/dbee/notes/`, log do `stdpath("cache")/dbee/dbee.log`, a utwardzony call log i wyniki do `stdpath("state")/dbee/backend/call-log.json` oraz `stdpath("state")/dbee/backend/history/`. Backend wymusza prywatne prawa POSIX dla własnego state, ale profile, notatki, logi i eksporty pozostają osobnymi plikami mogącymi zawierać dane poufne.
- **Dbout**: pełne connection stringi są zapisywane jawnym tekstem w `stdpath("state")/dbout/db_explorer.json`, pokazywane w pickerach i mogą trafić z `input()` do historii ShaDa. Wtyczka nie ma secret store ani ekspansji zmiennych środowiskowych.
- **Dadbod UI**: globalne profile i zapisane query trafiają pod `stdpath("data")/db_ui/`, w tym plaintext `connections.json`. `input()` i command-line mogą utrwalić URL w historii oraz ShaDa.
- **Dadbod Grip**: centralne profile trafiają do `stdpath("state")/dadbod-grip/connections.json`, ale historia, filtry i zapisane query mogą trafić do projektowego `.grip/`. Root tego repo ignoruje `.grip/`; inne projekty wymagają własnej reguły. `${VAR}` i `env_file` są rozwijane tylko przez Grip.
- **Wayfinder**: nazwane Traile są zapisywane per projekt w `stdpath("state")/wayfinder/trails/{sha256(root)}.json`; roboczy Trail bez jawnego save pozostaje tylko w pamięci.
- **Marki**: natywne marki mogą przetrwać przez ShaDa, natomiast bookmarki `marks.nvim`, ich extmarki i adnotacje są wyłącznie sesyjne i nie trafiają do pliku sesji ani osobnego storage.
- **Repozytorium**: nie zawiera rzeczywistych loginów, haseł, tokenów ani gotowych profili baz i nie należy dodawać do niego powyższych plików stanu, eksportów lub logów. Sekrety przekazuj poza repo przez mechanizm właściwy klientowi, środowisko albo zaufany secret manager i zawsze używaj minimalnych uprawnień.

## Co jest, a czego nie ma w lockfile

- `nvim/lazy-lock.json` przypina 49 zewnętrznych wtyczek Neovim do pełnych hashy Git.
- `watchdiff.nvim` i `claude.nvim` są ładowane z katalogów tego repo i nie mają osobnych wpisów lockfile.
- `tmux.conf` zapisuje tylko trzy identyfikatory repozytoriów TPM, bez commitów. Aktualny commit instalacji tmux jest więc stanem lokalnym, nie gwarancją odtworzenia.
- Homebrew i Mason nie są tu przypięte do wersji. `brew bundle` oraz ręczna lista Mason odtwarzają zestaw, ale nie historyczne wydania narzędzi.
