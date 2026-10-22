# DAP: klient, UI, virtual text, Python i Go

<a id="plugin-nvim-dap"></a>
## `nvim-dap`

Debugger w Neovim (Debug Adapter Protocol): breakpointy, kroki, stos, REPL. Skonfigurowane języki: Python (`debugpy`), Go (`delve`) oraz JS/TS/React przez `js-debug-adapter` (Node i Chrome).

- **`F5`** / **`<leader>dc`**: start sesji (wybór konfiguracji) albo kontynuuj.
- **`F10`**: step over; **`F11`**: step into; **`F12`**: step out.
- **`<leader>db`**: przełącz breakpoint; **`<leader>dB`**: breakpoint warunkowy (pyta o wyrażenie).
- **`<leader>dn`**: debuguj najbliższy test (Python i Go).
- **`<leader>dl`**: uruchom ponownie ostatnią konfigurację.
- **`<leader>dp`**: pauza; **`<leader>dt`**: zakończ sesję.
- **`<leader>dr`**: przełącz REPL.
- **`:DapClearBreakpoints`**: usuń wszystkie breakpointy.

### Jak używać

1. Uruchom Neovim w roocie projektu.
2. Ustaw breakpoint `<leader>db`.
3. `F5` i wybierz konfigurację (np. `file` w Pythonie, `Debug` w Go, `Launch current file with Node` w JS/TS).
4. Po zatrzymaniu: `F10`/`F11`/`F12`, `F5` aby kontynuować, `<leader>de` aby sprawdzić wartość.
5. `<leader>dt` kończy sesję.

Konfiguracje projektu można też dodać w `.vscode/launch.json` (szukany tylko w bieżącym katalogu). JS/TS: `Launch Chrome` pyta o URL (domyślnie `http://localhost:3000`), `Attach to Chrome` wymaga Chrome z remote debugging na porcie `9222`.

Problemy: `:checkhealth dap`, `:DapShowLog`.

<a id="plugin-nvim-dap-ui"></a>
## `nvim-dap-ui`

Panele debuggera: Scopes, Stacks, Breakpoints, Watches po prawej oraz REPL i Console na dole. Otwierają się same na start sesji i zamykają po jej końcu.

- **`<leader>du`**: ukryj/pokaż panele (sesja trwa dalej).
- **`<leader>de`**: oceń wyrażenie pod kursorem albo zaznaczenie.
- W panelach: **`Enter`** rozwiń zmienną, **`o`** przejdź do ramki/breakpointu, **`e`** edytuj wartość, **`d`** usuń watch/breakpoint, **`r`** wyślij do REPL.
- Watches: wejdź w Insert w panelu, wpisz wyrażenie i `Enter`.
- Console służy do wejścia/wyjścia programu (stdin), REPL do wyrażeń debuggera.

<a id="plugin-nvim-dap-virtual-text"></a>
## `nvim-dap-virtual-text`

Pokazuje wartości zmiennych obok kodu (jako komentarz) podczas zatrzymania debuggera. Działa samo.

- **`:DapVirtualTextToggle`**: wyłącz/włącz.

Po kontynuacji wartości mogą zostać na ekranie — to ostatni stan, nie wartości na żywo.

<a id="plugin-nvim-dap-python"></a>
## `nvim-dap-python`

Debugowanie Pythona przez `debugpy-adapter` (z Masona). Interpreter programu bierze z aktywnego venv (`VIRTUAL_ENV`, `.venv` w projekcie).

- **`<leader>dn`**: debuguj metodę testową pod kursorem (pytest/unittest/Django).
- Konfiguracje pod `F5`: `file`, `file:args` (pyta o argumenty), `attach` (do debugpy na `127.0.0.1:5678`).

**Uwaga:** aktywuj venv przed uruchomieniem Neovim, inaczej importy projektu nie zadziałają.

<a id="plugin-nvim-dap-go"></a>
## `nvim-dap-go`

Debugowanie Go przez Delve (`dlv` musi być w `PATH`).

- **`<leader>dn`**: debuguj test (lub subtest `t.Run("...")`) pod kursorem.
- Konfiguracje pod `F5`: `Debug` (plik), `Debug Package`, `Debug (Arguments)`, `Attach` (wybór procesu), `Debug test`.
