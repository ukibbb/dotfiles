# Bazy danych w `nvim-dbee`

<a id="plugin-nvim-dbee"></a>
## `nvim-dbee`

**Co robi i po co:** klient baz danych z frontendem Lua i osobnym backendem Go. Pozwala przeglądać źródła, połączenia, schematy, tabele i kolumny, pisać notatniki SQL, wykonywać zapytania, wracać do historii wywołań oraz eksportować wyniki. Nie uruchamia `psql`, `mysql`, `sqlite3` ani innych klientów CLI; używa sterowników skompilowanych w backendzie.

**Status upstream i forka:** oprogramowanie pozostaje alpha, a README zapowiada breaking changes. Aktywny checkout to kontrolowany fork `ukibbb/nvim-dbee` w commicie `6f2948a5bc958c0cb85c520c29953148663cd362`, zbudowany na bazie upstream `dda517694889a5d238d7aa407403984da9f80cc0`. Fork aktualizuje toolchain i zależności oraz utwardza backend state; nie obiecuje stabilnego API.

**Ładowanie lokalne:** Lazy ładuje wtyczkę po poleceniu `:Dbee` albo launcherze `<leader>Bd`. Launcher nie wywołuje Ex: po załadowaniu wykonuje bezpośrednio `require("dbee").toggle()`. `opts={}` uruchamia defaultowy setup, a zależnością UI jest `nui.nvim`.

**Aktywne lokalne:** `<leader>Bd`, polecenie `:Dbee`, domyślne źródła `EnvSource("DBEE_CONNECTIONS")` i `FileSource(stdpath("state") .. "/dbee/persistence.json")`, wszystkie wewnętrzne mapowania upstream bez zmian oraz parser Treesitter `sql`. Lock przypina fork `6f2948a5bc958c0cb85c520c29953148663cd362`. Synchroniczny hook wymaga dokładnego Go 1.26.6, buduje tymczasowy kandydat z cgo, skanuje go przez `govulncheck -mode=binary` i dopiero po sukcesie atomowo zastępuje runtime. Zainstalowane binarium ma raportować dokładnie hash forka; żaden prebuild upstream nie jest aktywny.

**Wymagania:** Neovim co najmniej 0.10, `nui.nvim`, dokładnie Go 1.26.6, `govulncheck`, kompilator C dla cgo, Git dla pełnego healthchecku, parser `sql` dla akcji pod kursorem oraz osiągalna baza z odpowiednimi uprawnieniami. Nerd Font jest przydatny dla ikon. Wyłączenie wszystkich ikon wymaga osobno `drawer.disable_candies=true` i `call_log.disable_candies=true`.

### Mentalny model

- **Source** dostarcza rekordy `{ id, name, type, url }`. Źródło może być tylko do odczytu albo implementować tworzenie, edycję, usuwanie i ręczną edycję pliku.
- **Connection** to jedna instancja adaptera. W całym DBee istnieje jedno aktywne połączenie, używane przez skróty edytora i `require("dbee").execute()`.
- **Adapter** wybiera sterownik po dokładnej, rozróżniającej wielkość liter wartości `type`, buduje drzewo struktury i dostarcza helpery tabel.
- **Call** to asynchroniczne wykonanie zapytania ze stanem `unknown`, `executing`, `executing_failed`, `retrieving`, `retrieving_failed`, `archived`, `archive_failed` albo `canceled`.
- **Result** buforuje wszystkie wiersze i archiwizuje je na dysku. `page_size` ogranicza tylko liczbę wierszy pokazywanych naraz, nie liczbę pobieraną z serwera.
- **UI** składa się z drawera, edytora, wyniku i call logu. Lokalny `opts={}` wykonuje `setup()` podczas ładowania, a core i cztery komponenty UI inicjalizują się dopiero przy pierwszej operacji, która ich potrzebuje.
- `setup()` wolno wywołać tylko raz. `require("dbee").install()`, `api.core.is_loaded()` i `api.ui.is_loaded()` są wyjątkami używalnymi przed setup. Pozostałe operacyjne funkcje core/UI oraz top-level `open`, `close`, `toggle`, `is_open`, `execute` i `store` wymagają wcześniejszego setup.

### Domyślny układ i jego cykl życia

- **Góra po lewej:** drawer ze źródłami, notatkami, połączeniami i strukturą; szerokość 40.
- **Dół po lewej:** call log aktywnego połączenia; wysokość 20.
- **Góra po prawej:** edytor notatnika SQL.
- **Dół po prawej:** wynik; wysokość 20.
- Po otwarciu fokus trafia do edytora. Po rozpoczęciu pobierania wyniku domyślne `focus_result=true` przenosi go do panelu wyniku.

`open()` zapisuje układ niefloatingowych okien bieżącej karty, zamyka je i tworzy cztery okna DBee. `close()` zamyka okna DBee i odtwarza drzewo splitów, bufory, rozmiary i opcje window-local. Nie odtwarza tych samych identyfikatorów okien ani pełnego widoku i pozycji każdego okna; floating windows są pomijane. Jest to odtworzenie struktury, nie snapshot całego stanu Neovim.

Domyślne `on_switch="immutable"` nie pozwala zastąpić bufora w panelu DBee: autocmd ponownie pokazuje właściwy panel. Opcjonalne `on_switch="close"` zamyka całe UI, gdy inne polecenie próbuje otworzyć obcy bufor w jego oknie. Zamknięcie któregokolwiek z czterech okien również zamyka całość i próbuje odtworzyć poprzedni układ.

`:Dbee open` na już otwartym UI tylko resetuje szerokości i wysokości. W tej rewizji `reset()` omyłkowo ustawia wysokość call logu z `result_height`, a nie `call_log_height`; różnica jest widoczna dopiero przy niestandardowych, nierównych wartościach.

### Drawer: wszystkie domyślne mapowania

- **`r`**: Przebuduj drawer i ponownie pobierz widoczną strukturę. **Tryb:** `n`.
- **`Enter`**: Akcja kontekstowa `action_1`. Aktywuje połączenie, otwiera notatkę, uruchamia dodawanie/edycję źródła, otwiera wybór bazy albo menu helperów tabeli/widoku. **Tryb:** `n`.
- **`cw`**: Akcja kontekstowa `action_2`. Zmienia nazwę notatki albo edytuje połączenie, jeśli jego source implementuje `update`. **Tryb:** `n`.
- **`dd`**: Akcja kontekstowa `action_3`. Po potwierdzeniu usuwa notatkę albo połączenie, jeśli source implementuje `delete`. **Tryb:** `n`.
- **`o`**: Rozwiń albo zwiń node. Leniwie pobierane są struktura połączenia oraz kolumny tabeli lub widoku; node schematów i ich dzieci powstają już z pobranej struktury. **Tryb:** `n`.
- **`Enter` w menu**: Zatwierdź wybór. **Tryb:** `n`.
- **`y` w menu helperów**: Skopiuj tekst helpera do aktywnego rejestru bez wykonania. W menu bez callbacku yank klawisz nic nie robi. **Tryb:** `n`.
- **`Esc` / `q` w menu**: Zamknij popup bez wyboru. **Tryb:** `n`.
- **`j` / `Down` / `Tab`**: Następna pozycja popupu wyboru. **Stan:** wbudowane w menu NUI.
- **`k` / `Up` / `Shift-Tab`**: Poprzednia pozycja popupu wyboru. **Stan:** wbudowane w menu NUI.
- **`Enter` w edytowalnym formularzu połączenia**: W trybie Insert wykonaj `:w`, zatwierdź formularz i wróć do Normal. **Stan:** wbudowane w float CRUD.
- **`q` w formularzu połączenia albo edytorze pliku source**: Zamknij float. **Tryb:** `n`. **Stan:** wbudowane w float CRUD.

Akcje `collapse` i `expand` istnieją w API drawera, lecz komentowane przykłady `c` i `e` nie są domyślnymi mapowaniami. `cw` i `dd` na połączeniu z `EnvSource` albo `MemorySource` celowo nic nie wykonują, ponieważ te źródła nie mają metod zapisu.

### Edytor: wszystkie domyślne mapowania

