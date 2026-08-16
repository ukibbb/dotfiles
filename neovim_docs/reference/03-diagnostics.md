<a id="diagnostyka"></a>
# Diagnostyka

## Kontrola bazowa

```sh
bash install.sh status
nvim --version
tmux -V
git --version
command -v rg fd fzf jq stylua ruff tree-sitter gh govulncheck
command -v go node npm curl tar cc psql mysql sqlite3 duckdb sqlcmd
command -v lua-language-server pyright-langserver typescript-language-server mypy
command -v debugpy-adapter dlv js-debug-adapter distant claude
go version
cc --version
node --version
npm --version
```

Brak pojedynczego opcjonalnego executable nie musi blokować całego edytora. Przykładowo brak `mypy` wyłącza tylko lokalny lint Python, a brak `claude` tylko backend claude.nvim.

## Neovim nie startuje lub wtyczka się nie ładuje

1. Uruchom `nvim --headless "+checkhealth" +qa` i zwykłe `:messages`.
2. Otwórz `:Lazy`, sprawdź błędy i commit problematycznej wtyczki. Do bezpiecznego powrotu do lockfile służy `:Lazy! restore`.
3. Uruchom `:checkhealth lazy`; dla startupu użyj `:Lazy profile`.
4. Gdy zniknęły kolory UI, wykonaj `:lua require("base46").load_all_highlights()`; funkcja ładuje wynik od razu. Restart służy dopiero do sprawdzenia czystego startu.
5. Sprawdź nadpisanie klawisza przez `:verbose nmap <leader>gf` albo odpowiednie `:verbose imap`, `:verbose xmap`, `:verbose smap`.

## LSP, completion, format i parsery

- **brak klienta LSP**: `:checkhealth vim.lsp`, `:lua =vim.lsp.get_clients({bufnr=0})`.
- **brak konkretnego serwera**: `:echo executable('lua-language-server')` z właściwą nazwą executable.
- **TypeScript nie trafia do implementacji**: upewnij się, że klient nazywa się `ts_ls`, potem `:verbose nmap gS`.
- **completion bez LSP/importu**: `:CmpStatus`, sprawdź etykietę `[LSP]`, capabilities i root projektu.
- **formatter nie działa**: `:ConformInfo`, `:echo executable('stylua')`, `:echo executable('ruff')`.
- **mypy się nie uruchamia**: zapisz plik Python, sprawdź `:messages` i `:echo executable('mypy')`.
- **brak parsera**: `:TSLog`, `:TSInstall {język}`, potem `:InspectTree`.
- **stary parser po zmianie rewizji**: `:TSUpdate`.
- **render Markdown nie działa**: `:RenderMarkdown config`, `:RenderMarkdown debug`, sprawdź `markdown` i `markdown_inline`.

## Parsery SQL i JSON

1. Lokalna konfiguracja instaluje oba parsery. Po nieudanej instalacji wykonaj osobno `:TSInstall sql` i `:TSInstall json`, a po zmianie rewizji `:TSUpdate`.
2. W buforze SQL sprawdź `:setlocal filetype?`, `:lua =pcall(vim.treesitter.get_parser, 0, "sql")` i `:InspectTree`; dla Queryera MongoDB albo panelu JSON użyj odpowiednio `:lua =pcall(vim.treesitter.get_parser, 0, "json")`.
3. DBee wymaga parsera `sql` do wykonania instrukcji pod kursorem przez `Enter`. Normal/Visual `BB` nie korzysta z tego wyboru AST.
4. Dbout, Dadbod/DBUI i Grip używają parserów do wyglądu buforów, ale wykonują tekst przez własny backend albo CLI. Brak parsera nie wyjaśnia awarii procesu, połączenia ani klienta bazy.

## DBee: health, dokładny backend i stan

