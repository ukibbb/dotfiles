# Git: Diffview i CodeDiff

<a id="plugin-diffview"></a>
## `diffview.nvim`

**Co robi i po co:** otwiera kartę z dwu-, trzy- lub czterostronnym diffem, panelem plików, historią oraz narzędziami konfliktów. Najlepiej sprawdza się w przeglądzie wielu plików i merge/rebase.

**Ładowanie lokalne:** po poleceniach Diffview lub `<leader>gv/gm/gl/gL/gq`. Dla plików binarnych wpis pozostaje w panelu, ale `diff_binaries=false` zastępuje treść pustym/null bufferem. Enhanced highlights są włączone, panel jest drzewem po lewej o szerokości 35, a hook wyłącza foldcolumn w buforach diff.

**Aktywne lokalne:** `<leader>gv`, `<leader>gm`, `<leader>gl`, `<leader>gL`, `<leader>gq`. W samym widoku `Tab` skupia panel plików i tym samym celowo zastępuje pinned default przejścia do następnego pliku. `q` zamyka Diffview w widoku, panelu plików i panelu historii. Nawigacja oraz staging panelu korzystają z defaultów przypiętej rewizji.

**Polecenia:** `:DiffviewOpen [rev] [options] [-- paths]`, `:DiffviewFileHistory [paths] [options]`, `:DiffviewClose`, `:DiffviewFocusFiles`, `:DiffviewToggleFiles`, `:DiffviewRefresh`, `:DiffviewLog`.

### Widok diff

- **`Tab`**: Fokus panelu plików. **Źródło:** **Aktywne lokalne**, nadpisuje next file.
- **`q`**: Zamknięcie całego Diffview. **Źródło:** **Aktywne lokalne**.
- **`Shift-Tab`**: Otwórz poprzedni wpis. **Źródło:** **Domyślne wtyczki**.
- **`[F` / `]F`**: Pierwszy / ostatni wpis. **Źródło:** **Domyślne wtyczki**.
- **`gf`**: Otwórz realny plik w poprzedniej karcie. **Źródło:** **Domyślne wtyczki**.
- **`Ctrl-w Ctrl-f` / `Ctrl-w gf`**: Otwórz plik w splicie / nowej karcie. **Źródło:** **Domyślne wtyczki**.
- **`<leader>e` / `<leader>b`**: Fokus / przełączenie panelu plików. **Źródło:** **Domyślne wtyczki**.
- **`g Ctrl-x`**: Następny dostępny layout. **Źródło:** **Domyślne wtyczki**.
- **`[x` / `]x`**: Poprzedni / następny konflikt. **Źródło:** **Kontekstowe**.
- **`<leader>co/ct/cb/ca`**: Ours / theirs / base / wszystkie wersje konfliktu. **Źródło:** **Kontekstowe**.
- **`dx`**: Usuń region konfliktu. **Źródło:** **Kontekstowe**, destrukcyjne dla wyniku.
- **`<leader>cO/cT/cB/cA`**: Ours / theirs / base / wszystkie dla całego pliku. **Źródło:** **Kontekstowe**.
- **`dX`**: Usuń wszystkie regiony konfliktów w pliku. **Źródło:** **Kontekstowe**, destrukcyjne.

Buffer-local `<leader>ca` Diffview oznacza „wybierz wszystkie wersje konfliktu” i w tej karcie ma pierwszeństwo przed akcją kodu LSP.

### Panel plików: pinned defaults zachowane

