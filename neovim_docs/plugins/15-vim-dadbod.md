# Dadbod, DBUI i completion

<a id="plugin-vim-dadbod"></a>
## `vim-dadbod`

Minimalny interfejs `:DB`, który zamienia URL połączenia na wywołanie natywnego klienta (`psql`, `mysql`, `sqlite3`, `duckdb`, `sqlcmd` z Brewfile). Jest bazą dla DBUI i completion.

- **`:DB [url] {sql}`**: wykonaj zapytanie i pokaż wynik w preview.
- **`:'<,'>DB [url]`**: wykonaj zaznaczone wiersze.
- **`:DB [url]`**: otwórz interaktywną konsolę bazy.
- **`R` / `r` / `gq`** (preview): powtórz zapytanie / edytuj je w command-line / zamknij.

Bez URL Dadbod bierze kolejno `w:db`, `t:db`, `b:db`, `$DATABASE_URL`, `g:db`. Przykłady: `postgresql://USER@HOST:5432/DB`, `sqlite:/abs/sciezka.sqlite3`.

**Uwaga:** URL z hasłem wpisany w command-line trafia do historii i ShaDa. Hasła trzymaj w `.pgpass`/`PGPASSWORD` itp. Brak potwierdzeń dla `DELETE`/`DROP`.

<a id="plugin-vim-dadbod-ui"></a>
## `vim-dadbod-ui`

Drawer połączeń, schematów, tabel i zapisanych zapytań nad Dadbod.

- **`<leader>Bu`**: przełącz drawer.
- **`<leader>Bs`**: zapisz zapytanie DBUI pod nazwą (tylko w buforach DBUI).
- **`<leader>Bp`**: edytuj bind parameters (`:param`) (tylko w buforach DBUI).
- **`o` / `Enter`** (drawer): rozwiń / otwórz połączenie, tabelę, helper lub zapytanie; **`S`**: otwórz w pionowym splicie.
- **`A`**: dodaj połączenie; **`d`**: usuń; **`r`**: zmień nazwę/edytuj; **`R`**: odśwież; **`?`**: pomoc; **`q`**: zamknij.
- **`:DBUIAddConnection`**, **`:DBUIFindBuffer`**, **`:DBUILastQueryInfo`**: dodaj połączenie, przypisz bufor do połączenia, info o ostatnim zapytaniu.

### Jak używać

1. `<leader>Bu`, `A` (lub `:DBUIAddConnection`) i podaj URL.
2. Rozwiń połączenie i tabelę `o`; `Enter` otwiera helper lub nowy bufor zapytania.
3. Wpisz zapytanie i zapisz `:w`, co wykonuje cały bufor (execute-on-save jest włączone).
4. Zamknij wynik `gq`, drawer `<leader>Bu`.

**Uwaga:** profile (`stdpath("data")/db_ui/connections.json`) i zapisane zapytania są plaintextem i mogą zawierać hasła. Upstreamowe `<leader>W/S/E` w SQL są wyłączone (konflikt z Wayfinderem).

<a id="plugin-vim-dadbod-completion"></a>
## `vim-dadbod-completion`

Źródło nvim-cmp z nazwami tabel, kolumn i aliasów z aktywnego połączenia Dadbod/DBUI. Działa w plikach `sql`, `mysql`, `plsql` i pokazuje się jako `[DB]` (po LSP, przed snippetami).

- **`:DBCompletionClearCache`**: odśwież metadane po zmianie schematu.

Pusta lista zwykle oznacza brak aktywnego połączenia (`b:db`/DBUI) albo klienta CLI. W query padzie Grip działa jego własne completion, nie `[DB]`.