1. Załaduj wtyczkę przez `:Lazy load nvim-dbee`, a potem uruchom `:checkhealth dbee`. Oczekiwany raport zawiera `Binary version matches version of current HEAD.` oraz commit `6f2948a5bc958c0cb85c520c29953148663cd362`.
2. Odczytaj aktywną ścieżkę przez `:lua =vim.fn.stdpath("data") .. "/dbee/bin/dbee"` i sprawdź standardową instalację poleceniem `"$HOME/.local/share/nvim/dbee/bin/dbee" -version`. Wynik ma być dokładnie `6f2948a5bc958c0cb85c520c29953148663cd362`.
3. Gdy binarium nie istnieje albo hash jest inny, sprawdź dokładnie `go version` równe `go1.26.6`, czysty checkout w `:Lazy`, `cc --version`, `govulncheck -version` i pin, po czym wykonaj `:Lazy build nvim-dbee`. Hook sprawdza HEAD oraz czyste VCS metadata kandydata, skanuje go i dopiero po sukcesie atomowo zastępuje runtime; błąd zachowuje poprzedni przeskanowany plik.
4. Hash manifestowego prebuilda `af5075f31ede9e7d76c87babdee0f70340061660` może przejść upstreamowy healthcheck, ale nie spełnia lokalnej polityki dokładnego builda z locka. W takim przypadku również wykonaj rebuild i ponów kontrolę wersji.
5. Sprawdź bez wypisywania zawartości `:lua =vim.fn.stdpath("state") .. "/dbee/persistence.json"`, `:lua =vim.fn.stdpath("state") .. "/dbee/notes"`, `:lua =vim.fn.stdpath("state") .. "/dbee/backend"` oraz `:lua =vim.fn.stdpath("cache") .. "/dbee/dbee.log"`. Na POSIX backend directory ma mieć `0700`, a `call-log.json` i pliki archiwów `0600`.
6. Dla źródła środowiskowego sprawdź samą obecność przez `:lua =vim.env.DBEE_CONNECTIONS ~= nil`, a poprawność JSON bez drukowania DSN przez `:lua local v=vim.env.DBEE_CONNECTIONS; print(v == nil or pcall(vim.json.decode, v))`.
7. Jeśli prosty query działa, ale drawer nie pokazuje schematów, sprawdź osobno uprawnienia do katalogów systemowych bazy. `:messages` i log backendu mogą zawierać host, SQL lub dane; zredaguj je przed udostępnieniem.
8. Brak `psql`, `mysql`, `sqlite3` lub innego klienta bazy nie jest błędem DBee. Połączenia realizują sterowniki w binarium Go.
9. Po każdym rebuildzie ponów `govulncheck -mode=binary "$HOME/.local/share/nvim/dbee/bin/dbee"`. Oczekiwany kod to zero i `No vulnerabilities found`; źródłowy skan może dodatkowo poinformować o nieosiągalnym `GO-2026-5932` z `golang.org/x/crypto/openpgp`. Nie skracaj tego do stwierdzenia „zero podatności”.
10. Po migracji upewnij się, że nie działa stare binarium, a następnie ręcznie sprawdź i usuń należące do siebie legacy `/tmp/dbee-calllog.json` oraz `/tmp/dbee-history`. Fork celowo nie usuwa tych ścieżek automatycznie.

## Dbout: ręczna diagnostyka Node

