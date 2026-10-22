<a id="narzedzia-terminala"></a>
# Narzędzia terminala

> Stan na 22 października 2026. Konfiguracje leżą w repozytorium i są podlinkowane przez `install.sh`. Shell nie używa już oh-my-zsh ani nvm.

<a id="narzedzia-sciaga"></a>
## Ściąga

- **`Ctrl-r`**: Wyszukiwanie w historii komend (atuin).
- **`Ctrl-t`**: Wybór pliku przez fzf z podglądem bat; wkleja ścieżkę do linii.
- **`Alt-c`**: Wybór katalogu przez fzf z podglądem drzewa; od razu `cd`.
- **`→` lub `End`**: Przyjęcie szarej podpowiedzi z historii (autosuggestions).
- **`ll`**: Lista plików ze szczegółami i statusem git.
- **`lt`**: Drzewo katalogu na 2 poziomy.
- **`cat plik`**: Podgląd z kolorowaniem składni (bat).
- **`git diff`**: Diff przez delta; `n` / `N` skacze między plikami.
- **`btop`**: Monitor systemu.
- **`n`** / **`nt`**: Skok do projektu przez fzf / skok do workspace WezTerm.

<a id="shell"></a>
## Shell: zsh bez oh-my-zsh

Plik: `.zshrc`. Ładuje się w kolejności: PATH, opcje, uzupełnianie, narzędzia, aliasy, funkcje, wtyczki.

- **Historia**: 100 000 wpisów, wspólna dla wszystkich otwartych terminali. Komenda poprzedzona spacją nie trafia do historii.
- **Uzupełnianie**: `Tab` otwiera menu, po którym chodzi się strzałkami. Wielkość liter nie ma znaczenia.
- **`auto_cd`**: Wpisanie samej nazwy katalogu robi `cd`.
- **Edycja linii**: Skróty jak w emacs: `Ctrl-a` początek, `Ctrl-e` koniec, `Alt-b` / `Alt-f` słowo wstecz/naprzód, `Ctrl-w` usuń słowo.
- **zsh-autosuggestions**: Szara podpowiedź z historii. `→` przyjmuje całość, `Alt-f` jedno słowo.
- **zsh-syntax-highlighting**: Zielona komenda istnieje, czerwona nie istnieje. Literówka widoczna przed `Enter`.

<a id="starship"></a>
## starship: prompt

Plik: `starship/starship.toml` → `~/.config/starship.toml`.

Pierwsza linia promptu pokazuje kolejno:

- **Katalog**: Skrócony do katalogu głównego repozytorium.
- **Gałąź git**: Fioletowa, z ikoną.
- **Status git**: `!` zmienione, `+` dodane, `?` nieśledzone, `⇡` / `⇣` commity do wypchnięcia / pobrania.
- **Wersja języka**: Node, Python, Go, Lua lub Bun, tylko gdy projekt go używa.
- **`⏱`**: Czas komendy, gdy trwała ponad 2 s.

Druga linia to `❯`: zielony po sukcesie, czerwony po błędzie poprzedniej komendy.

Diagnostyka: `starship explain` opisuje każdy element bieżącego promptu, `starship timings` pokazuje, co go spowalnia.

<a id="atuin"></a>
## atuin: historia komend

Plik: `atuin/config.toml` → `~/.config/atuin/config.toml`. Dane tylko lokalnie, bez synchronizacji.

- **`Ctrl-r`**: Otwiera wyszukiwarkę. Wpisuj fragmenty komendy; dopasowanie jest rozmyte.
- **`Enter`**: Uruchamia wybraną komendę.
- **`Tab`**: Wkleja komendę do linii bez uruchamiania, do edycji.
- **`Ctrl-r` w wyszukiwarce**: Przełącza zakres: wszystko → ten komputer → ta sesja → ten katalog.
- **`Esc`**: Wyjście.
- **Strzałka w górę**: Zostaje zwykła historią zsh; atuin jej nie przejmuje.
- **`atuin stats`**: Najczęściej używane komendy.
- **`atuin search --cwd . <tekst>`**: Wyszukiwanie z linii komend tylko w bieżącym katalogu.

