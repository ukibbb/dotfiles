#!/usr/bin/env bash
# =============================================================================
# install.sh - Skrypt instalacyjny dla Project Launcher
# =============================================================================
# Ten skrypt:
#   1. Sprawdza wymagane zależności (Swift, fzf, etc.)
#   2. Kompiluje mode-selector (Swift GUI)
#   3. Ustawia uprawnienia wykonywania dla skryptów
#   4. Opcjonalnie dodaje launcher do PATH
#   5. Tworzy config.yaml z config.example.yaml
#   6. Pokazuje instrukcje konfiguracji Hammerspoon
#
# Użycie:
#   ./install.sh
# =============================================================================

# Włącz strict mode
set -euo pipefail

# =============================================================================
# KOLORY - Dla czytelniejszego outputu
# =============================================================================

# Kody ANSI dla kolorowania tekstu w terminalu
# \033[ = rozpoczęcie kodu ANSI
# [0m = reset (powrót do domyślnego koloru)
RED='\033[0;31m'      # Czerwony (błędy)
GREEN='\033[0;32m'    # Zielony (sukces)
YELLOW='\033[0;33m'   # Żółty (ostrzeżenia)
BLUE='\033[0;34m'     # Niebieski (informacje)
NC='\033[0m'          # No Color (reset koloru)

# =============================================================================
# KONFIGURACJA - Ścieżki
# =============================================================================

# Pobierz ścieżkę do katalogu gdzie znajduje się ten skrypt
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ścieżki do poszczególnych komponentów
LIB_DIR="$SCRIPT_DIR/lib"
MODE_SELECTOR_SRC="$LIB_DIR/mode-selector.swift"
MODE_SELECTOR_BIN="$LIB_DIR/mode-selector"
LAUNCHER_SCRIPT="$SCRIPT_DIR/launcher"
CONFIG_FILE="$SCRIPT_DIR/config.yaml"
CONFIG_EXAMPLE="$SCRIPT_DIR/config.example.yaml"
HAMMERSPOON_CONFIG="$SCRIPT_DIR/hammerspoon-init.lua"

# =============================================================================
# FUNKCJA: print_header
# =============================================================================
# Wypisuje kolorowy nagłówek sekcji.
#
# Argumenty:
#   $1 - Tekst nagłówka
# =============================================================================
print_header() {
    # -e = interpretuj escape sequences (\n, kolory ANSI)
    echo -e "\n${BLUE}===================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===================================${NC}\n"
}

# =============================================================================
# FUNKCJA: print_success
# =============================================================================
# Wypisuje wiadomość sukcesu (zielony kolor).
#
# Argumenty:
#   $1 - Tekst wiadomości
# =============================================================================
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# =============================================================================
# FUNKCJA: print_error
# =============================================================================
# Wypisuje wiadomość błędu (czerwony kolor).
#
# Argumenty:
#   $1 - Tekst błędu
# =============================================================================
print_error() {
    # >&2 = wypisz do stderr (standard error)
    echo -e "${RED}✗ $1${NC}" >&2
}

# =============================================================================
# FUNKCJA: print_warning
# =============================================================================
# Wypisuje ostrzeżenie (żółty kolor).
#
# Argumenty:
#   $1 - Tekst ostrzeżenia
# =============================================================================
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# =============================================================================
# FUNKCJA: print_info
# =============================================================================
# Wypisuje informację (niebieski kolor).
#
# Argumenty:
#   $1 - Tekst informacji
# =============================================================================
print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# =============================================================================
# FUNKCJA: check_command
# =============================================================================
# Sprawdza czy komenda jest dostępna w systemie.
#
# Argumenty:
#   $1 - Nazwa komendy do sprawdzenia
#
# Zwraca: 0 jeśli komenda istnieje, 1 jeśli nie
# =============================================================================
check_command() {
    local cmd="$1"  # Nazwa komendy

    # command -v = zwraca ścieżkę do komendy jeśli istnieje
    # &>/dev/null = ignoruj cały output (stdout i stderr)
    if command -v "$cmd" &>/dev/null; then
        return 0  # Komenda istnieje - zwróć sukces
    else
        return 1  # Komenda nie istnieje - zwróć błąd
    fi
}

