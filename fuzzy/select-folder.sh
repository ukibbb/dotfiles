#!/usr/bin/env bash
#
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                         SELECT-FOLDER.SH                                   ║
# ║  Select a folder using FZF with WezTerm-themed colors                      ║
# ║  Searches your entire home directory with smart exclusions                 ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
#
# USAGE:
#   ./select-folder.sh              # Browse from home directory (~)
#   ./select-folder.sh ~/projects   # Browse from specific directory
#   ./select-folder.sh /            # Browse entire system (slow!)
#
# OUTPUT:
#   Prints the absolute path of the selected folder to stdout
#   Prints nothing if user cancels (presses Escape)
#
# DEPENDENCIES:
#   - fzf: brew install fzf
#   - fd:  brew install fd
#

# ─────────────────────────────────────────────────────────────────────────────
# STRICT MODE (partial)
# ─────────────────────────────────────────────────────────────────────────────
# -u          → Treat references to unset variables as errors
# -o pipefail → Pipeline fails if ANY command in it fails
#
# NOTE: We don't use -e because FZF returns exit code 1 when user
# presses Escape, and we don't want that to kill our script.
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# CHECK DEPENDENCIES
# ─────────────────────────────────────────────────────────────────────────────
# command -v <cmd>
#   └─ Returns the path to <cmd> if it exists, nothing if it doesn't
#   └─ Exit code: 0 if found, 1 if not found
#
# &>/dev/null
#   └─ Redirect both stdout (&) and stderr to /dev/null
#   └─ We don't care about the output, just the exit code
#
# ||
#   └─ OR operator: if left side fails (exit code != 0), run right side
#
# { ... }
#   └─ Command grouping: run multiple commands as a unit
#   └─ Allows us to echo AND exit together after ||
#
# >&2
#   └─ Redirect stdout to stderr (file descriptor 2)
#   └─ Error messages should go to stderr, not stdout
#
# exit 1
#   └─ Exit the script with code 1 (failure)
# ─────────────────────────────────────────────────────────────────────────────
command -v fd &>/dev/null || {
    echo "Error: 'fd' is not installed." >&2
    echo "Install with: brew install fd" >&2
    exit 1
}

command -v fzf &>/dev/null || {
    echo "Error: 'fzf' is not installed." >&2
    echo "Install with: brew install fzf" >&2
    exit 1
}

# ─────────────────────────────────────────────────────────────────────────────
# PARSE ARGUMENTS
# ─────────────────────────────────────────────────────────────────────────────
START_DIR="${1:-$HOME}"

# ─────────────────────────────────────────────────────────────────────────────
# FZF COLOR CONFIGURATION (WezTerm "Deep Space" theme)
# ─────────────────────────────────────────────────────────────────────────────
FZF_COLORS="--color=bg:#000000,fg:#e0e0e0,hl:#00d9ff"
FZF_COLORS+=",bg+:#2a4a7a,fg+:#ffffff,hl+:#4dffff"
FZF_COLORS+=",info:#50fa7b,prompt:#00d9ff,pointer:#bd93f9"
FZF_COLORS+=",marker:#50fa7b,spinner:#bd93f9,header:#569cd6"
FZF_COLORS+=",border:#4d4d4d,gutter:#000000"

# ─────────────────────────────────────────────────────────────────────────────
# LIST DIRECTORIES WITH FD
# ─────────────────────────────────────────────────────────────────────────────
# fd is a fast, user-friendly alternative to 'find'.
#
# OPTIONS:
#   --type d           → Only find directories
#   --hidden           → Include hidden directories (starting with .)
#   --exclude PATTERN  → Skip directories matching pattern
#   . "$dir"           → Search for anything (.) starting from $dir
#
# The backslash \ at end of line continues the command on the next line.
# ─────────────────────────────────────────────────────────────────────────────
list_directories() {
    local dir="$1"

    fd --type d --absolute-path \
        --exclude node_modules \
        --exclude __pycache__ \
        --exclude venv \
        --exclude Library \
        --exclude target \
        --exclude build \
        --exclude dist \
        --exclude DerivedData \
        --exclude Pods \
        --exclude Movies \
        --exclude "Photos Library.photoslibrary" \
        . "$dir" 2>/dev/null
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN: List directories and pipe to FZF
# ─────────────────────────────────────────────────────────────────────────────
# || true
#   └─ If FZF exits with error (user pressed Escape), ignore it
#   └─ Without this, pipefail would cause our script to exit
# ─────────────────────────────────────────────────────────────────────────────
selected=$(list_directories "$START_DIR" | \
    awk '{print gsub(/\//, "/"), $0}' | sort -rn | sed 's/^[0-9]* //' | \
    fzf \
    $FZF_COLORS \
    --height=40% \
    --layout=reverse \
    --border=rounded \
    --info=inline \
    --prompt="📁 " \
    --pointer="▶" \
    --marker="✓" \
    --header="Navigate to folder" \
    --preview='ls -lah --color=always {} 2>/dev/null | head -20' \
    --preview-window=right:40%:wrap:hidden \
    --bind='ctrl-p:toggle-preview' \
    --ansi) || true

# ─────────────────────────────────────────────────────────────────────────────
# OUTPUT THE RESULT
# ─────────────────────────────────────────────────────────────────────────────
# fd outputs absolute paths thanks to --absolute-path flag
# ─────────────────────────────────────────────────────────────────────────────
if [[ -n "$selected" ]]; then
    echo "$selected"
fi