1. Dbout nie implementuje `:checkhealth dbout` ani `:Dbout Health`. Zacznij od `:Lazy`, potwierdź commit `411e46041adeb8661e044f8421d8db5c56a9ef5d` i sprawdź błąd ostatniego `npm ci`.
2. `npm --version` musi działać w środowisku Lazy podczas instalacji, aktualizacji i `:Lazy build dbout.nvim`. W runtime sprawdź `:echo executable('node')` oraz `node --version`; dla przypiętego lockfile używaj Node 22 lub nowszego.
3. Załaduj wtyczkę przez `:Lazy load dbout.nvim`, potem odczytaj backend znaleziony przez runtimepath przez `:lua =vim.api.nvim_get_runtime_file('server/main.js', false)`. Pierwsza zwrócona ścieżka jest uruchamiana jako proces Node.
4. Otwórz lokalny launcher `<leader>Bo` albo `:Telescope dbout`, a następnie sprawdź techniczny stan joba przez `:lua =require('dbout.rpc').is_alive()`. Jeżeli picker jest otwarty, ale `Enter` nic nie robi, naciśnij `Esc`, ponieważ akcje rozszerzenia działają w Normal.
5. Samo `:Dbout` bez subkomendy uruchamia serwer, ale bez globalnego Snacks nie otwiera lokalnie UI. Do listy profili używaj Telescope, a mapowanie sprawdź przez `:verbose nmap <leader>Bo`.
6. Ścieżkę profili pokaż przez `:lua =vim.fn.stdpath("state") .. "/dbout/db_explorer.json"`. Nie drukuj ani nie publikuj tego pliku: zawiera pełne connection stringi jawnym tekstem, a błędny JSON może przerwać setup.
7. Pełny connection string jest także widoczny w pickerach i trafia z `input()` do historii, która może zostać zapisana w ShaDa. Po przypadkowym wpisaniu sekretu najpierw go unieważnij, usuń profil, wyczyść historię input przez `:call histdel('input')` we wszystkich właściwych instancjach i dopiero świadomie rozważ `:wshada!`, które nadpisuje cały stan ShaDa.
8. Dbout nie wymaga `sqlite3`, `psql`, `mysql`, `sqlcmd` ani `mongosh`; używa pakietów Node. Błędy RPC i stack procesu sprawdzaj w `:messages`, ponieważ osobny trwały log nie istnieje.

## Dadbod i DBUI: klient, drawer i completion

1. Sprawdź piny `vim-dadbod`, `vim-dadbod-ui` i `vim-dadbod-completion` w `:Lazy`, potem `:verbose command DB`, `:verbose command DBUIToggle` i `:verbose nmap <leader>Bu`.
2. Dla adaptera sprawdź odpowiednio `:echo executable('psql')`, `mysql`, `sqlite3`, `duckdb` albo `sqlcmd`. DBUI może się otworzyć mimo braku klienta; błąd pojawi się dopiero przy metadanych lub query.
3. Odczytaj tylko ścieżkę profili przez `:lua =vim.fn.stdpath("data") .. "/db_ui/connections.json"`. Nie drukuj pliku ani `g:dbs`, bo mogą zawierać pełne URL-e.
4. W query DBUI sprawdź `:setlocal filetype?`, `:echo exists('b:dbui_db_key_name')`, `:verbose nmap <leader>Bs` i `:verbose nmap <leader>Bp`. `Bp` wymaga przypisania do DBUI, a `Bs` dodatkowo tymczasowego query z akcją save. Upstreamowe SQL `<leader>W/S/E` są lokalnie wyłączone.
5. Brak `[DB]` diagnozuj przez `:CmpStatus`, kontekst `b:db` i `:DBCompletionClearCache`. Provider ładuje się tylko dla `sql`, `mysql` i `plsql`.
6. Pamiętaj, że domyślne `g:db_ui_execute_on_save=1`; zapis bufora jest wykonaniem zapytania, nie wyłącznie operacją plikową.

## Dadbod Grip: health, CLI i stan

