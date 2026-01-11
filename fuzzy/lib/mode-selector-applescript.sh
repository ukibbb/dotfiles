#!/usr/bin/env bash
# =============================================================================
# mode-selector-applescript.sh - AppleScript GUI dla wyboru trybu (alternatywa dla Swift)
# =============================================================================
# Ten skrypt używa AppleScript zamiast Swift do wyświetlenia natywnego macOS GUI.
# Działa na wszystkich wersjach macOS bez potrzeby kompilacji.
#
# Użycie: ./mode-selector-applescript.sh [project_path]
#
# Output (stdout): Identyfikator wybranego trybu (np. "tmux-nvim-claude")
# Exit code: 0 = sukces, 1 = anulowano
# =============================================================================

# Włącz strict mode
set -euo pipefail

# =============================================================================
# ARGUMENTY
# =============================================================================

# Pobierz ścieżkę projektu (opcjonalna)
PROJECT_PATH="${1:-}"  # Pierwszy argument lub pusty string

# =============================================================================
# DEFINICJE TRYBÓW
# =============================================================================

# Tablica z trybami: "ID|Tytuł|Opis"
MODES=(
    "terminal-only|Terminal (Ghostty)|Tylko terminal Ghostty w wybranym katalogu"
    "terminal-tmux|Terminal + Tmux|Terminal z uruchomionym tmux (bez nazwanej sesji)"
    "tmux-session|Tmux Session|Nazwana sesja tmux z możliwością ponownego podłączenia"
    "tmux-nvim|Tmux + Neovim|Sesja tmux z automatycznie uruchomionym Neovim"
    "tmux-nvim-claude|Tmux + Neovim + Claude Code|Sesja tmux: okno z Neovim + okno z Claude Code"
)

# =============================================================================
# BUDOWANIE LISTY OPCJI DLA APPLESCRIPT
# =============================================================================

# AppleScript wymaga listy w formacie: {"Option 1", "Option 2", ...}
build_choices_list() {
    local choices=""  # String z listą opcji

    # Dla każdego trybu...
    for mode in "${MODES[@]}"; do
        # Rozdziel string po | na 3 części
        IFS='|' read -r id title desc <<< "$mode"

        # Dodaj do listy w formacie: "Tytuł - Opis"
        # Escape'ujemy cudzysłowy w title i desc
        local choice="$title - $desc"
        # Zamień " na \" (escape cudzysłowy dla AppleScript)
        choice="${choice//\"/\\\"}"

        # Dodaj do listy
        if [[ -z "$choices" ]]; then
            # Pierwsz element - bez przecinka na początku
            choices="\"$choice\""
        else
            # Kolejne elementy - dodaj przecinek
            choices="$choices, \"$choice\""
        fi
    done

    # Zwróć listę
    echo "$choices"
}

# =============================================================================
# FUNKCJA: get_mode_id_from_choice
# =============================================================================
# Konwertuje wybraną opcję (tytuł + opis) z powrotem na ID trybu.
#
# Argumenty:
#   $1 - Wybrana opcja (format: "Tytuł - Opis")
#
# Zwraca (stdout): ID trybu (np. "tmux-nvim")
# =============================================================================
get_mode_id_from_choice() {
    local selected_choice="$1"  # Wybrana opcja

    # Dla każdego trybu...
    for mode in "${MODES[@]}"; do
        # Rozdziel string
        IFS='|' read -r id title desc <<< "$mode"

        # Zbuduj format opcji
        local choice="$title - $desc"

        # Sprawdź czy to jest wybrana opcja
        if [[ "$choice" == "$selected_choice" ]]; then
            # Znaleziono - zwróć ID
            echo "$id"
            return 0
        fi
    done

    # Nie znaleziono - zwróć błąd
    echo "" >&2
    return 1
}

# =============================================================================
# GŁÓWNA LOGIKA - Wyświetl GUI i pobierz wybór
# =============================================================================

# Zbuduj listę opcji dla AppleScript
CHOICES_LIST=$(build_choices_list)

# Zbuduj komunikat dla dialogu
# Jeśli podano ścieżkę projektu, dodaj ją do komunikatu
if [[ -n "$PROJECT_PATH" ]]; then
    # Ścieżka podana - wyświetl ją
    DIALOG_TEXT="Wybierz sposób uruchomienia projektu:\n\nProjekt: $PROJECT_PATH"
else
    # Ścieżka nie podana - tylko główny komunikat
    DIALOG_TEXT="Wybierz sposób uruchomienia projektu:"
fi

# Utwórz AppleScript
# AppleScript używa osascript do uruchomienia
# <<EOF ... EOF = heredoc (multi-line string)
SELECTED=$(osascript <<EOF
-- AppleScript do wyświetlenia dialogu z listą wyboru

-- Lista dostępnych opcji
set modeChoices to {$CHOICES_LIST}

-- Wyświetl dialog z listą wyboru
-- choose from list = natywne okno z listą
try
    set selectedMode to choose from list modeChoices ¬
        with prompt "$DIALOG_TEXT" ¬
        with title "Project Launcher" ¬
        default items {item 1 of modeChoices} ¬
        OK button name "Wybierz" ¬
        cancel button name "Anuluj"

    -- Sprawdź czy użytkownik coś wybrał (czy nie kliknął Anuluj)
    if selectedMode is false then
        -- Anulowano - zwróć pusty string
        return ""
    else
        -- Wybrano - zwróć pierwszy element (AppleScript zwraca listę)
        return item 1 of selectedMode
    end if
on error
    -- Błąd - zwróć pusty string
    return ""
end try
EOF
)

# Sprawdź czy użytkownik coś wybrał
if [[ -z "$SELECTED" ]]; then
    # Pusty string = anulowano lub błąd
    exit 1  # Zwróć kod błędu
fi

# Konwertuj wybraną opcję na ID trybu
MODE_ID=$(get_mode_id_from_choice "$SELECTED")

# Sprawdź czy znaleziono ID
if [[ -z "$MODE_ID" ]]; then
    # Nie znaleziono ID - błąd
    echo "Błąd: Nie można znaleźć ID dla wybranej opcji" >&2
    exit 1
fi

# Wypisz ID trybu na stdout (to będzie odczytane przez launcher)
echo "$MODE_ID"

# Zwróć kod sukcesu
exit 0
