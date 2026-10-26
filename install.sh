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
BULIOS_PAYLOAD="${BULIOS_REPO:-$HOME/Desktop/Projekty/ai/buliOs}/claude/buliOS/install"
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
}

# ~/.claude/projects/<projekt>/memory -> drzewo buliOS. Lokalna pamięć, której jeszcze nie ma w drzewie,
# najpierw do niego dołącza (pliki już obecne w drzewie wygrywają; lokalny katalog zostaje jako .backup.*).
link_claude_memories() {
    mkdir -p "$CLAUDE_MEMORY"
    local dir
    for dir in "$HOME"/.claude/projects/*/memory; do
        [[ -d "$dir" && ! -L "$dir" ]] || continue
        if [[ -z "$(ls -A "$dir")" ]]; then
            rmdir "$dir"
            continue
        fi
        local name
        name="$(basename "$(dirname "$dir")")"
        mkdir -p "$CLAUDE_MEMORY/$name"
        rsync -a --ignore-existing "$dir/" "$CLAUDE_MEMORY/$name/"
        backup_existing "$dir"
    done
    for dir in "$CLAUDE_MEMORY"/*/; do
        [[ -d "$dir" ]] || continue
        link_bulios_item "${dir%/}" "$HOME/.claude/projects/$(basename "$dir")/memory"
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

# Klucz SSH tylko do odczytu repo buliOS (deploy key) dla Maca bez prywatnego konta GitHub, np. służbowego.
# Osobny host github-bulios, żeby nie mieszał się z kluczem do firmowego konta GitHub.
bulios_key() {
    mkdir -p -m 700 "$HOME/.ssh"
    [[ -f "$BULIOS_KEY" ]] || ssh-keygen -q -t ed25519 -N '' -C "bulios-readonly-$(scutil --get ComputerName 2>/dev/null || hostname)" -f "$BULIOS_KEY"
    if ! grep -q '^Host github-bulios$' "$HOME/.ssh/config" 2>/dev/null; then
        printf '\nHost github-bulios\n  HostName github.com\n  User git\n  IdentityFile %s\n  IdentitiesOnly yes\n  StrictHostKeyChecking accept-new\n' "$BULIOS_KEY" >> "$HOME/.ssh/config"
    fi
    print_info "Dodaj ten klucz jako deploy key (tylko odczyt) w ukibbb/buliOs, potem uruchom: bash install.sh bootstrap"
    cat "$BULIOS_KEY.pub"
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

    command -v claude >/dev/null || curl -fsSL https://claude.ai/install.sh | bash

    # Repo buliOS (prywatne) dostarcza hooki, skille i narzędzia linkowane do ~/.claude.
    # Z kluczem tylko do odczytu (install.sh bulios-key) bez logowania do GitHuba, inaczej przez gh.
    local bulios_repo="${BULIOS_REPO:-$HOME/Desktop/Projekty/ai/buliOs}"
    if [[ ! -d "$bulios_repo" ]]; then
        if [[ -f "$BULIOS_KEY" ]]; then
            git clone git@github-bulios:ukibbb/buliOs.git "$bulios_repo"
        else
            gh auth status >/dev/null 2>&1 || gh auth login
            gh repo clone ukibbb/buliOs "$bulios_repo"
        fi
    fi

    install_symlinks

    print_info "Installing buliOS hook dependencies..."
    (cd "$HOME/.claude" && bun install)

    # Drzewo buliOS przychodzi z serwera po sparowaniu urządzeń (README: Drugi Mac).
    brew services start syncthing

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
    *)
        echo "Usage: $0 {bootstrap|install|uninstall|status|forget-personal|bulios-key}"
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
