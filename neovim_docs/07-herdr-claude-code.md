<a id="herdr-claude-code"></a>
# Herdr i Claude Code

> Stan na 22 października 2026. WezTerm jest głównym narzędziem (Neovim, konsola, serwery), herdr działa w osobnym workspace `agents` jako centrum agentów.

<a id="herdr"></a>
## Herdr: centrum agentów

Pliki: `herdr/config.toml`, `herdr/agents-status.sh` → `~/.config/herdr/`. Reszta `~/.config/herdr/` (sockety, logi, sesje) nie jest w repozytorium.

Herdr widzi tylko agentów uruchomionych w swoich panelach. Agent w zwykłej karcie WezTerm nie pojawi się w pasku bocznym ani w statusie.

### Z WezTerm

- **`Ctrl-s a`**: Skok do workspace `agents` z herdr; gdy nie istnieje, tworzy go i uruchamia `herdr`.
- **Pasek WezTerm (prawo)**: `herdr ⚙ 2  ⏸ 1  ✓ 1  ○ 3` znaczy: pracuje, czeka na Ciebie, skończył, bezczynny. Pusty, gdy nie ma agentów. Odświeżanie co 5 s.
- Zamknięcie WezTerm nie zabija agentów: serwer herdr działa w tle, a `Ctrl-s a` podłącza się do niego z powrotem.

### W herdr

Prefix herdr to `Ctrl-a` (WezTerm ma `Ctrl-s`, więc się nie gryzą). Naciśnij prefix, puść, potem klawisz.

Pomoc:

- **`Ctrl-a ?`**: Wszystkie aktywne skróty.

Agenci:

- **`Ctrl-a o`**: Skok do agenta z ostatniego powiadomienia (ten, który skończył albo czeka).
- **`Ctrl-a ]`** / **`Ctrl-a [`**: Następny / poprzedni agent.
- **`Ctrl-a g`**: Szybki skok (goto) do workspace, taba lub agenta.

Workspace'y (projekty):

- **`Ctrl-a w`**: Lista workspace'ów.
- **`Ctrl-a Shift-n`**: Nowy workspace.
- **`Ctrl-a Shift-w`**: Zmiana nazwy workspace.
- **`Ctrl-a Shift-d`**: Zamknięcie workspace (z potwierdzeniem).

Taby:

- **`Ctrl-a c`**: Nowy tab.
- **`Ctrl-a n`** / **`Ctrl-a p`**: Następny / poprzedni tab.
- **`Ctrl-a 1`...`9`**: Tab o numerze.
- **`Ctrl-a Shift-t`**: Zmiana nazwy taba.
- **`Ctrl-a Shift-x`**: Zamknięcie taba.

Panele:

- **`Ctrl-a v`** / **`Ctrl-a -`**: Panel obok / poniżej.
- **`Ctrl-a h/j/k/l`**: Przejście między panelami.
- **`Ctrl-a a`**: Poprzedni panel.
- **`Ctrl-a z`**: Powiększenie panelu.
- **`Ctrl-a r`**: Tryb zmiany rozmiaru; `h/j/k/l`, `Esc` kończy.
- **`Ctrl-a x`**: Zamknięcie panelu.

Inne:

- **`Ctrl-a b`**: Zwinięcie / rozwinięcie paska bocznego.
- **`Ctrl-a Shift-r`**: Przeładowanie konfiguracji.
- **`Ctrl-a q`**: Odłączenie; wszystko działa dalej, powrót przez `herdr` albo `Ctrl-s a`.
- **Myszka**: Klik w agenta na pasku bocznym przenosi do niego; przeciąganie krawędzi zmienia rozmiar; prawy przycisk otwiera menu.

### Wygląd i powiadomienia

- Motyw Tokyo Night z fioletowym akcentem; jasna wersja włącza się sama razem z jasnym trybem systemu.
- Pasek boczny: agenci czekający na odpowiedź są na górze; pod agentem szary opis tego, co robi.
- Pasek tabów: licznik agentów, gałąź git, bateria, dzień i godzina.
- Powiadomienia macOS i dźwięk, gdy agent skończy albo czeka.

### Przydatne komendy

- **`herdr agent list`**: Agenci i ich stany.
- **`herdr integration status`**: Zainstalowane integracje (claude).
- **`herdr config check`**: Sprawdzenie konfiguracji.
- **`herdr server stop`**: Zatrzymanie wszystkiego.

Pełna dokumentacja: https://herdr.dev/docs/

<a id="claude-code"></a>
## Claude Code

Pliki: `claude/settings.json`, `claude/CLAUDE.md`, `claude/statusline-command.sh` → `~/.claude/`. Historia rozmów i pamięć projektów nie są w repozytorium.

### Ustawienia

- Model `opus`, effort `xhigh`, pełnoekranowy interfejs, głos włączony.
- Hook `SessionStart` zgłasza sesję do herdr (przywracanie po restarcie).
- Brak globalnych serwerów MCP.

### Wtyczki

- **superpowers**: Z marketplace autora (`obra/superpowers-marketplace`), więc nowe wersje przychodzą od razu po wydaniu.
- **typescript-lsp**, **pyright-lsp**, **gopls-lsp**, **lua-lsp**: Claude widzi definicje, referencje i błędy typów. Serwery: TypeScript i Pyright z Mason, `gopls` i `lua-language-server` z brew.
- Aktualizacja: `/plugin` w Claude albo `claude plugin update <nazwa>`. Lista: `claude plugin list`.

### Pasek statusu

`Model | [====------] | 42% | 84K / 200K | gałąź | projekt`

- Pasek i procent zajętości kontekstu: zielony poniżej 50%, żółty do 80%, czerwony powyżej.
- Liczba tokenów w kontekście i rozmiar okna.
- Gałąź git i nazwa katalogu projektu.

### Wznawianie rozmów

- **`claude --resume`**: Lista poprzednich rozmów w bieżącym katalogu.
- **`claude --resume <id>`**: Konkretna rozmowa.
- **`claude attach <id>`**: Podgląd sesji działającej w tle (`claude --bg`); `Ctrl-z` wraca do shella, sesja działa dalej.
