# Git: Gitsigns, Unified i Neogit

<a id="plugin-gitsigns"></a>
## `gitsigns.nvim`

**Co robi i po co:** pokazuje dodane, zmienione i usunięte linie w signcolumn oraz blame bieżącego wiersza. Jest lekkim podglądem zmian bieżącego pliku, nie pełnym klientem Git.

**Ładowanie lokalne:** `User FilePost`. Efektywne znaki tej rewizji to między innymi `┃` dla add/change, lokalne ikony dla delete/changedelete, `▔` dla topdelete i `┆` dla untracked. `current_line_blame=true`, opóźnienie 300 ms, tekst na końcu wiersza.

**Aktywne mapowania:** brak globalnych lub buffer-local z konfiguracji. Gitsigns nie instaluje domyślnej warstwy klawiszy. Popup otwarty przez akcję ma kontekstowe `q` do zamknięcia.

**Polecenie:** `:Gitsigns {subcommand}`. Użyteczne subcommandy przypiętej rewizji: `stage_hunk`, `stage_buffer`, `reset_hunk`, `reset_buffer`, `preview_hunk`, `preview_hunk_inline`, `nav_hunk next`, `nav_hunk prev`, `blame`, `blame_line`, `toggle_current_line_blame`, `change_base`, `diffthis`, `toggle_word_diff`, `setqflist`, `setloclist`, `show`, `toggle_signs`, `toggle_numhl`, `toggle_linehl`.

> `reset_hunk` i `reset_buffer` odrzucają zmiany. `stage_hunk` na znaku staged działa w tej wersji jak cofnięcie stage danego hunka.

### README: przykład, który nie jest aktywny

Poniższe klawisze są **Przykładem nieaktywnym**, bo lokalny `configs/gitsigns.lua` nie definiuje `on_attach`:

- **`]c` / `[c`**: Następny / poprzedni hunk; w oknie diff delegacja do wbudowanego ruchu diff.
- **`<leader>hs` w `n,v`**: Stage hunka / zakresu.
- **`<leader>hr` w `n,v`**: Reset hunka / zakresu.
- **`<leader>hS` / `<leader>hR`**: Stage / reset bufora.
- **`<leader>hp` / `<leader>hi`**: Preview zwykły / inline.
- **`<leader>hb`**: Pełny blame wiersza.
- **`<leader>hd` / `<leader>hD`**: Diff z indeksem / poprzednim commitem.
- **`<leader>hQ` / `<leader>hq`**: Quickfix całego repo / bieżącego bufora.
- **`<leader>tb` / `<leader>tw`**: Blame bieżącej linii / word diff.
- **`ih` w `o,x`**: Text object hunka.

**Wymagania:** plik w repozytorium Git; signcolumn jest globalnie włączone.

### Mentalny model

Domyślną bazą jest indeks Git. Znak pokazuje różnicę bieżącego bufora względem indeksu, niekoniecznie względem `HEAD`. Po stage hunka może pojawić się stan staged, a kolejne `stage_hunk` na takim znaku działa jak unstage tego hunka.

### Tutorial: przegląd i częściowy stage

1. Zmień śledzony plik i obserwuj signcolumn oraz blame po około 300 ms.
2. `:Gitsigns preview_hunk_inline` pokazuje usunięcia i zmiany inline; `:Gitsigns preview_hunk` otwiera popup zamykany `q`.
3. Przechodź `:Gitsigns nav_hunk next` i `:Gitsigns nav_hunk prev`. Nie myl ich z nieaktywnymi lokalnie `[c`/`]c` z przykładu README.
4. Aby stage'ować cały bieżący hunk, wykonaj `:Gitsigns stage_hunk`. Dla części zakresu zaznacz linie w Visual i wykonaj zakresowe `:Gitsigns stage_hunk`.
5. Natychmiast sprawdź `git diff --cached`; Gitsigns zmienia indeks, ale nie tworzy commita.

### Reset, baza i listy