- **`BB`**: Wykonaj cały bieżący notatnik na aktywnym połączeniu. **Tryb:** `n`.
- **`BB`**: Wykonaj dokładnie zaznaczenie. **Tryb:** `v`.
- **`Enter`**: Znajdź przez Treesitter instrukcję SQL pod kursorem, podświetl ją na 750 ms i wykonaj. **Tryb:** `n`.

Notatniki mają domyślnie `filetype=sql`. Akcja `Enter` działa tylko dla tego filetype i parsera `sql`; lokalnie parser jest dostępny. Implementacja zamienia puste wiersze na tymczasowe średniki, wybiera root node typu `statement`, a przed wysłaniem usuwa z niego wszystkie znaki `;`. To jest wygodne dla zwykłego SQL, ale może zmienić średnik umieszczony wewnątrz literału. Dla MongoDB i Redis używaj raczej Visual `BB`, Normal `BB` albo API, ponieważ JSON/komenda Redis nie muszą tworzyć poprawnego node SQL.

### Wynik: wszystkie domyślne mapowania

- **`L`**: Następna strona. **Tryb konfiguracji:** `""`.
- **`H`**: Poprzednia strona. **Tryb konfiguracji:** `""`.
- **`E`**: Ostatnia znana strona. **Tryb konfiguracji:** `""`.
- **`F`**: Pierwsza strona. **Tryb konfiguracji:** `""`.
- **`yaj`**: Bieżący wiersz jako JSON; w Visual zakres wierszy jako JSON. **Tryb:** odpowiednio `n` i `v`.
- **`yaJ`**: Wszystkie wiersze jako JSON. **Tryb konfiguracji:** `""`.
- **`yac`**: Bieżący wiersz jako CSV; w Visual zakres wierszy jako CSV. **Tryb:** odpowiednio `n` i `v`.
- **`yaC`**: Wszystkie wiersze jako CSV. **Tryb konfiguracji:** `""`.
- **`Ctrl-c`**: Poproś o anulowanie bieżącego calla. **Tryb konfiguracji:** `""`.

Przed `yaj` albo `yac` ustaw kursor na rzeczywistym wierszu danych. Mapowania przekazują `vim.v.register`, więc na przykład `"+yaj` używa rejestru systemowego. Nie ma domyślnego mapowania formatu `table`; jest dostępny przez `store()`.

### Call log: wszystkie domyślne mapowania

- **`Enter`**: Pokaż wynik wskazanego calla, ale tylko gdy ma stan `retrieving` albo `archived`. **Tryb konfiguracji:** `""`.
- **`Ctrl-c`**: Poproś o anulowanie wskazanego calla. **Tryb konfiguracji:** `""`.

Lista dotyczy aktywnego połączenia, jest sortowana od najnowszego calla i odświeża się przy zmianie stanu. Ruch kursora pokazuje float z ID, zapytaniem, stanem, czasem, timestampem i błędem. Nie ma domyślnej akcji czyszczenia historii.

### Pierwszy przepływ pracy

1. Załaduj wtyczkę przez `:Lazy load nvim-dbee`, uruchom `:checkhealth dbee`, a następnie `<leader>Bd` albo `:Dbee`.
2. W drawerze rozwiń source i połączenie przez `o`. `Enter` na połączeniu ustawia je jako aktywne; wyróżniona nazwa pokazuje bieżący wybór.
3. W `global notes` albo `local notes` użyj `Enter` na `new`, wpisz nazwę i zatwierdź. Rozszerzenie `.sql` jest dopisywane automatycznie.
4. Zapisz notatnik przez `:w`, jeżeli ma przetrwać restart. Samo utworzenie node nie zapisuje jeszcze treści na dysku.
5. Wykonaj pojedynczą instrukcję `Enter`, zaznaczenie `BB` albo cały plik `BB`.
6. W panelu wyniku użyj `H/L/F/E`, a w call logu `Enter`, aby wrócić do wcześniejszego wyniku.
7. Zamknij UI przez `<leader>Bd`, `:Dbee`, `:Dbee toggle` albo `:Dbee close`. Poprzedni układ splitów zostanie odtworzony best effort.

### Źródła i identyfikatory połączeń

**Default upstream i aktywne lokalnie:** źródła są ładowane w kolejności `DBEE_CONNECTIONS`, potem `stdpath("state") .. "/dbee/persistence.json"`.

- **`EnvSource:new("DBEE_CONNECTIONS")`**: Czyta tablicę JSON z procesu Neovim. Pomija elementy bez `url` albo `type`, automatycznie nadaje brakujące ID w postaci `environment_source_DBEE_CONNECTIONS_{index}` i nie obsługuje interaktywnego CRUD.
- **`FileSource:new(path)`**: Czyta tablicę JSON z pliku, ignorując całe wiersze zaczynające się po trim od `//`. Obsługuje `create`, `update`, `delete` i `file`, dlatego drawer pokazuje `add` oraz `edit source`.
- **`MemorySource:new(connections, name?)`**: Czyta tabelę Lua, a ID ustawia na `memory_source_{name}{index}`. Nie utrwala zmian i nie oferuje CRUD.
- **Custom source, opcjonalne upstream:** musi implementować `name()` i `load()`. Metody `create(details)`, `update(id, details)`, `delete(id)` i `file()` są opcjonalne.

`Source:name()` jest jednocześnie ID source w handlerze, więc musi być unikalne. Dla `FileSource` jest nim sam basename pliku; dwa pliki o tej samej nazwie w różnych katalogach kolidują. Każde połączenie również musi mieć stabilne, unikalne ID. Interaktywny `FileSource.add` generuje ID, ale przy ręcznej edycji pliku jest to odpowiedzialność użytkownika.

Przykład bez sekretów:

```sh
export DBEE_CONNECTIONS='[
  {
    "id": "local-sqlite-example",
    "name": "SQLite example",
    "type": "sqlite",
    "url": "~/tmp/dbee-example.sqlite"
  }
]'
```

Przy `default_connection=nil` backend ustawia jako aktywne każde właśnie tworzone połączenie. Jeśli źródła zwrócą wiele rekordów, ostateczny wybór zależy od kolejności ładowania; wybierz go jawnie przez `Enter`. Opcja `default_connection="stable-id"` próbuje nadpisać ten wybór po załadowaniu źródeł.

### Co i gdzie jest utrwalane

- **Połączenia FileSource:** `vim.fn.stdpath("state") .. "/dbee/persistence.json"`. Dokładną ścieżkę pokaże `:lua =vim.fn.stdpath("state") .. "/dbee/persistence.json"`.
- **Globalne notatki:** `vim.fn.stdpath("state") .. "/dbee/notes/global"`.
- **Lokalne notatki:** `vim.fn.stdpath("state") .. "/dbee/notes/{connection_id}"`; słowo „local” oznacza namespace aktywnego połączenia, nie katalog projektu.
- **Backend lokalnego builda:** `vim.fn.stdpath("data") .. "/dbee/bin/dbee"`.
- **Cache opcjonalnego instalatora upstream:** `vim.fn.stdpath("cache") .. "/dbee/build"`; aktywny lokalny hook go nie używa.
- **Log backendu:** `vim.fn.stdpath("cache") .. "/dbee/dbee.log"`.
- **Prywatny root backendu:** `vim.fn.stdpath("state") .. "/dbee/backend"`, przekazywany procesowi jako absolutne `DBEE_STATE_DIR`.
- **Metadane call logu:** `stdpath("state")/dbee/backend/call-log.json`.
- **Zarchiwizowane wyniki:** `stdpath("state")/dbee/backend/history/{call_id}/` jako `meta.gob`, `header.gob`, porcje `row_*.gob` i marker kompletności.

Globalne notatki są wspólne dla wszystkich połączeń. Local notes są powiązane wyłącznie z ID połączenia; zmiana ID w JSON tworzy nowy namespace i pozostawia stary katalog bez automatycznej migracji. Call log jest zapisywany przy zamknięciu procesu backendu, a nie po każdym zapytaniu. Awaria procesu może więc utracić najnowszą listę, choć niekompletny katalog wyniku nie jest już publikowany jako gotowe archiwum.

### Wszystkie 12 adapterów, aliasy i formaty połączeń

Wartość `type` jest case-sensitive. Poniższe aliasy pochodzą z rejestracji tej rewizji; DSN jest następnie przekazywany do wskazanego sterownika Go.

