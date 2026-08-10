# Lokalne watchdiff.nvim i claude.nvim

<a id="plugin-watchdiff"></a>
## `watchdiff.nvim`

**Ścieżka:** `watchdiff.nvim/` w tym repozytorium.

**Co robi i po co:** obserwuje rekursywnie bieżący katalog przez `vim.uv` i pokazuje, co narzędzie zewnętrzne zmieniło od ostatniego „uznanego” stanu. To inny punkt odniesienia niż Gitsigns: baseline użytkownika zamiast Git HEAD/index.

**Ładowanie lokalne:** `VeryLazy`, `opts={}`. Debounce 200 ms, maksymalnie 50 wpisów historii na plik, ignorowanie między innymi `.git`, `.next`, `node_modules`, swapów i `.DS_Store`. Domyślnie śledzone są tylko już załadowane bufory.

**Zachowanie:** czysty bufor jest przeładowywany przez `checktime`; zmienione/dodane linie dostają zielone tło, usunięte pojawiają się jako czerwone virtual lines. Baseline aktualizuje otwarcie, własny zapis i clear, lecz nie zewnętrzna edycja.

- **`<leader>ch`**: Wyczyść highlight i uznaj bieżącą treść jako baseline. **Kontekst:** globalny `n`. **Stan:** **Aktywne lokalne**.
- **`q`**: Zamknij historię. **Kontekst:** scratch historii. **Stan:** **Kontekstowe**.
- **mapowanie historii**: Brak, bo `keys.history=false`. **Kontekst:** globalny. **Stan:** **Warunkowe/wyłączone**.

**Polecenie:** `:WatchDiffHistory` pokazuje zapamiętaną historię bieżącego pliku. Funkcje provenance używane przez Claude są API Lua, nie poleceniami Ex.

### Dokładny model baseline

- **otwarcie pliku**: **Baseline:** ustawiony na treść bufora. **Highlight:** brak zmiany. **Historia:** brak wpisu.
- **zewnętrzna zmiana czystego bufora**: **Baseline:** pozostaje stary. **Highlight:** przeliczony baseline → nowa treść. **Historia:** nowy skumulowany wpis.
- **własne `:write`**: **Baseline:** przesunięty do zapisanej treści. **Highlight:** istniejące extmarki chwilowo pozostają. **Historia:** brak wpisu.
- **następna zewnętrzna zmiana po zapisie**: **Baseline:** używa post-save baseline. **Highlight:** stare markery znikają i są przeliczane. **Historia:** nowy wpis.
- **`<leader>ch`**: **Baseline:** przesunięty do bieżącej treści. **Highlight:** wyczyszczony. **Historia:** wcześniejsza historia pozostaje.
- **restart Neovim**: **Baseline:** utracony. **Highlight:** utracony. **Historia:** utracona cała historia.

Kolejne zewnętrzne zmiany bez clear są porównywane do tego samego uznanego baseline. Drugi wpis może więc opisywać `A → C`, a nie tylko ostatni krok `B → C`.

### Tutorial: kontrolowana zmiana zewnętrzna

1. Uruchom Neovim w root testowego projektu i sprawdź `:pwd`. Otwórz oraz zapisz zwykły lokalny plik.
2. Zmień go z drugiej powłoki lub narzędzia. Wróć do Neovim; czysty bufor powinien się przeładować.
3. Zielone tło oznacza dodane/zmienione wiersze, czerwone virtual lines usunięcia względem baseline. Zamiana może liczyć jednocześnie dodania i usunięcia.
4. Otwórz `:WatchDiffHistory`. Najnowszy wpis pokazuje czas, ścieżkę, source/action, liczniki, opcjonalny summary i `meta.question`; pozostałe metadata są w Lua `get_history()`, ale UI ich nie renderuje. Historia nie przechowuje patcha ani starej/nowej treści.
5. Dopiero po review użyj `<leader>ch`. To akceptuje bieżącą treść jako nowy punkt odniesienia; nie usuwa zapisanej w pamięci listy historii.

### Konflikt z niezapisanym buforem

W głównej ścieżce fs-event zmodyfikowany bufor dostaje ostrzeżenie i nie jest przeładowywany; nie zawsze pojawia się interaktywny prompt. Prompt należy do fallbacku `FileChangedShell`. Nie powstaje wtedy wpis historii, a `:e!` bezpowrotnie odrzuca lokalną wersję bufora. Najpierw skopiuj ją do innego bufora/pliku albo porównaj dysk osobno.

### Historia i provenance bez fałszywych gwarancji

