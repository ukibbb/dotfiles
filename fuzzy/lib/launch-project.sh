#!/usr/bin/env bash
# =============================================================================
# launch-project.sh - Skrypt uruchamiający projekt w wybranym trybie
# =============================================================================
# Ten skrypt przyjmuje ścieżkę do projektu i tryb uruchomienia, a następnie
# uruchamia Ghostty terminal z odpowiednią konfiguracją (tmux/neovim/claude).
#
# Użycie: ./launch-project.sh <project_path> <mode>
#
# Argumenty:
#   project_path - Pełna ścieżka do katalogu projektu
#   mode         - Identyfikator trybu (terminal-only, tmux-session, etc.)
# =============================================================================

# Włącz strict mode
set -euo pipefail

# =============================================================================
# WALIDACJA ARGUMENTÓW
# =============================================================================

# Sprawdź czy podano wymaganą liczbę argumentów (2)
if [[ $# -lt 2 ]]; then
    # $# = liczba argumentów przekazanych do skryptu
    echo "Błąd: Nieprawidłowa liczba argumentów" >&2  # >&2 = wypisz do stderr
    echo "Użycie: $0 <project_path> <mode>" >&2
    exit 1  # Zakończ z kodem błędu
fi

# Przypisz argumenty do zmiennych z czytelnymi nazwami
PROJECT_PATH="$1"  # Pierwszy argument = ścieżka do projektu
MODE="$2"          # Drugi argument = tryb uruchomienia

# Sprawdź czy ścieżka do projektu istnieje
if [[ ! -d "$PROJECT_PATH" ]]; then
    # -d sprawdza czy to katalog i czy istnieje
    echo "Błąd: Katalog '$PROJECT_PATH' nie istnieje" >&2
    exit 1
fi

# =============================================================================
# FUNKCJA: get_session_name
# =============================================================================
# Tworzy nazwę sesji tmux na podstawie ścieżki projektu.
# Nazwa jest "slug" - tylko alfanumeryczne znaki i myślniki.
#
# Argumenty:
#   $1 - Pełna ścieżka do projektu
#
# Zwraca (stdout): Nazwę sesji (np. "my-project")
# =============================================================================
get_session_name() {
    local project_path="$1"  # Zapisz argument do zmiennej lokalnej

    # Wyciągnij nazwę katalogu (ostatni segment ścieżki)
    # basename "/path/to/my-project" → "my-project"
    local dir_name
    dir_name=$(basename "$project_path")

    # Zamień wszystkie znaki niealfanumeryczne na myślniki
    # tr '.' '-' = zamienia kropki na myślniki
    # sed 's/[^a-zA-Z0-9-]/-/g' = zamienia wszystkie inne znaki na myślniki
    # sed 's/--*/-/g' = redukuje wielokrotne myślniki do jednego
    # tr '[:upper:]' '[:lower:]' = zamienia wielkie litery na małe
    local session_name
    session_name=$(echo "$dir_name" \
        | tr '.' '-' \
        | sed 's/[^a-zA-Z0-9-]/-/g' \
        | sed 's/--*/-/g' \
        | tr '[:upper:]' '[:lower:]')

    # Wypisz nazwę sesji na stdout
    echo "$session_name"
}

# =============================================================================
# FUNKCJA: launch_terminal_only
# =============================================================================
# Uruchamia tylko terminal Ghostty w katalogu projektu.
# Najprostszy tryb - bez tmux, nvim czy claude.
# =============================================================================
launch_terminal_only() {
    # Komenda open -a uruchamia aplikację macOS
    # -a Ghostty = uruchom aplikację Ghostty
    # --args = argumenty przekazywane do aplikacji
    # --working-directory = ustaw katalog roboczy w terminalu
    open -a Ghostty --args --working-directory="$PROJECT_PATH"
}

# =============================================================================
# FUNKCJA: launch_terminal_tmux
# =============================================================================
# Uruchamia terminal Ghostty z tmux (bez nazwanej sesji).
# Tmux uruchamia się ale nie tworzy persystentnej sesji.
# =============================================================================
launch_terminal_tmux() {
    # open -a Ghostty = uruchom Ghostty
    # --args = argumenty dla Ghostty
    # --working-directory = katalog początkowy
    # -e "tmux" = wykonaj komendę "tmux" po uruchomieniu terminala
    open -a Ghostty --args --working-directory="$PROJECT_PATH" -e "tmux"
}

# =============================================================================
# FUNKCJA: launch_tmux_session
# =============================================================================
# Uruchamia nazwana sesję tmux z możliwością reattach.
# Jeśli sesja o tej nazwie już istnieje, podłącza się do niej.
# Jeśli nie istnieje, tworzy nową.
# =============================================================================
launch_tmux_session() {
    # Wygeneruj nazwę sesji na podstawie ścieżki projektu
    local session_name
    session_name=$(get_session_name "$PROJECT_PATH")

    # Sprawdź czy sesja tmux o tej nazwie już istnieje
    # tmux has-session -t "nazwa" = sprawdza czy sesja istnieje
    # 2>/dev/null = ignoruj komunikaty błędów (jeśli sesja nie istnieje)
    if tmux has-session -t "$session_name" 2>/dev/null; then
        # Sesja ISTNIEJE - podłącz się do niej (reattach)
        echo "Sesja '$session_name' już istnieje - podłączanie..." >&2

        # open -a Ghostty z komendą attach
        # tmux attach -t = podłącz do sesji o nazwie
        open -a Ghostty --args -e "tmux attach -t $session_name"
    else
        # Sesja NIE ISTNIEJE - utwórz nową
        echo "Tworzenie nowej sesji '$session_name'..." >&2

        # open -a Ghostty z komendą new-session
        # tmux new-session = utwórz nową sesję
        # -s = nazwa sesji (session name)
        # -c = katalog początkowy (change directory)
        open -a Ghostty --args -e "tmux new-session -s $session_name -c '$PROJECT_PATH'"
    fi
}

# =============================================================================
# FUNKCJA: launch_tmux_nvim
# =============================================================================
# Uruchamia sesję tmux z automatycznie uruchomionym Neovim.
# Jeśli sesja istnieje, podłącza się do niej.
# Jeśli nie istnieje, tworzy nową i uruchamia nvim.
# =============================================================================
launch_tmux_nvim() {
    # Wygeneruj nazwę sesji
    local session_name
    session_name=$(get_session_name "$PROJECT_PATH")

    # Sprawdź czy sesja już istnieje
    if tmux has-session -t "$session_name" 2>/dev/null; then
        # Sesja istnieje - podłącz się
        echo "Sesja '$session_name' już istnieje - podłączanie..." >&2
        open -a Ghostty --args -e "tmux attach -t $session_name"
    else
        # Sesja nie istnieje - utwórz z neovim
        echo "Tworzenie nowej sesji '$session_name' z Neovim..." >&2

        # Budujemy komendę tmux z kilkoma parametrami:
        # new-session -s = utwórz sesję o nazwie
        # -c = ustaw katalog roboczy
        # \; = separator komend tmux (escape dla bash)
        # send-keys 'nvim' C-m = wyślij tekst "nvim" + Enter do okna
        #   C-m = Control+M = klawisz Enter
        open -a Ghostty --args -e "tmux new-session -s $session_name -c '$PROJECT_PATH' \\; send-keys 'nvim' C-m"
    fi
}

# =============================================================================
# FUNKCJA: launch_tmux_nvim_claude
# =============================================================================
# Uruchamia sesję tmux z dwoma oknami:
#   1. Okno "editor" - Neovim
#   2. Okno "claude" - Claude Code
#
# Jeśli sesja istnieje:
#   - Sprawdza czy ma okno "claude", jeśli nie - dodaje je
#   - Podłącza się do istniejącej sesji
# =============================================================================
launch_tmux_nvim_claude() {
    # Wygeneruj nazwę sesji
    local session_name
    session_name=$(get_session_name "$PROJECT_PATH")

    # Sprawdź czy sesja już istnieje
    if tmux has-session -t "$session_name" 2>/dev/null; then
        echo "Sesja '$session_name' już istnieje..." >&2

        # Sprawdź czy sesja ma okno o nazwie "claude"
        # tmux list-windows = wylistuj wszystkie okna w sesji
        # -t = dla sesji o nazwie
        # -F "#{window_name}" = formatuj output - tylko nazwa okna
        # grep -q "claude" = szukaj czy jest okno "claude" (-q = quiet, tylko exit code)
        if ! tmux list-windows -t "$session_name" -F "#{window_name}" | grep -q "claude"; then
            # Okno "claude" NIE ISTNIEJE - dodaj je
            echo "Dodawanie okna 'claude' do sesji..." >&2

            # tmux new-window = utwórz nowe okno w istniejącej sesji
            # -t = w sesji o nazwie
            # -n = nazwa okna (window name)
            # -c = katalog roboczy dla nowego okna
            # \; send-keys = wyślij komendę do okna
            tmux new-window -t "$session_name" -n claude -c "$PROJECT_PATH" \; send-keys 'claude-code' C-m
        else
            echo "Okno 'claude' już istnieje w sesji" >&2
        fi

        # Podłącz się do sesji
        open -a Ghostty --args -e "tmux attach -t $session_name"
    else
        # Sesja NIE ISTNIEJE - utwórz nową z dwoma oknami
        echo "Tworzenie nowej sesji '$session_name' z Neovim i Claude Code..." >&2

        # Złożona komenda tmux tworząca sesję z dwoma oknami:
        # 1. new-session -s = utwórz sesję
        #    -c = katalog roboczy
        #    -n editor = nazwa pierwszego okna
        # 2. \; send-keys 'nvim' C-m = uruchom nvim w pierwszym oknie
        # 3. \; new-window = utwórz drugie okno
        #    -n claude = nazwa drugiego okna
        #    -c = katalog roboczy (ten sam)
        # 4. \; send-keys 'claude-code' C-m = uruchom claude-code w drugim oknie
        # 5. \; select-window -t editor = przełącz fokus z powrotem na okno "editor"
        #    (użytkownik zaczyna z neovim na pierwszym planie)
        open -a Ghostty --args -e "tmux new-session -s $session_name -c '$PROJECT_PATH' -n editor \\; send-keys 'nvim' C-m \\; new-window -n claude -c '$PROJECT_PATH' \\; send-keys 'claude-code' C-m \\; select-window -t editor"
    fi
}

# =============================================================================
# MAIN - Główna logika wyboru trybu
# =============================================================================

# Wypisz informację diagnostyczną (stdout)
echo "Uruchamianie projektu: $PROJECT_PATH" >&2
echo "Tryb: $MODE" >&2

# Switch na podstawie wybranego trybu
case "$MODE" in
    "terminal-only")
        # Tryb 1: Tylko terminal
        launch_terminal_only
        ;;

    "terminal-tmux")
        # Tryb 2: Terminal + tmux (bez sesji)
        launch_terminal_tmux
        ;;

    "tmux-session")
        # Tryb 3: Nazwana sesja tmux
        launch_tmux_session
        ;;

    "tmux-nvim")
        # Tryb 4: Sesja tmux + Neovim
        launch_tmux_nvim
        ;;

    "tmux-nvim-claude")
        # Tryb 5: Sesja tmux + Neovim + Claude Code
        launch_tmux_nvim_claude
        ;;

    *)
        # Nieznany tryb - wypisz błąd i zakończ
        echo "Błąd: Nieznany tryb '$MODE'" >&2
        echo "Dostępne tryby: terminal-only, terminal-tmux, tmux-session, tmux-nvim, tmux-nvim-claude" >&2
        exit 1
        ;;
esac

# Jeśli dotarliśmy tutaj, uruchomienie się powiodło
echo "Projekt uruchomiony!" >&2
exit 0