- **PostgreSQL:** `postgres`, `postgresql`, `pg`. Format źródłowy: `postgres://USER:PASSWORD@HOST:5432/DB?sslmode=require`. Obsługuje realne przełączanie bazy przez ponowne połączenie. Helpery: `List`, `Columns`, `Indexes`, `Foreign Keys`, `References`, `Primary Keys`.
- **MySQL:** `mysql`. Sterownikowy DSN, nie URL: `USER:PASSWORD@tcp(HOST:3306)/DB?tls=true`. DBee zawsze dopisuje `multiStatements=true`; wykrywanie istniejącego `?param=value` jest prostym regexem, więc nietypowy pierwszy parametr może dać błędne dwa znaki `?`. Brak DatabaseSwitcher. Helpery: `List`, `Columns`, `Indexes`, `Foreign Keys`, `Primary Keys`.
- **SQLite:** `sqlite`, `sqlite3`. `url` jest ścieżką, na przykład `~/tmp/app.sqlite`, `/absolute/app.sqlite` albo sterownikowe `:memory:`. Rozwijane są tylko `~` i prefiks `~/`. Adapter wystawia atrapę przełącznika: drawer może pokazać `not supported yet`, a wybór jest no-op. Helpery: `List`, `Columns`, `Indexes`, `Foreign Keys`, `Primary Keys`.
- **Microsoft SQL Server:** `sqlserver`, `mssql`. Najbezpieczniejszy dla tej implementacji jest URL `sqlserver://USER:PASSWORD@HOST:1433?database=DB&encrypt=true`; źródło parsuje go przez `net/url`, a przełącznik modyfikuje parametr `database`. Backend importuje także Kerberos integrated auth sterownika, ale uwierzytelnienie i parametry pozostają kontraktem go-mssqldb. Helper `List` generuje `SELECT top 200 * from [TABLE]` bez schematu, więc dla tabeli poza schematem domyślnym może wskazać zły obiekt albo zakończyć się błędem. Helper `Describe` generuje niepoprawne `exec sp_help ''SCHEMA.TABLE''` z podwojonymi apostrofami. Pozostałe helpery: `Columns`, `Indexes`, `Foreign Keys`, `References`, `Primary Keys`, `Constraints`.
- **Oracle:** `oracle`. Format potwierdzony w testach: `oracle://USER:PASSWORD@HOST:1521/SERVICE`; opcje sterownika mogą być dopisane jako query string. Brak DatabaseSwitcher. Adapter usuwa jeden końcowy średnik przed wysłaniem. Helpery: `List`, `Columns`, `Indexes`, `Foreign Keys`, `References`, `Primary Keys`.
- **ClickHouse:** `clickhouse`. Native DSN `clickhouse://USER:PASSWORD@HOST:9000/DB`, a parser zależności rozpoznaje także `http://HOST:8123/DB` i `https://HOST:8443/DB?secure=true` oraz query options. W tej wersji samo `https://` bez `secure=true` jest odrzucane. Connect wykonuje ping z limitem 5 s. Obsługuje realne przełączanie bazy. Helpery: `List`, `Columns`, `Info`.
- **Amazon Redshift:** `redshift`. Używa sterownika PostgreSQL i URL w stylu `postgres://USER:PASSWORD@HOST:5439/DB?sslmode=require`, mimo że `type` pozostaje `redshift`. Connect i zmiana bazy pingują z limitem 5 s. Helpery tabel: `List`, `Columns`, `Indexes`, `Foreign Keys`, `Table Definition`; helpery widoku: `List`, `View Definition`.
- **MongoDB:** `mongo`, `mongodb`. `mongodb://USER:PASSWORD@HOST:27017/DB` albo delegowane do mongo-driver `mongodb+srv://.../DB`. W tej rewizji ścieżka `/DB` powinna być obecna: adapter bezwarunkowo wykonuje `u.Path[1:]`, więc pusty path może wywołać panic. Zapytanie jest pojedynczą komendą Mongo Extended JSON, na przykład `{"find":"users","filter":{"active":true}}`, a nie JavaScriptem z `mongosh`. Obsługuje zmianę bazy. Helper: `List` jako `{"find":"COLLECTION"}`.
- **Redis:** `redis`. Formaty parsera: `redis://USER:PASSWORD@HOST:6379/0`, TLS `rediss://.../0` oraz `unix://USER:PASSWORD@/path/to/redis.sock?db=0`. Zapytanie jest surową komendą, na przykład `GET key`; parser obsługuje pojedyncze i podwójne cudzysłowy, ale nie jest pełnym parserem shell. Brak DatabaseSwitcher. Helper `List` wykonuje `KEYS *`, co może być kosztowne na dużej instancji.
- **DuckDB:** `duck`, `duckdb`. `url` jest surową ścieżką do pliku; pusty string oznacza bazę in-memory. W przeciwieństwie do SQLite adapter nie rozwija `~`. Adapter wystawia atrapę przełącznika z `not supported yet`; wybór jest no-op. Helpery: `List`, `Columns`, `Indexes`, `Constraints`.
- **Google BigQuery:** `bigquery`. Format `bigquery://PROJECT?credentials=/path/creds.json&max-bytes-billed=1000000`; pusty project uruchamia Google Default Credentials i autodetekcję projektu. Parametr `location`, mimo wymienienia w komentarzu adaptera, jest w tej rewizji nieskuteczny: mapper ustawia wyłącznie pola `bigquery.QueryConfig`, a lokalizacja należy do obiektu query i nie jest nigdzie przypisywana. Mapper wraca też po pierwszym dopasowanym polu, więc nie zakładaj, że wiele parametrów `QueryConfig` naraz zostanie zastosowanych; `credentials`, `endpoint` i `enable-storage-read` są obsługiwane osobno. Podanie `endpoint` wyłącza uwierzytelnienie, używa insecure gRPC i pomija walidację dial settings, dlatego nadaje się wyłącznie do zaufanej lokalnej infrastruktury testowej. Helper `List` generuje niekwalifikowane ``SELECT * FROM `TABLE` TABLESAMPLE SYSTEM (5 PERCENT)`` i zwykle wymaga skonfigurowanego domyślnego datasetu; w innym przypadku skopiuj helper i jawnie kwalifikuj `PROJECT.DATASET.TABLE`. Brak DatabaseSwitcher. Drugi helper to `Columns`.
- **Databricks:** `databricks`. DSN ma postać `token:TOKEN@HOST:443/sql/1.0/endpoints/WAREHOUSE?catalog=CATALOG`; `catalog` jest obowiązkowy. Przełącznik zmienia katalog przez nowy DSN. Helpery: `List`, `Columns`, `Describe`, `Constraints`, `Keys`. W tej rewizji tekst helpera `Columns` używa `information_schema.column` w liczbie pojedynczej, podczas gdy rozwijanie kolumn używa poprawnego `information_schema.columns`; błąd helpera nie musi oznaczać awarii całego adaptera.

Aktywny lokalny backend jest cgo buildem z dokładnie tej rewizji na Darwin i zawiera wszystkie 12 wymienionych adapterów. SQLite oraz DuckDB nadal mają build constraints istotne przy przenoszeniu konfiguracji na inną platformę.

### Aktywne połączenie, baza, schemat i helpery

- `Enter` na node połączenia ustawia globalnie aktywne połączenie. Edytor i call log przełączają kontekst; otwarta local note z poprzedniego namespace nie jest automatycznie tą samą notatką nowego połączenia.
- `o` na połączeniu pobiera strukturę. Schemat to grupa tabel i widoków zwrócona przez adapter, a nie osobne połączenie ani zawsze osobna baza.
- Node `database_switch` pojawia się tylko wtedy, gdy adapter zwróci niepustą bieżącą bazę i co najmniej jedną pozycję dostępną. `Enter` otwiera wybór i po sukcesie przebudowuje drawer.
- `o` na tabeli lub widoku pobiera kolumny z typami. Brak uprawnień do katalogów systemowych może zepsuć drzewo mimo działającego ręcznego `SELECT`.
- `Enter` na tabeli lub widoku otwiera alfabetyczną listę helperów. `Enter` wykonuje helper natychmiast, a `y` kopiuje SQL do aktywnego rejestru do review.
- Helpery `List` dodają własne limity tylko tam, gdzie wskazano je w adapterze. Nie traktuj menu helperów jako gwarantowanego trybu read-only; custom helper może wykonywać dowolny tekst.

