# Telescope i nvim-tree

<a id="plugin-telescope"></a>
## `telescope.nvim`

**Co robi i po co:** fuzzy finder plików, tekstu, buforów, pomocy, Git i LSP. Ładuje się po `:Telescope` albo po jednym z lokalnych mapowań.

**Konfiguracja lokalna:** układ 87% szerokości i 80% wysokości, prompt u góry, preview 55%, wyniki rosnąco. Pliki ukryte są widoczne, `.git/` jest ignorowane, `live_grep` dodaje `--hidden`. Lokalne mapowania pickerów: `Alt-j`, `Alt-k` w Insert i `q` w Normal.

**Aktywne launchery:** `<leader>ff`, `<leader>fa`, `<leader>fw`, `<leader>fW`, `<leader>fb`, `<leader>fh`, `<leader>ma`, `<leader>fo`, `<leader>fz`, `<leader>fZ`, `<leader>cm`, `<leader>gt`. `<leader>th` używa osobnego pickera NvChad i nie dziedziczy mapowań Telescope.

### Domyślne klawisze pickera

- **`Ctrl-n` / `Down`, `Ctrl-p` / `Up`**: Następny / poprzedni wynik. **Tryb:** `i`.
- **`Enter`**: Domyślna akcja pickera. **Tryb:** `i,n`.
- **`Ctrl-x`, `Ctrl-v`, `Ctrl-t`**: Split poziomy, split pionowy, nowa karta. **Tryb:** `i,n`.
- **`Ctrl-u`, `Ctrl-d`**: Preview w górę / w dół. **Tryb:** `i,n`.
- **`Ctrl-f`, `Ctrl-k`**: Preview w lewo / w prawo. **Tryb:** `i,n`.
- **`PageUp`, `PageDown`**: Lista wyników w górę / w dół. **Tryb:** `i,n`.
- **`Alt-f`, `Alt-k`**: Lista wyników w lewo / w prawo; lokalne `Alt-k` w `i` nadpisuje to ruchem wyboru. **Tryb:** `i,n`.
- **`Tab`, `Shift-Tab`**: Zaznacz i idź do gorszego / lepszego wyniku. **Tryb:** `i,n`.
- **`Ctrl-q`**: Wszystkie wyniki do quickfix i otwarcie listy. **Tryb:** `i,n`.
- **`Alt-q`**: Tylko zaznaczone wyniki do quickfix i otwarcie listy. **Tryb:** `i,n`.
- **`Ctrl-/` lub kod `Ctrl-_`**: Podgląd mapowań. **Tryb:** `i`.
- **`Ctrl-c`**: Zamknięcie. **Tryb:** `i`.
- **`Ctrl-r Ctrl-w/a/f/l`**: Wstawienie bieżącego word/WORD/pliku/wiersza do promptu. **Tryb:** `i`.
- **`j/k`, `H/M/L`, `gg/G`**: Ruch i skoki po wynikach. **Tryb:** `n`.
- **`?`, `Esc`, lokalne `q`**: Pomoc / zamknięcie. **Tryb:** `n`.

### Git pickery

- **`Enter`**: `git checkout` wybranego commita, zwykle detached `HEAD`. **Picker:** `git_commits` (`<leader>cm`).
- **`Ctrl-r m`**: Potwierdzony `git reset --mixed` do commita: przesuwa `HEAD`, resetuje indeks, zachowuje pliki robocze. **Picker:** `git_commits`.
- **`Ctrl-r s`**: Potwierdzony `git reset --soft`: przesuwa `HEAD`, zachowuje indeks i pliki robocze. **Picker:** `git_commits`.
- **`Ctrl-r h`**: Potwierdzony `git reset --hard`: przesuwa `HEAD` i odrzuca śledzone zmiany indeksu oraz drzewa roboczego. **Picker:** `git_commits`.
- **`Tab`**: Stage albo unstage zaznaczonego pliku; zastępuje tu zwykły multiselect. **Picker:** `git_status` (`<leader>gt`).
- **`Enter`**: Otwarcie pliku. **Picker:** `git_status`.
- **`Enter`, `Ctrl-t`, `Ctrl-r`, `Ctrl-a`, `Ctrl-s`, `Ctrl-d`, `Ctrl-y`**: Checkout, track, rebase, utwórz, `git switch`, usuń, merge; w tmux `Ctrl-s` wymaga `Ctrl-s Ctrl-s`. **Picker:** `git_branches`.

