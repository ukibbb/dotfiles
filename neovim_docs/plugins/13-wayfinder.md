# Nawigacja po powiązanym kodzie: Wayfinder

<a id="plugin-wayfinder"></a>
## `wayfinder.nvim`

Picker „powiązanego kodu” dla symbolu pod kursorem (albo bieżącego pliku): definicje, wywołujący, referencje, prawdopodobne testy i historia Git w jednym oknie. Pozwala skakać po kolejnych symbolach bez zamykania UI i budować z wybranych miejsc ścieżkę (Trail), którą można zapisać i wznowić.

Mapowania globalne (wielkie `W`):

- **`<leader>Wf`**: otwórz Wayfinder dla symbolu pod kursorem / bieżącego pliku.
- **`<leader>Ws`**: otwórz Wayfinder na fasecie `Trail`.
- **`<leader>Wo`**: skocz do bieżącego elementu Trail.
- **`<leader>Wn` / `<leader>Wp`**: następny / poprzedni element Trail (bez otwierania pickera).

W pickerze:

- **`j` / `k`**: wybór wyniku; **`h` / `l`** lub **`Tab` / `S-Tab`**: zmiana fasety (`All`, `Calls`, `Refs`, `Tests`, `Git`, `Trail`, `Saved`).
- **`Enter`**: skocz (wrócisz przez `Ctrl-t`); **`s` / `v` / `t`**: otwórz w split / vsplit / nowej karcie.
- **`e`**: eksploruj symbol z wybranego wiersza bez zamykania pickera; **`b` / `f`**: wstecz / naprzód w tej historii.
- **`p`**: przypnij wiersz do Trail; **`a`**: dodaj bieżący cel; **`A`**: dodaj całą drogę eksploracji.
- **`P`**: pokaż Trail; **`dd`**: usuń element (w fasecie Trail); **`da`**: wyczyść cały Trail.
- **`S`**: menu Trail (save, save as, load, resume, rename, delete); **`[` / `]`**: poprzedni / następny zapisany Trail.
- **`/`**: filtr wyników (`user !spec`, `"dwa słowa"`); **`Ctrl-l`**: wyczyść filtr.
- **`x`**: wyniki bieżącej fasety do quickfix; **`D`**: szczegóły wiersza; **`?`**: podpowiedzi; **`r`**: odśwież; **`q`**: zamknij (`Esc` nie zamyka).

Jak używać:

1. Zapisz bufor, ustaw kursor na nazwie funkcji i naciśnij `<leader>Wf`.
2. W `Calls`/`Refs` przeglądaj miejsca; `[LSP]` to wynik serwera, `[TXT]` to tylko dopasowanie tekstowe `rg`.
3. Ciekawe miejsca przypinaj `p`, w głąb idź `e`.
4. `S` → `Save Trail As`, żeby zachować ścieżkę; po restarcie `:WayfinderTrailResume`, potem `<leader>Wo`/`Wn`/`Wp`.

Polecenia bez skrótów: `:WayfinderTrailResume`, `:WayfinderTrailSave`, `:WayfinderTrailLoad`, `:WayfinderExportTrailQuickfix` (cały Trail do quickfix).

Uwagi:

- Trail roboczy żyje tylko w pamięci — bez zapisu przez `S` znika po restarcie. Nic nie wznawia się automatycznie.
- Load, `[`/`]` oraz `da` zastępują/czyszczą roboczy Trail bez pytania; jeśli pasek pokazuje `modified` lub `unsaved`, najpierw zapisz.
- `Delete Trail` usuwa zapis bez potwierdzenia.
- `Tests` to heurystyka po nazwach plików, a `Git` pokazuje commity pliku, nie symbolu. Bez LSP `Calls` jest puste, ale `Refs` działa przez `rg`.

Problemy: `:checkhealth wayfinder` (najpierw załaduj wtyczkę, np. `<leader>Wf`).
