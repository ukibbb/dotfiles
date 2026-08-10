# DAP: klient, UI, virtual text, Python i Go

<a id="plugin-nvim-dap"></a>
## `nvim-dap`

**Co robi i po co:** klient Debug Adapter Protocol. Steruje breakpointami, uruchomieniem, krokami, stosami, REPL i konfiguracjami adapterów.

**Ładowanie lokalne:** po dowolnym klawiszu DAP albo publicznym poleceniu DAP. Setup konfiguruje UI, virtual text, znaki breakpoint/stop, adaptery Python i Go oraz `pwa-node`/`pwa-chrome` przez `js-debug-adapter`.

**Aktywne lokalne:** `F5`, `F10`, `F11`, `F12`, `<leader>db`, `<leader>dB`, `<leader>dc`, `<leader>de` w `n,x`, `<leader>dn`, `<leader>dp`, `<leader>dl`, `<leader>dr`, `<leader>dt`, `<leader>du`. Sam upstream nie instaluje domyślnych klawiszy.

**Polecenia przypiętej wersji:** `:DapSetLogLevel`, `:DapShowLog`, `:DapContinue`, `:DapToggleBreakpoint`, `:DapClearBreakpoints`, `:DapToggleRepl`, `:DapStepOver`, `:DapStepInto`, `:DapStepOut`, `:DapPause`, `:DapTerminate`, `:DapDisconnect`, `:DapRestartFrame`, `:DapNew`, `:DapEval`.

**Konfiguracje JS/TS lokalne:** Launch current file with Node, attach do procesu Node wybranego z listy, launch Chrome pod wpisanym URL i attach Chrome pod portem. Filetype: `javascript`, `javascriptreact`, `typescript`, `typescriptreact`. Source maps są włączone, a node internals i `node_modules` pomijane przy krokach.

**`launch.json`:** nvim-dap tej rewizji ma provider, który na żądanie czyta dokładnie `${cwd}/.vscode/launch.json`; nie szuka w katalogach nadrzędnych. `${workspaceFolder}` również oznacza bieżący CWD Neovim. Lokalne aliasy adapterów to `pwa-node` i `pwa-chrome`. Nie trzeba wywoływać starego loadera Lua.

**Wymagania:** co najmniej jeden adapter w `PATH`; poprawna konfiguracja projektu; dla browser attach Chrome uruchomiony z remote debugging.

### Mentalny model

- `nvim-dap` jest klientem protokołu i zarządza sesją.
- Adapter (`debugpy-adapter`, `dlv`, `js-debug-adapter`) tłumaczy DAP na protokół debuggera.
- Debugger kontroluje docelowy proces. Błąd na każdej warstwie daje inny objaw.
- Konfiguracja launch/attach musi mieć co najmniej `type`, `request` i `name`; pozostałe pola są specyficzne dla adaptera.

### Cykl życia `F5`

1. Bez sesji `F5` zbiera konfiguracje i prosi o wybór.
2. W zatrzymanej sesji `F5` kontynuuje.
3. W uruchomionej lub inicjalizowanej sesji pokazuje menu: pause, terminate, restart, disconnect, nowa sesja albo anulowanie.
4. `<leader>dt` kończy domyślnie fokusowaną sesję i zwykle proces debugowany. `:DapDisconnect` odłącza z `terminateDebuggee=false`, gdy adapter to wspiera.
5. `:DapNew` wymusza kolejną sesję. `<leader>dl` ponawia ostatnią konfigurację, także utworzoną przez helper testu Python/Go.

Breakpointy są przechowywane w pamięci Neovim między sesjami, ale nie są lokalnie zapisywane na dysku.

### Tutorial: pierwsza sesja

1. Uruchom Neovim w root projektu, sprawdź `:pwd`, `:set filetype?` i executable adaptera.
2. Ustaw zwykły breakpoint `<leader>db`; warunkowy `<leader>dB` pyta o wyrażenie w języku programu.
3. Naciśnij `F5`, wybierz launch lub attach i poczekaj na zatrzymanie. Odrzucony breakpoint ma osobny znak.
4. Użyj `F10` step over, `F11` step into, `F12` step out, `F5` continue i `<leader>dp` pause.
5. `<leader>de` w Normal ocenia wyrażenie pod kursorem, a w Visual zaznaczenie przez dap-ui.
6. `<leader>dr` otwiera REPL, `<leader>du` przełącza panele, `<leader>dt` kończy sesję.

