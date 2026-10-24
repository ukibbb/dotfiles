# Distant i smart-splits po stronie Neovim

<a id="plugin-distant"></a>
## `distant.nvim`

Edycja plików na zdalnej maszynie (głównie Raspberry Pi) przez SSH: otwieranie i zapis zdalnych plików, przeglądarka katalogów, zdalny shell i polecenia.

- **`<leader>rp`**: połącz z Raspberry Pi (`DistantLaunch ssh://ukibbb@192.168.101.7`).
- **`<leader>rl`**: połącz z dowolnym hostem — pyta o `ssh://user@host`.
- **`<leader>ro`**: `:DistantOpen ` — dopisz ścieżkę pliku lub katalogu (bez ścieżki: zdalne `.`).
- **`<leader>rs`**: zdalny terminal w bieżącym oknie.
- **`<leader>rx`**: `:DistantSpawn ` — uruchom jedno polecenie i pokaż wynik.
- **`:Distant`** (po połączeniu): okno połączeń (`?` pomoc, `q` zamyka).

W zdalnym katalogu:

- **`Enter`**: otwórz; **`Ctrl-t`**: w nowej karcie; **`-`**: katalog wyżej.
- **`N`** / **`K`**: nowy plik / katalog.
- **`R`** / **`C`**: zmień nazwę / kopiuj.
- **`D`**: usuń — trwale, bez kosza; przeczytaj ścieżkę przed potwierdzeniem.

Jak używać:

1. `<leader>rp` (lub `<leader>rl` dla innego hosta).
2. `<leader>ro` + ścieżka, np. `~/projekt`, i `Enter`.
3. Edytuj normalnie; `:w` zapisuje na zdalnej maszynie.

Launch wymaga binarki `distant` na serwerze w `/home/ukibbb/.local/bin/distant`. Zdalny LSP nie jest skonfigurowany. Problemy: `:DistantCheckHealth`, `:DistantClientVersion`.

<a id="plugin-smart-splits"></a>
## `smart-splits.nvim`

**Co robi i po co:** tworzy jedną siatkę nawigacji ze splitów Neovim i paneli WezTerm. Ładuje się natychmiast.

**Mapowania:** `Ctrl-h/j/k/l` w Normal Neovim. Lokalne mapowania Insert `Ctrl-h/j/k/l` mają pierwszeństwo i poruszają kursorem.

**Konfiguracja:** `move.at_edge = "stop"`, czyli na zewnętrznej krawędzi bez sąsiedniego panelu nic się nie dzieje (bez zawijania na drugą stronę).

### Jak przebiega jeden klawisz

1. WezTerm odbiera `Ctrl-h/j/k/l` i sprawdza zmienną `IS_NVIM` panelu (ustawia ją smart-splits).
2. Panel bez Neovim: WezTerm przechodzi do sąsiedniego panelu.
3. Panel z Neovim: WezTerm przekazuje klawisz do Neovim, który przechodzi między splitami.
4. Na krawędzi Neovim smart-splits woła `wezterm cli activate-pane-direction`.

### Konflikty klawiszy

- `Ctrl-l` w shellu nie czyści ekranu; użyj `Ctrl-s Ctrl-l`.
- `Ctrl-h` nie jest terminalowym backspace.
- Nie ma skrótu `Ctrl-\` (poprzedni panel).

### Diagnostyka

1. `:checkhealth smart-splits` pokazuje wykryty multiplekser (powinien to być WezTerm).
2. `:verbose nmap <C-h>` pokazuje stronę Neovim.
3. `wezterm show-keys | grep CTRL` pokazuje stronę WezTerm.
