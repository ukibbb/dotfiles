<a id="wymagania"></a>
# Wymagania i środowisko

## Wersje bazowe sprawdzone lokalnie

- **macOS + WezTerm**: **Wersja/stan:** konfiguracja repo dla WezTerm. **Dlaczego ma znaczenie:** True color, synchronized output i extended keys CSI-u.
- **Neovim**: **Wersja/stan:** `v0.12.4`, LuaJIT. **Dlaczego ma znaczenie:** nowe API LSP i gałąź `main` nvim-treesitter.
- **tmux**: **Wersja/stan:** `3.6a`. **Dlaczego ma znaczenie:** [lista domyślnych mapowań tmux](../03-tmux.md#tmux) odpowiada tej wersji.
- **zsh + Oh My Zsh**: **Wersja/stan:** shell użytkownika. **Dlaczego ma znaczenie:** ładuje `PATH`, NVM i wyłącza XON/XOFF.
- **WezTerm keybindings**: **Wersja/stan:** mapowania `Cmd` w `wezterm.lua`. **Dlaczego ma znaczenie:** fizyczne `Cmd-h/j/k/l/q`, `Cmd-\`, `Cmd--` i `Cmd-n` do kodów terminalowych.
- **Nerd Font Symbols**: **Wersja/stan:** dołączone do WezTerm jako fallback. **Dlaczego ma znaczenie:** poprawne ikony NvChad, drzewa, Git, DAP i Markdown.

## Instalacja warstw

1. W katalogu repo uruchom `brew bundle --file Brewfile`. Deklarowane są: Neovim, tree-sitter-cli, tmux, fzf, fd, ripgrep, jq, stylua, ruff i WezTerm.
2. Zainstaluj NVM oraz domyślne Node LTS zgodnie z [głównym README repozytorium](../../README.md#fresh-mac-setup); Node uruchamia część serwerów Mason i adapter JS/TS.
3. Utwórz dowiązania przez `bash install.sh install` i sprawdź je przez `bash install.sh status`. Instalator wykonuje timestampowane backupy zastępowanych celów.
4. Sklonuj TPM do `~/.tmux/plugins/tpm`, wczytaj konfigurację przez `tmux source-file "$HOME/.tmux.conf"`, a wewnątrz tmux naciśnij `Ctrl-s I`.
5. Odtwórz wtyczki Neovim dokładnie z lockfile przez `nvim --headless "+Lazy! restore" +qa`.
6. Zainstaluj narzędzia Mason: `lua-language-server pyright ruff typescript-language-server html-lsp css-lsp dockerfile-language-server docker-compose-language-service stylua mypy debugpy delve js-debug-adapter`.
7. Dla Claude opcjonalnie zainstaluj `@anthropic-ai/claude-code` i wykonaj pierwsze logowanie poleceniem `claude`.
8. Dla Distant zapewnij lokalne `~/.local/bin/distant`. Skonfigurowany przepływ `DistantLaunch` wymaga także `/home/ukibbb/.local/bin/distant` na hoście; bezpośredni `DistantConnect ssh://...` może nie wymagać zdalnej instalacji. Używane binaria powinny należeć do zgodnej linii 0.20.x.

## Executable według funkcji

- **bootstrap i Git UI**: `git`.
- **runtime narzędzi opartych na JavaScript**: `node`, `npm`; wymagane przez Pyright, HTML/CSS, Docker/Compose LSP oraz `js-debug-adapter`.
- **Telescope**: `rg`, `fd`; `fzf` jest potrzebne przez tmux-fzf.
- **tmux-fzf**: GNU `bash`, `sed`, `fzf`; opcjonalnie `pstree` i CopyQ.
- **format Lua/Python**: `stylua`, `ruff`.
- **lint Python**: `mypy`.
- **LSP**: executable wymienione w [sekcji nvim-lspconfig](../plugins/03-lsp-completion-snippets-autopairs.md#plugin-nvim-lspconfig); Node dla serwerów JS oraz projektowy `typescript` dla TS.
- **DAP Python**: `debugpy-adapter`.
- **DAP Go**: `dlv` z pakietu Mason `delve`.
- **DAP JS/TS/Chrome**: `node`, `js-debug-adapter`; Chrome z remote debugging dla attach.
- **parsery Treesitter**: `curl`, `tar`, kompilator C/C++ i `tree-sitter >= 0.26.1`.
- **CodeDiff**: `curl` albo `wget` do pierwszego pobrania biblioteki natywnej.
- **Distant**: `ssh`, lokalny `distant`; zdalny `distant` dla skonfigurowanego Launch.
- **vim-tmux-navigator**: Bash, `ps`, `grep`, tmux i Neovim/Vim.
- **claude.nvim**: uwierzytelnione `claude` CLI i sieć do backendu.

`.zshrc` dodaje do `PATH` między innymi `~/.local/share/nvim/mason/bin`, środowisko NVM, Bun i OpenCode. Po zmianie uruchom nową powłokę albo `source ~/.zshrc`. `stty -ixon` uwalnia `Ctrl-s` od terminalowego XOFF; tmux nadal używa tego klawisza jako prefixu.

## Co jest, a czego nie ma w lockfile

- `nvim/lazy-lock.json` przypina 41 zewnętrznych wtyczek Neovim do pełnych hashy Git.
- `watchdiff.nvim` i `claude.nvim` są ładowane z katalogów tego repo i nie mają osobnych wpisów lockfile.
- `tmux.conf` zapisuje tylko trzy identyfikatory repozytoriów TPM, bez commitów. Aktualny commit instalacji tmux jest więc stanem lokalnym, nie gwarancją odtworzenia.
- Homebrew i Mason nie są tu przypięte do wersji. `brew bundle` oraz ręczna lista Mason odtwarzają zestaw, ale nie historyczne wydania narzędzi.