### Breakpointy i kroki dostępne bez lokalnego skrótu

- **hit condition**: **Sposób użycia:** `:lua require('dap').set_breakpoint(nil, vim.fn.input('Hit condition: '))`. **Stan:** **Opcjonalne upstream**; składnia adaptera.
- **logpoint**: **Sposób użycia:** `:lua require('dap').set_breakpoint(nil, nil, vim.fn.input('Log message: '))`. **Stan:** **Opcjonalne upstream**; `{variable}` zależy od adaptera.
- **exception filters**: **Sposób użycia:** `:lua require('dap').set_exception_breakpoints()`. **Stan:** **Opcjonalne upstream**.
- **run to cursor**: **Sposób użycia:** `:lua require('dap').run_to_cursor()`. **Stan:** **Opcjonalne upstream**.
- **reverse continue / step back**: **Sposób użycia:** API `reverse_continue()` / `step_back()`. **Stan:** **Kontekstowe**, tylko gdy adapter wspiera reverse debugging.
- **restart frame**: **Sposób użycia:** `:DapRestartFrame`. **Stan:** **Polecenie**, zależne od adaptera.

`goto_()` skacze bez wykonania kodu po drodze, więc nie jest odpowiednikiem run-to-cursor. `:DapEval` tworzy edytowalny bufor `dap-eval://`, którego treść jest oceniana przy `:write`; nie jest tym samym co lokalne `<leader>de`.

### Konfiguracje dostępne po lokalnym setup

- **Python**: `file`, `file:args`, `attach`, `file:doctest`.
- **Go**: `Debug`, `Debug (Arguments)`, `Debug (Arguments & Build Flags)`, `Debug Package`, `Attach`, `Debug test`, `Debug test (go.mod)`.
- **JS/TS/React**: `Launch current file with Node`, `Attach to Node process`, `Launch Chrome`, `Attach to Chrome`.

`file:doctest` ma `noDebug=true`, więc uruchamia doctest bez zwykłego zatrzymywania na breakpointach. Lokalne `skipFiles` dotyczy dwóch konfiguracji Node, nie Chrome.

### Tutorial: Node, TypeScript i Chrome

1. `Launch current file with Node` przekazuje `${file}` bez kompilacji. Samo `sourceMaps=true` nie uruchomi surowego TypeScript, jeśli runtime projektu go nie obsługuje.
2. `Attach to Node process` wybiera proces z listy; na macOS wymaga działającego `ps` i właściwych uprawnień.
3. `Launch Chrome` pyta o URL, domyślnie `http://localhost:3000`. `Attach to Chrome` wymaga procesu Chrome z remote debugging, domyślnie port `9222`.
4. Dla kompilowanego TS dodaj projektowe `outFiles` i program JavaScript do `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "pwa-node",
      "request": "launch",
      "name": "Launch compiled TypeScript",
      "program": "${workspaceFolder}/dist/index.js",
      "cwd": "${workspaceFolder}",
      "sourceMaps": true,
      "outFiles": ["${workspaceFolder}/dist/**/*.js"]
    }
  ]
}
```

Provider obsługuje `configurations`, `inputs` typu `promptString`/`pickString` oraz systemowe overrides. Nie implementuje VS Code tasks ani compounds, a JSON nie może zawierać trailing comma. Typ musi odpowiadać lokalnemu adapterowi, na przykład `pwa-node`, `pwa-chrome`, `python`, `debugpy` albo `go`.

### Diagnostyka warstwowa

1. Załaduj DAP dowolnym skrótem i uruchom `:checkhealth dap`.
2. Sprawdź adaptery: `:lua =vim.tbl_keys(require('dap').adapters)`.
3. Sprawdź konfiguracje bieżącego filetype: `:lua =vim.tbl_map(function(c) return c.name end, require('dap').configurations[vim.bo.filetype] or {})`.
4. Dla `launch.json`: `:pwd` i `:lua =require('dap.ext.vscode').getconfigs()`.
5. Ustaw `:DapSetLogLevel TRACE`, odtwórz błąd i otwórz `:DapShowLog`. W REPL `.capabilities` pokazuje funkcje adaptera.