- Zwykły event dostaje `source="external"`; watcher nie zna procesu, który zapisał plik.
- Claude może przez API oznaczyć następny pasujący diff, ale jest to adnotacja, nie dowód autorstwa ani atomowe powiązanie z konkretnymi bajtami.
- Na ścieżkę istnieje jeden pending annotation bez kolejki i expiry. Konflikt, identyczna treść, zignorowany event albo pominięcie dużego pliku może pozostawić oznaczenie dla późniejszej, innej zmiany.
- Liczniki wpisu są skumulowane względem baseline. Historia ma maksymalnie 50 rekordów na canonical path i istnieje tylko w bieżącej sesji.

### Ograniczenia zakresu

- Plik ponad 5000 wierszy kończy obsługę przed highlightem, liczeniem, historią, notyfikacją i konsumpcją provenance, nie tylko przed rysowaniem inline.
- Domyślnie zmiana nieotwartego pliku jest ignorowana. Opcjonalne `track_unopened_files=true` ładuje plik i używa Git `HEAD` jako baseline, co jest innym modelem.
- Usunięcie całego pliku, rename i trwała historia patchy nie są implementowane.
- Watcher obserwuje jeden CWD i restartuje się przy `DirChanged`; wsparcie recursive zależy od filesystemu/platformy.
- Bufory Distant `acwrite` nie są śledzone.

**Bezpieczeństwo:** `<leader>ch` nie cofa zmian, tylko je uznaje. `:e!` odrzuca niezapisany bufor. Provenance nie powinno być używane jako audyt bezpieczeństwa.

**Wymagania:** Neovim z `vim.uv`; recursive fs events zależą od systemu plików. CWD powinien być rootem obserwowanego projektu.

**Diagnostyka:** `:pwd`, `:set modified? autoread?`, `:messages`, `:autocmd WatchDiff`, sprawdzenie czy bufor jest załadowany i zwykły oraz czy ścieżka nie pasuje do ignore. `watchdiff.nvim/VALIDATION.md` zawiera ręczny scenariusz, ale nie pokrywa wszystkich ograniczeń provenance i dużych plików.

**Źródła lokalne:** [README](../../watchdiff.nvim/README.md), [implementacja](../../watchdiff.nvim/lua/watchdiff.lua), [ręczna walidacja](../../watchdiff.nvim/VALIDATION.md).

<a id="plugin-claude"></a>
## `claude.nvim`

**Ścieżka:** `claude.nvim/` w tym repozytorium.

**Co robi i po co:** lokalny popup do wysyłania pytania z kontekstem pliku/zaznaczenia do CLI Claude, z drawerem odpowiedzi i kontrolowanym wstawianiem komentarzy do kodu.

**Ładowanie lokalne:** `VeryLazy`, `opts={}`. Backend to executable `claude` z argumentami `-p --output-format json --permission-mode plan --model ... --json-schema ...`. Modele: `opus 4.5`, `sonnet`, `haiku`; etykieta `opus 4.5` wysyła alias CLI `opus`, którego faktyczną wersję rozwiązuje zainstalowane Claude CLI. Odpowiedzi używają drawera Volt, a scratch jest fallbackiem.

**Aktywne globalne:** `<leader>ac` w `n,v` oraz `<leader>aC` w `n,v`.

**Polecenia:** `:Claude`, `:ClaudeCommentNow`, `:ClaudeComment`.

### Popup wejściowy

- **`Enter`**: Wyślij prompt. **Tryb:** `i,n`.
- **`Ctrl-j`**: Wstaw nową linię bez wysyłania. **Tryb:** `i`.
- **`q` / `Esc`**: Zamknij. **Tryb:** `n`.
- **`Esc`**: Zamknij. **Tryb:** `i`.
- **`Ctrl-c`**: Gdy busy: anuluj żądanie i pozostaw popup; gdy idle: zamknij popup. **Tryb:** `i`.
- **`Ctrl-l`**: Wyczyść prompt. **Tryb:** `i`.
- **`Tab`**: Następny model. **Tryb:** `i,n`.
- **`F2`**: Answer kontra comment-now. **Tryb:** `i,n`.

### Drawer odpowiedzi