**Opcjonalne upstream:** dodatkowe helpery można dodać w setup albo runtime. Nazwa z `extra_helpers` ma pierwszeństwo nad wbudowaną nazwą, a wartości są Go templates z `.Table`, `.Schema` i `.Materialization`:

```lua
require("dbee").api.core.add_helpers {
  postgres = {
    ["Count rows"] = 'SELECT count(*) FROM "{{ .Schema }}"."{{ .Table }}"',
  },
}
```

### Notatki globalne i lokalne

- Drawer zawsze pokazuje `global notes`; `local notes` pojawia się po wybraniu aktywnego połączenia.
- `Enter` na `new` tworzy rekord i bufor o sugerowanej ścieżce. Dopiero `:w` zapisuje treść.
- `Enter` na istniejącej notatce otwiera ją w panelu edytora.
- `cw` zmienia nazwę i, jeśli plik istnieje, wykonuje rename na dysku.
- `dd` pyta `Yes/No`, po czym usuwa plik przez `vim.fn.delete()` i rekord z bieżącego namespace.
- Kropka `●` przy nazwie oznacza zmodyfikowany bufor.
- Przy pierwszym uruchomieniu bez globalnych notatek powstaje bufor `welcome.sql`; wejście w Insert jednorazowo czyści banner.

Notatki nie są związane z CWD ani rootem Git. Mogą zawierać wrażliwy SQL i są zwykłymi plikami pod `stdpath("state")`.

### Wykonanie, paginacja i anulowanie

Po wysłaniu zapytania backend zwraca `CallDetails` natychmiast. Stan przechodzi przez `executing`, potem `retrieving`; iterator jest równolegle opróżniany do pamięci, a po sukcesie cały wynik jest serializowany pod prywatnym `stdpath("state")/dbee/backend/history`. Pierwsza strona może pojawić się po zgromadzeniu `page_size` wierszy albo po końcu iteratora.

Domyślne `page_size=100`. `F/H/L/E` zmienia tylko wycinek już buforowanego wyniku. Winbar ma format `bieżąca/łączna (wiersze) Took ...`. Liczba stron jest liczona z długości cache w chwili renderowania; przy wolnym streamie może być chwilowo zaniżona. Po stanie `archived` użyj `require("dbee").api.ui.result_page_current()` albo ponownie `Enter` na callu, jeżeli `L` nie widzi jeszcze dalszych stron.

`Ctrl-c` wywołuje `call_cancel`, ale `Call.Cancel()` tej rewizji działa tylko w stanach `unknown` i `executing`. Po wejściu w `retrieving` metoda wraca bez anulowania, więc nie zatrzyma długiego opróżniania lub archiwizacji wyniku. Anulowanie zależy też od respektowania kontekstu przez konkretny sterownik.

### Eksport i dokładna semantyka zakresów

Formaty to `csv`, `json` i `table`. Cele to `file`, `buffer` i `yank`.

- Zakres jest zero-based i półotwarty: `from` wchodzi, `to` nie wchodzi.
- `{ from=0, to=1 }` oznacza pierwszy wiersz; `{ from=0, to=0 }` pusty zakres.
- Brak wartości jest normalizowany do `{ from=0, to=-1 }`, czyli wszystkich wierszy.
- Ujemny indeks jest liczony jako `length + 1 + index`; `-1` oznacza koniec, `-2` granicę przed ostatnim wierszem, a `{ from=-3, to=-1 }` ostatnie dwa wiersze.
- Dwa indeksy nieujemne albo dwa ujemne muszą spełniać `from <= to`.
- Ujemne `from` z nieujemnym `to` jest nieprawidłowe. Nieujemne `from` z ujemnym `to`, w tym domyślne `0,-1`, przechodzi walidację.
- Granice poza wynikiem są przycinane do `0..length`.
- Każde ujemne `to`, a więc także eksport wszystkich wierszy, czeka na pełne opróżnienie iteratora. Wewnętrzny timeout oczekiwania wynosi 5 minut.

Kod nie sprawdza kolejności granic ponownie po rozwiązaniu mieszanego zakresu. Na przykład nieujemne `from` i ujemne `to`, które po przeliczeniu znajdzie się przed `from`, może doprowadzić do panic przy slice. Poza bezpiecznym `0,-1` preferuj dwa indeksy nieujemne albo dwa ujemne i sam dopilnuj końcowego `from <= to`.

Przykłady API:

```lua
-- Całość jako CSV do bieżącego bufora. Treść bufora zostanie zastąpiona.
require("dbee").store("csv", "buffer", { from = 0, to = -1, extra_arg = 0 })

-- Wiersze o indeksach 2..6 jako JSON. Plik zostanie utworzony lub obcięty.
require("dbee").store("json", "file", {
  from = 2,
  to = 7,
  extra_arg = "/tmp/dbee-rows.json",
})

-- Pierwszy wiersz jako tabela do systemowego schowka.
require("dbee").store("table", "yank", { from = 0, to = 1, extra_arg = "+" })

-- Ostatnie dwa wiersze jako CSV do systemowego schowka.
require("dbee").store("csv", "yank", { from = -3, to = -1, extra_arg = "+" })
```

CSV zawsze zawiera nagłówek. JSON dla typowych wyników SQL jest tablicą obiektów według nazw kolumn, a dla schemaless MongoDB/Redis tablicą odpowiedzi. `table` dodaje numery wierszy. Cel `file` używa `os.Create`, więc bez pytania obcina istniejący plik; nie tworzy katalogu nadrzędnego. Cel `buffer` zastępuje całą treść wskazanego bufora. Cel `yank` nadpisuje wskazany rejestr.

### Wszystkie polecenia Ex

- **`:Dbee`**: Bez argumentu działa jak `toggle` i jest lokalnym triggerem Lazy.
- **`:Dbee open`**: Otwórz UI; jeśli już jest otwarte, zresetuj rozmiary.
- **`:Dbee close`**: Zamknij UI i spróbuj odtworzyć poprzedni układ.
- **`:Dbee toggle`**: Otwórz albo zamknij.
- **`:Dbee execute {query}`**: Połącz pozostałe tokeny pojedynczymi spacjami, wykonaj na aktywnym połączeniu i otwórz UI.
- **`:Dbee store {csv|json|table} {file|yank|buffer} {extra_arg}`**: Zapisz cały aktualnie wyświetlany wynik, domyślnym zakresem `0,-1`.

Przykłady:

```vim
:Dbee execute SELECT current_timestamp
:Dbee store csv file /tmp/result.csv
:Dbee store json yank +
:Dbee store table buffer 0
```

`store` wymaga co najmniej trzech argumentów po nazwie subcommand, także dla `yank`. `extra_arg` oznacza ścieżkę pliku, nazwę rejestru albo numer bufora. Parser Ex dzieli po spacji, tabie i `|`, redukuje odstępy oraz przez wspólną funkcję usuwa każde literalne wystąpienie `Dbee` także z właściwych argumentów. Nie implementuje shellowego quoting ani zakresów `from/to`, więc ścieżka ze spacją i złożone wielowierszowe SQL powinny użyć API lub edytora. Nie istnieją subcommandy `setup`, `install`, `health`, `is_open` ani bezpośrednie zarządzanie połączeniami.

### Tutorial: lokalny SQLite od zera

1. Utwórz katalog nadrzędny i wystartuj Neovim z jednorazowym źródłem środowiskowym:

```sh
mkdir -p "$HOME/tmp"
export DBEE_CONNECTIONS='[
  {
    "id": "tutorial-sqlite",
    "name": "SQLite tutorial",
    "type": "sqlite",
    "url": "~/tmp/dbee-tutorial.sqlite"
  }
]'
nvim
```

2. Użyj `<leader>Bd`, rozwiń `DBEE_CONNECTIONS`, ustaw `SQLite tutorial` jako aktywne przez `Enter`, rozwiń je `o` i utwórz local note.
3. Wklej poniższy SQL. Ustawiaj kursor kolejno w każdej instrukcji i naciskaj `Enter`; nie uruchamiaj od razu całego pliku, dopóki nie przejrzysz DDL/DML.

