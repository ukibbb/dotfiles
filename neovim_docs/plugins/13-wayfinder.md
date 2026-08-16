# Nawigacja po powiązanym kodzie: Wayfinder

<a id="plugin-wayfinder"></a>
## `wayfinder.nvim`

**Wersja opisana w tym dokumencie:** `error311/wayfinder.nvim` v0.3.1, commit [`2ce480d35626ddb533ba594fa7ca865d61184ec6`](https://github.com/error311/wayfinder.nvim/commit/2ce480d35626ddb533ba594fa7ca865d61184ec6).

**Co robi i po co:** otwiera prowadzony picker powiązanego kodu dla symbolu pod kursorem albo bieżącego pliku. Zbiera definicje, referencje, wywołujących, prawdopodobne testy i historię pliku, pozwala zmieniać punkt eksploracji bez zamykania UI oraz budować własną ścieżkę Trail. Nie jest zamiennikiem Telescope, zwykłego `rg` ani dowolnego wyszukiwania po repozytorium.

**Ładowanie lokalne:** `opts = {}`, czyli aktywne są upstreamowe wartości `performance = "balanced"` i `scope.mode = "project"`. Każde z 13 publicznych poleceń Ex jest wyzwalaczem Lazy. Pięć mapowań lokalnych również ładuje wtyczkę na żądanie.

**Aktywne lokalne, tryb Normal:**

- **`<leader>Wf`**: Otwórz Wayfinder dla symbolu pod kursorem lub bieżącego pliku. **Wywołanie lokalne:** `:Wayfinder`.
- **`<leader>Wn`**: Otwórz następny poprawny element roboczego Trail. **Wywołanie lokalne:** `:WayfinderTrailNext`.
- **`<leader>Wp`**: Otwórz poprzedni poprawny element roboczego Trail. **Wywołanie lokalne:** `:WayfinderTrailPrev`.
- **`<leader>Wo`**: Otwórz bieżący poprawny element roboczego Trail. **Wywołanie lokalne:** `:WayfinderTrailOpen`.
- **`<leader>Ws`**: Otwórz Wayfinder bezpośrednio na fasecie `Trail`. **Wywołanie lokalne:** `:WayfinderTrailShow`.

Wielkie `W` jest częścią lokalnych skrótów. Przykładowe małe `<leader>wf` i `<leader>wt...` z README są **Przykładem nieaktywnym**, nie stanem tej konfiguracji. Wewnątrz pickera małe `p` przypina wiersz; nie należy go mylić z globalnym `<leader>Wp`, które przechodzi do poprzedniego elementu Trail.

**Wymagania:** Neovim 0.10 lub nowszy. `rg` jest potrzebny do tekstowych dopasowań w `Refs`, `git` do fasety `Git` i do najlepszej ścieżki wykrywania kandydatów testowych. LSP jest opcjonalny i zależy od klienta podłączonego do konkretnego bufora.

**Założenie środowiska lokalnego:** `rg` i `git` są dostępne. Dane LSP są dostępne tylko w buforach, do których faktycznie dołączył odpowiedni klient i dla metod obsługiwanych przez ten serwer.

## Model mentalny

Wayfinder działa wokół jednego **celu**, a nie wokół dowolnego zapytania:

1. `<leader>Wf` ustala cel z pozycji kursora.
2. Wtyczka rozpoznaje prosty token symbolu albo przechodzi do trybu pliku.
3. Trzy źródła zbierają połączone lokalizacje: LSP wraz z `rg`, heurystyka testów oraz Git.
4. Fasety pokazują różne przekroje tych samych wyników.
5. `e` zmienia cel i ponownie uruchamia zbieranie bez wychodzenia z pickera.
6. `b` i `f` cofają lub ponawiają takie zmiany celu.
7. `p`, `a` i `A` kopiują świadomie wybrane przystanki do roboczego Trail.
8. Zapis nazwany utrwala snapshot roboczego Trail dla projektu.

Najważniejsze rozróżnienia:

- **wyniki źródeł** są obliczane dla aktualnego celu;
- **historia Explore** jest tymczasowym stosem bieżącego otwarcia pickera;
- **roboczy Trail** jest wspólną listą w pamięci bieżącej instancji Neovim;
- **nazwany zapisany Trail** jest trwałym snapshotem przypisanym do rozpoznanego projektu;
- samo `e` niczego nie przypina, a samo `p` niczego nie zapisuje na dysku.

## Symbol i fallback pliku

Rozpoznawanie symbolu jest celowo proste. Wtyczka szuka pod kursorem ciągu pasującego do `[%w_]+`, czyli tokenu z liter/cyfr i podkreślenia. Nie pyta w tym kroku Treesittera, `documentSymbol` ani parsera języka.

- Kursor wewnątrz `create_user` daje tryb `Symbol` i temat `create_user`.
- Kursor na spacji, kropce, operatorze albo poza tokenem daje tryb `File`.
- Nazwy złożone, operatory i część identyfikatorów nie-ASCII mogą nie zostać rozpoznane jako jeden symbol.
- Tryb `Symbol` zaczyna od `Calls`.
- Tryb `File` zaczyna od `All`.
- Gdy `Calls` jest puste, a `Refs` zdążyło już zebrać więcej niż jeden wynik, pierwsze otwarcie symbolu może automatycznie przejść do `Refs`.

W trybie pliku źródło LSP zwraca stan „brak celu symbolu”, a tekstowe `rg` także nie startuje, bo wymaga tekstu symbolu. Nadal użyteczne są `Tests`, wyliczane między innymi z nazwy pliku, oraz `Git`, wyliczany dla ścieżki pliku.

`e` ponownie wykrywa token dokładnie w lokalizacji wybranego wiersza. Jeżeli go znajdzie, nowy cel jest symbolem. Jeżeli nie, Wayfinder eksploruje lokalizację lub plik. Pasek górny pokazuje wcześniej rzeczywisty zamiar, na przykład `Explore findUser` albo `Explore service.ts:42`.

## Interfejs trzech paneli

Wayfinder tworzy wyśrodkowaną ramkę i trzy interaktywne panele:

- **lewy panel, facet rail:** `All`, `Calls`, `Refs`, `Tests`, `Git`, `Trail`, `Saved` wraz z licznikami;
- **środkowy panel, result list:** nagłówki grup i gęste, dwuwierszowe rekordy z ikoną, etykietą, badge'em, ścieżką oraz markerem przypięcia;
- **prawy panel, preview:** kontekst pliku, zapisany Trail, stan źródła albo historyczna treść pliku z Git.

Nad panelami jest jednoliniowy pasek stanu. Zależnie od szerokości może pokazać tryb `Symbol`/`File`, temat, liczbę widocznych wyników, nieprojektowy scope, aktywne ładowanie, historię Explore, stan Trail, filtr, powód dopasowania, cel `e` i plik źródłowy. Długie segmenty są obcinane, a mniej ważne końcowe segmenty mogą się nie zmieścić.

Pod panelami domyślnie są dwa wiersze podpowiedzi klawiszy. `?` przełącza je na czas bieżącej instancji Neovim; ukrycie oddaje wysokość panelom. Nie jest to trwała preferencja między restartami.

Podgląd zwykłego wyniku:

- czyta plik z dysku;
- ustawia filetype i syntax dla wyróżniania;
- pokazuje projektowo względną ścieżkę i zakres w nagłówku;
- dodaje numery linii jako virtual text;
- wyróżnia zakres kontekstu i dokładny wiersz celu;
- aktualizuje się po domyślnym debounce 40 ms.

Podgląd Git wykonuje `git show HASH:ścieżka`, więc pokazuje treść pliku w wybranym commicie, a nie patch commita. Podgląd `Saved` pokazuje uporządkowane elementy przed załadowaniem listy. Podgląd wiersza stanu pokazuje jego wyjaśnienie.

Wiersze i preview korzystają głównie z zawartości zapisanej na dysku. Przy zmodyfikowanym, niezapisanym buforze pozycje zwrócone przez LSP mogą odnosić się do nowszej treści bufora, podczas gdy etykieta, wykrywanie celu `e`, heurystyka testu i preview widzą starszy plik. Przed dokładną eksploracją najlepiej zapisać bufor.

## Fasety i wiarygodność

### `All`

`All` łączy tylko wyniki `Calls`, `Refs`, `Tests` i `Git`. Nie włącza elementów `Trail` ani rekordów `Saved`; te mają osobne fasety i liczniki.

Wewnętrzne priorytety ustawiają zwykle definicje przed wywołującymi, referencje LSP przed tekstem, potem testy i Git. To ranking interfejsu, nie dowód poprawności. Ta sama lokalizacja może pojawić się osobno jako definicja i referencja, bo deduplikacja zachowuje rozdział faset.

### `Calls`

`Calls` zawiera dwie grupy:

- **`Definitions`**, badge `[LSP]`: wyniki `textDocument/definition`;
- **`Callers`**, badge `[LSP]`: wywołujący z `prepareCallHierarchy` i `callHierarchy/incomingCalls`.

Nie jest to lista wywołań wychodzących z funkcji. Nie zawiera osobnego zapytania `outgoingCalls`, `implementation` ani `typeDefinition`. Z każdego klienta bierze tylko pierwszy element zwrócony przez `prepareCallHierarchy`, a incoming call wskazuje `from.selectionRange`/`from.range` symbolu wywołującego; wtyczka nie rozwija wszystkich `fromRanges` do osobnych miejsc wywołania. Dokładność zależy od serwera językowego, jego indeksu, obsługi metod oraz aktualności bufora. Brak klienta daje `Calls unavailable`; klient bez call hierarchy może nadal dostarczyć definicję.

### `Refs`

`Refs` może jednocześnie zawierać:

- **`LSP References`**, badge `[LSP]`: semantyczne lokalizacje od serwera;
- **`Text Matches`**, badge `[TXT]`: leksykalne dopasowania `rg` z powodem `plain text fallback`.

`[LSP]` jest zwykle silniejszym sygnałem semantycznym, ale serwer może zwrócić niepełny lub opóźniony indeks. `[TXT]` oznacza tylko identyczne słowo w tekście. Może trafić w komentarz, string, martwy kod albo symbol o tej samej pisowni i nie rozumie rename'ów ani aliasów.

Tekst nie jest uruchamiany wyłącznie wtedy, gdy LSP zwróci zero. W v0.3.1 `rg` jest wykonywany po zapytaniach referencji zawsze, gdy `limits.text.enabled`, istnieje symbol i program jest dostępny. Deduplikacja preferuje wcześniejszą lokalizację LSP, jeżeli LSP i `rg` wskazują tę samą fasetę, ścieżkę, linię i kolumnę.

### `Tests`

`Tests` zawiera grupę `Likely Tests` z badge'em `[TEST]`. Są to kandydaci heurystyczni, nie wyniki adaptera testowego, AST ani uruchomienia testów.

Sygnały z nazwy i ścieżki pliku:

- `test` albo `spec` w ścieżce dodaje 40 punktów;
- stem bieżącego pliku w ścieżce kandydata dodaje 35;
- tekst symbolu w ścieżce dodaje 20;
- `__tests__` albo `/tests/` dodaje 10.

Plik z wynikiem większym od zera staje się kandydatem. Wtyczka czyta najwyżej pierwszych 250 linii i wybiera najlepszy cel na podstawie tekstu symbolu, stemu pliku oraz prostych wzorców `describe(`, `it(`, `test(`, `def test_` i `function test_`. Jeżeli nie znajdzie trafniejszej linii, używa pierwszej niepustej albo linii 1.

Najsilniejszy powód widoczny w pasku może brzmieć `symbol test block`, `symbol text match`, `filename text match`, `test block` albo `test file`. Jeden plik daje najwyżej jeden wiersz. Kandydat nie gwarantuje, że test importuje cel, że kompiluje się ani że w ogóle jest testem.

### `Git`

`Git` zawiera grupę `Recent Commits` z badge'em `[GIT]`. Dla bieżącego pliku uruchamia odpowiednik:

```sh
git log -n LIMIT --pretty=format:%h%x09%s%x09%cr -- RELATIVE_PATH
```

Wiersz wiarygodnie mówi, że commit dotknął tej ścieżki. Nie mówi, że commit dotyczył bieżącego symbolu. `e` jest zablokowane, bo commit jest historią pliku, a nie precyzyjną lokalizacją kodu. `Enter` na takim wierszu otwiera bieżący plik roboczy na linii 1; historyczna treść istnieje tylko w preview. Wayfinder nie pokazuje diffu, autora, pełnego hasha ani rename-follow przez `--follow`.

### `Trail`

`Trail` pokazuje aktualną listę roboczą. Najpierw grupuje `Explore Targets` dodane przez `a`/`A`, potem `Pinned Rows` dodane przez `p`. Brak pliku jest jawnie oznaczony `[MISSING]`.

Grupowanie jest prezentacją fasety. Podstawowa lista nadal zachowuje kolejność faktycznego przypinania; tej kolejności używają zewnętrzne przechodzenie Trail i eksport całego Trail do quickfix.

### `Saved`

`Saved` pokazuje nazwane Traile bieżącego projektu, posortowane alfabetycznie. Każdy wiersz ma liczbę elementów, liczbę brakujących ścieżek i jeden badge:

- **`[ACTIVE]`**: roboczy Trail jest aktualnie dołączony do tej nazwy w tym samym projekcie;
- **`[LAST]`**: zapis jest ostatnio aktywny na dysku, ale nie jest bieżącym dołączonym Trailem;
- **`[SAVED]`**: zwykły zapis nieaktywny.

Aktywny, zmieniony roboczy Trail dostaje dodatkowy tekst `modified`. `Enter` ładuje wybrany zapis do roboczego Trail i przechodzi do fasety `Trail`. `s`, `v` i `t` nie otwierają zapisu; wyświetlają wskazówkę, aby użyć `Enter`.

## Zbieranie LSP i `rg`

Dla celu symbolu kolektor uruchamia trzy gałęzie:

1. Definicje startują od razu.
2. Incoming callers startują po około 10 ms.
3. Referencje startują po około 20 ms.

Każde zapytanie trafia do wszystkich klientów podłączonych do bufora, które deklarują obsługę danej metody. Błędy pojedynczego klienta nie są osobnym wierszem; jego odpowiedź jest pomijana.

Pozycje LSP nie przechodzą tu przez konwersję właściwą dla `client.offset_encoding`. Wayfinder wysyła surowe `character = col - 1`, wspólne dla wszystkich klientów, a zwrócone `range.start.character` zapisuje jako kolumnę przez proste `+ 1`. Przy ASCII zwykle jest to niewidoczne, ale znak nie-ASCII przed celem albo jednoczesne klienty UTF-8/UTF-16 mogą przesunąć kolumnę jumpa oraz miejsce, w którym `e` próbuje ponownie wykryć symbol.

Gałąź referencji wykonuje najpierw `textDocument/references` z `includeDeclaration = false`, potem ponawia z `includeDeclaration = true`, scala i deduplikuje wyniki, a następnie uruchamia `rg`. `rg` dostaje:

```sh
rg --line-number --column --no-heading --fixed-strings --word-regexp SYMBOL .
```

Polecenie działa z katalogu aktywnego scope. Zachowuje zwykłe reguły ignorowania ripgrep, szuka stałego tekstu jako całego słowa i nie interpretuje symbolu jako regexu. Jeżeli bufor celu jest widoczny w oknie, post-processing odrzuca każdy tekstowy wynik z bieżącej linii kursora w tym pliku, a nie tylko wystąpienie dokładnie pod kursorem. Gdy bufor celu nie jest widoczny, tej redukcji bieżącej linii nie ma.

Responsywność i anulowanie:

- odpowiedzi LSP są przetwarzane porcjami po 40 lokalizacji i oddają sterowanie pętli Neovim;
- ukończona gałąź może od razu dodać częściowe wyniki, gdy inne jeszcze pracują;
- `limits.refs.timeout_ms` finalizuje całą kolekcję LSP z tym, co już zebrano;
- `limits.text.timeout_ms` osobno zatrzymuje `rg` i zachowuje zebrane dopasowania;
- zamknięcie, nowe otwarcie i `e` anulują śledzone requesty LSP oraz job `rg`;
- spóźnione callbacki starej sesji są ignorowane;
- podczas `e` do innego załadowanego pliku Wayfinder próbuje dołączyć do niego klientów z poprzedniego bufora.

Semantyczne referencje i `rg` są ograniczane do scope. Definicje oraz incoming callers nie są w tej rewizji postfiltrowane przez scope, więc mogą wskazać kod poza pakietem. Limit `limits.refs.max_results` ogranicza referencje, ale nie tworzy osobnego twardego limitu dla definicji i callers.

Bez LSP `Calls` jest niedostępne, lecz `Refs` może nadal działać przez `rg`. Bez `rg` pozostają referencje LSP. Bez obu źródeł wiersz stanu wyjaśnia brak.

## Wykrywanie testów

Pierwsza próba listy kandydatów to `git ls-files -- .` uruchomione w katalogu scope. Ma to ważne konsekwencje:

- w działającym repo przeglądane są pliki śledzone przez Git;
- nowy, nieśledzony test nie pojawi się, dopóki ta ścieżka Git się powiedzie;
- wszystkie typy śledzonych plików mogą być ocenione po nazwie, nie tylko cztery rozszerzenia fallbacku;
- timeout tej komendy jest `limits.tests.timeout_ms`.

Jeżeli Git zawiedzie albo przekroczy timeout, fallback `vim.fs.find` szuka tylko `*.lua`, `*.ts`, `*.tsx` i `*.js`. Limit kandydatów fallbacku to co najmniej 300 albo `12 * limits.tests.max_results`. Sam fallback filesystemu nie ma osobnego timera.

Źródło testów zwraca wynik dopiero po ocenie kandydatów, bez częściowych batchy. Zamknięta lub zastąpiona sesja ignoruje końcowy callback, ale v0.3.1 nie zwraca z tego źródła uchwytu anulowania procesu `git ls-files`.

## Historia Git

Źródło najpierw wykonuje `git rev-parse --show-toplevel` z katalogu scope, a potem `git log` dla bieżącej ścieżki. Każdy etap używa `limits.git.timeout_ms`. `limits.git.max_commits` ogranicza wiersze.

Git działa dla ścieżki bieżącego celu, nie dla symbolu i nie dla wszystkich plików scope. Nieśledzony plik zwykle da pustą historię. Brak programu, brak repo, wyłączone źródło lub timeout kończy się wierszem stanu zamiast wyjątkiem. Podobnie jak testy, źródło Git ignoruje spóźniony wynik zamkniętej sesji, lecz jego procesy `vim.system` nie mają uchwytu anulowania w v0.3.1 i mogą dobiec do końca lub timeoutu.

## Wiersze stanu

Gdy faseta nie ma prawdziwych rekordów, środkowy panel nadal pokazuje wybieralny, zwarty wiersz stanu. Przykładowe etykiety przypiętej wersji:

- `Loading LSP...`, `Loading tests...`, `Loading git...` albo `Loading connected code...`;
- `No matches for /...`;
- `Trail is empty`;
- `No saved Trails` albo `Saved Trails unavailable`;
- `Calls unavailable` albo `No calls or definitions found`;
- `References unavailable` albo `No references found`;
- `Tests unavailable` albo `No likely tests found`;
- `Git unavailable` albo `No recent commits found`;
- `No connected code found` dla pustego `All`.

Najpierw wygrywa stan ładowania, potem aktywny filtr, a dopiero później szczegółowy pusty stan fasety. `Calls unavailable` oznacza brak dołączonego LSP. `References unavailable` wymaga braku LSP oraz wyłączonego tekstu albo brakującego `rg`. `Tests unavailable` oznacza brak jakichkolwiek plików kandydatów w scope. `Git unavailable` obejmuje wyłączone źródło, brak ścieżki, plik poza repo oraz niedokończoną historię. `Saved Trails unavailable` oznacza błąd odczytu storage, na przykład niepoprawny JSON.

Wiersz stanu nie zwiększa licznika `results`. Preview pokazuje jego przyczynę. `Enter`, `s`, `v`, `t`, `p` i `e` pozostawiają picker otwarty i pokazują wyjaśnienie; `x` nie eksportuje go jako lokalizacji.

## Pełna mapa pickera

Poniższe mapowania są **Domyślne wtyczki**, a nie globalne mapowania lokalnej konfiguracji. Są buffer-local, tylko w trybie Normal, `silent` i `nowait`, instalowane identycznie w panelach facet, list i preview. Większość akcji po renderze przywraca fokus środkowej liście.

### Wybór wyniku

- **`j` / `<Down>`**: Następny widoczny element; ruch zawija z końca na początek.
- **`k` / `<Up>`**: Poprzedni widoczny element; ruch zawija z początku na koniec.
- **`gg`**: Pierwszy widoczny element.
- **`G`**: Ostatni widoczny element.
- **`<PageDown>` / `<C-d>`**: Przesuń wybór w dół o połowę wysokości panelu listy, bez zawijania.
- **`<PageUp>` / `<C-u>`**: Przesuń wybór w górę o połowę wysokości panelu listy, bez zawijania.

Help nazywa PageUp/PageDown ruchem o stronę, ale kod v0.3.1 kieruje je do dokładnie tej samej funkcji półstronicowej co `Ctrl-u`/`Ctrl-d`.

### Wybór fasety

- **`h` / `<Left>`**: Poprzednia faseta; cykl zawija.
- **`l` / `<Right>`**: Następna faseta; cykl zawija.
- **`<Tab>`**: Następna faseta.
- **`<S-Tab>`**: Poprzednia faseta.

Kolejność cyklu to `All`, `Calls`, `Refs`, `Tests`, `Git`, `Trail`, `Saved`. W ramach jednego otwarcia Wayfinder zapamiętuje ostatni element każdej fasety i próbuje go odtworzyć po powrocie. Nowe otwarcie zaczyna z czystą pamięcią wyborów.

### Otwieranie i Explore

- **`<CR>`**: Zwykły jump `edit`; na rekordzie `Saved` zamiast tego załaduj zapis.
- **`e`**: Eksploruj symbol/lokalizację wybranego wiersza bez zamykania pickera.
- **`b`**: Poprzedni cel historii Explore.
- **`f`**: Następny cel historii Explore.
- **`s`**: Otwórz wybraną lokalizację przez `:split`.
- **`v`**: Otwórz wybraną lokalizację przez `:vsplit`.
- **`t`**: Otwórz wybraną lokalizację przez `:tabedit`.

### Trail i zapis

- **`p`**: Przypnij wybrany wiersz do roboczego Trail.
- **`a`**: Dodaj bieżący cel Wayfindera do roboczego Trail.
- **`A`**: Dodaj całą dotychczasową ścieżkę Explore, od celu początkowego do bieżącego.
- **`P`**: Przejdź bezpośrednio do fasety `Trail`.
- **`S`**: Otwórz menu zapisu i zarządzania Trail.
- **`[`**: Załaduj poprzedni nazwany Trail bieżącego projektu.
- **`]`**: Załaduj następny nazwany Trail bieżącego projektu.
- **`dd`**: Usuń wskazany element, ale tylko w fasecie `Trail`.
- **`da`**: Wyczyść cały roboczy Trail bez promptu potwierdzenia, niezależnie od aktualnej fasety.

### Filtr, prezentacja i cykl życia

- **`/`**: Otwórz `vim.ui.input` z lokalnym filtrem.
- **`<C-l>`**: Wyczyść aktywny filtr i wróć do pierwszego wyniku.
- **`D`**: Przełącz dodatkowe szczegóły oraz dokładny cel `e` wybranego wiersza.
- **`?`**: Pokaż lub ukryj dwa dolne wiersze podpowiedzi.
- **`x`**: Utwórz nową listę quickfix z lokalizacji aktualnie widocznej fasety.
- **`r`**: Anuluj bieżące zbieranie, wyczyść pamięciowy cache źródeł i spróbuj otworzyć sesję ponownie.
- **`q`**: Zamknij cały Wayfinder i wróć fokusem do okna źródłowego.

Nie ma domyślnego mapowania `Esc`. Wykonanie `:q` w dowolnym z trzech buforów wywołuje `BufWinLeave` i także zamyka cały zestaw okien.

### Mysz

- **`<LeftMouse>`**: W railu wybierz fasetę, na liście wybierz rekord, w preview wróć do listy.
- **`<2-LeftMouse>`**: Najpierw wykonaj wybór spod kursora, potem akcję jump. Dwuklik w railu może więc zmienić fasetę i od razu otworzyć jej bieżący rekord.
- **`<ScrollWheelDown>`**: Następny element z zawijaniem.
- **`<ScrollWheelUp>`**: Poprzedni element z zawijaniem.

## Filtr lokalny

Filtr nie uruchamia nowego wyszukiwania. Przesiewa rekordy już zebrane w bieżącej sesji i fasecie. Dopasowanie jest nieczułe na wielkość liter i sprawdza łącznie `label`, `secondary`, `reason` oraz `detail`.

- **`user`**: Wymaga podciągu `user`.
- **`user test`**: Wymaga jednocześnie `user` i `test`; dodatnie termy mają semantykę AND.
- **`user !spec`**: Wymaga `user` i odrzuca każdy rekord zawierający `spec`.
- **`"user service"`**: Wymaga dokładnego, wielowyrazowego podciągu `user service`.
- **`!"git status"`**: Odrzuca dokładną frazę `git status`.
- **`create "user service" !generated`**: Łączy dowolną liczbę dodatnich termów i negacji.

Cudzysłowy nie obsługują escapowania. Niedomknięty cudzysłów traktuje całą resztę jako frazę. Filtr jest wspólny dla faset w danym otwarciu, lecz nowe `e` tworzy nową sesję z pustym filtrem. Liczniki raila pozostają licznikami niefiltrowanych danych, natomiast górne `N results` i eksport `x` dotyczą widocznego wyniku po filtrze.

## Explore i historia

`e` jest pivotem, nie skokiem:

1. Wayfinder rozwiązuje cel wybranego wiersza i pokazuje go na górnym pasku jeszcze przed akcją.
2. Bieżący cel trafia na stos `back`.
3. Stos `forward` jest czyszczony.
4. Stare requesty są anulowane lub oznaczane jako nieaktualne.
5. Picker pozostaje otwarty, a wszystkie źródła zbierają dane dla nowej lokalizacji.

`b` przenosi bieżący cel na `forward` i wraca do ostatniego `back`. `f` wykonuje operację odwrotną. Górny pasek może pokazywać `Back N`, `Back N  Forward N` albo `Original`. Nowe `<leader>Wf` nie dziedziczy tej historii.

`e` nie działa dla:

- wierszy Git, bo opisują historię pliku;
- wierszy stanu;
- brakujących plików;
- rekordów bez ścieżki, w tym wierszy `Saved`.

Historia Explore nie zapisuje się, nie zmienia Trail i nie przeżywa zamknięcia pickera. `A` może skopiować do Trail stos `back` oraz bieżący cel, ale nie kopiuje odgałęzienia pozostającego na `forward`.

## Jump, split, tab i tagstack

`Enter`, `s`, `v` i `t` sprawdzają istnienie ścieżki przed zamknięciem UI. Po poprawnym otwarciu ustawiają kursor na zapisanej linii i kolumnie.

- **`Enter`**: zamyka picker, wraca do okna źródłowego, dopisuje jego pozycję do tagstack i wykonuje `edit`; `<C-t>` może wrócić do miejsca sprzed jumpa.
- **`s`**: zamyka picker i tworzy poziomy split; nie dopisuje tagstack.
- **`v`**: zamyka picker i tworzy pionowy split; nie dopisuje tagstack.
- **`t`**: zamyka picker i otwiera kartę; nie dopisuje tagstack.
- **`<leader>Wn` / `<leader>Wp` / `<leader>Wo`**: otwierają przez `edit` poza UI, lecz również nie dopisują tagstack.

Tagstack dotyczy więc zwykłego jumpa z pickera, nie każdej operacji nawigacyjnej Wayfindera. Dla brakującego pliku akcja pozostawia picker otwarty i nie tworzy pustego bufora.

## Roboczy Trail

Roboczy Trail jest listą Lua w pamięci procesu Neovim:

- przeżywa zamknięcie i ponowne otwarcie pickera w tej samej instancji;
- nie przeżywa restartu bez jawnego zapisu i późniejszego load/resume;
- nie jest sam w sobie ograniczony do projektu;
- może pozostać w pamięci po przejściu do innego repo;
- nowy `<leader>Wf` nie czyści go i nie ładuje automatycznie zapisu.

Ta globalność oznacza, że przed zapisaniem Trail w innym projekcie trzeba sprawdzić jego zawartość. Nazwany zapis otrzyma wszystkie aktualne elementy robocze, także pochodzące z innego repo.

### `p`, `a` i `A`

- **`p`** kopiuje dokładnie wybrany rekord źródła. Zachowuje jego typ i metadata, więc można przypiąć także wiersz Git. Deduplikacja używa `id` rekordu.
- **`a`** tworzy jawny rekord `TARGET` dla aktualnego celu sesji, niezależnie od wybranego wiersza. Wymaga istniejącego pliku.
- **`A`** tworzy rekordy `TARGET` dla całej drogi od oryginalnego celu przez historię `back` do bieżącego celu.
- **`a` i `A`** deduplikują także po dokładnej trójce ścieżka, linia, kolumna.
- **`p`, `a` i `A`** nie przełączają automatycznie do `Trail` i nie zapisują na dysk.

Po przypięciu kursor roboczego Trail wskazuje najnowszy element. `P` tylko otwiera fasetę. `dd` usuwa pojedynczy wiersz, `da` czyści całość bez potwierdzenia. Każda mutacja oznacza dołączony zapis jako `modified`, ale nie nadpisuje go automatycznie.

Zewnętrzne przechodzenie:

- `<leader>Wo` otwiera aktualny poprawny wpis; jeśli aktualny zniknął, szuka dalej;
- `<leader>Wn` zaczyna od pozycji za kursorem i zawija;
- `<leader>Wp` zaczyna od pozycji przed kursorem i zawija;
- brakujące wpisy są pomijane;
- jeżeli wszystkie są brakujące, komunikat odróżnia `Trail has no valid entries` od pustego Trail.

## Nazwane Traile

Nazwane Traile są jawnie utrwalane per rozpoznany `project_root`. Nie są per branch i nie są per `scope.mode = "package"`. Model danych przewiduje pole `branch`, ale v0.3.1 go nie ustawia ani nie wykorzystuje.

### Menu `S`

Menu zawiera dokładnie:

- `Browse Saved Trails`;
- `Save Trail`;
- `Save Trail As`;
- `Resume Last Trail`;
- `Load Trail`;
- `Rename Trail`;
- `Delete Trail`.

Picker jest tymczasowo zamykany na czas `vim.ui.select` lub `vim.ui.input`, aby prompt nie znalazł się za floatami, a potem odtwarzany. Anulowanie promptu nie zmienia danych.

### Save i Save As

- `Save Trail` nadpisuje bez dodatkowego potwierdzenia aktualnie dołączoną nazwę w tym samym projekcie.
- Jeżeli nie ma dołączonej nazwy dla tego projektu, `Save Trail` przechodzi do `Save Trail As`.
- `Save Trail As` przycina białe znaki nazwy i odrzuca pustą nazwę.
- Istniejąca obca nazwa wymaga wyboru `Overwrite`; anulowanie pozostawia stary zapis.
- Zapis pustego roboczego Trail jest odrzucany.
- Udany zapis staje się `last_active`, dołącza roboczy Trail do nazwy i czyści marker `modified`.
- Jeżeli dołączony Trail został wyczyszczony przez `da`, `Save Trail` nie zapisze pustej wersji; poprzedni snapshot na dysku pozostaje.

### Load, Resume i `Saved`

- `Load Trail` wybiera alfabetycznie nazwę i zastępuje cały roboczy Trail jej elementami.
- `Resume Last Trail` ładuje nazwę zapisaną jako `last_active` dla bieżącego projektu.
- `Enter` w fasecie `Saved` wykonuje load wybranego wiersza i przechodzi do `Trail`.
- Load zachowuje kolejność, ustawia kursor na pierwszy element, dołącza nazwę i oznacza listę jako czystą.
- Zwykłe `:Wayfinder`, `<leader>Wf` i `<leader>Ws` nigdy automatycznie nie wykonują resume.

Po restarcie typowy powrót do pracy to `:WayfinderTrailResume`, następnie `<leader>Ws` albo od razu `<leader>Wo`. Samo `<leader>Ws` po restarcie pokaże pusty roboczy Trail, jeżeli wcześniej nie wykonano resume/load.

### Cykl `[` i `]`

Nazwy są sortowane alfabetycznie i cykl zawija:

- `]` bez aktywnej nazwy ładuje pierwszy zapis;
- `[` bez aktywnej nazwy ładuje ostatni zapis;
- przy aktywnej nazwie oba przechodzą względnie do niej;
- każda zmiana zastępuje roboczy Trail, ustawia wybraną nazwę jako `last_active` i może odrzucić niezapisane modyfikacje poprzedniego roboczego Trail bez osobnego promptu.

Przed `[`/`]`, load albo resume zapisz potrzebny stan przez `S`, jeżeli górny pasek pokazuje `modified` lub `unsaved`.

### Rename i Delete

- `Rename Trail` najpierw wybiera zapis, potem pyta o nową nazwę.
- Rename tej samej nazwy jest no-opem; kolizja z inną nazwą jest odrzucana bez overwrite.
- Rename aktualizuje `last_active` i aktywne dołączenie roboczego Trail.
- `Delete Trail` usuwa po samym wyborze z listy, bez drugiego promptu potwierdzenia.
- Usunięcie nieaktywnego zapisu nie zmienia roboczego Trail.
- Usunięcie aktywnego zapisu odłącza nazwę, ale zachowuje elementy robocze jako niezapisany Trail.
- `dd` w fasecie `Saved` niczego nie usuwa i kieruje do menu `S`.

### Pasek stanu Trail

Przykładowe rzeczywiste stany v0.3.1:

- `Trail (2 saved)`;
- `Trail (2 saved)  •  unsaved`;
- `Trail (3 saved): auth bug`;
- `Trail (3 saved): auth bug  •  modified`.

`unsaved` oznacza roboczą listę bez dołączonej nazwy dla bieżącego projektu. `modified` oznacza mutację po save/load. Te flagi są stanem pamięciowym, nie porównaniem JSON bajt po bajcie.

## Przechowywanie

Root zapisu to:

```text
stdpath("state")/wayfinder/trails/
```

Plik projektu ma nazwę:

```text
sha256(normalized_project_root).json
```

Jeden JSON zawiera znormalizowany root, `last_active` i mapę `trails`. Każdy zapis ma nazwę, uporządkowane `items`, `created_at` i `updated_at`. Domyślne `branch = nil` nie serializuje się jako klucz; jeżeli obcy/starszy plik ma niepuste `branch`, loader je zachowa, lecz żadna operacja v0.3.1 nie użyje go do rozdzielenia Trail.

Z elementu utrwalane są pola `id`, `path`, `lnum`, `col`, `label`, `secondary`, `detail`, `facet`, `kind`, `source`, `reason`, `badge`, `preview_range` oraz metadata Git `hash`, `relative`, `repo_root`. Pola czysto renderujące, takie jak `score`, `icon`, `group` i `pinned`, są usuwane i odbudowywane po load.

Wpisy tworzone przez zwykłe źródła i akcje UI mają zazwyczaj znormalizowane ścieżki absolutne. Warstwa storage kopiuje jednak pole `path`, zamiast ponownie je normalizować lub zamieniać na ścieżkę względną. Przeniesienie repozytorium zmienia hash projektu i może pozostawić stary plik storage oraz nieaktualne ścieżki. Wtyczka nie wykonuje migracji, rename detection ani aktualizacji ścieżek.

v0.3.1 zapisuje atomowo:

1. Tworzy plik tymczasowy obok docelowego.
2. Zapisuje całą treść.
3. Wykonuje `fsync`.
4. Zamyka plik.
5. Zastępuje docelowy przez rename.

Jeżeli którykolwiek krok zawiedzie, plik tymczasowy jest usuwany, a ostatni poprawny JSON pozostaje. Odczyt ma cache według rozmiaru i mtime pliku. Niepoprawny JSON daje błąd `Saved Trail storage is invalid`; wtyczka nie próbuje go automatycznie naprawić ani nadpisać pustym stanem.

## Brakujące pliki

Semantyka v0.3.1 jest celowo zachowawcza:

- zapisany Trail pokazuje liczbę `N missing`;
- preview zapisu oznacza każdy wpis `[MISSING]`;
- load zachowuje brakujące rekordy zamiast cicho zmieniać snapshot;
- roboczy `Trail` pokazuje brakującą ścieżkę i badge `[MISSING]`;
- preview brakującego wpisu mówi `File is no longer available`;
- `Enter`, `s`, `v` i `t` nie zamykają pickera i nie tworzą pustego bufora;
- `e` odmawia pivotu;
- `<leader>Wo`, `<leader>Wn` i `<leader>Wp` pomijają brakujące wpisy;
- oba eksporty quickfix pomijają brakujące lokalizacje;
- nic nie usuwa brakującego wpisu automatycznie.

Kontrolowane czyszczenie:

1. Załaduj nazwany Trail.
2. Otwórz `Trail` przez `<leader>Ws` albo `P`.
3. Ustaw się na `[MISSING]` i użyj `dd`.
4. Powtórz dla wszystkich nieaktualnych pozycji.
5. Użyj `S` i `Save Trail`, aby jawnie nadpisać snapshot.

Jeżeli plik później wróci pod dokładnie tę samą ścieżkę, rekord znów stanie się poprawny. Brak jest sprawdzany przez `fs_stat`, nie przez Git ani zawartość.

## Quickfix

### Aktualna faseta

`x` i `:WayfinderExportQuickfix` wywołują `setqflist()` z akcją spacji, czyli tworzą nową listę quickfix, ustawiają ją jako bieżącą i pozostawiają poprzednie listy w stosie quickfix. Obejmuje to rekordy aktualnie widocznej fasety, w aktualnej kolejności, także po filtrze `All` lub dowolnej innej fasety. Tytuł ma postać `Wayfinder refs`, `Wayfinder tests` i podobnie; do starszej listy można wrócić przez `:colder`, a potem przez `:cnewer`.

- Wpis zawiera filename, linię, kolumnę, badge i etykietę.
- Wpis Git dopisuje hash i względny czas z `detail`.
- Wiersze stanu, rekordy `Saved` i brakujące ścieżki nie trafiają do quickfix.
- Eksport pustej bieżącej fasety nadal tworzy nową, pustą listę w stosie i zgłasza `0 item(s)`.
- Eksport nie wykonuje automatycznie `:copen`.
- Polecenie wymaga otwartego Wayfindera; bez sesji zgłasza `Wayfinder is not open`.

### Cały Trail

`:WayfinderExportTrailQuickfix` działa także poza UI. Eksportuje poprawne elementy w bazowej kolejności roboczego Trail, nie w wizualnym porządku grup fasety. Brakujące wpisy pomija.

Pusty Trail daje `Trail is empty`. Trail zawierający wyłącznie brakujące wpisy daje `Trail has no valid entries`. W obu przypadkach funkcja kończy się przed `setqflist()`, więc nie tworzy pustej listy, nie zmienia bieżącej listy i pozostawia cały stos quickfix bez zmian. To różni nieudany eksport całego Trail od eksportu pustej aktualnej fasety.

## Zakres wyszukiwania

Aktywny lokalnie default to `scope.mode = "project"`.

- **`project`**: root rozpoznanego projektu albo CWD jako fallback.
- **`cwd`**: dokładne bieżące `vim.uv.cwd()` Neovim.
- **`package`**: najbliższy marker pakietu/modułu, z fallbackiem do project root, potem CWD.
- **`file_dir`**: katalog bieżącego pliku, a bez ścieżki CWD.

Project root jest szukany w górę od katalogu pliku do katalogu domowego po markerach `.git`, `package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `setup.py`. „Project” nie musi więc oznaczać wyłącznie top-level Git; bliższy marker projektu może wyznaczyć root.

Domyślne `scope.package_markers` to `package.json`, `tsconfig.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `.git`. Można je zastąpić, nie rozszerzyć automatycznie, podając własną listę.

Scope bezpośrednio ogranicza `rg`, kandydatów testów i semantyczne referencje. Git nadal pyta o historię jednego bieżącego pliku. Definicje i incoming callers mogą wyjść poza root. Zapisane Traile używają `project_root`, a nie `scope.root`, więc zmiana na `package` nie tworzy automatycznie osobnego storage dla pakietu.

## Presety wydajności

Preset jest nakładany na defaulty przed indywidualnym `opts`, więc jawne wartości `limits` mają pierwszeństwo.

### `fast`

- `refs`: `max_results = 120`, `timeout_ms = 800`.
- `text`: `max_results = 60`, `timeout_ms = 450`.
- `tests`: `max_results = 30`, `timeout_ms = 450`.
- `git`: `max_commits = 8`, `timeout_ms = 250`.

### `balanced`

- `refs`: `max_results = 200`, `timeout_ms = 1200`.
- `text`: `max_results = 100`, `timeout_ms = 800`.
- `tests`: `max_results = 50`, `timeout_ms = 700`.
- `git`: `max_commits = 15`, `timeout_ms = 400`.

### `full`

- `refs`: `max_results = 400`, `timeout_ms = 2000`.
- `text`: `max_results = 200`, `timeout_ms = 1600`.
- `tests`: `max_results = 100`, `timeout_ms = 1200`.
- `git`: `max_commits = 25`, `timeout_ms = 900`.

`limits.text.enabled = true` i `limits.git.enabled = true` są dziedziczone przez wszystkie presety, chyba że użytkownik jawnie je wyłączy.

Nazwy presetów i scope nie są walidowane. Nieznane `performance` pobierze limity `balanced`, choć samo pole zachowa podany tekst; nieznane `scope.mode` zachowa etykietę, ale rozwiąże root ścieżką fallbacku używaną dla `project`.

Znaczenie limitów:

- **`limits.refs.max_results`**: limit scalonych referencji semantycznych; nie ogranicza osobno definitions/callers.
- **`limits.refs.timeout_ms`**: wspólny deadline kolektora definicji, referencji i incoming callers.
- **`limits.text.enabled`**: włącza lub wyłącza `rg` w `Refs`.
- **`limits.text.max_results`**: maksymalna liczba tekstowych dopasowań.
- **`limits.text.timeout_ms`**: deadline joba `rg`.
- **`limits.tests.max_results`**: maksymalna liczba wynikowych plików testowych.
- **`limits.tests.timeout_ms`**: timeout `git ls-files`; nie ogranicza czasowo fallbacku `vim.fs.find`.
- **`limits.git.enabled`**: włącza lub wyłącza fasetę Git jako źródło.
- **`limits.git.max_commits`**: argument `git log -n`.
- **`limits.git.timeout_ms`**: timeout każdego z etapów `rev-parse` i `log`.

## Pełna konfiguracja

Poniższy blok jest referencją upstreamowych pól v0.3.1, nie sugestią zmiany aktywnej konfiguracji lokalnej:

```lua
require("wayfinder").setup({
  cache_ttl_ms = 2000,
  preview_debounce_ms = 40,
  performance = "balanced",
  scope = {
    mode = "project",
    package_markers = {
      "package.json",
      "tsconfig.json",
      "pyproject.toml",
      "go.mod",
      "Cargo.toml",
      ".git",
    },
  },
  limits = {
    refs = {
      max_results = 200,
      timeout_ms = 1200,
    },
    text = {
      enabled = true,
      max_results = 100,
      timeout_ms = 800,
    },
    tests = {
      max_results = 50,
      timeout_ms = 700,
    },
    git = {
      enabled = true,
      max_commits = 15,
      timeout_ms = 400,
    },
  },
  git_commit_limit = 10,
  max_results_per_facet = 80,
  icons = {
    all = "•",
    calls = "↗",
    refs = "⌕",
    tests = "✓",
    git = "⎇",
    trail = "→",
    definition = "D",
    caller = "C",
    reference = "R",
    test = "T",
    commit = "G",
    pinned = "+",
  },
  layout = {
    width = 0.88,
    height = 0.72,
    border = "rounded",
    title = " Wayfinder ",
    facet_width = 16,
    list_width = 39,
    show_hints = true,
  },
})
```

### Cache

- **`cache_ttl_ms = 2000`**: pamięciowy cache wyniku każdego źródła przez 2 sekundy.
- Klucz obejmuje źródło, ścieżkę, filetype, symbol, pozycję oraz tryb/root scope.
- Cache nie jest zapisywany na dysku i nie ma limitu liczby wpisów ani okresowego sweepa; przeterminowany rekord znika przy następnym odczycie.
- Nowy cel `e` zwykle ma inny klucz, a powrót `b` może jeszcze trafić w cache.
- `r` czyści cały cache źródeł bieżącej instancji.
- Cache storage zapisanych Trail jest osobny i unieważnia się przez sygnaturę size/mtime JSON-u.

`preview_debounce_ms = 40` jest zadeklarowane w konfiguracji, lecz funkcja debounce w v0.3.1 przechwytuje wartość podczas ładowania modułu `layout`. Późniejsze ponowne `setup()` nie przebudowuje już tego timera. Lokalny default 40 działa zgodnie z oczekiwaniem; nie należy zakładać, że runtime'owa zmiana pola od razu zmieni opóźnienie.

### Layout

- **`width` / `height`**: ułamki rozmiaru całego edytora, domyślnie 88% i 72%.
- **`border`**: obramowanie zewnętrznego floata.
- **`title`**: wyśrodkowany tytuł ramki.
- **`facet_width`**: skonfigurowany górny limit raila; algorytm adaptacyjny celuje co najmniej w 12 kolumn przy domyślnej wartości.
- **`list_width`**: skonfigurowany górny limit listy; algorytm adaptacyjny celuje co najmniej w 24 kolumny przy domyślnej wartości.
- Preview dostaje resztę i wymaga co najmniej 18 kolumn.
- Body wymaga co najmniej 4 wierszy.
- Wewnętrzne panele wymuszają `border = "none"`, aby globalne `winborder` nie tworzyło ramek w ramce.
- **`show_hints`** ustala początkową widoczność stopki; `?` mutuje tę wartość w pamięci.
- Zbyt mały edytor daje ostrzeżenie z bieżącym i przybliżonym wymaganym rozmiarem, po czym otwarcie kończy się bez częściowego UI.

Konfiguracja nie waliduje zakresów. Ręczne `facet_width < 12`, `list_width < 24`, niepoprawny ułamek albo nieobsługiwany border może ominąć założenia adaptacji i wywołać błąd Neovim.

### Ikony

- `all`, `calls`, `refs`, `tests`, `git`, `trail` sterują ikonami raila.
- `Saved` używa tej samej ikony `trail`; nie ma osobnego pola `saved`.
- `definition`, `caller`, `reference` są używane w wierszach LSP.
- Dopasowanie `rg` używa `icons.refs`.
- Wiersz testowy używa `icons.tests`, a wiersz Git `icons.git`.
- `pinned` jest markerem w drugim wierszu rekordu już obecnego w Trail.
- Pola `icons.test` i `icons.commit` są obecne w defaultach, ale kod v0.3.1 ich nie odczytuje.
- `↳` dla kolejnych elementów grupy Trail, `·` wiersza stanu i tekstowe badge'e `[LSP]`, `[TXT]`, `[TEST]`, `[GIT]`, `[MISSING]` są hardcoded.

### Highlights

`setup()` definiuje 19 grup jako linki z `default = true`, więc istniejące definicje użytkownika nie są nadpisywane:

- `WayfinderNormal` → `NormalFloat`.
- `WayfinderBorder`, `WayfinderTitle`, `WayfinderFacet`, `WayfinderHeader`, `WayfinderPath`, `WayfinderDim` → `Comment`.
- `WayfinderFacetActive` → `Identifier`.
- `WayfinderCount`, `WayfinderLabelSoft`, `WayfinderBadgeText` → `LineNr`.
- `WayfinderLabel` → `Normal`.
- `WayfinderBadgeLsp` → `Function`.
- `WayfinderBadgeTest` → `String`.
- `WayfinderBadgeGit` → `DiffChange`.
- `WayfinderPreviewContext` → `CursorLine`.
- `WayfinderPreviewTarget` → `Search`.
- `WayfinderTrail` → `DiffAdd`.
- `WayfinderMissing` → `DiagnosticWarn`.

Pięć grup zaznaczenia także powstaje z `default = true`, ale z konkretnymi atrybutami wyliczonymi z aktywnego colorscheme:

- `WayfinderSelection`: tło kolejno z `PmenuSel`, `CursorLine` albo `Visual`.
- `WayfinderSelectionAccent`: to samo tło i kolor tekstu z `DiffAdd` albo `Identifier`.
- `WayfinderSelectionLabel`: to samo tło, kolor `Normal` i bold.
- `WayfinderSelectionPath`: to samo tło i kolor `Comment` albo `Normal`.
- `WayfinderSelectionMuted`: to samo tło i kolor `Comment` albo `Normal`.

Wszystkie 24 grupy można nadpisać przez `vim.api.nvim_set_hl()` po colorscheme. `WayfinderLabelSoft` jest zdefiniowane, ale żaden renderer przypiętej rewizji go nie używa. **Źródło:** [implementacja highlightów v0.3.1](https://github.com/error311/wayfinder.nvim/blob/2ce480d35626ddb533ba594fa7ca865d61184ec6/lua/wayfinder/highlights.lua).

### Pola zgodnościowe

`git_commit_limit` i `max_results_per_facet` są starszymi polami zgodnościowymi. Ich wartości widoczne w tabeli defaultów nie zastępują presetów same z siebie, bo adapter zgodności reaguje tylko wtedy, gdy pole zostało jawnie przekazane w `opts`.

- Jawne `git_commit_limit` ustawia `limits.git.max_commits`, chyba że podano już zagnieżdżoną wartość.
- Jawne `max_results_per_facet` ustawia `refs.max_results` i `text.max_results`.
- Dla testów ustawia minimum z tej wartości i limitu wybranego presetu.
- Nie ogranicza definitions, callers ani Git.
- Nowa konfiguracja powinna używać `limits.*`, bo ich semantyka jest jednoznaczna.

## Polecenia Ex

W lokalnej specyfikacji każde z poniższych poleceń jest osobnym wyzwalaczem Lazy. Polecenia nie przyjmują argumentów ani `!`.

- **`:Wayfinder`**: Otwórz picker dla bieżącego symbolu/pliku.
- **`:WayfinderExportQuickfix`**: Eksportuj widoczną fasetę otwartego pickera.
- **`:WayfinderExportTrailQuickfix`**: Eksportuj poprawne elementy całego roboczego Trail.
- **`:WayfinderTrailNext`**: Otwórz następny poprawny element Trail.
- **`:WayfinderTrailPrev`**: Otwórz poprzedni poprawny element Trail.
- **`:WayfinderTrailOpen`**: Otwórz bieżący poprawny element Trail.
- **`:WayfinderTrailShow`**: Otwórz picker na fasecie `Trail`; jeśli UI już istnieje, tylko przełącz fasetę.
- **`:WayfinderTrailSave`**: Zapisz pod aktywną nazwą albo przejdź do promptu Save As.
- **`:WayfinderTrailSaveAs`**: Zapytaj o inną nazwę i obsłuż ewentualny overwrite.
- **`:WayfinderTrailLoad`**: Wybierz i załaduj nazwany Trail bieżącego projektu.
- **`:WayfinderTrailResume`**: Załaduj `last_active` bieżącego projektu.
- **`:WayfinderTrailDelete`**: Wybierz i usuń nazwany Trail.
- **`:WayfinderTrailRename`**: Wybierz i przemianuj nazwany Trail.

Nie ma publicznego `:WayfinderTrailClear`. Całość czyści `da` wewnątrz UI. Nie ma też polecenia Ex dla fasety `Saved`; otwiera ją cykl faset albo `Browse Saved Trails` z menu `S`.

Otwarcie nowego UI przez `:WayfinderTrailShow` lub `<leader>Ws` ustawia początkową fasetę `Trail`, ale nadal uruchamia w tle wszystkie trzy kolektory dla bieżącego celu. Nie jest to lekki, osobny viewer pozbawiony LSP/test/Git.

## Interfejs `<Plug>`

Upstream rejestruje tylko pięć celów, wszystkie w trybie Normal. Są dostępne po załadowaniu pluginu jako **Opcjonalne upstream**, ale lokalna konfiguracja ich nie używa:

- **`<Plug>(WayfinderOpen)`**: odpowiednik `:Wayfinder`.
- **`<Plug>(WayfinderTrailNext)`**: odpowiednik `:WayfinderTrailNext`.
- **`<Plug>(WayfinderTrailPrev)`**: odpowiednik `:WayfinderTrailPrev`.
- **`<Plug>(WayfinderTrailOpen)`**: odpowiednik `:WayfinderTrailOpen`.
- **`<Plug>(WayfinderTrailShow)`**: odpowiednik `:WayfinderTrailShow`.

Lokalne `<leader>Wf/Wn/Wp/Wo/Ws` wywołują bezpośrednio odpowiadające polecenia Ex, a nie powyższe cele `<Plug>`. Upstream nie przypisuje sam z siebie globalnych klawiszy użytkownika. Nie istnieją `<Plug>` dla save, load, resume, rename, delete ani quickfix; dla nich publicznym interfejsem są polecenia Ex i akcje pickera.

## Workflow: śledzenie symbolu

1. Zapisz bufor i ustaw kursor wewnątrz nazwy symbolu.
2. Naciśnij `<leader>Wf`; sprawdź na górze `Symbol • nazwa` i root w `:checkhealth`, jeżeli wyniki wyglądają zbyt szeroko.
3. W `Calls` obejrzyj `[LSP]` definicje i incoming callers.
4. Przejdź `l` albo `<Tab>` do `Refs`; odróżnij semantyczne `[LSP]` od leksykalnych `[TXT]`.
5. Użyj `D`, aby zobaczyć dokładną lokalizację celu, i potwierdź kod w preview.
6. Naciśnij `e` na właściwym wierszu, aby zmienić temat bez skoku.
7. Użyj `b`/`f`, aby porównać poprzedni i następny temat.
8. Przypnij wybrane dowody przez `p`, bieżący temat przez `a` albo całą drogę przez `A`.
9. Naciśnij `P`, przejrzyj Trail i wykonaj `Enter` na docelowym rekordzie.
10. Po zwykłym jumpie użyj `<C-t>`, aby wrócić do miejsca sprzed Wayfindera.

## Workflow: praca bez LSP

1. Ustaw kursor na jednoznacznym słowie symbolu i otwórz `<leader>Wf`.
2. `Calls unavailable` jest oczekiwane bez klienta, nie oznacza awarii całej wtyczki.
3. Otwórz `Refs`; `[TXT]` pochodzi z `rg --fixed-strings --word-regexp` i wymaga ręcznej oceny.
4. Użyj `/ "nazwa symbolu" !generated`, aby odsiać oczywisty szum już zebranych rekordów.
5. Sprawdź `Tests`, pamiętając, że są heurystyką nazw i pierwszych 250 linii.
6. Sprawdź `Git`, aby poznać ostatnie commity pliku, ale do patcha użyj osobnego narzędzia Git.

## Workflow: zapis ścieżki

1. Zbuduj roboczy Trail przez `p`, `a` i `A`.
2. Otwórz `P` i sprawdź kolejność oraz ewentualne `[MISSING]`.
3. Naciśnij `S`, wybierz `Save Trail As` i nadaj nazwę opisującą zadanie, nie branch.
4. Po kolejnych zmianach sprawdź `modified` i użyj `S` → `Save Trail`.
5. W nowej instancji Neovim otwórz plik projektu i wykonaj `:WayfinderTrailResume`.
6. Nawiguj bez pickera przez `<leader>Wo`, `<leader>Wn` i `<leader>Wp` albo otwórz `<leader>Ws`.
7. Przed loadem innej nazwy zapisz potrzebne zmiany; load i `[`/`]` zastępują roboczą listę bez promptu o dirty state.

## Workflow: monorepo

Aktywny lokalnie `balanced` + `project` jest dobrym punktem startowym, ale nie zawsze najlepszym zakresem dla dużego monorepo. Opcjonalna konfiguracja upstream wygląda tak:

```lua
require("wayfinder").setup({
  performance = "fast",
  scope = {
    mode = "package",
  },
})
```

1. Najpierw użyj `:checkhealth wayfinder` i przeczytaj `Resolved scope` oraz `Resolved project root`.
2. Jeżeli marker pakietu jest zły, dopiero wtedy dostosuj `scope.package_markers`.
3. Zmniejsz `limits.text.max_results` dla szerokich słów i `limits.tests.max_results` dla repo z wieloma testami.
4. Pamiętaj, że definitions/callers mogą nadal wyjść poza package scope.
5. Nazwane Traile pozostaną przy `project_root`, nie przy package root.

## Health

Po załadowaniu wtyczki uruchom:

```vim
:checkhealth wayfinder
```

Na całkiem świeżej sesji Lazy health nie musi sam wyzwolić ładowania Wayfindera. Najpierw użyj `<leader>Wf`, dowolnego publicznego polecenia albo `:Lazy load wayfinder.nvim`.

Raport obejmuje:

- wersję Neovim;
- możliwość załadowania modułów pluginu;
- dostępność `rg`;
- dostępność `git`;
- klientów LSP aktywnych dla bieżącego zwykłego bufora albo zwykłego bufora alternatywnego;
- rozwiązany scope i project root;
- root storage zapisanych Trail;
- dokładny plik storage projektu;
- liczbę zapisanych Trail;
- ostatnio aktywną nazwę;
- bieżące `performance` i `scope.mode`.

## Diagnostyka

### Brak polecenia lub mapowania

1. Sprawdź `:Lazy` i stan `wayfinder.nvim`.
2. Użyj `:verbose nmap <leader>Wf` oraz analogicznie dla `<leader>Wn/Wp/Wo/Ws`.
3. Jeżeli diagnozujesz opcjonalny interfejs upstream, po załadowaniu sprawdź `:verbose nmap <Plug>(WayfinderOpen)`; lokalne `<leader>W*` nie zależą od tego mapowania.
4. Sprawdź `:messages` pod kątem błędu modułu albo zbyt małego layoutu.
5. Nie oczekuj małych mapowań z README; lokalne używają wielkiego `W`.

### Puste `Calls` lub `Refs`

1. Sprawdź, czy górny pasek mówi `Symbol`, a nie `File`.
2. Sprawdź klientów przez `:lua =vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients({bufnr=0}))`.
3. Zweryfikuj metody klienta, szczególnie definition, references i call hierarchy.
4. Zapisz bufor, aby LSP i dyskowe etykiety używały zgodnych pozycji.
5. Sprawdź `:echo executable('rg')` i aktywne `limits.text.enabled`.
6. Uruchom ręcznie `rg --fixed-strings --word-regexp 'symbol' .` z rootu pokazanego przez health.
7. Pamiętaj, że krótki timeout może legalnie finalizować częściowy zestaw bez osobnego błędu.

### Brak testów

1. Uruchom `git ls-files -- .` w aktywnym scope i sprawdź, czy test jest śledzony.
2. Porównaj nazwę testu ze stemem pliku źródłowego i symbolu.
3. Sprawdź pierwszych 250 linii pod kątem prostych obsługiwanych wzorców.
4. Nie oczekuj semantyki frameworka, parametrów testu ani analizy importów.
5. Poza Git fallback filesystemu rozpoznaje dokładnie `*.lua`, `*.js`, `*.ts` i `*.tsx`; nie obejmuje między innymi `.jsx`, Pythona, Go ani Rusta.

### Brak Git

1. Sprawdź `:echo executable('git')`.
2. Sprawdź `git rev-parse --show-toplevel` z katalogu scope.
3. Sprawdź `git log -- ścieżka/do/pliku`.
4. Nieśledzony albo nowy plik może poprawnie mieć pustą historię.
5. `Git history did not finish in time` może oznaczać zbyt niski `limits.git.timeout_ms`, nie uszkodzone repo.

### Zły root lub za dużo wyników

1. Odczytaj `Resolved scope` i `Resolved project root` z health.
2. Sprawdź bliższe markery `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `setup.py` i `.git`.
3. Dla monorepo wybierz opcjonalnie `package`; dla bardzo lokalnego przeglądu `file_dir`.
4. Użyj presetu `fast` albo zmniejsz indywidualne limity.
5. Pamiętaj, że scope nie ucina definitions i incoming callers.

### Trail i storage

1. `:checkhealth wayfinder` pokaże plik JSON właściwego projektu.
2. `No recent saved Trail` oznacza brak poprawnego `last_active`, nie brak roboczego Trail w pamięci.
3. `Saved Trail storage is invalid` oznacza niepoprawny JSON; przed ręczną naprawą zrób kopię pliku wskazanego przez health.
4. Po przeniesieniu repo sprawdź nowy hash storage i absolutne ścieżki starych wpisów.
5. Przy `[MISSING]` nie usuwaj całego zapisu z fasety `Saved`; load, `dd`, review i jawny save zachowują kontrolę.
6. Przed `[`/`]`, load lub resume sprawdź `modified`, bo operacja zastępuje roboczy Trail.

### Za małe UI lub nieaktualny preview

1. Zwiększ rozmiar terminala albo ustaw opcjonalnie `layout.show_hints = false`.
2. Sprawdź ostrzeżenie `editor too small` w `:messages`.
3. Zapisz bufor, jeśli preview nie odpowiada tekstowi widzianemu przez LSP.
4. Dla Git pamiętaj, że preview jest historycznym plikiem, ale jump prowadzi do bieżącego worktree.
5. Kwadraty zamiast ikon wynikają z glifów terminala/fontu; można zastąpić używane pola `icons` prostym ASCII.

## Ograniczenia v0.3.1

- Wayfinder nie jest ogólnym fuzzy finderem i nie przyjmuje zapytania startowego.
- Rozpoznawanie symbolu jest leksykalne, a nie składniowe.
- Etykiety i preview czytają dysk, nie niezapisany tekst bufora.
- Incoming callers zależą od call hierarchy i nie obejmują outgoing calls.
- Definitions/callers mogą wyjść poza aktywny scope.
- Surowe kolumny `character` LSP nie są konwertowane per `client.offset_encoding`; znaki nie-ASCII i mieszane klienty UTF-8/UTF-16 mogą przesunąć jump oraz wykrywanie celu `e`.
- Testy są heurystyką nazw i maksymalnie pierwszych 250 linii.
- Git pokazuje treść pliku z rewizji, nie diff i nie historię symbolu.
- Roboczy Trail jest globalny dla instancji Neovim; zapisane Traile są projektowe, ale nie branchowe.
- Brakujące ścieżki nie są relokowane ani usuwane automatycznie.
- Test i Git ignorują spóźnione wyniki, lecz ich procesy nie są aktywnie anulowane przez uchwyt źródła.
- `icons.test` i `icons.commit` są niewykorzystane, a część glifów jest hardcoded.
- `preview_debounce_ms` jest przechwytywane przy ładowaniu modułu layout.
- Akcja `r` w kodzie v0.3.1 wywołuje ponowne `open()` po skupieniu bufora pickera, bez jawnego zachowania pierwotnego targetu. Jeżeli refresh zmieni temat na `wayfinder://...` albo tekst wiersza UI, zamknij `q` i otwórz ponownie `<leader>Wf` z właściwego pliku.

## Źródła przypiętej rewizji

- [README](https://github.com/error311/wayfinder.nvim/blob/2ce480d35626ddb533ba594fa7ca865d61184ec6/README.md)
- [pełny help `wayfinder.txt`](https://github.com/error311/wayfinder.nvim/blob/2ce480d35626ddb533ba594fa7ca865d61184ec6/doc/wayfinder.txt)
- [changelog](https://github.com/error311/wayfinder.nvim/blob/2ce480d35626ddb533ba594fa7ca865d61184ec6/CHANGELOG.md)
- [pełne defaulty i presety konfiguracji](https://github.com/error311/wayfinder.nvim/blob/2ce480d35626ddb533ba594fa7ca865d61184ec6/lua/wayfinder/config.lua)
- [definicje highlightów](https://github.com/error311/wayfinder.nvim/blob/2ce480d35626ddb533ba594fa7ca865d61184ec6/lua/wayfinder/highlights.lua)
- [rejestracja wszystkich poleceń Ex i celów `<Plug>`](https://github.com/error311/wayfinder.nvim/blob/2ce480d35626ddb533ba594fa7ca865d61184ec6/plugin/wayfinder.lua)
- [sesja, agregacja, facety, state rows, cache i mapowania pickera](https://github.com/error311/wayfinder.nvim/blob/2ce480d35626ddb533ba594fa7ca865d61184ec6/lua/wayfinder/init.lua)
- [akcje jump, Explore, Trail, persistence i quickfix](https://github.com/error311/wayfinder.nvim/blob/2ce480d35626ddb533ba594fa7ca865d61184ec6/lua/wayfinder/actions.lua)
- [kolektor LSP i fallback `rg`](https://github.com/error311/wayfinder.nvim/blob/2ce480d35626ddb533ba594fa7ca865d61184ec6/lua/wayfinder/sources/lsp.lua)
- [heurystyka prawdopodobnych testów](https://github.com/error311/wayfinder.nvim/blob/2ce480d35626ddb533ba594fa7ca865d61184ec6/lua/wayfinder/sources/tests.lua)
- [źródło Git](https://github.com/error311/wayfinder.nvim/blob/2ce480d35626ddb533ba594fa7ca865d61184ec6/lua/wayfinder/sources/git.lua)
- [roboczy Trail](https://github.com/error311/wayfinder.nvim/blob/2ce480d35626ddb533ba594fa7ca865d61184ec6/lua/wayfinder/trail.lua)
- [operacje nazwanych Trail](https://github.com/error311/wayfinder.nvim/blob/2ce480d35626ddb533ba594fa7ca865d61184ec6/lua/wayfinder/trail_persistence.lua)
- [format storage i zapis atomowy](https://github.com/error311/wayfinder.nvim/blob/2ce480d35626ddb533ba594fa7ca865d61184ec6/lua/wayfinder/trail_store.lua)
- [layout trzech paneli i paski stanu](https://github.com/error311/wayfinder.nvim/blob/2ce480d35626ddb533ba594fa7ca865d61184ec6/lua/wayfinder/layout.lua)
- [render preview zwykłego, Git, Saved i brakującego pliku](https://github.com/error311/wayfinder.nvim/blob/2ce480d35626ddb533ba594fa7ca865d61184ec6/lua/wayfinder/render/preview.lua)
- [parser filtra](https://github.com/error311/wayfinder.nvim/blob/2ce480d35626ddb533ba594fa7ca865d61184ec6/lua/wayfinder/util/filter.lua)
- [rozwiązywanie scope i project root](https://github.com/error311/wayfinder.nvim/blob/2ce480d35626ddb533ba594fa7ca865d61184ec6/lua/wayfinder/util/scope.lua)
- [healthcheck](https://github.com/error311/wayfinder.nvim/blob/2ce480d35626ddb533ba594fa7ca865d61184ec6/lua/wayfinder/health.lua)