**Polecenie:** `:Telescope {builtin} [opcje]`, na przykład `:Telescope resume`, `:Telescope lsp_references`, `:Telescope git_branches`. To jedno publiczne polecenie udostępnia builtiny i rozszerzenia.

**Wymagania:** Neovim co najmniej 0.10.4, `ripgrep` dla live grep, `fd` dla szybkiego find files, Git dla pickerów Git. Wszystkie trzy executable są przewidziane przez środowisko repo.

### Mentalny model pickera

Picker składa się z promptu, listy wyników i preview. Startuje w Insert, aby od razu filtrować. `Esc` przechodzi do Normal, a dopiero kolejne `Esc` lub lokalne `q` zamyka. Domyślna akcja `Enter` zależy od pickera: zwykle otwiera plik, lecz w `git_commits` wykonuje checkout, a w `git_status` otwiera wskazany plik.

`Tab` nie oznacza zwykłego ruchu: zaznacza element i przechodzi dalej. `Ctrl-q` wysyła wszystkie wyniki do quickfix, `Alt-q` tylko jawnie zaznaczone. Po zamknięciu pickera `[q` / `]q` nawiguje listę.

### Katalog builtinów dostępnych przez `:Telescope`

- **pliki i tekst**: `grep_string`, `git_files`, `search_history`, `command_history`.
- **stan Neovim**: `commands`, `keymaps`, `registers`, `jumplist`, `quickfix`, `loclist`, `diagnostics`, `autocommands`, `filetypes`.
- **LSP**: `lsp_definitions`, `lsp_implementations`, `lsp_type_definitions`, `lsp_document_symbols`, `lsp_workspace_symbols`, `lsp_dynamic_workspace_symbols`, `lsp_incoming_calls`, `lsp_outgoing_calls`.
- **Git**: `git_bcommits`, `git_branches`, `git_stash` oraz lokalnie używane `git_commits`, `git_status`.
- **składnia i historia**: `treesitter`, `pickers`, `resume`, `builtin`.
- **rozszerzenia UI**: `themes` i `terms` dostarczane przez NvChad UI po dynamicznym załadowaniu.

`builtin` pozwala wybrać nazwę pickera z listy, `pickers` pokazuje wcześniejsze pickery, a `resume` wraca do ostatniego promptu i stanu. Opcje można dopisać po nazwie, na przykład `:Telescope find_files hidden=true no_ignore=true`.

### Tutorial: plik, split i bufor

1. Uruchom Neovim w root projektu; domyślny CWD jest punktem wyszukiwania.
2. `<leader>ff` pokazuje także dotfiles, ale respektuje ignore. `<leader>fa` dodatkowo ignoruje reguły ignore i śledzi symlinki, więc może zwrócić bardzo dużo wyników.
3. Filtruj fragmentem ścieżki. `Enter` otwiera normalnie, `Ctrl-v` pionowo, `Ctrl-x` poziomo, a `Ctrl-t` w nowej karcie.
4. `<leader>fb` przełącza już otwarte bufory, a `<leader>fo` wraca do historii plików.

### Tutorial: wyszukiwanie i lista wyników

1. `<leader>fw` uruchamia ripgrep w projekcie z plikami ukrytymi poza wnętrzem `.git/`. `<leader>fW` zaczyna od słowa pod kursorem.
2. Zaznacz kilka trafień `Tab`; `Shift-Tab` cofa zaznaczenie/ruch.
3. Wyślij wybrane `Alt-q`, zamknij picker i przechodź `[q` / `]q`. `:copen` pokazuje całą listę.
4. Dla bieżącego pliku użyj `<leader>fz` albo `<leader>fZ`; ten picker nie uruchamia ripgrep po całym projekcie.
5. `:Telescope resume` przywraca ostatni picker, co jest wygodne po obejrzeniu jednego wyniku.

### Bezpieczeństwo pickerów Git

`<leader>cm` nie jest tylko przeglądarką: `Enter` checkoutuje commit, a `Ctrl-r m/s/h` resetuje bieżącą gałąź. `<leader>gt` zmienia indeks przez `Tab`. Przed akcją sprawdź nagłówek pickera, `git status` i listę akcji Git powyżej. Do bezpiecznego samego podglądu historii lepszy bywa Diffview albo CodeDiff.

**Diagnostyka:** `:checkhealth telescope`, `:echo executable('fd')`, `:echo executable('rg')`, `:pwd` i `:messages`. Brak wyników w `<leader>ff` może wynikać z ignore; porównaj `<leader>fa`. `Ctrl-/` w Insert albo `?` w Normal pokazuje mapowania konkretnego pickera.

