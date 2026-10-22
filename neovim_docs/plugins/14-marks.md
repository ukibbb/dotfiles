<a id="plugin-marks"></a>
# Natywne marki Neovim i `marks.nvim`

Marka to nazwana pozycja w tekście. Neovim obsługuje marki sam; `marks.nvim` dodaje znaki w gutterze, automatyczny przydział liter, nawigację po markach i ulotne bookmarki (grupy `0`-`9`).

## Natywne marki w skrócie

- **`m{a-z}`**: marka lokalna dla pliku; **`m{A-Z}`**: marka globalna (skok między plikami).
- **`` `x ``**: skok dokładnie do marki `x`; **`'x`**: do pierwszego niebiałego znaku jej wiersza.
- **`` `. ``**: ostatnia zmiana; **`` `^ ``**: miejsce ostatniego wyjścia z Insert; **`` `[ ``**/**`` `] ``**: początek/koniec ostatniej zmiany lub wklejenia.
- **`:marks`**: lista marek; **`<leader>ma`**: marki w Telescope (z podglądem).

## Co dodaje `marks.nvim`

- **`m,`**: ustaw następną wolną małą literę (`a`, `b`, ...).
- **`m;`**: przełącz markę w bieżącym wierszu (uwaga: na zajętym wierszu usuwa wszystkie jego marki).
- **`m]`** / **`m[`**: następna / poprzednia marka w bieżącym pliku (z zawijaniem).
- **`m:`**: podgląd marki w oknie pływającym (zamknij przez `:close`).
- **`dmx`**: usuń markę `x`; **`dm-`**: usuń marki z bieżącego wiersza; **`dm<Space>`**: usuń wszystkie marki w buforze.
- **`m0`-`m9`**: dodaj bookmark z grupy 0-9; **`m}`** / **`m{`**: następny / poprzedni bookmark tej samej grupy (także w innych plikach, kursor musi stać na bookmarku).
- **`dm=`**: usuń bookmark pod kursorem; **`dm0`-`dm9`**: usuń całą grupę.
- **`:MarksListBuf`** / **`:MarksListAll`**: marki w location list; **`:BookmarksList 1`**: bookmarki grupy 1.
- **`:MarksToggleSigns`**: ukryj/pokaż znaki w gutterze.

### Jak używać

1. W pliku implementacji ustaw `mI`, w teście `mT`; skacz między nimi przez `` `I `` i `` `T ``.
2. Szybkie punkty w jednym pliku: kilka razy `m,`, potem przechodź `m]` / `m[`.
3. Tymczasowy cykl między plikami: `m1` w kilku miejscach, potem `m}` / `m{`.

**Uwaga:** bookmarki (`m0`-`m9`) znikają po restarcie Neovim i po `:bdelete`; `m]`/`m[` nie przechodzą między plikami. `dm<Space>` czyści też changelistę.
