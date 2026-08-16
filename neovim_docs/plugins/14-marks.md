<a id="plugin-marks"></a>
# Natywne marki Neovim i `marks.nvim`

Marka to nazwana pozycja w tekście. Sam Neovim przechowuje marki i wykonuje skoki; `marks.nvim` dodaje do tego znaki w gutterze, wygodniejsze operacje, cykliczną nawigację, podgląd oraz osobny, ulotny system bookmarków. Opis wtyczki dotyczy dokładnie commita `f353e8c08c50f39e99a9ed474172df7eddd89b72` z 13 maja 2025, a część natywna odpowiada lokalnemu Neovimowi `0.12.4`.

W tym rozdziale obowiązują cztery warstwy:

- **Domyślne Neovim**: działa bez `marks.nvim`; źródłem prawdy jest natywny stan marek.
- **Domyślne wtyczki**: mapowanie albo zachowanie instalowane przez przypięty `marks.nvim`.
- **Aktywne lokalne**: ustawienie lub skrót rzeczywiście przyjęty dla tej konfiguracji.
- **Opcjonalne upstream**: funkcja istnieje w kodzie wtyczki, lecz lokalnie nie ma domyślnego skrótu albo wymaga innej konfiguracji.

## Primer: natywne marki Vim/Neovim

### Mentalny model

Natywna marka zapisuje numer bufora lub pliku, wiersz i kolumnę. Nie jest rejestrem tekstowym, breakpointem, wpisem quickfix ani pozycją jumplisty. Bez wtyczki marka nie ma własnego widocznego znaku; `marks.nvim` tylko wizualizuje i obsługuje stan, który nadal należy do Neovim.

Najważniejszy podział obejmuje marki małoliterowe, wielkoliterowe, numerowane i specjalne:

- **`a`-`z`**: marki lokalne dla bufora/pliku. Każdy bufor może mieć własne `a`, własne `b` i tak dalej. **Stan:** **Domyślne Neovim**.
- **`A`-`Z`**: marki plikowe, nazywane też globalnymi. Istnieje jeden globalny zestaw 26 nazw, a każda pozycja zawiera docelowy plik. **Stan:** **Domyślne Neovim**.
- **`0`-`9`**: historia pozycji zapisana przez ShaDa. Nie ustawia się ich poleceniem `m0`; Neovim tworzy i przesuwa je podczas zapisu ShaDa. **Stan:** **Domyślne Neovim**.
- **marki specjalne**: pozycje aktualizowane automatycznie przez edycję, skoki, Visual, Insert i cykl życia bufora. **Stan:** **Domyślne Neovim**.
- **bookmarki `marks.nvim`**: nienazwane extmarki w grupach `0`-`9`; nie są żadną z powyższych natywnych kategorii. **Stan:** **Domyślne wtyczki**.

### Marki małoliterowe: pozycje w jednym buforze

`ma` ustawia `a` pod kursorem, `mb` ustawia `b`, a kolejne ustawienie tej samej litery przenosi markę. Nazwa jest lokalna dla bieżącego bufora, dlatego `a` w `main.lua` i `a` w `test.lua` mogą istnieć jednocześnie.

- `ma`: ustaw `a` w bieżącej pozycji.
- apostrof + `a`, czyli `'a`: przejdź do pierwszego niebiałego znaku wiersza marki.
- backtick + `a`, czyli `` `a ``: przejdź dokładnie do zapamiętanego wiersza i kolumny.
- `d'a`: usuń wierszowo od kursora do wiersza `a`, ponieważ apostrof jest ruchem linewise.
- `d` oraz backtick + `a`: wykonaj znakowy, dokładny ruch do kolumny marki; natywny ruch backtickiem jest exclusive.
- `]'` / `['`: następna / poprzednia linia zawierająca małoliterową markę, z kursorem na pierwszym niebiałym znaku.
- `]` + backtick / `[` + backtick: następna / poprzednia małoliterowa marka z zachowaniem dokładnej kolumny.

Wstawianie i usuwanie wierszy zwykle przesuwa markę razem z tekstem. Usunięcie wiersza zawierającego małoliterową markę usuwa ją, a undo/redo potrafi ją odtworzyć. W Neovimie `0.12` samo `:bdelete` rozładowuje bufor i usuwa go z listy, ale nie musi całkowicie zniszczyć obiektu bufora ani jego lokalnych marek; ponowne dodanie lub otwarcie niewyczyszczonego bufora może je zachować. Dopiero `:bwipeout` naprawdę unieważnia bufor i wszystkie jego marki. „Lokalna dla bufora” nie oznacza też automatycznie „tylko na jedną sesję”: ShaDa może zapisać małoliterowe marki ostatnio edytowanych plików i wczytać je przy ponownym otwarciu pliku.

### Marki wielkoliterowe: skok między plikami

`mA` ustawia globalną markę `A` wraz z nazwą bieżącego pliku. Apostrof + `A` otwiera właściwy plik i ustawia kursor na pierwszym niebiałym znaku wiersza, a backtick + `A` wraca do dokładnej kolumny. Ponowne `mA` gdziekolwiek przenosi jedyną globalną `A`.

- Wielka litera jest dobra dla trwałych, zapamiętywalnych celów, na przykład `C` dla konfiguracji albo `T` dla testu.
- Skok może przełączyć bufor lub otworzyć plik, ale operator nie może działać przez granicę plików. Wielkoliterowa marka jest ruchem operatora tylko wtedy, gdy cel leży w bieżącym pliku.
- Pozycje `A`-`Z` są przechowywane w ShaDa, jeżeli opcja `'shada'` jest niepusta i jej flaga `f` nie ma wartości `0`.
- `marks.nvim` może pokazać znak wielkoliterowej marki dopiero w buforze, do którego pozycja należy i który został zarejestrowany przez wtyczkę.

### Marki numerowane i specjalne

Marki `0`-`9` są rotującą historią zapisów ShaDa. Podczas wyjścia albo `:wshada` bieżąca pozycja staje się `0`, wcześniejsze `0` przechodzi do `1`, następne do `2` i tak dalej. Apostrof lub backtick z cyfrą może otworzyć zapisany plik. Nie należy mylić ich z grupami bookmarków `m0`-`m9`: domyślne mapowania wtyczki używają cyfr właśnie dla bookmarków, a natywnego `m0` i tak nie można użyć do ustawienia marki numerowanej.

Najpraktyczniejsze marki specjalne:

- **podwójny apostrof / podwójny backtick**: pozycja sprzed ostatniego skoku albo ustawiona przez `m'` lub `m` z backtickiem; apostrof wraca linewise, backtick dokładnie.
- **`'"` / backtick + `"`**: pozycja kursora przy ostatnim opuszczeniu bieżącego bufora; ShaDa może ją zachować.
- **`'^` / backtick + `^`**: pozycja, w której ostatnio zakończono Insert; używa jej także `gi`.
- **`'.` / backtick + `.`**: początek lub okolica ostatniej zmiany; starsze zmiany obsługuje changelist przez `g;` i `g,`.
- **`'[` / `']`**: pierwszy / ostatni wiersz poprzednio zmienionego albo yankowanego tekstu.
- **backtick + `[` / backtick + `]`**: dokładny pierwszy / ostatni znak tego zakresu.
- **`'<` / `'>`**: pierwszy / ostatni wiersz ostatniego zaznaczenia Visual.
- **backtick + `<` / backtick + `>`**: dokładne granice ostatniego zaznaczenia Visual; używa ich też `gv`.
- **`'(`, `')`, `'{`, `'}` i warianty z backtickiem**: dynamiczne granice bieżącego zdania i akapitu; `:marks` ich nie wypisuje.
- **`':`**: początek bieżącego wejścia użytkownika w buforze typu prompt.

