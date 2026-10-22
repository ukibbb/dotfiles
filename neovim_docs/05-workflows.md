<a id="przeplywy-pracy"></a>
# Praktyczne przepływy pracy

## Plik i wyszukiwanie

1. Otwórz projekt przez `nt` (workspace WezTerm), potem `nvim .`.
2. Użyj `<leader>ff`, wpisz część ścieżki i `Enter`; `Ctrl-v` otworzy wynik w pionowym splicie.
3. Otwórz drzewo przez `<leader>e`; `Enter` otwiera plik, `-` idzie katalog wyżej, `g?` pokazuje pomoc.
4. Znajdź tekst przez `<leader>fw`; `Tab` zaznacza wiele wyników, `Alt-q` wysyła zaznaczone do quickfix.
5. Przechodź quickfix przez `[q` / `]q` albo bufory przez `<leader>fb`.

## LSP, refaktoryzacja, completion i snippet

1. Otwórz plik obsługiwany przez aktywny serwer i sprawdź `:checkhealth vim.lsp`.
2. Przejdź `gd`, wróć `Ctrl-o`, znajdź użycia `gr`, a dokumentację zobacz przez `K`.
3. Zaznacz zakres w Visual i naciśnij `<leader>ca`, aby ograniczyć akcję kodu do zakresu.
4. Zmień symbol przez `<leader>ra`. Dla TypeScript użyj `gS` do definicji źródłowej i `<leader>ci` do akcji całego pliku.
5. Zacznij pisać. W menu completion etykiety `[LSP]`, `[Snippet]`, `[Nvim]`, `[Buffer]`, `[Path]`, a w SQL także `[DB]`, pokazują źródło.
6. Wybierz pozycję `Tab` i zatwierdź `Enter`; po rozwinięciu snippetu przechodź placeholdery `Tab` / `Shift-Tab`.
7. `ts_ls` próbuje automatycznie odzyskać utratę synchronizacji lub crash; jeśli inny serwer się zawiesi albo restart nie nastąpił, użyj `<leader>lr`.

## Format i lint

1. Naciśnij `<leader>fm` przed przeglądem zmian albo po prostu zapisz plik.
2. Lua używa `stylua`; Python kolejno `ruff check --fix` i `ruff format`, więc zapis może także poprawić kod lub usunąć import. Inne filetype mogą użyć formatowania LSP.
3. Po zapisie Pythona `nvim-lint` uruchamia `mypy`, jeśli executable jest w `PATH`.
4. Otwórz `<leader>ds`, aby przejść po diagnostyce location list. Użyj `:ConformInfo`, gdy formatter nie działa.

## Bazy danych: które narzędzie

- **DBee** (`<leader>Bd`): wiele baz naraz, drzewo struktur, notatniki SQL, stronicowany wynik, eksport CSV/JSON.
- **Dbout** (`<leader>Bo`): szybkie podpięcie połączenia do istniejącego pliku `.sql`, Inspector obiektów, MongoDB.
- **Dadbod/DBUI** (`<leader>Bu`): lekki drawer schematów i zwykłe bufory SQL z podpowiedziami `[DB]`; `:w` wykonuje zapytanie.
- **Dadbod Grip** (`<leader>Bg`): edytowalna tabela wyników z podglądem zmian przed zapisem.

Żadne z nich nie pyta o potwierdzenie przed `UPDATE`/`DELETE`. Do eksperymentów używaj testowej bazy albo konta tylko do odczytu. Jak zacząć: [DBee](plugins/11-nvim-dbee.md#plugin-nvim-dbee), [Dbout](plugins/12-dbout.md#plugin-dbout), [Dadbod/DBUI](plugins/15-vim-dadbod.md#plugin-vim-dadbod), [Grip](plugins/16-dadbod-grip.md#plugin-dadbod-grip).

## Punkty powrotu: marka, bookmark czy Trail

- **Jedno miejsce w pliku**: marka `ma`, powrót `'a`. Wielka litera (`mA`) działa między plikami.
- **Kilka miejsc na chwilę**: bookmarki `m0`…`m9`, znikają po zamknięciu Neovim. [Marki](plugins/14-marks.md#plugin-marks).
- **Ścieżka przez wiele plików do wznowienia później**: Wayfinder Trail (`<leader>Wf`, potem zapis). [Wayfinder](plugins/13-wayfinder.md#plugin-wayfinder).

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

## Git: które narzędzie

- **Zmiany w bieżącym pliku, blame, stage kawałka**: Gitsigns.
- **Commit, branch, push, rebase**: Neogit (`<leader>gg`).
- **Przegląd wielu plików lub brancha, konflikty**: Diffview (`<leader>gv`).
- **Dokładny diff znak po znaku**: CodeDiff (`<leader>gD`).

## DAP: Python, Go, JavaScript, TypeScript i Chrome

1. Zainstaluj odpowiedni adapter: `debugpy-adapter`, `dlv` albo `js-debug-adapter` musi być w `PATH`.
2. Ustaw breakpoint przez `<leader>db`, uruchom `F5` i wybierz konfigurację.
3. Python: wybierz konfigurację dap-python; `<leader>dn` debugguje metodę testową nad kursorem. Adapter jest skonfigurowany jako `debugpy-adapter`.
4. Go: wybierz debug programu/testów; `<leader>dn` uruchamia najbliższy test znaleziony przez parser Go.
5. JS/TS: wybierz `Launch current file with Node`, `Attach to Node process`, `Launch Chrome` albo `Attach to Chrome`.
6. Dla Chrome uruchamianego ręcznie użyj portu remote debugging, domyślnie `9222`; dla launch wpisz URL aplikacji, domyślnie `http://localhost:3000`.
7. Projektowe konfiguracje umieść dokładnie w `${cwd}/.vscode/launch.json`. Typ musi odpowiadać adapterowi, na przykład `pwa-node`, `pwa-chrome`, `python`, `debugpy` albo `go`; provider czyta plik na żądanie.
8. Steruj przez `F10/F11/F12`, ewaluuj `<leader>de`, a sesję zakończ `<leader>dt`.
