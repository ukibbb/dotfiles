#!/usr/bin/env bash
#
# WEZTERM-WORKSPACE.SH
# Switch to (or create) a WezTerm workspace for a given folder
#
# USAGE:
#   ./wezterm-workspace.sh /path/to/folder
#
# BEHAVIOR:
#   - Sets the `wezterm_workspace` user var; wezterm.lua reacts to it
#   - Workspace name is derived from folder basename
#   - If the workspace exists: switch to it
#   - If not: create it with the folder as working directory
#

set -uo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 /path/to/folder" >&2
    exit 1
fi

folder="$1"
if [[ ! -d "$folder" ]]; then
    echo "Error: '$folder' is not a directory." >&2
    exit 1
fi

if [[ "${TERM_PROGRAM:-}" != "WezTerm" ]]; then
    echo "Error: not running inside WezTerm." >&2
    exit 1
fi

# OSC 1337 SetUserVar, value base64-encoded (written to the tty so it works from $(...))
printf '\033]1337;SetUserVar=%s=%s\007' wezterm_workspace "$(printf '%s' "$folder" | base64 | tr -d '\n')" > /dev/tty