```sql
CREATE TABLE IF NOT EXISTS people (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  active INTEGER NOT NULL DEFAULT 1
);

INSERT INTO people (name, active) VALUES ('Ada', 1);

SELECT id, name, active
FROM people
ORDER BY id;
```

4. Zapisz notatnik `:w`. Odśwież drawer przez `r` albo zwiń i ponownie rozwiń połączenie przez `o`, potem schema `sqlite_schema`, tabelę `people` i jej kolumny.
5. `Enter` na `people` otwiera helpery. Najpierw `y` na `List`, aby obejrzeć SQL, albo `Enter`, aby wykonać `SELECT * FROM "people" LIMIT 500`.
6. Wyeksportuj wszystkie wiersze przez `:Dbee store csv file /tmp/people.csv`. Polecenie nadpisze istniejący plik.
7. Połączenie z `EnvSource` żyje tak długo, jak zmienna jest obecna w środowisku nowych procesów. Aby utrwalić sam rekord bez zmiennej, użyj node `add` pod source `persistence.json`; dla SQLite nie zapisujesz tam sekretu.

Plik SQLite jest niezależny od konfiguracji DBee i pozostaje pod `~/tmp`. Usunięcie połączenia z FileSource nie usuwa samej bazy.

### Tutorial: PostgreSQL lub inna baza serwerowa

1. Przekaż sekrety osobno i zbuduj rekord z template. Poniższy przykład nie zapisuje hasła w repo ani w `persistence.json`:

```sh
export DBEE_PG_USER='app_user'
export DBEE_PG_PASSWORD='replace-in-shell-only'
export DBEE_PG_DATABASE='app_db'
export DBEE_CONNECTIONS='[
  {
    "id": "postgres-dev",
    "name": "PostgreSQL dev",
    "type": "postgres",
    "url": "postgres://{{ env `DBEE_PG_USER` }}:{{ env `DBEE_PG_PASSWORD` }}@127.0.0.1:5432/{{ env `DBEE_PG_DATABASE` }}?sslmode=require"
  }
]'
nvim
```

2. Jeśli hasło lub nazwa zawiera `@`, `:`, `/`, `?`, `#` albo `%`, przekaż wartość już percent-encoded. Template wstawia tekst dosłownie i nie wykonuje URL encoding.
3. Otwórz DBee, aktywuj połączenie i rozwiń je. Błąd samego drzewa może oznaczać brak praw do `information_schema` lub `pg_catalog`, nawet gdy zwykły query działa.
4. Uruchom najpierw zapytanie diagnostyczne bez modyfikacji danych:

```sql
SELECT current_database(), current_schema(), current_user;
```

5. Jeśli drawer pokazuje node bazy, `Enter` wybiera inną bazę i tworzy nowe połączenie sterownika z tym samym hostem oraz użytkownikiem. To nie zmienia aktywnego connection ID ani DSN zapisanego w source.
6. Utwórz local note, zapisz ją i wykonuj kontrolowane zaznaczenia przez Visual `BB`. Dla `UPDATE`, `DELETE`, DDL i procedur DBee nie daje dodatkowego potwierdzenia.
7. Rozwiń tabelę, skopiuj helper przez `y`, przejrzyj limit i kwalifikację schematu, dopiero potem wykonaj.
8. Obserwuj stany w call logu. `Ctrl-c` ma sens podczas `executing`; po przejściu w `retrieving` ta rewizja już nie anuluje pobierania.

Dla MySQL, SQL Server, Oracle, ClickHouse, Redshift, MongoDB, Redis, BigQuery, DuckDB i Databricks przepływ UI jest taki sam, ale `type`, DSN, język zapytania, TLS i uprawnienia muszą odpowiadać katalogowi adapterów powyżej.

### Sekrety `env` i `exec`

Każde z czterech pól połączenia, czyli `id`, `name`, `type` i `url`, przechodzi przez Go `text/template`. Dostępne funkcje to `{{ env "NAME" }}` i `{{ exec "command args" }}`. W JSON wygodniejsze bywają backticki template, jak w tutorialu PostgreSQL.

- `env` czyta środowisko procesu backendu w chwili tworzenia połączenia.
- Brakująca zmienna `env` nie jest błędem template; rozwija się do pustego tekstu.
- `exec` bez tekstu ` | ` dzieli argument po zwykłych spacjach i uruchamia executable bez shellowego quoting.
- `exec` zawierające dokładnie spacje wokół pipe, czyli ` | `, uruchamia cały tekst przez `sh -c`.
- Wynik `exec` jest trimowany.
- Błąd parsowania lub wykonania template jest cicho ignorowany przez `expandOrDefault`; do adaptera trafia wtedy oryginalny tekst z `{{ ... }}`, co może wyglądać jak błąd DSN zamiast błąd sekretu.

`exec` jest wykonaniem kodu. Plik połączeń, zmienna `DBEE_CONNECTIONS` i custom source muszą być zaufane. Nie otwieraj nieznanego persistence JSON tylko po to, aby sprawdzić jego zawartość w drawerze.

### Bezpieczeństwo

- Repozytorium nie przechowuje faktycznych credentials. Użytkownik musi dostarczyć je przez środowisko, zaufany secret manager wywołany przez `exec` albo lokalny plik poza repo.
- Environment nie jest sejfem: wartości dziedziczą procesy potomne i mogą być widoczne narzędziom systemowym. FileSource zapisuje zwykły JSON bez szyfrowania.
- Backend przechowuje rozwinięty URL w obiekcie connection. Publiczne `get_current_connection()` i `source_get_connections()` mogą zwrócić URL z hasłem; nie drukuj ich do `:messages`, logów ani nagrania ekranu.
- Profile, notatniki, query, błędy, eksporty i pełne wyniki mogą zawierać dane poufne. Fork utwardza FileSource oraz backend call state, ale nie szyfruje żadnej zawartości i nie zmienia praw dowolnego istniejącego custom directory notatek, logów ani eksportów.
- Na POSIX backend tworzy własne katalogi z `0700`, pliki z `0600`, zapisuje pliki przez atomową podmianę i publikuje archiwum dopiero po ukończeniu. Odrzuca symlink FileSource, względne `DBEE_STATE_DIR` oraz archive ID z traversalem.
- Fork nie usuwa automatycznie starych `/tmp/dbee-calllog.json` i `/tmp/dbee-history`. Po zatrzymaniu wszystkich starych procesów sprawdź własność i ręcznie usuń należące do siebie legacy state.
- Atomic rename nie synchronizuje katalogu nadrzędnego na dysk, a równoległe instancje Neovim nadal używają last-writer-wins dla wspólnego call logu i FileSource. To ogranicza odporność na utratę zasilania i konkurencyjne zapisy, choć usuwa ekspozycję współdzielonego `/tmp`.
- `:Dbee store ... file ...` obcina wskazany plik bez promptu. `buffer` zastępuje cały bufor, a mapowania yank nadpisują rejestr.
- `BB`, `Enter` i helpery wykonują tekst bez sandboxa, trybu read-only ani potwierdzenia DDL/DML. MySQL ma dodatkowo wymuszone multiple statements.
- Ustawiaj TLS w DSN zgodnie z polityką serwera. `sslmode=disable`, `encrypt=false`, `TrustServerCertificate=true`, `tls=skip-verify` i podobne opcje z przykładów testowych nie są bezpiecznymi defaultami produkcyjnymi.
- Źródłowy i binarny `govulncheck` forka zbudowanego Go 1.26.6 zwracają kod zero i nie znajdują osiągalnych podatności. Źródłowy skan nadal raportuje nieosiągalne advisory `GO-2026-5932` dla wymaganego `golang.org/x/crypto/openpgp`; pakiet jest deprecated i nie ma znanej naprawionej wersji. Nie jest to równoznaczne z „zero podatności”.
- CI używa Go 1.26.6 i `govulncheck@v1.7.0`; lokalny hook używa executable `govulncheck` znalezionego na `PATH`. Hook sprawdza dokładne `go1.26.6`, HEAD checkoutu oraz bez uruchamiania kandydata `vcs.revision` i `vcs.modified=false`. Dopiero po czystym skanie wywołuje `-version`, porównuje hash i atomowo zastępuje używane binarium. Błąd usuwa kandydat i zachowuje poprzedni przeskanowany plik.
- Oddzielne ID i użytkownik bazy z minimalnymi uprawnieniami są pewniejszą granicą niż UI DBee.