# =============================================================================
# KROK 1: Sprawdź wymagane zależności
# =============================================================================
check_dependencies() {
    print_header "Sprawdzanie zależności"

    # Flaga czy wszystkie zależności są dostępne
    local all_ok=true

    # --- Swift compiler (WYMAGANY) ---
    if check_command "swiftc"; then
        # swiftc znaleziony - sprawdź wersję
        local swift_version
        swift_version=$(swiftc --version | head -n1)  # Pierwsza linia z --version
        print_success "Swift compiler: $swift_version"
    else
        # swiftc NIE znaleziony
        print_error "Swift compiler nie jest zainstalowany"
        print_info "Swift jest wymagany do kompilacji GUI"
        print_info "Zainstaluj Xcode Command Line Tools: xcode-select --install"
        all_ok=false
    fi

    # --- fzf (WYMAGANY) ---
    if check_command "fzf"; then
        # fzf znaleziony - sprawdź wersję
        local fzf_version
        fzf_version=$(fzf --version | cut -d' ' -f1)  # Wyciągnij numer wersji
        print_success "fzf: $fzf_version"
    else
        # fzf NIE znaleziony
        print_error "fzf nie jest zainstalowany"
        print_info "fzf jest wymagany do wyboru projektów"
        print_info "Zainstaluj: brew install fzf"
        all_ok=false
    fi

    # --- fd (OPCJONALNY) ---
    if check_command "fd"; then
        # fd znaleziony (szybsza alternatywa dla find)
        local fd_version
        fd_version=$(fd --version | cut -d' ' -f2)
        print_success "fd: $fd_version (opcjonalny, ale zalecany)"
    else
        # fd NIE znaleziony - to OK, użyjemy find
        print_warning "fd nie jest zainstalowany (opcjonalny)"
        print_info "fd jest szybszą alternatywą dla find"
        print_info "Zainstaluj (opcjonalnie): brew install fd"
    fi

    # --- yq (OPCJONALNY) ---
    if check_command "yq"; then
        # yq znaleziony (parser YAML)
        local yq_version
        yq_version=$(yq --version 2>&1 | head -n1 | cut -d' ' -f3 || echo "unknown")
        print_success "yq: $yq_version (opcjonalny)"
    else
        # yq NIE znaleziony - to OK, użyjemy prostego parsera
        print_warning "yq nie jest zainstalowany (opcjonalny)"
        print_info "yq ułatwia parsowanie YAML, ale nie jest wymagany"
        print_info "Zainstaluj (opcjonalnie): brew install yq"
    fi

    # --- Ghostty (WYMAGANY do uruchomienia) ---
    # Sprawdzamy czy aplikacja Ghostty istnieje
    if [[ -d "/Applications/Ghostty.app" ]]; then
        print_success "Ghostty: Zainstalowany"
    else
        # Ghostty NIE znaleziony
        print_warning "Ghostty nie jest zainstalowany"
        print_info "Ghostty jest wymagany do uruchamiania projektów"
        print_info "Pobierz z: https://ghostty.org/"
        # To nie jest błąd krytyczny (można zainstalować później)
    fi

    # --- tmux (OPCJONALNY, ale zalecany) ---
    if check_command "tmux"; then
        # tmux znaleziony
        local tmux_version
        tmux_version=$(tmux -V | cut -d' ' -f2)
        print_success "tmux: $tmux_version"
    else
        # tmux NIE znaleziony
        print_warning "tmux nie jest zainstalowany (opcjonalny)"
        print_info "tmux jest wymagany dla większości trybów uruchomienia"
        print_info "Zainstaluj: brew install tmux"
    fi

    # Sprawdź czy wszystkie WYMAGANE zależności są OK
    if [[ "$all_ok" == false ]]; then
        # Brakuje wymaganych zależności
        print_error "Brakuje wymaganych zależności!"
        echo ""
        print_info "Zainstaluj brakujące pakiety i uruchom install.sh ponownie"
        exit 1  # Zakończ z błędem
    fi

    print_success "Wszystkie wymagane zależności są dostępne"
}

# =============================================================================
# KROK 2: Kompiluj mode-selector
# =============================================================================
compile_mode_selector() {
    print_header "Kompilacja mode-selector"

    # Sprawdź czy plik źródłowy istnieje
    if [[ ! -f "$MODE_SELECTOR_SRC" ]]; then
        print_error "Nie znaleziono pliku źródłowego: $MODE_SELECTOR_SRC"
        exit 1
    fi

    # Kompiluj Swift binary
    print_info "Kompilowanie $MODE_SELECTOR_SRC..."

    # swiftc -o <output> <source>
    # -o = ścieżka do pliku wynikowego
    if swiftc -o "$MODE_SELECTOR_BIN" "$MODE_SELECTOR_SRC"; then
        # Kompilacja się powiodła
        print_success "mode-selector skompilowany pomyślnie"

        # Sprawdź rozmiar skompilowanego binary
        local size
        # ls -lh = lista z rozmiarami w formacie human-readable
        # awk '{print $5}' = wyciągnij 5. kolumnę (rozmiar pliku)
        size=$(ls -lh "$MODE_SELECTOR_BIN" | awk '{print $5}')
        print_info "Rozmiar binary: $size"
    else
        # Kompilacja się nie powiodła
        print_error "Kompilacja mode-selector nie powiodła się"
        exit 1
    fi
}

