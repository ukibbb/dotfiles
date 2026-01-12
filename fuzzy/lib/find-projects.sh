#!/usr/bin/env bash
# =============================================================================
# find-projects.sh - Skrypt do skanowania systemu plików w poszukiwaniu projektów
# =============================================================================
# Ten skrypt skanuje system plików (domyślnie $HOME) i generuje listę
# wszystkich folderów, z wyłączeniem najczęstszych folderów systemowych.
#
# Output: Lista ścieżek (jedna na linię) do użycia z fzf
# =============================================================================

# Włącz strict mode:
# -e: zakończ skrypt jeśli jakakolwiek komenda zwróci błąd
# -u: traktuj niezdefiniowane zmienne jako błąd
# -o pipefail: propaguj błędy w pipeline
set -euo pipefail

# =============================================================================
# KONFIGURACJA - Zmienne globalne
# =============================================================================

# Katalog startowy dla wyszukiwania (domyślnie $HOME użytkownika)
START_DIR="${HOME}"

# Domyślne wykluczenia (najczęstsze foldery które chcemy pominąć)
DEFAULT_EXCLUSIONS=(
    "Library"
    "Applications"
    ".Trash"
    ".cache"
    ".npm"
    ".yarn"
    "node_modules"
    ".git"
    ".svn"
    "dist"
    "build"
    "target"
)

# =============================================================================
# FUNKCJA: build_find_command
# =============================================================================
# Buduje komendę find/fd z domyślnymi wykluczeniami.
#
# Zwraca: Wykonuje komendę find/fd i wypisuje wyniki
# =============================================================================
build_find_command() {
    # Sprawdź czy mamy zainstalowane fd (szybsza alternatywa dla find)
    if command -v fd &> /dev/null; then
        # === UŻYWAMY FD ===

        # Zbuduj tablicę z argumentami dla fd (bezpieczniejsze niż eval)
        local fd_args=(
            --type d                # Szukaj tylko katalogów
            --hidden                # Włącz ukryte pliki/foldery
            --absolute-path         # Zwracaj pełne ścieżki
        )

        # Dla każdego wykluczenia dodaj flagę --exclude
        for exclusion in "${DEFAULT_EXCLUSIONS[@]}"; do
            # Dodaj --exclude do tablicy argumentów
            fd_args+=(--exclude "$exclusion")
        done

        # Wywołaj fd z wszystkimi argumentami
        # . = wzorzec (dowolny katalog)
        # "$START_DIR" = katalog startowy
        fd "${fd_args[@]}" . "$START_DIR"

    else
        # === UŻYWAMY FIND (fallback) ===

        # Rozpocznij budowanie komendy find
        local find_cmd="find '$START_DIR'"

        # -type d = szukaj tylko katalogów
        find_cmd="$find_cmd -type d"

        # Buduj listę wykluczeń dla find
        # Format: \( -name "folder1" -o -name "folder2" \) -prune -o
        local prune_expr="\("
        local first=true

        for exclusion in "${DEFAULT_EXCLUSIONS[@]}"; do
            if [[ "$first" == true ]]; then
                # Pierwszy element - rozpocznij wyrażenie
                prune_expr="$prune_expr -name '$exclusion'"
                first=false
            else
                # Kolejne elementy - dodaj z -o (OR)
                prune_expr="$prune_expr -o -name '$exclusion'"
            fi
        done

        # Zamknij wyrażenie i dodaj -prune (nie wchodź do tych folderów)
        prune_expr="$prune_expr \) -prune -o"
        find_cmd="$find_cmd $prune_expr"

        # -type d -print = wypisz tylko katalogi (nie pliki)
        find_cmd="$find_cmd -type d -print"

        # Wykonaj zbudowaną komendę
        eval "$find_cmd"
    fi
}

# =============================================================================
# MAIN - Główna logika skryptu
# =============================================================================

main() {
    # Zbuduj i wykonaj komendę find/fd z domyślnymi wykluczeniami
    build_find_command
}

# Wywołaj funkcję main
main
