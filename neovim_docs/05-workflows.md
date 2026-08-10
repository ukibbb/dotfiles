<a id="przeplywy-pracy"></a>
# Praktyczne przepływy pracy

## Plik i wyszukiwanie

1. Otwórz projekt przez `tmux new -s nazwa`, potem `nvim .`.
2. Użyj `<leader>ff`, wpisz część ścieżki i `Enter`; `Ctrl-v` otworzy wynik w pionowym splicie.
3. Otwórz drzewo przez `<leader>e`; `Enter` otwiera plik, `-` idzie katalog wyżej, `g?` pokazuje pomoc.
4. Znajdź tekst przez `<leader>fw`; `Tab` zaznacza wiele wyników, `Alt-q` wysyła zaznaczone do quickfix.
5. Przechodź quickfix przez `[q` / `]q` albo bufory przez `<leader>fb`.

## LSP, refaktoryzacja, completion i snippet

1. Otwórz plik obsługiwany przez aktywny serwer i sprawdź `:checkhealth vim.lsp`.
2. Przejdź `gd`, wróć `Ctrl-o`, znajdź użycia `gr`, a dokumentację zobacz przez `K`.
3. Zaznacz zakres w Visual i naciśnij `<leader>ca`, aby ograniczyć akcję kodu do zakresu.
4. Zmień symbol przez `<leader>ra`. Dla TypeScript użyj `gS` do implementacji i `<leader>ci` do akcji całego pliku.
5. Zacznij pisać. W menu completion etykiety `[LSP]`, `[Snippet]`, `[Nvim]`, `[Buffer]`, `[Path]` pokazują źródło.
6. Wybierz pozycję `Tab` i zatwierdź `Enter`; po rozwinięciu snippetu przechodź placeholdery `Tab` / `Shift-Tab`.
7. `ts_ls` próbuje automatycznie odzyskać utratę synchronizacji lub crash; jeśli inny serwer się zawiesi albo restart nie nastąpił, użyj `<leader>lr`.

## Format i lint

1. Naciśnij `<leader>fm` przed przeglądem zmian albo po prostu zapisz plik.
2. Lua używa `stylua`; Python kolejno `ruff check --fix` i `ruff format`, więc zapis może także poprawić kod lub usunąć import. Inne filetype mogą użyć formatowania LSP.
3. Po zapisie Pythona `nvim-lint` uruchamia `mypy`, jeśli executable jest w `PATH`.
4. Otwórz `<leader>ds`, aby przejść po diagnostyce location list. Użyj `:ConformInfo`, gdy formatter nie działa.

## Od instalacji narzędzia do widocznego efektu

1. Mason albo Homebrew dostarcza executable, lecz samo zainstalowanie pakietu nie uruchamia funkcji.
2. `nvim-lspconfig` wybiera serwer po filetype/root i uruchamia wbudowanego klienta Neovim.
3. `cmp-nvim-lsp` reklamuje capabilities i dostarcza kandydaty `[LSP]`; nvim-cmp renderuje menu.
4. LuaSnip rozwija body snippetu, `cmp_luasnip` tylko wystawia je w menu, a friendly-snippets jest wyłącznie kolekcją danych.
5. nvim-autopairs reaguje po zatwierdzeniu completion i może dopisać parę.
6. Conform używa osobnego executable przy formatowaniu, a nvim-lint uruchamia mypy po zapisie. Diagnostyka LSP i lint może więc pochodzić z kilku niezależnych procesów.

Przy awarii diagnozuj od dołu: `executable()` → filetype/root → klient/provider → mapowanie/UI. Naprawianie samego popupu nie uruchomi brakującego serwera.

## Git: status, stage, review i historia

1. Otwórz `<leader>gg`. W statusie Neogit `s` stage'uje zaznaczenie, `u` cofa stage, `S` stage'uje zmiany wszystkich śledzonych plików, dosłowny `Ctrl-s` także untracked, a `U` cofa cały staged zestaw.
2. Obejrzyj diff przez `<leader>gv` albo char-level przez `<leader>gD`; w zwykłym statusie CodeDiff `-` przełącza stage całego pliku. Nie używaj stagingu w widoku rewizji.
3. Utwórz commit przez `<leader>gc`; napisz wiadomość i zatwierdź `Ctrl-c Ctrl-c`. `Ctrl-c Ctrl-k` anuluje edytor commita.
4. Przed push użyj `<leader>gm`, aby porównać `origin/main...HEAD`, potem `<leader>gp`.
5. Historię pliku pokażą `<leader>gh` albo `<leader>gl`; historię repozytorium `<leader>gL`; picker commitów `<leader>cm` służy do checkout/reset i wymaga szczególnej ostrożności.

## Git: konflikt

1. W Diffview otwartym podczas merge/rebase przechodź konflikty `[x` / `]x`.
2. Wybierz `<leader>co` ours, `<leader>ct` theirs, `<leader>cb` base, `<leader>ca` wszystkie strony albo `dx` usuń region konfliktu. Wielkie warianty działają na cały plik.
3. Alternatywnie uruchom CodeDiff jako mergetool. W nim `<leader>co` oznacza current/ours, `<leader>ct` incoming/theirs, `<leader>cb` inteligentne połączenie obu, a `<leader>cx` powrót do base.
4. Zapisz bufor wyniku, sprawdź treść i dopiero wtedy stage'uj plik. Nie myl akcji rozwiązania konfliktu z odrzuceniem całego pliku przez `X`.

## Git: którego narzędzia użyć