Natywne `m{znak}` ustawia przede wszystkim `a`-`z` i `A`-`Z`. Dodatkowe formy `m'`, `m` z backtickiem, `m[`, `m]`, `m<` i `m>` ustawiają odpowiednio kontekst oraz wybrane granice specjalne. W aktywnej integracji domyślne mapowania wtyczki przejmują cały prefiks `m`; `m[` i `m]` oznaczają więc nawigację wtyczki, a nie natywne ręczne ustawienie `'[` i `']`. Gdy ręczne ustawienie tych dwóch specjalnych pozycji jest naprawdę potrzebne, `:normal! m[` i `:normal! m]` omijają mapowania.

### Dokładny backtick kontra wierszowy apostrof

Różnica jest semantyczna, nie tylko wizualna:

- Apostrof + nazwa ustawia kursor na pierwszym niebiałym znaku docelowego wiersza i jest ruchem linewise.
- Backtick + nazwa przywraca dokładny wiersz oraz kolumnę i jest ruchem exclusive.
- Dla znanej marki do precyzyjnej edycji zwykle lepszy jest backtick; apostrof jest wygodny do skoku na początek logicznego wiersza albo jako ruch operatora obejmującego całe wiersze.
- `g'` i `g` z backtickiem wykonują odpowiadający skok bez zmiany jumplisty, gdy cel jest w bieżącym buforze. To przydatne w automatyzacji i częstych skokach kontrolnych.

### `:marks` i `:delmarks`

- `:marks`: wypisz aktualne marki; pierwsza kolumna pozycji ma numer `0`.
- `:marks aB`: pokaż tylko `a` i `B`.
- `:delmarks a`: usuń `a`.
- `:delmarks a b 1`: usuń `a`, `b` i numerowaną `1`.
- `:delmarks p-z`: usuń zakres małoliterowy.
- `:delmarks Aa`: usuń globalną `A` i lokalną `a`.
- `:delmarks ^.[]`: usuń wymienione marki specjalne.
- `:delmarks!`: usuń marki bieżącego bufora poza `A`-`Z` i `0`-`9`, a dodatkowo wyczyść changelist bieżącego bufora.

Poprzedniej marki kontekstu `'` nie można usunąć przez `:delmarks`. Usunięcie marki w pamięci i usunięcie jej starego wpisu z ShaDa to dwie różne operacje; ma to szczególne znaczenie dla globalnych `A`-`Z`.

### ShaDa: co naprawdę przetrwa restart

ShaDa, czyli shared data, jest domyślnie czytana przy starcie i zapisywana przy poprawnym wyjściu. Na Unixie domyślny plik to `$XDG_STATE_HOME/nvim/shada/main.shada`. Przechowuje między innymi historię, rejestry, marki dla ograniczonej liczby plików, globalne marki plikowe, listy skoków i zmian oraz listę starych plików.

- Marki lokalne zapisuje się osobno dla każdego pliku i wczytuje dopiero przy jego otwarciu.
- `:bdelete` nie gwarantuje utraty natywnych marek lokalnych, ponieważ bufor może pozostać poprawnym, nieujętym na liście obiektem. `:bwipeout` unieważnia je wraz z całym buforem.
- Jeżeli bieżące marki mają przetrwać porzucenie albo wyczyszczenie bufora przed normalnym wyjściem, wykonaj świadomie `:wshada`, dopóki bufor i marki jeszcze istnieją. Po `:bwipeout` bieżącego stanu nie ma już czego zapisać; starszy wpis ShaDa może nadal istnieć i później odtworzyć starsze pozycje zależnie od merge, limitów i wykluczeń `'shada'`.
- Marki `[` i `]` nie są zapisywane, natomiast `"` jest.
- `A`-`Z` są wpisami globalnymi, jeżeli pozwala na to flaga `f` opcji `'shada'`.
- `0`-`9` są tworzone i rotowane przy zapisie ShaDa.
- Flaga apostrofu w `'shada'`, na przykład domyślne `'100`, określa liczbę ostatnich plików z lokalnymi markami; wartość niezerowa zapisuje też jumplistę i changelistę.
- Prefiksy `r` w `'shada'` wykluczają ścieżki, lokalnie domyślnie między innymi `/tmp/` i `/private/`.
- `:wshada` scala stan z istniejącym plikiem, a `:wshada!` nie czyta starego pliku przed zapisem i wyłącza część zabezpieczeń.
- Każde `:wshada` resetuje marki `"` i aktualizuje rotację `0`-`9`; zapis nie jest neutralnym „flush”.
- `:rshada` scala odczytany stan, a `:rshada!` może nadpisać już ustawione rejestry, marki i inne dane.

### Marki a jumplista

Jumplista jest chronologiczną historią skoków, a nie zbiorem nazwanych punktów:

- `Ctrl-o`: starsza pozycja w jumpliście.
- `Ctrl-i` albo `Tab`: nowsza pozycja w jumpliście, z zastrzeżeniami terminala i mapowań.
- `:jumps`: pokaż listę bieżącego okna.
- `:clearjumps`: wyczyść listę bieżącego okna.
- Każde okno ma osobną listę, maksymalnie 100 pozycji; nowy split otrzymuje kopię listy.
- Zwykły skok apostrofem lub backtickiem odkłada pozycję źródłową w jumpliście. `g'`, `g` z backtickiem albo `:keepjumps` może temu zapobiec.
- Podwójny apostrof lub podwójny backtick wraca tylko do poprzedniego kontekstu; `Ctrl-o` i `Ctrl-i` przemieszczają się po pełnej historii.
- ShaDa może zachować jumplistę, ale nie zamienia jej w marki. Nazwa marki pozostaje stabilnym zamiarem użytkownika, podczas gdy jumplista jest historią nawigacji.

## Co dodaje `marks.nvim`

**Co robi i po co:** pokazuje natywne marki w signcolumn, automatycznie przydziela litery, usuwa i przełącza marki, przechodzi po nich w kolejności położenia, otwiera podgląd oraz eksportuje pozycje do location list albo quickfix. Dodatkowo utrzymuje własne bookmarki oparte na extmarkach.

**Ładowanie lokalne:** pierwsze użycie dowolnego z 11 stubów poleceń Lazy albo zdarzenie `VeryLazy`, zależnie od tego, co nastąpi wcześniej. Zimne triggery to `MarksToggleSigns`, `MarksListBuf`, `MarksListGlobal`, `MarksListAll`, `MarksQFListBuf`, `MarksQFListGlobal`, `MarksQFListAll`, `BookmarksList`, `BookmarksListAll`, `BookmarksQFList`, `BookmarksQFListAll`. Nazwy stubów są dostępne przed załadowaniem; wywołanie usuwa stub, ładuje wtyczkę i uruchamia właściwe polecenie. Domyślne mapowania pojawiają się dopiero po wykonaniu `setup()` podczas ładowania. Wymaganie upstream to Neovim `0.5+`; lokalne `0.12.4` spełnia je z dużym zapasem.

**Konfiguracja lokalna:** `default_mappings=true`, `builtin_marks={ ".", "<", ">", "^" }`, `signs=true`, `cyclic=true`, `force_write_shada=false`, `refresh_interval=250`. Nie ma lokalnego override `sign_priority`, grup bookmarków ani list wykluczeń, więc te wartości pozostają domyślne upstream.

```lua
require("marks").setup({
  default_mappings = true,
  builtin_marks = { ".", "<", ">", "^" },
  signs = true,
  cyclic = true,
  force_write_shada = false,
  refresh_interval = 250,
})
```

To jest opis przyjętego stanu, nie instrukcja zmiany konfiguracji. `marks.nvim` nie zastępuje natywnych marek własną bazą: ogólny callback `m` przyjmuje litery oraz rozpoznawane znaki specjalne `.`, `^`, apostrof, backtick, `"`, `<`, `>`, `[`, `]` i `0`-`9`, po czym deleguje ustawienie przez natywne `m{znak}`. Dokładne, dłuższe mapowania wtyczki, między innymi `m[`, `m]` i `m0`-`m9`, mają pierwszeństwo przed ogólnym callbackiem. `builtin_marks={ ".", "<", ">", "^" }` jest osobną listą czterech automatycznych marek okresowo odświeżanych z Neovim, a nie listą wszystkich form akceptowanych przez `m` ani wszystkich marek, które mogą pojawić się w cache, znakach i listach.