1. Załaduj Grip przez `<leader>Bg` albo `:GripConnect` i uruchom `:checkhealth dadbod-grip`. Brak klucza AI nie blokuje tej konfiguracji, ponieważ `ai=false`.
2. Sprawdź wybrany executable: `psql`, `mysql`, `sqlite3`, `duckdb` albo jawnie `sqlcmd`, którego health może nie uwzględnić we wszystkich ścieżkach.
3. Sprawdź aktywne opcje bez publikowania profili: `:lua local c=require('dadbod-grip').get_opts(); vim.print({completion=c.completion, connections_path=c.connections_path, discovery=c.discovery, picker=c.picker, ai_enabled=require('dadbod-grip.ai').is_enabled()})`. Oczekuj `true`, ścieżki pod `stdpath("state")`, `false`, `telescope`, `false`.
4. Centralny profil jest pod `stdpath("state")/dadbod-grip/connections.json`; projektowe historia, filtry i query mogą pozostać pod rozpoznanym rootem `.grip/`.
5. Puste completion w query padzie diagnozuj przez aktywne połączenie i `Ctrl-Spacja`, nie przez `[DB]` Dadbod ani globalny `:CmpStatus`.
6. Gdy Telescope nie otwiera tabel lub historii, sprawdź `:checkhealth telescope`. Połączenia i zapisane query używają złożonego pickera wbudowanego nawet przy `picker="telescope"`.
7. `discovery=false` wyłącza Docker, ale nie skan lokalnych plików w CWD. `mode="ro"` i read-only grid SQL Server nie blokują DML wpisanego ręcznie w query padzie.

## Wayfinder: źródła, scope i Trail

1. Najpierw załaduj wtyczkę przez `<leader>Wf`, dowolne polecenie `:Wayfinder...` albo `:Lazy load wayfinder.nvim`, potem uruchom `:checkhealth wayfinder`. Raport pokazuje `rg`, Git, klientów LSP, rozwiązany scope, project root i plik storage Trail.
2. Dla pustego `Calls` lub semantycznego `Refs` sprawdź `:checkhealth vim.lsp` oraz `:lua =vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients({bufnr=0}))`. Klient musi być dołączony do tego bufora i obsługiwać definition, references lub call hierarchy.
3. Dla tekstowych `[TXT]` sprawdź `:echo executable('rg')` i uruchom z rootu pokazanego przez health `rg --fixed-strings --word-regexp 'symbol' .`. Brak `rg` nie usuwa referencji LSP, ale wyłącza tekstową część `Refs`.
4. Dla `Git` i kandydatów testów sprawdź `:echo executable('git')`, `git rev-parse --show-toplevel`, `git ls-files -- .` i `git log -- ścieżka/do/pliku`. Nieśledzony plik może poprawnie nie mieć historii ani pojawić się w podstawowej liście testów.
5. Gdy wyników jest za dużo albo pochodzą ze złego katalogu, odczytaj `Resolved scope` i `Resolved project root` z health, a potem sprawdź bliższe markery `.git`, `package.json`, `go.mod`, `pyproject.toml`, `setup.py` lub `Cargo.toml`. Lokalny default to `scope.mode="project"`; definitions i incoming callers mogą mimo to wyjść poza scope.
6. Root nazwanych Trail to `stdpath("state")/wayfinder/trails/`, a dokładny plik projektu wskazuje health. Roboczy Trail jest tylko w pamięci; po restarcie użyj `:WayfinderTrailResume` albo `:WayfinderTrailLoad`, ponieważ samo `<leader>Ws` niczego nie wczytuje.
7. Przy `Saved Trail storage is invalid` zrób kopię dokładnego JSON-u wskazanego przez health przed naprawą. Po przeniesieniu repo sprawdź nowy hash projektu i absolutne ścieżki starych wpisów; wtyczka nie migruje ich automatycznie.
8. Zapisz bufor przed porównaniem wyników LSP z preview. Wayfinder pobiera część pozycji z bieżącego bufora, ale etykiety, testy i zwykły preview czytają pliki z dysku.

## marks.nvim: mapowania, znaki i trwałość