- **`q` / `Esc`**: Zamknij drawer. **Kontekst:** body.
- **`I`**: Spróbuj wstawić ostatnią odpowiedź jako komentarze. **Kontekst:** body.
- **`y` / `Y`**: Kopiuj odpowiedź / gotowy blok komentarza. **Kontekst:** body.
- **`o`**: Zamknij drawer i otwórz pełny scratch. **Kontekst:** body.
- **`Tab` / `Shift-Tab`**: Następna / poprzednia karta. **Kontekst:** body.
- **`1` / `2` / `3`**: Answer / Question / Files. **Kontekst:** body.
- **`Enter`**: Podgląd wskazanego consulted file w splicie, drawer pozostaje otwarty. **Kontekst:** body, Files.
- **`q` / `Esc`, `1/2/3`, `y/Y`**: Zamknięcie, karta, kopiowanie. **Kontekst:** shell Volt.
- **`Enter`, `Tab`, `Shift-Tab`**: Kliknięcie i cykl interaktywnych elementów dodany przez Volt. **Kontekst:** shell Volt.
- **`q`, `I`, `y`, `Y`**: Zamknij, komentarz, kopia odpowiedzi, kopia bloku. **Kontekst:** scratch.

### Jaki kontekst jest wysyłany

Prompt zawiera root repozytorium, ścieżkę/etykietę pliku, pozycję kursora, zakres zaznaczenia, zaznaczony tekst, pytanie, tryb answer/comment-now i wymagany schema output. Bez zaznaczenia cała treść pliku nie jest wklejana do promptu; proces CLI startuje z `cwd=repo_root` i może sam przeczytać zapisany plik oraz inne pliki repo.

Konsekwencje prywatności:

- pytanie i zaznaczony kod trafiają jako argument do lokalnego procesu Claude;
- `--permission-mode plan` i prompt proszą o read-only, ale CLI może czytać dodatkowe pliki repo;
- `consulted_files` jest deklaracją modelu, nie niezależnym audytem odczytów;
- każda prośba jest nowym procesem, bez historii rozmowy;
- unnamed buffer bez zaznaczenia nie daje użytecznej ścieżki ani pełnej treści.

Submit jest blokowany dla comment-now z niezapisanym buforem oraz answer bez zaznaczenia w zmodyfikowanym buforze. Answer z Visual może wysłać zaznaczony, niezapisany tekst, ale późniejsze `I` zwykle nie przejdzie kontroli stanu pliku.

### Modele i cykl żądania

- Każdy nowy popup zaczyna od pierwszego modelu. `Tab` cyklicznie idzie tylko naprzód; `Shift-Tab` nie ma mapowania.
- F2 zmienia answer/comment-now tylko gdy request nie jest busy.
- Busy `Ctrl-c` wysyła zakończenie procesu i ustawia UI jako idle. Callback starego procesu nie ma osobnego tokenu generacji, więc po anulowaniu może jeszcze pojawić się spóźniony błąd, a bardzo szybki resubmit ma ryzyko wyścigu.
- Zamknięcie popupu albo zmiana/reopen także anuluje proces. Nie ma lokalnego timeoutu.
- Błąd backendu pozostawia popup z footerem Error, dzięki czemu można poprawić prompt i wysłać ponownie.
- Plugin przechowuje tylko ostatni rekord w pamięci. Nie ma historii konwersacji ani polecenia reopen-last-answer.

### Tutorial: odpowiedź do przeglądu

1. Zaznacz funkcję i użyj `<leader>ac`, albo użyj skrótu bez zaznaczenia na czystym, zapisanym pliku.
2. Wpisz pytanie; `Ctrl-j` tworzy nową linię, `Ctrl-l` czyści, `Tab` zmienia model, `Enter` wysyła.
3. W drawerze `1/2/3` przełącza Answer/Question/Files. `Tab`/`Shift-Tab` robi to samo cyklicznie.
4. `y` kopiuje surową odpowiedź, `Y` buduje i kopiuje preview komentarza bez rygorystycznego sprawdzenia bieżącego stanu pliku.
5. W Files `Enter` otwiera zgłoszoną ścieżkę w splicie. Lista jest model-reported; plugin sprawdza czy plik da się przeczytać, ale nie stanowi audytu bezpieczeństwa i nie gwarantuje, że relative path pozostaje w repo.
6. `o` przenosi odpowiedź do prostszego scratcha. Fallback scratch nie ma kart ani file preview.
7. `I` próbuje wstawić komentarz dla rekordu widocznego w drawerze; `:ClaudeComment` używa globalnie ostatniej odpowiedzi.

### Dokładne zabezpieczenia wstawiania

Przed zapisem plugin sprawdza: obecność source path w rekordzie, modyfikowalny bufor, brak niezapisanych zmian, identyczny `changedtick` jak przy otwarciu popupu, hash dysku równy snapshotowi oraz poprawne `commentstring` z `%s`. Nawet edit + undo zmienia `changedtick` i może konserwatywnie zablokować operację. Nie ma jednak jawnego `filereadable()` ani chronionego odczytu w ścieżce insert: usunięty lub nieczytelny plik może zgłosić `E484` zamiast kontrolowanego fallbacku.