### Lokalne integracje wokół marek

- **`<leader>ma`**: nadal uruchamia builtin `marks` wtyczki Telescope przez `:Telescope marks`. Picker pokazuje natywne marki Neovim, ale sam nie jest natywną funkcją Neovim ani pickerem dostarczanym przez `marks.nvim`. **Stan:** **Aktywne lokalne**.
- **`J` w Normal**: łączy wiersze i przywraca pozycję kursora bez tymczasowego `mz` i bez skoku do `z`. Marka `z` pozostaje do dyspozycji użytkownika i automatycznego przydziału `m,`. To lokalne mapowanie, nie funkcja upstream `marks.nvim`. **Stan:** **Aktywne lokalne**.
- **signcolumn**: lokalne `signcolumn=yes` utrzymuje jedną widoczną kolumnę znaków; konkurencję z Gitsigns, DAP i innymi providerami rozstrzyga pojemność kolumny oraz priority. **Stan:** **Aktywne lokalne**.

## Wszystkie domyślne mapowania `m*` i `dm*`

Wszystkie poniższe mapowania działają w Normal, są `noremap` i po załadowaniu oraz wykonaniu `setup()` mają stan **Domyślne wtyczki, aktywne lokalnie**. Setup następuje po wyzwoleniu jednym z 11 poleceń albo przez `VeryLazy`. Ogólne mapowanie `m` albo `dm` czeka synchronicznie na następny znak; dłuższe dokładne mapowania, takie jak `m,` czy `dm0`, mają własne akcje.

- **`m{znak}`**, na przykład `mx`: ustaw wskazaną markę i zarejestruj jej znak. Callback akceptuje litery oraz rozpoznawane znaki specjalne wymienione wyżej; dokładne mapowania wtyczki mają pierwszeństwo. Mała litera jest lokalna, wielka globalna. Dla obsługiwanego znaku wtyczka deleguje końcowe ustawienie do natywnego `normal! m{znak}`.
- **`m,`**: ustaw najniższą wolną markę małoliterową w bieżącym buforze, zaczynając od `a`.
- **`m;`**: jeśli w bieżącym wierszu nie ma śledzonej marki, ustaw następną wolną małą literę; jeśli jest co najmniej jedna, usuń wszystkie śledzone natywne marki z tego wiersza. Nie jest to przełączenie bookmarka.
- **`dm{znak}`**, na przykład `dmx`: usuń wskazaną, zarejestrowaną literę albo rozpoznawaną markę specjalną. Dla wielkiej litery operacja działa tylko wtedy, gdy cache bieżącego bufora zawiera tę globalną markę.
- **`dm-`**: usuń wszystkie śledzone natywne marki w bieżącym wierszu. Bookmarki należą do osobnego stanu i pozostają.
- **`dm<Space>`**: wyczyść stan marek bieżącego bufora, usuń jego znaki i wykonaj natywne `:delmarks!`. Skutkiem ubocznym Neovim jest wyczyszczenie changelisty; `A`-`Z` i `0`-`9` nie są trwale kasowane przez samo `:delmarks!`.
- **`m]`**: następna literowa marka w bieżącym buforze według numeru wiersza.
- **`m[`**: poprzednia literowa marka w bieżącym buforze według numeru wiersza.
- **`m:`**: zapytaj o znak marki i otwórz jej podgląd w nowym pływającym oknie.
- **`m0`**: dodaj bookmark grupy `0` w bieżącym wierszu.
- **`m1`**: dodaj bookmark grupy `1` w bieżącym wierszu.
- **`m2`**: dodaj bookmark grupy `2` w bieżącym wierszu.
- **`m3`**: dodaj bookmark grupy `3` w bieżącym wierszu.
- **`m4`**: dodaj bookmark grupy `4` w bieżącym wierszu.
- **`m5`**: dodaj bookmark grupy `5` w bieżącym wierszu.
- **`m6`**: dodaj bookmark grupy `6` w bieżącym wierszu.
- **`m7`**: dodaj bookmark grupy `7` w bieżącym wierszu.
- **`m8`**: dodaj bookmark grupy `8` w bieżącym wierszu.
- **`m9`**: dodaj bookmark grupy `9` w bieżącym wierszu.
- **`dm0`**: usuń wszystkie bookmarki grupy `0` ze wszystkich buforów.
- **`dm1`**: usuń wszystkie bookmarki grupy `1` ze wszystkich buforów.
- **`dm2`**: usuń wszystkie bookmarki grupy `2` ze wszystkich buforów.
- **`dm3`**: usuń wszystkie bookmarki grupy `3` ze wszystkich buforów.
- **`dm4`**: usuń wszystkie bookmarki grupy `4` ze wszystkich buforów.
- **`dm5`**: usuń wszystkie bookmarki grupy `5` ze wszystkich buforów.
- **`dm6`**: usuń wszystkie bookmarki grupy `6` ze wszystkich buforów.
- **`dm7`**: usuń wszystkie bookmarki grupy `7` ze wszystkich buforów.
- **`dm8`**: usuń wszystkie bookmarki grupy `8` ze wszystkich buforów.
- **`dm9`**: usuń wszystkie bookmarki grupy `9` ze wszystkich buforów. Każde `dm0`-`dm9` działa na całą grupę, nie tylko bookmark pod kursorem ani bieżący bufor.
- **`m}`**: znajdź grupę bookmarka dokładnie pod kursorem i przejdź do następnego bookmarka tej samej grupy, także w innym buforze.
- **`m{`**: jak wyżej, lecz przejdź do poprzedniego bookmarka tej samej grupy.
- **`dm=`**: usuń bookmark pod kursorem. Jeżeli kilka grup zajmuje ten sam wiersz, implementacja wybiera pierwszą grupę zwróconą przez nieuporządkowane `pairs()`, więc wybór nie jest gwarantowany.

`m[` i `m]` przesłaniają natywne komendy ręcznie ustawiające specjalne `'[` i `']`. `m0`-`m9` nie odbierają możliwości ustawiania natywnych marek numerowanych, ponieważ tych marek nie można ustawiać ręcznie.

## Znaki, priority i timer odświeżania

Wtyczka definiuje znaki leniwie, osobno dla tekstu marki, i umieszcza je w grupach znaków `MarkSigns` oraz `BookmarkSigns`. Znak jest tylko prezentacją: jego ukrycie nie usuwa natywnej marki ani extmarka bookmarka.

- `signs=true` włącza znaki natywnych marek. Kod inicjalizuje znaki bookmarków osobno jako włączone; `:MarksToggleSigns` przełącza obie kategorie razem.
- Bez lokalnego `sign_priority` każda kategoria ma priority `10`: małe litery, wielkie litery, builtiny i bookmarki.
- Pokazane w README wartości `{ lower=10, upper=15, builtin=8, bookmark=20 }` są przykładem konfiguracji, a nie domyślnym ani lokalnym stanem.
- Lokalny `signcolumn=yes` ma pojemność jednej komórki znaku na wiersz. Gdy marka, bookmark, Gitsigns i DAP konkurują o ten sam wiersz, zobaczyć można tylko zwycięski znak; pozostałe pozycje nadal istnieją.
- Wyższe priority wygrywa z niższym. Przy remisie `10` nie należy opierać workflow na stabilnej kolejności renderowania między niezależnymi grupami znaków.
- Timer startuje od razu po `setup()` i co `250 ms` planuje `refresh()` bieżącego bufora. Obciążony event loop może zwiększyć faktyczne opóźnienie.
- `BufEnter` wymusza pełną rejestrację bieżącego bufora, a `BufDelete` usuwa jego cache marek i bookmarków.
- Akcja wykonana przez samą wtyczkę zwykle aktualizuje własny znak natychmiast. Natywna zmiana wykonana poza nią może być widoczna dopiero po timerze albo ponownym wejściu do bufora.

