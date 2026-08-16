<a id="tmux"></a>
# Tmux

## Konfiguracja i zachowanie terminala

- Terminal domyślny: `tmux-256color`; dla WezTerm włączone są RGB, synchronized output i extended keys w formacie CSI-u.
- `allow-passthrough` jest wyłączone, aby surowe odpowiedzi DCS nie trafiały do aplikacji TUI.
- Mysz jest włączona.
- Czas powtarzania mapowań wynosi 1000 ms.
- Copy mode używa klawiszy vi.
- Pasek statusu ma tło `#00d9ff` i czarny tekst.

## Wszystkie jawne mapowania z `tmux.conf`

- **`Ctrl-s`**: Wejście do tabeli prefix. **Kontekst:** globalny. **Stan:** **Aktywne lokalne**.
- **`Ctrl-s`**: `send-prefix`, czyli wysłanie dosłownego klawisza prefix do programu lub zagnieżdżonego tmux. **Kontekst:** prefix. **Stan:** **Aktywne lokalne**.
- **`|`**: `split-window -h` w bieżącym katalogu, panele obok siebie. **Kontekst:** prefix. **Stan:** **Aktywne lokalne**.
- **`-`**: `split-window -v` w bieżącym katalogu, panele jeden nad drugim. **Kontekst:** prefix. **Stan:** **Aktywne lokalne**.
- **`c`**: Nowe okno w bieżącym katalogu panelu. **Kontekst:** prefix. **Stan:** **Aktywne lokalne**.
- **`r`**: `source-file ~/.tmux.conf`. **Kontekst:** prefix. **Stan:** **Aktywne lokalne**.
- **`h` / `j` / `k` / `l`**: Rozmiar panelu w lewo / dół / górę / prawo o 5. **Kontekst:** prefix, powtarzalne. **Stan:** **Aktywne lokalne**.
- **`m`**: Przełączenie zoomu panelu. **Kontekst:** prefix, powtarzalne. **Stan:** **Aktywne lokalne**.
- **`Ctrl-j`**: Skrypt `tmux-fzf/scripts/session.sh switch` w tle. **Kontekst:** prefix. **Stan:** **Aktywne lokalne**.
- **`Ctrl-g`**: Wyłączenie trybów myszy i alternate screen oraz `stty sane -ixon` po zepsutym TUI. **Kontekst:** prefix. **Stan:** **Aktywne lokalne**.
- **`v`**: Początek zaznaczenia. **Kontekst:** copy-mode-vi. **Stan:** **Aktywne lokalne**.
- **`y`**: Kopiowanie zaznaczenia do bufora tmux. **Kontekst:** copy-mode-vi. **Stan:** **Aktywne lokalne**.
- **zakończenie przeciągania myszą**: Nie wychodzi automatycznie z copy mode. **Kontekst:** copy-mode-vi. **Stan:** **Warunkowe/wyłączone**: domyślna akcja została odpięta.

## Przydatne domyślne mapowania tmux 3.7b, które nadal działają

- **`d`**: Odłącz klienta od sesji. **Obszar:** sesje.
- **`s`**: Interaktywna lista sesji. **Obszar:** sesje.
- **`$`**: Zmień nazwę sesji. **Obszar:** sesje.
- **`(` / `)`**: Poprzednia / następna sesja. **Obszar:** sesje.
- **`L`**: Ostatnio używana sesja. **Obszar:** sesje.
- **`n` / `p`**: Następne / poprzednie okno. **Obszar:** okna.
- **`0`...`9`**: Okno o podanym numerze. **Obszar:** okna.
- **`w`**: Drzewo okien i sesji. **Obszar:** okna.
- **`,`**: Zmień nazwę okna. **Obszar:** okna.
- **`&`**: Zabij okno po potwierdzeniu. **Obszar:** okna.
- **`o`**: Następny panel. **Obszar:** panele.
- **`;`**: Ostatni panel. **Obszar:** panele.
- **`q`**: Pokaż numery paneli. **Obszar:** panele.
- **`x`**: Zabij panel po potwierdzeniu. **Obszar:** panele.
- **`!`**: Przenieś panel do nowego okna. **Obszar:** panele.
- **`{` / `}`**: Zamień panel z poprzednim / następnym. **Obszar:** panele.
- **`Spacja`**: Następny układ paneli. **Obszar:** układ.
- **`[`**: Wejdź do copy mode. **Obszar:** copy mode.
- **`?`**: Lista mapowań tmux. **Obszar:** pomoc.
- **`:`**: Prompt poleceń tmux. **Obszar:** polecenie.

