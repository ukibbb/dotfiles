<a id="szybka-sciaga"></a>
# Szybka ściąga

`prefix` tmux to `Ctrl-s`. `<leader>` Neovim to `Spacja`.

## Tmux na co dzień

- **`Ctrl-s c`**: Nowe okno w bieżącym katalogu.
- **`Ctrl-s |`**: Panel obok, lewo/prawo.
- **`Ctrl-s -`**: Panel poniżej, góra/dół.
- **`Ctrl-h/j/k/l`**: Przejście między panelami tmux i splitami Neovim bez prefixu.
- **`Ctrl-\`**: Poprzedni panel lub split, bez prefixu.
- **`Ctrl-s h/j/k/l`**: Zmiana rozmiaru panelu o 5 komórek.
- **`Ctrl-s m`**: Maksymalizacja/przywrócenie panelu.
- **`Ctrl-s Ctrl-j`**: Wyszukiwarka sesji `tmux-fzf`.
- **`Ctrl-s s`**: Lista sesji tmux.
- **`Ctrl-s d`**: Odłączenie od sesji.
- **`Ctrl-s r`**: Ponowne wczytanie `~/.tmux.conf`.

## Neovim na co dzień

- **Plik**: `<leader>ff` pliki projektu, `<leader>fa` także ignorowane, `<leader>e` drzewo.
- **Tekst**: `<leader>fw` w projekcie, `<leader>fW` słowo pod kursorem, `<leader>fz` w buforze, `<leader>fZ` słowo w buforze.
- **Bufor**: `<leader>fb`, fizyczne `Cmd-h` / `Cmd-l`, fizyczne `Cmd-q`.
- **LSP**: `gd` definicja, `gD` deklaracja, `gr` referencje, `K` hover, `<leader>ca` akcje, `<leader>ra` zmiana nazwy.
- **TypeScript**: `gS` źródłowa definicja, `<leader>ci` akcje importów.
- **Diagnostyka**: `[d` / `]d`, `<leader>dd`, `<leader>ds`.
- **Format**: `<leader>fm`; zapis także formatuje.
- **Git**: `<leader>gg` status, `<leader>gv` Diffview, `<leader>gD` CodeDiff, `<leader>gf` bieżący plik kontra `HEAD`.
- **Debugger**: `F5`, `F10`, `F11`, `F12`, `<leader>db`, `<leader>du`.
- **Markdown**: `<leader>mr` przełącza renderowanie tylko w buforze Markdown.
- **Zdalnie**: `<leader>rl` połączenie, `<leader>ro` plik/katalog, `<leader>rs` powłoka.
- **Zmiany zewnętrzne**: `<leader>ch` zatwierdza obejrzenie podświetleń watchdiff.
- **Claude**: `<leader>ac` pytanie, `<leader>aC` pytanie i próba natychmiastowego komentarza.

<a id="bezpieczenstwo"></a>
## Najważniejsze ostrzeżenia

> **UWAGA: Git.** `X` w CodeDiff i Diffview, `x` w Neogit, reset hard w Telescope, przywracanie pliku oraz usuwanie nieśledzonego pliku mogą bezpowrotnie usunąć niezapisane lub niezatwierdzone dane. Przed użyciem sprawdź `git status`, zapisz potrzebne bufory i w razie wątpliwości utwórz commit albo stash.

> **UWAGA: historia Git.** `Enter` w pickerze `<leader>cm` wykonuje checkout wybranego commita i zwykle przechodzi do detached `HEAD`. `Ctrl-r m`, `Ctrl-r s` i `Ctrl-r h` przesuwają bieżącą gałąź. Szczególnie `Ctrl-r h` usuwa śledzone zmiany z indeksu i drzewa roboczego.

> **UWAGA: `Ctrl-s`.** Tmux przechwytuje `Ctrl-s` jako prefix. Aby wysłać dosłowne `Ctrl-s` do Neovim lub programu w panelu, naciśnij `Ctrl-s Ctrl-s`. Dotyczy to między innymi wbudowanej pomocy sygnatur LSP, akcji `StageAll` w Neogit i zapisu koloru w Minty. `.zshrc` wykonuje `stty -ixon`, więc terminal nie używa `Ctrl-s` jako XOFF, ale konflikt z prefixem tmux pozostaje.

> **UWAGA: pliki zdalne i zewnętrzne.** `D`, `R`, `K` w interfejsach Distant mogą usuwać, zmieniać nazwę lub zrywać połączenie. `:e!` po konflikcie watchdiff odrzuca lokalne, niezapisane zmiany bufora.

> **UWAGA: automatyczne zmiany przy zapisie.** Zapis Lua lub Pythona uruchamia Conform. Dla Pythona najpierw działa `ruff check --fix`, a dopiero potem `ruff format`, więc zapis może usuwać importy i stosować poprawki kodu, nie tylko zmieniać odstępy. Po pierwszym użyciu w projekcie obejrzyj `git diff`.

> **UWAGA: interfejs nie zawsze pokazuje historyczny stan, na którym operuje.** Stage, unstage i discard w historycznych widokach CodeDiff albo Diffview nadal mogą zmieniać realny indeks i drzewo robocze. Operacji `-`, `S`, `U` i `X` używaj do stagingu tylko w zwykłym widoku bieżących zmian, po sprawdzeniu `git status`.
