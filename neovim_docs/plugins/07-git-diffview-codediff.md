# Git: Diffview i CodeDiff

<a id="plugin-diffview"></a>
## `diffview.nvim`

Karta z diffem wielu plików, panelem plików (drzewo po lewej), historią i narzędziami do konfliktów. Najlepszy do przeglądu całego zestawu zmian i merge/rebase.

- **`<leader>gv`**: bieżące zmiany (indeks kontra worktree) — tu się stage'uje.
- **`<leader>gm`**: review brancha: `origin/main...HEAD`.
- **`<leader>gl`** / **`<leader>gL`**: historia bieżącego pliku / całego repo.
- **`<leader>gq`** lub **`q`**: zamknij Diffview.

W widoku i panelu plików:

- **`Tab`**: w diffie skacze do panelu plików; w panelu otwiera następny plik. **`Shift-Tab`**: poprzedni plik.
- **`j` / `k`**, **`Enter`**: wybór i otwarcie pliku w panelu.
- **`-`** / **`s`**: stage/unstage pliku; **`S`**: stage wszystkiego; **`U`**: unstage wszystkiego.
- **`gf`**: otwórz prawdziwy plik w poprzedniej karcie.
- **`g?`**: pomoc.
- W historii: **`L`** szczegóły commita, **`y`** kopiuj hash.

Konflikty (merge/rebase):

- **`[x` / `]x`**: poprzedni / następny konflikt.
- **`<leader>co`** / **`<leader>ct`** / **`<leader>cb`** / **`<leader>ca`**: weź ours / theirs / base / wszystkie (wielkie litery: cały plik).
- **`dx`**: usuń region konfliktu.
- Po rozwiązaniu: `:write`, sprawdź wynik i dopiero stage'uj.

**Uwaga:** **`X`** przywraca plik do wersji z lewej strony i odrzuca zmiany — w historii bez potwierdzenia. W `<leader>gm` i historii `S`/`U`/`X` nadal działają na prawdziwym repo.

<a id="plugin-codediff"></a>
## `codediff.nvim`

Diff side-by-side w stylu VS Code z podświetleniem zmian na poziomie znaków. Wygodny do dokładnego przeglądu jednego pliku.

- **`<leader>gf`**: bieżący plik kontra `HEAD` (lewo: `HEAD`, prawo: prawdziwy plik).
- **`<leader>gD`**: explorer wszystkich zmienionych plików.
- **`<leader>gh`**: historia bieżącego pliku (`Enter` rozwija commit).

W widoku:

- **`]c` / `[c`**: następny / poprzedni hunk; **`]f` / `[f`**: następny / poprzedni plik.
- **`do`** / **`dp`**: pobierz hunk z drugiej strony / wyślij hunk na drugą stronę (zmienia prawdziwy plik).
- **`<leader>b`**: pokaż/ukryj explorer; **`gf`**: otwórz prawdziwy plik; **`q`**: zamknij kartę.
- W explorerze: **`-`** stage/unstage pliku, **`S`** / **`U`** stage / unstage wszystkiego, **`R`** odśwież.
- Konflikty (`:CodeDiff merge plik`): **`<leader>co`** / **`<leader>ct`** / **`<leader>cb`** ours / theirs / oba, **`]x` / `[x`** nawigacja.

**Uwaga:** **`X`** w explorerze odrzuca zmiany unstaged, a dla pliku untracked go usuwa. `<leader>cx` w konflikcie przywraca wersję base. Staging (`-`/`S`/`U`/`X`) używaj tylko w zwykłym `<leader>gD`, nie w widokach historycznych.

Problemy: `:CodeDiff install!` reinstaluje bibliotekę diffu.