- **znaki i blame bieżącego pliku**: Gitsigns.
- **czytelny inline review bez dwóch kolumn**: Unified.
- **częściowy stage hunka lub zakresu**: Gitsigns albo Neogit.
- **commit, branch, pull, push, stash, rebase**: Neogit.
- **review wielu plików/brancha i klasyczne konflikty**: Diffview.
- **char-level diff, dwa pliki/katalogi, result buffer konfliktu**: CodeDiff.

Bezpieczny porządek to: obserwacja Gitsigns → review Unified/CodeDiff/Diffview → staging Gitsigns/Neogit → commit/push Neogit. Historyczne viewery nie są bezpiecznym miejscem do eksperymentowania z `S/U/X`.

## DAP: Python, Go, JavaScript, TypeScript i Chrome

1. Zainstaluj odpowiedni adapter: `debugpy-adapter`, `dlv` albo `js-debug-adapter` musi być w `PATH`.
2. Ustaw breakpoint przez `<leader>db`, uruchom `F5` i wybierz konfigurację.
3. Python: wybierz konfigurację dap-python; `<leader>dn` debugguje metodę testową nad kursorem. Adapter jest skonfigurowany jako `debugpy-adapter`.
4. Go: wybierz debug programu/testów; `<leader>dn` uruchamia najbliższy test znaleziony przez parser Go.
5. JS/TS: wybierz `Launch current file with Node`, `Attach to Node process`, `Launch Chrome` albo `Attach to Chrome`.
6. Dla Chrome uruchamianego ręcznie użyj portu remote debugging, domyślnie `9222`; dla launch wpisz URL aplikacji, domyślnie `http://localhost:3000`.
7. Projektowe konfiguracje umieść dokładnie w `${cwd}/.vscode/launch.json`. Typ musi odpowiadać adapterowi, na przykład `pwa-node`, `pwa-chrome`, `python`, `debugpy` albo `go`; provider czyta plik na żądanie.
8. Steruj przez `F10/F11/F12`, ewaluuj `<leader>de`, a sesję zakończ `<leader>dt`.

## Markdown i tagi

1. Otwórz `.md`; render-markdown ładuje się tylko dla `markdown` i renderuje również w Normal oraz Insert.
2. Naciśnij `<leader>mr`, aby wyłączyć lub włączyć render tylko dla tego bufora.
3. Parsery `markdown` i `markdown_inline` są instalowane, a Treesitter startuje dla Markdown.
4. W HTML wpisz `<div>`: `>` uruchamia domknięcie do `<div></div>`. Zmień nazwę tagu i wyjdź z Insert, aby sparowany tag został przemianowany.
5. Autotag wymaga parsera `html`; ten parser jest instalowany i Treesitter startuje dla `html`.

## Distant

1. Sprawdź lokalny klient przez `:DistantClientVersion`. `<leader>rl` używa Launch, więc wymaga skonfigurowanego zdalnego binarnego; `:DistantConnect ssh://...` może użyć samego backendu SSH.
2. Podaj `ssh://user@host`, a potem potwierdź globalnie aktywne połączenie w `:Distant`. Otwarty bufor zachowuje własny connection ID.
3. Wpisz `<leader>ro`, dopisz ścieżkę i zatwierdź. W katalogu `Enter` otwiera wpis, `-` idzie wyżej, `Ctrl-t` otwiera kartę.
4. Otwórz zdalną powłokę `<leader>rs` albo wykonaj pojedyncze polecenie przez `<leader>rx`.
5. Zapis działa na hoście zdalnym. Przed `D` upewnij się, że wskazany wpis można usunąć.

## watchdiff i Claude

1. Pozostaw czysty, zapisany bufor otwarty i pozwól narzędziu zewnętrznemu zmienić plik.
2. watchdiff przeładuje czysty bufor, pokaże zielone dodania/zmiany i czerwone wirtualne usunięcia.
3. Obejrzyj zmianę, opcjonalnie uruchom `:WatchDiffHistory`, a potem `<leader>ch`, aby uznać nowy baseline.
4. Zaznacz kod i użyj `<leader>ac`; wpisz pytanie, `Tab` zmienia model, `Enter` wysyła, `Ctrl-j` dodaje nową linię.
5. W drawerze odpowiedzi `1/2/3` przełącza Answer/Question/Files, `y` kopiuje odpowiedź, `I` próbuje wstawić komentarze.
6. `<leader>aC` próbuje natychmiastowego zapisu po kontrolach stanu pliku, ale nie gwarantuje semantycznego bezpieczeństwa komentarza. Obejrzyj `git diff`; wpis watchdiff jest warunkową adnotacją i może nie powstać.

## Granice lokalne, zdalne i zewnętrzne

- **Distant + watchdiff**: remote buffer ma `acwrite`; działa watcher Distant, ale nie historia watchdiff.
- **Distant + lokalny Mason**: lokalny executable nie staje się automatycznie remote LSP.
- **Claude + Distant**: zaznaczony tekst może trafić do promptu, lecz inspekcja ścieżki i writer zakładają lokalny plik; workflow nie jest wspierany.
- **Claude writer + watchdiff**: zapis następuje pierwszy, a watcher później może dodać highlight/provenance, jeśli spełnione są wszystkie warunki.
- **zewnętrzne Claude Code + watchdiff**: wykrycie pochodzi z filesystem event; repo nie ma aktywnego hooka PostToolUse przypisującego autora.
- **Gitsigns + watchdiff**: Gitsigns porównuje Git index/base, watchdiff użytkownikowy baseline; oba widoki mogą jednocześnie pokazywać inne różnice.
