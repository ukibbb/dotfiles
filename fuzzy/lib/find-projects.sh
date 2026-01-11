#!/usr/bin/env bash
# =============================================================================
# find-projects.sh - Skrypt do skanowania systemu plików w poszukiwaniu projektów
# =============================================================================
# Ten skrypt skanuje system plików (domyślnie $HOME) i generuje listę
# wszystkich folderów, z wyłączeniem tych zdefiniowanych w konfiguracji.
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

# Pobierz ścieżkę do katalogu gdzie znajduje się ten skrypt
# ${BASH_SOURCE[0]} = ścieżka do bieżącego skryptu
# dirname = wyciąga katalog z pełnej ścieżki
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ścieżka do głównego katalogu projektu (poziom wyżej niż lib/)
# dirname "$SCRIPT_DIR" = katalog parent dla lib/
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Ścieżka do pliku konfiguracyjnego
CONFIG_FILE="$PROJECT_ROOT/config.yaml"

# Katalog startowy dla wyszukiwania (domyślnie $HOME użytkownika)
START_DIR="${HOME}"

# =============================================================================
# FUNKCJA: parse_config
# =============================================================================
# Parsuje plik config.yaml i wyciąga listę wykluczonych folderów.
# Używa prostego grep/sed jeśli yq nie jest dostępne.
#
# Zwraca: Lista wykluczonych folderów (jeden na linię)
# =============================================================================
parse_config() {
    # Sprawdź czy plik konfiguracyjny istnieje
    if [[ ! -f "$CONFIG_FILE" ]]; then
        # Jeśli nie istnieje, zwróć pustą listę (brak wykluczeń)
        echo ""
        return
    fi

    # Sprawdź czy mamy zainstalowane yq (parser YAML)
    if command -v yq &> /dev/null; then
        # yq jest dostępne - użyj go do parsowania YAML
        # .excluded_dirs[] = wyciąga wszystkie elementy z tablicy excluded_dirs
        yq eval '.excluded_dirs[]' "$CONFIG_FILE" 2>/dev/null || echo ""
    else
        # yq nie jest dostępne - użyj prostego parsera grep/sed
        # Parsujemy tylko sekcję excluded_dirs do następnej sekcji [...]

        # sed -n '/^excluded_dirs:/,/^[a-z]/p' = wyciąga linie od excluded_dirs do następnej sekcji
        # grep '^ *-' = wybiera tylko linie z listą (zaczynające się od -)
        # sed 's/^ *- *//' = usuwa "- " z początku
        # sed 's/"//g' = usuwa cudzysłowy
        sed -n '/^excluded_dirs:/,/^[a-z]/p' "$CONFIG_FILE" \
            | grep '^ *-' \
            | sed 's/^ *- *//' \
            | sed 's/"//g' \
            | sed "s/'//g" \
            || echo ""
    fi
}

# =============================================================================
# FUNKCJA: build_find_command
# =============================================================================
# Buduje komendę find/fd z odpowiednimi wykluczeniami.
#
# Argumenty:
#   $1 - Lista wykluczonych folderów (rozdzielona nowymi liniami)
#
# Zwraca: Wykonuje komendę find/fd i wypisuje wyniki
# =============================================================================
build_find_command() {
    local exclusions="$1"  # Zapisz pierwszy argument do zmiennej lokalnej

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
        while IFS= read -r exclusion; do
            # Pomiń puste linie
            [[ -z "$exclusion" ]] && continue

            # Usuń gwiazdki z początku wzorca dla fd
            # fd nie wymaga */ na początku - automatycznie szuka w całym drzewie
            local pattern="$exclusion"
            # Zamień "*/folder" na "folder"
            pattern="${pattern#\*/}"

            # Dodaj --exclude do tablicy argumentów
            fd_args+=(--exclude "$pattern")
        done <<< "$exclusions"

        # Dodaj domyślne wykluczenia (ważne systemowe foldery)
        fd_args+=(
            --exclude ".git"
            --exclude "node_modules"
            --exclude ".cache"
            --exclude "Library"
            --exclude "Applications"
        )

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
        local prune_expr=""
        local first=true

        while IFS= read -r exclusion; do
            # Pomiń puste linie
            [[ -z "$exclusion" ]] && continue

            # Zamień wzorce glob (np. "*/node_modules") na format find
            # Jeśli zawiera */, użyj -path zamiast -name
            if [[ "$exclusion" == *"/"* ]]; then
                # Zawiera slash - użyj -path dla pełnej ścieżki
                local pattern="*/$exclusion"

                if [[ "$first" == true ]]; then
                    # Pierwszy element - rozpocznij wyrażenie
                    prune_expr="\( -path '$pattern'"
                    first=false
                else
                    # Kolejne elementy - dodaj z -o (OR)
                    prune_expr="$prune_expr -o -path '$pattern'"
                fi
            else
                # Tylko nazwa folderu - użyj -name
                if [[ "$first" == true ]]; then
                    prune_expr="\( -name '$exclusion'"
                    first=false
                else
                    prune_expr="$prune_expr -o -name '$exclusion'"
                fi
            fi
        done <<< "$exclusions"

        # Jeśli są jakieś wykluczenia, dodaj je do komendy find
        if [[ -n "$prune_expr" ]]; then
            # Zamknij wyrażenie i dodaj -prune (nie wchodź do tych folderów)
            prune_expr="$prune_expr \) -prune -o"
            find_cmd="$find_cmd $prune_expr"
        fi

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
    # Sprawdź czy istnieje config file, jeśli nie użyj domyślnego
    if [[ ! -f "$CONFIG_FILE" ]]; then
        # Spróbuj użyć config.example.yaml jeśli config.yaml nie istnieje
        if [[ -f "$PROJECT_ROOT/config.example.yaml" ]]; then
            CONFIG_FILE="$PROJECT_ROOT/config.example.yaml"
        fi
    fi

    # Parsuj konfigurację i pobierz listę wykluczeń
    local exclusions
    exclusions=$(parse_config)

    # Zbuduj i wykonaj komendę find/fd
    build_find_command "$exclusions"
}

# Wywołaj funkcję main
main
