# Edytowalne siatki w `dadbod-grip.nvim`

<a id="plugin-dadbod-grip"></a>
## `dadbod-grip.nvim`

**Przypięta rewizja:** [`2100fb7b9d817651ff417b8b8b40a061f0812553`](https://github.com/joryeugene/dadbod-grip.nvim/tree/2100fb7b9d817651ff417b8b8b40a061f0812553).

**Co robi i po co:** Grip uruchamia natywne klienty baz, pokazuje schemat, query pad i tabelaryczny grid, pozwala etapować zmiany komórek, oglądać wygenerowany SQL i wykonać zatwierdzone mutacje w transakcji. Może też otwierać CSV, JSON i Parquet przez DuckDB.

### Dokładny stan lokalny

```lua
{
  ai = false,
  completion = true,
  connections_path = vim.fn.stdpath("state") .. "/dadbod-grip/connections.json",
  discovery = false,
  picker = "telescope",
}
```

- **`<leader>Bg`** uruchamia `:GripConnect`.
- Wbudowane completion Grip pozostaje aktywne; w query padzie przejmuje popup zamiast globalnego nvim-cmp.
- AI jest całkowicie wyłączone. `A` i `gA` nie wysyłają schematu ani zapytania do providera.
- Docker discovery jest wyłączone, więc otwarcie pickera nie wykonuje `docker ps`.
- Telescope obsługuje proste pickery, między innymi tabele, historię i command palette. Złożony picker połączeń i zapisanych query pozostaje wbudowany.
- Lazy czyta `lazy.lua` wtyczki, dlatego wszystkie polecenia `:Grip*` są triggerami bez ręcznie utrzymywanej listy `cmd`.

### Wymagane klienty

- **PostgreSQL:** `psql`.
- **MySQL/MariaDB:** `mysql`.
- **SQLite:** `sqlite3`.
- **DuckDB, MotherDuck i pliki:** `duckdb`.
- **SQL Server:** `sqlcmd`.

Wszystkie są instalowane przez `Brewfile`. Grip nie ma własnych sterowników; błąd executable, TLS, uwierzytelnienia albo składni klienta pojawia się w warstwie procesu CLI.

### Model trzech powierzchni

- **`1`**: schema sidebar; ponowne `1` otwiera picker połączeń.
- **`2`**: query pad; ponowne `2` otwiera historię.
- **`3`**: grid; bez aktywnego wyniku otwiera picker tabel.
- **`4`**: diagram relacji.
- **`5`-`9`**: statystyki, kolumny, foreign keys, indeksy i constraints.
- **`Ctrl-p`**: przeszukiwalna command palette na powierzchniach Grip.
- **`?`**: pomoc kontekstowa.

### Query pad

- **`Ctrl-Enter`**: wykonaj Visual selection, SQL fence albo instrukcję oddzieloną pustymi wierszami pod kursorem; cały bufor jest fallbackiem, gdy instrukcja nie zostanie rozpoznana.
- **`Shift-Enter`**: wykonaj i otwórz nowy split wyniku.
- **`Ctrl-s`**: zapisz query pod `.grip/queries/`; w tmux dosłowny klawisz wymaga `Ctrl-s Ctrl-s`.
- **`gn`**: otwórz projektowy notebook `.md` lub `.sql`.
- **`gq`**: wczytaj zapisane query.
- **`gF`**: sformatuj SQL przez pierwszy dostępny formatter albo fallback Lua.
- **`gh`**: historia zapytań.
- **`gb`**: schema sidebar.
- **`gw`**: grid.
- **`gC` / `Ctrl-g`**: zmień połączenie.

Fenced block w Markdown jest wybierany przez implementację notebooka Grip. Parser Treesitter `sql` zapewnia wygląd query pada, lecz nie wybiera ani nie wykonuje zapytania.

### Grid i etapowane zmiany

- **`Enter` / `i`**: edytuj komórkę.
- **`o`**: etapuj nowy wiersz; **`c`** klonuje bieżący; **`d`** przełącza usunięcie.
- **`x`**: ustaw `NULL`; **`p`** wklej do komórki.
- **`u` / `Ctrl-r` / `U`**: undo, redo, wycofanie wszystkich zmian etapowanych.
- **`gs`**: pokaż wygenerowany SQL; **`gc`** kopiuje go.
- **`a`**: po preview wykonaj wszystkie etapowane zmiany.
- **`H` / `L`**: poprzednia / następna strona.
- **`s` / `S`**: sort podstawowy / dodatkowy.
- **`f` / `Ctrl-f` / `F`**: filtr z komórki, własny warunek, wyczyszczenie filtra.
- **`gf` / `gm` / `Ctrl-o`**: przejdź po foreign key, reverse foreign key, wróć.
- **`gE` / `gX`**: eksport do schowka / pliku.

Grip pokazuje preview DML i drugie potwierdzenie, a etapowane zmiany stosuje w transakcji. Jest to ochrona przed przypadkiem, nie granica bezpieczeństwa. Query pad nadal może wykonać dowolny tekst, a undo zatwierdzonej transakcji ma ograniczoną historię i nie zastępuje backupu.

### Polecenia

Najczęstsze polecenia to `:Grip`, `:GripConnect`, `:GripSchema`, `:GripTables`, `:GripQuery`, `:GripSave`, `:GripLoad`, `:GripHistory`, `:GripProfile`, `:GripExplain`, `:GripProperties`, `:GripDiff`, `:GripExport` i `:GripToggle`.

Operacje zmieniające strukturę to `:GripCreate`, `:GripDrop`, `:GripRename` i `:GripFill`. DuckDB federation używa `:GripAttach` oraz `:GripDetach`. `:GripOpen` otwiera lokalny lub zdalny plik, a `:GripStart` uruchamia dołączone demo. `:GripAsk` pozostaje poleceniem, ale lokalne `ai=false` blokuje użycie providera.

### Połączenia i stan

Lokalny `connections_path` przenosi zwykłe profile do jednego pliku:

```text
stdpath("state")/dadbod-grip/connections.json
```

Konfiguracja tworzy brakujący katalog z żądanym trybem POSIX `0700`. Nie poprawia jednak praw już istniejącego katalogu i Grip nie gwarantuje jawnego `0600` ani atomowego zapisu samego JSON-u.

Niestandardowy `connections_path` nie przenosi całego stanu. W root projektu nadal mogą powstać:

- `.grip/history.jsonl` z pełnym SQL i zredagowanym hasłem URL;
- `.grip/filters.json` z zapisanymi filtrami;
- `.grip/queries/*.sql` z zapisanymi query i nagłówkiem `-- grip:url=...`.

Root tego repo ignoruje `.grip/`, ale ta reguła nie chroni innych projektów. Dodaj `.grip/` do właściwego `.gitignore` albo świadomie wersjonuj wyłącznie pliki bez sekretów. Grip szuka rootu przez `.git` lub `.grip`, a bez nich używa bieżącego CWD.

### Sekrety

Profil może zawierać `${NAZWA}` i opcjonalne `env_file`. Grip rozwiązuje zmienną przy łączeniu, odrzuca brakującą albo pustą wartość i przekazuje hasła do `psql`, `mysql` i `sqlcmd` przez środowisko zamiast `argv`. Ta składnia jest własnością Grip: Dadbod `:DB` zobaczy literalne `${NAZWA}`.

Nie wpisuj hasła w zwykłym promptcie ani literalnym URL-u. Prompt korzysta z `vim.fn.input()` i może trafić do historii/ShaDa, a zapisane query może utrwalić URL. Preferuj plik środowiskowy poza repo, chroniony przez system, albo zmienne procesu o ograniczonym czasie życia.

**Wyjątek DuckDB:** federation `ATTACH` osadza DSN w SQL przekazywanym do `duckdb -c`. Hasło attached PostgreSQL/MySQL może być wtedy widoczne w argumentach procesu nawet po użyciu `${VAR}`. Jest to otwarte ograniczenie issue [#39](https://github.com/joryeugene/dadbod-grip.nvim/issues/39); nie federuj credentialed bazy przez DuckDB na niezaufanym hoście.

### Read-only i SQL Server

Profil z `"mode": "ro"` używa lokalnych przełączników klientów, wyłącza edycję grida i blokuje część poleceń DDL. Te ustawienia można odwrócić tekstem SQL albo nadpisać parametrem połączenia. Jedyną wiarygodną granicą jest użytkownik bazy bez praw zapisu.

SQL Server ma read-only grid: edycja komórek i DDL z UI są niedostępne. Query pad nadal przekazuje SQL do `sqlcmd`, w tym potencjalne DML lub DDL. Nie opisuj całej integracji SQL Server jako bezpiecznie tylko do odczytu.

### Completion, pliki i discovery

`completion=true` włącza własny popup nazw tabel, kolumn, aliasów i słów SQL. `Ctrl-Spacja` otwiera go ręcznie. W query padzie Grip wyłącza nvim-cmp buforowo; provider Dadbod `[DB]` nie jest tutaj źródłem kandydatów.

`discovery=false` wyłącza wyłącznie skan Dockera. Picker nadal może skanować lokalne CSV, JSON, Parquet i podobne pliki w CWD. Otwarcie z `--write` pozwala nadpisać plik po potwierdzeniu, a `--watch` okresowo odświeża wynik. Zdalne URL-e są tylko do odczytu.

### Bezpieczny przepływ

1. Uruchom `<leader>Bg` i wybierz profil bez literalnego hasła.
2. W sidebarze sprawdź nazwę połączenia i otwórz tabelę przez `Enter`.
3. Przejdź do query pada przez `2`, wpisz ograniczony `SELECT` i wykonaj `Ctrl-Enter`.
4. Do edycji grida użyj konta testowego. Etapuj pojedynczą zmianę, obejrzyj `gs`, potem dopiero `a`.
5. `u` wycofuje preview albo lokalną zmianę zależnie od kontekstu; po wykonaniu sprawdź dane osobnym odczytem.
6. Przed zamknięciem sprawdź `.grip/`, eksporty i zapisane query pod kątem poufnych danych.

### Diagnostyka

1. Uruchom `:checkhealth dadbod-grip`. Przy `ai=false` ostrzeżenie o braku klucza AI nie blokuje funkcji bazodanowych.
2. Sprawdź właściwy klient przez `:echo executable('psql')`, `mysql`, `sqlite3`, `duckdb` lub `sqlcmd`; health może nie sprawdzić każdego wariantu.
3. Odczytaj opcje bez sekretów przez `:lua vim.print(require('dadbod-grip').get_opts())` i sprawdź `connections_path`, `discovery`, `completion`, `picker`. Stan AI pokaże osobno `:lua =require('dadbod-grip.ai').is_enabled()`; oczekiwane jest `false`.
4. Dla pustego completion sprawdź query pad, aktywne połączenie i `Ctrl-Spacja`; globalny `:CmpStatus` nie diagnozuje wbudowanego popupu Grip.
5. Dla błędu pickera porównaj prosty Telescope z wbudowanym pickerem połączeń. `picker="telescope"` nie obejmuje wszystkich okien.

**Źródła przypiętej rewizji:** [README](https://github.com/joryeugene/dadbod-grip.nvim/blob/2100fb7b9d817651ff417b8b8b40a061f0812553/README.md), [auto-spec Lazy](https://github.com/joryeugene/dadbod-grip.nvim/blob/2100fb7b9d817651ff417b8b8b40a061f0812553/lazy.lua), [setup i polecenia](https://github.com/joryeugene/dadbod-grip.nvim/blob/2100fb7b9d817651ff417b8b8b40a061f0812553/lua/dadbod-grip/init.lua), [mapowania](https://github.com/joryeugene/dadbod-grip.nvim/blob/2100fb7b9d817651ff417b8b8b40a061f0812553/lua/dadbod-grip/keymaps.lua), [adaptery CLI](https://github.com/joryeugene/dadbod-grip.nvim/tree/2100fb7b9d817651ff417b8b8b40a061f0812553/lua/dadbod-grip/adapters).
