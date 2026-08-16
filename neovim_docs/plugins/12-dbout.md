# Bazy danych w Neovim przez Dbout

<a id="plugin-dbout"></a>
## `zongben/dbout.nvim`

**Przypięta rewizja:** [`411e46041adeb8661e044f8421d8db5c56a9ef5d`](https://github.com/zongben/dbout.nvim/tree/411e46041adeb8661e044f8421d8db5c56a9ef5d).

**Co robi i po co:** Dbout zapisuje lokalne profile połączeń, uruchamia sterowniki baz w procesie Node.js, pozwala wykonywać SQL albo komendy MongoDB EJSON z bufora i pokazuje metadane oraz wyniki jako JSON. Obsługiwane typy to dokładnie `sqlite3`, `postgresql`, `mysql`, `mssql` i `mongodb`.

### Stan tej konfiguracji

- **Aktywne lokalne:** Lazy ładuje wtyczkę przez polecenie `:Dbout`; instalacja lub aktualizacja wykonuje `npm ci`.
- **Aktywne lokalne:** Telescope jest zależnością, rozszerzenie `dbout` jest załadowane, a globalny launcher w Normal to **`<leader>Bo`**.
- **Aktywne lokalne, kontekstowe:** **`F6`** wykonuje zapytanie, **`F7`** formatuje, **`F8`** przełącza Inspector, **`F9`** przełącza Viewer, a **`q`** zamyka bieżący panel pomocniczy.
- **Domyślne upstream, zachowane lokalnie:** Inspector używa **`H`**, **`L`**, **`I`**, **`Backspace`**, **`R`**; Viewer używa **`}`**, **`{`**, **`Ctrl-x`**.
- **Domyślne upstream, zastąpione lokalnie:** upstream proponuje `F5` dla wykonania, `F2` dla formatowania, `F12` dla Inspectora i `F11` dla Viewera. Nie są to skróty Dbout w tej konfiguracji.
- **Aktywne lokalne:** parsery Treesitter `sql` i `json` są dostępne dla podświetlania Queryera, Inspectora i Viewera. Treesitter nie wykonuje ani nie waliduje zapytań.
- **Nieaktywne lokalnie:** integracja Snacks nie jest lokalnym launcherem. Bez globalnego `Snacks` samo `:Dbout` nie otwiera żadnego UI.
- **Opcjonalne upstream:** `on_attach` może konfigurować LSP lub własny stan bufora, ale domyślnie jest `nil`.

### Najważniejsze ostrzeżenia

> **UWAGA: PostgreSQL.** Backend tej rewizji przekazuje do `pg.Pool` domyślne `ssl = { rejectUnauthorized = false }`. Ten niezabezpieczony default obowiązuje, gdy URI nie zawiera własnej opcji SSL. Przypięty `pg-connection-string` parsuje URI później i może nadpisać pole `ssl`: zalecane `?sslmode=verify-full` włącza weryfikację certyfikatu i nazwy hosta, natomiast `?sslmode=disable` jawnie wyłącza TLS. Dbout nie udostępnia równoważnego przełącznika w `setup()`.

> **UWAGA: hasła nie są maskowane ani wyłączone z historii.** Pełny connection string jest wpisywany zwykłym `vim.fn.input()`, które dodaje odpowiedź do historii input-line. W tej konfiguracji `history=10000`, a `shada` nie zawiera `@0`; pominięte `@` używa limitu `history`, więc wpis może trafić do ShaDa i wrócić w następnej sesji. Connection string jest też zapisany jawnym tekstem i pokazany w pickerze, a `on_attach` może otrzymać osobne `password`. Nie wpisuj prawdziwych haseł, dopóki upstream nie zastąpi tego promptu co najmniej `inputsecret()`; samo `inputsecret()` nadal nie rozwiązałoby plaintext state ani ekspozycji w pickerze.

> **UWAGA: brak potwierdzeń.** Usunięcie profilu przez Telescope lub `:Dbout DeleteConnection` następuje od razu. `F6` wysyła dowolny `DROP`, `DELETE`, `TRUNCATE`, DDL lub komendę MongoDB bez analizy i bez pytania. Dbout nie dodaje trybu read-only ani automatycznej transakcji.

> **UWAGA: historia nie jest kopią bezpieczeństwa.** Historia Viewera istnieje tylko w pamięci, nie zawiera tekstu zapytania i znika po usunięciu Queryera lub restarcie Neovim. Wtyczka nie ma polecenia health ani implementacji `:checkhealth dbout`.

W repozytorium nie ma connection stringów ani sekretów Dbout. Przykłady poniżej celowo używają `REDACTED`, nazw testowych i ścieżek poza repozytorium.

### Wymagania i budowanie

- `npm` musi być dostępny dla Lazy podczas instalacji i aktualizacji, ponieważ lokalny build wykonuje `npm ci`.
- Node.js musi być dostępny jako executable `node` w runtime, gdy pierwsze polecenie Dbout albo picker uruchamia `server/main.js`.
- Dla dokładnego `package-lock.json` najbezpieczniej używać Node.js 22 lub nowszego. `mongodb` i `bson` wymagają co najmniej Node 20.19, a przypięty `tedious` używany przez MSSQL deklaruje Node 22 lub nowszy.
- `better-sqlite3` jest modułem natywnym. `npm ci` pobiera odpowiedni prebuild albo wymaga działającego toolchainu do kompilacji.
- Nie są potrzebne CLI `sqlite3`, `psql`, `mysql`, `sqlcmd` ani `mongosh`; połączenia realizują pakiety Node.
- Serwer bazy, sieć, uwierzytelnienie i uprawnienia użytkownika pozostają wymaganiami konkretnego środowiska.
- Telescope jest wymagany przez lokalny launcher. Parsers `sql` i `json` odpowiadają wyłącznie za wygląd buforów.

Lokalne `npm ci` różni się od pokazanego w README upstream `npm install`: usuwa stare `node_modules` i instaluje dokładne wersje z lockfile. Po zmianie wersji Node warto ponownie uruchomić build w Lazy, szczególnie ze względu na binarny `better-sqlite3`.

### Model architektury

1. `require("dbout").setup()` wczytuje profile z pliku stanu, instaluje mapowania buforowe i rejestruje jedno polecenie `:Dbout`.
2. Pierwsze polecenie Dbout albo otwarcie pickera Telescope uruchamia `node server/main.js` jako job Neovim. Proces dziedziczy środowisko i katalog roboczy z chwili startu.
3. Lua wysyła przez stdin po jednej linii JSON-RPC 2.0. Każde żądanie ma losowy identyfikator, a callback jest przechowywany w pamięci Lua.
4. Node czyta linie przez `readline`, waliduje podstawową kopertę JSON-RPC, przekazuje metodę przez `consumer.js` do `driver.js`, a ten wybiera sterownik bazy.
5. Sterownik zwraca obiekt JavaScript. Serwer zamienia go na wcięty JSON i odsyła przez stdout; Lua nie buduje tabeli wyników, tylko pokazuje tekst JSON w Viewerze.
6. Jeden proces Node utrzymuje mapę otwartych backendów według trwałego `connection.id`. Queryer, Inspector i Viewer są obiektami Lua związanymi z buforem.

To nie jest LSP ani zewnętrzne CLI bazy. Nie istnieje osobny daemon, socket, log protokołu, polecenie reconnect ani publiczny monitor aktywnych połączeń.

### Dokładne polecenia `:Dbout`

- **`:Dbout NewConnection`**: wybiera jeden z pięciu typów, pyta o unikalną nazwę i connection string, po czym zapisuje profil. Nie testuje połączenia.
- **`:Dbout EditConnection`**: wybiera profil i pozwala zmienić nazwę oraz connection string. Typ bazy pozostaje niezmienny.
- **`:Dbout DeleteConnection`**: wybiera profil i natychmiast usuwa go z pliku stanu. Nie pyta o potwierdzenie, nie usuwa pliku SQLite i nie zamyka backendu używanego już przez otwarty Queryer.
- **`:Dbout OpenConnection`**: wybiera profil, otwiera backend i tworzy nowy, listowany bufor o nazwie `query_<bufnr>`.
- **`:Dbout AttachConnection`**: wybiera profil i przypina go do bieżącego bufora zamiast tworzyć Queryer. Jest to właściwa droga dla istniejącego `.sql`.
- **`:Dbout`**: zawsze próbuje uruchomić proces Node, ale otwiera picker tylko wtedy, gdy istnieje globalne `Snacks`. Bez Snacks jest widocznym dla użytkownika no-opem.

Nazwy subkomend są case-sensitive i dokładnie takie jak powyżej. Polecenie przyjmuje najwyżej jeden argument. Nie ma subkomend `Health`, `Query`, `Format`, `Close`, `Reconnect` ani `History`; nieznany pojedynczy argument po uruchomieniu backendu nie robi nic i nie zgłasza własnego błędu.

Polecenia używają `vim.ui.select`. Każdy wpis jest formatowany jako `nazwa typ:pełny_connection_string`, więc także ta ścieżka pokazuje hasło bez maskowania.

### Lokalny picker Telescope

Otwórz go przez **`<leader>Bo`**, `:Telescope dbout` albo opcjonalne API `require("telescope").extensions.dbout.dbout()`.

Rozszerzenie mapuje akcje wyłącznie w trybie Normal pickera. Dodatkowo zastępuje domyślne `select_default` pustą funkcją. Po otwarciu Telescope jest zwykle w Insert, dlatego najpierw naciśnij `Esc`; `Enter` w Insert nie otworzy połączenia.

- **`Enter`**: otwórz zaznaczony profil w nowym Queryerze. **Tryb:** Normal pickera. **Stan:** **Domyślne rozszerzenia, aktywne lokalnie**.
- **`n`**: zamknij picker, utwórz profil i odśwież lub otwórz picker ponownie. **Tryb:** Normal pickera. **Stan:** **Domyślne rozszerzenia, aktywne lokalnie**.
- **`d`**: natychmiast usuń zaznaczony profil i odśwież listę. Nie ma confirm ani undo. **Tryb:** Normal pickera. **Stan:** **Domyślne rozszerzenia, aktywne lokalnie**.
- **`e`**: edytuj nazwę i connection string zaznaczonego profilu; typ pozostaje ten sam. **Tryb:** Normal pickera. **Stan:** **Domyślne rozszerzenia, aktywne lokalnie**.
- **`a`**: otwórz profil i dołącz go do bufora, który jest bieżący w chwili zakończenia asynchronicznego otwierania. **Tryb:** Normal pickera. **Stan:** **Domyślne rozszerzenia, aktywne lokalnie**.
- **`q`**: zamknij Telescope dzięki globalnej konfiguracji Telescope. **Tryb:** Normal pickera. **Stan:** **Aktywne lokalne**.
- **`Alt-j` / `Alt-k`**: następny / poprzedni wpis w Insert dzięki globalnej konfiguracji Telescope. **Stan:** **Aktywne lokalne**.

Picker wyszukuje tylko po nazwie profilu, ale wyświetla obok pełne `db_type:connstr`. Przy pustej liście `n` nadal tworzy pierwszy profil; akcje wymagające zaznaczenia nie mają osłony na brak wpisu.

### Formaty connection stringów

Wybierany `db_type` i wpisywany connection string to dwie różne rzeczy. Typ musi być jedną z nazw rozpoznawanych przez Dbout, a treść jest przekazywana bez ekspansji zmiennych środowiskowych do biblioteki Node.

- **SQLite, typ `sqlite3`:** surowa ścieżka pliku, na przykład `/tmp/dbout-tutorial.sqlite3`, albo `:memory:`. Nie używaj `sqlite:///...`. Brakujący plik zostanie utworzony przy otwarciu, ale katalog nadrzędny musi istnieć. Ścieżka względna jest liczona względem CWD odziedziczonego przez proces Node, dlatego bezpieczniejsza jest ścieżka absolutna.
- **PostgreSQL, typ `postgresql`:** `postgresql://USER:PASSWORD@HOST:5432/DATABASE?sslmode=verify-full`, na przykład `postgresql://dbout_user:REDACTED@db.example.test:5432/app?sslmode=verify-full`. Bez opcji SSL backendowy default to `ssl = { rejectUnauthorized = false }`; przypięty parser URI nadpisuje go dla `sslmode=verify-full` i wtedy weryfikuje certyfikat oraz host. `sslmode=disable` także nadpisuje default, ale wyłącza TLS całkowicie i nadaje się tylko do świadomie zaakceptowanego, izolowanego środowiska.
- **MySQL, typ `mysql`:** `mysql://USER:PASSWORD@HOST:3306/DATABASE`, przekazywane wprost do `mysql2.createPool()`.
- **MSSQL, typ `mssql`:** klasyczny string `mssql`, na przykład `Server=localhost,1433;Database=app;User Id=sa;Password=REDACTED;Encrypt=true;TrustServerCertificate=false`. Kod używa `ConnectionPool.parseConnectionString()`, a nie URI w stylu `mssql://`. `TrustServerCertificate=true` akceptuje certyfikat bez zaufanej weryfikacji i powinno być ograniczone do jednorazowego, świadomie zaakceptowanego środowiska deweloperskiego.
- **MongoDB, typ `mongodb`:** `mongodb://USER:PASSWORD@HOST:27017/DATABASE?authSource=admin` albo `mongodb+srv://USER:PASSWORD@CLUSTER/DATABASE`. Nazwa bazy jest brana dosłownie ze ścieżki URI po pierwszym `/`; nie pomijaj jej.

Znaki specjalne w użytkowniku i haśle URI muszą być percent-encoded, na przykład `@` jako `%40`. Dla MongoDB ta rewizja przekazuje jednak zakodowane `URL.pathname` bez dekodowania do `client.db()`, więc nazwa `app%20data` wskazałaby dosłownie taką nazwę; unikaj nazw baz MongoDB wymagających kodowania URI. Dbout nie rozpoznaje `${PASSWORD}`, wpisów keychain ani odwołań do pliku `.env`; taki tekst stałby się częścią connection stringa.

### Plik stanu i ekspozycja sekretów

Profile są przechowywane dokładnie pod:

```text
stdpath('state')/dbout/db_explorer.json
```

Rzeczywistą bazę ścieżki pokaże `:lua =vim.fn.stdpath('state')`. Wtyczka obsługuje też wariant, w którym `stdpath()` zwraca listę, biorąc pierwszy element.

Plik zawiera jednowierszową tablicę JSON. Każdy profil ma `id`, `name`, `db_type` i pełny `connstr`. Katalog powstaje przy pierwszym zapisie. Implementacja nie szyfruje danych, nie maskuje haseł, nie ustawia jawnie restrykcyjnego trybu pliku, nie wykonuje zapisu atomowego i nie tworzy kopii zapasowej.

Connection string jest widoczny w następujących miejscach:

- w pliku `db_explorer.json`;
- podczas zwykłego, niesekretnego promptu `vim.fn.input()`;
- w pamięci historii `input` oraz, po zapisie lub wyjściu, w pliku ShaDa;
- w pickerze Telescope;
- w listach `vim.ui.select` poleceń `:Dbout`;
- w tabeli przekazywanej do opcjonalnego `on_attach`;
- w pamięci procesu Neovim i procesu Node.

Usunięcie profilu usuwa tylko rekord z JSON. Nie czyści historii systemowych backupów, nie usuwa bazy SQLite i nie zrywa automatycznie backendu już używanego przez Queryer. Chroń katalog stanu uprawnieniami systemu i nie wklejaj jego treści do zgłoszeń diagnostycznych.

Jeżeli prawdziwy sekret został już wpisany, usuń zarówno profil, jak i jego kopię w historii:

1. Unieważnij albo obróć ujawnione hasło lub token. Czyszczenie lokalnych plików nie odbiera sekretowi ważności.
2. Usuń profil przez `:Dbout DeleteConnection`; to nie czyści historii input ani istniejących backupów pliku stanu.
3. W każdej działającej instancji Neovim, która mogła wczytać lub zapamiętać sekret, wykonaj `:call histdel('input')`. Polecenie usuwa całą historię input, nie tylko wpisy Dbout. Nie używaj `:history input` podczas udostępniania ekranu, bo wypisuje jej treść.
4. Gdy wszystkie działające instancje mają już wyczyszczoną historię, wykonaj `:wshada!` w jednej z nich. Bang jest istotny: nadpisuje cały plik ShaDa bieżącym stanem, nie tylko historię input, podczas gdy zwykłe `:wshada` scala istniejący plik i może przywrócić skasowany wpis. Wymuszone nadpisanie może odrzucić dane ShaDa obecne tylko w innej instancji.
5. Nie pozostawiaj innej, niewyczyszczonej instancji Neovim. Jej późniejsze zwykłe wyjście może ponownie scalić sekret do ShaDa. Kopie zapasowe i synchronizowane snapshoty katalogu state trzeba usunąć zgodnie z polityką danego systemu.

Pomoc Neovim dla tej ścieżki to `:help input()`, `:help inputsecret()`, `:help histdel()` i `:help shada-@`.

### Mapowania w Queryerze i panelach

- **`F6`**: wykonaj cały bufor albo wizualny zakres pełnych wierszy. **Tryb:** `n`, `i`, `v`. **Kontekst:** Queryer. **Stan:** **Aktywne lokalne**.
- **`F7`**: sformatuj cały bufor albo wizualny zakres pełnych wierszy i zastąp go wynikiem formattera. **Tryb:** `n`, `i`, `v`. **Kontekst:** Queryer. **Stan:** **Aktywne lokalne**.
- **`F8`**: zamknij lub pokaż Inspector związany z aktywnym Queryerem. **Tryb:** `n`, `i`. **Kontekst:** Queryer, Inspector albo Viewer. **Stan:** **Aktywne lokalne**.
- **`F9`**: zamknij lub pokaż Viewer związany z aktywnym Queryerem. **Tryb:** `n`, `i`. **Kontekst:** Queryer, Inspector albo Viewer. **Stan:** **Aktywne lokalne**.
- **`q`**: zamknij tylko okno bieżącego Inspectora albo Viewera. Nie odłącza bazy, nie kasuje bufora panelu i nie zamyka Queryera. **Tryb:** `n`. **Stan:** **Aktywne lokalne**.

W samym Queryerze `q` nie jest mapowaniem Dbout. Zwykłe zachowanie Normal, czyli rozpoczęcie nagrywania makra, pozostaje aktywne.

### Wykonanie całego bufora i zaznaczenia

Bez aktywnego Visual `F6` pobiera linie od początku do końca bufora. Nie wybiera zapytania pod kursorem, nie szuka średnika i nie analizuje AST. W Insert także wykonuje cały bufor.

W Visual pobierany jest zakres od wiersza wcześniejszego końca zaznaczenia do wiersza późniejszego końca, włącznie. Kolumny są ignorowane. Zaznaczenie znakowe albo blokowe nadal wysyła pełne wiersze, dlatego do precyzyjnego wykonania najlepiej umieszczać każde zapytanie w osobnym zestawie wierszy i zaznaczać cały zestaw.

Cały tekst trafia jako jedno wywołanie sterownika. Dbout nie zapewnia spójnej obsługi wielu statementów:

- SQLite używa `db.prepare()` i oczekuje jednego statementu;
- MySQL używa `pool.execute()` bez włączenia `multipleStatements`;
- PostgreSQL może zwrócić formę wyniku inną niż oczekiwany pojedynczy `rowCount` i `rows`;
- MSSQL przekazuje tekst jako batch, ale Viewer pokazuje tylko `recordset` i pierwszy element `rowsAffected`;
- MongoDB wymaga jednego kompletnego dokumentu EJSON reprezentującego komendę.

Dbout nie wiąże parametrów. Tekst jest wykonywany bezpośrednio z uprawnieniami użytkownika connection stringa. Używaj kont o minimalnych prawach, a operacje wymagające gwarantowanej transakcji wykonuj natywnym klientem bazy.

Nie rozdzielaj `BEGIN`, DML i `COMMIT` albo `ROLLBACK` między osobne naciśnięcia `F6`: sterowniki korzystające z poola nie przypinają kolejnych wywołań do tej samej fizycznej sesji. Transakcja może mieć poprawny zakres tylko wtedy, gdy cały batch mieści się w jednym wywołaniu i dany sterownik go obsługuje, ale powyższe różnice SQLite, MySQL, PostgreSQL i MSSQL sprawiają, że Dbout nie jest wiarygodnym interfejsem do takiego workflow.

### Formatter `F7`

Formatter używa tej samej reguły zakresu co `F6` i asynchronicznie zastępuje wskazane linie. Nie zapisuje pliku na dysk.

- SQLite: `sql-formatter` z dialektem `sqlite`.
- PostgreSQL: `sql-formatter` z dialektem `postgresql`.
- MySQL: `sql-formatter` z dialektem `mysql`.
- MSSQL: `sql-formatter` z dialektem `tsql`.
- MongoDB: `EJSON.parse()`, a następnie `EJSON.stringify(..., null, 2)`.

Formatter jest syntaktyczny, nie łączy się z parserem Treesitter i nie potwierdza poprawności względem konkretnego schematu. Pusty wynik formattera SQL jest szczególnym przypadkiem tej rewizji: serwer nie wysyła odpowiedzi dla wartości pustej, a callback nie ma timeoutu.

### Układ trzech kolumn

Konfiguracja pozycji używa liczb `1`, `2`, `3`, a nie szerokości:

```text
1 = lewa krawędź | 2 = pozycja względna/środek | 3 = prawa krawędź
```

Domyślnie Inspector ma `1`, Viewer ma `3`, więc Queryer pozostaje pomiędzy nimi. Oba panele są domyślnie otwierane po attach.

- Pozycja `1` tworzy split po lewej stronie.
- Pozycja `3` tworzy split po prawej stronie.
- Pozycja `2` jest liczona względem drugiego panelu. Jeżeli drugi panel jest na `1`, panel `2` trafia na jego prawą stronę; jeżeli drugi jest na `3`, trafia na jego lewą stronę.
- Gdy panel odniesienia jest zamknięty, pozycja `2` wybiera odpowiednią krawędź, na której miał powstać układ.
- Oba panele mogą mieć `1`; nowszy split pojawi się bardziej na lewo. Oba mogą mieć `3`; nowszy pojawi się bardziej na prawo.
- Oba panele nie mogą mieć jednocześnie `2`; setup kończy się błędem walidacji.

Wartości nie ustawiają stałej szerokości ani proporcji. Układ korzysta z natywnych splitów Neovim i aktualnej geometrii okien.

### Inspector

Inspector jest niemodyfikowalnym scratch bufferem z filetype `json`. Jego treść to ten sam obiekt `{ duration, total, rows }`, który zwraca zapytanie metadanych, a winbar pokazuje aktywną kartę.

- **`L` / `H`**: następna / poprzednia dostępna karta, cyklicznie. **Tryb:** Normal. **Stan:** **Domyślne upstream, zachowane lokalnie**.
- **`I`**: otwórz picker obiektu lub akcję zależną od aktywnej karty. Nie działa na wierszu pod kursorem. **Tryb:** Normal. **Stan:** **Domyślne upstream, zachowane lokalnie**.
- **`Backspace`**: wróć z warstwy tabeli lub kolekcji do kart głównych. **Tryb:** Normal. **Stan:** **Domyślne upstream, zachowane lokalnie**.
- **`R`**: usuń cache list dla tego connection ID, wróć do pierwszej karty `Tables` i pobierz ją ponownie. Nie reconnectuje bazy. **Tryb:** Normal. **Stan:** **Domyślne upstream, zachowane lokalnie**.
- **`q`**: zamknij okno Inspectora, zachowując obiekt i stan Queryera. **Tryb:** Normal. **Stan:** **Aktywne lokalne**.

Dostępne karty zależą od sterownika:

- SQLite: główne `Tables`, `Views`; po wyborze tabeli `Columns`, `Triggers`.
- PostgreSQL: główne `Tables`, `Views`, `StoreProcedures`, `Functions`; po wyborze tabeli `Columns`, `Triggers`.
- MySQL: główne `Tables`, `Views`, `StoreProcedures`, `Functions`; po wyborze tabeli `Columns`, `Triggers`.
- MSSQL: główne `Tables`, `Views`, `StoreProcedures`, `Functions`; po wyborze tabeli `Columns`, `Triggers`.
- MongoDB: główne tylko `Tables`, czyli kolekcje; po wyborze kolekcji tylko `Indexes`.

`I` na `Tables` pobiera listę przez `vim.ui.select`. Po wybraniu tabeli lub kolekcji Inspector przechodzi do drugiej warstwy. `I` na `Views`, `StoreProcedures`, `Functions` i `Triggers` wybiera obiekt, pobiera jego definicję i **zastępuje całą treść Queryera** definicją bez pytania. Przed inspekcją definicji zachowaj potrzebne, niezapisane SQL.

Na karcie `Columns`, `I` pyta o `SELECT`, `INSERT` albo `UPDATE`, generuje szablon i również zastępuje cały Queryer. Logika jest dokładnie następująca:

```sql
SELECT col1, col2 FROM table_name WHERE pk_col = @pk_col
INSERT INTO table_name(col1, col2) VALUES (@col1, @col2)
UPDATE table_name SET non_pk_col = @non_pk_col WHERE pk_col = @pk_col
```

Szablony są tylko rusztowaniem:

- identyfikatory nie są cytowane ani kwalifikowane schematem;
- placeholder `@column` jest używany dla wszystkich silników, choć nie jest uniwersalną składnią parametru;
- Dbout nie dostarcza żadnych wartości ani mechanizmu bind;
- `INSERT` obejmuje także klucze, kolumny identity i kolumny z defaultem;
- brak klucza głównego daje pustą część po `WHERE`, a klucz złożony łączy warunki przez `AND`;
- `UPDATE` nie aktualizuje kolumn klucza głównego.

Najpierw popraw wygenerowany tekst, wpisz konkretne wartości lub właściwe parametry klienta i dopiero wtedy uruchamiaj. `I` na MongoDB `Indexes` nie ma handlera i nic nie robi; sama karta już pokazuje wynik `listIndexes`.

Cache obejmuje tylko listy `Tables`, `Views`, `StoreProcedures` i `Functions`, osobno dla connection ID. Kolumny, triggery, indeksy i definicje są pobierane ponownie. `R` usuwa cały cache list dla tego ID.

### Viewer i format wyniku

Viewer jest scratch bufferem `json`. Typowy wynik SQL ma postać:

```json
{
  "duration": "3ms",
  "total": 2,
  "rows": [
    { "id": 1, "name": "Ada" },
    { "id": 2, "name": "Linus" }
  ]
}
```

`duration` mierzy tylko wywołanie sterownika. `total` oznacza liczbę zwróconych wierszy dla odczytu albo liczbę zmienionych wierszy dla wielu operacji zapisu. `rows` jest tablicą rekordów; dla DML zwykle jest pusta. MSSQL używa tylko pierwszego `rowsAffected`, a MongoDB dla komendy bez kursora może umieścić w `rows` cały obiekt odpowiedzi i ustawić `total` na `0`.

Domyślna historia jest włączona i ma limit 10 wyników na Queryer. Najnowszy wynik trafia pod indeks `1`; winbar pokazuje `[Query Result(i/n)]`.

- **`}`**: przejdź do starszego wyniku, czyli zwiększ indeks. **Tryb:** Normal. **Stan:** **Domyślne upstream, zachowane lokalnie**.
- **`{`**: przejdź do nowszego wyniku, czyli zmniejsz indeks. **Tryb:** Normal. **Stan:** **Domyślne upstream, zachowane lokalnie**.
- **`Ctrl-x`**: natychmiast usuń aktualny wpis historii, bez potwierdzenia. **Tryb:** Normal. **Stan:** **Domyślne upstream, zachowane lokalnie**.
- **`q`**: zamknij okno Viewera, ale zachowaj historię tak długo, jak żyje Queryer. **Tryb:** Normal. **Stan:** **Aktywne lokalne**.

Wpis przechowuje wyłącznie linie JSON wyniku, w tym pole `duration`. Nie ma tekstu zapytania, absolutnego timestampu, connection stringa ani błędu. Nieudane zapytanie nie tworzy wpisu. Historia nie jest zapisywana do `db_explorer.json` ani żadnego innego pliku; znika przy `BufDelete` Queryera lub restarcie Neovim.

### Konteksty buforów i rzeczywisty cykl życia

Każdy Queryer ma własny kontekst Lua z profilem, buforem Inspectora, buforem Viewera, historią wyników, kartą Inspectora oraz flagami otwarcia paneli. `BufWinEnter` przełącza bieżący kontekst, a gdy w aktualnej karcie nie ma widocznego Queryera, wspólne okna paneli są chowane.

Izolacja nie jest jednak pełna:

- Proces Node jest jeden na instancję Neovim.
- Backendowa mapa jest indeksowana przez trwałe `connection.id`. Dwa Queryery otwarte z tego samego profilu współdzielą ten sam pool lub klient, mimo osobnych Viewerów i Inspectorów.
- `create_connection` dla już obecnego ID zwraca tylko `"connected"`; edycja connection stringa nie przełącza istniejącego backendu. Nowa wartość zacznie działać dopiero po rzeczywistym zamknięciu starego ID i ponownym otwarciu.
- `BufDelete` Queryera wysyła asynchroniczne `close_connection`. Zamknięcie jednego z dwóch Queryerów tego samego profilu może więc zerwać backend drugiego.
- Callback `BufDelete` używa globalnie bieżącego kontekstu, a nie bezpośrednio kontekstu `args.buf`. `:bdelete` wykonane dla nieaktywnego Queryera może wyczyścić cache i zamknąć połączenie innego, aktywnego Queryera.
- Okna Inspectora i Viewera są globalnymi polami compositora, nie obiektami per tabpage. Równoczesne Queryery w wielu kartach mogą podmieniać bufory paneli w oknach należących do innej karty.
- Odpowiedź `F6` jest pokazana tylko wtedy, gdy globalny kontekst nadal wskazuje ten sam Queryer. Przejście do innego Queryera przed odpowiedzią odrzuca wynik, ale operacja w bazie już się wykonała, także jeśli była destrukcyjna.
- Przejście do zwykłego bufora nie zawsze zeruje globalny kontekst. Spóźniona odpowiedź może ponownie otworzyć Viewer w nieoczekiwanym układzie lub karcie.
- `F7` zapamiętuje numer bufora i po odpowiedzi próbuje go zmodyfikować bez analogicznej kontroli aktywnego kontekstu. Usunięcie bufora w trakcie formatowania może skończyć się błędem callbacka.

Po uruchomieniu job pozostaje aktywny do końca sesji lub awarii procesu. Wtyczka nie ma `on_exit`, automatycznego restartu Queryerów ani jawnego zamknięcia wszystkich pooli przy `VimLeave`. Polecenie lub Telescope potrafi uruchomić nowy proces po wykryciu martwego joba, ale istniejące Queryery nie odtwarzają w nim swoich connection ID i wymagają ponownego open/attach.

Transport także ma ograniczenia tej rewizji. Lua skleja wszystkie fragmenty stdout i próbuje zdekodować je jako jeden dokument JSON. Dwie odpowiedzi dostarczone w jednym callbacku mogą utworzyć niepoprawne `}{` i pozostawić callbacki bez zakończenia. Nie ma timeoutu, anulowania ani kolejki serializującej równoległe zapytania.

### Dołączenie istniejącego `.sql`

1. Otwórz i zapisz właściwy plik `.sql`.
2. Uruchom `:Dbout AttachConnection` albo `<leader>Bo`, przejdź `Esc` do Normal, wybierz profil i naciśnij `a`.
3. Dbout zachowa nazwę i zwykły charakter bufora, ustawi filetype `sql` dla baz relacyjnych albo `json` dla MongoDB, doda mapowania i winbar `Database:[nazwa]`.
4. Domyślnie otworzą się Inspector po lewej i pusty Viewer po prawej. Pierwsze `F8` z Queryera zamyka już otwarty Inspector; przejdź do niego nawigacją okien albo zamknij i ponownie otwórz `F8`, aby drugie naciśnięcie ustawiło w nim fokus. `F9` analogicznie przełącza Viewer.
5. Zaznacz pełne wiersze jednego zapytania i użyj `F6`; bez zaznaczenia zostanie wysłany cały plik.
6. `q` w panelu tylko zamyka panel. Połączenie pozostaje do `BufDelete` bufora, nie tylko do zamknięcia jego okna.

Nie istnieje akcja detach. Ponowne Attach na tym samym buforze nadpisuje kontekst Lua bez jawnego zamknięcia starego backendu. Dodatkowo zarówno polecenie, jak i Telescope pobierają `nvim_get_current_buf()` dopiero w callbacku po otwarciu połączenia. Jeżeli w trakcie łączenia przełączysz bufor, attach może trafić do nowego bieżącego bufora zamiast pierwotnego `.sql`.

Inspekcja definicji albo wygenerowanie SQL przez `I` zastępuje cały dołączony plik w pamięci. Dbout nie zapisuje go automatycznie, ale niezapisana treść zostaje nadpisana w buforze i wymaga zwykłego undo lub odczytania pliku ponownie.

### API `on_attach`

**Stan:** **Opcjonalne upstream, domyślnie nieaktywne**.

Callback jest wywoływany po przypięciu mapowań i po asynchronicznym `get_connection_info`:

```lua
on_attach = function(connection, bufnr)
  -- connection.name
  -- connection.db_type
  -- connection.host
  -- connection.port
  -- connection.user
  -- connection.password
  -- connection.database
  -- connection.connstr
end
```

SQLite dostarcza tylko `database`, a MSSQL i MongoDB rozłożone dane połączenia, w tym hasło, jeśli było obecne. W tej rewizji PostgreSQL odczytuje pola z `pool.options`, gdzie URI nie zostaje rozłożone na oczekiwane klucze, więc callback dostaje dla nich `nil`. MySQL próbuje użyć nieistniejącego `pool.config`; RPC kończy się błędem i `on_attach` nie zostaje wywołany. Nie zakładaj przenośności tych metadanych między backendami, nie loguj całej tabeli i nie przekazuj jej bez potrzeby do LSP.

API nadaje się do ustawienia zmiennych buforowych lub uruchomienia klienta SQL LSP. Nie jest kontrolą dostępu, hookiem przed zapytaniem ani mechanizmem maskowania. Nie ma odpowiadającego `on_detach`, a błąd callbacka nie jest izolowany przez `pcall`.

### MongoDB i Extended JSON

Mongo Queryer ma filetype `json`, ale nie przyjmuje składni `mongosh`. Treść musi być jednym dokumentem Extended JSON opisującym komendę przekazywaną do `db.command()`.

Dozwolony styl:

```json
{
  "find": "users",
  "filter": {
    "status": "active",
    "createdAt": {
      "$gte": {
        "$date": "2026-01-01T00:00:00Z"
      }
    }
  },
  "projection": {
    "name": 1,
    "email": 1
  },
  "sort": {
    "createdAt": -1
  },
  "limit": 10
}
```

Niedozwolony styl to na przykład `db.users.find({...})`, niecytowane klucze, funkcje JavaScript, komentarze lub kilka dokumentów obok siebie. Rozszerzone typy takie jak `$date`, `$oid`, `$numberLong` i `$binary` są dekodowane przez `bson.EJSON.parse()`.

`F7` parsuje i ponownie serializuje EJSON, więc niepoprawny dokument zgłasza błąd zamiast częściowego formatowania. `F6` wykonuje komendę. Jeżeli odpowiedź zawiera `cursor.firstBatch`, Viewer pokazuje tylko ten pierwszy batch i nie wysyła automatycznego `getMore`. Dla odpowiedzi bez kursora `rows` może być obiektem, a `total` pozostaje `0`.

Wynik jest na końcu serializowany zwykłym `JSON.stringify`, a nie `EJSON.stringify`. Reprezentacja typów BSON w Viewerze może więc różnić się od wejściowej postaci canonical EJSON.

### Tutorial: SQLite od zera

1. Otwórz `<leader>Bo`, naciśnij `Esc`, potem `n`.
2. Wybierz dokładnie `sqlite3`, wpisz nazwę `dbout-sqlite-demo` i absolutną ścieżkę `/tmp/dbout-tutorial.sqlite3`. Profil trafi do lokalnego state, nie do repozytorium.
3. W pickerze przejdź do Normal, zaznacz profil i naciśnij `Enter`. Otwarcie brakującego pliku utworzy bazę.
4. Wstaw poniższe trzy statementy w osobnych wierszach. Zaznaczaj i wykonuj `F6` po jednym wierszu, ponieważ sterownik SQLite przygotowuje pojedynczy statement.

```sql
CREATE TABLE IF NOT EXISTS notes (id INTEGER PRIMARY KEY, body TEXT NOT NULL);
INSERT INTO notes (body) VALUES ('pierwsza notatka');
SELECT id, body FROM notes ORDER BY id;
```

5. Viewer pokaże dla `INSERT` pustą tablicę `rows` i liczbę zmian w `total`, a dla `SELECT` rekordy w `rows`.
6. Inspector jest już domyślnie otwarty po lewej, więc przejdź do jego okna, na przykład przez `Ctrl-h`, ustaw kartę `Tables`, naciśnij `I` i wybierz `notes`. Jedno `F8` z Queryera zamknęłoby panel; jeżeli chcesz użyć skrótu do ustawienia fokusu, zamknij go `F8` i naciśnij `F8` ponownie, aby go otworzyć oraz sfokusować. `Columns` pokaże metadane; `Triggers` będzie puste, dopóki nie utworzysz triggera.
7. `I` na `Columns` i wybór `SELECT` zastąpi cały Queryer szablonem z `@id`. Zastąp placeholder konkretną wartością przed wykonaniem.
8. `q` zamyka panel. Usunięcie profilu przez `d` nie usuwa `/tmp/dbout-tutorial.sqlite3`; plik usuwa się osobno, świadomie.

SQLite tej rewizji ma dwie usterki prezentacji metadanych: `PRAGMA notnull = 1` jest mapowane na `is_nullable = true`, czyli odwrotnie do znaczenia, a detekcja unikalnego indeksu odwołuje się do niewłaściwego klucza i może raportować `is_unique = false`. Nie traktuj tych dwóch pól Inspectora jako autorytatywnych.

### Tutorial: PostgreSQL bez zapisywania sekretu w repo

1. Przygotuj osobnego użytkownika bazy o minimalnych uprawnieniach, najlepiej tylko do odczytu na czas poznawania wtyczki.
2. Otwórz `<leader>Bo`, przejdź do Normal, naciśnij `n`, wybierz `postgresql` i wpisz URI w rodzaju `postgresql://dbout_reader:REDACTED@db.example.test:5432/app?sslmode=verify-full`. Nie wpisuj prawdziwego, stałego hasła do obecnego promptu `input()`; do świadomego testu użyj co najwyżej tymczasowego poświadczenia o ograniczonych prawach, ponieważ odpowiedź trafia do historii input, ShaDa i jawnego pliku state.
3. Bez opcji SSL kod pozostawia `ssl = { rejectUnauthorized = false }`. `?sslmode=verify-full` jest zalecanym override z weryfikacją certyfikatu i hosta. Dla serwera celowo pozbawionego TLS `?sslmode=disable` jawnie wyłączy szyfrowanie; używaj go tylko w zaakceptowanym, izolowanym środowisku. Ta rewizja nie udostępnia tych ustawień przez `setup()`.
4. Otwórz profil i wykonaj najpierw nieszkodliwe zapytanie:

```sql
SELECT current_database() AS database_name,
       current_user AS user_name,
       now() AS server_time;
```

5. Ograniczaj wyniki przez `LIMIT`; Viewer wczytuje wszystkie zwrócone rekordy do pamięci Node, transportu JSON i jednego bufora Neovim.
6. Inspector pokazuje tabele, widoki i triggery tylko ze schematu `public`. Lista funkcji i procedur obejmuje schematy niesystemowe, ale wybór oraz pobranie definicji opierają się tylko na nazwie, więc przeciążenia i takie same nazwy w wielu schematach są niejednoznaczne.
7. Inspekcja widoku może w tym commicie zakończyć się błędem składni, ponieważ zapytanie sterownika PostgreSQL używa `definition as 'definition'` z apostrofami. Pozostałe błędy Inspectora sprawdzaj osobnym zapytaniem do katalogów PostgreSQL.
8. Przed `UPDATE` lub `DELETE` sprawdź zakres odpowiadającym mu zapytaniem `SELECT`, ale właściwy zapis wykonaj kontem o minimalnych prawach i w natywnym kliencie utrzymującym jedną sesję transakcji. Osobne `F6` nie są wspólną transakcją, a Dbout nie pokaże confirm nawet dla zapytania bez `WHERE`.

Pool PostgreSQL i MySQL powstaje leniwie. Sam callback `create_connection` może zwrócić sukces przed handshake; domyślnie otwierany Inspector szybko wysyła zapytanie metadanych i zwykle ujawnia problem połączenia jako pierwszy.

### Tutorial: MongoDB przez EJSON

1. Utwórz profil `mongodb` z URI zawierającym bazę, na przykład `mongodb://dbout_reader:REDACTED@localhost:27017/app?authSource=admin`. Dla Atlas może to być `mongodb+srv://.../app`.
2. Otwórz profil. Queryer zmieni filetype na `json`, a Inspector pokaże kolekcje na karcie `Tables`.
3. Aby sprawdzić połączenie bez helperów `mongosh`, wykonaj cały dokument:

```json
{
  "listCollections": 1,
  "filter": {
    "type": "collection"
  }
}
```

4. Dla kolekcji `users` użyj kompletnej komendy `find`, takiej jak przykład EJSON powyżej. `F7` ją sformatuje, a `F6` wyśle do `db.command()`.
5. W Inspectorze naciśnij `I` na `Tables`, wybierz kolekcję i przejdź do `Indexes`. Treść pochodzi z komendy `listIndexes`; `I` na tej karcie nie ma dalszej akcji.
6. Operacje `insert`, `update`, `delete` i `drop` są równie bezpośrednie jak `find` i nie mają potwierdzenia. Najpierw użyj użytkownika read-only albo wykonuj je wyłącznie na bazie testowej.

MongoClient łączy się od razu podczas `OpenConnection`, podobnie jak MSSQL. SQLite otwiera plik od razu; PostgreSQL i MySQL tworzą pool, który może zestawić fizyczne połączenie dopiero przy pierwszym zapytaniu.

### Diagnostyka

Dbout nie ma własnego health checka. `:checkhealth dbout` ani `:Dbout Health` nie są zaimplementowane; diagnozuj warstwy ręcznie.

1. Sprawdź Lazy i build: wtyczka powinna być przypięta do właściwego commita, `npm --version` musi działać w środowisku Lazy, a `npm ci` powinno zakończyć się bez błędu modułu natywnego.
2. Sprawdź runtime: `:echo executable('node')` powinno zwrócić `1`, a `node --version` w tej samej powłoce powinno spełniać wymagania lockfile. `npm` nie jest wywoływany przy każdym zapytaniu, ale `node` jest potrzebny procesowi serwera.
3. Sprawdź backend znaleziony przez runtimepath: `:lua =vim.api.nvim_get_runtime_file('server/main.js', false)`. Pierwsza ścieżka jest uruchamiana przez Dbout.
4. Po `:Dbout NewConnection` sprawdź wewnętrzne API `:lua =require('dbout.rpc').is_alive()`. To diagnostyka implementacji, nie stabilne publiczne API.
5. Sprawdź Telescope przez `:Telescope dbout`. Gdy picker się otwiera, ale `Enter` nie działa, naciśnij `Esc`; akcje rozszerzenia istnieją tylko w Normal.
6. Sprawdź mapowania we właściwym Queryerze: `:verbose nmap <F6>`, `:verbose imap <F6>`, `:verbose nmap <F8>` i `:setlocal filetype?`.
7. Sprawdź bazę state przez `:lua =vim.fn.stdpath('state')`, ale nie wypisuj publicznie `db_explorer.json`. Niepoprawny JSON może przerwać setup, bo loader nie ma obsługi błędu dekodowania.
8. Otwórz `:messages`. Standardowe błędy JSON-RPC zawierają komunikat i stack Node, lecz wtyczka nie zapisuje osobnego trwałego logu.
9. Zweryfikuj host, port, DNS, firewall, certyfikat, użytkownika i bazę natywnym klientem poza Neovim. To rozdziela problem sterownika Dbout od problemu serwera.
10. Dla PostgreSQL sprawdź efektywny wariant URI: brak override oznacza źródłowe `rejectUnauthorized=false`, `sslmode=verify-full` weryfikuje certyfikat i host, a `sslmode=disable` wyłącza TLS. Dla SQLite sprawdź absolutną ścieżkę i prawa katalogu. Dla MongoDB upewnij się, że URI ma nazwę bazy i `authSource`, jeżeli użytkownik należy do innej bazy.
11. Gdy podświetlanie nie działa, sprawdź `:setlocal filetype?` oraz parser `sql` lub `json`. Brak parsera nie tłumaczy błędu sieci ani wykonania zapytania.
12. Jeżeli proces Node umarł, ponowne otwarcie `:Dbout ...` albo pickera uruchomi job, ale stary Queryer nadal nie ma odtworzonego backendu. Otwórz profil w nowym Queryerze lub świadomie dołącz go ponownie.

### Ograniczenia przypiętej rewizji

- Brak potwierdzenia dla destrukcyjnego SQL, komend MongoDB, usunięcia profilu i usunięcia wpisu historii.
- Brak maskowania hasła, `inputsecret()`, secret store, zmiennych środowiskowych, szyfrowania state i redakcji pickera. Connection string trafia również do historii input i, przy aktywnym ShaDa, na dysk.
- Brak health command, reconnect, statusu połączeń, timeoutu RPC, anulowania zapytania i trwałego logu.
- Brak trwałej historii zapytań i wyników. Historia Viewera przechowuje tylko maksymalnie 10 wyników na Queryer w pamięci.
- Brak CSV, tabelarycznego gridu, paginacji, streamingu i automatycznego `LIMIT`. Duży wynik jest materializowany w sterowniku, serializowany do JSON i kopiowany do bufora.
- Brak wykonania statementu pod kursorem i spójnej obsługi wielu statementów. Visual oznacza pełne wiersze, nie dokładne kolumny.
- Dla poolowanych PostgreSQL, MySQL i MSSQL osobne wywołania `F6` nie są przypięte do jednej sesji. `BEGIN` i późniejsze DML uruchamiane osobno nie tworzą wiarygodnej wspólnej transakcji; SQLite używa jednego obiektu, ale przyjmuje tylko pojedynczy statement i nadal nie ma UI transakcji.
- Brak bind parametrów. Wygenerowane `@column` są tekstem i często nie są wykonywalne bez ręcznej zmiany.
- Metadane są ograniczone i oparte na niekwalifikowanych nazwach. PostgreSQL skupia tabele, widoki i triggery na `public`; MSSQL i część pozostałych zapytań może mieszać identyczne nazwy z wielu schematów.
- Nazwy obiektów są interpolowane do SQL Inspectora bez parametrów i bez bezpiecznego cytowania. Apostrof lub nietypowy identyfikator może zepsuć zapytanie; złośliwa nazwa obiektu w niezaufanej bazie zwiększa ryzyko.
- SQLite błędnie prezentuje część flag nullable/unique, a PostgreSQL ma wadliwe zapytanie definicji widoku w tym commicie.
- MongoDB pokazuje tylko `cursor.firstBatch`, nie wykonuje `getMore`, a odpowiedź końcowa nie zachowuje gwarantowanej postaci EJSON.
- Serializacja zwykłym `JSON.stringify` może zmieniać reprezentację dat, binariów i typów liczbowych; wartość JavaScript `BigInt` może w ogóle nie dać się zserializować.
- Profile mają pseudolosowy UUID używany jako klucz, ale nie jest to token bezpieczeństwa. Ten sam ID oznacza współdzielony backend w procesie Node.
- Globalny aktywny kontekst i globalne okna paneli mają wyścigi przy wielu Queryerach, kartach, asynchronicznych odpowiedziach i `BufDelete` nieaktywnego bufora.
- Parser stdout zakłada jeden kompletny JSON naraz. Równoległe odpowiedzi mogą się skleić, a brak timeoutu pozostawia wiszące callbacki.
- Proces Node nie ma jawnego shutdown hooka wtyczki. Zamknięcie pojedynczego Queryera wysyła notification, lecz zakończenie Neovim polega na zakończeniu procesu potomnego przez edytor/system.

### Źródła przypiętej rewizji

Wszystkie poniższe odnośniki są niemutowalne i wskazują commit `411e46041adeb8661e044f8421d8db5c56a9ef5d`.

**Dokumentacja i zależności:**

- [README](https://github.com/zongben/dbout.nvim/blob/411e46041adeb8661e044f8421d8db5c56a9ef5d/README.md)
- [`package.json`](https://github.com/zongben/dbout.nvim/blob/411e46041adeb8661e044f8421d8db5c56a9ef5d/package.json)
- [`package-lock.json`](https://github.com/zongben/dbout.nvim/blob/411e46041adeb8661e044f8421d8db5c56a9ef5d/package-lock.json)

**Warstwa Lua:**

- [setup `lua/dbout/init.lua`](https://github.com/zongben/dbout.nvim/blob/411e46041adeb8661e044f8421d8db5c56a9ef5d/lua/dbout/init.lua)
- [defaulty `lua/dbout/config.lua`](https://github.com/zongben/dbout.nvim/blob/411e46041adeb8661e044f8421d8db5c56a9ef5d/lua/dbout/config.lua)
- [polecenie `lua/dbout/cmd.lua`](https://github.com/zongben/dbout.nvim/blob/411e46041adeb8661e044f8421d8db5c56a9ef5d/lua/dbout/cmd.lua)
- [profile `lua/dbout/connection.lua`](https://github.com/zongben/dbout.nvim/blob/411e46041adeb8661e044f8421d8db5c56a9ef5d/lua/dbout/connection.lua)
- [stan `lua/dbout/saver.lua`](https://github.com/zongben/dbout.nvim/blob/411e46041adeb8661e044f8421d8db5c56a9ef5d/lua/dbout/saver.lua)
- [mapowania `lua/dbout/keymap.lua`](https://github.com/zongben/dbout.nvim/blob/411e46041adeb8661e044f8421d8db5c56a9ef5d/lua/dbout/keymap.lua)
- [klient metod `lua/dbout/client.lua`](https://github.com/zongben/dbout.nvim/blob/411e46041adeb8661e044f8421d8db5c56a9ef5d/lua/dbout/client.lua)
- [transport `lua/dbout/rpc.lua`](https://github.com/zongben/dbout.nvim/blob/411e46041adeb8661e044f8421d8db5c56a9ef5d/lua/dbout/rpc.lua)
- [narzędzia `lua/dbout/utils.lua`](https://github.com/zongben/dbout.nvim/blob/411e46041adeb8661e044f8421d8db5c56a9ef5d/lua/dbout/utils.lua)
- [integracja Snacks `lua/dbout/snacks.lua`](https://github.com/zongben/dbout.nvim/blob/411e46041adeb8661e044f8421d8db5c56a9ef5d/lua/dbout/snacks.lua)
- [rozszerzenie Telescope](https://github.com/zongben/dbout.nvim/blob/411e46041adeb8661e044f8421d8db5c56a9ef5d/lua/telescope/_extensions/dbout.lua)

**UI Lua:**

- [compositor](https://github.com/zongben/dbout.nvim/blob/411e46041adeb8661e044f8421d8db5c56a9ef5d/lua/dbout/ui/compositor.lua)
- [Queryer](https://github.com/zongben/dbout.nvim/blob/411e46041adeb8661e044f8421d8db5c56a9ef5d/lua/dbout/ui/queryer.lua)
- [Inspector](https://github.com/zongben/dbout.nvim/blob/411e46041adeb8661e044f8421d8db5c56a9ef5d/lua/dbout/ui/inspector.lua)
- [Viewer](https://github.com/zongben/dbout.nvim/blob/411e46041adeb8661e044f8421d8db5c56a9ef5d/lua/dbout/ui/viewer.lua)
- [winbar](https://github.com/zongben/dbout.nvim/blob/411e46041adeb8661e044f8421d8db5c56a9ef5d/lua/dbout/ui/winbar.lua)

**Backend Node:**

- [wejście procesu `server/main.js`](https://github.com/zongben/dbout.nvim/blob/411e46041adeb8661e044f8421d8db5c56a9ef5d/server/main.js)
- [dispatcher JSON-RPC `server/rpc.js`](https://github.com/zongben/dbout.nvim/blob/411e46041adeb8661e044f8421d8db5c56a9ef5d/server/rpc.js)
- [consumer](https://github.com/zongben/dbout.nvim/blob/411e46041adeb8661e044f8421d8db5c56a9ef5d/server/consumer.js)
- [mapa sterowników i generatory SQL](https://github.com/zongben/dbout.nvim/blob/411e46041adeb8661e044f8421d8db5c56a9ef5d/server/driver.js)
- [SQLite](https://github.com/zongben/dbout.nvim/blob/411e46041adeb8661e044f8421d8db5c56a9ef5d/server/db/sqlite.js)
- [PostgreSQL](https://github.com/zongben/dbout.nvim/blob/411e46041adeb8661e044f8421d8db5c56a9ef5d/server/db/postgres.js)
- [MySQL](https://github.com/zongben/dbout.nvim/blob/411e46041adeb8661e044f8421d8db5c56a9ef5d/server/db/mysql.js)
- [MSSQL](https://github.com/zongben/dbout.nvim/blob/411e46041adeb8661e044f8421d8db5c56a9ef5d/server/db/mssql.js)
- [MongoDB](https://github.com/zongben/dbout.nvim/blob/411e46041adeb8661e044f8421d8db5c56a9ef5d/server/db/mongodb.js)