**Źródła przypiętej rewizji:** [README](https://github.com/nvim-telescope/telescope.nvim/blob/a8c2223ea6b185701090ccb1ebc7f4e41c4c9784/README.md), [pełny help](https://github.com/nvim-telescope/telescope.nvim/blob/a8c2223ea6b185701090ccb1ebc7f4e41c4c9784/doc/telescope.txt), [builtiny](https://github.com/nvim-telescope/telescope.nvim/blob/a8c2223ea6b185701090ccb1ebc7f4e41c4c9784/lua/telescope/builtin/init.lua).

<a id="plugin-nvim-tree"></a>
## `nvim-tree.lua`

**Co robi i po co:** boczne drzewo plików z ikonami, statusem Git i operacjami plikowymi. Netrw jest wyłączone. Wtyczka ładuje się po lokalnych klawiszach albo poleceniach.

**Konfiguracja lokalna:** lewa strona, szerokość 35, synchronizacja root z cwd, śledzenie aktywnego pliku bez zmiany root, Git włączony, `.DS_Store` i `.git` w filtrze niestandardowym. Watchery ignorują `.next`, `node_modules`, `.git`. Otwieranie pliku nie zamyka drzewa.

**Aktywne lokalne:** `<leader>e` toggle, `<leader>E` reveal bieżącego pliku; w drzewie fizyczne `Cmd-\` i `Cmd--` otwierają pionowy/poziomy split. Wszystkie poniższe defaulty są instalowane przed lokalnymi dodatkami.

- **`Enter` / `o`**: Otwórz; `O` otwiera bez wyboru okna; `Tab` preview.
- **`Ctrl-v` / `Ctrl-x` / `Ctrl-t`**: Split pionowy / poziomy / karta.
- **`Ctrl-]`**: Ustaw root na node; `-` root wyżej; `P` rodzic.
- **`Ctrl-e`**: Otwórz node w miejscu bufora drzewa.
- **`Ctrl-k`**: Informacje o node.
- **`Backspace`**: Zamknij katalog; `E` rozwiń wszystko; `W` zwiń wszystko.
- **`>` / `<`, `J` / `K`**: Następny/poprzedni oraz ostatni/pierwszy sibling.
- **`a`**: Utwórz plik lub katalog.
- **`r`, `e`, `u`, `Ctrl-r`**: Rename pełny, basename, pełna ścieżka, bez nazwy pliku.
- **`c`, `x`, `p`**: Copy, cut, paste.
- **`d` / `Del`, `D`**: Usuń / przenieś do kosza.
- **`y`, `Y`, `gy`, `ge`**: Nazwa, ścieżka względna, absolutna, basename.
- **`m`, `bd`, `bt`, `bmv`**: Bookmark; usuń, trash, przenieś zaznaczone bookmarki.
- **`H`**: Przełącz filtr dotfiles.
- **`I`**: Przełącz filtr `.gitignore`.
- **`U`**: Przełącz filtr **niestandardowy**, opisany w UI jako Hidden; lokalnie odsłania/chowa `.DS_Store` i `.git`, nie wszystkie dotfiles.
- **`B`, `C`, `M`**: Filtry no-buffer, git-clean, no-bookmark.
- **`[c` / `]c`**: Poprzedni / następny wpis Git.
- **`[e` / `]e`**: Poprzednia / następna diagnostyka.
- **`f` / `F`**: Start / wyczyszczenie live filter.
- **`L`**: Przełącz grupowanie pustych katalogów.
- **`.`**: Prompt polecenia; `s` uruchom program systemowy; `S` wyszukaj node.
- **`R`**: Odśwież; `q` zamknij; `g?` pomoc.
- **`2-LeftMouse` / `2-RightMouse`**: Otwórz / ustaw root.

**Polecenia:** `:NvimTreeOpen [dir]`, `:NvimTreeClose`, `:NvimTreeToggle [dir]`, `:NvimTreeFocus`, `:NvimTreeRefresh`, `:NvimTreeClipboard`, `:NvimTreeFindFile[!]`, `:NvimTreeFindFileToggle[!] [dir]`, `:NvimTreeResize {width}`, `:NvimTreeCollapse`, `:NvimTreeCollapseKeepBuffers`, `:NvimTreeHiTest`. Początkowymi triggerami Lazy są tylko `NvimTreeToggle`, `NvimTreeFocus` i `NvimTreeFindFile`; pozostałe polecenia pojawiają się po załadowaniu wtyczki.

**Bezpieczeństwo:** `d`, `Del`, `D`, `bd` i `bt` usuwają albo przenoszą pliki; sprawdź node i potwierdzenie. Cut nie zmienia dysku do `p`, lecz wynik paste może nadpisać/kolizjonować.

**Wymagania:** `nvim-web-devicons` i Nerd Font dla ikon, Git dla statusów.

### Root, fokus i reveal

- `<leader>e` przełącza drzewo bez gwarancji odsłonięcia bieżącego pliku.
- `<leader>E` otwiera potrzebne katalogi i ustawia kursor na bieżącym lokalnym pliku.
- Root synchronizuje się z CWD przy jego zmianie, ale samo śledzenie aktywnego pliku nie zmienia root.
- `Ctrl-]` ustawia wskazany katalog jako root, `-` idzie poziom wyżej, a `P` tylko przechodzi na node rodzica.

### Tutorial: utworzenie i otwarcie pliku

1. Użyj `<leader>E`, aby zobaczyć położenie bieżącego pliku, albo `<leader>e` do zwykłego toggle.
2. `a` otwiera prompt tworzenia. Ścieżka zakończona `/` tworzy katalog, pozostała plik; przeczytaj prompt przed zatwierdzeniem.
3. `Enter` otwiera w wybranym oknie, `Ctrl-v` pionowo, `Ctrl-x` poziomo, `Ctrl-t` w karcie, a `Tab` robi preview bez trwałego opuszczenia drzewa.
4. Fizyczne `Cmd-\` i `Cmd--` są lokalnymi odpowiednikami splitów w tym buforze.
5. `q` zamyka panel, ale otwarte pliki pozostają buforami.

### Tutorial: rename, copy, cut i bookmarki

1. `r` zmienia pełną nazwę, `e` basename, `u` pełną ścieżkę, a `Ctrl-r` usuwa nazwę pliku z początkowego promptu. Sprawdź docelową ścieżkę.
2. `c` kopiuje node do wewnętrznego schowka nvim-tree, `x` zaznacza cut, a `p` wykonuje operację w wskazanym katalogu. `:NvimTreeClipboard` pokazuje stan schowka.
3. `m` przełącza bookmark. `bmv` przenosi zaznaczone bookmarki, `bd` usuwa, a `bt` przenosi do kosza; prefiks `b` nie czyni operacji bezpieczną.
4. `y/Y/gy/ge` kopiuje różne warianty nazwy i ścieżki, bez modyfikowania dysku.

### Filtry, Git i diagnostyka

1. Gdy pliku nie widać, kolejno sprawdź `H` dla dotfiles, `I` dla `.gitignore` i `U` dla lokalnego filtra `.DS_Store`/`.git`.
2. `C` ukrywa lub pokazuje pliki Git clean, `B` node bez bufora, `M` elementy bez bookmarka.
3. `[c` / `]c` przechodzi po statusach Git, `[e` / `]e` po diagnostyce.
4. `f` uruchamia live filter nazw w już zbudowanym drzewie, `F` go czyści; nie jest to wyszukiwanie zawartości plików.
5. `g?` jest najpewniejszą pomocą, ponieważ pokazuje mapowania po lokalnym `on_attach`.

### Operacje destrukcyjne

`d`/`Del` usuwa po ścieżce potwierdzenia, `D` wysyła do skonfigurowanego kosza, a `bd`/`bt` działa na bookmarkach. `s` uruchamia program systemowy, a `.` prompt polecenia w katalogu node. Nie używaj ich do diagnozy. Po każdej operacji sprawdź ścieżkę, komunikat i w repo także `git status`.

**Diagnostyka:** `R` odświeża, `:NvimTreeHiTest` sprawdza highlighty, `:NvimTreeRefresh` działa po załadowaniu, a `:messages` pokazuje błędy watchera i operacji. Na zimnym starcie Lazy zna tylko trzy polecenia-trigger: `NvimTreeToggle`, `NvimTreeFocus`, `NvimTreeFindFile`; pozostałe pojawiają się po pierwszym załadowaniu.

**Źródła przypiętej rewizji:** [README](https://github.com/nvim-tree/nvim-tree.lua/blob/037d89e60fb01a6c11a48a19540253b8c72a3c32/README.md), [pełny help i mapowania](https://github.com/nvim-tree/nvim-tree.lua/blob/037d89e60fb01a6c11a48a19540253b8c72a3c32/doc/nvim-tree-lua.txt), [publiczne API](https://github.com/nvim-tree/nvim-tree.lua/blob/037d89e60fb01a6c11a48a19540253b8c72a3c32/lua/nvim-tree/api.lua).