### Konfiguracja opcjonalna upstream

Lokalnie aktywne są defaulty. Poniższy fragment pokazuje dostępne kierunki zmian, ale nie opisuje bieżącego stanu repo:

```lua
require("dbee").setup {
  default_connection = "stable-connection-id",
  result = {
    page_size = 200,
    focus_result = false,
    progress = {
      text_prefix = "Query...",
    },
  },
  editor = {
    directory = vim.fn.stdpath("state") .. "/dbee/custom-notes",
  },
  float_options = {
    border = "rounded",
  },
  window_layout = require("dbee.layouts").Default:new {
    on_switch = "close",
    drawer_width = 34,
    result_height = 16,
    call_log_height = 12,
  },
}
```

Pełne grupy knobów:

- **Top-level:** `default_connection`, `sources`, `extra_helpers`, `float_options`, `drawer`, `editor`, `result`, `call_log`, `window_layout`.
- **Drawer:** `window_options`, `buffer_options`, `disable_help`, `mappings`, `disable_candies`, `candies` dla typów node i chevronów.
- **Editor:** `window_options`, `buffer_options`, `directory`, `mappings`.
- **Result:** `window_options`, `buffer_options`, `page_size`, `focus_result`, `progress.spinner`, `progress.text_prefix`, `mappings`.
- **Call log:** `window_options`, `buffer_options`, `mappings`, `disable_candies`, `candies` dla wszystkich stanów calla.
- **Mapowanie:** `{ key, mode, action, opts? }`; `action` może być nazwą wbudowanej akcji albo funkcją Lua.

Konfiguracja jest łączona przez `vim.tbl_deep_extend("force")`. Niepusta własna lista `sources` jest specjalnie podstawiana w całości; pusta lista nie usuwa defaultowych sources. `window_layout` także jest podstawiany jako obiekt. Listy mappings są natomiast deep-merged po indeksach, dlatego najbezpieczniej podawać kompletną zamierzoną listę zamiast zakładać zwykłe zastąpienie.

`window_options` i `buffer_options` są stosowane bezpośrednio. Upstream ostrzega, że zmiana wymaganych opcji bufora, takich jak `buftype`, `modifiable`, `filetype` lub `bufhidden`, może złamać funkcjonalność.

### Własny layout

Obiekt `Layout` musi implementować `is_open()`, `open()`, `reset()` i `close()`. W `open()` tworzy własne, dedykowane okna i przekazuje ich ID do:

```lua
local ui = require("dbee").api.ui
ui.drawer_show(drawer_win)
ui.editor_show(editor_win)
ui.result_show(result_win)
ui.call_log_show(call_log_win)
```

Okna nie powinny być współdzielone z innym UI, a `close()` nie powinno pozostawiać okien DBee do ponownego użycia. Publiczne `*_show(winid)` konfiguruje zawartość, lecz zarządzanie splitami i odtworzeniem poprzedniego układu należy do custom layoutu.

### Zdarzenia

**Core API:** `require("dbee").api.core.register_event_listener(name, callback)`.

- **`call_state_changed`**: `{ call = CallDetails }`.
- **`current_connection_changed`**: `{ conn_id = string }`.
- **`database_selected`**: `{ conn_id = string, database_name = string }`.

**Editor API:** `require("dbee").api.ui.editor_register_event_listener(name, callback)`.

- **`note_created`**: `{ note = note_details }`.
- **`note_removed`**: `{ note_id = string }`.
- **`note_state_changed`**: `{ note = note_details }`, obecnie emitowane przy rename.
- **`current_note_changed`**: `{ note_id = string }`.

Nie ma publicznego unregister. Listenery pozostają w pamięci do końca życia załadowanej wtyczki.

### Publiczne API top-level

- **`setup(cfg?)`**: Połącz konfigurację z defaultem i zainicjalizuj stan; dokładnie raz.
- **`open()` / `close()` / `toggle()` / `is_open()`**: Sterowanie obiektem layoutu.
- **`execute(query)`**: Wykonaj na aktywnym połączeniu, ustaw call w Result UI i otwórz albo zresetuj layout.
- **`store(format, output, opts)`**: Eksportuj aktualnie wyświetlany call.
- **`install(command?)`**: Opcjonalny instalator upstream działający także przed `setup()`; może użyć `wget`, `curl`, `bitsadmin`, `go` albo `cgo`, ale nie uczestniczy w aktywnym lokalnym hooku build.
- **`api.core` / `api.ui`**: Moduły niższego poziomu opisane poniżej.

### Kompletne publiczne Core API

**Stan i eventy:**

- `core.is_loaded()` zwraca stan bez inicjalizacji core i jest bezpieczne przed `setup()`.
- `core.register_event_listener(event, listener)`.

**Sources:**

- `core.add_source(source)`.
- `core.get_sources()`.
- `core.source_reload(source_id)`.
- `core.source_add_connection(source_id, details)` zwraca connection ID.
- `core.source_remove_connection(source_id, connection_id)`.
- `core.source_update_connection(source_id, connection_id, details)`.
- `core.source_get_connections(source_id)`.

**Helpery i połączenia:**

- `core.add_helpers(helpers_by_type)`.
- `core.connection_get_helpers(connection_id, { table, schema, materialization })`.
- `core.get_current_connection()`.
- `core.set_current_connection(connection_id)`.
- `core.connection_execute(connection_id, query)` zwraca `CallDetails`, ale sam nie ustawia Result UI.
- `core.connection_get_structure(connection_id)`.
- `core.connection_get_columns(connection_id, { table, schema, materialization })`.
- `core.connection_get_params(connection_id)` zwraca oryginalne, nierozwinięte parametry source.
- `core.connection_list_databases(connection_id)` zwraca bieżącą nazwę i listę dostępnych.
- `core.connection_select_database(connection_id, database)`.
- `core.connection_get_calls(connection_id)`.

**Calle i wyniki:**

- `core.call_cancel(call_id)`.
- `core.call_display_result(call_id, bufnr, from, to)` formatuje tabelę do bufora i zwraca liczbę wierszy.
- `core.call_store_result(call_id, format, output, opts)` eksportuje dowolny call, nie tylko aktualny w UI.

`ConnectionParams` ma `id`, `name`, `type`, `url`. `CallDetails` ma `id`, `query`, `state`, `time_taken_us`, `timestamp_us` i opcjonalny `error`.

### Kompletne publiczne UI API

**Stan:**

- `ui.is_loaded()` zwraca stan bez inicjalizacji UI i jest bezpieczne przed `setup()`.

**Editor:**

- `ui.editor_register_event_listener(event, listener)`.
- `ui.editor_search_note(note_id)`.
- `ui.editor_search_note_with_buf(bufnr)`.
- `ui.editor_search_note_with_file(file)`.
- `ui.editor_namespace_create_note(namespace_id, name)`.
- `ui.editor_namespace_get_notes(namespace_id)`.
- `ui.editor_namespace_remove_note(namespace_id, note_id)`.
- `ui.editor_note_rename(note_id, name)`.
- `ui.editor_get_current_note()`.
- `ui.editor_set_current_note(note_id)`.
- `ui.editor_show(winid)`.
- `ui.editor_do_action(action)`, gdzie wbudowane akcje to `run_file`, `run_selection`, `run_under_cursor`.

**Call log:**

- `ui.call_log_refresh()`.
- `ui.call_log_show(winid)`.
- `ui.call_log_do_action(action)`, gdzie akcje to `show_result`, `cancel_call`.

**Drawer:**

- `ui.drawer_refresh()`.
- `ui.drawer_show(winid)`.
- `ui.drawer_do_action(action)`, gdzie akcje to `refresh`, `action_1`, `action_2`, `action_3`, `collapse`, `expand`, `toggle`.

**Result:**