- `reset_hunk` i `reset_buffer` zmieniają treść bufora względem indeksu. Zapis utrwala odrzucenie; przed akcją zachowaj potrzebne zmiany.
- `change_base REV` porównuje z inną rewizją, a `change_base` bez poprawnego ref może zmienić interpretację wszystkich znaków.
- `setqflist` i `setloclist` budują listy hunków do nawigacji; `blame` otwiera pełniejszy widok historii, `blame_line` szczegół linii.
- `toggle_current_line_blame`, `toggle_word_diff`, `toggle_signs`, `toggle_numhl` i `toggle_linehl` zmieniają tylko sposób prezentacji.

**Diagnostyka:** `:Gitsigns refresh`, `:messages`, `git status` i `:lua =vim.b.gitsigns_status_dict`. Brak znaków może oznaczać plik poza repo, nieśledzony stan, brak attach albo bazę równą treści.

**Źródła przypiętej rewizji:** [README](https://github.com/lewis6991/gitsigns.nvim/blob/42d6aed4e94e0f0bbced16bbdcc42f57673bd75e/README.md), [help](https://github.com/lewis6991/gitsigns.nvim/blob/42d6aed4e94e0f0bbced16bbdcc42f57673bd75e/doc/gitsigns.txt), [polecenia i API](https://github.com/lewis6991/gitsigns.nvim/blob/42d6aed4e94e0f0bbced16bbdcc42f57673bd75e/lua/gitsigns/actions.lua).

<a id="plugin-unified"></a>
## `unified.nvim`

**Co robi i po co:** pokazuje unified diff bezpośrednio w zwykłym buforze i otwiera boczne drzewo zmienionych plików. Dobrze nadaje się do szybkiego przeglądu bez dwóch kolumn.

**Ładowanie lokalne:** po `:Unified` lub `<leader>gd`, z domyślnymi opcjami i auto-refresh.

**Aktywne lokalne:** `<leader>gd` otwiera albo odświeża widok względem `HEAD`; nie jest przełącznikiem zamknięcia. Po zbudowaniu drzewa wtyczka automatycznie otwiera pierwszy zmieniony plik w głównym oknie, więc nie musi to być plik, z którego wywołano skrót.

- **`j` / `Down`, `k` / `Up`**: Następny / poprzedni plik, z pominięciem węzłów katalogu. **Stan:** **Domyślne wtyczki**.
- **`l`**: Otwórz/przełącz node i diff pliku. **Stan:** **Domyślne wtyczki**.
- **`R`**: Odśwież. **Stan:** **Domyślne wtyczki**.
- **`q`**: Zamknij drzewo. **Stan:** **Domyślne wtyczki**.
- **`?`**: Pomoc; w pomocy `Spacja`, `q`, `Enter`, `Esc` zamykają. **Stan:** **Domyślne wtyczki**.

**Polecenia:** `:Unified`, `:Unified {commit_ref}`, `:Unified reset`.

Upstream pokazuje własne mapowania nawigacji i stage/unstage/revert hunka jako **Przykład nieaktywny**. API hunk actions nie jest poleceniem Ex ani lokalnym mapowaniem.

**Wymagania:** Neovim, Git i Nerd Font dla ikon.

### Tutorial: szybki inline review

1. Naciśnij `<leader>gd`. Drzewo zawiera zmienione pliki i automatycznie otwiera pierwszy z nich w głównym oknie z unified diff względem `HEAD`; plik początkowy może zostać zastąpiony.
2. W drzewie przechodź `j/k`, otwieraj `l`, odśwież `R`, a `?` pokaże pomoc.
3. `q` zamyka tylko drzewo. Inline diff nadal pozostaje aktywny w buforze.
4. `:Unified reset` usuwa znaki, extmarki i hunki tylko z bieżącego bufora oraz zamyka aktywne drzewo. Wykonaj je osobno w każdym odwiedzonym pliku, który nadal ma markery.
5. `:Unified HEAD~1` porównuje z pojedynczym refem. Ta rewizja nie interpretuje zakresów `A..B` jak pełny viewer branchy.

### Ograniczenia hunk actions

Upstreamowe przykłady stage/unstage/revert nie są mapowane. Ich API buduje patch na podstawie dyskowego `git diff`, może wybrać najbliższy hunk, a następnie wykonać przeładowanie `edit!`; przy niezapisanym buforze grozi to utratą pracy. Do stagingu używaj tutaj Gitsigns lub Neogit, a Unified traktuj jako czytelny podgląd.

**Diagnostyka:** `git rev-parse --verify REF`, `git status`, `:messages`, `R` w drzewie i `:Unified reset` w każdym buforze z markerami. Ponowne `<leader>gd` nie zamyka widoku.

**Źródła przypiętej rewizji:** [README](https://github.com/axkirillov/unified.nvim/blob/6b9d94b83cdaf7a33afeb1d66a9de386f02d8c55/README.md), [help](https://github.com/axkirillov/unified.nvim/blob/6b9d94b83cdaf7a33afeb1d66a9de386f02d8c55/doc/unified.txt), [obsługa polecenia](https://github.com/axkirillov/unified.nvim/blob/6b9d94b83cdaf7a33afeb1d66a9de386f02d8c55/lua/unified/command.lua).

<a id="plugin-neogit"></a>
## `neogit`

**Co robi i po co:** pełny, inspirowany Magit klient Git: status, staging hunka/pliku, commit, branch, pull/push, log, rebase i stash. Lokalnie otwiera się w nowej karcie i integruje z Telescope oraz Diffview.

**Ładowanie lokalne:** po `:Neogit` lub lokalnych `<leader>gg`, `<leader>gc`, `<leader>gp`, `<leader>gP`, `<leader>gb`. File watcher odświeża status, hinty są widoczne, graf jest Unicode, commit editor otwiera kartę i pokazuje staged diff.

**Polecenia:** `:Neogit [popup] [kind=tab|split|vsplit|floating|...] [cwd=...]`, `:NeogitResetState`, `:NeogitLogCurrent [path]` także z zakresem, `:NeogitCommit [sha]`. Pierwszy argument pozycyjny `commit`, `push`, `pull` lub `branch` wybiera popup, a nie rodzaj okna.

### Finder Neogit: dokładne defaulty

- **`Enter`**: `Select`.
- **`Ctrl-c` / `Esc`**: `Close`.
- **`Ctrl-n` / `Down`**: `Next`.
- **`Ctrl-p` / `Up`**: `Previous`.
- **`Tab`**: `InsertCompletion`, nie multiselect.
- **`Ctrl-y`**: `CopySelection`, nie zatwierdzenie wielu pozycji.
- **`Spacja` / `Shift-Spacja`**: Multiselect i ruch do następnej / poprzedniej pozycji.
- **`Ctrl-j`**: `NOP`, nie ruch w dół.
- **`ScrollWheelDown` / `ScrollWheelUp`**: Scroll w dół / górę.
- **`ScrollWheelLeft` / `ScrollWheelRight`**: `NOP`.
- **`LeftMouse`**: Wybór pozycji.
- **`2-LeftMouse`**: `NOP`.

### Status Neogit: dokładne defaulty

- **`j` / `k`**: `MoveDown` / `MoveUp`. **Ryzyko/uwaga:** Bezpieczne.
- **`o`**: `OpenTree`. **Ryzyko/uwaga:** Otwiera drzewo/element.
- **`q`**: `Close`. **Ryzyko/uwaga:** Bezpieczne.
- **`I`**: `InitRepo`. **Ryzyko/uwaga:** Inicjalizacja repo, tylko poza repo.
- **`1` / `2` / `3` / `4`**: Głębokość rozwinięcia 1..4. **Ryzyko/uwaga:** Widok.
- **`Q`**: `Command`. **Ryzyko/uwaga:** Prompt dowolnego polecenia Git.
- **`Tab` / `za`**: `Toggle` sekcji/elementu. **Ryzyko/uwaga:** Widok.
- **`zo` / `zc`**: Otwórz / zamknij fold. **Ryzyko/uwaga:** Widok.
- **`zC` / `zO`**: Głębokość 1 / 4. **Ryzyko/uwaga:** Widok.
- **`x`**: `Discard`. **Ryzyko/uwaga:** **Destrukcyjne**, odrzuca wskazane zmiany po przepływie potwierdzenia.
- **`s`**: `Stage` zaznaczenia. **Ryzyko/uwaga:** Zmienia indeks.
- **`S`**: `StageUnstaged`. **Ryzyko/uwaga:** `git add --update`: stage zmian wszystkich śledzonych plików, bez nowych untracked.
- **`Ctrl-s`**: `StageAll`. **Ryzyko/uwaga:** Stage wszystkiego; w tmux naciśnij `Ctrl-s Ctrl-s`.
- **`u`**: `Unstage` zaznaczenia. **Ryzyko/uwaga:** Zmienia indeks, nie plik roboczy.
- **`K`**: `Untrack`. **Ryzyko/uwaga:** Usuwa z indeksu; sprawdź zamiar.
- **`R`**: `Rename`. **Ryzyko/uwaga:** Zmienia nazwę pliku.
- **`U`**: `UnstageStaged`. **Ryzyko/uwaga:** Unstage wszystkich staged.
- **`y`**: `ShowRefs`. **Ryzyko/uwaga:** Pokazuje referencje.
- **`$`**: `CommandHistory`. **Ryzyko/uwaga:** Historia poleceń Git.
- **`Y`**: `YankSelected`. **Ryzyko/uwaga:** Kopiuje zaznaczoną wartość.
- **`gp`**: `GoToParentRepo`. **Ryzyko/uwaga:** Repo nadrzędne/submodule.
- **`Ctrl-r`**: `RefreshBuffer`. **Ryzyko/uwaga:** Odświeżenie.
- **`Enter` / `Shift-Enter`**: `GoToFile` / `PeekFile`. **Ryzyko/uwaga:** Otwórz / podgląd.
- **`Ctrl-v` / `Ctrl-x` / `Ctrl-t`**: Otwórz w pionowym, poziomym splicie, karcie. **Ryzyko/uwaga:** Nawigacja.
- **`{` / `}`**: Poprzedni / następny nagłówek hunka. **Ryzyko/uwaga:** Nawigacja.
- **`[c` / `]c`**: `OpenOrScrollUp` / `OpenOrScrollDown`. **Ryzyko/uwaga:** Zmiana/hunk.
- **`Ctrl-k` / `Ctrl-j`**: `PeekUp` / `PeekDown`. **Ryzyko/uwaga:** Podgląd.
- **`Ctrl-n` / `Ctrl-p`**: Następna / poprzednia sekcja. **Ryzyko/uwaga:** Nawigacja.

### Popupy, commit i rebase

- **`?`, `A`, `d`, `M`, `P`, `X`, `Z`**: Pomoc, cherry-pick, diff, remote, push, reset, stash. **Kontekst:** popup.
- **`i`, `t`, `b`, `B`, `w`**: Ignore, tag, branch, bisect, worktree. **Kontekst:** popup.
- **`c`, `f`, `l`, `L`, `m`, `p`, `r`, `v`**: Commit, fetch, log, margin, merge, pull, rebase, revert. **Kontekst:** popup.
- **`Ctrl-c Ctrl-c`**: Submit. **Kontekst:** commit editor `n,i`.
- **`Ctrl-c Ctrl-k`**: Abort. **Kontekst:** commit editor `n,i`.
- **`q`, `Alt-p`, `Alt-n`, `Alt-r`**: Close, poprzednia/następna wiadomość, reset wiadomości. **Kontekst:** commit editor `n`.
- **`p`, `r`, `e`, `s`, `f`**: Pick, reword, edit, squash, fixup. **Kontekst:** rebase editor `n`.
- **`x`, `d`, `b`**: Execute, drop, break. **Kontekst:** rebase editor `n`.
- **`Enter`, `gk`, `gj`**: Otwórz commit, przenieś pozycję w górę/dół. **Kontekst:** rebase editor `n`.
- **`Ctrl-c Ctrl-c`, `Ctrl-c Ctrl-k`**: Submit planu / abort. **Kontekst:** rebase editor `n,i`.
- **`[c`, `]c`**: `OpenOrScrollUp` / `OpenOrScrollDown`. **Kontekst:** rebase editor `n`.

`d` w rebase oznacza drop commita z przepisywanej historii. `X` w popupie otwiera operacje reset. Obie ścieżki wymagają rozumienia skutków przed zatwierdzeniem.

**Wymagania:** Git, `plenary.nvim`; lokalnie także Telescope i Diffview jako aktywne integracje.

### Jak czytać popupy Neogit

Pierwszy klawisz otwiera transient popup, w którym małe/duże flagi zmieniają parametry, a klawisz akcji uruchamia Git. Zawsze czytaj opis w popupie. `?` pokazuje pomoc. Finder Telescope używa `Spacja` do multiselect; `Tab` jest completion, a `Ctrl-j` celowo nie porusza listą.

### Tutorial: hunk, commit i push

1. Otwórz `<leader>gg`. `Tab` rozwija sekcję pliku i jego hunki, `j/k` porusza się, a `Enter` przechodzi do realnego pliku.
2. Na hunku użyj `s`, aby stage'ować tylko zaznaczenie, lub `u`, aby je cofnąć. `S` obejmuje wszystkie zmiany śledzonych plików; dosłowny `Ctrl-s` obejmuje także untracked.
3. Przed commitem sprawdź sekcję Staged i ewentualnie otwórz diff. Użyj `c c` albo `<leader>gc`.
4. W edytorze wpisz wiadomość, zatwierdź `Ctrl-c Ctrl-c`; `Ctrl-c Ctrl-k` anuluje.
5. Otwórz popup push przez `P` lub `<leader>gp`, przeczytaj remote/ref i dopiero wykonaj akcję.

### Tutorial: branch, pull, stash i log

1. `<leader>gb` otwiera popup branch. Tworzenie, checkout, usuwanie i zmiana upstream to osobne akcje; sprawdź wskazaną gałąź.
2. `<leader>gP` otwiera pull, małe `f` fetch, `l` log, `Z` stash. Flagi popupu pozostają zapamiętane przez konfigurację Neogit.
3. `:NeogitLogCurrent %` pokazuje log bieżącej ścieżki, a zwykły popup `l` pozwala dobrać zakres i filtry.
4. `:NeogitResetState` czyści zapamiętany stan/flagę popupów; nie wykonuje `git reset` repozytorium.

### Rebase i polecenia zaawansowane

W edytorze rebase `p/r/e/s/f/x/d/b` oznacza pick/reword/edit/squash/fixup/exec/drop/break, a `gk/gj` zmienia kolejność. Submit przepisuje historię po zatwierdzeniu. Najpierw utwórz backup branch lub upewnij się, że historia nie została wypchnięta.

`Q` uruchamia prompt surowego Git, którego parser dzieli argumenty po spacjach i nie zachowuje się jak pełny shell z cytowaniem. `x` discarduje po przepływie potwierdzenia, `K` usuwa z indeksu, `U` unstaginguje cały staged zestaw. Nie używaj ich eksperymentalnie.

**Diagnostyka:** `$` otwiera historię poleceń, błędy trafiają do konsoli i `:messages`; porównaj zawsze z `git status`. Opcjonalny debug zapisuje log Neogit po uruchomieniu Neovim z `NEOGIT_LOG_FILE=1 NEOGIT_LOG_LEVEL=debug`.

**Źródła przypiętej rewizji:** [README](https://github.com/NeogitOrg/neogit/blob/73870229977fdd8747025820e15e98cfde787b9c/README.md), [pełny help i mapowania](https://github.com/NeogitOrg/neogit/blob/73870229977fdd8747025820e15e98cfde787b9c/doc/neogit.txt), [domyślne mapowania](https://github.com/NeogitOrg/neogit/blob/73870229977fdd8747025820e15e98cfde787b9c/lua/neogit/config.lua).
