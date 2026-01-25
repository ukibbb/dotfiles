#!/usr/bin/env bash
#
# TMUX-SESSION.SH
# Create or attach to a tmux session for a given folder
#
# USAGE:
#   ./tmux-session.sh /path/to/folder
#
# BEHAVIOR:
#   - Session name is derived from folder basename
#   - If session exists: attach/switch to it
#   - If session doesn't exist: create it with folder as working directory
#

set -uo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# CHECK DEPENDENCIES
# ─────────────────────────────────────────────────────────────────────────────
command -v tmux &>/dev/null || {
    echo "Error: 'tmux' is not installed." >&2
    exit 1
}

# ─────────────────────────────────────────────────────────────────────────────
# VALIDATE ARGUMENTS
# ─────────────────────────────────────────────────────────────────────────────
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 /path/to/folder" >&2
    exit 1
fi

folder="$1"

if [[ ! -d "$folder" ]]; then
    echo "Error: '$folder' is not a directory." >&2
    exit 1
fi

# ─────────────────────────────────────────────────────────────────────────────
# DERIVE SESSION NAME
# ─────────────────────────────────────────────────────────────────────────────
# tmux session names cannot contain dots or colons, so we replace them
# ─────────────────────────────────────────────────────────────────────────────
session_name=$(basename "$folder" | tr '.:' '-')

# ─────────────────────────────────────────────────────────────────────────────
# CREATE OR ATTACH TO SESSION
# ─────────────────────────────────────────────────────────────────────────────

session_exists=false
tmux has-session -t "$session_name" 2>/dev/null && session_exists=true

if [[ -n "${TMUX:-}" ]]; then
    # Running from INSIDE tmux
    if [[ "$session_exists" == "false" ]]; then
        cd "$folder" && tmux new-session -s "$session_name"
    else
        # Session exists - cd to folder
        tmux send-keys -t "$session_name" "cd '$folder' && clear" Enter
        tmux switch-client -t "$session_name"
    fi
else
    # Running from OUTSIDE tmux
    if [[ "$session_exists" == "true" ]]; then
        # Session exists - cd to folder, then attach
        tmux send-keys -t "$session_name" "cd '$folder' && clear" Enter
        tmux attach -t "$session_name"
    else
        # cd first, then create session in that directory
        cd "$folder" && tmux new-session -s "$session_name"
    fi
fi