- **`j` / `Down`, `k` / `Up`**: Następny / poprzedni wpis panelu.
- **`Enter` / `o` / `l` / `2-LeftMouse`**: Otwórz diff wpisu.
- **`-` / `s`**: Toggle stage/unstage zaznaczonego wpisu zależnie od sekcji.
- **`S`**: Stage realnych working/conflict entries widoku.
- **`U`**: Unstage całego repozytorium przez reset indeksu.
- **`X`**: Przywróć wpis do stanu po lewej stronie.
- **`L`**: Panel logu commita.
- **`zo`, `h` / `zc`, `za`, `zR`, `zM`**: Otwórz, zamknij, toggle, otwórz wszystkie, zamknij wszystkie foldy.
- **`Ctrl-b` / `Ctrl-f`**: Przewiń główny widok w górę / w dół.
- **`Tab` / `Shift-Tab`**: Otwórz następny / poprzedni wpis, a nie tylko zmień fokus.
- **`[F` / `]F`**: Pierwszy / ostatni wpis.
- **`gf`, `Ctrl-w Ctrl-f`, `Ctrl-w gf`**: Otwórz realny plik.
- **`i`**: Lista kontra drzewo.
- **`f`**: Flatten directories.
- **`R`**: Odśwież statystyki i wpisy.
- **`<leader>e` / `<leader>b`**: Fokus / toggle panelu.
- **`g Ctrl-x`, `[x`, `]x`, `g?`**: Layout, konflikty, pomoc.
- **`q`**: Zamknij Diffview (**Aktywne lokalne**).

Nie ma lokalnego `u` do cofania stage pojedynczego pliku. Użyj toggle `-`/`s` na wpisie staged albo `U` dla wszystkich.

### Panel historii i layout konfliktów

- **`g!`**: Opcje historii. **Kontekst:** historia.
- **`Ctrl-Alt-d`**: Otwórz zaznaczony commit w osobnym Diffview. **Kontekst:** historia.
- **`y`, `L`**: Kopiuj hash, pokaż szczegóły commita. **Kontekst:** historia.
- **`X`**: Natychmiast przywróć plik do wersji wpisu, jeśli realny bufor nie ma niezapisanych zmian; brak promptu potwierdzenia. **Kontekst:** historia.
- **`j/k`, `Enter/o/l`, foldy, scroll, `Tab/Shift-Tab`, `[F/]F`**: Nawigacja analogiczna do panelu plików. **Kontekst:** historia.
- **`gf`, split/tab, `<leader>e/b`, `g Ctrl-x`, `g?`**: Plik, panel, layout, pomoc. **Kontekst:** historia.
- **`q`**: Zamknij Diffview (**Aktywne lokalne**). **Kontekst:** historia.
- **`2do` / `3do`**: Pobierz hunk z ours / theirs. **Kontekst:** layout diff3 `n,x`.
- **`1do` / `2do` / `3do`**: Pobierz hunk z base / ours / theirs. **Kontekst:** layout diff4 `n,x`.
- **`g?`**: Pomoc właściwa dla layoutu. **Kontekst:** dowolny layout.
- **`Tab`, `q`, `g?`**: Zmień opcję, zamknij, pomoc. **Kontekst:** panel opcji.
- **`q` / `Esc`**: Zamknięcie. **Kontekst:** panel pomocy.

### Tutorial: bieżące zmiany wielu plików

1. Otwórz `<leader>gv`; to właściwy kontekst do stagingu, bo porównuje indeks z worktree.
2. Lokalny `Tab` z widoku ustawia fokus na panelu. `j/k` wybiera plik, `Enter` otwiera diff, `Shift-Tab` przechodzi do poprzedniego wpisu.
3. `-` albo `s` przełącza stage całego wskazanego wpisu zależnie od sekcji. Sprawdź `git status` po operacji.
4. `S` stage'uje realne working/conflict entries widoku, a `U` resetuje cały indeks repozytorium. Nie traktuj ich jak działań ograniczonych do jednego widocznego pliku.
5. `q` albo `<leader>gq` zamyka całą kartę.

### Zaawansowany partial staging przez bufor indeksu

W zwykłym `<leader>gv` lewa strona unstaged diff reprezentuje indeks, prawa worktree. Możesz pobrać wybrany hunk semantyką wbudowanego diff `do`/`dp` do modyfikowalnego bufora indeksu, a następnie zapisać właśnie ten bufor przez `:write`. Jest to bezpośrednia edycja indeksu; po każdym zapisie sprawdź `git diff --cached`. Jeśli nie rozpoznajesz, która strona jest indeksem, użyj prostszego Gitsigns albo Neogit.

