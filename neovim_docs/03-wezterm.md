<a id="wezterm"></a>
# WezTerm

> Stan na 22 października 2026. WezTerm jest terminalem i multiplekserem: workspace'y, karty i panele są wbudowane. Konfiguracja: `wezterm.lua` → `~/.config/wezterm/wezterm.lua`; WezTerm przeładowuje ją sam po zapisie.

<a id="wezterm-pojecia"></a>
## Pojęcia

- **Workspace**. Osobny zestaw kart, zwykle jeden na projekt. Nazwa widoczna po prawej stronie paska.
- **Karta** (tab) na pasku u góry.
- **Panel** (split).
- **Leader `Ctrl-s`**. Naciśnij, puść, potem klawisz; masz na to 1 s. Gdy leader jest aktywny, po prawej świeci fioletowe `^S`.

**Czego nie ma:** trwałości. Zamknięcie okna WezTerm zamyka shelle, Neovim i serwery w środku. Agenci w herdr działają dalej, bo herdr ma własny serwer.

<a id="wezterm-skroty"></a>
## Skróty

### Panele

- **`Ctrl-s |`**: Panel obok, lewo/prawo, w bieżącym katalogu.
- **`Ctrl-s -`**: Panel poniżej, góra/dół, w bieżącym katalogu.
- **`Ctrl-h/j/k/l`**: Przejście między panelami WezTerm i splitami Neovim bez leadera (smart-splits.nvim).
- **`Ctrl-s h/j/k/l`**: Zmiana rozmiaru o 5 komórek. Przez kolejną sekundę same `h/j/k/l` dalej zmieniają rozmiar. `Esc` kończy.
- **`Ctrl-s m`**: Maksymalizacja/przywrócenie panelu.
- **`Ctrl-s x`**: Zamknięcie panelu po potwierdzeniu.

### Karty

- **`Ctrl-s c`**: Nowa karta.
- **`Ctrl-s n`** / **`Ctrl-s p`**: Następna / poprzednia karta.
- **`Ctrl-s 1`...`9`**: Karta o numerze.
- **`Ctrl-s ,`**: Zmiana nazwy karty.

### Workspace'y (dawne sesje)

- **`nt`** w shellu: Wybór folderu przez fzf, potem przełączenie do workspace o nazwie folderu albo utworzenie go z tym folderem jako katalogiem.
- **`Ctrl-s s`** lub **`Ctrl-s Ctrl-j`**: Lista workspace'ów z wyszukiwaniem fuzzy.
- **`Ctrl-s (`** / **`Ctrl-s )`**: Poprzedni / następny workspace.
- **`Ctrl-s a`**: Workspace `agents` z herdr; tworzy go i uruchamia `herdr`, jeśli nie istnieje.

### Inne

- **`Ctrl-s [`**: Copy mode z klawiszami vi: `h/j/k/l`, `v` zaznaczenie, `y` kopiowanie, `/` szukanie, `q` / `Esc` wyjście.
- **`Ctrl-s r`**: Ręczne przeładowanie konfiguracji.
- **`Ctrl-s Ctrl-s`**: Wysłanie dosłownego `Ctrl-s` do programu.
- **`Ctrl-s Ctrl-l`**: Wyczyszczenie ekranu; samo `Ctrl-l` przechodzi do panelu po prawej.
- **`Ctrl-s Ctrl-g`**: Naprawa panelu po TUI, które zostawiło włączoną mysz lub alternate screen.
- **`Cmd-h` / `Cmd-l` / `Cmd-q`**, **`Cmd-\`** / **`Cmd--`**, **`Cmd-j` / `Cmd-k`**, **`Cmd-n`**: Bez zmian, trafiają do Neovim jako sekwencje CSI-u.

<a id="wezterm-pasek"></a>
## Pasek u góry

- **Lewo**: Przyciski okna macOS, potem karty. Aktywna karta ma cyjanowe tło.
- **Prawo**: `^S`, gdy leader jest aktywny; stan agentów herdr (`herdr ⚙ 2  ⏸ 1  ✓ 1  ○ 3`: pracuje, czeka na Ciebie, skończył, bezczynny); nazwa workspace; godzina. Odświeżanie co 5 s.

<a id="wezterm-nawigacja-nvim"></a>
## Nawigacja Neovim ↔ WezTerm

Neovim z wtyczką smart-splits.nvim ustawia zmienną `IS_NVIM` na swoim panelu. `wezterm.lua` sprawdza ją przy `Ctrl-h/j/k/l`:

1. Panel bez Neovim: WezTerm przechodzi do sąsiedniego panelu.
2. Panel z Neovim: klawisz trafia do Neovim, który przechodzi między swoimi splitami.
3. Na krawędzi Neovim smart-splits przekazuje ruch do WezTerm.

W trybie Insert `Ctrl-h/j/k/l` nadal poruszają kursorem (lokalne mapowania).

<a id="wezterm-diagnostyka"></a>
## Diagnostyka

- **`wezterm show-keys`**: Wszystkie aktywne skróty, w tym leader.
- **`Ctrl-Shift-l`**: Debug overlay z błędami konfiguracji i konsolą Lua.
- **`wezterm cli list`**: Workspace'y, karty i panele.
- **Nowy panel nie startuje w bieżącym katalogu**: Shell integration nie działa; sprawdź, czy `.zshrc` ładuje `wezterm.sh` (`echo $TERM_PROGRAM` powinno dać `WezTerm`).
- **`Ctrl-h/j/k/l` nie wychodzi z Neovim**: `:checkhealth smart-splits`.