1. Wtyczka nie ma własnego healthchecka. Załaduj ją na przykład przez `:MarksListBuf` albo poczekaj na `VeryLazy`, następnie sprawdź `:verbose nmap m`, `:verbose nmap m,`, `:verbose nmap m[`, `:verbose nmap dm` i lokalne `:verbose nmap J`.
2. Porównaj natywny stan przez `:marks`, `:lua vim.print(vim.fn.getmarklist("%"))` i `:lua vim.print(vim.fn.getmarklist())`. Gdy cache lub znak pozostaje stary dłużej niż `250 ms`, wykonaj `:lua require("marks").refresh(true)`.
3. Dla niewidocznego znaku użyj `:set signcolumn?`, `:sign place` i `:highlight MarkSignHL`. Lokalnie `signcolumn=yes` mieści jedną komórkę, a małe, wielkie, builtinowe marki i bookmarki mają bez override jednakowy `sign_priority=10`.
4. Marka, bookmark, Gitsigns i DAP mogą konkurować o ten sam wiersz; przy równym priority kolejność między providerami nie jest kontraktem. Brak widocznego znaku nie oznacza braku pozycji, co potwierdza `:marks` albo odpowiednia lista.
5. Dla problemów po restarcie sprawdź `:set shada? shadafile?`, `:oldfiles`, `:jumps` i `:messages`. Natywne marki lokalne oraz `A`-`Z` mogą przetrwać przez ShaDa; lokalne `force_write_shada=false` oznacza, że usunięcie marki nie wymusza zapisu na dysk.
6. Jeśli bieżące natywne marki mają przetrwać `:bwipeout`, wykonaj świadomie `:wshada` przed usunięciem bufora. Nie używaj odruchowo `:wshada!`: pomija merge, zmienia także inne dane ShaDa i może odrzucić stan innej instancji.
7. Bookmarki `m0`-`m9`, ich extmarki i adnotacje są session-only. Nie trafiają do ShaDa, pliku sesji ani własnego storage, znikają po restarcie, a `:bdelete` usuwa bookmarki danego bufora; jest to oczekiwane zachowanie, nie awaria zapisu.
8. `<leader>ma` i `:marks` pokazują natywne marki, nie bookmarki. Bookmarki diagnozuj przez `:BookmarksListAll` albo `:BookmarksQFListAll`; znaki obu kategorii przełącza `:MarksToggleSigns` bez usuwania pozycji.

## Tmux, WezTerm i kod klawisza

1. Sprawdź składnię i przeładuj przez `tmux source-file "$HOME/.tmux.conf"`.
2. Obejrzyj efektywne mapowania przez `tmux list-keys -T root`, `tmux list-keys -T prefix` i `tmux list-keys -T copy-mode-vi`.
3. Sprawdź opcje przez `tmux show-options -gv prefix`, `tmux show-options -gv extended-keys`, `tmux show-options -gv extended-keys-format` i `tmux show-options -gv allow-passthrough`.
4. Gdy nawigator nie przechodzi przez granicę, użyj `:TmuxNavigatorProcessList`, a potem sprawdź proces panelu przez `tmux display-message -p '#{pane_current_command}'`.
5. Aby zobaczyć kod wysyłany przez terminal, wykonaj w Neovim `:lua print(vim.fn.keytrans(vim.fn.getcharstr()))`, zatwierdź i naciśnij badany klawisz.
6. Jeśli TUI pozostawiło w panelu mysz lub alternate screen, użyj `Ctrl-s Ctrl-g`; polecenie naprawcze zmienia stan terminala i powinno służyć tylko do tej awarii.

Jeśli `Ctrl-s` zamraża samą powłokę poza tmux, sprawdź `stty -a` i ponownie wykonaj `stty -ixon`. W tmux `Ctrl-s` jest świadomie prefixem, więc dosłowny klawisz do aplikacji to `Ctrl-s Ctrl-s`.

## Git UI i różnice

- **Telescope nie widzi plików/tekstu**: `:checkhealth telescope`, potem `:echo executable('fd')` i `:echo executable('rg')`.
- **Neogit pokazuje błąd Git**: panel `$`/console, `:messages`, zwykłe `git status` w root repo.
- **Diffview ma zły zakres**: zamknij `:DiffviewClose`, sprawdź ref przez Git i podaj go jawnie do `:DiffviewOpen`.
- **CodeDiff nie ma biblioteki natywnej**: `:CodeDiff install`; wariant z `!` wymusza ponowną instalację.
- **operacja stage nie daje oczekiwanego wyniku**: natychmiast sprawdź `git status` i sekcję staged/unstaged przed dalszą akcją.