### Tutorial: branch review i historia

1. `<leader>gm` otwiera `origin/main...HEAD`, czyli porównanie od merge-base do `HEAD`. Służy do review branch, nie do stagingu.
2. `<leader>gl` pokazuje historię bieżącego pliku, `<leader>gL` całego repo. `g!` zmienia opcje historii, `y` kopiuje hash, `L` pokazuje szczegóły.
3. `Ctrl-Alt-d` otwiera commit w osobnym Diffview. `gf` wraca do realnego pliku.
4. Nie używaj `S/U/X` w historycznym lub branchowym widoku tylko dlatego, że panel je pokazuje. Operacje nadal dotykają realnego repozytorium.

### Tutorial: konflikt merge/rebase

1. Przechodź konflikty `[x` / `]x` i sprawdź etykiety layoutu.
2. Dla regionu wybierz `<leader>co` ours, `<leader>ct` theirs, `<leader>cb` base, `<leader>ca` wszystkie albo `dx` usuń. Wielkie warianty dotyczą całego pliku.
3. W layoutach diff3/diff4 numerowane `do` pobiera hunk ze wskazanej strony.
4. Przejrzyj realny wynik, wykonaj `:write`, sprawdź markery i dopiero wtedy stage'uj.
5. Buffer-local `<leader>ca` oznacza tutaj wszystkie strony konfliktu, nie code action LSP.

### Bezpieczeństwo `X`

`X` w panelu plików może przywrócić wpis do lewej strony. W historii nie ma potwierdzenia: przywrócenie może wykonać odpowiednik checkoutu historycznej wersji ścieżki i zmienić worktree oraz indeks. Wtyczka może wypisać obiekt/komendę odzyskania starej treści, lecz nie jest to pełne undo indeksu. Najpierw zachowaj potrzebne zmiany i nie testuj `X` na ważnym pliku.

**Wymagania:** Neovim z LuaJIT, Git co najmniej 2.31 albo Mercurial co najmniej 5.4; lokalnie Git. Ikony przez `nvim-web-devicons` są opcjonalne.

**Diagnostyka:** `:checkhealth diffview`, `:DiffviewLog`, `:messages`, `:DiffviewRefresh` i jawny ref w `:DiffviewOpen`. Zły zakres najpierw zweryfikuj zwykłym `git rev-parse`/`git diff`, bez operacji przywracania.

