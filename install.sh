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
    "ghostty:$HOME/.config/ghostty/config"
    "tmux.conf:$HOME/.tmux.conf"
claude/settings.json:$HOME/.claude/settings.json
    "claude/statusline-command.sh:$HOME/.claude/statusline-command.sh"
    "claude/CLAUDE.md:$HOME/.claude/CLAUDE.md"
    "claude/commands:$HOME/.claude/commands"
)

# Define copies (for apps that don't work with symlinks): "source:target"
COPIES=(
    "karabiner/karabiner.json:$HOME/.config/karabiner/karabiner.json"
)

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}!${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${BLUE}→${NC} $1"; }

create_symlink() {
    local source="$DOTFILES_DIR/$1"
    local target="$2"
    local target_dir="$(dirname "$target")"

    [[ ! -e "$source" ]] && { print_error "Source missing: $source"; return 1; }

    mkdir -p "$target_dir"

    # Remove whatever is there
    [[ -e "$target" || -L "$target" ]] && rm -rf "$target"

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
    cp "$source" "$target"
    print_success "$target <- $source (copied)"
}

install_symlinks() {
    echo -e "\n${BLUE}Installing dotfiles...${NC}\n"
    for entry in "${SYMLINKS[@]}"; do
        create_symlink "${entry%%:*}" "${entry##*:}"
    done
    for entry in "${COPIES[@]}"; do
        copy_file "${entry%%:*}" "${entry##*:}"
    done
    echo -e "\n${GREEN}Done!${NC}"
}

uninstall_symlinks() {
    echo -e "\n${BLUE}Removing symlinks...${NC}\n"
    for entry in "${SYMLINKS[@]}"; do
        remove_symlink "${entry%%:*}" "${entry##*:}"
    done
    echo -e "\n${GREEN}Done!${NC}"
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
        local target="${entry##*:}"
        if [[ -e "$target" ]]; then
            print_success "$target (copy)"
        else
            print_error "$target (missing)"
        fi
    done
}

case "${1:-}" in
    install)   install_symlinks ;;
    uninstall) uninstall_symlinks ;;
    status)    show_status ;;
    *)
        echo "Usage: $0 {install|uninstall|status}"
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