Nie diagnozuj problemu Git przez próbne `X`, discard albo hard reset. Najpierw użyj operacji tylko do odczytu: `git status`, diff i log.

## DAP

1. Sprawdź adapter przez `:echo executable('debugpy-adapter')`, `:echo executable('dlv')` albo `:echo executable('js-debug-adapter')`.
2. Włącz log przez `:DapSetLogLevel TRACE`, odtwórz problem i otwórz `:DapShowLog`.
3. Dla Node sprawdź `cwd`, source mapy i czy program istnieje. Dla attach wybierz właściwy proces.
4. Dla Chrome sprawdź port remote debugging, domyślnie `9222`, oraz zgodność `webRoot` z root projektu.
5. Jeśli UI się nie otworzy, wykonaj `<leader>du`; sprawdź też `:messages`, bo dap-ui jest zależnością ładowaną razem z nvim-dap.
6. Gdy `.vscode/launch.json` nie daje konfiguracji, sprawdź `:pwd`, dokładną ścieżkę `${cwd}/.vscode/launch.json`, poprawny JSON i `type` odpowiadający zarejestrowanemu adapterowi. Provider launch.json nie filtruje wpisów według bieżącego filetype.

## Distant

1. Wykonaj `:DistantClientVersion`, `:DistantCheckHealth` i `:DistantSystemInfo`.
2. Sprawdź `:echo executable(expand('~/.local/bin/distant'))` oraz ręczne SSH do celu.
3. Przy timeout sprawdź host i użytkownika; dla Launch także zdalną ścieżkę executable oraz limit 60 s.
4. Obecny pusty wpis `lsp['*']` nie uruchamia remote LSP. Najpierw skonfiguruj realne `cmd` i `root_dir`, potem sprawdź executable na hoście zdalnym.
5. `:DistantSessionInfo` pokazuje globalne Connections. Przed zapisem/usunięciem porównaj active connection z `:lua =vim.b.distant` bieżącego remote buffer.

## watchdiff i Claude

- **brak zewnętrznego diffu**: sprawdź, czy plik jest otwartym buforem, CWD obejmuje plik, wzorzec nie jest ignorowany i bufor był czysty.
- **konflikt z niezapisanym buforem**: najpierw skopiuj/zapisz potrzebną treść; nie wybieraj odruchowo `:e!`.
- **historia jest pusta**: historia nie jest trwała i zaczyna się dopiero po zdarzeniach w bieżącej sesji.
- **popup Claude nie startuje**: `:echo executable('claude')`, `:messages`, potem ręczne `claude` w powłoce.
- **drawer Volt zawodzi**: brak wsparcia lub zwrot `false` daje scratch; wyjątek runtime może przerwać bez fallbacku, więc sprawdź `:messages` i `volt` w Lazy.
- **komentarz nie został zapisany od razu**: kontrolowana odmowa bezpieczeństwa daje drawer; `E484` może oznaczać brakujący lub nieczytelny plik źródłowy.

## Gdzie pytać o mapowanie

- Neovim: `:map`, `:nmap`, `:imap`, `:xmap`, `:smap`, a dla źródła definicji `:verbose {tryb}map {klawisz}`.
- Lazy: `:Lazy help`, a potem `?` w UI konkretnej rewizji.
- Panel wtyczki: najpierw `g?` albo `?`, jeśli dana sekcja ten klawisz dokumentuje.
- Tmux: `prefix ?` lub `tmux list-keys`; pamiętaj o osobnych tabelach root, prefix i copy-mode-vi.
- Polecenia: `:help :commands`, `:command`, `:verbose command {nazwa}`; nazwa funkcji Lua z README nie oznacza automatycznie polecenia Ex.