### Cztery lokalnie automatycznie odświeżane builtiny

- **`.`**: pozycja ostatniej zmiany.
- **`<`**: początek ostatniego zaznaczenia Visual.
- **`>`**: koniec ostatniego zaznaczenia Visual.
- **`^`**: pozycja ostatniego wyjścia z Insert.

Te cztery automatyczne marki są okresowo odświeżane, pokazywane jako znaki i trafiają do list generowanych przez wtyczkę. `builtin_marks` nie ogranicza nazwanych liter ani znaków specjalnych rozpoznawanych przez ogólny callback `m`; określa tylko automatyczne builtiny pobierane podczas refreshu. Te cztery nie uczestniczą w `m]` i `m[`, ponieważ kod cyklu przepuszcza wyłącznie litery. Upstream potrafi automatycznie śledzić także specjalną markę poprzedniego kontekstu `'`, lecz nie jest ona lokalnie wpisana do `builtin_marks`.

## Cykliczna nawigacja po markach

`m]` i `m[` nie oznaczają skoku według alfabetu. Wtyczka bierze literowe marki z cache bieżącego bufora i szuka najbliższego większego albo mniejszego numeru wiersza.

- `cyclic=true` powoduje zawinięcie z ostatniej do pierwszej oraz z pierwszej do ostatniej marki.
- Małe i wielkie litery położone w bieżącym buforze uczestniczą w tym samym cyklu.
- Builtiny, marki numerowane i bookmarki nie uczestniczą w tym cyklu.
- Wielkoliterowa marka w innym pliku nie jest celem `m]` ani `m[`; użyj bezpośredniego apostrofu/backticka albo `<leader>ma`.
- Kilka marek w tym samym wierszu stanowi jedną granicę dla wyszukiwania: algorytm porównuje wiersz, nie kolumnę, więc nie przechodzi kolejno po markach leżących na tej samej linii.
- Cache miesza dwie konwencje kolumn: akcje kursora zapisują indeks od `0`, a `getmarklist()` zwraca kolumnę od `1`. Po wymuszonym refreshu `m]`, `m[` i eksport listy mogą wskazać o jeden bajt za daleko; bezpośredni natywny skok nie używa tego cache.
- Kod nie odczytuje `vim.v.count`, dlatego `3m]` nie ma udokumentowanej semantyki trzech kroków. Upstream wymienia count-aware movement i operator-pending mappings jako niezrealizowane zadania.
- Skok ustawia kursor bezpośrednio przez API okna. Nie jest natywnym ruchem operator-pending i nie służy do konstrukcji takich jak `d2m]`.

## Podgląd `m:`

Po `m:` wtyczka wyświetla komunikat i czeka na jeden znak. `Esc` anuluje. Dla istniejącej marki pobiera pozycję przez `getpos()`, tworzy nowe okno float o połowie szerokości i wysokości bieżącego okna, z ramką `single`, przełącza do niego fokus, wykonuje dokładny skok backtickiem i centruje cel przez `zz`.

Istotne konsekwencje:

- „Preview” jest prawdziwym, fokusowanym oknem pokazującym docelowy bufor, a nie tymczasową warstwą podpowiedzi ani Telescope preview.
- Wtyczka nie ustawia bufora jako read-only i nie zamyka floatu automatycznie. `:close` albo zwykłe polecenie zamknięcia okna kończy podgląd.
- Każde skuteczne wywołanie może utworzyć kolejny float.
- Podgląd globalnej marki wymaga bufora, który `nvim_open_win()` potrafi otworzyć po numerze zwróconym przez `getpos()`; stara marka tylko w ShaDa albo niezaładowany cel może nie dać użytecznego podglądu.
- README i help obiecują, że `Enter` pokaże następną markę. Kod tej rewizji nie ma gałęzi obsługującej `Enter`; traktuje kod klawisza jak nazwę marki, więc nie należy polegać na tej obietnicy.
- Podanie nieistniejącej marki kończy akcję bez floatu, gdy numer wiersza wynosi `0`.

Do szybkiego podglądu wielu wyników lepszy jest lokalny `<leader>ma`; do znanej pozycji najprostszy pozostaje natywny backtick z nazwą.

## Bookmarki: 10 ulotnych grup

Bookmark `marks.nvim` to nienazwany rekord `(bufor, wiersz, kolumna)` połączony z extmarkiem. Nie zużywa liter `a`-`z` ani `A`-`Z`, może mieć znak, stały tekst wirtualny na końcu wiersza i indywidualną adnotację w osobnej virtual line. Wszystkie bookmarki żyją wyłącznie w pamięci bieżącego procesu Neovim.

Kod rewizji przypisuje domyślne znaki następująco:

- **grupa `0`**: znak `)`, ustawienie `m0`, usunięcie całej grupy `dm0`.
- **grupa `1`**: znak `!`, ustawienie `m1`, usunięcie całej grupy `dm1`.
- **grupa `2`**: znak `@`, ustawienie `m2`, usunięcie całej grupy `dm2`.
- **grupa `3`**: znak `#`, ustawienie `m3`, usunięcie całej grupy `dm3`.
- **grupa `4`**: znak `$`, ustawienie `m4`, usunięcie całej grupy `dm4`.
- **grupa `5`**: znak `%`, ustawienie `m5`, usunięcie całej grupy `dm5`.
- **grupa `6`**: znak `^`, ustawienie `m6`, usunięcie całej grupy `dm6`.
- **grupa `7`**: znak `&`, ustawienie `m7`, usunięcie całej grupy `dm7`.
- **grupa `8`**: znak `*`, ustawienie `m8`, usunięcie całej grupy `dm8`.
- **grupa `9`**: znak `(`, ustawienie `m9`, usunięcie całej grupy `dm9`.

README streszcza znaki jako `!@#$%^&*()` „od 0 do 9”, ale tabela Lua zaczyna zwykłe indeksy od `1` i jawnie ustawia `[0]=")"`. Powyższe przypisanie pochodzi bezpośrednio ze źródła i jest nadrzędne.

### Znak, `virt_text`, `annotate` i extmark

- `bookmark_N.sign`: znak grupy w signcolumn. `false` wyłącza znak tej grupy bez wyłączenia bookmarka.
- `bookmark_N.virt_text`: ten sam statyczny tekst dla każdego bookmarka grupy, renderowany na końcu wiersza. Kod domyślnie przechowuje `nil`, więc lokalnie nie ma tekstu EOL.
- `bookmark_N.annotate`: gdy `true`, bezpośrednio po ustawieniu bookmarka pyta o indywidualną adnotację. Lokalnie nie jest ustawione, więc prompt nie pojawia się automatycznie.
- `annotate()` z niepustym tekstem aktualizuje extmark i umieszcza virtual line nad bookmarkiem. Pusty tekst usuwa adnotację i odtwarza extmark z bazowym `virt_text` grupy.
- Tekst wirtualny i virtual line używają `MarkVirtTextHL` i nie modyfikują zawartości pliku.
- Każda grupa ma namespace `BookmarksN`; extmark przesuwa się wraz z edycją. Timer odczytuje jego bieżący wiersz, aktualizuje indeks w pamięci i odtwarza znaki.
- W jednej grupie może istnieć najwyżej jeden bookmark na danym wierszu. Różne grupy mogą współistnieć w tym samym wierszu.
- Ponowne `mN` na wierszu, który ma już bookmark tej samej grupy `N`, niczego nie zmienia; domyślne `mN` dodaje, a nie przełącza. Do toggle służy opcjonalne `toggle_bookmarkN()`.
- Wewnętrzny rekord zachowuje pierwotną kolumnę. Refresh koryguje wiersz z extmarka, lecz nie aktualizuje zapisanej kolumny po przesunięciu w obrębie tego samego wiersza; nawigacja i eksport mogą więc użyć starej kolumny.