Komentarz nie jest umieszczany przez AST ani model. Trafia po końcu zaznaczenia albo po pierwotnej linii kursora, dziedziczy wcięcie, dostaje prefiks `Claude: `, maksymalnie 6 zawiniętych wierszy po 92 bajty. Marker heading/list jest usuwany; obsługa fenced code nie śledzi pełnego stanu bloku.

> **Ograniczenie semantyczne:** prompt prosi model, aby zwrócił pusty `comment_candidate`, gdy komentarz inline jest niebezpieczny. Obecna implementacja przy pustym kandydacie fallbackuje jednak do pierwszych oczyszczonych linii ogólnej odpowiedzi. Comment-now może więc wstawić komentarz mimo odmowy modelu. Zawsze traktuj wynik jak zwykłą edycję wymagającą review.

### Tutorial: comment-now

1. Upewnij się, że plik jest zapisany i czysty, ustaw kursor lub zaznacz zakres, użyj `<leader>aC`.
2. Przeczytaj badge `comment-now`, wybierz model i wyślij.
3. Gdy kontrole pliku przejdą, writer zapisuje komentarz bez otwierania drawera. Kontrolowana odmowa bezpieczeństwa otwiera drawer; błąd odczytu brakującego lub nieczytelnego pliku może natomiast przerwać operację przez `E484`.
4. Natychmiast obejrzyj bufor, `git diff` oraz, jeśli powstał, `:WatchDiffHistory`. Nie używaj `<leader>ch` przed review.

### Writer i integracja z watchdiff

Writer ponownie czyta i synchronicznie przepisuje cały plik. Nie ma atomowego compare-and-swap ani locka między kontrolą a zapisem. Używa tekstowych `readfile()`/`writefile()`, więc może przy okazji zamienić CRLF na LF, usunąć UTF-8 BOM i dodać końcowy newline. Hash obejmuje znormalizowaną treść linii, a nie reprezentację bajtową, więc nie wykrywa tych zmian; automatyczne komentarze są najbezpieczniejsze w zwykłych plikach LF bez BOM. Przed zapisem writer oznacza następną zmianę w watchdiff, ale historia `source=claude.nvim` powstaje tylko wtedy, gdy watcher działa, widzi ścieżkę, bufor jest czysty, reload się powiedzie, plik mieści się w limicie i diff jest niepusty. To warunkowa adnotacja, nie dowód autorstwa.

Jeżeli watchdiff jest załadowany, ale nie zobaczy eventu, writer nie zawsze wykonuje własny fallback `checktime`; bufor może pozostać chwilowo nieaktualny mimo komunikatu sukcesu. Porównaj dysk i bufor przed kolejną edycją.

### Tryb deweloperski

Autocmd repo ładuje go raz po wejściu do `*/claude.nvim/lua/*.lua`.

- **`<leader>rr`**: Reload modułów i ponowny setup. **Stan:** **Kontekstowe**.
- **`<leader>rt`**: Reload i natychmiastowy popup. **Stan:** **Kontekstowe**.
- **`<leader>rd`**: Debug lista modułów. **Stan:** **Kontekstowe**.

Po aktywacji mapowania deweloperskie są globalne do końca sesji, nie tylko buffer-local. Służą do rozwijania samej wtyczki.

**Wymagania:** zainstalowane i uwierzytelnione CLI `claude`, dostęp do backendu oraz `volt` dla preferowanego drawera. Bez Volt pozostaje scratch fallback.

**Diagnostyka:** `:echo executable('claude')`, ręczne logowanie/wywołanie `claude`, `:messages`, `:verbose nmap <leader>ac`, stan `modified`, `changedtick`, readable source i `commentstring`. Brak wsparcia drawera albo jego zwrot `false` przechodzi do scratch, ale wyjątek podczas tworzenia drawera może przerwać operację bez fallbacku; sprawdź wtedy Volt w `:Lazy`.

**Źródła lokalne:** [README](../../claude.nvim/README.md), [architektura](../../claude.nvim/ARCHITECTURE.md), [budowa promptu](../../claude.nvim/lua/claude/request.lua), [cykl żądania](../../claude.nvim/lua/claude/controller.lua), [kontrole komentarzy](../../claude.nvim/lua/claude/comments.lua), [writer](../../claude.nvim/lua/claude/writer.lua), [drawer](../../claude.nvim/lua/claude/output_drawer.lua).