# =============================================================================
# KROK 3: Ustaw uprawnienia wykonywania
# =============================================================================
set_permissions() {
    print_header "Ustawianie uprawnień"

    # Lista plików które powinny być wykonywalne
    local executables=(
        "$LAUNCHER_SCRIPT"
        "$LIB_DIR/find-projects.sh"
        "$LIB_DIR/launch-project.sh"
        "$MODE_SELECTOR_BIN"
    )

    # Dla każdego pliku...
    for file in "${executables[@]}"; do
        # Sprawdź czy plik istnieje
        if [[ -f "$file" ]]; then
            # chmod +x = dodaj uprawnienie wykonywania
            chmod +x "$file"

            # Wyciągnij nazwę pliku (bez pełnej ścieżki)
            local filename
            filename=$(basename "$file")

            print_success "Uprawnienia ustawione: $filename"
        else
            print_warning "Plik nie istnieje: $file"
        fi
    done
}

# =============================================================================
# KROK 4: Utwórz config.yaml
# =============================================================================
create_config() {
    print_header "Konfiguracja"

    # Sprawdź czy config.yaml już istnieje
    if [[ -f "$CONFIG_FILE" ]]; then
        # Config już istnieje - nie nadpisuj
        print_warning "config.yaml już istnieje - pomijam"
        print_info "Jeśli chcesz zresetować konfigurację, usuń $CONFIG_FILE"
    else
        # Config nie istnieje - skopiuj z example
        if [[ -f "$CONFIG_EXAMPLE" ]]; then
            # Skopiuj config.example.yaml -> config.yaml
            cp "$CONFIG_EXAMPLE" "$CONFIG_FILE"
            print_success "Utworzono config.yaml z config.example.yaml"
            print_info "Możesz edytować $CONFIG_FILE aby dostosować wykluczenia"
        else
            # Brak config.example.yaml
            print_error "Nie znaleziono $CONFIG_EXAMPLE"
            exit 1
        fi
    fi
}

# =============================================================================
# KROK 5: Opcjonalnie dodaj launcher do PATH
# =============================================================================
setup_path() {
    print_header "Dodawanie do PATH (opcjonalne)"

    # Zapytaj użytkownika czy chce dodać launcher do PATH
    echo -n "Czy chcesz dodać launcher do PATH? (t/n): "
    read -r response  # Czytaj odpowiedź użytkownika

    # Konwertuj odpowiedź na małe litery
    # tr '[:upper:]' '[:lower:]' = zamień wielkie na małe
    response=$(echo "$response" | tr '[:upper:]' '[:lower:]')

    # Sprawdź odpowiedź
    if [[ "$response" == "t" || "$response" == "y" || "$response" == "yes" || "$response" == "tak" ]]; then
        # Użytkownik chce dodać do PATH

        # Sprawdź która lokalizacja istnieje
        # Typowe lokalizacje dla user binaries: ~/bin lub ~/.local/bin
        local bin_dir=""

        if [[ -d "$HOME/bin" ]]; then
            # ~/bin istnieje - użyj go
            bin_dir="$HOME/bin"
        elif [[ -d "$HOME/.local/bin" ]]; then
            # ~/.local/bin istnieje - użyj go
            bin_dir="$HOME/.local/bin"
        else
            # Żadna nie istnieje - utwórz ~/.local/bin
            print_info "Tworzenie ~/.local/bin..."
            mkdir -p "$HOME/.local/bin"
            bin_dir="$HOME/.local/bin"
        fi

        # Utwórz symlink do launcher
        local symlink_path="$bin_dir/project-launcher"

        # Sprawdź czy symlink już istnieje
        if [[ -L "$symlink_path" ]]; then
            # Symlink już istnieje - usuń stary
            print_warning "Symlink już istnieje - aktualizuję"
            rm "$symlink_path"
        fi

        # Utwórz symlink
        # ln -s <target> <link_name>
        ln -s "$LAUNCHER_SCRIPT" "$symlink_path"

        print_success "Utworzono symlink: $symlink_path"

        # Sprawdź czy $bin_dir jest w PATH
        # $PATH = zmienna środowiskowa z listą katalogów (separator :)
        # case ... in ... esac = pattern matching
        case ":$PATH:" in
            *":$bin_dir:"*)
                # $bin_dir JUŻ JEST w PATH
                print_success "$bin_dir jest już w PATH"
                print_info "Możesz teraz uruchomić: project-launcher"
                ;;
            *)
                # $bin_dir NIE JEST w PATH - dodaj instrukcje
                print_warning "$bin_dir nie jest w PATH"
                echo ""
                print_info "Dodaj do swojego shell config (~/.zshrc lub ~/.bashrc):"
                echo -e "${YELLOW}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
                echo ""
                print_info "Następnie uruchom: source ~/.zshrc (lub ~/.bashrc)"
                ;;
        esac
    else
        # Użytkownik NIE chce dodawać do PATH
        print_info "Pominięto dodawanie do PATH"
        print_info "Możesz uruchomić launcher bezpośrednio: $LAUNCHER_SCRIPT"
    fi
}