### Kolejność między buforami

Bookmarki danej grupy są sortowane najpierw rosnąco po numerze bufora, potem po numerze wiersza. Numer bufora zwykle odzwierciedla kolejność tworzenia buforów, nie alfabet ścieżek ani kolejność ostatniego użycia.

- `m}` i `m{` najpierw rozpoznają grupę bookmarka dokładnie w bieżącym wierszu.
- Następny lub poprzedni cel w innym buforze jest otwierany przez `:buffer {nr}` w bieżącym oknie.
- Cykl bookmarków zawsze zawija na początek lub koniec; opcja `cyclic` steruje tylko `m]` i `m[` dla marek literowych.
- Help twierdzi, że warianty grupowe idą najpierw po wierszu, a potem po buforze. Implementacja `flatten()` robi odwrotnie: bufor, potem wiersz. Źródło jest tu nadrzędne.
- `next_bookmarkN()` i `prev_bookmarkN()` mogą rozpocząć nawigację grupy `N` z dowolnego wiersza, lecz lokalnie nie mają domyślnego skrótu.
- `BufDelete` usuwa wszystkie bookmarki kasowanego bufora z pamięci. Nie istnieje zapis do ShaDa ani pliku sesji wtyczki.

## Polecenia Ex

Wszystkie 11 nazw poniżej istnieje na zimnym starcie jako stuby Lazy. Pierwsze wywołanie dowolnej z nich ładuje wtyczkę, wykonuje `setup()` i przekazuje wywołanie do właściwego polecenia; bez wcześniejszego polecenia ten sam setup następuje na `VeryLazy`. Warianty list zastępują bieżącą zawartość docelowej listy flagą `r` i od razu ją otwierają.

### Widoczność znaków

- **`:MarksToggleSigns`**: przełącz znaki marek i bookmarków globalnie. Stan pozycji pozostaje bez zmian.
- **`:MarksToggleSigns {bufnr}`**: przełącz znaki tylko dla wskazanego numeru bufora, na przykład `:MarksToggleSigns 3`.

Odświeżenie wykonywane przez polecenie dotyczy od razu bieżącego bufora. Znaki w innym wskazanym lub wcześniej otwartym buforze mogą dogonić stan dopiero po wejściu do niego albo kolejnym refreshu, gdy stanie się bieżący.

### Location list

- **`:MarksListBuf`**: zastąp location list śledzonymi markami bieżącego bufora i wykonaj `:lopen`.
- **`:MarksListGlobal`**: wpisz wielkoliterowe marki ze śledzonych, otwartych buforów i wykonaj `:lopen`.
- **`:MarksListAll`**: wpisz wszystkie śledzone marki wszystkich buforów znanych cache i wykonaj `:lopen`.
- **`:BookmarksList {0-9}`**: wpisz wszystkie bookmarki wskazanej grupy ze wszystkich buforów i wykonaj `:lopen`.
- **`:BookmarksListAll`**: wpisz wszystkie bookmarki wszystkich zainicjalizowanych grup i wykonaj `:lopen`.

### Quickfix

- **`:MarksQFListBuf`**: odpowiednik `MarksListBuf` dla quickfix; kończy `:copen`.
- **`:MarksQFListGlobal`**: odpowiednik `MarksListGlobal` dla quickfix; kończy `:copen`.
- **`:MarksQFListAll`**: odpowiednik `MarksListAll` dla quickfix; kończy `:copen`.
- **`:BookmarksQFList {0-9}`**: bookmarki wskazanej grupy do quickfix; kończy `:copen`.
- **`:BookmarksQFListAll`**: wszystkie bookmarki do quickfix; kończy `:copen`.

Listy są migawkami cache z chwili wywołania. Wtyczka nie dodaje do nich automatycznie nowej marki, nie usuwa skasowanej pozycji i nie odświeża zapisanego tekstu wpisu; sam Neovim może nadal korygować linię istniejącego wpisu podczas edycji. Kolejność elementów pochodzi z `pairs()` i nie jest gwarantowanym sortowaniem przestrzennym. Nieistniejąca jeszcze grupa bookmarków powoduje wcześniejszy return, więc jej polecenie może tylko otworzyć poprzednią location list lub quickfix zamiast zastąpić ją pustą listą. Listy mogą też nie obejmować globalnej marki istniejącej wyłącznie w ShaDa, jeżeli jej plik nie został otwarty i zarejestrowany. Ponowne wywołanie polecenia dla istniejącego stanu buduje nową migawkę.

## Wszystkie opcje `setup()`

- **`default_mappings: boolean`**: czy instalować domyślne mapowania. Upstream `true`, lokalnie `true`.
- **`builtin_marks: table`**: automatyczne marki specjalne okresowo odświeżane, śledzone i pokazywane niezależnie od ustawiania ich przez callback `m`. Upstream domyślnie `{}`; help wspiera `'`, `^`, `.`, `<`, `>`; lokalnie `.`, `<`, `>`, `^`.
- **`signs: boolean`**: widoczność znaków natywnych marek. Upstream `true`, lokalnie `true`. Kod inicjalizuje widoczność znaków bookmarków osobno jako `true`.
- **`cyclic: boolean`**: zawijanie `m]` i `m[` na granicach bieżącego bufora. Upstream `true`, lokalnie `true`; nie steruje bookmarkami.
- **`force_write_shada: boolean`**: po usunięciu zarejestrowanej marki wywołuj `:wshada!`. Upstream `false`, lokalnie `false`.
- **`refresh_interval: integer`**: okres timera w milisekundach. Upstream `150`, lokalnie `250`.
- **`sign_priority: number | table`**: jeden priorytet dla wszystkiego albo pola `lower`, `upper`, `builtin`, `bookmark`. Upstream `10`; lokalnie brak override, więc wszystkie cztery kategorie mają `10`.
- **`excluded_filetypes: table`**: filetype bez śledzenia i znaków. Upstream oraz lokalnie `{}`. Natywne ustawienie i skok nadal mogą działać, ale akcje cache takie jak `m]` nie mają tam pełnego stanu.
- **`excluded_buftypes: table`**: analogiczna lista dla `buftype`. Upstream oraz lokalnie `{}`.
- **`bookmark_0`-`bookmark_9: table`**: konfiguracja każdej grupy przez `sign`, `virt_text`, `annotate`. Lokalnie brak override.
- **`mappings: table`**: nadpisania mapowań według kluczy akcji. Upstream oraz lokalnie `{}`, więc działają defaulty.

Nie istnieje opcja zapisu bookmarków, nazwa pliku bookmarków, limit historii ani mechanizm przywracania po restarcie. Wielokrotne wywołanie `setup()` tworzy kolejny timer, a kod nie udostępnia funkcji teardown; setup należy wykonywać raz.

## Wszystkie klucze `mappings`

Wartością klucza jest nowy lewy skrót, a `false` wyłącza daną domyślną akcję. `default_mappings=false` najpierw opróżnia zestaw defaultów, ale wpisy jawnie podane w `mappings` nadal są instalowane. Wszystkie mapowania tworzone przez setup są globalne i tylko w Normal.