- `ui.result_set_call(call_details)`.
- `ui.result_get_call()`.
- `ui.result_page_current()`.
- `ui.result_page_next()`.
- `ui.result_page_prev()`.
- `ui.result_page_last()`.
- `ui.result_page_first()`.
- `ui.result_show(winid)`.
- `ui.result_do_action(action)`, gdzie akcje to `page_next`, `page_prev`, `page_last`, `page_first`, `yank_current_json`, `yank_selection_json`, `yank_all_json`, `yank_current_csv`, `yank_selection_csv`, `yank_all_csv`, `cancel_call`.

Wywołanie niższego poziomu `core.connection_execute()` wymaga ręcznego `ui.result_set_call(call)`, jeśli wynik ma śledzić panel. Po setup pierwsza operacyjna funkcja UI tworzy leniwie wszystkie cztery komponenty, nawet gdy wywołujesz tylko jeden z nich; samo `ui.is_loaded()` tego nie robi.

### Aktywny lokalny build backendu

Lokalna specyfikacja nie wywołuje `require("dbee").install()`. Podczas instalacji, aktualizacji albo jawnego rebuildu Lazy tworzy katalog docelowy i synchronicznie czeka na odpowiednik:

```sh
test "$(GOTOOLCHAIN=local go env GOVERSION)" = "go1.26.6"
GOTOOLCHAIN=local CGO_ENABLED=1 go build -C "<plugin>/dbee" -o "<cel>.tmp-<pid>"
govulncheck -mode=binary "<cel>.tmp-<pid>"
# Dopiero po obu sukcesach atomowy rename kandydata na <stdpath(data)>/dbee/bin/dbee.
```

`<plugin>` jest checkoutem przypiętym przez `lazy-lock.json`, obecnie `6f2948a5bc958c0cb85c520c29953148663cd362`. Wszystkie wywołania kończą się przez `vim.system(...):wait()`, więc Lazy nie uznaje hooka za zakończony przed kodem wyjścia skanera. Niezgodny checkout, zmodyfikowane źródła, błędny build, skan albo rename usuwa kandydat i przerywa hook bez zastępowania poprzedniego binarium. Nie jest pobierany prebuild upstream.

Build wymaga lokalnego Go 1.26.6 zgodnego z `go.mod` i `toolchain go1.26.6` oraz kompilatora C dla `CGO_ENABLED=1`. `GOTOOLCHAIN=local` celowo nie pobiera innego wydania. Na lokalnym Darwin build obejmuje wszystkie 12 adapterów, w tym wymagający cgo DuckDB. Fork usunął z macierzy cele, których Go 1.26 nie obsługuje: `freebsd/riscv64` oraz `windows/arm`.

Aktywna ścieżka to `vim.fn.stdpath("data") .. "/dbee/bin/dbee"`. Bezpośrednia weryfikacja lokalnej instalacji:

```sh
"$HOME/.local/share/nvim/dbee/bin/dbee" -version
```

Oczekiwany wynik to `6f2948a5bc958c0cb85c520c29953148663cd362`, identyczny z checkoutem. Po zmianie locka wykonaj `:Lazy build nvim-dbee`; do sprawdzenia toolchainów użyj `go version`, `cc --version`, `govulncheck -version` i osobnego skanu binarium.

### Opcjonalny instalator upstream i manifest

`require("dbee").install(command?)` jest publicznym, asynchronicznym helperem odziedziczonym z upstream i może działać przed `setup()`, ale nie jest częścią lokalnej integracji. Bez argumentu wybiera kolejno `wget`, `curl`, `bitsadmin` albo `go`; jawnie można wybrać także `cgo`. Metody `go` i `cgo` budują bieżący checkout, przy czym tylko druga wymusza `CGO_ENABLED=1`. Ten helper nie uruchamia lokalnej polityki `govulncheck`.

Metody `wget` i `curl` pobierają archiwum wskazane przez manifest, rozpakowują je bezpośrednio do katalogu binarium i wykonują `chmod +x`. Instalator nie weryfikuje checksumy archiwum ani podpisu; sam transport HTTPS i późniejsze odczytanie wersji nie są kryptograficzną weryfikacją pobranego artefaktu. Implementacja `bitsadmin` tej rewizji nadal przekazuje wyłącznie argument `TODO`.

Odziedziczony manifest nadal wskazuje release `v0.1.9` i oczekiwany osadzony hash `af5075f31ede9e7d76c87babdee0f70340061660`. To identyfikator starego prebuilda upstream, nie hash aktywnego lokalnego binarium ani mechanizm weryfikacji integralności archiwum. `install()` przez `wget` lub `curl` może zastąpić utwardzony backend tym starszym artefaktem; nie uruchamiaj go.

### Health i diagnostyka instalacji

`:checkhealth dbee` wykonuje trzy kontrole: wymaga executable pod `stdpath("data") .. "/dbee/bin/dbee"`, sprawdza dostępność Git i, gdy Git jest obecny, porównuje wynik `dbee -version` najpierw z HEAD checkoutu, a potem z identyfikatorem manifestu. Dla aktywnej konfiguracji oczekiwany komunikat to `Binary version matches version of current HEAD.` i hash `6f2948a5bc958c0cb85c520c29953148663cd362`.

Health uzna również `af5075f31ede9e7d76c87babdee0f70340061660` za poprawny prebuild manifestu. Taki wynik przechodzi regułę upstream, ale oznacza odejście od lokalnej polityki builda z przypiętego checkoutu i powinien zakończyć się `:Lazy build nvim-dbee`. Brak Git daje wyłącznie warning i kończy porównanie. Health nie weryfikuje checksumy ani podpisu artefaktu, nie sprawdza Go lub kompilatora C i nie testuje `nui.nvim`, parsera SQL, JSON źródeł, adapterów, DSN, TLS, sieci, credentials ani uprawnień bazy.

### Diagnostyka warstwowa

1. **Lazy:** `:Lazy`, `:verbose command Dbee`, `:verbose nmap <leader>Bd`. Zarówno `:Dbee`, jak i `<leader>Bd` są triggerami Lazy; po załadowaniu funkcja mapowania wykonuje bezpośrednio `require("dbee").toggle()`, a nie polecenie `:Dbee`.
2. **Backend:** `:checkhealth dbee`, `:lua =vim.fn.executable(vim.fn.stdpath("data") .. "/dbee/bin/dbee")`, `go version`, `cc --version` i `govulncheck -version`. Bezpośrednie `"$HOME/.local/share/nvim/dbee/bin/dbee" -version` ma lokalnie zwrócić `6f2948a5bc958c0cb85c520c29953148663cd362`, a skan binarny kod zero.
3. **Źródła:** `:lua =vim.env.DBEE_CONNECTIONS ~= nil`, potem bez drukowania sekretów `:lua =pcall(vim.fn.json_decode, vim.env.DBEE_CONNECTIONS or "")`.
4. **Ścieżka FileSource:** `:lua =vim.fn.stdpath("state") .. "/dbee/persistence.json"`; JSON może mieć pełne komentarze `//`, ale nie inline comments ani trailing commas.
5. **Aktywne połączenie bez ujawniania URL:** `:lua local c=require("dbee").api.core.get_current_connection(); print(c and (c.name .. " [" .. c.type .. "]") or "no active connection")`.
6. **Adapter:** obecny lokalny build powinien rejestrować wszystkie 12 adapterów. Błąd `no driver registered for provided type alias` oznacza więc najpierw literówkę, złą wielkość liter albo obce/stare binarium; build tags są dodatkową możliwością dopiero dla binarium z innej platformy lub innymi flagami.
7. **Zapytanie pod kursorem:** `:set filetype?` oraz `:lua =pcall(vim.treesitter.get_parser, 0, "sql")`. Lokalna instalacja przewiduje parser, ale uszkodzona aktualizacja Treesitter nadal może go czasowo wyłączyć.
8. **Struktura:** sprawdź osobno prosty query i prawa do katalogów systemowych. Działający `SELECT 1` nie gwarantuje dostępu do listy schematów, baz albo kolumn.
9. **Wynik:** jeśli spinner trwa przy dużej odpowiedzi, pamiętaj, że backend pobiera całość. Ujemny zakres eksportu także czeka na pełny drain, maksymalnie 5 minut.
10. **Logi:** `:messages` oraz `vim.fn.stdpath("cache") .. "/dbee/dbee.log"`. Nie publikuj logu przed sprawdzeniem błędów i danych serwera.

### Ograniczenia przypiętej rewizji

