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
4. Zmień symbol przez `<leader>ra`. Dla TypeScript użyj `gS` do definicji źródłowej i `<leader>ci` do akcji całego pliku.
5. Zacznij pisać. W menu completion etykiety `[LSP]`, `[Snippet]`, `[Nvim]`, `[Buffer]`, `[Path]`, a w SQL także `[DB]`, pokazują źródło.
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

## Bazy danych: wybór jednego z czterech interfejsów

- **DBee** wybierz do rozbudowanego workspace: wielu typów baz, drzewa struktur, trwałych notatników SQL, call logu, stronicowanego widoku oraz eksportu CSV/JSON/table. Utwardzony backend zapisuje call log i wyniki pod prywatnym `stdpath("state")/dbee/backend`, ale pozostałe profile, notatki, logi i eksporty nadal są osobnym plaintext state.
- **Dbout** wybierz, gdy ważniejsze są manager Telescope, dołączenie połączenia do istniejącego `.sql`, formatter, Inspector i prosty Viewer JSON albo komendy MongoDB EJSON. Obsługuje tylko `sqlite3`, `postgresql`, `mysql`, `mssql` i `mongodb`, nie ma paginacji ani trwałej historii wyników.
- **Dadbod/DBUI** wybierz do lekkiego workflow opartego na natywnych klientach: drawer schematów, zwykłe bufory SQL, bind parameters, zapisane query i completion `[DB]`. `:write` domyślnie wykonuje query DBUI.
- **Dadbod Grip** wybierz do edytowalnego grida, query pada, preview mutacji, statystyk, notebooków i pracy z plikami przez DuckDB. Grip ma więcej osłon UI, lecz jego `mode="ro"` nie zastępuje roli read-only na serwerze.
- **Do bezpiecznej nauki** użyj osobnej bazy SQLite albo tymczasowego konta serwerowego tylko do odczytu. Żaden z czterech interfejsów nie jest granicą uprawnień.
- **Do migracji, produkcyjnego DML i transakcji** użyj natywnego klienta z kontrolowanym połączeniem, transakcją i backupem. UI Neovima nie jest granicą uprawnień; właściwą granicą pozostaje osobny użytkownik bazy z minimalnymi prawami.