- **`set`**: ustaw markę po odczytaniu znaku. Domyślnie `m`.
- **`set_next`**: ustaw następną wolną małą literę. Domyślnie `m,`.
- **`toggle`**: ustaw markę albo usuń marki bieżącego wiersza. Domyślnie `m;`.
- **`delete`**: usuń markę po odczytaniu znaku. Domyślnie `dm`.
- **`delete_line`**: usuń marki bieżącego wiersza. Domyślnie `dm-`.
- **`delete_buf`**: usuń marki bieżącego bufora. Domyślnie `dm<Space>`.
- **`next`**: następna marka literowa w buforze. Domyślnie `m]`.
- **`prev`**: poprzednia marka literowa w buforze. Domyślnie `m[`.
- **`preview`**: prompt i float podglądu. Domyślnie `m:`.
- **`set_bookmark0`-`set_bookmark9`**: ustaw bookmark grupy. Domyślnie odpowiednio `m0`-`m9`.
- **`delete_bookmark0`-`delete_bookmark9`**: usuń całą grupę. Domyślnie odpowiednio `dm0`-`dm9`.
- **`delete_bookmark`**: usuń bookmark pod kursorem. Domyślnie `dm=`.
- **`next_bookmark`**: następny bookmark grupy rozpoznanej pod kursorem. Domyślnie `m}`.
- **`prev_bookmark`**: poprzedni bookmark grupy rozpoznanej pod kursorem. Domyślnie `m{`.
- **`toggle_bookmark0`-`toggle_bookmark9`**: przełącz bookmark konkretnej grupy w bieżącym wierszu. **Stan:** **Opcjonalne upstream**, bez domyślnego skrótu.
- **`next_bookmark0`-`next_bookmark9`**: następny bookmark jawnie wybranej grupy. **Stan:** **Opcjonalne upstream**, bez domyślnego skrótu.
- **`prev_bookmark0`-`prev_bookmark9`**: poprzedni bookmark jawnie wybranej grupy. **Stan:** **Opcjonalne upstream**, bez domyślnego skrótu.
- **`annotate`**: prompt adnotacji dla bookmarka pod kursorem. **Stan:** **Opcjonalne upstream**, bez domyślnego skrótu.

Nieznany klucz nie ma udokumentowanej walidacji jako błąd konfiguracji; setup próbuje użyć funkcji modułu o tej samej nazwie. Należy ograniczyć się do powyższego katalogu.

## Wszystkie cele `<Plug>`

Cele `<Plug>` istnieją niezależnie od tabeli defaultów i pozwalają zbudować mapowania poza `setup()`. Zewnętrzne mapowanie do `<Plug>` powinno zezwalać na remap, na przykład `nmap ... <Plug>(...)`.

- `<Plug>(Marks-set)`
- `<Plug>(Marks-setnext)`
- `<Plug>(Marks-toggle)`
- `<Plug>(Marks-delete)`
- `<Plug>(Marks-deleteline)`
- `<Plug>(Marks-deletebuf)`
- `<Plug>(Marks-preview)`
- `<Plug>(Marks-next)`
- `<Plug>(Marks-prev)`
- `<Plug>(Marks-delete-bookmark)`
- `<Plug>(Marks-next-bookmark)`
- `<Plug>(Marks-prev-bookmark)`
- `<Plug>(Marks-set-bookmark0)` do `<Plug>(Marks-set-bookmark9)`
- `<Plug>(Marks-delete-bookmark0)` do `<Plug>(Marks-delete-bookmark9)`
- `<Plug>(Marks-toggle-bookmark0)` do `<Plug>(Marks-toggle-bookmark9)`
- `<Plug>(Marks-next-bookmark0)` do `<Plug>(Marks-next-bookmark9)`
- `<Plug>(Marks-prev-bookmark0)` do `<Plug>(Marks-prev-bookmark9)`

Nie ma `<Plug>(Marks-annotate)`, `<Plug>` dla poleceń list ani `<Plug>` dla przełączania znaków. Adnotację można przypisać kluczem `mappings.annotate` albo wywołać przez Lua.

## Highlighty

- **`MarkSignHL`**: tekst znaków zarówno marek, jak i bookmarków; source używa `hi default link ... Identifier`.
- **`MarkSignNumHL`**: numer wiersza dla umieszczonego znaku; source linkuje do `CursorLineNr`.
- **`MarkVirtTextHL`**: `virt_text` EOL i virtual lines adnotacji; source linkuje do `Comment`.

Linki są `default`, więc colorscheme albo późniejsza konfiguracja może je nadpisać. Help tej rewizji opisuje `MarkSignNumHL` jako domyślnie połączony z `LineNr`, ale wykonywany plik `plugin/marks.vim` używa `CursorLineNr`; rzeczywisty kod jest nadrzędny.

## Publiczne wywołania Lua

Moduł zwracany przez `require("marks")` eksportuje następujące funkcje. Upstream nie deklaruje stabilnej polityki API, dlatego bezpośrednie wywołania należy wiązać z przypiętą rewizją.

### Setup i marki natywne

- **`require("marks").setup(config)`**: inicjalizacja stanów, mapowań, autocmdów i timera.
- **`require("marks").set()`**: odczytaj znak, zarejestruj i ustaw obsługiwaną markę.
- **`require("marks").set_next()`**: ustaw najniższą wolną małą literę.
- **`require("marks").toggle()`**: przełącz obecność śledzonych marek w bieżącym wierszu.
- **`require("marks").delete()`**: odczytaj znak i usuń zarejestrowaną markę.
- **`require("marks").delete_line()`**: usuń śledzone marki z wiersza.
- **`require("marks").delete_buf()`**: wyczyść marki bieżącego bufora przez `:delmarks!`.
- **`require("marks").preview()`**: prompt i nowe okno float.
- **`require("marks").next()`**: następna literowa marka w bieżącym buforze.
- **`require("marks").prev()`**: poprzednia literowa marka w bieżącym buforze.

### Bookmarki

- **`require("marks").set_bookmark0()` do `set_bookmark9()`**: dodaj bookmark grupy.
- **`require("marks").toggle_bookmark0()` do `toggle_bookmark9()`**: przełącz bookmark grupy w wierszu.
- **`require("marks").delete_bookmark0()` do `delete_bookmark9()`**: usuń wszystkie bookmarki grupy.
- **`require("marks").next_bookmark0()` do `next_bookmark9()`**: następny bookmark jawnej grupy.
- **`require("marks").prev_bookmark0()` do `prev_bookmark9()`**: poprzedni bookmark jawnej grupy.
- **`require("marks").delete_bookmark()`**: usuń bookmark pod kursorem.
- **`require("marks").next_bookmark()`**: następny bookmark grupy rozpoznanej pod kursorem.
- **`require("marks").prev_bookmark()`**: poprzedni bookmark grupy rozpoznanej pod kursorem.
- **`require("marks").annotate()`**: dodaj, zmień albo wyczyść adnotację bookmarka pod kursorem.

### Odświeżanie i znaki

- **`require("marks").refresh([force_reregister])`**: odśwież natywne marki i bookmarki bieżącego bufora; `true` wymusza ponowną rejestrację marek.
- **`require("marks").toggle_signs([bufnr])`**: przełącz znaki globalnie albo dla numeru bufora.
- **`require("marks")._on_delete()`**: technicznie eksportowana, ale wewnętrzna obsługa `BufDelete`; nie jest funkcją użytkową.

Po `setup()` moduł ujawnia także `mark_state` i `bookmark_state`. Polecenia Ex wywołują na nich między innymi `buffer_to_list()`, `global_to_list()`, `all_to_list()` i `to_list()`. Są to szczegóły implementacji obiektów stanu, nie dokumentowany stabilny interfejs; lepiej używać poleceń Ex.

## Relacja z Telescope

Lokalny `<leader>ma` wywołuje `:Telescope marks`, czyli builtin `marks` wtyczki Telescope. Przypięta rewizja Telescope pobiera lokalne pozycje przez `getmarklist(bufnr)`, globalne przez `getmarklist()`, dokłada preview i pozwala fuzzy-filtrować wynik. Picker prezentuje natywny stan marek Neovim, lecz sam jest funkcją wtyczki Telescope, nie natywnym pickerem Neovim ani rozszerzeniem `marks.nvim`.

- Natywna marka utworzona przez `marks.nvim` pojawia się w Telescope, bo końcowo jest prawdziwą marką Neovim.
- Bookmark nie pojawia się w Telescope, ponieważ jest prywatnym extmarkiem w pamięci `marks.nvim`.
- `m:` tworzy własny float wtyczki; nie otwiera pickera Telescope i nie dziedziczy jego mapowań.
- `MarksList*` i `MarksQFList*` tworzą listy Neovim; nie uruchamiają Telescope.
- `<leader>ma` działa jako przeglądarka natywnych marek także wtedy, gdy nie używa się bookmarków albo znaki `marks.nvim` są wyłączone.