- Projekt jest alpha i nie obiecuje stabilnego API ani migracji danych.
- Paginacja nie jest server-side. Brak automatycznego `LIMIT` oznacza koszt pamięci, czasu i prywatnego state proporcjonalny do całego wyniku.
- Anulowanie nie działa po przejściu calla do `retrieving`.
- Jedno aktywne połączenie i jeden aktualnie wyświetlany call są globalne dla instancji DBee; nie ma niezależnego kontekstu per tab.
- Historia i wyniki używają wspólnego dla użytkownika `stdpath("state")/dbee/backend`. Równoległe procesy nadal mogą nadpisać call log metodą last-writer-wins, ale niekompletne archiwum nie jest publikowane jako gotowe, a błędne archive ID jest odrzucane.
- Nie ma UI transakcji, parametrów zapytań, migracji, bezpiecznego trybu read-only ani potwierdzeń dla ręcznych DDL/DML.
- Parser `Enter` usuwa wszystkie średniki z wykrytej instrukcji i jest przeznaczony dla SQL, nie dla komend MongoDB/Redis.
- SQLite i DuckDB pokazują atrapę wyboru `not supported yet`, mimo że faktyczne przełączenie nie jest zaimplementowane.
- Reset custom layoutu używa `result_height` także dla call logu.
- BigQuery może zastosować tylko pierwsze dopasowane pole `QueryConfig`; parametr `location` jest nieskuteczny, helper `List` nie kwalifikuje datasetu, a testowy `endpoint` wyłącza uwierzytelnienie i używa insecure gRPC.
- SQL Server pomija schemat w helperze `List` i generuje wadliwe podwójne apostrofy w `Describe`; helper Databricks `Columns` ma nazwę `information_schema.column`.
- MySQL automatycznie włącza multiple statements; parser Redis ma uproszczone reguły spacji, quoting i escaping.
- `setup()` nie może być ponowiony, a publiczne listenery nie mają unregister. Testowanie zmian konfiguracji wymaga nowej instancji Neovim.
- Przywrócenie poprzedniego layoutu jest best effort i dotyczy tylko bieżącej karty oraz niefloatingowych okien.

**Źródła aktywnego forka i jego bazy upstream:**

- [aktywny fork](https://github.com/ukibbb/nvim-dbee/tree/6f2948a5bc958c0cb85c520c29953148663cd362), [Go i zależności](https://github.com/ukibbb/nvim-dbee/blob/6f2948a5bc958c0cb85c520c29953148663cd362/dbee/go.mod) oraz [workflow security](https://github.com/ukibbb/nvim-dbee/blob/6f2948a5bc958c0cb85c520c29953148663cd362/.github/workflows/security.yml)
- [prywatny state](https://github.com/ukibbb/nvim-dbee/tree/6f2948a5bc958c0cb85c520c29953148663cd362/dbee/state), [archiwizacja wyników](https://github.com/ukibbb/nvim-dbee/blob/6f2948a5bc958c0cb85c520c29953148663cd362/dbee/core/call_archive.go), [call log](https://github.com/ukibbb/nvim-dbee/blob/6f2948a5bc958c0cb85c520c29953148663cd362/dbee/handler/call_log.go) i [FileSource](https://github.com/ukibbb/nvim-dbee/blob/6f2948a5bc958c0cb85c520c29953148663cd362/lua/dbee/sources.lua)

Poniższe linki wskazują niezmienioną bazę UI/API upstream `dda517...`, od której fork pochodzi:

- [README](https://github.com/kndndrj/nvim-dbee/blob/dda517694889a5d238d7aa407403984da9f80cc0/README.md)
- [pełny przewodnik `doc/dbee.txt`](https://github.com/kndndrj/nvim-dbee/blob/dda517694889a5d238d7aa407403984da9f80cc0/doc/dbee.txt)
- [referencja konfiguracji, typów, sources, layoutu i API](https://github.com/kndndrj/nvim-dbee/blob/dda517694889a5d238d7aa407403984da9f80cc0/doc/dbee-reference.txt)
- [top-level API](https://github.com/kndndrj/nvim-dbee/blob/dda517694889a5d238d7aa407403984da9f80cc0/lua/dbee.lua) i [polecenie `:Dbee`](https://github.com/kndndrj/nvim-dbee/blob/dda517694889a5d238d7aa407403984da9f80cc0/plugin/dbee.lua)
- [defaultowa konfiguracja i mapowania](https://github.com/kndndrj/nvim-dbee/blob/dda517694889a5d238d7aa407403984da9f80cc0/lua/dbee/config.lua)
- [wbudowane sources](https://github.com/kndndrj/nvim-dbee/blob/dda517694889a5d238d7aa407403984da9f80cc0/lua/dbee/sources.lua)
- [Core API](https://github.com/kndndrj/nvim-dbee/blob/dda517694889a5d238d7aa407403984da9f80cc0/lua/dbee/api/core.lua) i [UI API](https://github.com/kndndrj/nvim-dbee/blob/dda517694889a5d238d7aa407403984da9f80cc0/lua/dbee/api/ui.lua)
- [defaultowy layout](https://github.com/kndndrj/nvim-dbee/blob/dda517694889a5d238d7aa407403984da9f80cc0/lua/dbee/layouts/init.lua) i [odtwarzanie okien](https://github.com/kndndrj/nvim-dbee/blob/dda517694889a5d238d7aa407403984da9f80cc0/lua/dbee/layouts/tools.lua)
- [drawer i helpery](https://github.com/kndndrj/nvim-dbee/blob/dda517694889a5d238d7aa407403984da9f80cc0/lua/dbee/ui/drawer/convert.lua), [edytor i Treesitter](https://github.com/kndndrj/nvim-dbee/blob/dda517694889a5d238d7aa407403984da9f80cc0/lua/dbee/ui/editor/init.lua), [wynik](https://github.com/kndndrj/nvim-dbee/blob/dda517694889a5d238d7aa407403984da9f80cc0/lua/dbee/ui/result/init.lua) i [call log](https://github.com/kndndrj/nvim-dbee/blob/dda517694889a5d238d7aa407403984da9f80cc0/lua/dbee/ui/call_log.lua)
- [wyniki i zakresy](https://github.com/kndndrj/nvim-dbee/blob/dda517694889a5d238d7aa407403984da9f80cc0/dbee/core/result.go), [cykl i anulowanie calla](https://github.com/kndndrj/nvim-dbee/blob/dda517694889a5d238d7aa407403984da9f80cc0/dbee/core/call.go), [stare archiwum przed utwardzeniem](https://github.com/kndndrj/nvim-dbee/blob/dda517694889a5d238d7aa407403984da9f80cc0/dbee/core/call_archive.go) oraz [stary zapis call logu](https://github.com/kndndrj/nvim-dbee/blob/dda517694889a5d238d7aa407403984da9f80cc0/dbee/handler/call_log.go)
- [wszystkie adaptery i aliasy](https://github.com/kndndrj/nvim-dbee/tree/dda517694889a5d238d7aa407403984da9f80cc0/dbee/adapters), [BigQuery](https://github.com/kndndrj/nvim-dbee/blob/dda517694889a5d238d7aa407403984da9f80cc0/dbee/adapters/bigquery.go), [mapper `QueryConfig`](https://github.com/kndndrj/nvim-dbee/blob/dda517694889a5d238d7aa407403984da9f80cc0/dbee/adapters/bigquery_driver.go) i [SQL Server](https://github.com/kndndrj/nvim-dbee/blob/dda517694889a5d238d7aa407403984da9f80cc0/dbee/adapters/sqlserver.go)
- [opcjonalny instalator upstream](https://github.com/kndndrj/nvim-dbee/blob/dda517694889a5d238d7aa407403984da9f80cc0/lua/dbee/install/init.lua), [manifest binariów](https://github.com/kndndrj/nvim-dbee/blob/dda517694889a5d238d7aa407403984da9f80cc0/lua/dbee/install/__manifest.lua), [platformy CI](https://github.com/kndndrj/nvim-dbee/blob/dda517694889a5d238d7aa407403984da9f80cc0/ci/targets.json) i [health](https://github.com/kndndrj/nvim-dbee/blob/dda517694889a5d238d7aa407403984da9f80cc0/lua/dbee/health.lua)
