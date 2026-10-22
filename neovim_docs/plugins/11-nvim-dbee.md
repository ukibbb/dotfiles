# Bazy danych w `nvim-dbee`

<a id="plugin-nvim-dbee"></a>
## `nvim-dbee`

Pełny workspace baz danych: drawer połączeń i schematów, notatniki SQL, stronicowane wyniki i historia wywołań. Używa sterowników wkompilowanych w backend Go (fork `ukibbb/nvim-dbee`, budowany lokalnie przy instalacji, wymaga Go 1.26.6 i `govulncheck`), więc nie potrzebuje `psql` ani innych klientów CLI.

- **`<leader>Bd`** / **`:Dbee`**: otwórz/zamknij UI.
- **`o`** (drawer): rozwiń/zwiń node; **`Enter`**: aktywuj połączenie, otwórz notatkę albo menu helperów tabeli; **`cw`**: zmień nazwę/edytuj; **`dd`**: usuń; **`r`**: odśwież.
- **`y`** (menu helperów): skopiuj SQL helpera bez wykonania.
- **`Enter`** (edytor): wykonaj instrukcję SQL pod kursorem; **`BB`**: wykonaj cały notatnik (Normal) albo zaznaczenie (Visual).
- **`H` / `L` / `F` / `E`** (wynik): poprzednia / następna / pierwsza / ostatnia strona.
- **`yaj` / `yac`**: skopiuj wiersz (lub zaznaczenie) jako JSON / CSV; **`yaJ` / `yaC`**: wszystkie wiersze.
- **`Ctrl-c`** (wynik, call log): anuluj zapytanie; **`Enter`** (call log): pokaż wcześniejszy wynik.
- **`:Dbee store csv file /tmp/out.csv`**: eksport całego wyniku (nadpisuje plik bez pytania).

### Połączenia

Źródła: zmienna `DBEE_CONNECTIONS` (tablica JSON) oraz `stdpath("state")/dbee/persistence.json` (node `add` w drawerze). Hasła podawaj przez template, nie literalnie:

```sh
export DBEE_CONNECTIONS='[{"id":"pg-dev","name":"PG dev","type":"postgres",
  "url":"postgres://app:{{ env `DBEE_PG_PASSWORD` }}@127.0.0.1:5432/app_db?sslmode=require"}]'
```

### Jak używać

1. `<leader>Bd`, rozwiń połączenie przez `o`, aktywuj je `Enter`.
2. W `local notes` użyj `Enter` na `new`, nadaj nazwę, zapisz `:w`.
3. Wpisz zapytanie i wykonaj `Enter` (instrukcja pod kursorem) albo `BB`.
4. Przeglądaj wynik `H`/`L`, wróć do starszych wyników z call logu.

**Uwaga:** DML/DDL wykonuje się bez potwierdzenia. `exec` w template uruchamia polecenia, więc plik połączeń musi być zaufany. Problemy: `:checkhealth dbee`, log w `stdpath("cache")/dbee/dbee.log`.
