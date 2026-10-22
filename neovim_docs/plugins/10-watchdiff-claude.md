# Lokalne watchdiff.nvim

<a id="plugin-watchdiff"></a>
## `watchdiff.nvim`

Lokalna wtyczka z `watchdiff.nvim/` w tym repo. Gdy zewnętrzne narzędzie (np. Claude) zmieni otwarty plik, bufor się przeładowuje, a zmiany są podświetlone: zielone tło dla dodanych/zmienionych linii, czerwone wirtualne linie dla usuniętych. Punktem odniesienia jest ostatni „uznany” stan pliku, nie Git.

- **`<leader>ch`**: zaakceptuj zmiany — czyści podświetlenia i ustawia bieżącą treść jako nowy punkt odniesienia (niczego nie cofa).
- **`:WatchDiffHistory`**: historia zewnętrznych zmian bieżącego pliku w tej sesji (`q` zamyka).

Jak używać:

1. Otwórz plik w Neovim, zleć zmianę narzędziu zewnętrznemu.
2. Przejrzyj zielone/czerwone podświetlenia; kolejne zmiany kumulują się aż do akceptacji.
3. `<leader>ch`, gdy zmiany są przejrzane.

Uwagi:

- Śledzone są tylko pliki otwarte w buforach, w obrębie bieżącego katalogu (`:pwd`); pliki ponad 5000 linii są pomijane.
- Jeśli bufor ma niezapisane zmiany, nie zostanie przeładowany — `:e!` wczyta wersję z dysku i **odrzuci** Twoje zmiany.
- Historia i podświetlenia znikają po restarcie Neovim. Zdalne bufory Distant nie są śledzone.
