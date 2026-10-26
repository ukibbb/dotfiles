#!/bin/bash

# Dotfiles Install Script
# Manages symlinks for configuration files

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Define symlinks: "source:target"
SYMLINKS=(
    ".zshrc:$HOME/.zshrc"
    "nvim:$HOME/.config/nvim"
    "wezterm.lua:$HOME/.config/wezterm/wezterm.lua"
    "claude/settings.json:$HOME/.claude/settings.json"
    "claude/statusline-command.sh:$HOME/.claude/statusline-command.sh"
    "claude/CLAUDE.md:$HOME/.claude/CLAUDE.md"
    "claude/agents:$HOME/.claude/agents"
    "git/gitconfig:$HOME/.gitconfig"
    "starship/starship.toml:$HOME/.config/starship.toml"
    "atuin/config.toml:$HOME/.config/atuin/config.toml"
    "mise/config.toml:$HOME/.config/mise/config.toml"
    "bat/config:$HOME/.config/bat/config"
    "btop/btop.conf:$HOME/.config/btop/btop.conf"
    "herdr/config.toml:$HOME/.config/herdr/config.toml"
    "herdr/agents-status.sh:$HOME/.config/herdr/agents-status.sh"
    "uv/uv.toml:$HOME/.config/uv/uv.toml"
    "pnpm/rc:$HOME/Library/Preferences/pnpm/rc"
    "bun/bunfig.toml:$HOME/.bunfig.toml"
)

# Define copies (for apps that don't work with symlinks): "source:target"
COPIES=()

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}!${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${BLUE}→${NC} $1"; }

backup_existing() {
    local target="$1"
    local backup="${target}.backup.$(date +%Y%m%d%H%M%S)"

    mv "$target" "$backup"
    print_warning "Backed up existing $target to $backup"
}

create_symlink() {
    local source="$DOTFILES_DIR/$1"
    local target="$2"
    local target_dir="$(dirname "$target")"

    [[ ! -e "$source" ]] && { print_error "Source missing: $source"; return 1; }

    mkdir -p "$target_dir"

    if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]; then
        print_success "$target already linked"
        return 0
    fi

    [[ -e "$target" || -L "$target" ]] && backup_existing "$target"

    ln -s "$source" "$target"
    print_success "$target -> $source"
}

remove_symlink() {
    local source="$DOTFILES_DIR/$1"
    local target="$2"

    if [[ -L "$target" ]]; then
        rm "$target"
        print_success "Removed: $target"
    else
        print_info "$target not a symlink"
    fi
}

copy_file() {
    local source="$DOTFILES_DIR/$1"
    local target="$2"
    local target_dir="$(dirname "$target")"

    [[ ! -e "$source" ]] && { print_error "Source missing: $source"; return 1; }

    mkdir -p "$target_dir"

    if [[ -e "$target" ]] && cmp -s "$source" "$target"; then
        print_success "$target already up to date"
        return 0
    fi

    [[ -e "$target" || -L "$target" ]] && backup_existing "$target"

    cp "$source" "$target"
    print_success "$target <- $source (copied)"
}

# buliOS (fork LifeOS) lives in the buliOs repo; here we only link it into ~/.claude.
# Personal data (profile, memory) stays in ~/.config/bulios/USER, outside any git repo.
BULIOS_REPO_DIR="${BULIOS_REPO:-$HOME/Desktop/Projekty/ai/buliOs}"
BULIOS_PAYLOAD="$BULIOS_REPO_DIR/claude/buliOS/install"
BULIOS_DATA="$HOME/.config/bulios/USER"
# Pamięci projektów Claude Code w drzewie buliOS: Syncthing przenosi je na drugiego Maca i serwer.
CLAUDE_MEMORY="$BULIOS_DATA/CLAUDE_MEMORY"

# An existing file or dir at the target is an old copy: report it instead of backing it up
# next to the original, because Claude Code would load the backup as a duplicate skill or hook.
link_bulios_item() {
    local source="$1"
    local target="$2"

    if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]; then
        return 0
    fi
    if [[ -e "$target" || -L "$target" ]]; then
        print_error "$target istnieje — usuń starą kopię i uruchom ponownie"
        return 0
    fi

    mkdir -p "$(dirname "$target")"
    ln -s "$source" "$target"
    print_success "$target -> $source"
}