**Źródła przypiętej rewizji:** [README](https://github.com/mfussenegger/nvim-dap/blob/9e848e09a697ee95302a3ef2dd43fd6eb709e570/README.md), [pełny help](https://github.com/mfussenegger/nvim-dap/blob/9e848e09a697ee95302a3ef2dd43fd6eb709e570/doc/dap.txt), [provider `launch.json`](https://github.com/mfussenegger/nvim-dap/blob/9e848e09a697ee95302a3ef2dd43fd6eb709e570/lua/dap/ext/vscode.lua).

<a id="plugin-nvim-dap-ui"></a>
## `nvim-dap-ui`

**Co robi i po co:** panele Scopes, Stacks, Breakpoints, Watches po prawej oraz REPL i Console na dole. Lokalny listener otwiera UI, gdy sesja staje się aktywna, i zamyka dopiero po zniknięciu ostatniej sesji; `<leader>du` pozwala przełączyć ręcznie.

**Konfiguracja lokalna:** prawa kolumna szerokości 40 z proporcjami 0.40/0.25/0.20/0.15, dolny panel wysokości 10 i rounded border dla floatów.

- **`Enter` / `2-LeftMouse`**: Rozwinięcie dzieci. **Element UI:** zmienna/watch. **Stan:** **Kontekstowe**.
- **`o`**: Przejście do lokalizacji. **Element UI:** stack frame. **Stan:** **Kontekstowe**.
- **`d`**: Usunięcie watcha lub włączonego breakpointu. **Element UI:** watch/breakpoint. **Stan:** **Kontekstowe**.
- **`e`**: Edycja wartości lub wyrażenia. **Element UI:** zmienna/watch. **Stan:** **Kontekstowe**.
- **`r`**: Wysłanie do REPL. **Element UI:** zmienna/watch. **Stan:** **Kontekstowe**.
- **`t`**: Przełączenie subtelnych ramek albo enabled breakpointu. **Element UI:** stack/breakpoint. **Stan:** **Kontekstowe**.
- **`q` / `Esc`**: Zamknięcie floata. **Element UI:** floating element. **Stan:** **Domyślne wtyczki**.

Nie ma domyślnego `w` dodającego dowolne wyrażenie w panelu Watches. W Watches wejdź do Insert, wpisz wyrażenie w prompt i zatwierdź `Enter`. Kod tej rewizji ma osobną kontekstową akcję `watch` pod `w` na zmiennej w Scopes; wysyła istniejącą zmienną do Watches, a nie otwiera promptu „add watch”.

Wtyczka nie rejestruje poleceń Ex; `require("dapui").open()` i podobne nazwy są API Lua.

**Wymagania:** `nvim-dap` i `nvim-nio`.

### Co pokazuje każdy panel

- **Scopes**: Zmienne aktualnie wybranej ramki stosu.
- **Stacks**: Wątki i ramki; `o` wybiera ramkę i zmienia kontekst Scopes/eval.
- **Breakpoints**: Lista breakpointów; `t` przełącza enabled, `o` skacze, `d` usuwa włączony.
- **Watches**: Wyrażenia oceniane przy zatrzymaniu; prompt znajduje się bezpośrednio w panelu.
- **REPL**: Wyrażenia debuggera, komendy DAP, frames/threads/scopes i output adaptera.
- **Console**: Zintegrowany terminal/stdin procesu dla konfiguracji z `integratedTerminal`.

REPL i Console nie są zamienne. W Console wejdź do trybu terminalowego/Insert, aby odpowiedzieć programowi. W REPL wpisuj wyrażenia lub komendy `.help`, `.frames`, `.threads`, `.scopes`, `.capabilities`, `.c`, `.n`, `.into`, `.out`, `.up`, `.down`, `.pause`.

### Tutorial: scope, stack i watch

1. Zatrzymaj program. Rozwiń obiekt w Scopes przez `Enter` i przejdź do jego dzieci.
2. `r` wysyła zmienną do REPL, a `w` jest dostępne tylko dla odpowiednich zmiennych z `evaluateName` i dodaje właśnie tę zmienną do Watches.
3. W Stacks ustaw kursor na innej ramce i `o`; Scopes i ocena powinny przełączyć kontekst.
4. W Watches naciśnij `i`, wpisz `object.field`, zatwierdź `Enter`, wróć `Esc`. W Normal `e` edytuje wyrażenie, `d` usuwa, `r` wysyła do REPL.
5. Watch pozostaje między sesjami w bieżącym życiu pluginu, ale nie jest utrwalany po restarcie Neovim.

### Eval, floaty i sterowanie sesją

- `<leader>de` w Normal ocenia `<cexpr>`, a w Visual zaznaczenie. Domyślny kontekst `hover` ma ograniczać skutki uboczne; niektóre adaptery wymagają kontekstu REPL.
- `q`/`Esc` zamyka float, nie całą sesję. `<leader>du` chowa/pokazuje layout bez zatrzymania programu.
- REPL ma klikalny winbar z play/pause, krokami, run last, terminate i disconnect. Klawiaturowe skróty globalne pozostają pewniejsze.
- **Opcjonalne upstream API:** `dapui.open({layout=1})`, `close`, `float_element('scopes')`, `elements.watches.add(...)`; repo nie mapuje tych wywołań.

**Diagnostyka:** jeśli sesja działa bez paneli, użyj `<leader>du`, `:messages` i sprawdź `nvim-dap-ui` oraz `nvim-nio` w Lazy. Akcja na wierszu bez obsługi wypisuje „No ... action for current line”; nie oznacza awarii całego panelu.

**Źródła przypiętej rewizji:** [README](https://github.com/rcarriga/nvim-dap-ui/blob/cc9dd33aade7f20bae414d0cba163bc60d4d4b43/README.md), [pełny help](https://github.com/rcarriga/nvim-dap-ui/blob/cc9dd33aade7f20bae414d0cba163bc60d4d4b43/doc/nvim-dap-ui.txt), [domyślne mapowania elementów](https://github.com/rcarriga/nvim-dap-ui/blob/cc9dd33aade7f20bae414d0cba163bc60d4d4b43/lua/dapui/config/init.lua).

<a id="plugin-nvim-dap-virtual-text"></a>
## `nvim-dap-virtual-text`

**Co robi i po co:** pokazuje wartości zmiennych obok kodu podczas zatrzymania. Lokalnie `commented=true`, więc tekst wygląda jak komentarz.

**Mapowania:** brak. **Polecenia po załadowaniu nadrzędnego DAP:** `:DapVirtualTextEnable`, `:DapVirtualTextDisable`, `:DapVirtualTextToggle`, `:DapVirtualTextForceRefresh`. Na całkiem świeżym starcie nie są triggerami Lazy i pojawią się dopiero po użyciu skrótu lub polecenia `nvim-dap`.

**Wymagania:** zatrzymana ramka z realną ścieżką źródła, załadowane scopes/variables, parser Treesitter i query `locals` dla języka.

### Tutorial: wartości inline

1. Zatrzymaj program i najpierw sprawdź, czy panel Scopes zawiera zmienne.
2. Wartości pojawiają się przy węzłach definicji znalezionych przez query `locals`; `commented=true` formatuje je przy użyciu `commentstring` filetype.
3. Wykonaj krok i porównaj highlight wartości zmienionych względem poprzedniego zatrzymania.
4. Po continue tekst może pozostać widoczny, bo aktywny default `clear_on_continue=false`; to ostatni snapshot, nie wartość live.
5. `:DapVirtualTextToggle` przełącza, a `ForceRefresh` czyści i buduje od nowa, gdy adapter ominął typowe zdarzenie.

Domyślnie widoczna jest bieżąca ramka, pierwsza definicja i bez wszystkich referencji. `all_frames`, `all_references`, `virt_lines` oraz custom `display_callback` są **Opcjonalnym upstream**, nie aktywnym stanem.

**Diagnostyka:** gdy Scopes działa, ale tekst nie, sprawdź parser i query: `:lua =pcall(vim.treesitter.get_parser, 0)` oraz `:lua =vim.treesitter.query.get(vim.treesitter.language.get_lang(vim.bo.filetype), 'locals')`. Brak source path lub scopes powoduje cichy brak tekstu.

**Źródła przypiętej rewizji:** [README i opcje](https://github.com/theHamsta/nvim-dap-virtual-text/blob/fbdb48c2ed45f4a8293d0d483f7730d24467ccb6/README.md), [implementacja i polecenia](https://github.com/theHamsta/nvim-dap-virtual-text/blob/fbdb48c2ed45f4a8293d0d483f7730d24467ccb6/lua/nvim-dap-virtual-text.lua), [mapowanie zmiennych na Treesitter](https://github.com/theHamsta/nvim-dap-virtual-text/blob/fbdb48c2ed45f4a8293d0d483f7730d24467ccb6/lua/nvim-dap-virtual-text/virtual_text.lua).

<a id="plugin-nvim-dap-python"></a>
## `nvim-dap-python`

**Co robi i po co:** rejestruje debugpy, konfiguracje Python oraz debug testów unittest/pytest/django.

**Konfiguracja lokalna:** setup wskazuje executable `debugpy-adapter`. Interpreter programu/testu jest rozwiązywany między innymi z `VIRTUAL_ENV` lub `CONDA_PREFIX`. `<leader>dn` w Python uruchamia metodę testową nad kursorem.

**Mapowania i polecenia:** brak własnych defaultów i brak publicznych poleceń Ex. Lokalne `<leader>dn` wywołuje API test method.

**Wymagania:** aktywna konfiguracja wywołuje dokładnie `debugpy-adapter` z `PATH`. Inny interpreter z zainstalowanym `debugpy` nie jest automatycznym fallbackiem bez zmiany setup. Framework testowy musi być zainstalowany w środowisku docelowym.

### Adapter a interpreter programu

- Adapter to lokalny wrapper `debugpy-adapter`, zwykle z Masona.
- Interpreter targetu/testu jest rozwiązywany osobno: `VIRTUAL_ENV`, `CONDA_PREFIX`, opcjonalny resolver, potem `venv`, `.venv`, `env`, `.env` pod CWD/rootami.
- Plik `envFile` albo domyślne `./.env` może dostarczyć proste wartości `KEY=VALUE`.

### Konfiguracje Python

- **`file`**: Uruchom bieżący plik.
- **`file:args`**: Zapytaj o argumenty i uruchom plik.
- **`attach`**: Połącz z debugpy, domyślnie `127.0.0.1:5678`.
- **`file:doctest`**: Uruchom `python -m doctest`, ale z `noDebug=true`.

### Tutorial: program i attach

1. Aktywuj środowisko przed uruchomieniem Neovim i sprawdź `:echo executable('debugpy-adapter')`, `$VIRTUAL_ENV`, `$CONDA_PREFIX` oraz `:pwd`.
2. Ustaw breakpoint, `F5`, wybierz `file`; dla argumentów użyj `file:args`.
3. Przy błędnych importach odróżnij adapter od target interpretera. Działający adapter nie gwarantuje właściwych pakietów projektu.
4. `attach` wymaga już uruchomionego procesu debugpy nasłuchującego pod adresem; nie startuje aplikacji sam.

### Tutorial: najbliższy test

1. Ustaw kursor wewnątrz funkcji testowej i naciśnij `<leader>dn`.
2. Helper wybiera najbliższą definicję funkcji powyżej kursora i uwzględnia klasę; nie sprawdza, czy nazwa naprawdę oznacza test.
3. Runner jest wykrywany kolejno przez `pytest.ini`, `manage.py`, konfigurację pytest w `pyproject.toml`, a w pozostałych przypadkach unittest.
4. Sesja używa integrated terminal. Po udanym uruchomieniu `<leader>dl` ponawia wygenerowaną konfigurację.
5. `test_class()` i `debug_selection()` istnieją jako **Opcjonalne upstream API**, bez lokalnych mapowań.

**Diagnostyka:** zły test zwykle oznacza położenie kursora lub parser Python; błąd pytest/Django brak frameworka w target environment; unverified breakpoint może oznaczać path mapping, `justMyCode` albo niezaładowany moduł. Log DAP rozstrzyga, czy zawiódł adapter czy program.

**Źródła przypiętej rewizji:** [README](https://github.com/mfussenegger/nvim-dap-python/blob/1808458eba2b18f178f990e01376941a42c7f93b/README.md), [help](https://github.com/mfussenegger/nvim-dap-python/blob/1808458eba2b18f178f990e01376941a42c7f93b/doc/dap-python.txt), [konfiguracje i test discovery](https://github.com/mfussenegger/nvim-dap-python/blob/1808458eba2b18f178f990e01376941a42c7f93b/lua/dap-python.lua).

<a id="plugin-nvim-dap-go"></a>
## `nvim-dap-go`

**Co robi i po co:** rejestruje Delve, konfiguracje debug programu/testu/attach i odnajdywanie najbliższego testu przez Treesitter.

**Konfiguracja lokalna:** domyślne `require("dap-go").setup()`. `<leader>dn` dla filetype Go uruchamia nearest test.

**Mapowania i polecenia:** brak własnych aktywnych klawiszy i publicznych poleceń Ex. README pokazuje przykładowe mapowania debug test/last test, ale są **Przykładem nieaktywnym**.

**Wymagania:** `dlv` w `PATH` i parser Treesitter Go, który jest instalowany lokalnie.

### Konfiguracje Go

- **`Debug`**: Debug bieżącego pliku.
- **`Debug (Arguments)`**: Prompt prostych argumentów.
- **`Debug (Arguments & Build Flags)`**: Prompt argumentów i build flags.
- **`Debug Package`**: Debug katalogu bieżącego pliku.
- **`Attach`**: Wybór lokalnego procesu.
- **`Debug test`**: Test mode dla bieżącego pliku.
- **`Debug test (go.mod)`**: Test package względem CWD/modułu.

Prompty argumentów dzielą tekst po spacjach i nie implementują pełnego cytowania shell. Dla argumentu zawierającego spację użyj projektowej konfiguracji Lua/`launch.json`, zamiast zakładać obsługę cudzysłowów.

### Tutorial: program, package i attach

1. Otwórz moduł z jego root, sprawdź `:pwd`, `:echo executable('dlv')` i `dlv version` w powłoce.
2. Ustaw breakpoint i wybierz `F5 → Debug` dla pliku albo `Debug Package` dla pakietu.
3. `Attach` wybiera istniejący lokalny proces; wymaga uprawnień systemu do debugowania.
4. Build tags i flags ustawiaj jako build flags, nie zwykłe args Delve w trybie DAP.

### Tutorial: test i subtest

1. Ustaw kursor wewnątrz `Test...` z parametrem `*testing.T`/`*testing.M` albo obsługiwanego `t.Run("literal", ...)`.
2. `<leader>dn` buduje zakotwiczony wzorzec `-test.run` dla testu/subtestu i package na podstawie pliku względem CWD.
3. Helper nie obsługuje jako nearest test benchmarków, examples, fuzz ani dowolnych wrapperów.
4. `<leader>dl` ponawia ostatni wygenerowany test. `require('dap-go').debug_last_test()` istnieje, ale nie ma lokalnego mapowania.

**Diagnostyka:** brak testu oznacza zwykle zły CWD, kursor przed deklaracją, nieobsługiwaną sygnaturę albo brak parsera. Odrzucony breakpoint może wskazywać build tags lub plik niewłączony do kompilacji. Użyj TRACE logu DAP dla błędu `dlv dap`.

**Źródła przypiętej rewizji:** [README](https://github.com/leoluz/nvim-dap-go/blob/b4421153ead5d726603b02743ea40cf26a51ed5f/README.md), [help](https://github.com/leoluz/nvim-dap-go/blob/b4421153ead5d726603b02743ea40cf26a51ed5f/doc/nvim-dap-go.txt), [konfiguracje](https://github.com/leoluz/nvim-dap-go/blob/b4421153ead5d726603b02743ea40cf26a51ed5f/lua/dap-go.lua), [parser testów](https://github.com/leoluz/nvim-dap-go/blob/b4421153ead5d726603b02743ea40cf26a51ed5f/lua/dap-go-ts.lua).
