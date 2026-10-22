# Telescope i nvim-tree

<a id="plugin-telescope"></a>
## `telescope.nvim`

Fuzzy finder plików, tekstu, buforów, pomocy i Git. Pokazuje pliki ukryte (bez wnętrza `.git/`), `live_grep` szuka także w dotfiles.

- **`<leader>ff`**: szukaj plików (respektuje `.gitignore`).
- **`<leader>fa`**: wszystkie pliki, łącznie z ignorowanymi.
- **`<leader>fw`** / **`<leader>fW`**: grep w projekcie / grep słowa pod kursorem.
- **`<leader>fz`** / **`<leader>fZ`**: szukaj w bieżącym pliku / słowa pod kursorem w bieżącym pliku.
- **`<leader>fb`**: otwarte bufory.
- **`<leader>fo`**: ostatnio otwierane pliki.
- **`<leader>fh`**: help Neovim.
- **`<leader>ma`**: natywne marki Neovim.
- **`<leader>cm`** / **`<leader>gt`**: commity / status Git (patrz uwaga niżej).
- **`<leader>Bo`**: profile połączeń Dbout.
- **`:Telescope resume`**: wróć do ostatniego pickera; `:Telescope` bez argumentów listuje wszystkie pickery.

W pickerze:

- **`Ctrl-n` / `Ctrl-p`** lub **`Alt-j` / `Alt-k`**: następny / poprzedni wynik.
- **`Enter`**, **`Ctrl-v`**, **`Ctrl-x`**, **`Ctrl-t`**: otwórz / split pionowy / poziomy / nowa karta.
- **`Ctrl-u` / `Ctrl-d`**: przewijanie preview.
- **`Tab`**: zaznacz wynik; **`Alt-q`** wysyła zaznaczone, **`Ctrl-q`** wszystkie do quickfix (dalej `[q` / `]q`).
- **`Esc`**: tryb Normal; tam **`q`** zamyka, **`?`** pokazuje mapowania (w Insert **`Ctrl-/`**).

**Uwaga (Git):** w `<leader>cm` `Enter` robi checkout commita (detached `HEAD`), a `Ctrl-r m/s/h` robi `git reset` mixed/soft/**hard** — hard odrzuca zmiany. W `<leader>gt` `Tab` stage'uje/unstage'uje plik. Do samego przeglądania historii użyj Diffview albo CodeDiff.

Problemy: `:checkhealth telescope` (wymaga `rg` i `fd`).

<a id="plugin-nvim-tree"></a>
## `nvim-tree.lua`

Boczne drzewo plików (lewa strona, szerokość 35) ze statusem Git. Zastępuje netrw, root podąża za `:cd`.

- **`<leader>e`**: pokaż/ukryj drzewo.
- **`<leader>E`**: pokaż bieżący plik w drzewie.

W drzewie:

- **`Enter`** / **`o`**: otwórz; **`Tab`**: preview bez opuszczania drzewa.
- **`Ctrl-v`** / **`Ctrl-x`** / **`Ctrl-t`**: split pionowy / poziomy / karta (także `Cmd-\` i `Cmd--`).
- **`a`**: utwórz plik; ścieżka zakończona `/` tworzy katalog.
- **`r`**: zmień nazwę; **`c`** / **`x`** / **`p`**: kopiuj / wytnij / wklej.
- **`d`**: usuń (z potwierdzeniem); **`D`**: do kosza.
- **`y`** / **`Y`** / **`gy`**: kopiuj nazwę / ścieżkę względną / absolutną.
- **`Ctrl-]`**: ustaw katalog jako root; **`-`**: root poziom wyżej; **`P`**: skok do rodzica.
- **`Backspace`**: zwiń katalog; **`W`**: zwiń wszystko; **`E`**: rozwiń wszystko.
- **`H`** / **`I`** / **`U`**: przełącz dotfiles / pliki z `.gitignore` / ukryte `.DS_Store` i `.git`.
- **`f`** / **`F`**: filtr nazw / wyczyść filtr.
- **`[c` / `]c`**: poprzedni / następny plik ze zmianą Git.
- **`R`**: odśwież; **`q`**: zamknij; **`g?`**: wszystkie mapowania.

Gdy pliku nie widać, sprawdź kolejno `H`, `I`, `U`.
