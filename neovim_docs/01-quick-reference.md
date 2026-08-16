<a id="szybka-sciaga"></a>
# Szybka ściąga

`prefix` tmux to `Ctrl-s`. `<leader>` Neovim to `Spacja`.

## Tmux na co dzień

- **`Ctrl-s c`**: Nowe okno w bieżącym katalogu.
- **`Ctrl-s |`**: Panel obok, lewo/prawo.
- **`Ctrl-s -`**: Panel poniżej, góra/dół.
- **`Ctrl-h/j/k/l`**: Przejście między panelami tmux i splitami Neovim bez prefixu.
- **`Ctrl-\`**: Poprzedni panel lub split, bez prefixu.
- **`Ctrl-s h/j/k/l`**: Zmiana rozmiaru panelu o 5 komórek.
- **`Ctrl-s m`**: Maksymalizacja/przywrócenie panelu.
- **`Ctrl-s Ctrl-j`**: Wyszukiwarka sesji `tmux-fzf`.
- **`Ctrl-s s`**: Lista sesji tmux.
- **`Ctrl-s d`**: Odłączenie od sesji.
- **`Ctrl-s r`**: Ponowne wczytanie `~/.tmux.conf`.

## Neovim na co dzień

- **Plik**: `<leader>ff` pliki projektu, `<leader>fa` także ignorowane, `<leader>e` drzewo.
- **Tekst**: `<leader>fw` w projekcie, `<leader>fW` słowo pod kursorem, `<leader>fz` w buforze, `<leader>fZ` słowo w buforze.
- **Bufor**: `<leader>fb`, fizyczne `Cmd-h` / `Cmd-l`, fizyczne `Cmd-q`.
- **LSP**: `gd` definicja, `gD` deklaracja, `gr` referencje, `K` hover, `<leader>ca` akcje, `<leader>ra` zmiana nazwy.
- **TypeScript**: `gS` źródłowa definicja, `<leader>ci` akcje importów.
- **Diagnostyka**: `[d` / `]d`, `<leader>dd`, `<leader>ds`.
- **Format**: `<leader>fm`; zapis także formatuje.
- **Git**: `<leader>gg` status, `<leader>gv` Diffview, `<leader>gD` CodeDiff, `<leader>gf` bieżący plik kontra `HEAD`.
- **Debugger**: `F5`, `F10`, `F11`, `F12`, `<leader>db`, `<leader>du`.
- **Bazy danych**: `<leader>Bd` przełącza workspace DBee, `<leader>Bo` otwiera Dbout, `<leader>Bu` przełącza drawer Dadbod UI, a `<leader>Bg` otwiera połączenia Grip. W buforze SQL DBUI `<leader>Bs` zapisuje query, a `<leader>Bp` edytuje bind parameters; surowy Dadbod pozostaje pod `:DB`.
- **Dbout po otwarciu lub dołączeniu połączenia**: `F6` wykonuje cały Queryer albo zaznaczone pełne wiersze, `F7` formatuje ten sam zakres, `F8` przełącza Inspector, `F9` przełącza Viewer. `F6` / `F7` działają tylko w Queryerze, a `F8` / `F9` także w jego panelach; nie są to skróty globalne.
- **Wayfinder**: `<leader>Wf` eksploruje symbol lub plik, `<leader>Wn` / `<leader>Wp` otwierają następny / poprzedni element Trail, `<leader>Wo` otwiera bieżący element, `<leader>Ws` pokazuje Trail.
- **Marki**: `m,` ustawia następną wolną małą literę; `` `a `` skacze dokładnie do `a`, `'a` do początku jej wiersza, `m]` / `m[` cyklicznie po markach bieżącego bufora, a `<leader>ma` otwiera picker natywnych marek. `mA` i `` `A `` tworzą i otwierają cel między plikami; `dm{litera}` usuwa wskazaną markę. `m;` ustawia markę na wierszu bez śledzonej marki, a na zajętym usuwa wszystkie śledzone marki tego wiersza.
- **Bookmarki `marks.nvim`**: `m1` dodaje pozycję do ulotnej grupy `1`, `m}` / `m{` przechodzi po tej grupie z wiersza bookmarka, `dm=` usuwa bookmark pod kursorem, a `dm1` całą grupę. Bookmarki znikają po restarcie i po `:bdelete` ich bufora.
- **Markdown**: `<leader>mr` przełącza renderowanie tylko w buforze Markdown.
- **Zdalnie**: `<leader>rl` połączenie, `<leader>ro` plik/katalog, `<leader>rs` powłoka.
- **Zmiany zewnętrzne**: `<leader>ch` zatwierdza obejrzenie podświetleń watchdiff.
- **Claude**: `<leader>ac` pytanie, `<leader>aC` pytanie i próba natychmiastowego komentarza.

<a id="bezpieczenstwo"></a>
## Najważniejsze ostrzeżenia

> **UWAGA: zapytania bazodanowe mogą być destrukcyjne.** DBee, Dbout i Dadbod/DBUI wysyłają tekst bez sandboxa ani analizy DDL/DML; DBUI dodatkowo wykonuje domyślnie cały query buffer przy `:write`. Grip pokazuje preview części mutacji i ma lokalny `mode="ro"`, ale query pad nadal może wykonać dowolny SQL. Sprawdź tekst i aktywną bazę, używaj konta o minimalnych prawach, a produkcyjne zmiany wykonuj z kontrolowaną transakcją i kopią bezpieczeństwa.

> **UWAGA: Dbout zapisuje connection string jawnym tekstem.** Pełna wartość trafia do `stdpath("state")/dbout/db_explorer.json`, zwykłego `input()`, historii `input` i przy tej konfiguracji do ShaDa; pokazują ją też picker Telescope i listy `vim.ui.select`. Nie wpisuj stałego prawdziwego hasła; używaj co najwyżej tymczasowych poświadczeń o minimalnych prawach, a ujawniony sekret natychmiast unieważnij lub obróć.

> **UWAGA: DBee FileSource nie szyfruje sekretów.** `stdpath("state")/dbee/persistence.json` jest zwykłym JSON-em. W zaufanym FileSource albo `DBEE_CONNECTIONS` zamiast literalnego hasła preferuj szablon `env` lub zaufany secret manager wywołany przez `exec`, ale środowisko nie jest sejfem, brakująca zmienna rozwija się do pustego tekstu, a `exec` wykonuje kod; ładuj wyłącznie zaufane źródła i nie drukuj rozwiniętego URL-a do logów ani `:messages`.

> **UWAGA: audyt DBee nie oznacza „braku podatności”.** Kontrolowany fork `6f2948a...`, zbudowany Go 1.26.6, ma zero podatności osiągalnych według źródłowego i binarnego `govulncheck`. Skan nadal widzi advisory `GO-2026-5932` w wymaganym module `golang.org/x/crypto/openpgp`, lecz nie znajduje ścieżki wywołania z DBee. Każdy rebuild jest skanowany, a niezerowy wynik blokuje hook Lazy; nadal używaj TLS i minimalnych uprawnień bazy.

> **UWAGA: Dadbod UI i Grip zapisują plaintext state.** DBUI może utrwalić URL pod `stdpath("data")/db_ui/connections.json`, a Grip pod `stdpath("state")/dadbod-grip/connections.json` oraz projektowym `.grip/`. Nie zapisuj literalnych haseł. W Grip używaj `${VAR}` lub chronionego `env_file`; te placeholdery nie działają w surowym Dadbod `:DB`.

> **UWAGA: DuckDB federation Grip ujawnia DSN w argumentach procesu.** `ATTACH` przekazuje credentialed DSN wewnątrz SQL do `duckdb -c`, więc hasło może być widoczne w `argv` nawet po rozwinięciu `${VAR}`. Do czasu rozwiązania issue #39 nie używaj takiej federacji na niezaufanym hoście.

> **UWAGA: Dbout dla PostgreSQL nie weryfikuje domyślnie certyfikatu.** Bez własnej opcji SSL backend ustawia `ssl = { rejectUnauthorized = false }`. Dodaj `?sslmode=verify-full` do URI, aby weryfikować certyfikat i nazwę hosta; `sslmode=disable` całkowicie wyłącza TLS i nadaje się tylko do świadomie zaakceptowanego, izolowanego środowiska.

> **UWAGA: Dbout usuwa profil bez potwierdzenia.** `d` w trybie Normal pickera Telescope i `:Dbout DeleteConnection` natychmiast usuwają wskazany rekord, bez confirm i undo. Operacja nie usuwa pliku SQLite ani nie gwarantuje zamknięcia backendu już używanego przez Queryer, dlatego przed użyciem sprawdź nazwę i pełny connection string.

> **UWAGA: Git.** `X` w CodeDiff i Diffview, `x` w Neogit, reset hard w Telescope, przywracanie pliku oraz usuwanie nieśledzonego pliku mogą bezpowrotnie usunąć niezapisane lub niezatwierdzone dane. Przed użyciem sprawdź `git status`, zapisz potrzebne bufory i w razie wątpliwości utwórz commit albo stash.

> **UWAGA: historia Git.** `Enter` w pickerze `<leader>cm` wykonuje checkout wybranego commita i zwykle przechodzi do detached `HEAD`. `Ctrl-r m`, `Ctrl-r s` i `Ctrl-r h` przesuwają bieżącą gałąź. Szczególnie `Ctrl-r h` usuwa śledzone zmiany z indeksu i drzewa roboczego.

> **UWAGA: `Ctrl-s`.** Tmux przechwytuje `Ctrl-s` jako prefix. Aby wysłać dosłowne `Ctrl-s` do Neovim lub programu w panelu, naciśnij `Ctrl-s Ctrl-s`. Dotyczy to między innymi wbudowanej pomocy sygnatur LSP, akcji `StageAll` w Neogit i zapisu koloru w Minty. `.zshrc` wykonuje `stty -ixon`, więc terminal nie używa `Ctrl-s` jako XOFF, ale konflikt z prefixem tmux pozostaje.

> **UWAGA: pliki zdalne i zewnętrzne.** `D`, `R`, `K` w interfejsach Distant mogą usuwać, zmieniać nazwę lub zrywać połączenie. `:e!` po konflikcie watchdiff odrzuca lokalne, niezapisane zmiany bufora.

> **UWAGA: automatyczne zmiany przy zapisie.** Zapis Lua lub Pythona uruchamia Conform. Dla Pythona najpierw działa `ruff check --fix`, a dopiero potem `ruff format`, więc zapis może usuwać importy i stosować poprawki kodu, nie tylko zmieniać odstępy. Po pierwszym użyciu w projekcie obejrzyj `git diff`.

> **UWAGA: interfejs nie zawsze pokazuje historyczny stan, na którym operuje.** Stage, unstage i discard w historycznych widokach CodeDiff albo Diffview nadal mogą zmieniać realny indeks i drzewo robocze. Operacji `-`, `S`, `U` i `X` używaj do stagingu tylko w zwykłym widoku bieżących zmian, po sprawdzeniu `git status`.
