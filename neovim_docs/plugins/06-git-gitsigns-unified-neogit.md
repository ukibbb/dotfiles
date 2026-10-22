# Git: Gitsigns, Unified i Neogit

<a id="plugin-gitsigns"></a>
## `gitsigns.nvim`

Znaki dodanych, zmienionych i usuniętych linii w signcolumn oraz blame bieżącej linii (na końcu wiersza, po 300 ms). Lekki podgląd zmian pliku, nie pełny klient Git.

Brak własnych mapowań — akcje przez `:Gitsigns {subcommand}`:

- **`:Gitsigns preview_hunk_inline`** / **`preview_hunk`**: podgląd hunka inline / w popupie (`q` zamyka).
- **`:Gitsigns nav_hunk next`** / **`nav_hunk prev`**: następny / poprzedni hunk.
- **`:Gitsigns stage_hunk`**: stage hunka (w Visual: tylko zaznaczone linie); ponownie na staged hunku — unstage.
- **`:Gitsigns blame_line`** / **`blame`**: blame linii / całego pliku.
- **`:Gitsigns diffthis`**: diff pliku z indeksem.
- **`:Gitsigns setqflist`**: hunki do quickfix.
- **`:Gitsigns toggle_current_line_blame`**: wyłącz/włącz blame w linii.

**Uwaga:** `:Gitsigns reset_hunk` i `reset_buffer` odrzucają zmiany w buforze — po zapisie są stracone.

Znaki pokazują różnicę względem indeksu, nie `HEAD`; po stage'u hunk dostaje znak „staged”. Stage nie tworzy commita.

<a id="plugin-unified"></a>
## `unified.nvim`

Unified diff względem `HEAD` bezpośrednio w buforze plus boczne drzewo zmienionych plików. Szybki, jednokolumnowy przegląd zmian.

- **`<leader>gd`**: otwórz lub odśwież widok (to nie jest toggle; otwiera pierwszy zmieniony plik).
- **`j` / `k`**: następny / poprzedni plik w drzewie; **`l`**: otwórz diff pliku.
- **`R`**: odśwież; **`q`**: zamknij drzewo; **`?`**: pomoc.
- **`:Unified HEAD~1`**: porównaj z innym refem.
- **`:Unified reset`**: usuń markery diffu z bieżącego bufora (`q` zostawia je w buforach).

Do stagingu używaj Gitsigns albo Neogit — Unified traktuj jako podgląd.

<a id="plugin-neogit"></a>
## `neogit`

Klient Git w stylu Magit: status, staging hunków, commit, branch, pull/push, log, stash, rebase. Otwiera się w nowej karcie, diffy pokazuje przez Diffview.

- **`<leader>gg`**: status Neogit.
- **`<leader>gc`** / **`<leader>gp`** / **`<leader>gP`** / **`<leader>gb`**: popup commit / push / pull / branch.

W statusie:

- **`Tab`**: rozwiń/zwiń plik lub sekcję; **`Enter`**: przejdź do pliku.
- **`s`** / **`u`**: stage / unstage pliku, hunka lub zaznaczenia.
- **`S`**: stage wszystkich zmian w śledzonych plikach; **`U`**: unstage wszystkiego.
- **`Ctrl-s`**: stage wszystkiego, także untracked — w WezTerm naciśnij **`Ctrl-s Ctrl-s`** (`Ctrl-s` to leader).
- **`x`**: **discard** — trwale odrzuca wskazane zmiany (po potwierdzeniu).
- **`c`**, **`P`**, **`p`**, **`b`**, **`l`**, **`Z`**, **`r`**: popup commit / push / pull / branch / log / stash / rebase.
- **`q`**: zamknij; **`?`**: wszystkie akcje.

W edytorze commita: **`Ctrl-c Ctrl-c`** zatwierdza, **`Ctrl-c Ctrl-k`** anuluje.

Jak używać:

1. `<leader>gg`, `Tab` na pliku pokazuje hunki.
2. `s` na wybranych hunkach, sprawdź sekcję Staged.
3. `c c` (lub `<leader>gc`), wpisz wiadomość, `Ctrl-c Ctrl-c`.
4. `P`, przeczytaj remote w popupie i wybierz akcję push.

**Uwaga:** `X` w popupie to `git reset`, a `d` w edytorze rebase usuwa commit z historii — czytaj opis popupu przed akcją.