**Źródła przypiętej rewizji:** [README](https://github.com/sindrets/diffview.nvim/blob/4516612fe98ff56ae0415a259ff6361a89419b0a/README.md), [pełny help](https://github.com/sindrets/diffview.nvim/blob/4516612fe98ff56ae0415a259ff6361a89419b0a/doc/diffview.txt), [domyślne mapowania](https://github.com/sindrets/diffview.nvim/blob/4516612fe98ff56ae0415a259ff6361a89419b0a/lua/diffview/config.lua).

<a id="plugin-codediff"></a>
## `codediff.nvim`

**Co robi i po co:** VS Code-style side-by-side diff z osobnym podświetleniem linii i znaków, explorerem Git, historią oraz mergetool. Jest wygodny do szczegółowego przeglądu jednego hunka lub pliku.

**Ładowanie lokalne:** po `:CodeDiff` albo `<leader>gD/gf/gh`, z zależnością `nui.nvim`. Biblioteka C algorytmu diff pobiera się automatycznie przy pierwszym użyciu. Bieżąca konfiguracja nie nadpisuje highlightów i korzysta z `line_insert`, `line_delete` oraz automatycznego char highlight z defaultów wtyczki.

**Aktywne lokalne:** `<leader>gD` uruchamia `CodeDiff`; `<leader>gf` uruchamia dokładnie `CodeDiff file HEAD`; `<leader>gh` uruchamia dokładnie `CodeDiff history %`.

**Polecenie i tryby:** `:CodeDiff`, `:CodeDiff {rev}`, `:CodeDiff {rev1} {rev2}`, `:CodeDiff file {rev} [rev2]`, `:CodeDiff file {file_a} {file_b}`, `:CodeDiff dir {dir1} {dir2}`, `:CodeDiff {dir1} {dir2}`, `:CodeDiff history [range] [file]`, `:CodeDiff merge {file}`, `:CodeDiff install`, `:CodeDiff install!`. Po załadowaniu dostępny jest też zgodnościowy alias `:VscodeDiff` o tej samej składni.

### Widok i explorer

- **`q`**: Zamknij kartę CodeDiff. **Kontekst:** cała karta.
- **`<leader>b`**: Pokaż/ukryj explorer. **Kontekst:** explorer mode.
- **`]c` / `[c`**: Następny / poprzedni hunk. **Kontekst:** diff.
- **`]f` / `[f`**: Następny / poprzedni plik. **Kontekst:** explorer mode.
- **`do`**: Pobierz hunk z **drugiego** bufora do bieżącego. **Kontekst:** modyfikowalny diff.
- **`dp`**: Wyślij hunk z bieżącego bufora do **drugiego**. **Kontekst:** modyfikowalny diff.
- **`gf`**: Otwórz realny bufor w poprzedniej karcie; wirtualna rewizja nie ma pliku do otwarcia. **Kontekst:** diff.
- **`-`**: Stage/unstage bieżącego pliku lub wpisu; konflikt stage oznacza resolved. **Kontekst:** explorer mode.
- **`Enter`**: Wybór pliku/katalogu. **Kontekst:** explorer.
- **`K`**: Szczegóły/hover wpisu. **Kontekst:** explorer.
- **`R`**: Odświeżenie. **Kontekst:** explorer.
- **`i`**: Przełączenie płaskiej listy i drzewa, nie ignored files. **Kontekst:** explorer.
- **`S` / `U`**: Stage all / unstage all. **Kontekst:** explorer.
- **`X`**: Dla unstaged: discard do indeksu/HEAD; dla untracked: usuń po potwierdzeniu. **Kontekst:** explorer.
- **`Enter`**: Rozwiń commit albo otwórz jego plik/diff. **Kontekst:** historia.
- **`i`**: Przełączenie listy/drzewa plików historii. **Kontekst:** historia.

`do` i `dp` zależą od bieżącego okna, a nie od stałej etykiety ours/theirs. W `:CodeDiff file HEAD` lewa rewizja jest readonly, ale prawa strona jest realnym, modyfikowalnym plikiem. `do` wykonane po prawej może więc pobrać hunk z `HEAD` i zmienić plik.

### Modyfikowalność trybów

- **`CodeDiff file HEAD`**: **Strona lewa:** wirtualny `HEAD`, readonly. **Strona prawa:** bieżący realny plik, edytowalny.
- **`CodeDiff file REV1 REV2`**: **Strona lewa:** readonly. **Strona prawa:** readonly.
- **`CodeDiff file FILE1 FILE2`**: **Strona lewa:** realny, edytowalny. **Strona prawa:** realny, edytowalny.
- **zwykły explorer `CodeDiff`**: **Strona lewa:** zależy od wybranego wpisu. **Strona prawa:** realny stan repo albo rewizja.

### Konflikty CodeDiff

- **`<leader>ct`**: Accept incoming, czyli theirs po lewej.
- **`<leader>co`**: Accept current, czyli ours po prawej.
- **`<leader>cb`**: Accept both: inteligentne połączenie zmian jak VS Code; kolejność zaczyna się od strony, na której jest kursor, a fallback konkatenacji zachowuje tę kolejność.
- **`<leader>cx`**: Discard obu stron konfliktu i przywrócenie zawartości **base**; działa także na wcześniej rozwiązanym bloku.
- **`]x` / `[x`**: Następny / poprzedni konflikt.
- **`2do` w result buffer**: Pobierz incoming/theirs do wyniku.
- **`3do` w result buffer**: Pobierz current/ours do wyniku.

W conflict mode zwykłe `do`/`dp` są usuwane. Akcje `<leader>ct/co/cb/cx` wykonuj z lewej lub prawej strony; mimo mapowania w result buffer implementacja je tam odrzuca. W result buffer używaj `2do` albo `3do`.

### Tutorial: jeden plik kontra `HEAD`

1. Zapisz bieżący plik i naciśnij `<leader>gf`.
2. Przechodź hunki `]c` / `[c`. Lewa strona to `HEAD`, prawa to realny plik.
3. Na prawej stronie `do` pobiera hunk z lewej i odrzuca tę część bieżącej zmiany. To realna edycja; użyj tylko świadomie, potem zapisz albo cofnij `u`.
4. `gf` wraca do realnego bufora w poprzedniej karcie, a `q` zamyka całą kartę CodeDiff.

### Tutorial: explorer, historia i katalogi

1. `<leader>gD` otwiera explorer bieżącego statusu. `Enter` wybiera plik, `]f/[f` przechodzi, `<leader>b` ukrywa panel.
2. W zwykłym statusie `-` przełącza cały plik, `S` wykonuje `git add -A`, a `U` odpowiednik `git reset HEAD` dla całego repo.
3. `<leader>gh` pokazuje historię bieżącego pliku; domyślnie do 100 commitów i bez merge commitów. `Enter` rozwija commit i pliki.
4. `:CodeDiff file REV1 REV2` porównuje dwa snapshoty, a `:CodeDiff file FILE1 FILE2` dwa realne pliki.
5. `:CodeDiff dir DIR1 DIR2` skanuje rekurencyjnie katalogi; wykrywanie zmian pliku bazuje na rozmiarze i mtime, więc nie jest kryptograficzną weryfikacją identyczności.

### Staging w widokach historycznych

W explorerze otwartym dla rewizji wpisy mogą nadal wyglądać jak grupa unstaged, ale `-`, `S`, `U` i `X` operują na realnym indeksie/worktree, nie na historycznym snapshotcie. Używaj ich wyłącznie w zwykłym `:CodeDiff` bez argumentów. `X` dla tracked wykonuje restore, a dla untracked może wykonać usunięcie przez Git po promptcie.

### Tutorial: mergetool

1. Otwórz conflict mode odpowiednim `:CodeDiff merge plik` lub integracją Git.
2. Z lewej/prawej strony wybierz incoming/current/both/base przez `<leader>ct/co/cb/cx` i przechodź `]x/[x`.
3. W result buffer używaj `2do` incoming lub `3do` current.
4. Zapisz result buffer przez `:write`, przeczytaj wynik i dopiero potem stage'uj plik.

**Bezpieczeństwo:** `X` może skasować nieśledzony plik lub odrzucić unstaged. `<leader>cx` nie oznacza „usuń markery”, lecz reset konkretnego konfliktu do base. `S` i `U` działają na całym repo. Zawsze sprawdź `git status` i realny result buffer.

**Wymagania:** zapisany plik w repo Git dla trybu rewizji, `curl` albo `wget` do pobrania biblioteki C, Git dla explorera/historii.

**Diagnostyka:** `:CodeDiff install` pobiera brakującą bibliotekę, `:CodeDiff install!` wymusza reinstalację. Dalej użyj `:messages`, sprawdź Git i zapisany plik. Wtyczka nie ma osobnego health/log command. Alias `:VscodeDiff` pojawia się dopiero po załadowaniu CodeDiff.

**Źródła przypiętej rewizji:** [README](https://github.com/esmuellert/codediff.nvim/blob/32ccb9b66645b3b93148854b9b4421770709ad20/README.md), [pełny help](https://github.com/esmuellert/codediff.nvim/blob/32ccb9b66645b3b93148854b9b4421770709ad20/doc/codediff.txt), [akcje explorera](https://github.com/esmuellert/codediff.nvim/blob/32ccb9b66645b3b93148854b9b4421770709ad20/lua/codediff/ui/explorer/actions.lua), [akcje konfliktów](https://github.com/esmuellert/codediff.nvim/blob/32ccb9b66645b3b93148854b9b4421770709ad20/lua/codediff/ui/conflict/actions.lua).