link_bulios() {
    if [[ ! -d "$BULIOS_PAYLOAD" ]]; then
        print_warning "buliOS: $BULIOS_PAYLOAD not found, skipping"
        return 0
    fi
    echo -e "\n${BLUE}Linking buliOS...${NC}\n"

    mkdir -p "$BULIOS_DATA/MEMORY"
    link_bulios_item "$BULIOS_DATA" "$BULIOS_PAYLOAD/BULIOS/USER"
    link_bulios_item "$BULIOS_DATA/MEMORY" "$BULIOS_PAYLOAD/BULIOS/MEMORY"
    link_bulios_item "$BULIOS_PAYLOAD/BULIOS" "$HOME/.claude/BULIOS"
    link_bulios_item "$BULIOS_PAYLOAD/package.json" "$HOME/.claude/package.json"

    local entry
    for entry in "$BULIOS_PAYLOAD"/skills/*; do
        link_bulios_item "$entry" "$HOME/.claude/skills/$(basename "$entry")"
    done
    for entry in "$BULIOS_PAYLOAD"/hooks/*; do
        [[ "$(basename "$entry")" == "hooks.json" ]] && continue
        link_bulios_item "$entry" "$HOME/.claude/hooks/$(basename "$entry")"
    done
    link_claude_memories
    link_device_logs
}

# Nazwa tego urządzenia w buliOS (~/.config/bulios/device, poza drzewem). Hostname nie wystarcza:
# dwa Maki potrafią mieć ten sam („Lukaszs-MacBook-Pro”), więc dochodzi skrót sprzętowego UUID.
device_name() {
    local file="$HOME/.config/bulios/device"
    if [[ ! -s "$file" ]]; then
        local host uuid
        host="$(scutil --get LocalHostName 2>/dev/null || hostname -s)"
        uuid="$(ioreg -rd1 -c IOPlatformExpertDevice 2>/dev/null | awk -F'"' '/IOPlatformUUID/ {print $4}')"
        mkdir -p "$(dirname "$file")"
        printf '%s-%s\n' "$host" "${uuid:0:4}" >"$file"
    fi
    tr -d '[:space:]' <"$file"
}

# Logi zdarzeń buliOS (MEMORY/OBSERVABILITY) są per urządzenie: OBSERVABILITY to dowiązanie do
# MEMORY/DEVICES/<urządzenie>/OBSERVABILITY. Każde urządzenie pisze tylko do swojego katalogu,
# więc synchronizacja nie robi konfliktów, a panel czyta katalogi wszystkich urządzeń.
link_device_logs() {
    local memory="$BULIOS_DATA/MEMORY" device
    device="$(device_name)"
    local own="$memory/DEVICES/$device/OBSERVABILITY" obs="$memory/OBSERVABILITY"
    mkdir -p "$own" "$memory/PROPOSALS"
    if [[ -d "$obs" && ! -L "$obs" ]]; then
        # Wspólna kolejka propozycji przenosi się do MEMORY/PROPOSALS; stary katalog (z kopiami konfliktów
        # synchronizacji — duplikatami logów innych urządzeń) idzie do kopii poza drzewem, żeby się nie synchronizował.
        [[ -f "$obs/pending-proposals.jsonl" && ! -e "$memory/PROPOSALS/pending-proposals.jsonl" ]] &&
            mv "$obs/pending-proposals.jsonl" "$memory/PROPOSALS/"
        rsync -a --exclude='*.sync-conflict-*' --exclude='pending-proposals.jsonl*' "$obs/" "$own/"
        mv "$obs" "$HOME/.config/bulios/OBSERVABILITY.backup.$(date +%Y%m%d%H%M%S)"
    fi
    if [[ ! -L "$obs" ]]; then
        ln -s "DEVICES/$device/OBSERVABILITY" "$obs"
        print_success "$obs -> DEVICES/$device/OBSERVABILITY"
    fi
}

# ~/.claude/projects/<projekt>/memory -> drzewo buliOS. Claude Code nazywa projekt pełną ścieżką
# (-Users-<użytkownik>-Desktop-X), a Maki mają różne nazwy użytkownika, więc w drzewie klucz jest
# względny do katalogu domowego (Desktop-X): ten sam projekt ma jedną pamięć na każdym Macu.
# Lokalna pamięć najpierw dołącza do drzewa (pliki z drzewa wygrywają; lokalny katalog zostaje jako .backup.*).
link_claude_memories() {
    local home_key dir name rel target
    home_key="$(tr '/' '-' <<<"$HOME")"
    mkdir -p "$CLAUDE_MEMORY"

    # Dawny układ z pełnym kluczem (z dowolnego Maca) -> klucz względny; kolizje zostają jako *.conflict-<klucz>.
    for dir in "$CLAUDE_MEMORY"/-Users-*/; do
        [[ -d "$dir" ]] || continue
        name="$(basename "$dir")"
        rel="${name#-Users-*-}"
        mkdir -p "$CLAUDE_MEMORY/$rel"
        rsync -a -b --suffix=".conflict-$name" "$dir" "$CLAUDE_MEMORY/$rel/"
        rm -rf "$dir"
    done

    for dir in "$HOME"/.claude/projects/"$home_key"-*/memory; do
        [[ -d "$dir" && ! -L "$dir" ]] || continue
        if [[ -z "$(ls -A "$dir")" ]]; then
            rmdir "$dir"
            continue
        fi
        name="$(basename "$(dirname "$dir")")"
        rel="${name#"$home_key"-}"
        mkdir -p "$CLAUDE_MEMORY/$rel"
        rsync -a --ignore-existing "$dir/" "$CLAUDE_MEMORY/$rel/"
        backup_existing "$dir"
    done

    for dir in "$CLAUDE_MEMORY"/*/; do
        [[ -d "$dir" ]] || continue
        target="$HOME/.claude/projects/$home_key-$(basename "$dir")/memory"
        # Link z dawnego układu wskazuje na nieistniejący już katalog w drzewie — zastępujemy go.
        if [[ -L "$target" && "$(readlink "$target")" == "$CLAUDE_MEMORY"/* && "$(readlink "$target")" != "${dir%/}" ]]; then
            rm "$target"
        fi
        link_bulios_item "${dir%/}" "$target"
    done
}

install_symlinks() {
    echo -e "\n${BLUE}Installing dotfiles...${NC}\n"
    for entry in "${SYMLINKS[@]}"; do
        create_symlink "${entry%%:*}" "${entry##*:}"
    done
    for entry in "${COPIES[@]}"; do
        copy_file "${entry%%:*}" "${entry##*:}"
    done
    link_bulios
    echo -e "\n${GREEN}Done!${NC}"
}

BULIOS_KEY="$HOME/.ssh/bulios_deploy"

# Klucz SSH do repo buliOS (deploy key) dla Maca bez prywatnego konta GitHub, np. służbowego.
# Osobny host github-bulios, żeby nie mieszał się z kluczem do firmowego konta GitHub.
bulios_key() {
    mkdir -p -m 700 "$HOME/.ssh"
    [[ -f "$BULIOS_KEY" ]] || ssh-keygen -q -t ed25519 -N '' -C "bulios-$(scutil --get ComputerName 2>/dev/null || hostname)" -f "$BULIOS_KEY"
    if ! grep -q '^Host github-bulios$' "$HOME/.ssh/config" 2>/dev/null; then
        printf '\nHost github-bulios\n  HostName github.com\n  User git\n  IdentityFile %s\n  IdentitiesOnly yes\n  StrictHostKeyChecking accept-new\n' "$BULIOS_KEY" >> "$HOME/.ssh/config"
    fi
    print_info "Dodaj ten klucz jako deploy key w ukibbb/buliOs (z zapisem, jeśli z tego Maca wypychasz zmiany), potem uruchom: bash install.sh bootstrap"
    cat "$BULIOS_KEY.pub"
}

# Skrypt hooka herdra, który wywołuje claude/settings.json. `herdr integration install` dopisałby też
# do settings.json drugi taki sam hook z absolutną ścieżką, więc instaluje się do katalogu tymczasowego.
install_herdr_hook() {
    local tmp
    tmp="$(mktemp -d)"
    CLAUDE_CONFIG_DIR="$tmp" herdr integration install claude >/dev/null
    mkdir -p "$HOME/.claude/hooks"
    cp "$tmp/hooks/herdr-agent-state.sh" "$HOME/.claude/hooks/"
    rm -rf "$tmp"
    print_success "herdr: hook Claude Code w ~/.claude/hooks/herdr-agent-state.sh"
}

# Najnowsze dotfiles i kod buliOS (tylko fast-forward, lokalne zmiany zostają), potem ponowne linkowanie.
update() {
    git -C "$DOTFILES_DIR" pull --ff-only
    [[ -d "$BULIOS_REPO_DIR" ]] && git -C "$BULIOS_REPO_DIR" pull --ff-only
    install_symlinks
    (cd "$HOME/.claude" && bun install)
    install_claude_bridge
    install_usage_aggregator
    clear_wezterm_quarantine
}

# WezTerm z flagą kwarantanny macOS startuje z losowej kopii (App Translocation), więc system widzi go jako nową
# aplikację i odbiera mu zgodę na Biurko, gdzie leżą repo i hooki buliOS. Bez flagi zgoda zostaje na stałe.
clear_wezterm_quarantine() {
    [[ -d /Applications/WezTerm.app ]] && xattr -dr com.apple.quarantine /Applications/WezTerm.app 2>/dev/null
    return 0
}

# Usługa launchd odbierająca zatwierdzone zlecenia Jarvisa dla Claude Code. Projekty tego Maca są w
# zsynchronizowanym USER/CONFIG/claude-projects.json (klucz: nazwa urządzenia), więc konfiguracja jest jedna dla wszystkich.
install_claude_bridge() {
    bun "$HOME/.claude/BULIOS/TOOLS/ClaudeBridge.ts" install || print_warning "ClaudeBridge się nie zainstalował — szczegóły wyżej"
}

# Nocne podsumowanie zużycia Claude Code (usage-daily.jsonl w logach urządzenia) — z niego panel liczy Koszty AI.
install_usage_aggregator() {
    bun "$HOME/.claude/BULIOS/TOOLS/InstallUsageAggregator.ts" || print_warning "UsageAggregator się nie zainstalował — szczegóły wyżej"
}

# Syncthing serwera (konrad126); ID urządzenia nie jest sekretem — połączenie wymaga akceptacji po obu stronach.
BULIOS_SERVER_ID="BMKI3PC-MZO7U67-3NTHMYW-JUBTV7S-5R3FP5Z-PLLRMDN-7QM456A-S3SLHAD"

# Paruje ten Mac z serwerem: folder bulios-user (drzewo buliOS). Na start tylko odbiera, żeby pusty Mac
# niczego nie nadpisał. Serwer musi już znać ID tego Maca (st config devices add …).
bulios_sync() {
    if ! pgrep -qx syncthing; then
        # brew services bywa zablokowane na Macu służbowym (MDM), więc start jako zwykły proces.
        nohup syncthing serve --no-browser >"$HOME/Library/Logs/syncthing.log" 2>&1 &
        sleep 5
    fi
    mkdir -p "$BULIOS_DATA"
    cp "$BULIOS_REPO_DIR/deploy/stignore" "$BULIOS_DATA/.stignore"
    syncthing cli config devices list | grep -q "$BULIOS_SERVER_ID" ||
        syncthing cli config devices add --device-id "$BULIOS_SERVER_ID" --name konrad126
    if ! syncthing cli config folders list | grep -qx bulios-user; then
        syncthing cli config folders add --id bulios-user --label buliOS --path "$BULIOS_DATA" --type receiveonly
        syncthing cli config folders bulios-user devices add --device-id "$BULIOS_SERVER_ID"
        print_success "Syncthing: folder bulios-user podpięty do serwera (tylko odbiór, uruchom ponownie po pobraniu drzewa)"
    elif [[ -f "$BULIOS_DATA/PRINCIPAL/PRINCIPAL_MEMORY.md" ]]; then
        # Drzewo już przyszło z serwera, więc ten Mac może też wysyłać swoje sesje i pamięć (także z pracy).
        syncthing cli config folders bulios-user type set sendreceive
        print_success "Syncthing: folder bulios-user wysyła i odbiera"
    fi
    syncthing cli show system | grep myID
}

bootstrap() {
    if ! command -v brew >/dev/null; then
        print_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"

    print_info "Installing Homebrew packages..."
    # Pojedyncza aplikacja może się nie zainstalować (np. brak uprawnień administratora na Macu służbowym);
    # reszta bootstrapu i tak ma się wykonać.
    brew bundle --file "$DOTFILES_DIR/Brewfile" || print_warning "Część pakietów Homebrew się nie zainstalowała — szczegóły wyżej"
    clear_wezterm_quarantine

    command -v claude >/dev/null || curl -fsSL https://claude.ai/install.sh | bash

    # Repo buliOS (prywatne) dostarcza hooki, skille i narzędzia linkowane do ~/.claude.
    # Z kluczem deploy (install.sh bulios-key) bez logowania do GitHuba, inaczej przez gh.
    if [[ ! -d "$BULIOS_REPO_DIR" ]]; then
        if [[ -f "$BULIOS_KEY" ]]; then
            git clone git@github-bulios:ukibbb/buliOs.git "$BULIOS_REPO_DIR"
        else
            gh auth status >/dev/null 2>&1 || gh auth login
            gh repo clone ukibbb/buliOs "$BULIOS_REPO_DIR"
        fi
    fi

    install_symlinks
    install_herdr_hook

    print_info "Installing buliOS hook dependencies..."
    (cd "$HOME/.claude" && bun install)
    install_claude_bridge
    install_usage_aggregator

    # Drzewo buliOS przychodzi z serwera po sparowaniu urządzeń (README: Drugi Mac).
    # Na macOS Tahoe launchd potrafi zarejestrować agenta bez uruchomienia go; kickstart startuje go od razu.
    brew services start syncthing
    launchctl kickstart "gui/$(id -u)/sh.brew.syncthing"

    print_info "Installing mise runtimes..."
    (cd "$HOME" && mise install)

    print_info "Restoring Neovim plugins..."
    nvim --headless "+Lazy! restore" +qa

    print_info "Next: optional tools and Mason packages from README.md"
}

uninstall_symlinks() {
    echo -e "\n${BLUE}Removing symlinks...${NC}\n"
    for entry in "${SYMLINKS[@]}"; do
        remove_symlink "${entry%%:*}" "${entry##*:}"
    done
    echo -e "\n${GREEN}Done!${NC}"
}

# Zabiera z tego Maca prywatne dane buliOS (np. przed oddaniem komputera służbowego); narzędzia i dotfiles zostają.
# Syncthing jest zatrzymywany i rozparowywany PRZED kasowaniem drzewa — inaczej usunięcie poszłoby na serwer.
forget_personal() {
    echo "Usunie: drzewo buliOS ($BULIOS_DATA) z pamięciami projektów, konfigurację Syncthinga,"
    echo "prywatne konto gh (ukibbb) i sesje 1Password. Dane na serwerze zostają nietknięte."
    local answer
    read -r -p "Wpisz USUN, aby kontynuować: " answer
    if [[ "$answer" != "USUN" ]]; then
        print_warning "Przerwano"
        return 1
    fi

    brew services stop syncthing >/dev/null 2>&1 || true
    rm -rf "$HOME/Library/Application Support/Syncthing"

    local link
    for link in "$HOME"/.claude/projects/*/memory; do
        if [[ -L "$link" && "$(readlink "$link")" == "$CLAUDE_MEMORY"/* ]]; then
            rm "$link"
        fi
    done
    rm -rf "$BULIOS_DATA"

    gh auth logout --hostname github.com --user ukibbb 2>/dev/null || true
    op signout --all 2>/dev/null || true
    print_success "Prywatne dane usunięte z tego Maca."
    print_info "Na serwerze usuń to urządzenie: st config devices remove --device-id <ID tego Maca>"
}

show_status() {
    echo -e "\n${BLUE}Status:${NC}\n"
    for entry in "${SYMLINKS[@]}"; do
        local source="$DOTFILES_DIR/${entry%%:*}"
        local target="${entry##*:}"
        if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]; then
            print_success "$target"
        elif [[ -e "$target" ]]; then
            print_warning "$target (not linked)"
        else
            print_error "$target (missing)"
        fi
    done
    for entry in "${COPIES[@]}"; do
        local source="$DOTFILES_DIR/${entry%%:*}"
        local target="${entry##*:}"
        if [[ -e "$target" ]] && cmp -s "$source" "$target"; then
            print_success "$target (copy)"
        elif [[ -e "$target" ]]; then
            print_warning "$target (copy differs)"
        else
            print_error "$target (missing)"
        fi
    done
    if [[ -L "$HOME/.claude/BULIOS" ]] && [[ "$(readlink "$HOME/.claude/BULIOS")" == "$BULIOS_PAYLOAD/BULIOS" ]]; then
        print_success "$HOME/.claude/BULIOS (buliOS)"
    else
        print_warning "$HOME/.claude/BULIOS (buliOS not linked)"
    fi
}

case "${1:-}" in
    bootstrap) bootstrap ;;
    install)   install_symlinks ;;
    uninstall) uninstall_symlinks ;;
    status)    show_status ;;
    forget-personal) forget_personal ;;
    bulios-key) bulios_key ;;
    bulios-sync) bulios_sync ;;
    update)    update ;;
    *)
        echo "Usage: $0 {bootstrap|install|uninstall|status|forget-personal|bulios-key|bulios-sync|update}"
        echo ""
        echo "Symlinks:"
        for entry in "${SYMLINKS[@]}"; do
            echo "  ${entry%%:*} -> ${entry##*:}"
        done
        echo ""
        echo "Copies:"
        for entry in "${COPIES[@]}"; do
            echo "  ${entry%%:*} -> ${entry##*:}"
        done
        ;;
esac
