# Edytowalne siatki w `dadbod-grip.nvim`

<a id="plugin-dadbod-grip"></a>
## `dadbod-grip.nvim`

Query pad, schemat i edytowalny grid nad natywnymi klientami (`psql`, `mysql`, `sqlite3`, `duckdb`, `sqlcmd`). Zmiany w komórkach są etapowane, można obejrzeć wygenerowany SQL i zatwierdzić je w transakcji. Otwiera też CSV/JSON/Parquet przez DuckDB. AI i Docker discovery są wyłączone.

- **`<leader>Bg`**: `:GripConnect`, wybór połączenia.
- **`1` / `2` / `3`**: schema sidebar / query pad / grid (ponowne `1` to picker połączeń, `2` to historia); **`4`-`9`**: diagram, statystyki, kolumny, FK, indeksy, constraints.
- **`Ctrl-p`**: command palette; **`?`**: pomoc.

Query pad:
- **`Ctrl-Enter`**: wykonaj zaznaczenie albo instrukcję pod kursorem; **`Shift-Enter`**: wynik w nowym splicie.
- **`Ctrl-s`**: zapisz zapytanie do `.grip/queries/` (w WezTerm `Ctrl-s Ctrl-s`, bo `Ctrl-s` to leader); **`gq`**: wczytaj zapisane.
- **`gF`**: formatuj; **`gh`**: historia; **`gC` / `Ctrl-g`**: zmień połączenie; **`Ctrl-Spacja`**: completion.

Grid:
- **`Enter` / `i`**: edytuj komórkę; **`o`**: nowy wiersz; **`c`**: klonuj; **`d`**: oznacz do usunięcia; **`x`**: `NULL`.
- **`u` / `Ctrl-r` / `U`**: undo / redo / odrzuć wszystkie zmiany.
- **`gs`**: pokaż wygenerowany SQL; **`a`**: zatwierdź etapowane zmiany.
- **`H` / `L`**: strony; **`s`**: sort; **`f` / `Ctrl-f` / `F`**: filtr z komórki / własny / wyczyść.
- **`gf` / `Ctrl-o`**: przejdź po foreign key / wróć; **`gE` / `gX`**: eksport do schowka / pliku.

### Jak używać

1. `<leader>Bg` i wybierz profil (hasło jako `${ZMIENNA}`, nie literalnie).
2. W sidebarze otwórz tabelę `Enter`, albo przejdź do query pada `2` i wykonaj `SELECT` przez `Ctrl-Enter`.
3. Przy edycji grida: zmień komórki, sprawdź `gs`, zatwierdź `a`.

**Uwaga:**
- Profile: `stdpath("state")/dadbod-grip/connections.json`. W katalogu projektu powstaje `.grip/` (historia z pełnym SQL, zapisane zapytania, filtry); dodaj go do `.gitignore`.
- `"mode": "ro"` w profilu to wygoda, nie zabezpieczenie; prawdziwą granicą jest użytkownik bazy bez praw zapisu. Query pad wykona dowolny SQL.
- Problemy: `:checkhealth dadbod-grip` (ostrzeżenie o braku klucza AI można zignorować).