Atuin zapisuje też kod wyjścia i czas trwania, więc w wyszukiwarce widać, które wywołania się nie powiodły. Komendy w stylu `export ...KEY=...`, `...TOKEN=...`, `...SECRET=...`, `...PASSWORD=...` nie są zapisywane.

<a id="mise"></a>
## mise: wersje Node, Go i Pythona

Plik: `mise/config.toml` → `~/.config/mise/config.toml`. Zastępuje nvm.

- **Globalnie**: Node `24.13.0` (to samo, co wcześniej domyślne w nvm).
- **`mise use node@22`** w katalogu projektu: Tworzy `mise.toml` i przypina wersję dla tego projektu. Po wejściu do katalogu wersja zmienia się sama.
- **`mise use -g node@lts`**: Zmiana wersji globalnej.
- **`mise ls`**: Zainstalowane i aktywne wersje.
- **`mise ls-remote node`**: Dostępne wersje.
- **`mise current`**: Co jest aktywne tutaj.
- **`.nvmrc` / `.node-version`**: Respektowane w istniejących projektach.

Globalne pakiety npm (`codex`, `pi`, `gemini`, `crush`, `opencode`, `buli`, `agent-browser`) są zainstalowane w Node z mise. Po zmianie globalnej wersji Node trzeba je doinstalować: `npm i -g <pakiet>`.

Stary katalog `~/.nvm` nie jest już ładowany; można go usunąć, gdy wszystko działa.

<a id="direnv"></a>
## direnv: zmienne środowiskowe per katalog

Bez pliku konfiguracyjnego; hook w `.zshrc`.

- W katalogu projektu utwórz `.envrc`, na przykład `dotenv` (wczytuje `.env`) albo `export DATABASE_URL=...`.
- **`direnv allow`**: Zatwierdza plik. Bez tego direnv go nie wykona, także po każdej zmianie `.envrc`.
- Po wejściu do katalogu zmienne się ładują, po wyjściu znikają.
- **`direnv deny`**: Cofa zgodę.

`.envrc` z sekretami dopisz do `.gitignore` projektu.

<a id="eza-bat"></a>
## eza i bat: ls i cat

Pliki: `bat/config` → `~/.config/bat/config`. eza nie ma pliku; ustawienia są w aliasach.

- **`ls`**: Ikonki, katalogi najpierw.
- **`ll`**: Szczegóły i kolumna statusu git.
- **`la`**: Jak `ll`, z plikami ukrytymi.
- **`lt`**: Drzewo na 2 poziomy; `lt -L 4` głębiej.
- **`cat plik`**: Kolorowanie składni bez numerów linii, dobre do kopiowania.
- **`bat plik`**: Pełny widok z numerami linii, zmianami git i przewijaniem.
- **`command cat`** / **`command ls`**: Oryginalne narzędzia, gdy potrzebny czysty wynik w skrypcie.

<a id="delta"></a>
## git-delta: diffy

Plik: `git/gitconfig` → `~/.gitconfig`.

- `git diff`, `git show`, `git log -p` i `git add -p` używają delta automatycznie.
- **`n` / `N`**: Następny / poprzedni plik w diffie.
- **`q`**: Wyjście.
- **Widok obok siebie**: `git -c delta.side-by-side=true diff`.

<a id="btop"></a>
## btop: monitor systemu

Plik: `btop/btop.conf` → `~/.config/btop/btop.conf`. Klawisze vim są włączone.

- **`j` / `k`**: Ruch po liście procesów.
- **`f`**: Filtr procesów po nazwie.
- **`Enter`**: Szczegóły procesu.
- **`t`**: Zakończenie wybranego procesu (SIGTERM).
- **`Shift-k`**: Zabicie wybranego procesu (SIGKILL); samo `k` przewija w górę, bo klawisze vim są włączone.
- **`Shift-h`**: Pomoc z listą wszystkich klawiszy.
- **`e`**: Widok drzewa procesów.
- **`Esc`**: Menu i opcje.
- **`q`**: Wyjście.

Przydaje się, gdy serwer dev lub agent zjada procesor albo pamięć.

<a id="nowy-mac"></a>
## Odtworzenie na nowym Macu

```sh
brew bundle --file ~/Desktop/Projekty/dotfiles/Brewfile
bash ~/Desktop/Projekty/dotfiles/install.sh install
mise install
atuin import zsh
```