Praktyczny podział: użyj bezpośredniego backticka, gdy pamiętasz nazwę; `m]`/`m[` do przestrzennego cyklu w jednym buforze; `<leader>ma` do wyszukania nazwy lub pliku; bookmarków do krótkiego, nienazwanego zestawu pozycji w bieżącej sesji.

## Relacja z Wayfinder Trail

Wayfinder Trail i bookmarki `marks.nvim` rozwiązują inne problemy. Pełny lokalny opis znajduje się w [rozdziale Wayfinder](13-wayfinder.md#plugin-wayfinder).

- **natywna marka**: ma krótką nazwę, jest częścią Neovim, nadaje się do natychmiastowego skoku i może trafić do ShaDa.
- **bookmark `marks.nvim`**: jest lekkim, widocznym extmarkiem grupy, wygodnym do cyklu po już otwartych buforach, ale znika po restarcie.
- **Wayfinder Trail**: jest kuratorowaną ścieżką eksploracji kodu z elementami wybranymi z definicji, referencji, wywołań, testów i Git. Zapisane Trails są projektowe i trafiają pod stan Neovim, a nie do ShaDa ani do pliku repozytorium.

Trail zachowuje narrację „jak doszedłem przez powiązany kod”, podczas gdy marka lub bookmark odpowiada na prostsze „wróć do tej pozycji”. Trail nie zużywa liter marek, nie jest widoczny przez `:marks`, nie jest grupą `m0`-`m9` i nie jest źródłem znaków `marks.nvim`.

## Przepływy pracy

### Szybkie punkty w jednym pliku

1. Naciśnij `m,`; w pustym zestawie powstanie `a`.
2. Ustaw kolejne punkty przez `m,` albo wybierz semantyczne nazwy, na przykład `mt` i `mb`.
3. Przechodź przestrzennie przez `m]` i `m[`, z zawijaniem dzięki `cyclic=true`.
4. Do znanej pozycji użyj dokładnego backticka z literą; apostrofu użyj, gdy chcesz pierwszy niebiały znak wiersza.
5. `m;` jest wygodnym toggle tylko na wierszu bez innych ważnych marek. Na zajętym wierszu usuwa wszystkie śledzone marki, więc przed użyciem sprawdź gutter albo `:marks`.

### Implementacja i test w dwóch plikach

1. W implementacji ustaw `mI`, a w teście `mT`.
2. Backtick + `I` i backtick + `T` wykonują precyzyjne skoki między plikami.
3. `<leader>ma` pozwala znaleźć obie po nazwie lub ścieżce i obejrzeć preview.
4. Nie oczekuj, że `m]` przejdzie z `I` do `T`; cykl marek wtyczki jest ograniczony do bieżącego bufora.
5. Przy `force_write_shada=false` usunięcie starej wielkiej litery nie wymusza trwałego zapisu; sprawdź sekcję o ShaDa przed ręcznym `:wshada!`.

### Ulotny cykl kod i test przez bookmarki

1. Ustaw `m1` na interesującej linii implementacji.
2. Otwórz test i ustaw kolejne `m1`.
3. Stojąc dokładnie na jednym z tych wierszy, używaj `m}` i `m{` do przełączania grupy `1` między buforami.
4. Jeśli chcesz rozpocząć cykl grupy z dowolnego miejsca, ręcznie wywołaj `:lua require("marks").next_bookmark1()`; lokalnie nie ma skrótu dla tej funkcji.
5. `dm=` usuwa pojedynczy bookmark pod kursorem, natomiast `dm1` usuwa całą grupę `1` we wszystkich buforach.
6. Nie traktuj grupy jako stanu projektu: restart albo `:bdelete` usuwa bookmarki.

### Adnotowany punkt przeglądu

1. Ustaw na wierszu bookmark, na przykład `m2`.
2. Wywołaj `:lua require("marks").annotate()`.
3. Wpisz tekst; pojawi się jako virtual line nad wierszem i nie zmieni pliku.
4. Ponów wywołanie i zatwierdź pusty tekst, aby usunąć indywidualną adnotację oraz wrócić do statycznego `virt_text` grupy, lokalnie niewidocznego.
5. Pamiętaj, że adnotacja również jest sesyjna.

### Przegląd przez location list albo quickfix

1. Użyj `:MarksListBuf` dla bieżącego pliku albo `:MarksListAll` dla cache wielu buforów.
2. Location list jest lokalna dla okna i otwiera się automatycznie; poruszaj się standardowymi `:lnext` i `:lprevious`.
3. Do współdzielonej listy użyj `:MarksQFListAll`; lokalne `[q` i `]q` przechodzą po quickfix.
4. Dla bookmarków wybierz grupę przez `:BookmarksList 1` albo użyj `:BookmarksQFListAll`.
5. Po zmianie marek ponownie wykonaj polecenie, bo członkostwo i tekst listy są migawką.

### `J` bez zajmowania `z`

1. Ustaw własne `mz` albo pozwól, aby `m,` kiedyś doszło do `z`.
2. Używaj lokalnego `J` do łączenia wierszy z zachowaniem kursora.
3. Sprawdź `:marks z`: `J` nie powinno tworzyć ani przenosić `z`.
4. Jeżeli `z` mimo to się zmienia, `:verbose nmap J` ujawni starsze lub konkurencyjne mapowanie używające sekwencji `mzJ` i skoku do `z`.

## Trwałość i ograniczenia wynikające ze źródła

- **Bookmarki są session-only:** nie są natywnymi markami, nie trafiają do ShaDa, session file ani własnego storage. Extmark i adnotacja znikają przy restarcie, a `BufDelete` usuwa stan bufora.
- **Listy są migawkami:** polecenia location/quickfix kopiują członkostwo aktualnego cache oraz tekst wierszy i zastępują listę. Neovim może przesuwać pozycję już istniejącego wpisu razem z edycją, ale wtyczka nie przebudowuje członkostwa, tekstu ani kolejności i nie zna globalnych celów z nieotwartych buforów.
- **Znaki konkurują:** lokalna jedna kolumna i priority `10` dla wszystkich kategorii nie gwarantują jednoczesnego pokazania marki, bookmarka, Gitsigns i DAP. Brak znaku nie dowodzi braku pozycji.
- **`force_write_shada=false`:** usunięcie globalnej marki działa w bieżącej pamięci, lecz wtyczka nie wymusza usunięcia starego wpisu z dysku. Późniejsze scalanie lub odczyt ShaDa może odtworzyć wpis; nie ma gwarancji trwałego skasowania bez świadomego zarządzania ShaDa.
- **`force_write_shada=true` jest destrukcyjne:** implementacja wywołuje `:wshada!` po każdej ścieżce `delete_mark()`, nie tylko po wielkich literach. Bang pomija merge starego pliku i część zabezpieczeń, aktualizuje `0`-`9`, resetuje marki `"` oraz może utracić dane nieobecne w bieżącym procesie. Usuwanie kilku marek z wiersza może wywołać zapis wielokrotnie.
- **`delete_buf()` nie wymusza ShaDa:** ta ścieżka zeruje cache i wykonuje `:delmarks!` bez przechodzenia przez `delete_mark()`, więc nawet `force_write_shada=true` nie daje tu jednolitego zachowania.
- **Podgląd tworzy float:** `m:` wchodzi do nowego, edytowalnego okna i go nie zamyka. Nie jest to pasywny tooltip.
- **`Enter` w podglądzie:** obietnica „następnej marki” z README/help nie ma implementacji w tej rewizji.
- **Ograniczenie wielkich liter:** `m]`/`m[` nie przechodzą między plikami, `dmA` z innego bufora może nic nie zrobić, a listy globalne obejmują tylko cache otwartych lub śledzonych buforów. Natywny backtick/apostrof i Telescope korzystają bezpośrednio z globalnego stanu i są właściwą drogą do odległych celów.
- **Wielkie litery mogą wrócić po `dm<Space>`:** `:delmarks!` ich nie kasuje, a następny timer może ponownie zarejestrować je i odtworzyć znaki w bieżącym buforze.
- **Nawigacja jest wierszowa:** cykl marek ignoruje różnice kolumn na tej samej linii; refresh wykrywa zmianę pozycji natywnej marki głównie po numerze wiersza, więc natywne przesunięcie tylko w kolumnie może pozostać chwilowo nieaktualne w cache.
- **Podstawa kolumn jest niespójna:** `nvim_win_get_cursor()` daje kolumnę od `0`, `getmarklist()` od `1`, a source zapisuje obie bez normalizacji. Po pełnej rejestracji cykl marek może wylądować o jeden bajt w prawo, a wpis listy może mieć kolumnę zawyżoną; natywne apostrofy/backticki i Telescope nie korzystają z tej zapisanej kolumny wtyczki.
- **Kolumna bookmarka może się zestarzeć:** extmark poprawnie śledzi edycję, lecz rekord Lua odświeża tylko wiersz. Skok i eksport mogą zachować dawną kolumnę.
- **Wiele grup w jednym wierszu jest niejednoznaczne:** `dm=`, `m{` i `m}` wybierają grupę przez `pairs()`, bez gwarantowanej kolejności.
- **Porządek bookmarków to bufor, potem wiersz:** nie ścieżka, MRU ani kolejność opisana w helpie.
- **Brak count i operator-pending:** mapowania callback nie implementują liczników ani ruchów operatora. Do zakresów tekstowych używaj natywnych apostrofów/backticków.
- **Brak obsługi wyczerpania liter:** po zajęciu wszystkich `a`-`z` allocator `m,` przesuwa swój znak za `z` i może spróbować niepoprawnego natywnego `m{`; nie zawija ani nie zgłasza kontrolowanego „brak wolnych marek”.
- **Timer odświeża bieżący bufor:** nieaktywny bufor może pokazywać stary znak do wejścia przez `BufEnter`.
- **`dm<Space>` czyści changelistę:** to skutek natywnego `:delmarks!`, łatwy do przeoczenia, gdy intencją było tylko usunięcie znaków.
- **`m;` i `dm-` obejmują builtiny:** cache `marks_by_line` zawiera także lokalnie śledzone `.`, `<`, `>`, `^`; operacja usuwa wszystkie śledzone marki tego wiersza, nie tylko małą literę utworzoną przez `m,`.
- **Brak mechanizmu health:** rewizja nie dostarcza `:checkhealth marks`; diagnoza opiera się na mapowaniach, stanie Lua, znakach, `:messages` i natywnych poleceniach.

## Diagnostyka

1. Otwórz `:Lazy` i potwierdź właściwy commit oraz czy `marks.nvim` załadował się przez jedno z 11 poleceń-triggerów albo przez `VeryLazy`.
2. Użyj `:verbose nmap m`, `:verbose nmap m,`, `:verbose nmap m[` i `:verbose nmap dm`; opis powinien wskazywać callbacki `marks: ...`.
3. Użyj `:verbose nmap J`, aby potwierdzić lokalną wersję zachowującą kursor bez marki `z`.
4. Porównaj `:marks`, `:lua vim.print(vim.fn.getmarklist("%"))` i `:lua vim.print(vim.fn.getmarklist())`; pierwsza funkcja Lua pokazuje lokalne, druga globalne marki źródłowe.
5. Sprawdź cache przez `:lua vim.print(require("marks").mark_state.buffers[vim.api.nvim_get_current_buf()])` i konfigurację mapowań przez `:lua vim.print(require("marks").mappings)`.
6. Wymuś bieżący refresh przez `:lua require("marks").refresh(true)`, jeżeli natywna marka istnieje, ale znak lub lista spóźnia się ponad `250 ms`.
7. Użyj `:sign place`, `:set signcolumn?` i `:highlight MarkSignHL`; obecność kilku znaków na jednym wierszu wyjaśnia niewidoczny gutter.
8. Porównaj `:MarksListAll`, `:MarksListGlobal` i `<leader>ma`. Bookmarków szukaj przez `:BookmarksListAll`, nie `:marks` ani Telescope.
9. Sprawdź `:set shada? shadafile?`, `:oldfiles`, `:jumps` oraz `:messages`, jeżeli globalna marka wraca po restarcie albo zapis ShaDa zgłasza błąd.
10. Jeżeli `m:` zostawił fokusowany float, sprawdź `:windows` i zamknij tylko to okno przez `:close`; nie usuwaj bufora źródłowego.
11. Jeżeli bookmark nie przechodzi przez `m}` lub `m{`, ustaw kursor dokładnie w jego wierszu albo wywołaj jawne `next_bookmarkN()`.
12. Jeżeli mapowania zniknęły po ponownym setupie albo zachowują się wielokrotnie, sprawdź, czy `setup()` nie został uruchomiony więcej niż raz; każdy setup tworzy timer i nie ma teardown.

## Źródła przypiętych rewizji

**`marks.nvim` `f353e8c08c50f39e99a9ed474172df7eddd89b72`:** [README](https://github.com/chentoast/marks.nvim/blob/f353e8c08c50f39e99a9ed474172df7eddd89b72/README.md), [pełny help](https://github.com/chentoast/marks.nvim/blob/f353e8c08c50f39e99a9ed474172df7eddd89b72/doc/marks-nvim.txt), [setup, mapowania i API](https://github.com/chentoast/marks.nvim/blob/f353e8c08c50f39e99a9ed474172df7eddd89b72/lua/marks/init.lua), [cache, cykl, listy i preview marek](https://github.com/chentoast/marks.nvim/blob/f353e8c08c50f39e99a9ed474172df7eddd89b72/lua/marks/mark.lua), [bookmarki i extmarki](https://github.com/chentoast/marks.nvim/blob/f353e8c08c50f39e99a9ed474172df7eddd89b72/lua/marks/bookmark.lua), [znaki i klasyfikacja marek](https://github.com/chentoast/marks.nvim/blob/f353e8c08c50f39e99a9ed474172df7eddd89b72/lua/marks/utils.lua), [polecenia, `<Plug>` i highlighty](https://github.com/chentoast/marks.nvim/blob/f353e8c08c50f39e99a9ed474172df7eddd89b72/plugin/marks.vim).

**Neovim `0.12.4`, commit `68ea43cd0c28af25cd47731308c94fedfcfd1b0b`:** [marki i jumplista](https://github.com/neovim/neovim/blob/68ea43cd0c28af25cd47731308c94fedfcfd1b0b/runtime/doc/motion.txt), [cykl życia `:bdelete` i `:bwipeout`](https://github.com/neovim/neovim/blob/68ea43cd0c28af25cd47731308c94fedfcfd1b0b/runtime/doc/windows.txt), [odczyt, zapis i merge ShaDa](https://github.com/neovim/neovim/blob/68ea43cd0c28af25cd47731308c94fedfcfd1b0b/runtime/doc/starting.txt), [opcja `'shada'`](https://github.com/neovim/neovim/blob/68ea43cd0c28af25cd47731308c94fedfcfd1b0b/runtime/doc/options.txt).

**Powiązane integracje:** [builtin `marks` wtyczki Telescope w przypiętej rewizji](https://github.com/nvim-telescope/telescope.nvim/blob/a8c2223ea6b185701090ccb1ebc7f4e41c4c9784/lua/telescope/builtin/__internal.lua), [model Wayfinder Trail w commicie `2ce480d35626ddb533ba594fa7ca865d61184ec6`](https://github.com/error311/wayfinder.nvim/blob/2ce480d35626ddb533ba594fa7ca865d61184ec6/README.md).
