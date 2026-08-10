<a id="diagnostyka"></a>
# Diagnostyka

## Kontrola bazowa

```sh
bash install.sh status
nvim --version
tmux -V
git --version
command -v rg fd fzf jq stylua ruff tree-sitter
command -v node npm curl tar cc
command -v lua-language-server pyright-langserver typescript-language-server mypy
command -v debugpy-adapter dlv js-debug-adapter distant claude
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