# =============================================================================
# KROK 6: Instrukcje Hammerspoon
# =============================================================================
setup_hammerspoon() {
    print_header "Konfiguracja Hammerspoon (opcjonalne)"

    print_info "Aby używać globalnego skrótu klawiszowego (Cmd+Shift+P):"
    echo ""
    echo "1. Zainstaluj Hammerspoon:"
    echo -e "   ${YELLOW}brew install --cask hammerspoon${NC}"
    echo ""
    echo "2. Uruchom Hammerspoon (pojawi się ikona w menu bar)"
    echo ""
    echo "3. Dodaj do ~/.hammerspoon/init.lua:"
    echo -e "   ${YELLOW}cat $HAMMERSPOON_CONFIG >> ~/.hammerspoon/init.lua${NC}"
    echo ""
    echo "   LUB skopiuj ręcznie zawartość z:"
    echo -e "   ${YELLOW}$HAMMERSPOON_CONFIG${NC}"
    echo ""
    echo "4. Reload Hammerspoon config (Cmd+Ctrl+R lub przez menu)"
    echo ""

    # Sprawdź czy Hammerspoon jest już zainstalowany
    if [[ -d "/Applications/Hammerspoon.app" ]]; then
        print_success "Hammerspoon jest już zainstalowany"

        # Sprawdź czy ~/.hammerspoon/init.lua istnieje
        if [[ -f "$HOME/.hammerspoon/init.lua" ]]; then
            print_info "~/.hammerspoon/init.lua już istnieje"

            # Zapytaj czy dodać konfigurację
            echo -n "Czy chcesz automatycznie dodać konfigurację? (t/n): "
            read -r response
            response=$(echo "$response" | tr '[:upper:]' '[:lower:]')

            if [[ "$response" == "t" || "$response" == "y" || "$response" == "yes" || "$response" == "tak" ]]; then
                # Dodaj konfigurację do istniejącego pliku
                echo "" >> "$HOME/.hammerspoon/init.lua"
                echo "-- Project Launcher configuration (auto-added)" >> "$HOME/.hammerspoon/init.lua"
                cat "$HAMMERSPOON_CONFIG" >> "$HOME/.hammerspoon/init.lua"

                print_success "Konfiguracja dodana do ~/.hammerspoon/init.lua"
                print_info "Zreloaduj Hammerspoon: Cmd+Ctrl+R"
            else
                print_info "Pominięto automatyczną konfigurację"
            fi
        else
            # ~/.hammerspoon/init.lua nie istnieje - utwórz go
            print_info "Tworzę ~/.hammerspoon/init.lua..."
            mkdir -p "$HOME/.hammerspoon"
            cp "$HAMMERSPOON_CONFIG" "$HOME/.hammerspoon/init.lua"
            print_success "Utworzono ~/.hammerspoon/init.lua"
            print_info "Zreloaduj Hammerspoon: Cmd+Ctrl+R"
        fi
    else
        print_warning "Hammerspoon nie jest zainstalowany"
        print_info "Zainstaluj: brew install --cask hammerspoon"
    fi
}

# =============================================================================
# MAIN - Główna logika instalacji
# =============================================================================
main() {
    # Wypisz nagłówek instalatora
    echo -e "${GREEN}"
    echo "========================================="
    echo "  Project Launcher - Instalacja"
    echo "========================================="
    echo -e "${NC}"

    # Wykonaj wszystkie kroki instalacji
    check_dependencies    # Krok 1: Sprawdź zależności
    compile_mode_selector # Krok 2: Kompiluj Swift GUI
    set_permissions       # Krok 3: Ustaw chmod +x
    create_config         # Krok 4: Utwórz config.yaml
    setup_path            # Krok 5: Dodaj do PATH (opcjonalne)
    setup_hammerspoon     # Krok 6: Konfiguracja Hammerspoon (opcjonalne)

    # Podsumowanie
    print_header "Instalacja zakończona!"

    print_success "Project Launcher jest gotowy do użycia!"
    echo ""
    print_info "Użycie:"
    echo "  - Z linii komend: ./launcher (lub project-launcher jeśli w PATH)"
    echo "  - Z Hammerspoon: Cmd+Shift+P (jeśli skonfigurowane)"
    echo ""
    print_info "Konfiguracja:"
    echo "  - Edytuj $CONFIG_FILE aby dostosować wykluczenia"
    echo ""
    print_info "Dokumentacja:"
    echo "  - Zobacz README.md dla więcej informacji"
    echo ""
}

# Wywołaj funkcję main
main