W copy-mode-vi działają między innymi `h/j/k/l`, `Ctrl-u`, `Ctrl-d`, `/`, `?` i `q`. `v` oraz `y` są lokalnie ustawione jawnie.

## Domyślne akcje zastąpione lokalnie

- **`Ctrl-b`**: Prefix. **Stan lokalny:** Odpięty, zastąpiony przez `Ctrl-s`.
- **`prefix %`**: Split lewo/prawo. **Stan lokalny:** Odpięty, użyj `prefix |`.
- **`prefix "`**: Split góra/dół. **Stan lokalny:** Odpięty, użyj `prefix -`.
- **`prefix r`**: `refresh-client`, czyli polecenie odświeżenia bieżącego klienta tmux. **Stan lokalny:** Zastąpione wczytaniem konfiguracji; nie jest to już domyślne odświeżenie klienta.
- **`prefix l`**: Ostatnie okno. **Stan lokalny:** Zastąpione zmianą rozmiaru w prawo.
- **`prefix m`**: Oznaczenie panelu. **Stan lokalny:** Zastąpione zoomem.

## Trzy wtyczki tmux

### `tmux-plugins/tpm`

- **`prefix I`**: Instalacja brakujących wtyczek i odświeżenie środowiska tmux. **Stan:** **Domyślne wtyczki**.
- **`prefix U`**: Aktualizacja wtyczek. **Stan:** **Domyślne wtyczki**.
- **`prefix Alt-u`**: Usunięcie wtyczek nieobecnych w konfiguracji. **Stan:** **Domyślne wtyczki**.

Aktualizacja nie jest ograniczona commitami w `tmux.conf`; patrz [manifest źródeł i wersji](reference/02-manifest.md#manifest).

### `sainnhe/tmux-fzf`

- **`prefix F`**: Pełne menu sesji, okien, paneli, poleceń, klawiszy, schowka i procesów. **Stan:** **Domyślne wtyczki**.
- **`prefix Ctrl-j`**: Bezpośredni picker przełączania sesji. **Stan:** **Aktywne lokalne**.
- **`Tab` / `Shift-Tab` w fzf**: Zaznaczenie wielu elementów / ruch wstecz. **Stan:** **Kontekstowe**.

Wymagane są GNU Bash, `sed` i `fzf`; CopyQ i `pstree` są opcjonalne.

### `christoomey/vim-tmux-navigator`

- **`Ctrl-h/j/k/l`**: Lewo / dół / góra / prawo przez granice splitów i paneli. **Kontekst:** root tmux i Normal Neovim. **Stan:** **Domyślne wtyczki**.
- **`Ctrl-\`**: Poprzedni split lub panel. **Kontekst:** root tmux i Normal Neovim. **Stan:** **Domyślne wtyczki**.
- **`Ctrl-h/j/k/l`, `Ctrl-\`**: Nawigacja paneli tmux. **Kontekst:** copy-mode-vi. **Stan:** **Kontekstowe**.
- **`Ctrl-l`**: Wysłanie dosłownego `Ctrl-l` do programu, zwykle wyczyszczenie ekranu powłoki. **Kontekst:** prefix tmux. **Stan:** **Domyślne wtyczki**.

Po stronie tmux wtyczka sprawdza proces w panelu. Gdy wykryje Vim/Neovim lub proces pasujący do jej wzorca, przekazuje klawisz do aplikacji; w innym panelu wykonuje `select-pane`. Nie naciska się prefixu. W Insert Neovim lokalne `Ctrl-h/j/k/l` poruszają kursorem, więc nie przełączają panelu. Polecenia Neovim: `:TmuxNavigateLeft`, `:TmuxNavigateDown`, `:TmuxNavigateUp`, `:TmuxNavigateRight`, `:TmuxNavigatePrevious`, `:TmuxNavigatorProcessList`.

## Mini-tutorial: sesja i panele

1. Uruchom `tmux new -s projekt` w powłoce.
2. Utwórz okno edytora przez `Ctrl-s c`, a potem panel terminala przez `Ctrl-s |`.
3. Uruchom Neovim w jednym panelu i przechodź `Ctrl-h` / `Ctrl-l` przez split Neovim oraz granicę tmux.
4. Zmień rozmiar panelu przez `Ctrl-s`, a następnie powtarzaj `h/j/k/l`.
5. Otwórz inne sesje przez `Ctrl-s Ctrl-j`, wybierz sesję w fzf i zatwierdź `Enter`.
6. Odłącz się przez `Ctrl-s d`; wróć poleceniem `tmux attach -t projekt`.
