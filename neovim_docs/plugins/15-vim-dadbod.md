# Dadbod, DBUI i completion

<a id="plugin-vim-dadbod"></a>
## `vim-dadbod`

**Przypięta rewizja:** [`6d1d41da4873a445c5605f2005ad2c68c99d8770`](https://github.com/tpope/vim-dadbod/tree/6d1d41da4873a445c5605f2005ad2c68c99d8770).

**Co robi i po co:** Dadbod zamienia URL połączenia na wywołanie natywnego klienta bazy. Sam nie dostarcza drawera ani tabelarycznego grida. Daje polecenie `:DB`, wynik w preview i wspólny kontekst używany przez DBUI oraz completion.

**Aktywne lokalnie:** polecenie `:DB` jest triggerem Lazy. Nie ma osobnego globalnego mapowania; launcher `<leader>Bu` należy do DBUI.

### Formy polecenia `:DB`

- **`:DB [url]`**: uruchom interaktywną konsolę wskazanej bazy.
- **`:DB [url] {sql}`**: wykonaj tekst i pokaż wynik w preview.
- **`:{range}DB [url]`**: wykonaj wskazane wiersze bieżącego bufora.
- **`:DB [url] < {plik}`**: wykonaj zawartość pliku.
- **`:DB w:db = {url}`**: znormalizuj URL i zapisz go w zmiennej Vim.
- **`R` w preview**: wykonaj ostatnie zapytanie ponownie.
- **`r` w preview**: wstaw ostatnie zapytanie do command-line do edycji.
- **`gq` w preview**: zamknij wynik.

Bez jawnego URL Dadbod wybiera pierwszą dostępną wartość w kolejności `w:db`, `t:db`, `b:db`, `$DATABASE_URL`, `g:db`. Literalny URL wpisany w command-line może trafić do historii poleceń i ShaDa. Dadbod nie analizuje SQL, nie dodaje potwierdzeń i nie tworzy sandboxa dla `UPDATE`, `DELETE`, `DROP`, DDL ani procedur.

### Lokalne silniki i executable

- **PostgreSQL:** URL `postgresql://USER@HOST:5432/DB`, executable `psql`.
- **MySQL/MariaDB:** URL `mysql://USER@HOST:3306/DB`, executable `mysql`.
- **SQLite:** preferowany URL `sqlite:/absolutna/sciezka.sqlite3`, executable `sqlite3`.
- **DuckDB:** URL `duckdb:/absolutna/sciezka.duckdb`, executable `duckdb`.
- **SQL Server:** URL `sqlserver://USER@HOST:1433/DB`, executable `sqlcmd`.

Homebrew instaluje wszystkie powyższe klienty, a `.zshrc` dodaje keg-only `psql`, `mysql` i `sqlite3` do `PATH`. Dadbod ma też adaptery dla innych klientów, lecz bez odpowiedniego executable nie zadziałają.

### Sekrety i transport

Nie zapisuj URL-a z prawdziwym hasłem w repo, `g:db`, command-line ani nieszyfrowanym pliku projektu. Preferuj mechanizmy natywnego klienta: `.pgpass` lub `PGPASSWORD` dla PostgreSQL, chroniony plik opcji MySQL i `SQLCMDPASSWORD` dla SQL Server. Ustaw TLS zgodnie z polityką serwera i używaj osobnego użytkownika o minimalnych prawach.

Dadbod może przekazać klientowi pełny URL albo argument zawierający hasło, zależnie od adaptera. Oznacza to możliwą ekspozycję w historii, liście procesów i komunikatach błędu. Zmienna środowiskowa również nie jest secret store, ale pozwala uniknąć utrwalania literalnej wartości w tym repo.

### Minimalny przepływ bez DBUI

1. Otwórz plik SQL bez sekretów.
2. Ustaw połączenie poza repo, na przykład przez `$DATABASE_URL` albo buforowe `b:db`.
3. Zaznacz nieszkodliwe zapytanie odczytowe i wykonaj `:'<,'>DB`.
4. W preview użyj `R`, `r` albo `gq`.
5. Przed DML sprawdź tekst, aktywną bazę i użytkownika. Bezpieczeństwo zapewniają uprawnienia serwera, nie polecenie `:DB`.

**Źródła przypiętej rewizji:** [help `dadbod.txt`](https://github.com/tpope/vim-dadbod/blob/6d1d41da4873a445c5605f2005ad2c68c99d8770/doc/dadbod.txt), [adaptery](https://github.com/tpope/vim-dadbod/tree/6d1d41da4873a445c5605f2005ad2c68c99d8770/autoload/db/adapter), [polecenie](https://github.com/tpope/vim-dadbod/blob/6d1d41da4873a445c5605f2005ad2c68c99d8770/plugin/dadbod.vim).

<a id="plugin-vim-dadbod-ui"></a>
## `vim-dadbod-ui`

**Przypięta rewizja:** [`afd07819d8efcefc3317205b855ad4e3513b0011`](https://github.com/kristijanhusak/vim-dadbod-ui/tree/afd07819d8efcefc3317205b855ad4e3513b0011).

**Co robi i po co:** DBUI dodaje drawer połączeń, schematów, tabel, buforów i zapisanych zapytań. Wykonanie nadal deleguje do Dadbod i odpowiedniego klienta CLI.

### Stan tej konfiguracji

- **`<leader>Bu`**: przełącz drawer przez `:DBUIToggle`.
- **`<leader>Bs`**: zapisz pod nazwą tymczasowy query utworzony przez DBUI. Mapowanie istnieje tylko wtedy, gdy bufor ma `b:dbui_db_key_name` i akcję save.
- **`<leader>Bp`**: edytuj bind parameters query faktycznie przypisanego do DBUI.
- Nerd Font jest włączony przez `g:db_ui_use_nerd_fonts=1`.
- Profile i zapisane query trafiają pod `stdpath("data") .. "/db_ui"`.
- `g:db_ui_disable_mappings_sql=1` wyłącza upstreamowe `<leader>W`, `<leader>S` i `<leader>E`, aby nie zabrać namespace `<leader>W*` Wayfinderowi. Lokalne `Bs` i `Bp` są dodawane dopiero po rozpoznaniu kontekstu DBUI, więc nie pojawiają się w zwykłym SQL, Dbout ani Grip.
- Domyślne `g:db_ui_execute_on_save=1` pozostaje aktywne: zapis bufora DBUI przez `:write` wykonuje zapytanie.

### Polecenia

- **`:DBUI`**: otwórz drawer.
- **`:DBUIToggle`**: przełącz drawer.
- **`:DBUIAddConnection`**: dodaj globalny profil do `connections.json`.
- **`:DBUIFindBuffer`**: znajdź bieżący bufor w drawerze albo przypisz mu połączenie.
- **`:DBUIRenameBuffer`**: zmień nazwę zapisanego bufora.
- **`:DBUILastQueryInfo`**: pokaż tekst i czas ostatniego zapytania.

### Najważniejsze mapowania drawera

- **`o` / `Enter`**: rozwiń node albo otwórz połączenie, tabelę, helper lub query.
- **`S`**: otwórz element w pionowym splicie.
- **`A`**: dodaj połączenie.
- **`d`**: usuń po potwierdzeniu obsługiwany profil, bufor albo zapisane query.
- **`r`**: zmień nazwę bufora/query albo edytuj profil zapisany przez DBUI.
- **`R`**: odśwież drawer i metadane.
- **`H`**: pokaż źródło każdego połączenia.
- **`?`**: pomoc kontekstowa.
- **`q`**: zamknij drawer.

### Połączenia i pliki stanu

DBUI łączy profile z `$DBUI_URL`, opcjonalnego prefiksu `DB_UI_`, `g:db`, `g:dbs` i własnego `connections.json`. Lokalny zapis znajduje się pod:

```text
stdpath("data")/db_ui/connections.json
```

Plik jest zwykłym JSON-em i może zawierać pełne URL-e z hasłami. Zapisane query są również plaintextem. `vim.fn.input()` używany przez prompt może dodać wartość do historii input i ShaDa. Najbezpieczniej dostarczać URL przez funkcję rozwiązującą sekret w runtime albo użyć natywnego mechanizmu klienta, bez utrwalania hasła w DBUI.

Bind parameter nie jest przygotowanym statementem po stronie serwera. DBUI podstawia wartość do tekstu przed wykonaniem; liczby i booleany mają specjalne reguły, pozostałe wartości są cytowane. Sprawdź finalny SQL i nie traktuj tego jako uniwersalnej ochrony przed injection.

### Przepływ DBUI

1. Otwórz drawer przez `<leader>Bu`.
2. Rozwiń połączenie i tabelę przez `o`; `Enter` otwiera helper lub nowy bufor query.
3. Wpisz najpierw ograniczony `SELECT`. Zapis `:write` wykonuje cały bufor, ponieważ execute-on-save pozostaje aktywne.
4. Dla `:param` ustaw lub zmień wartość przez `<leader>Bp`.
5. Tymczasowy query zachowaj przez `<leader>Bs`; zwykły plik SQL zapisuj normalnie. Zapisane query może zawierać dane poufne.
6. Wynik jest zwykłym preview Dadbod. Zamknij go przez `gq`, a drawer przez `<leader>Bu`.

**Źródła przypiętej rewizji:** [README](https://github.com/kristijanhusak/vim-dadbod-ui/blob/afd07819d8efcefc3317205b855ad4e3513b0011/README.md), [pełny help](https://github.com/kristijanhusak/vim-dadbod-ui/blob/afd07819d8efcefc3317205b855ad4e3513b0011/doc/dadbod-ui.txt), [defaulty i mapowania](https://github.com/kristijanhusak/vim-dadbod-ui/tree/afd07819d8efcefc3317205b855ad4e3513b0011/autoload/db_ui).

<a id="plugin-vim-dadbod-completion"></a>
## `vim-dadbod-completion`

**Przypięta rewizja:** [`a8dac0b3cf6132c80dc9b18bef36d4cf7a9e1fe6`](https://github.com/kristijanhusak/vim-dadbod-completion/tree/a8dac0b3cf6132c80dc9b18bef36d4cf7a9e1fe6).

**Co robi i po co:** źródło completion pobiera z kontekstu Dadbod nazwy tabel, kolumn i aliasy SQL. Lokalnie ładuje się tylko dla `sql`, `mysql` i `plsql`, a nvim-cmp pokazuje kandydatów jako **`[DB]`** z priorytetem 900, między LSP 1000 i LuaSnip 750.

- Nazwy tabel działają dla adapterów rozpoznawanych przez Dadbod.
- Kontekstowe kolumny są wspierane dla PostgreSQL, MySQL, Oracle, SQLite co najmniej 3.37 oraz SQL Server.
- Połączenie jest wybierane z kontekstu DBUI albo kolejno `w:db`, `t:db`, `b:db`, `g:db`, `$DATABASE_URL`.
- Metadane są cache'owane. Po zmianie schematu wykonaj `:DBCompletionClearCache`.
- Grip ma osobne, wbudowane completion i w swoim query padzie nie korzysta z tego źródła `[DB]`.

**Diagnostyka:** sprawdź `:setlocal filetype?`, aktywne `b:db` bez drukowania wartości, `:CmpStatus`, obecność `[DB]` oraz `:DBCompletionClearCache`. Brak klienta CLI, brak połączenia lub brak praw do metadanych może dać pustą listę mimo poprawnie załadowanej wtyczki.

**Źródła przypiętej rewizji:** [README](https://github.com/kristijanhusak/vim-dadbod-completion/blob/a8dac0b3cf6132c80dc9b18bef36d4cf7a9e1fe6/README.md), [źródło nvim-cmp](https://github.com/kristijanhusak/vim-dadbod-completion/tree/a8dac0b3cf6132c80dc9b18bef36d4cf7a9e1fe6/lua), [cache i completion](https://github.com/kristijanhusak/vim-dadbod-completion/tree/a8dac0b3cf6132c80dc9b18bef36d4cf7a9e1fe6/autoload/vim_dadbod_completion).