Szczegóły zawierają [tutorial DBee](plugins/11-nvim-dbee.md#plugin-nvim-dbee), [tutorial Dbout](plugins/12-dbout.md#plugin-dbout), [tutorial Dadbod/DBUI](plugins/15-vim-dadbod.md#plugin-vim-dadbod) i [tutorial Grip](plugins/16-dadbod-grip.md#plugin-dadbod-grip).

## DBee: bezpieczny SQLite, serwer, paginacja i eksport

### Lokalny SQLite

1. Utwórz katalog poza repozytorium i uruchom Neovim z połączeniem bez sekretów:

```sh
mkdir -p "$HOME/tmp"
export DBEE_CONNECTIONS='[
  {
    "id": "workflow-sqlite",
    "name": "SQLite workflow",
    "type": "sqlite",
    "url": "~/tmp/dbee-workflow.sqlite"
  }
]'
nvim
```

2. Otwórz `<leader>Bd`, rozwiń `DBEE_CONNECTIONS` przez `o`, a na `SQLite workflow` naciśnij `Enter`, aby jawnie ustawić aktywne połączenie. `o` na połączeniu pobiera strukturę.
3. Pod `local notes` wybierz `new`, nadaj notatnikowi nazwę i od razu wykonaj `:w`. Lokalna notatka należy do ID połączenia, nie do katalogu projektu.
4. Zacznij od odczytu i wykonuj każdą instrukcję osobno przez `Enter` pod kursorem:

```sql
SELECT sqlite_version();

SELECT name
FROM sqlite_schema
WHERE type = 'table'
ORDER BY name;
```

5. Do dokładnie zaznaczonego fragmentu użyj Visual `BB`; Normal `BB` wysyła cały notatnik. DDL i DML ćwicz tylko na tej testowej bazie, po przejrzeniu zaznaczenia, ponieważ DBee nie pyta o potwierdzenie.
6. `Enter` na tabeli otwiera helpery. Najpierw użyj `y`, aby skopiować i przeczytać wygenerowane zapytanie; `Enter` wykona helper natychmiast i nie gwarantuje trybu read-only.

### Baza serwerowa

1. Przygotuj osobne konto tylko do odczytu i dostarcz jego dane z zaufanej lokalnej powłoki lub secret managera. Sam rekord może odwoływać się do środowiska bez umieszczania wartości w repozytorium:

```sh
export DBEE_CONNECTIONS='[
  {
    "id": "postgres-review",
    "name": "PostgreSQL review",
    "type": "postgres",
    "url": "postgres://{{ env `DBEE_PG_USER` }}:{{ env `DBEE_PG_PASSWORD` }}@db.example.test:5432/app?sslmode=verify-full"
  }
]'
```

2. Ustaw `DBEE_PG_USER` i `DBEE_PG_PASSWORD` poza dokumentacją oraz repozytorium, uruchom `nvim` z tego środowiska i wybierz połączenie przez `Enter`. Znaki specjalne w URI muszą być percent-encoded; nie drukuj rozwiniętego URL do `:messages` ani logu. Środowisko jest dziedziczone przez procesy i nie jest sejfem, a `exec` z pliku połączeń wykonuje kod, więc używaj wyłącznie zaufanych źródeł.
3. Najpierw sprawdź tożsamość i kontekst bez modyfikacji danych:

```sql
SELECT current_database(), current_schema(), current_user;
```

4. Dodawaj jawny `LIMIT` do zapytań eksploracyjnych i kwalifikuj schemat. Błąd drawera może oznaczać brak praw do katalogów systemowych mimo działającego prostego `SELECT`.
5. Dla `UPDATE`, `DELETE`, DDL i procedur nie polegaj na UI ani osobnych wywołaniach jako bezpiecznej transakcji. Użyj natywnego klienta, minimalnych uprawnień i planu odtworzenia danych.

### Wynik i eksport

1. W wyniku używaj `F` / `E` do pierwszej / ostatniej znanej strony oraz `H` / `L` do poprzedniej / następnej. Domyślne 100 wierszy dotyczy tylko prezentacji: backend nadal pobiera, buforuje i archiwizuje cały wynik, dlatego prawdziwy limit kosztu musi znaleźć się w zapytaniu.
2. W call logu `Enter` przywraca wcześniejszy dostępny wynik. `Ctrl-c` ma praktyczny efekt tylko podczas `executing`; po przejściu do `retrieving` przypięta rewizja nie zatrzyma pełnego pobierania.
3. `yaj` / `yac` kopiuje bieżący wiersz jako JSON / CSV, Visual obsługuje zakres wierszy, a `yaJ` / `yaC` kopiuje całość. Prefiks rejestru działa, więc `"+yaC` kieruje pełny CSV do schowka systemowego.
4. Eksport poleceniem obejmuje cały aktualny wynik:

```vim
:Dbee store csv file /tmp/dbee-result.csv
:Dbee store json yank +
```

5. Cel `file` bez pytania tworzy lub obcina wskazany plik, eksport całości czeka na pełne pobranie, a CSV zawsze zawiera nagłówek. Sprawdź ścieżkę i zawartość przed wykonaniem; nie eksportuj poufnych danych do współdzielonego `/tmp`.
6. Zamknij workspace przez `<leader>Bd`. To nie usuwa notatników, profili, call logu ani archiwów wyników. Nowy backend przechowuje call log pod `stdpath("state")/dbee/backend/call-log.json`, a wyniki pod `stdpath("state")/dbee/backend/history/`; katalogi mają `0700`, a pliki `0600` na POSIX. Po migracji ręcznie sprawdź i usuń należące do siebie stare `/tmp/dbee-calllog.json` oraz `/tmp/dbee-history` dopiero po zatrzymaniu wszystkich starych procesów DBee.

## Dbout: manager, Queryer, Inspector, Viewer i MongoDB

1. Najbezpieczniej zacznij od testowego SQLite. Otwórz `<leader>Bo`, przejdź z Insert do Normal przez `Esc`, naciśnij `n`, wybierz dokładnie `sqlite3` i podaj absolutną ścieżkę poza repozytorium, na przykład `/tmp/dbout-workflow.sqlite3`.
2. W Normal pickera `Enter` otwiera profil w nowym Queryerze, `a` dołącza go do bieżącego bufora, `e` edytuje, a `d` usuwa profil natychmiast bez confirm i undo. Usunięcie profilu nie usuwa pliku SQLite.
3. Aby użyć istniejącego `.sql`, najpierw go zapisz, potem wykonaj `<leader>Bo`, `Esc`, wybierz profil i naciśnij `a` albo użyj `:Dbout AttachConnection`. Nie przełączaj bufora podczas asynchronicznego otwierania, bo attach może trafić do innego bieżącego bufora; nie ma osobnej akcji detach.
4. W Queryerze umieść jedno zapytanie w osobnym zestawie wierszy. Visual `F7` formatuje pełne zaznaczone wiersze, a Visual `F6` je wykonuje; w Normal lub Insert oba skróty obejmują cały bufor. Dbout nie wybiera statementu pod kursorem i nie wiąże parametrów.
5. Dla SQLite zacznij od nieszkodliwego odczytu:

```sql
SELECT name
FROM sqlite_schema
WHERE type = 'table'
ORDER BY name;
```

6. Inspector i Viewer otwierają się domyślnie po lewej i prawej stronie Queryera. `F8` / `F9` przełącza odpowiedni panel z Queryera, Inspectora lub Viewera w Normal i Insert; `q` w Normal zamyka tylko bieżący panel, nie połączenie ani Queryer.
7. W Inspectorze `H` / `L` zmienia kartę, `I` wybiera obiekt lub akcję, `Backspace` wraca poziom wyżej, a `R` czyści cache list i odświeża. Zapisz potrzebny SQL przed `I`: definicja obiektu albo szablon z karty `Columns` zastępuje cały Queryer bez pytania, a wygenerowane placeholdery wymagają ręcznej poprawy.
8. Viewer pokazuje JSON i trzyma najwyżej 10 wyników danego Queryera tylko w pamięci. `}` przechodzi do starszego wyniku, `{` do nowszego, a `Ctrl-x` usuwa bieżący wpis bez potwierdzenia. Dbout materializuje cały wynik bez paginacji, więc ograniczaj odczyt przez `LIMIT`.
9. Dla MongoDB utwórz profil typu `mongodb` wyłącznie dla lokalnej bazy testowej albo tymczasowego konta read-only; URI musi zawierać nazwę bazy. Queryer przyjmuje jeden dokument Extended JSON, nie składnię `mongosh`:

```json
{
  "listCollections": 1,
  "filter": {
    "type": "collection"
  }
}
```

10. `F7` parsuje i formatuje EJSON, a `F6` przekazuje dokument do `db.command()`. Dla `find` Viewer pokazuje tylko `cursor.firstBatch` i nie wykonuje `getMore`; komendy `insert`, `update`, `delete` oraz `drop` są wykonywane równie bezpośrednio i bez potwierdzenia.
11. `q` zamyka tylko panel. Usuń Queryer świadomie przez `:bdelete`, gdy kontekst nie jest już potrzebny. Unikaj równoległych zapytań, wielu kart i kilku Queryerów tego samego profilu: przypięta rewizja ma wspólny proces Node, globalny kontekst oraz znane wyścigi przy odpowiedziach i `BufDelete`.

**Ostrzeżenie o sekretach:** Dbout pobiera connection string zwykłym `input()`, zapisuje go jawnym tekstem pod `stdpath('state')/dbout/db_explorer.json`, pokazuje w pickerach i może utrwalić w historii input oraz ShaDa. W tej rewizji nie wpisuj rzeczywistych stałych poświadczeń serwerowych; użyj izolowanej bazy testowej albo krótkotrwałego konta o minimalnych prawach. PostgreSQL bez własnej opcji SSL używa nieweryfikowanego certyfikatu, dlatego świadomy test serwera wymaga co najmniej `sslmode=verify-full`; nie zastępuj go `sslmode=disable`. Osobne naciśnięcia `F6` nie tworzą wiarygodnej wspólnej transakcji, a Dbout nie ma anulowania zapytania.

## Dadbod i DBUI: drawer, query i completion

1. Dostarcz URL poza repo przez mechanizm natywnego klienta, `$DATABASE_URL`, `g:dbs` z funkcją rozwiązującą sekret albo `:DBUIAddConnection` bez literalnego hasła.
2. Otwórz `<leader>Bu`, rozwiń połączenie oraz schemat przez `o` i otwórz nowy query buffer.
3. Wpisz ograniczony `SELECT`. Completion `[DB]` podpowiada tabele, kolumny i aliasy; po zmianie schematu wyczyść cache przez `:DBCompletionClearCache`.
4. `:write` wykonuje cały bufor, ponieważ DBUI zachowuje `execute_on_save=1`. Przed zapisem sprawdź aktywne połączenie i pełny tekst.
5. Dla `:param` użyj `<leader>Bp`; tymczasowy query utworzony przez DBUI zachowaj przez `<leader>Bs`. Mapowania powstają wyłącznie w buforze przypisanym do DBUI, nie w zwykłym SQL, Dbout ani Grip.
6. W preview Dadbod `R` powtarza, `r` pozwala edytować ostatni tekst, a `gq` zamyka wynik.

## Dadbod Grip: query pad i etapowana edycja

1. Otwórz `<leader>Bg`. Profil może używać `${VAR}` i `env_file`; nie wpisuj literalnego hasła do zwykłego promptu.
2. Po połączeniu `1` fokusuje schema sidebar, `2` query pad, a `3` grid. `Ctrl-p` pokazuje palette wszystkich akcji.
3. W query padzie `Ctrl-Enter` wykonuje Visual selection, SQL fence albo instrukcję oddzieloną pustymi wierszami pod kursorem; cały bufor jest fallbackiem, gdy Grip nie znajdzie instrukcji. Wbudowane completion działa niezależnie od `[DB]` Dadbod.
4. W gridzie `i` edytuje komórkę, `d` etapuje usunięcie, `u` wycofuje, `gs` pokazuje SQL, a `a` dopiero po preview stosuje zmiany.
5. Lokalny `mode="ro"` jest tylko osłoną UI. Do prawdziwego odczytu użyj roli serwerowej bez DML/DDL; SQL Server nadal przyjmuje dowolny tekst z query pada mimo read-only grida.
6. Po pracy sprawdź projektowe `.grip/history.jsonl`, `.grip/filters.json` i `.grip/queries/`. To repo ignoruje `.grip/`, lecz inne projekty wymagają własnej reguły.

## Wayfinder: Explore, filtr, Trail i quickfix

1. Zapisz bufor, ustaw kursor wewnątrz nazwy symbolu i naciśnij `<leader>Wf`. Na górnym pasku sprawdź, czy celem jest `Symbol`, czy fallback `File`; niezapisany tekst może nie zgadzać się z dyskowym preview.
2. Przechodź fasety `All`, `Calls`, `Refs`, `Tests`, `Git`, `Trail`, `Saved` przez `h` / `l` albo `Shift-Tab` / `Tab`. `[LSP]` jest semantyczne, `[TXT]` jest tylko dopasowaniem `rg`, testy są heurystyką, a Git dotyczy całego pliku, nie symbolu.
3. Naciśnij `/` i wpisz na przykład `"create user" !generated`, aby wymagać frazy i odrzucić szum. Filtr działa tylko na już zebranych rekordach bieżącej sesji; `Ctrl-l` go czyści.
4. Użyj `D`, aby zobaczyć dokładny cel, potem `e`, aby bez zamykania pickera eksplorować wybrany wynik. `b` / `f` porusza historią Explore, która znika po zamknięciu; `Enter` wykonuje zwykły jump, a `Ctrl-t` może wrócić przez tagstack.
5. `p` przypina wybrany rekord, `a` bieżący cel, a `A` całą dotychczasową drogę Explore. `P` albo globalne `<leader>Ws` pokazuje roboczy Trail; `dd` usuwa wskazany element, a `da` czyści cały roboczy Trail bez pytania.
6. Przejrzyj Trail i wybierz `S` → `Save Trail As`. Robocza lista jest globalna dla bieżącej instancji Neovim, więc przed zapisem w innym repo sprawdź wszystkie elementy; nazwany snapshot jest zapisany per rozpoznany projekt, ale nie per branch.
7. Po zmianach użyj `S` → `Save Trail`, gdy pasek pokazuje `modified`. Po restarcie otwórz plik właściwego projektu, wykonaj `:WayfinderTrailResume`, a potem `<leader>Ws` lub `<leader>Wo`; samo `<leader>Ws` nie wczytuje ostatniego zapisu.
8. Po roboczym Trail przechodź bez pickera przez `<leader>Wn` / `<leader>Wp`, a bieżący element otwieraj `<leader>Wo`. Brakujące pliki są zachowywane w zapisie i pomijane podczas tej nawigacji.
9. `x` eksportuje widoczne, przefiltrowane rekordy aktualnej fasety do nowej listy quickfix, ale jej nie otwiera; wykonaj `:copen`, potem używaj `[q` / `]q`. `:WayfinderExportTrailQuickfix` działa także poza UI i eksportuje wszystkie poprawne elementy roboczego Trail w kolejności przypinania.
10. Przed `[` / `]`, load albo resume zapisz potrzebny stan: operacje zastępują roboczy Trail bez promptu o `modified`. `Save Trail` nadpisuje dołączoną nazwę, `da` czyści listę, a usunięcie nazwanego Trail po wyborze nie ma drugiego potwierdzenia.

Pełna mapa paneli, semantyka filtra, storage i ograniczenia źródeł są w [tutorialu Wayfinder](plugins/13-wayfinder.md#plugin-wayfinder).

## Punkty powrotu: marki, bookmarki czy Trail

- **Natywna marka `a`-`z`** jest krótkim, nazwanym celem w jednym buforze; ustaw ją przez `ma`, skocz dokładnie przez `` `a ``, a wierszowo przez `'a`. ShaDa może zachować marki lokalne tylko dla ograniczonej liczby ostatnich plików.
- **Natywna marka `A`-`Z`** jest jednym globalnym celem między plikami i również może przetrwać restart przez ShaDa. `<leader>ma` otwiera Telescope nad natywnymi markami, nie nad bookmarkami `marks.nvim`.
- **Udogodnienia `marks.nvim` dla liter**, takie jak `m,`, `m;`, `m[` i `m]`, nadal ustawiają albo obsługują natywne marki. Wtyczka dodaje znaki i cache, lecz nie tworzy dla liter osobnego trwałego storage; lokalne `J` nie używa już tymczasowej marki `z`.
- **Bookmark `marks.nvim` `m0`-`m9`** jest nienazwanym extmarkiem grupy. `m{` / `m}` cyklicznie przechodzi po grupie rozpoznanej pod kursorem, `dm=` usuwa jeden wpis, a `dm0`-`dm9` całą grupę ze wszystkich buforów. Bookmark znika po `BufDelete` albo restarcie i nie trafia do ShaDa.
- **Historia Explore Wayfindera** istnieje tylko podczas jednego otwarcia pickera. **Roboczy Trail** pozostaje w pamięci bieżącego procesu po zamknięciu pickera, ale znika przy restarcie. **Nazwany Trail** jest jawnym, projektowym snapshotem pod `stdpath('state')/wayfinder/trails/`; po restarcie wymaga load albo `:WayfinderTrailResume` i nie jest rozdzielany per branch.
- **Praktyczny wybór:** znana pojedyncza pozycja to marka, kilka ulotnych punktów bieżącej sesji to grupa bookmarków, a wieloplikowa ścieżka dochodzenia z kolejnością i możliwością wznowienia to zapisany Wayfinder Trail.

Marka, bookmark i Trail są wskaźnikami, nie backupem zawartości. Po przeniesieniu lub usunięciu pliku pozycje mogą się zestarzeć; szczegóły mapowań i trwałości zawierają [tutorial marek](plugins/14-marks.md#plugin-marks) oraz [tutorial Wayfinder](plugins/13-wayfinder.md#plugin-wayfinder).

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
