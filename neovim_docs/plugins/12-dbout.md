# Bazy danych w Neovim przez Dbout

<a id="plugin-dbout"></a>
## `zongben/dbout.nvim`

Lekki klient baz (SQLite, PostgreSQL, MySQL, MSSQL, MongoDB) na sterownikach Node.js, z pickerem połączeń w Telescope, Inspectorem obiektów i Viewerem wyników w JSON. Wymaga `node` (build: `npm ci`).

- **`<leader>Bo`**: picker połączeń (Telescope). W Normal pickera: **`Enter`** otwórz w nowym Queryerze, **`a`** dołącz do bieżącego bufora, **`n`** nowy profil, **`e`** edytuj, **`d`** usuń (bez potwierdzenia).
- **`F6`**: wykonaj cały bufor albo zaznaczone pełne wiersze.
- **`F7`**: sformatuj SQL.
- **`F8` / `F9`**: przełącz Inspector / Viewer.
- **`q`**: zamknij bieżący panel (połączenie zostaje).
- **`L` / `H`** (Inspector): następna / poprzednia karta; **`I`**: wybierz obiekt/akcję; **`Backspace`**: wróć; **`R`**: odśwież.
- **`}` / `{`** (Viewer): starszy / nowszy wynik; **`Ctrl-x`**: usuń wpis historii.
- **`:Dbout AttachConnection`**: podłącz profil do istniejącego pliku `.sql`.

Formaty connection stringów: SQLite to absolutna ścieżka pliku (nie `sqlite:///`), PostgreSQL `postgresql://USER:PASS@HOST:5432/DB?sslmode=verify-full`, MySQL `mysql://...`, MSSQL `Server=host,1433;Database=...;User Id=...;Password=...;Encrypt=true`, MongoDB URI z nazwą bazy.

### Jak używać

1. `<leader>Bo`, `Esc`, `n`: wybierz typ, nazwę i connection string.
2. `Enter` na profilu otwiera Queryer z Inspectorem i Viewerem.
3. Wpisz zapytanie, zaznacz jego wiersze i naciśnij `F6` (bez zaznaczenia idzie cały bufor; SQLite/MySQL przyjmują jedną instrukcję naraz).

**Uwaga:**
- Connection string (z hasłem) trafia jawnym tekstem do `stdpath("state")/dbout/db_explorer.json`, historii input/ShaDa i pickera. Używaj kont testowych lub o minimalnych prawach.
- PostgreSQL bez `sslmode` w URI nie weryfikuje certyfikatu; dodaj `?sslmode=verify-full`.
- `F6` wykonuje `DROP`/`DELETE` bez pytania; osobne `F6` to nie jedna transakcja.
- Samo `:Dbout` bez argumentu nic nie otwiera (wymaga Snacks), używaj `<leader>Bo`.
